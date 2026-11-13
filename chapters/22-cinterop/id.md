---
chapter: 22
title: The C Boundary
job: Bind a C function, map its types, and cross the cstring boundary deliberately.
nimony_version: 0.6.3
nimony_commit: 4ba90a781b0b22d0821efaa153c129c37cef6143
toolchain: ~/.local/opt/nimony/4ba90a7
host_compiler: ~/.local/opt/nim-2.4.0
status: frozen
tech_review: Momo 2026-11-13
editorial_pass: 2026-11-13
samples: [samples/22-cinterop/cinterop.nim]
glossary_added: [importc, exportc, cdecl, header, dynlib, cstring array]
---

# Batas C

## Untuk apa bab ini

Setiap routine di buku ini sampai titik ini ditulis dalam Nimony dan diperiksa Nimony. Fungsi C berbeda: compiler
cuma melihat signature yang kamu tulis dan tidak melihat body sama sekali, jadi tidak ada apa pun di dalamnya yang
diverifikasi. Bab ini soal mendeklarasikan signature itu dengan jujur, memetakan tipe supaya sisi C membaca
apa yang kamu maksud, dan menyeberangi batas string tanpa berpura-pura dua model string itu sama.

Aturan yang menata bab ini lugas: di deklarasi `importc`, tipe itu janji, bukan pemeriksaan. Semua yang salah
di batas ini salah karena janjinya salah — `long` yang dideklarasikan `int`, pointer yang dideklarasikan non-null
padahal C membiarkannya null, callback yang daftar parameternya beda satu `const`.

## Mendeklarasikan fungsi C

`{.importc.}` menamai simbol C dan `header` menamai file yang harus di-include oleh C yang dihasilkan
(`src/nimony/sempragmas.nim:346` menerima pasangan itu). Deklarasi lengkap terkecil adalah routine libc:

```nim
import std / [syncio]

proc strlen(s: cstring): int {.importc, header: "<string.h>".}
echo strlen(cstring"hello")
```

Itu mencetak `5`. Namanya diambil dari identifier Nimony kecuali pragma membawa string, dan header bukan yang
memunculkan simbolnya: Nimony menulis sendiri prototipe dari deklarasi kamu, dan tanpa header dia memancarkan
prototipe dengan nama C ditempel lewat label assembler, `cstrlen_0(...) __asm__("strlen")`. Yang ditambahkan
`header` adalah deklarasi aslinya. `major` adalah buktinya — dia mencetak `0` dengan `<sys/types.h>` di pragma,
dan tanpa header itu link gagal dengan `_major` yang tidak terdefinisi, karena `major` adalah makro di header
tersebut dan simbol dengan nama itu tidak ada. Sebut header kapan pun sisi C punya header.

`dynlib` memuat library alih-alih menautkannya, dan string-nya adalah nama platform, bukan nama portabel:
`dynlib: "libm.so.6"` gagal di mesin ini dengan `could not load: libm.so.6`, sementara `dynlib: "libm.dylib"`
terselesaikan dan `cos(0.0)` mencetak `1.0`. Kalau kodenya harus jalan di lebih dari satu sistem, string itu
pilihan build, bukan konstanta untuk disalin.

Routine C variadik memakai `{.varargs.}`, dan argumen setelah yang tetap dikirim apa adanya:

```nim
proc printf(fmt: cstring): cint {.importc, header: "<stdio.h>", varargs.}
discard printf(cstring"%s %d\n", cstring"hi", 42)
```

Satu detail di baris itu bukan trik `printf`: literal setelah `cstring` adalah *generalized string literal*, dan
lexer membacanya mentah (`src/nifler2/nimlexer.nim:1061-1064`), jadi `\n` tetap dua karakter. Output panggilan itu
adalah `hi 42\n` dalam satu baris, backslash ikut tercetak. Nim 2.4.0 membacanya dengan cara yang sama, jadi ini
lubang di manual, bukan perubahan di pin.

Callable yang di C berupa makro bisa dideklarasikan sebagai routine, dan header-nya yang membuat itu jalan:
compiler C mengembangkan namanya sebelum sempat meminta simbol, itulah sebabnya `major` mengembalikan `0` ketika
pragma menyebut `<sys/types.h>`. Makro yang bukan pemanggilan fungsi — ekspresi seperti `sizeof`, `offsetof`,
sebuah konstanta — perkara lain: `{.importc: "sizeof(struct stat)".}` dengan header ditolak compiler C sebagai
`called object type 'unsigned long' is not a function`, dan tanpa header link gagal pada simbol
`sizeof(struct stat)`.

## Tipe yang dibutuhkan sebuah signature

Alias selebar C datang bersama `system`, jadi tidak perlu import: `cint` adalah `int32`, `cdouble` adalah
`float64`, `csize_t` adalah `uint`, `clong` mengikuti platform (`int` di mesin ini). `sizeof` menjawab dalam byte
di pin, dan empat nilai yang penting di sini adalah `4` untuk `cint`, `8` untuk `cdouble`, `8` untuk `pointer`,
dan `8` untuk `csize_t`.

Alias-alias itulah inti aturan pertama bab ini. `cint` bukan `int`, dan nilai yang sudah bertipe harus
dikonversi: `csize_t(sizeof(cint))` ditulis eksplisit karena `sizeof` mengembalikan `int`, sementara literal
telanjang seperti `3` di bawah berkonversi sendiri.

```nim
proc memset(p: pointer, c: cint, n: csize_t): pointer {.importc, header: "<string.h>".}
var buf: array[4, char]
discard memset(addr buf[0], cint(ord('x')), 3)
```

`buf` lalu berisi `xxx`, dan `buf[3]` masih `'\0'` — array `char` adalah buffer C, dan alamatnya yang diminta C.

Struct C dipetakan sebagai object `{.importc.}` yang field-nya kamu daftar berurutan, dan nama tipenya nama C-nya:

```nim
type
  DivT {.importc: "div_t", header: "<stdlib.h>", nodecl.} = object
    quot: cint
    rem: cint

proc cdiv(a, b: cint): DivT {.importc: "div", header: "<stdlib.h>".}
let d = cdiv(7, 2)
```

`d.quot` dan `d.rem` mencetak `3` dan `1`: struct kecil kembali by value dan dibaca field demi field. Pemetaan
yang sama berlaku untuk parameter output — `stat` POSIX mengisi object `Stat` lewat `ptr Stat` dan mengembalikan
`0`, dan C yang dihasilkan memuat `struct stat` serta pemanggilan `stat(...)` yang asli. `out Stat` adalah
pointer yang sama dengan aturan inisialisasi dari Bab 8 menempel padanya: deklarasi yang manualnya sendiri
tunjukkan (`doc/language.md:2778`) memancarkan `stat("main.nim", (&st))` dan mengisi object-nya.

`sizeof` pada tipe seperti itu bertanya ke C, bukan ke Nimony: object `{.importc: "struct stat".}` yang cuma
mendeklarasikan satu field tetap melaporkan `144`, karena emitter C menulis `sizeof(struct stat)`
(`src/lengc/genexprs.nim:527-533`). Daftar field itu untuk membaca field, bukan untuk memberi tahu compiler
seberapa besar object C-nya.

## String di batas

`string` Nimony membawa panjang dan boleh berisi byte apa pun; `char*` C berhenti di byte nol pertama. Pin
memberimu tiga jalan menyeberang, dan ketiganya tidak bisa saling menggantikan.

`cstring"..."` adalah literal di memori read-only, mentah seperti dijelaskan di atas. `toCString(s)` mengambil
`var string` dan mengembalikan pointer ke byte string itu sendiri, jadi pandangannya bisa ditulis dan string-nya
tidak disalin:

```nim
var greeting = "hello"
let asC = toCString(greeting)
echo $asC
asC[0] = 'H'
echo greeting
```

Itu mencetak `hello` lalu `Hello`. `let` tidak bisa dikirim: `toCString` pada `let` adalah
`cannot pass s to var/out T parameter`, dan `cstring(x)` pada apa pun selain literal ditolak dengan pesan
`Only string literals can be converted to cstring. Use` ``toCString`` `for safe conversion.`
(`src/nimony/sem.nim:880`).

`fromCString(c)` menyalin arah sebaliknya. `$c` juga menyalin, tapi `$` untuk `cstring` di pin tinggal di
`std/strutils`, bukan di `system`: tanpa import itu, `$c` gagal sebagai type mismatch terhadap setiap kandidat
`$`. `echo c` gagal karena alasan yang Bab 20 berikan: sembilan overload `write` tidak memuat `cstring`.

Dua model itu berbeda pendapat di byte nol pertama, dan perselisihannya diam:

```nim
var withNul = "a\0b"
echo withNul.len, " ", strlen(toCString(withNul))
```

`3 1`. String Nimony punya tiga byte; C menghitung satu. Tidak ada yang memperingatkan, karena tidak ada di
kedua sisi yang boleh melihat melewati terminator.

## Pointer null punya tipenya sendiri

Di pin `ptr`, `pointer` dan `cstring` tidak bisa nil kecuali tipenya bilang begitu, dan fungsi C justru tempat
paling mungkin tipenya salah. `getenv` mengembalikan pointer null untuk nama yang tidak diset, jadi tipe
kembaliannya harus `nil cstring`:

```nim
proc getenv(name: cstring): nil cstring {.importc, header: "<stdlib.h>".}
let missing = getenv(cstring"BOOK22_NOPE")
echo isNil(missing)
```

Itu mencetak `true`, dan `getenv(cstring"PATH")` memberi nilai yang `isNil`-nya `false`. Mendeklarasikan routine
yang sama dengan kembalian `cstring` biasa juga ter-compile, dan `isNil` atas jawabannya tetap mencetak `true` —
compiler percaya janjinya dan tidak menyisipkan pemeriksaan, karena kembalian C tidak bisa diperiksa. Tipe itu
satu-satunya penjaga yang ada.

Hal yang sama berlaku di arah masuk. Parameter yang boleh dibiarkan null oleh C mengambil `nil pointer` atau
`nil cstring`, dan argumen `nil` telanjang ke parameter `pointer` adalah `expected non-nil value`
(`src/nimony/contracts.nim:280`). Dengan `nil pointer` di signature, `gettimeofday(addr tv, nil)` jalan dan
mencetak `true` untuk timestamp yang wajar.

Array string C butuh elemen `nil cstring`, karena terminator null array itu adalah pointer null:

```nim
var slots: array[2, nil cstring]
slots[0] = cstring"one"
slots[1] = nil
let first: nil cstring = slots[0]
if first != nil:
  echo strlen(first)
```

Baik assignment maupun pemeriksaannya lebih rewel dari kelihatannya, dan keributannya mulai dari deklarasi.
`var slots: array[2, cstring]` ditolak sebelum apa pun di-assign:
`'slots' is of type 'array[0..1, cstring not nil]', which has no default value`. Dengan elemen `nil cstring`
array-nya ada, tapi `nil` yang di-assign ke elemen bertipe lain adalah `expected non-nil value`; memeriksa
`slots[0] != nil` di tempat adalah `cannot analyze expression is not nil: slots[0]`
(`src/nimony/contracts.nim:293`), dan `isNil(slots[0])` gagal dengan cara yang sama, jadi menyalinnya ke `first`
yang membuat pemeriksaan itu bekerja. `cast[cstring](slots[0])` juga lolos, dengan menjanjikan apa yang tidak
bisa dibuktikan pemeriksaan tadi.

## Memanggil balik, dan satu hal yang C periksa

`{.exportc.}` memberi routine Nimony nama C, dan `{.compile.}` menambahkan file C ke build, diselesaikan relatif
terhadap file sumber:

```nim
{.compile: "helper2.c".}
proc book_cb(x: cint): cint {.exportc: "book_cb", cdecl.} = cint(x + 1)
proc helper_call(x: cint): cint {.importc, header: "helper2.h".}
```

Dengan `helper2.c` mendeklarasikan `book_cb` dan memanggilnya, `helper_call(41)` mencetak `42`. Simbolnya benar-
benar ada: `nm` pada binary menunjukkan `_book_add` untuk probe `exportc` biasa, dengan underscore yang
ditambahkan toolchain C platform ini. `{.cdecl.}` mendarat di C yang dihasilkan sebagai `N_CDECL(int, book_add)(...)`,
dan di platform ini makronya mengembang jadi kosong karena konvensi default-nya memang C.

Satu-satunya tempat compiler C benar-benar memeriksa kamu adalah prototipe callback, dan dia lebih ketat dari sisi
Nimony. `qsort` meminta `int (*)(const void *, const void *)`; pin memancarkan proc Nimony `{.cdecl.}` dengan
parameter `pointer` sebagai `int (void *, void *)` — tanpa `const` — dan clang menolaknya dengan
`incompatible function pointer types`. Mendeklarasikan parameternya `pointer` lalu mengirim `cast[pointer](cmp)`
ter-compile dan mengurutkan `3 1 2` jadi `123`. Cast itu bukan kosmetik: itu sistem tipe C yang diberi tahu bahwa
dua signature cukup dekat, janji yang sama dengan yang dipakai seluruh batas ini.

## Yang tidak diperiksa batas ini

Tidak ada apa pun tentang routine `importc` yang dianalisis. Body-nya diperlakukan eksternal, jadi effect tag-nya
apa pun yang kamu tulis dan signature-nya tidak dibandingkan dengan header C:
`src/nimony/contracts_fir.nim:6036-6041` melewati penelusuran body untuk proc extern sepenuhnya. `cint` yang
salah di tempat C punya `long` ter-compile di kedua sisi dan membaca byte yang salah; `proc` yang mengambil dua
parameter lalu dipanggil dengan tiga paling banter jadi error C.

Global C adalah binding, bukan salinan: `var errno {.importc, header: "<errno.h>".}: cint` membaca `7` setelah
ditulis, dan setelah `open` pada file yang tidak ada mengembalikan `-1`, variabel yang sama membaca `2` — `errno`
yang asli (`src/nimony/contracts_fir.nim:5791`). Mendeklarasikannya `cint` benar di sini; mendeklarasikan `long`
C sebagai `cint` akan ter-compile dan membaca separuh nilai.

Itulah metode seluruh bab: baca prototipe C, tulis tipe Nimony yang cocok persis, dan perlakukan setiap
penyimpangan sebagai bug yang kamu temukan saat jalan, bukan saat compile.

## Nim 2 delta

*Apa yang Nim 2 lakukan:* `cstring(x)` mengonversi `var string` langsung, `$` untuk `cstring` terjangkau dari
`system`, `allocCStringArray` membangun array argumen, dan `ptr`/`pointer`/`cstring` nullable kecuali dinyatakan
lain.
*Apa yang Nimony lakukan:* hanya literal string yang berkonversi ke `cstring`; `var string` lewat `toCString`, dan
`let` tidak bisa sama sekali. `$` untuk `cstring` datang dari `std/strutils`. Tidak ada `allocCStringArray`:
array-nya adalah `alloc0` plus `cast` ke `ptr UncheckedArray[nil cstring]`, lalu `dealloc` di akhir. Nullability
terbalik — tipe telanjang non-null dan tipe nullable ditulis `nil cstring`.
*Apa yang rusak kalau kamu bawa kebiasaannya:* `cstring(someVar)` adalah error konversi yang dikutip di atas,
`echo cstringValue` adalah mismatch terhadap sembilan overload `write`, `allocCStringArray` adalah
`undeclared identifier`, dan `getenv` yang dideklarasikan mengembalikan `cstring` ter-compile sambil menjanjikan
sesuatu yang tidak ditepati fungsi C-nya.

## Samples

`samples/22-cinterop/cinterop.nim`, dijalankan di commit yang di-pin:

```
nimony c -r samples/22-cinterop/cinterop.nim
```

Output yang diharapkan, yang dicetak verifier sample secara penuh:

```
5
hello
4 3
3 1
xxx true
4 8
true
Hello
3 1
3
true
```

Baris demi baris: panjang `hello` lewat `strlen` (`5`); byte yang sama sebagai string Nimony (`hello`); literal
`cstring` mentah dan literal Nimony yang di-escape berdampingan (`4 3`); struct C yang kembali by value (`3 1`);
buffer yang diisi C (`xxx`, dengan byte keempat masih nol, `true`); `sizeof` dari `cint` dan dari struct importc
(`4 8`); jawaban `getenv` yang null (`true`); pandangan yang bisa ditulis mengubah string (`Hello`); string
Nimony dengan nol di dalamnya melawan hitungan C (`3 1`); elemen array yang diperiksa (`3`); dan slot null
(`true`).

## Cek

1. Deklarasikan `strlen` dengan `header` dan panggil pada `cstring"abcdef"`. Harapan: `6`.
2. Panggil `strlen` pada `string` `let` Nimony tanpa konversi. Harapan: type mismatch yang menyebut `string` dan
   `cstring`.
3. Panggil `toCString` pada `let`. Harapan: `cannot pass … to var/out T parameter`.
4. Tulis `cstring"a\nb"` dan `"a\nb"` lalu cetak kedua panjangnya. Harapan: `4` dan `3`.
5. Deklarasikan `getenv` mengembalikan `cstring` biasa, lalu panggil dengan nama yang kamu tahu tidak diset dan
   cetak `isNil`. Harapan: `true`, tanpa keluhan compiler — pelajarannya, deklarasi tidak bisa membuatnya
   non-null.
6. Deklarasikan `memset` dan isi tiga byte dari `array[4, char]` dengan `'x'`. Harapan: `xxx` dan byte keempat
   nol.
7. Taruh proc `{.exportc.}` di program kamu dan cari namanya dengan `nm`. Harapan: simbolnya ada.

## Chapter checklist

draft 2026-11-13 · tech_review 2026-11-13 · editorial_pass 2026-11-13 · frozen 2026-11-13
