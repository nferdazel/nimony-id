---
chapter: 23
title: Testing and the Sample Verifier
job: Write checks that run under the pin and use the book's sample verifier so a chapter's claims stay reproducible.
nimony_version: 0.6.3
nimony_commit: 4ba90a781b0b22d0821efaa153c129c37cef6143
toolchain: ~/.local/opt/nimony/4ba90a7
host_compiler: ~/.local/opt/nim-2.4.0
status: frozen
tech_review: Momo 2026-11-13
editorial_pass: 2026-11-13
samples: [samples/23-testing/testing.nim]
glossary_added: [assert, assertionsEnabled, assumeSync, sample verifier]
---

# Testing dan Verifier Sample

## Untuk apa bab ini

Klaim soal compiler nilainya sebesar reproducer-nya. Setiap bab di buku ini diperiksa dengan menjalankan
sesuatu, dan bab ini tempat kebiasaan itu jadi berkas yang bisa kamu jalankan ulang: test yang gagal berisik
kalau perilakunya berubah, dan verifier kecil yang mengompilasi serta menjalankan setiap sample di repo terhadap
satu commit yang dipin.

Pin membuat ini lebih sederhana sekaligus lebih aneh daripada Nim 2. Lebih sederhana, karena toolchain-nya satu
dan perintahnya satu. Lebih aneh, karena perabot testing yang biasa diambil programmer Nim 2 tidak semuanya ada
di sini: `std/unittest` tidak ada, `doAssert` tidak dideklarasikan, `static:` bukan statement yang diterima
compiler, dan `assert` sendiri tidak ada di `system`. Yang ada adalah modul assertion kecil yang bisa dibaca
utuh dan exit code proses, dan itu cukup untuk menulis pemeriksaan yang berarti.

## `assert` tidak ada di `system`

Kejutan pertama ada di import. Di Nim 2, `assert` sudah tersedia sebelum kamu menulis apa pun. Di pin dia template
di `std/assertions` (`lib/std/assertions.nim:23`), jadi program yang cuma mengimpor `syncio` dapat:

```
main.nim(2, 1) Error: undeclared identifier: 'assert'
```

Tambahkan modulnya dan baris yang sama terkompilasi. Modul itu cukup kecil untuk dibaca sekali duduk, dan
membacanya menjawab sebagian besar pertanyaan yang kalau tidak harus diuji bab ini:

```nim
import std / [assertions, syncio]

assert 1 + 1 == 2
assert true, "never printed"
echo "survived"
```

Itu mencetak `survived` dan tidak ada yang lain: assertion yang lolos itu diam. Tiga definisi di modul itu yang
bekerja. `assertionsEnabled` adalah konstanta compile-time, `not defined(danger) and not defined(noAssertions)`
(`:3`). `assert` adalah template yang mengembang jadi panggilan `failedAssertImpl` hanya kalau konstanta itu
benar (`:23-31`). `raiseAssert` mencetak `[Assertion Failure] ` plus pesannya dengan `echo` lalu keluar dengan
status `1` (`:11-13`).

Detail terakhir itu layak diberhentikan, karena Bab 21 sudah menunjukkan bentuk yang sama: `quit(msg)`
menulis ke stdout di pin. Assertion yang gagal ikut aturan itu. Pesannya ke stdout, bukan stderr, dan prosesnya
keluar `1`:

```
[Assertion Failure] got 2
```

Pesannya apa pun yang kamu kirim; tanpa pesan barisnya `[Assertion Failure] ` dengan spasi di ujung dan tidak ada
apa-apa sesudahnya. Test runner yang memungut stderr untuk mencari kegagalan tidak akan melihat apa pun.

`assert` juga boleh di dalam `func`, dan itu penting kalau pemeriksaan kamu tinggal di helper read-only.
`failedAssertImpl` dideklarasikan `{.noinline, noSideEffect, noreturn.}` dan membuang efeknya di dalam body
(`lib/std/assertions.nim:15-22`), jadi panggilannya tidak membuat pemanggilnya jadi tidak murni:

```nim
import std / [assertions, syncio]

func clampPositive(x: int): int =
  assert x >= 0, "negative"
  x
echo clampPositive(7)
```

Itu mencetak `7`.

## Harness yang kamu tulis sendiri

Tidak ada `std/unittest` di pin. `import std / [unittest]` gagal di parser dengan
`file not found: …/src/lib/std/unittest.nim`, bentuk yang sama dengan modul yang hilang di Bab 20: errornya
menyebut path yang dicari compiler, bukan fitur yang tidak ada. `doAssert` juga tidak dideklarasikan, jadi
kebiasaan Nim 2 memakai assertion kedua yang tidak bisa dicabut tidak punya padanan di sini.

Yang kamu tulis sebagai gantinya adalah procedure dengan nama, kondisi, dan dua counter. Versi pertamanya yang
paling sering ditulis orang tidak terkompilasi, dan errornya pelajaran bagus:

```nim
var checks = 0

proc bump() =
  inc checks
```

```
Error: unsynchronized access to global variable 'checks'; pass it to a '.sync' routine or use
'{.cast(assumeSync).}'
```

Di pin variabel module-level yang mutable tidak boleh disentuh lewat namanya dari dalam routine
(`src/nimony/contracts_fir.nim:4120-4127`). Pemeriksaannya soal state bersama, dan dia menyala bahkan di program
single-threaded yang tidak punya thread sama sekali. Pesannya menawarkan dua jalan keluar, dan bagian `.sync`
artinya lebih sedikit daripada kelihatannya: mendeklarasikan routine-nya `{.sync.}` tidak membuat akses langsung
itu sah, karena klausa itu soal global yang diserahkan ke routine sebagai parameter `var` atau `ptr`. Menyerahkan
counter lewat parameter begitu adalah bentuk pertama, dan itu menjaga routine-nya jujur soal apa yang dia ubah:

```nim
proc check(name: string; cond: bool; checks, failures: var int) =
  inc checks
  if cond:
    echo "ok - ", name
  else:
    inc failures
    echo "not ok - ", name
```

Atau bungkus mutasinya dalam blok pragma yang disebut pesan itu. Pesannya bilang "use `{.cast(assumeSync).}`",
dan menyimpan pragma itu di deklarasi variabelnya ditolak sebagai `too many arguments for pragma`; bentuk yang
berhasil adalah blok:

```nim
proc bump() =
  {.cast(assumeSync).}:
    inc checks
```

Bagian `.sync` dari pesan itu bukan izin untuk mendeklarasikan routine harness-nya `{.sync.}`. Dia menjelaskan
rute parameter `var` di atas; bloknya adalah cara menyatakan janji yang sama untuk baris yang menyebut global
secara langsung.

`{.feature: "assumeSync".}` di level modul adalah bentuk ketiga: dia menandai setiap global di modul itu sebagai
single-threaded, dan itu yang dilakukan source compiler sendiri untuk state internalnya
(`src/nimony/programs.nim:9`). Itu janji, dan compiler menerimanya.

Counter sebagai parameter adalah bentuk yang bab ini ajarkan, karena janjinya tetap lokal di routine yang
membuatnya. `check` tidak pernah menyebut global, jadi dia tidak butuh `{.sync.}` sendiri; driver-nya adalah
statement biasa di body modul, di mana global mutable diperbolehkan:

```nim
var checks = 0
var failures = 0

check("addition", 1 + 1 == 2, checks, failures)
check("length of hello", "hello".len == 5, checks, failures)
echo checks, " checks, ", failures, " failed"
quit(if failures == 0: 0 else: 1)
```

`quit` itulah yang membuat harness jadi test, bukan laporan. Exit code adalah satu-satunya yang dibaca shell,
job CI, atau verifier buku ini.

## Pemeriksaan yang jalan saat compile

Sebagian klaim lebih murah diperiksa sambil mengompilasi, dan pin punya satu cara yang andal, satu pragma yang
cuma jalan di satu posisi, dan satu bentuk statement yang ditolak.

`static:` bukan statement yang diterima compiler. `static: assert 1 + 1 == 3` berhenti di sem dengan
`unsupported statement: staticstmt` (`src/nimony/sem.nim:5873`), untuk body apa pun, bukan cuma assertion.

Yang berhasil adalah `when` plus pragma `{.error.}`, yang dinilai saat modul dianalisis dan mencetak pesan kamu
dengan posisi sumber:

```nim
when 1 + 1 != 3:
  {.error: "arithmetic broke".}
```

```
main.nim(3, 5) Error: arithmetic broke
```

Bentuk ketiga adalah `{.assert.}`, dan posisinya menentukan berhasil atau tidak. Sebagai statement di dalam body
dia diterima, dan itu bentuk yang diuji `tests/nimony/contracts/tassertpragma.nim`. Ditaruh di posisi pragma
routine, pragma yang sama membuat compiler mati: `proc half(x: int): int {.assert: x mod 2 == 0.}` berhenti
dengan `Error: unhandled exception: nifcore.nim(1875, 3) 'b.openTags.len > 0' closeTag with no matching openTag`.
Itu defect compiler yang harus di-file, bukan fitur yang harus dihindari: komentar modul assertion sendiri
menunjuk pragma itu — "a claim the contract prover may rely on is `{.assert: cond.}`"
(`lib/std/assertions.nim:33-35`) — jadi bentuk statement yang dipakai, dan posisi routine yang rusak.

Type error di dalam assertion dilaporkan lewat template, itu sebabnya diagnostiknya menyebut `assertions.nim`
alih-alih baris kamu. `assert 1` memberi `Type mismatch at [position]`, baris sumbernya, lalu
`[1] expected: bool but got: int64 (declared in …/lib/std/assertions.nim(23, 1))`. Baca `[1]` sebagai "argumen
pertama template itu".

## Flag yang menghapus assertion

`assertionsEnabled` adalah konstanta compile-time, jadi flag yang mengubahnya kelihatan di binernya. Di pin
`-d:danger` dan `-d:noAssertions` mengeluarkan setiap assertion dari hasil kompilasi, sementara `-d:release`
mempertahankannya. Program yang satu-satunya pemeriksaan adalah `assert 1 == 2` berperilaku begini:

| Flags | Output | Exit |
| --- | --- | --- |
| none | `[Assertion Failure] ` | `1` |
| `-d:release` | `[Assertion Failure] ` | `1` |
| `-d:danger` | `not reached`, program lanjut | `0` |
| `-d:noAssertions` | `not reached`, program lanjut | `0` |

Konstantanya sendiri adalah bukti termurah, dan satu-satunya yang tidak bergantung pada program yang gagal:

```nim
import std / [assertions, syncio]
echo assertionsEnabled
```

`true` tanpa flag, `true` di bawah `-d:release`, `false` di bawah `-d:danger`, `false` di bawah
`-d:noAssertions`.

Dua konsekuensi mengikuti. Gate yang jalan dengan `-d:danger` tidak membuktikan apa pun soal assertion, jadi
verifier buku ini jalan tanpa flag. Dan pemeriksaan yang kamu tulis sendiri tidak terpengaruh: `check`, `quit`, dan
counter-nya adalah kode biasa, jadi harness yang dikompilasi dengan `-d:danger` tetap mencetak `ok - …` dan tetap
mengembalikan `1` saat gagal. Yang hilang cuma `assert`.

## Menjalankan program dan membaca exit code-nya

`nimony c -r` mengompilasi, menjalankan binernya, dan mencetak baris `FAILURE:` kalau programnya keluar
non-nol. Dia tidak meneruskan kodenya. Program yang berakhir dengan `quit 3` menghasilkan:

```
before
FAILURE: nimcache/c/<hash>/main
```

dan `nimony c -r` itu sendiri keluar `1`. Biner yang disebutnya, dijalankan langsung, keluar `3`. Beda itu
penting saat test membedakan jenis kegagalan: driver-nya meratakan, binernya tidak.

Layout cache di pin itulah yang membuat path-nya bisa ditemukan. Binernya mendarat di bawah direktori sumber,
`nimcache/c/<hash>/main`, dan hash-nya diturunkan dari path modul seperti dilihat compiler — relatif ke working
directory atau ke search path — jadi dia berubah tergantung cara kamu memanggil build-nya. Script yang butuh exit
code asli men-glob `nimcache/c/*/main` setelah compile biasa lalu menjalankannya, bukan mengunci satu hash.
Bab 21 sudah memakai trik itu untuk probe soal exit code; di sini dia bedanya antara "ada yang gagal" dan
"ini yang gagal".

## Verifier buku ini

`tools/verify-samples.sh` adalah gate yang dilalui sample setiap bab. Dia script bash sekitar sembilan puluh
baris, dan bentuknya adalah bentuk kontraknya:

- Dia menolak jalan di toolchain yang salah. `nimony --version` harus dimulai `0.6.3` (`tools/verify-samples.sh:33-40`),
  dan direktori toolchain-nya harus checkout git yang `HEAD`-nya `4ba90a781b0b22d0821efaa153c129c37cef6143`
  (`:42-52`). Dua kegagalan itu keluar `2`, kode script untuk "masalah toolchain, bukan masalah sample".
- Dia men-glob `samples/*/*.nim` (`:55`), jadi sample adalah berkas satu direktori di bawah `samples/`, dan
  direktori berisi berkas pendukung di sebelahnya adalah input, bukan sample, seperti plugin di Bab 19.
- Dia mengompilasi dan menjalankan setiap berkas dari root repo dengan `nimony c -r` (`:67`), itu sebabnya
  sample yang membaca path relatif membacanya dari root, bukan dari direktorinya sendiri.
- Dia menulis setiap transkrip ke `tools/verify-samples.log`, satu blok per berkas dengan exit code di
  header-nya (`:70-74`), dan mencetak `PASS`/`FAIL` plus baris `SUMMARY` (`:76-87`). Status exit script-nya
  sendiri adalah test terakhir (`:88`).

Itu seluruh kontraknya: satu berkas per bab di bawah `samples/`, tanpa argumen, tanpa flag, exit `0` kalau
sukses, dan output yang bab cetak apa adanya. CI menjalankan script yang sama lewat `./task check`
(`.github/workflows/ci.yml:73`) dengan batas job lima belas menit, jadi sample yang hang adalah build gagal, bukan
build macet.

Aturan yang mengikutinya membosankan dan gampang dilanggar: sample tidak boleh bergantung pada apa pun yang tidak
dibawa repo. Menulis berkas itu boleh asal ke direktori temp yang sample-nya bersihkan sendiri; sample Bab 21
melakukan tepat itu. Membaca path relatif ke direktori sample sendiri tidak boleh, karena working directory
verifier-nya adalah root.

## Nim 2 delta

*Apa yang Nim 2 lakukan:* `assert` dan `doAssert` ada di `system`, blok `static:` jalan saat compile-time,
`std/unittest` menyediakan `suite`/`test`/`check`, dan `var` di level modul bisa diubah dari routine mana pun.

*Apa yang Nimony lakukan:* `assert` adalah template di `std/assertions` dan harus diimpor; `doAssert` tidak ada;
`static:` ditolak sebagai statement yang tidak didukung; tidak ada `unittest`, jadi harness-nya adalah proc dan
exit code; dan global mutable yang disentuh dari routine butuh parameter `var` atau `ptr`, blok
`{.cast(assumeSync).}:`, atau modul `{.feature: "assumeSync".}` — mendeklarasikan routine-nya `{.sync.}` tidak
cukup.

*Apa yang rusak kalau kamu mempertahankan kebiasaan lama:* `assert` tanpa import jadi `undeclared identifier`,
`static: assert` jadi `unsupported statement`, `import std / [unittest]` jadi berkas yang tidak ketemu, dan `inc`
pertama pada global di dalam helper jadi error `unsynchronized access` yang tidak ada hubungannya dengan thread.

## Samples

`samples/23-testing/testing.nim`, dijalankan di commit yang dipin:

```
nimony c -r samples/23-testing/testing.nim
```

Output yang diharapkan, yang dicetak verifier sample secara penuh:

```
ok - double of 4
ok - length of hello
ok - empty string
3 checks, 0 failed
```

Baris per baris: pemeriksaan pertama memanggil `func` yang meng-assert argumennya positif lalu menggandakannya;
yang kedua memeriksa panjang string; yang ketiga memeriksa panjang string kosong, kasus yang sering dilupakan test
suite; dan baris terakhir adalah hitungan yang dicetak driver sebelum `quit`. Programnya keluar `0`, dan itu yang
dibaca verifier.

## Cek

1. Impor cuma `std/syncio` lalu tulis `assert 1 == 1`. Harapan: `undeclared identifier: 'assert'`.
2. Tambahkan `std/assertions` dan buat assertion-nya gagal. Harapan: `[Assertion Failure] ` di stdout, exit `1`.
3. Jalankan program yang sama dengan `-d:danger`. Harapan: tidak ada output dari assertion, exit `0`.
4. Cetak `assertionsEnabled` tanpa flag dan dengan `-d:noAssertions`. Harapan: `true`, lalu `false`.
5. Taruh `inc counter` untuk `var` module-level di dalam proc. Harapan: error `unsynchronized access`.
6. Bungkus baris yang sama dengan `{.cast(assumeSync).}:`. Harapan: terkompilasi.
7. Tulis `static: assert 1 == 1`. Harapan: `unsupported statement: staticstmt`.
8. Tulis `when 1 + 1 != 3: {.error: "broke".}`. Harapan: build berhenti dengan pesan kamu dan nomor baris.

## Chapter checklist

draft 2026-11-13 · tech_review 2026-11-13 · editorial_pass 2026-11-13 · frozen 2026-11-13
