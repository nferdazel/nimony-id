---
chapter: 3
title: Values, Names, and Mutability
job: Introduce `let`, `var`, `const`, lexical scope, and the fact that names are case-sensitive.
nimony_version: 0.6.3
nimony_commit: 4ba90a781b0b22d0821efaa153c129c37cef6143
toolchain: /Users/sachiel/.local/opt/nimony/4ba90a7
host_compiler: /Users/sachiel/.local/opt/nim-2.4.0
status: frozen
tech_review: Momo 2026-11-12
editorial_pass: 2026-11-12
samples: ["samples/03-values-names-mutability/values.nim"]
glossary_added: ["let variable", "case-sensitive identifier", "scope (of a name)", "zero value"]
---

# 3. Values, Names, and Mutability

## Untuk apa chapter ini

Nimony memberimu tiga cara menempelkan nama pada sebuah nilai, dan ketiganya cuma berbeda di satu pertanyaan:
*bisakah nama ini ditulis lagi setelah baris yang mendeklarasikannya lewat?* `const` bilang tidak, dan nilainya
ditetapkan sebelum program berjalan. `let` bilang tidak, dan nilainya ditetapkan saat deklarasinya dijalankan.
`var` bilang bisa.

Itu seluruh aturannya, dan layak dipelajari persis sekarang karena hampir semua chapter berikutnya jadi lebih
mudah dibaca begitu kamu tahu nama mana yang boleh berubah. Chapter ini juga membahas dua hal tentang nama itu
sendiri yang berbeda dari Nim 2: ejaannya harus persis, dan sebuah nama hanya hidup di block yang mendeklarasikannya.

## Tiga deklarasi, tiga janji

### `const`: ditetapkan sebelum program berjalan

Sebuah `const` terikat pada constant expression. `doc/language.md` di pin membatasinya ke literal, operator
bawaan, konstanta yang sudah dideklarasikan sebelumnya, dan pemanggilan routine yang semua argumennya bisa
dievaluasi saat compile time (`doc/language.md:24-31`). Nilainya selesai saat kompilasi, jadi ketika programmu
mulai berjalan tidak ada lagi yang perlu dihitung.

```
const Language = "nimony"
const Banner = Language & " / names and values"
```

Penyambungan string itu terjadi saat kompilasi. Pemanggilan routine juga, asal tidak ada bagian yang membutuhkan
program yang sedang berjalan:

```
proc double(x: int): int = x * 2
const Twice = double(4)          # 8, computed while compiling
```

`doc/language.md:1711-1733` menambah satu hal lagi: simbol konstanta boleh dipakai sebagai constant expression,
dan bagian nilai dari tiap konstanta membuka scope-nya sendiri, jadi nama yang dideklarasikan di dalamnya tidak
bocor ke baris berikutnya.

### `let`: satu kali penetapan

`let` mengikat nilai sekali, di titik deklarasinya dijalankan, lalu menolak setiap penulisan sesudahnya. Ini
deklarasi yang paling sering kamu pakai: kebanyakan nilai di program yang bentuknya bagus dibaca berkali-kali dan
ditulis sekali.

```
let limit = 3
```

Menulis ke sana adalah compile error, bukan error saat runtime:

```
Error: invalid reassignment to `let` variable
```

`doc/language.md:1640-1655` menambahkan dua konsekuensi yang layak kamu tahu sebelum kaget. Sebuah `let`
bukan l-value, jadi ia tidak bisa dilewatkan ke parameter `var` dan alamatnya tidak bisa diambil. Dan karena
nilainya immutable sejak awal, sebuah `let` wajib punya initializer — satu-satunya pengecualian adalah deklarasi
yang mengambil nilainya dari kode native lewat pragma bergaya `importc`.

### `var`: yang boleh ditulis ulang

`var` mendeklarasikan nama yang bisa diubah. Inilah deklarasi yang berubah, dan di Nimony ini juga yang paling
banyak diperiksa:

```
var total = 0
for i in 1 .. limit:
  total = total + i
```

Sebuah `var` di level module mulai dari zero value tipenya, ditulis atau tidak ditulis: `int` terbaca `0`,
`string` terbaca `""`, dan object yang tersusun dari keduanya terbaca serba nol.

Di dalam routine, aturannya yang tertulis di guide (`doc/language.md:1591-1630`): sebuah local harus terbukti
sudah ditulis sebelum dibaca. `var chosen: int` yang tidak ditulis di jalur mana pun menghentikan build dengan
`Error: cannot prove that chosen has been initialized`; menulis di kedua cabang memenuhi analisisnya, menulis di
satu cabang saja tidak.

Pemeriksaannya soal bukti, bukan soal tipe: `int` juga gagal di situ. Kasus yang berbeda adalah `var` di level
module dengan tipe yang tidak punya default value — itu langsung ditolak di deklarasinya:

```
Error: 'base' is of type 'ref int64 not nil', which has no default value (it contains a not-nil pointer): give it an initial value
```

`{.noinit.}` mematikan pemeriksaan itu dan menyerahkan storage mentahnya kepadamu: dibaca sebelum ditulis, isinya
apa pun yang kebetulan ada di memori, bukan `0`.

## Nama peka huruf besar-kecil

Ini perbedaan pertama yang nyata dari Nim 2, dan perbedaannya cuma di ejaan.

Nimony case-sensitive: dua identifier yang beda huruf besar-kecil adalah dua identifier (`doc/language.md:7`;
`doc/differences.md:22`). Jadi ini ter-compile, dan kedua nama tetap hidup:

```
let step = 2
let Step = 5
echo step      # 2
echo Step      # 5
```

Tidak ada "mirip-mirip". Memakai ejaan yang tidak ada adalah error di titik pemakaiannya:

```
Error: undeclared identifier: my_value
```

padahal deklarasinya `let myValue = 1`. Alasan perubahan ini disebut terus terang di language guide —
kesederhanaan implementasi — dan bisa berubah di masa depan, yang justru jadi alasan buku ini menyebutnya di pin,
bukan sebagai kebenaran permanen.

Kalau kamu mem-port sebuah module dan butuh aturan Nim 2 kembali, jalan keluarnya ada dan sifatnya per module:

```
{.feature: "ignoreStyle".}
```

Dengan baris itu di atas, `myValue`, `my_value` dan `myvalue` menunjuk ke simbol yang sama. Itu switch
kompatibilitas, bukan gaya yang diajarkan buku ini; kode yang ditulis baru sebaiknya mengeja nama dengan persis.

## Di mana sebuah nama hidup

Sebuah identifier berlaku dari titik deklarasinya sampai akhir block tempat ia dideklarasikan
(`doc/language.md:4752-4765`). Block yang lebih dalam boleh mendeklarasikan ejaan yang sama lagi, dan di dalam
block itu deklarasi dalamnya yang kamu dapat:

```
block:
  let step = 100
  echo step     # 100

echo step       # 2 — the outer let, untouched
```

Dua aturan membuat ini tidak jadi teka-teki. Sebuah identifier tidak bisa dideklarasikan ulang di block yang
*sama*, hanya di block yang bersarang — compilernya bilang `Error: attempt to redeclare: step`. Dan nama khusus
`_` tidak pernah masuk ke scope sama sekali, jadi `let _ = 123` dievaluasi lalu dibuang, dan kamu boleh menulisnya
ulang sesering yang kamu mau.

## Nim 2 delta: ejaan dan kapan `const` dihitung

> **Yang dilakukan Nim 2.** Identifier tidak peka gaya penulisan: `myValue`, `my_value` dan `myvalue` adalah satu
> nama, dan ejaan campur dalam satu berkas itu normal. Nilai `const` dievaluasi oleh evaluator compile-time yang
> terbatas.
>
> **Yang dilakukan Nimony.** Identifier harus persis (`doc/language.md:7`), dengan `{.feature: "ignoreStyle".}`
> tersedia per module untuk kode hasil port. `const` dievaluasi oleh mesin compile-time yang menerima pemanggilan
> routine asal semua argumennya bisa dievaluasi saat kompilasi (`doc/language.md:24-31`). Itulah sebabnya
> `const Twice = double(4)` bekerja.
>
> **Apa yang rusak kalau kebiasaannya dipertahankan.** Kode hasil port berhenti di `undeclared identifier` pada
> varian ejaan yang dulu diterima Nim 2 — perbaikannya mekanis, tapi datangnya sebagai seratus error, bukan satu.
> Dan `const` yang nilainya bergantung pada sebuah `var` tetap compile error, jadi menghitung "konstanta" dari
> data runtime tetap mustahil; obatnya `let`, bukan pragma.

## Sample

- `samples/03-values-names-mutability/values.nim` — satu program yang mendeklarasikan ketiga bentuk, menghitung
  `const` lewat pemanggilan routine, menjaga dua nama yang beda huruf besar-kecil tetap hidup, membayangi salah
  satunya di block bersarang, dan mendeklarasikan `var` di level module tanpa nilai yang kemudian ditulis oleh
  kedua cabang. Dibuktikan oleh `tools/verify-samples.sh`:

  ```
  PASS samples/03-values-names-mutability/values.nim exit=0
  ```

  Output yang diharapkan, berurutan — verifier memeriksa compile, run dan exit code, bukan stdout, jadi daftar
  inilah pemeriksaannya:

  ```
  nimony / names and values
  8
  6
  2
  5
  100
  2
  1
  ```

## Latihan

1. Deklarasikan `let n = 1` lalu `n = 2`. Harapan: compile error `invalid reassignment to \`let\` variable`,
   dilaporkan di assignment-nya, bukan di deklarasinya.
2. Deklarasikan `let step = 2` dua kali di block yang sama. Harapan: `attempt to redeclare: step`. Pindahkan yang
   kedua ke dalam `block:` dan keduanya ter-compile.
3. Deklarasikan `let myValue = 1`, lalu `echo my_value`. Harapan: `undeclared identifier: my_value`. Tambahkan
   `{.feature: "ignoreStyle".}` di atas deklarasinya dan jalankan lagi: harapan, ia ter-compile dan mencetak `1`.
4. Hitung `const Twice = double(4)` dengan `double` sebuah proc satu baris. Harapan: ter-compile dan mencetak `8`.
   Lalu ganti argumennya dengan sebuah `var` dan build lagi. Harapan: compile error di baris `const` — sebuah
   `const` tidak boleh bergantung pada data runtime.
5. Tulis `var chosen: int` di dalam sebuah proc tanpa menulisnya di jalur mana pun, lalu baca. Harapan:
   `cannot prove that chosen has been initialized`. Lalu pastikan setiap jalur menulis lebih dulu, dan build lagi:
   harapan, ia ter-compile. Perhatikan bahwa blok yang sama di level module tidak gagal — di sana nilainya `0`.

## Checklist chapter

draft 2026-11-12 · tech_review Momo 2026-11-12 · editorial_pass 2026-11-12 · frozen 2026-11-12
