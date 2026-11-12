---
chapter: 9
title: Overloading and UFCS
job: Resolve overload sets by argument type, call either form with method-call syntax, and know what is no longer overloadable (`var T` for `[]`).
nimony_version: 0.6.3
nimony_commit: 4ba90a781b0b22d0821efaa153c129c37cef6143
toolchain: /Users/sachiel/.local/opt/nimony/4ba90a7
host_compiler: /Users/sachiel/.local/opt/nim-2.4.0
status: frozen
tech_review: Momo 2026-11-12
editorial_pass: 2026-11-12
samples: ["samples/09-overloading/overloading.nim"]
glossary_added: ["overload set", "overload resolution", "receiver", "method call syntax", "index setter", "module-of-origin"]
---

# Overloading dan UFCS

## Untuk apa chapter ini

Chapter 8 memberi satu routine satu nama. Di sini satu nama membawa beberapa routine, dan compiler memilih yang
dimaksud sebuah panggilan. Itu mekanisme di balik sebagian besar yang tampak seperti perilaku bawaan di buku ini:
`$` pada angka dan `$` pada tuple adalah dua deklarasi dengan satu nama
(`lib/std/system/formatint.nim:104`, `lib/std/system/dollars.nim:41`). Tidak semua yang tampak overload memang
overload: `echo` cuma satu deklarasi, `template echo*() {.varargs.}` (`lib/std/syncio.nim:465`), yang menerima
argumen berapa pun jumlahnya.

Chapter ini punya dua paruh. Pertama, bagaimana sebuah nama dengan beberapa kandidat diselesaikan, termasuk
kasus ketika resolusinya gagal dan mengatakannya. Kedua, sintaks pemanggilan yang menaruh argumen pertama di
depan nama — `x.f(y)` untuk `f(x, y)` — yang bukan fitur bahasa kedua, melainkan panggilan yang sama dengan
penulisan lain.

Bagian terakhir adalah deltanya: `var T` bukan lagi dimensi overloading. Itu menghapus satu bentuk dari kode
Nim 2 yang tidak bisa langsung lo port. Dua pemeriksaan terpisah yang membawa penghapusan itu, dan mencampur
keduanya adalah kesalahan yang biasa: resolusi overload tidak punya dimensi `var`-ness, jadi pasangan `var T` /
`T` adalah satu ambiguitas; dan lintasan borrow (`validBorrowsFrom`) memutuskan ke mana hasil `var` boleh
menunjuk. Keduanya muncul di bawah.

## Satu nama, beberapa routine

Dua routine boleh berbagi nama asalkan daftar parameternya berbeda. Tidak ada yang dideklarasikan sebagai
"overload" — `proc` kedua dengan nama yang sama adalah satu kandidat lagi di himpunan itu:

```
func render(x: int): string = "int " & $x
func render(x: string): string = "text " & x

echo render(3)
echo render("a")
```

```
int 3
text a
```

Ariti juga dihitung, karena ia bagian dari daftar parameter:

```
func twice(x: int): int = x * 2
func twice(x: int, y: int): int = x * 2 + y

echo twice(4)
echo twice(4, 1)
```

```
8
9
```

Tipe hasil bukan bagian dari daftar parameter, dan tidak membedakan dua kandidat. Menulis daftar parameter yang
sama dua kali dengan hasil berbeda diterima di deklarasi dan ditolak di pemanggilan:

```
proc g(x: int): int = 1
proc g(x: int): string = "s"
echo g(1)
```

```
q4.nim(4, 7) Error: ambiguous call: 'g'
proc (x: int64): int64 (declared in q4.nim(2, 1))
proc (x: int64): string (declared in q4.nim(3, 1))
```

Baca dua baris yang dicetak pesan itu: mereka kandidat yang tidak bisa ia pilih di antaranya. Inilah bentuk
setiap pesan ambiguitas di chapter ini, jadi layak dikenali sebelum lo bertemu satu di program yang lebih besar.
Pesannya dibangun di `src/nimony/semcall.nim:1397`. Pin mencetak `int` sebagai `int64` di daftar seperti ini;
itu bukan bug di kode lo, itu cara tipe argumen dirender.

## Bagaimana compiler memilih

`doc/language.md:1318` menggambarkan pemanggilan sebagai *symbol choice*: nama bisa merujuk ke lebih dari satu
kandidat, dan resolusi overload mengubahnya jadi satu simbol. Pekerjaannya dilakukan dalam percobaan berurutan,
dan percobaan pertama yang memisahkan dua kandidat yang memutuskan di antaranya. Percobaan pertama adalah
pencocokan kategori (`doc/language.md:1328-1347`), yang memeringkat tiap argumen terhadap tiap parameter formal
dengan urutan ini:

1. **Exact match** — tipe yang sama.
2. **Literal match** — literal integer atau float yang nilainya muat di tipe parameter.
3. **Generic match** — parameternya tipe generic.
4. **Subrange atau subtype match.**
5. **Integral conversion match.**
6. **Conversion match**, bisa lewat sebuah `converter`.

Kandidat yang cocok di lebih banyak argumen pada kategori lebih tinggi menang. Kalau dua kandidat masih seri
setelah semua percobaan, ambiguitasnya dilaporkan — panduan mengatakannya di `doc/language.md:1325-1326`, dan
pesan di bagian sebelumnya adalah bentuknya.

Peringkat itu langsung kelihatan dengan literal. Diberi satu kandidat `int` dan satu `int32`, panggilannya jatuh
ke `int`:

```
proc pick(x: int): string = "int"
proc pick(x: int32): string = "int32"
echo pick(5)
```

```
int
```

`int32` akan menerima `5` sebagai literal match, tapi `int` menerimanya sebagai exact match dan menang di
kategori lebih tinggi — diprobe di pin ini, bukan kalimat di panduan. Ganti parameter kedua dengan `float` dan
`pick(5)` tetap mencetak `int`, sementara `pick(5.0)` mencetak `float` — bentuk argumennya sendiri yang memilih
sisi.

Itu hanya berlaku selama satu sisinya `int`. Daftar di panduan memberi literal integer target integer dan
literal float target float, jadi ia memprediksi tidak ada seri antara `int32` dan `float`. Pin menyetikannya
tetap terjadi, dan itu temuan probe, bukan kategori yang dinamai panduan:

```
proc amb(x: int32): string = "int32"
proc amb(x: float): string = "float"
echo amb(5)
```

```
v4.nim(4, 9) Error: ambiguous call: 'amb'
proc (x: int32): string (declared in v4.nim(2, 1))
proc (x: float64): string (declared in v4.nim(3, 1))
```

Jadi aturan literal cuma membawa lo sejauh itu. Lewat `int`, sebutkan tipe yang lo maksud dengan konversi atau
variabel bertipe di call site; jangan harap literalnya melebar sendiri.

Satu jebakan di pin ini berhak dapat paragrafnya sendiri. `int` adalah `int64` di sini, bukan lebar tersendiri:

```
func show(x: int64): string = "int64"
var a: int = 5
echo show(a)
echo sizeof(int)
echo sizeof(int64)
```

```
int64
8
8
```

Jadi di target 64-bit `int` dan `int64` adalah tipe yang sama dengan dua penulisan:
`src/nimony/builtintypes.nim:160-163` membangun `int` sebagai `(i configBits)`, `:197-199` membangun `int64`
sebagai `(i 64)`, dan `src/nimony/semmain.nim:652` memberi bit target. Di target 32-bit pasangan itu akan
berbeda; setiap target yang dibangun buku ini 64-bit. Himpunan dengan satu kandidat `int` dan satu kandidat
`int64` karena itu himpunan dengan dua kandidat identik: ia tercompile, dan setiap panggilan ke sana ambigu.
Kalau lo port kode Nim 2 yang meng-overload dua lebar itu, gabungkan pasangannya jadi satu routine.

Kalau dua kandidat datang dari modul berbeda, yang dideklarasikan di modul pemanggil yang dipilih. Panduan
mengodekannya sebagai parameter implisit tambahan dan menyebutnya module-of-origin
(`doc/language.md:1375-1400`); lo tidak menulis apa pun untuknya, tapi itu menjelaskan kenapa wrapper lokal bisa
diam-diam menutupi routine impor yang cocok sama baiknya. Diprobe 2026-11-12 dengan dua modul: dengan `pick`
lokal di samping yang diimpor, yang lokal menang, dan setelah yang lokal dihapus, yang impor yang dipakai, dua
build exit 0.

## Method call syntax

`f(x, y)` punya ejaan kedua: `x.f(y)`. Panduan memperkenalkannya untuk kode berorientasi objek lalu bilang terus
terang bahwa ia tidak dibatasi objek — argumen pertama apa pun bisa jadi receiver
(`doc/language.md:2836-2842`). Tanda kurung dihilangkan kalau tidak ada argumen sisa, jadi `5.twice` dan
`5.twice()` panggilan yang sama:

```
func twice(x: int): int = x * 2
func twice(x: int, y: int): int = x * 2 + y

echo 5.twice
echo 5.twice(1)
```

```
10
11
```

`5.twice(1)` menunjukkan seluruh aturannya sekaligus: receiver jadi argumen pertama, sisanya menyusul
berurutan, dan himpunan overload-nya sama dengan yang dipakai panggilan biasa.

Ia juga jalan keluar dari batas satu argumen pada bentuk command yang dibahas di Chapter 8. Di posisi ekspresi
bentuk itu menerima tepat satu argumen dan parser berhenti di koma; di posisi statement ia memang menerima dua
dan terparse sebagai satu panggilan, tapi hasilnya tidak ada tempatnya, jadi `add 1, 2` gagal dengan
`expression of type int64 must be discarded`. `1.add(2)` satu panggilan di posisi mana pun.

Receiver harus parameter pertama, dan compiler mengatakannya dalam istilah tipe:

```
func wrap(s: string, n: int): string = s & $n
echo 1.wrap("a")
```

```
r4.nim(3, 12) Error: Type mismatch at [position]
1.(wrap, "a")
[1] expected: string but got: int64 (declared in r4.nim(2, 1))
```

Panggilan yang ditulis ulang di pesan itu intinya: `1.wrap("a")` menjadi `1.(wrap, "a")`, dengan `1` di posisi
pertama. Receiver tidak dicocokkan ke semacam tipe receiver; ia dicocokkan ke parameter pertama seperti argumen
lain.

Instansiasi generic eksplisit tidak selamat dari penulisan ulang itu. Panduan memperingatkan bahwa `p[T](x)`
tidak bisa ditulis `x.p[T]`, karena itu terparse sebagai `(x.p)[T]` (`doc/language.md:2855-2866`). Kedua paruh
peringatan itu kelihatan di pin:

```
func count[T](a: T, b: T): int = 2
echo 3.count[int](4)
```

```
u3.nim(3, 7) Error: undeclared field: 'count' for type int64
```

Parser membacanya sebagai akses field pada `3`, persis seperti didokumentasikan; pesannya datang dari
`src/nimony/sem.nim:5162`. Obat yang didokumentasikan adalah bentuk `[: ]`, dan itu bekerja di posisi receiver:

```
echo 3.count[:int](4)
```

```
2
```

`[: ]` tidak punya syntax tree sendiri: parser menulis ulang jadi `count[int](3, 4)` sebelum apa pun
melihatnya (`doc/language.md:2862-2866`). Diprobe, bukan dikutip: bentuk panggilan telanjang `count[:int](3, 4)`
tidak terparse di pin ini — gagal dengan `invalid indentation` di bracket — jadi escape `[: ]` hanya bisa
dipakai di sisi receiver. Tulis `count[int](3, 4)` kalau lo tidak memakai receiver.

## Nim 2 delta: `var T` bukan lagi dimensi overloading

`doc/differences.md:31` mencatat perubahannya: overloading berdasarkan `var T` hilang, dan accessor jadi
polimorfik — mutabilitas dilacak di lokasi yang ditulis, bukan dipilih oleh overload kedua. Berkas itu lalu
menunjukkan pasangan Nim 2 yang dulu ada dan satu routine Nimony yang menggantikannya
(`doc/differences.md:31-43`):

```
# Nim 2
func `[]`(x: var Container): var Element
func `[]`(x: Container): lent Element

# Nimony
func `[]`(x: Container): var Element
```

Tiga hal terpisah mengikuti itu di pin, dan mudah tertukar karena hanya satu yang khusus soal `[]`.

**Overload `var` dan non-`var` bukan dua kandidat; mereka satu ambiguitas.** Resolusi tidak lagi membedakan
keduanya, jadi pasangan yang di Nim 2 dipisah oleh mutabilitas adalah pasangan yang di pin tidak bisa dipisah
sama sekali:

```
func get(b: var Box, i: int): var int = b.v
func get(b: Box, i: int): int = b.v
var b = Box(v: 7)
echo get(b, 0)
```

```
r5.nim(7, 9) Error: ambiguous call: 'get'
func (b: var Box, i: int64): var int64 (declared in r5.nim(4, 1))
func (b: Box, i: int64): int64 (declared in r5.nim(5, 1))
```

**Hasil `var` butuh jalur yang boleh ia pinjam.** Accessor sederhana di delta itu ada, tapi lintasan borrow
harus melihat ada tempat untuk hasilnya menunjuk. Field inline milik parameter by-value tidak memberi itu: field
itu duduk di dalam salinan pemanggil, jadi tidak ada jalur kembali. Menulis baris panduan itu dengan parameter
biasa ditolak di definisi, bukan di pemanggilan:

```
func `[]`(b: Box, i: int): var int = b.v
```

```
r2.nim(4, 39) Error: cannot borrow from b.v
```

Pemeriksaannya `trReturn` di `src/nimony/derefs.nim:466-468`, yang memanggil `validBorrowsFrom`
(`src/nimony/derefs.nim:258-314`).

Ini lintasan borrow, bukan aturan resolusi. Overload yang dihapus menentukan routine mana yang dipilih sebuah
panggilan; `validBorrowsFrom` membatasi ke mana hasil `var` boleh menunjuk. Dengan `b: var Box` accessornya
terbangun dan pembacaan lewat situ bekerja. Parameter `lent` juga diterima, dan indireksi juga — field `seq`
yang dibaca lewat parameter biasa tercompile, karena jalurnya lewat penyimpanan heap alih-alih field inline:

```
type Container = object
  data: seq[int]

func `[]`(x: Container, i: int): var int = x.data[i]
```

Ini bentuk yang dijalankan sample chapter ini di bagian akhir: `1` dibaca lewat accessor, lalu `5` setelah
elemennya ditulis langsung. Ganti field `seq` jadi `v: int` inline dan lo dapat penolakan di atas.

**Menulis lewat indeks butuh `[]=` sendiri.** Accessor yang mengembalikan `var` tidak cukup untuk assignment.
Dengan hanya `func `[]`(b: var Box, i: int): var int` dideklarasikan, `b[0] = 9` gagal di assignment. Pesannya
memang menyebut tipe lo sekali, di baris pertamanya, lalu mendaftar kandidat `[]=` bawaan. Yang tidak pernah ia
katakan dengan kata-kata adalah bahwa tidak ada `[]=` untuk `Box`:

```
s1.nim(6, 1) Error: Type mismatch at [position]
b[0] = 9
[1] Box does not match constraint T (declared in /.../lib/std/system.nim(32, 1))
[1] expected: array[I, T] but got: Box (declared in /.../lib/std/system.nim(34, 1))
... 10 more candidate lines
```

Assignment meminta `[]=`, dan tanpa `[]=` milik lo sendiri ia hanya bisa mencoba yang bawaan; header
`Type mismatch at [position]` datang dari `src/nimony/semcall.nim:1436`, dan kandidat bawaan pertama adalah
`lib/std/system.nim:32`. Deklarasikan setter-nya dan baris yang sama tercompile:

```
func `[]`(b: Box, i: int): int = b.v
func `[]=`(b: var Box, i: int, val: int) = b.v = val

var b = Box(v: 7)
b[0] = 9
echo b[0]
```

```
9
```

Apa yang Nim 2 lakukan → apa yang Nimony lakukan → apa yang rusak kalau lo pertahankan kebiasaannya:

- **Nim 2:** dua overload `[]`, satu pada `var Container` yang mengembalikan `var Element`, satu pada
  `Container` yang mengembalikan `lent Element`; assignment lewat overload `var` secara otomatis.
- **Nimony:** satu accessor `[]`, yang boleh mengembalikan `var` kalau ia punya jalur untuk dipinjam —
  parameter `var`, `out` atau `lent`, atau indireksi seperti field `seq`; penulisan lewat `[]=` terpisah yang
  lo deklarasikan.
- **Yang rusak:** container hasil port yang meng-overload `var T` tercompile sebagai dua kandidat yang tampak
  identik dan setiap panggilannya ambigu; accessor hasil port yang mengembalikan `var` dari field inline milik
  parameter by-value berhenti tercompile dengan `cannot borrow from b.v`; dan tipe hasil port yang mengandalkan
  write-through implisit mulai gagal di assignment dengan daftar kandidat bawaan.

Ini chapter yang deltanya bukan catatan kaki. Baca `doc/differences.md:31-43` sebelum mem-port tipe container
apa pun.

## Sample

`samples/09-overloading/overloading.nim` — himpunan overload, kedua bentuk panggilan, dan index setter, di
commit yang dipin:

```
$ nimony c -r samples/09-overloading/overloading.nim
int 3
text a
8
9
10
11
a1
9
1
5
```

`10` dan `11` adalah `5.twice` dan `5.twice(1)`: receiver sama, kandidat berbeda, dipilih oleh argumen yang
menyusulnya. `9` adalah penulisan lewat `[]=` sample itu dan pembacaan balik lewat `[]`. Dua baris terakhir
adalah container ber-`seq` dari bagian borrow: `1` dibaca lewat accessor, lalu `5` setelah elemennya ditulis
langsung — itu yang menunjukkan hasil `var` benar-benar menunjuk ke penyimpanan container itu sendiri.

## Latihan

1. Tulis `func render(x: int)` dan `func render(x: string)` yang mengembalikan `int 3` dan `text a`. Harapan:
   dua baris yang sama dengan sample.
2. Tulis `twice(x: int)` dan `twice(x: int, y: int)`. Harapan: `twice(4)` adalah `8`, `twice(4, 1)` adalah `9`.
3. Tulis `proc g(x: int): int` dan `proc g(x: int): string`, lalu panggil `g(1)`. Harapan: `ambiguous call: 'g'`
   diikuti dua baris kandidat. Hapus satu deklarasi. Harapan: ia terbangun.
4. Tulis `pick(x: int)` dan `pick(x: int32)`, lalu panggil `pick(5)`. Harapan: baris `int`.
5. Tulis `once(x: int)` dan `once(x: int64)`, lalu panggil `once(5)`. Harapan: `ambiguous call` dengan dua
   kandidat `(x: int64)` yang tampak identik. Ganti tipe parameter kedua jadi `int32`. Harapan: ia terbangun dan
   mencetak baris `int`.
6. Tulis `func show(x: int64)` dan berikan nilai yang dideklarasikan `var a: int`. Harapan: ia terbangun. Ganti
   parameternya jadi `int32`. Harapan: `Type mismatch`, dengan baris detail `[1] expected: 32 but got: 64`.
7. Tulis `wrap(s: string, n: int)` dan panggil `"a".wrap(1)`. Harapan: `a1`. Panggil `1.wrap("a")`. Harapan:
   `Type mismatch`, dan pesannya menulis ulang panggilan jadi `1.(wrap, "a")`.
8. Tulis `5.twice` dan `5.twice()`. Harapan: nilai yang sama dari keduanya, dan sama dengan `twice(5)`.
9. Tulis `echo 3.count[int](4)` untuk `count[T]`. Harapan: `undeclared field: 'count' for type int64`. Tulis
   `echo 3.count[:int](4)`. Harapan: `2`. Tulis `echo count[:int](3, 4)`. Harapan: `invalid indentation`.
10. Tulis pasangan `get` dari bagian delta, satu pada `var Box` dan satu pada `Box`. Harapan: `ambiguous call`
    yang mendaftar keduanya. Hapus salah satu deklarasi. Harapan: ia terbangun.
11. Tulis `func `[]`(b: Box, i: int): var int = b.v` dengan `v` field inline. Harapan: `cannot borrow from
    b.v`. Ganti parameternya jadi `b: var Box`. Harapan: ia terbangun, dan membaca `b[0]` bekerja.
12. Tulis accessor `[]` dengan `b: var Box` lalu assign `b[0] = 9`. Harapan: `Type mismatch at [position]`
    dengan daftar kandidat bawaan. Tambahkan `func `[]=`(b: var Box, i: int, val: int)`. Harapan: ia terbangun
    dan mencetak nilai yang ditulis.

## Checklist chapter

draft 2026-11-12 · tech_review Momo 2026-11-12 · editorial_pass 2026-11-12 · frozen 2026-11-12
