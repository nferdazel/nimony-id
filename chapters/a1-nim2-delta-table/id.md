---
appendix: A
title: Nim 2 to Nimony: the delta table
job: One consolidated table of everything at the pin that a Nim 2 habit gets wrong, each row traceable to the chapter that proved it.
nimony_version: 0.6.3
nimony_commit: 4ba90a781b0b22d0821efaa153c129c37cef6143
toolchain: ~/.local/opt/nimony/4ba90a7
host_compiler: ~/.local/opt/nim-2.4.0
status: frozen
tech_review: assembled from Chapters 3-24, each tech-reviewed by Momo 2026-11-12 to 2026-11-13; introduces no new claim
editorial_pass: 2026-11-13
samples: []
glossary_added: []
---

# Nim 2 ke Nimony: tabel delta

## Untuk apa lampiran ini

Setiap bab yang mengubah kebiasaan Nim 2 ditutup dengan kotak *Nim 2 delta*. Dibaca satu per satu, kotak itu
urutan mengajar yang benar dan urutan mencari yang salah: orang yang mem-port satu berkas ingin satu halaman yang
mengatakan apa saja yang berpindah. Halaman ini halaman itu.

Tidak ada yang baru di sini. Setiap baris adalah kotak delta satu bab yang dipadatkan jadi dua klausa
pertentangan, dan kolom terakhir menyebut bab yang tech review-nya memutuskan baris itu, plus baris sumber yang
dikutip review tersebut kalau ada. Bab adalah sumber kebenaran untuk kalimatnya; berkas sumber adalah sumber
kebenaran untuk perilakunya. Kalau kolom sumber cuma menyebut bab tanpa baris, perilakunya sudah dibuktikan
dengan run di pin dan berkas `review.md` bab itu menyimpan probe-nya.

## Cara membaca baris

*Nim 2.4.0* adalah yang terjadi pada sumber yang sama di tarball resmi Nim 2.4.0. *Nimony di `4ba90a7`* adalah yang
terjadi di toolchain yang disematkan, `nimony 0.6.3`. Dua kolom itu bukan rekomendasi; jalan keluarnya ada di bab,
bukan di tabel ini.

Ada dua jenis baris di tabel ini, dan keduanya terbaca sama tapi gagal berbeda. Baris **dihapus** berarti baris
Nim 2-nya tidak lagi bisa dikompilasi. Baris **berubah** berarti baris itu masih bisa dikompilasi dan sekarang
melakukan hal lain, dan yang ini yang mahal.

## Ejaan dan konstanta

| Area | Nim 2.4.0 | Nimony di `4ba90a7` | Ditetapkan oleh |
| --- | --- | --- | --- |
| Ejaan identifier (berubah) | Tidak peka gaya: `myValue`, `my_value` dan `myvalue` satu nama. | Ejaan persis; `{.feature: "ignoreStyle".}` mengembalikan bacaan lama per modul. | Bab 3; `doc/language.md:7` |
| Isi `const` (berubah) | Dievaluasi evaluator compile time yang terbatas. | Pemanggilan rutin diterima selama semua argumennya bisa dievaluasi saat kompilasi, jadi `const Twice = double(4)` bisa dibangun. | Bab 3; `doc/language.md:24-31` |
| `const` yang menyebut `var` (dihapus) | Error kompilasi, dilaporkan di baris `const`. | Tetap error, sekarang dilaporkan sebagai `undeclared identifier` terhadap `var` itu. | Bab 3; watch list ERRATA |

## Angka

| Area | Nim 2.4.0 | Nimony di `4ba90a7` | Ditetapkan oleh |
| --- | --- | --- | --- |
| Overflow bertanda (berubah) | Memunculkan `OverflowDefect` saat pemeriksaan hidup, yang berarti build debug crash dan build rilis wrap. | Selalu wrap; backend C dibangun dengan `-fwrapv`. | Bab 4; `doc/differences.md:24`, `doc/language.md:76-90` |
| Menyadari overflow (dihapus) | `try`/`except OverflowDefect`, atau `overflowChecks: off`. | `try`-nya jadi kode mati yang tetap kompil; jalan eksplisitnya `{.keepOverflowFlag.}` plus `overflowFlag()`. | Bab 4; `doc/language.md:76-90` |
| Konstanta yang overflow | Tidak diukur untuk buku ini. | `expression overflow at compile time`. | Bab 4, Bab 18 |

## String dan C string

| Area | Nim 2.4.0 | Nimony di `4ba90a7` | Ditetapkan oleh |
| --- | --- | --- | --- |
| Terminator (dihapus) | Ada `'\0'` di belakang karakter terakhir; `s[s.len]` membacanya. | Tanpa terminator; `s[s.len]` menghentikan program dengan `AssertionDefect`. | Bab 5; `doc/differences.md:15-18` |
| `cstring(s)` pada `var string` (dihapus) | Cast. | Ditolak: hanya literal string yang bisa dikonversi; `toCString(s)` menulis nolnya saat diminta dan menolak `let`. | Bab 5, Bab 22; `lib/std/system/stringimpl.nim:1095-1109` |
| Menulis terminator kembali (berubah) | Otomatis di dalam konversi. | `toCString(var string)` bisa membuat buffer unik dulu; `fromCString` menyalin balik. | Bab 5; `lib/std/system/stringimpl.nim:1095-1109` |

## Alur kendali

| Area | Nim 2.4.0 | Nimony di `4ba90a7` | Ditetapkan oleh |
| --- | --- | --- | --- |
| `break` tanpa label (berubah) | Bisa keluar dari `block` yang berada di dalam loop. | Selalu loop terdalam; `block` bernama plus `break <nama>` mengatakan apa yang ditinggalkan, dan `{.feature: "anonBlockBreaks".}` mengembalikan bacaan lama per modul. | Bab 6; `doc/differences.md:23` |
| `elif` setelah cabang `of` (dihapus) | Diterima. | Ditolak dengan petunjuk menaruh `if` di dalam `else`. | Bab 6; `src/nimony/sem.nim:3305` |
| Nilai `range` (berubah) | Dijaga saat runtime, jadi nilai yang benar diterima sejauh apa pun perjalanannya. | Dibuktikan contracts engine saat kompilasi; nilai yang tidak terbukti jadi error walaupun saat jalan ia ada di rentang. | Bab 7; `doc/differences.md:58-62` |
| Cara menulis buktinya (berubah) | Guard apa pun yang jalan lebih dulu. | Terlihat di tempat nilainya dipakai, dan pada parameter berupa dua perbandingan: `n in 0..9` tidak dihitung. | Bab 7; watch list ERRATA |

## Prosedur dan tipe

| Area | Nim 2.4.0 | Nimony di `4ba90a7` | Ditetapkan oleh |
| --- | --- | --- | --- |
| Overload `var T` (dihapus) | Dua accessor `[]`, satu pada `var Container` yang mengembalikan `var Element`, satu pada `Container` yang mengembalikan `lent Element`. | Satu accessor, polimorfik pada lokasi; pasangan `var`/non-`var` jadi satu ambiguitas. | Bab 9; `doc/differences.md:31-43` |
| Hasil `var` (berubah) | Dikembalikan dari field inline milik parameter by-value. | Ditolak dengan `cannot borrow from b.v` kecuali hasilnya punya jalur pinjam: parameter `var`, `out` atau `lent`, atau indireksi seperti field `seq`. | Bab 9; `src/nimony/derefs.nim:466-468`, `:258-314` |
| Tulis lewat indeks (dihapus) | Otomatis lewat overload `var`. | Butuh `[]=` yang kamu deklarasikan sendiri; tanpanya assignment gagal dengan daftar kandidat bawaan. | Bab 9; `src/nimony/semcall.nim:1436` |
| `echo` pada tipe buatan sendiri (berubah) | Menemukan dan memakai `$` milikmu, mencetak `P1`. | Menulis nilainya sendiri; `$` milikmu adalah rutin yang kamu panggil, jadi tulis `echo $p`. | Bab 11; `doc/language.md:466-471` |
| Membaca field varian (berubah) | `FieldDefect: field 'width' is not accessible …` kalau cabangnya tidak aktif. | Tidak diperiksa: bacaannya mengembalikan isi union. | Bab 12; watch list |
| Meng-assign discriminator (berubah) | `FieldDefect: assignment to discriminant changes object branch`. | Penulisan field biasa; byte lamanya tetap. | Bab 12; watch list |

## Pointer, kepemilikan dan error

| Area | Nim 2.4.0 | Nimony di `4ba90a7` | Ditetapkan oleh |
| --- | --- | --- | --- |
| Kemungkinan nil (dihapus) | Semua `ref`, `ptr`, `pointer` dan `cstring` boleh nil, dan deklarasinya dinolkan, jadi `var x: ref int` di level modul legal dan diam-diam nil. | Ada di tipe: `ref T` biasa tidak bisa nil, pointer bukan-nil tidak punya nilai bawaan, dan dereference tanpa penjagaan tidak kompil. Bentuk nullable-nya `nil T`. | Bab 13; `doc/lenientnils.md:141-155` |
| Nil sebagai "tidak ada" (berubah) | Argumen nil. | Parameternya harus ditulis `nil T`. | Bab 13 |
| Aliasing dalam satu panggilan (dihapus) | `take(s, s)` kompil dan mencetak `1`. | `mutable argument aliases with immutable parameter`. | Bab 14; `src/nimony/contracts_fir.nim:4340-4351` |
| Mutasi saat iterasi (berubah) | Kompil, lalu mati dengan `the length of the seq changed while iterating over it`. | `'s' is borrowed and cannot be mutated`, di baris itu. | Bab 14 |
| `move` dan `sink` (berubah) | Perilaku sama, termasuk nilai kosong yang ditinggal. | Sama; penolakan `ensureMove` diberi kalimat berbeda (`not the last usage of: a`). | Bab 14; `src/hexer/duplifier.nim:1611`, `lib/std/system.nim:123-126` |
| Exception (dihapus) | `raise newException(IOError, "msg")`, `.msg`, stack trace, `except IOError as e`. | Nilai `ErrorCode`: `raise IOError`, tanpa alokasi, tanpa pesan, tanpa trace; `.msg` jadi error kompilasi. | Bab 15; `doc/porting.md:106` (ERRATA) |
| Menyatakan apa yang raise (berubah) | `{.raises: [].}` opsional. | Bawaannya non-raising; rutin yang raise mengatakan `{.raises.}` dan pemanggilnya duduk di `try`/`except`. | Bab 15 |

## Modul, global dan visibilitas

| Area | Nim 2.4.0 | Nimony di `4ba90a7` | Ditetapkan oleh |
| --- | --- | --- | --- |
| `echo` tanpa import (dihapus) | `system` disuntik ke mana-mana. | Import `std/syncio` sebelum `echo` pertama. | Bab 16 |
| Global yang bisa diubah dari rutin (dihapus) | Diizinkan. | Ditolak: kirim sebagai parameter `var` atau `ptr`, pakai blok `{.cast(assumeSync).}:`, atau modul `{.feature: "assumeSync".}`. Menandai rutinnya `{.sync.}` tidak cukup. | Bab 16, Bab 23 |
| Import di dalam rutin (berubah) | Ditolak: import duduk di level teratas. | Diterima, dan berlaku untuk seluruh modul, jadi panggilan di rutin lain menemukan nama itu walaupun prosedur pemegang import tidak pernah jalan. | Bab 16; `doc/language.md:4646` (ERRATA), `src/nimony/sem.nim:5947-5953` |

## Generic, template dan macro

| Area | Nim 2.4.0 | Nimony di `4ba90a7` | Ditetapkan oleh |
| --- | --- | --- | --- |
| Type class di posisi parameter (berubah) | Generic implisit, disubstitusi per pemanggilan. | Diterima front end lalu membuat backend crash pada instansiasi kedua; tulis `[T: Addable]`. | Bab 17; `src/nimony/sigmatch.nim:1825-1827` |
| Parameter `typed` pada template (berubah) | Jalan; Nim 2.4.0 mencetak `41` dan `42` untuk dua template yang ditolak pin. | Diterima dan tidak bisa dipakai; tulis `untyped` atau tipe sungguhan. | Bab 18 |
| Pembangkitan kode (berubah) | `macro` yang mengembalikan `NimNode` dari `std/macros`. | Plugin: program terpisah, NIF masuk dan NIF keluar, tanpa pohon di dalam proses. `macro` dengan parameter `untyped` masih kompil di pin — surface kompatibilitas, bukan jalan yang diajarkan. | Bab 18, Bab 19; `doc/differences.md:19` |
| `{.dirty.}` (berubah) | Jalan keluar untuk body yang butuh nama pemanggil. | Inert tanpa `{.feature: "untyped".}`, dan setelah itu menyuntik dua arah. | Bab 18; `src/nimony/semdecls.nim:1183` |

## Standard library, berkas dan proses

| Area | Nim 2.4.0 | Nimony di `4ba90a7` | Ditetapkan oleh |
| --- | --- | --- | --- |
| `std/strformat` dan `std/re` (dihapus) | Import biasa. | Tidak ada di pin; `%` dari `std/strutils` menutup yang pertama, dan `re` tidak punya pengganti. | Bab 20 |
| Penyambungan sekuens (dihapus) | `xs & ys`. | `&` hanya untuk string; `concat` dari `std/sequtils`. | Bab 20 |
| Atomic (berubah) | Tipe pembungkus, `Atomic[int]`, dengan anggota `load()` dan `store()`. | Operasi pada `var` biasa; turun ke builtin `__atomic_*`. | Bab 20 |
| `removeFile` (berubah) | `std/os.removeFile(file: string)`, diam kalau berkasnya tidak ada. | `std/files.removeFile(file: Path)`, `{.raises.}`, `tryRemoveFile` untuk alasannya — dan masih diam kalau berkasnya tidak ada, jadi deltanya modul dan tipenya, bukan toleransinya. | Bab 21; `lib/std/files.nim:65`, `:68-70` |
| `quit(msg)` (berubah) | Menulis pesan ke stderr. | Menulisnya ke stdout. | Bab 21; `doc/stdlib.md:232` (ERRATA) |

## Batas C

| Area | Nim 2.4.0 | Nimony di `4ba90a7` | Ditetapkan oleh |
| --- | --- | --- | --- |
| `cstring(var string)` (dihapus) | Konversi langsung. | Hanya literal string yang bisa dikonversi; `toCString` untuk `var`, dan tidak ada jalan untuk `let`. | Bab 22 |
| Kemungkinan nil tipe C (berubah) | `ptr`, `pointer` dan `cstring` nullable kecuali dinyatakan lain. | Tipe telanjangnya non-null; tipe nullable ditulis `nil cstring`. | Bab 22 |
| `$` untuk `cstring` (dihapus) | Terjangkau dari `system`. | Datang dari `std/strutils`. | Bab 22 |
| Array argumen (dihapus) | `allocCStringArray`. | `alloc0` plus `cast` ke `ptr UncheckedArray[nil cstring]`, dan `dealloc` di akhir. | Bab 22 |

## Pengujian dan konkurensi

| Area | Nim 2.4.0 | Nimony di `4ba90a7` | Ditetapkan oleh |
| --- | --- | --- | --- |
| `assert` dan `doAssert` (berubah) | Template di `system`. | `assert` ada di `std/assertions` dan wajib di-import; `doAssert` tidak ada. | Bab 23; `lib/std/assertions.nim:3` |
| Blok `static:` (dihapus) | Jalan saat kompilasi. | `unsupported statement: staticstmt`; pakai `when` dengan `{.error.}`. | Bab 23 |
| `std/unittest` (dihapus) | `suite`, `test`, `check`. | Tidak ada: `lib/std/` tidak membawa `unittest.nim`. Harness-nya proc dan exit code. | Bab 23; watch list ERRATA |
| `async` dan `await` (dihapus) | `std/asyncdispatch`, future, `await`. | Proc `.passive`, `Continuation`, `delay` dan `complete`; `await` jadi identifier yang tidak dikenal. | Bab 24; `doc/differences.md:8-9` |
| `thread` dan `spawn` (berubah) | Prosedur thread untuk kerja paralel. | Mekanisme `.passive` yang sama, dan satu continuation bisa diserahkan ke pool. `complete` menjalankan rantai sampai habis, jadi panggilan dari kode biasa menunggu. | Bab 24 |

## Yang sengaja tidak masuk tabel ini

Empat golongan sengaja ditinggalkan, dan alasan meninggalkannya adalah bagian dari isinya.

**Niat desain.** Halaman desain menggambarkan bahasa yang lebih jauh dari pin. `doc/differences.md` menaruh
"macro diganti plugin" di bagian masa depan, jadi `macro` yang masih jalan adalah surface kompatibilitas; baris
tentang apa yang akan dihapus desain adalah janji yang pin tidak bisa tepati. Semua baris di atas adalah perilaku
yang diamati atau dinyatakan di `4ba90a7`.

**Diagnostik yang tidak ada.** Pemeriksaan yang tidak eksis adalah kandidat cacat di `ERRATA.md`, bukan delta:
sumber Nim 2-nya kompil di kedua kompiler, dan perbaikan untuk pembaca sama di keduanya. `delay()` tanpa titik
suspensi adalah contoh hidupnya — assertion dari code generator, bukan diagnostik, sudah di-file ke
`nim-lang/nimony#2985` dengan perbaikannya di `nim-lang/nimony#2988`.

**Perilaku yang identik di kedua kompiler.** `cstring"a\nb"` juga empat byte di Nim 2.4.0, jadi literal `cstring`
yang mentah adalah celah dokumentasi yang diwarisi pin, bukan delta. Ia ada di `ERRATA.md` dan di teks Bab 22, dan
tidak punya baris di sini.

**Perilaku per platform.** Beberapa baris hanya diukur di macOS arm64 — pemisahan `const` pada callback C, nama
library `dynlib`, nilai `errno` setelah panggilan yang gagal. Bab yang mengukurnya menyebutkannya; tabel ini tidak
menggeneralisasi.
