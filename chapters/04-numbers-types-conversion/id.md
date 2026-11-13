---
chapter: 4
title: Numbers, Types, and Conversion
job: Cover integers, floats, booleans, characters, ranges, and explicit conversion, including the fact that integer overflow wraps instead of raising.
nimony_version: 0.6.3
nimony_commit: 4ba90a781b0b22d0821efaa153c129c37cef6143
toolchain: ~/.local/opt/nimony/4ba90a7
host_compiler: ~/.local/opt/nim-2.4.0
status: frozen
tech_review: Momo 2026-11-12
editorial_pass: 2026-11-12
samples: ["samples/04-numbers-types-conversion/numbers.nim"]
glossary_added: ["integer type", "floating-point type", "narrowing conversion", "wrapping overflow", "range type"]
---

# Angka, Tipe, dan Konversi

## Untuk apa chapter ini

Setiap nilai dalam program Nimony punya tepat satu tipe, dan compiler sudah menyimpulkannya sebelum kamu
menyebutnya. Untuk angka, kesimpulan itu menentukan tiga hal yang langsung terasa: seberapa banyak ruang yang
dimiliki nilai itu, apa yang terjadi ketika sebuah perhitungan butuh ruang lebih besar dari itu, dan apakah dua
nilai bertipe berbeda boleh bertemu dalam satu ekspresi.

Chapter ini membahas tipe numerik, dua tipe non-numerik yang setiap hari kamu pegang di variabel — `bool` dan
`char` — dan satu tempat di mana tipe bukan sekadar label melainkan bukti: `range`. Konversi dapat bagiannya
sendiri karena Nimony relatif sedikit melakukannya untukmu.

## Tipe integer

`int` adalah integer yang kamu pakai sebagai default. Lebarnya sama dengan pointer pada mesin yang kamu compile
(`doc/language.md:59-66`), jadi di host 64-bit `sizeof(int)` adalah `8` dan jangkauannya dari `low(int)` sampai
`high(int)`. Kalau kamu butuh lebar yang tidak bisa diubah platform, sebut namanya: `int8`, `int16`, `int32`,
`int64`, dan keluarga unsigned `uint`, `uint8`, `uint16`, `uint32`, `uint64` (`doc/language.md:63-71`). Tabel yang
sama memberi tiap tipe sufiks literal, jadi literal-nya sendiri bisa membawa lebar:

```
let small = 127'i8
let big = 9223372036854775807'i64
let byte = 255'u8
```

Satu kebiasaan dari C sebaiknya ditinggalkan di sini: `int` bukan "32 bit, kira-kira". Ia adalah tipe yang
lebarnya mengikuti target, dan kode yang butuh lebar pasti menyebutkannya. Tipe unsigned sebagian besar ada untuk
batas C, yaitu Chapter 22; untuk aritmetika di programmu sendiri, `int` adalah default-nya.

## Apa yang terjadi saat integer overflow

Aritmetika signed wrap. `doc/language.md:76-90` menyatakan aturannya di pin: ketika hasil matematis `+`, `-`, `*`
atau unary `-` pada tipe signed `T` tidak muat di `T`, hasilnya adalah nilai itu modulo `2^bits` dalam two's
complement. Jadi `127'i8 + 1'i8` adalah `-128'i8`, `high(int64) + 1` adalah `low(int64)`, dan tidak ada error —
baik saat compile time maupun runtime.

Itulah seluruh bedanya dengan Nim 2, dan ini bukan konfigurasi: `doc/differences.md:24` mencatat bahwa overflow
signed wrap **alih-alih** melempar `OverflowDefect`, dan bahwa backend C dikompilasi dengan `-fwrapv` supaya
compiler C tidak boleh menganggap sebaliknya. Tidak ada yang dilempar untuk kamu selamatkan.

Konsekuensinya mudah diucapkan dan mudah dilupakan: angka yang kelihatan mustahil adalah cacat di aritmetika-mu,
bukan sinyal dari bahasa. Kalau sebuah nilai penting, periksa batasnya sebelum operasi, atau minta flag-nya.
`{.keepOverflowFlag.}` menjaga flag CPU tetap hidup di sekitar satu blok dan `overflowFlag()` melaporkan apakah
`+`, `-` atau `*` signed terakhir di dalamnya mengalami overflow (`doc/language.md:92-104`):

```
var top = 9223372036854775807'i64
var wrapped: int64
var overflowed = false
{.keepOverflowFlag.}:
  wrapped = top + 1'i64
  overflowed = overflowFlag()
# wrapped is -9223372036854775808, overflowed is true
```

Constant expression adalah pengecualiannya, dan itu compile error, bukan wrap. `const X = 127'i8 + 1'i8`
menghentikan build dengan `Error: expression overflow at compile time: 127'i8 + 1'i8` (`doc/language.md:98-104`,
string-nya di `src/nimony/expreval.nim:466`), karena konstanta yang tidak bisa memuat nilainya sendiri adalah
kesalahan di sumber, bukan kondisi runtime.

## Dua keluarga angka yang tidak bercampur

`float` adalah tipe floating-point umum dan lebarnya 64 bit; `float32` dan `float64` ditulis eksplisit ketika
lebarnya penting (`doc/language.md:126-140`). Keduanya mengikuti IEEE 754, dan pengecualian IEEE — invalid, division
by zero, overflow, underflow, inexact — diabaikan saat eksekusi (`doc/language.md:142`).

Integer dan float tidak saling mengonversi dengan sendirinya. `doc/language.md:139-140` mengatakannya lugas:
"Integer types are not converted to floating-point types automatically and vice versa." Yang akan dilakukan
compiler adalah menerima literal, karena literal numerik belum punya tipe sampai konteks memberinya satu
(`doc/language.md:1106-1108`; relasi Convertible yang dilewatinya mulai di `:1097`):

```
var good: float = 3        # fine: the literal becomes 3.0
var i = 3
var bad: float = i         # Error: type mismatch: got: int64 but wanted: float64
```

Asimetri yang sama berlaku ke arah sebaliknya: `var n: int = 3.0` ditolak dengan `type mismatch: got: float64 but
wanted: int64`. Literal menyesuaikan diri dengan tipe yang kamu minta; sebuah nilai tidak.

Pembagian mengikuti dua keluarga itu. `/` selalu menghasilkan float, bahkan ketika kedua operand integer,
sementara `div` dan `mod` tetap di tipe integer:

```
echo 7 div 2      # 3
echo 7 mod 2      # 1
echo 6 / 2        # 3.0
```

`div` memotong ke arah nol, jadi `-7 div 2` adalah `-3`, bukan `-4`. `mod` mengambil tanda dari dividend:
`-7 mod 3` adalah `-1`. Tidak satu pun dari kedua operator itu bisa ditukar dengan `/`, dan menulis `7 / 2` di
tempat yang kamu maksud `3` adalah cara diam-diam untuk mengakhiri chapter berikutnya dengan float.

## Konversi eksplisit

Konversi ditulis sebagai pemanggilan pada nama tipe (`doc/language.md:2138-2160`):

```
echo int(3.9)      # 3
echo int(-3.9)     # -3
echo float(3)      # 3.0
```

Float ke integer memotong ke arah nol — `int(-3.9)` adalah `-3`, bukan `-4` — jadi pembulatan adalah keputusanmu,
bukan keputusan konversi. Konversi juga cara kamu menyempitkan tipe (narrowing), dan narrowing tidak memeriksa
apa pun: `int8(200)` ter-compile dan mencetak `-56`. `doc/language.md:2159-2162` menjelaskan kebijakannya untuk
target unsigned, di mana konversi memang tidak dicek demi interoperabilitas C; di pin, kesunyian yang sama berlaku
untuk narrowing signed, dan test suite pin bergantung padanya — `int8(wb)` adalah `-56`
(`tests/nimony/errmsgs/tconvsignchange.nim:84-88`). Kalau nilainya mungkin tidak muat, uji dulu sebelum kamu
mengonversinya.

Jangan meraih `toInt` atau `toFloat` di sini. `doc/language.md:2144-2148` menyebutnya sebagai idiom Nim, tapi di
`4ba90a7` keduanya hanya ada untuk `Rational[T]` (`lib/std/rationals.nim:137,141`), bukan untuk `float` atau `int` —
`3.7.toInt` gagal dengan `undeclared field: 'toInt' for type float64`. Bentuk konversi itulah yang ada.

## Boolean dan karakter

`bool` memuat `true` dan `false` dan berukuran satu byte (`doc/language.md:149-172`). Nilai ordinalnya tetap:
`ord(false)` adalah `0` dan `ord(true)` adalah `1`, dan operator biasanya — `not`, `and`, `or`, `xor` serta
perbandingan — didefinisikan di atasnya. `and` dan `or` short-circuit, itulah sebabnya `p != nil and p.next != nil`
aman ditulis.

`char` juga satu byte, dan byte itu adalah *bagian* dari sebuah karakter UTF-8, bukan sebuah karakter
(`doc/language.md:175-181`). Apa pun di luar ASCII tidak akan muat di satu `char`. Dua fungsi yang kamu butuh
adalah `ord`, yang mengubah `char` menjadi nilai numeriknya, dan `chr`, yang mengubah angka di `0..255` kembali
menjadi `char` (`lib/std/system.nim:249-251`):

```
echo ord('a')     # 97
echo chr(97)      # a
echo 'a' < 'b'    # true
```

Perbandingan bekerja karena `char` bersifat ordinal: `'a' < 'b'` benar dengan alasan yang sama `97 < 98` benar.

## Range

Range adalah tipe yang batasnya menjadi bagian dari tipe: `range[0..9]` bukan `int` yang kebetulan kecil,
melainkan tipe yang nilainya sepuluh integer dari `0` sampai `9`. Kamu mendeklarasikannya dengan sebuah nama lalu
memakainya seperti tipe lain:

```
type Digit = range[0..9]
var five: Digit = 5
echo ord(five)     # 5
```

Compiler menegakkan batas itu, dan caranya adalah pembuktian, bukan pemeriksaan runtime. Literal di luar range
ditolak saat deklarasi dengan `Error: value out of range: 10 notin 0..9`. Nilai bertipe lain harus dibuktikan
berada di dalam batas sebelum konversinya diterima:

```
var step = 10
var d: Digit = Digit(step)
# Error: cannot prove 'step' is in range 0..9
```

Bungkus konversinya dengan guard dan ia ter-compile — prover menerima pemeriksaan yang bisa dilihatnya:

```
if step >= 0 and step <= 9:
  d = Digit(step)
```

Chapter 7 memakai range di loop; di sini poinnya cuma bahwa range memindahkan fakta yang biasanya kamu uji saat
runtime ke dalam tipe, dan compiler tidak akan membiarkanmu melewati pembuktian itu.

## Nim 2 delta: overflow wraps

> **Yang dilakukan Nim 2.** Overflow signed melempar `OverflowDefect` ketika overflow check menyala, yang dalam
> praktik berarti build debug crash di tempat build release wrap — sumber yang sama berperilaku dua cara. Penyelamat
> standarnya adalah menangkap defect itu atau memasang `overflowChecks: off`.
>
> **Yang dilakukan Nimony.** Overflow signed wrap, selalu, dan backend C dikompilasi dengan `-fwrapv` supaya tidak
> ada yang di hilir boleh menganggap sebaliknya (`doc/differences.md:24`, `doc/language.md:76-90`). Cara eksplisit
> untuk menyadari overflow adalah `{.keepOverflowFlag.}` dengan `overflowFlag()`; constant expression yang overflow
> malah menjadi compile error.
>
> **Apa yang rusak kalau kebiasaannya dipertahankan.** `try`/`except OverflowDefect` di sekitar aritmetika adalah
> kode mati yang tetap ter-compile, jadi angka yang wrap berjalan terus dan gagal di tempat lain — sebagai indeks
> yang salah, panjang yang negatif, total yang diam-diam keliru. Dan aritmetika yang ditulis dengan mengandalkan
> build debug melempar sekarang hanyalah aritmetika yang wrap.

## Sample

- `samples/04-numbers-types-conversion/numbers.nim` — satu program yang mencetak lebar `int`, me-wrap nilai signed
  dan unsigned di batasnya, membaca overflow flag, membagi dengan `div`, `mod` dan `/`, mengonversi dua arah
  termasuk narrowing yang wrap, memakai `bool` dan `char`, serta memakai tipe `range`. Dibuktikan oleh
  `tools/verify-samples.sh`:

  ```
  PASS samples/04-numbers-types-conversion/numbers.nim exit=0
  ```

  Output yang diharapkan, berurutan — verifier memeriksa compile, run dan exit code, bukan stdout, jadi daftar ini
  adalah pemeriksaannya:

  ```
  8
  -128
  127
  -128
  0
  -9223372036854775808
  true
  3
  1
  3.5
  3
  -3
  3.0
  -56
  1
  1
  97
  a
  true
  5
  5
  ```

  `8` untuk `sizeof(int)` adalah host 64-bit ini; pada target 32-bit baris yang sama mencetak `4`.

## Latihan

1. Cetak `sizeof(int)`, `low(int8)` dan `high(int8)`. Harapan: `8`, `-128`, `127` di host ini; angka pertama
   berubah mengikuti target, dua sisanya tidak pernah.
2. Set `var edge: int8 = 127` lalu tambahkan `1'i8`. Harapan: ter-compile dan mencetak `-128`. Lalu tulis jumlah
   yang sama sebagai `const`. Harapan: `expression overflow at compile time: 127'i8 + 1'i8`.
3. Cetak `7 div 2`, `7 mod 2` dan `7 / 2`. Harapan: `3`, `1`, `3.5`. Ganti angka pertamanya menjadi `-7`.
   Harapan: `-3`, `-1`, `-3.5`.
4. Deklarasikan `var i = 3` lalu `var f: float = i`. Harapan: `type mismatch: got: int64 but wanted: float64`.
   Ganti `i` dengan literal `3`. Harapan: ter-compile dan mencetak `3.0`.
5. Deklarasikan `type Digit = range[0..9]` lalu beri literal `10`. Harapan: `value out of range: 10 notin 0..9`.
   Lewatkan sebuah `var` berisi `10` melalui `Digit(...)`. Harapan: `cannot prove 'step' is in range 0..9`. Bungkus
   konversinya dengan `if step >= 0 and step <= 9:` lalu build lagi — harapan, ia ter-compile.
6. Konversi `200` ke `int8` lalu cetak. Harapan: `-56`. Konversi `-3.9` ke `int`. Harapan: `-3`, karena konversi
   memotong ke arah nol, bukan membulatkan.

## Checklist chapter

draft 2026-11-12 · tech_review Momo 2026-11-12 · editorial_pass 2026-11-12 · frozen 2026-11-12
