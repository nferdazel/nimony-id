---
chapter: 11
title: Objects, Enums, and Distinct Types
job: Model data with nominal `object` types, ordinal `enum` types and representation-sharing `distinct` types, and explain value copy at assignment.
nimony_version: 0.6.3
nimony_commit: 4ba90a781b0b22d0821efaa153c129c37cef6143
toolchain: /Users/sachiel/.local/opt/nimony/4ba90a7
host_compiler: /Users/sachiel/.local/opt/nim-2.4.0
status: frozen
tech_review: Momo 2026-11-12
editorial_pass: 2026-11-12
samples: ["samples/11-objects-enums-distinct/objects.nim"]
glossary_added: ["nominal type", "enum type", "borrow"]
---

# 11. Objects, Enums, and Distinct Types

## Untuk apa chapter ini

Chapter 10 memilih container berdasarkan apa yang harus dilakukan data. Chapter ini memberi nama pada datanya
sendiri. Sebuah `object` memberi satu nama untuk sekumpulan field yang berhubungan, jadi routine bisa menerima
`Point` alih-alih dua integer dengan urutan yang harus diingat. Sebuah `enum` menamai sekumpulan nilai tetap dan
mengurutkannya, jadi `Color` bukan pengganti `int`. Tipe `distinct` mempertahankan satu representasi dan menolak
bercampur dengan base-nya, jadi jarak dalam meter tidak bisa dijumlahkan dengan durasi dalam detik secara tidak
sengaja.

Ketiganya value type biasa, dan aturan dari Chapter 10 tetap berlaku: assignment menyalin. Yang berubah adalah
apa yang diizinkan compiler untuk lo campur. Object itu nominal, jadi dua object dengan field identik tetap dua
tipe. Nilai enum terurut dan bisa diiterasi. Tipe distinct berbagi byte dengan base-nya dan tidak berbagi apa pun
selain itu.

## Objects

Object adalah kumpulan field bernama, masing-masing dengan tipenya sendiri (`doc/language.md:476`). Mendeklarasikan
satu berarti menamai tipe baru; tidak ada hubungan antara dua object yang kebetulan mirip.

```nim
type Point = object
  x: int
  y: int
```

Field yang tidak pernah ditulis tetap punya nilai. Konstruksi mengisi field yang lo sebut dan membiarkan sisanya
apa adanya — manual menyatakannya di `doc/language.md:568-583`. Bahwa field yang dihilangkan mengambil default
tipenya (`0` untuk `int`, `false` untuk `bool`, string kosong untuk `string`) diukur di pin ini, bukan dikutip
(`ch11-probes/o1.nim`, `o3.nim`).

```nim
var empty = Point()
echo empty.x      # 0
echo empty.y      # 0
echo Point(x: 1).y   # 0 — y is not required in the constructor
```

Field juga boleh mendeklarasikan default-nya sendiri, dan default itu berlaku untuk `Point()` maupun untuk field
yang dilewati constructor (`doc/language.md:652`):

```nim
type Badge = object
  label: string = "new"
  level: int = 1

echo Badge().label      # new
echo Badge(level: 4).level   # 4, label stays "new"
```

Dua kesalahan layak dikenali dari pesannya. Menyebut field yang tidak dimiliki tipe ditolak di constructor:
`P(z: 1)` memberi `undeclared field: 'z' for type P`. Melewati sebuah field bukan kesalahan sama sekali — itu
default.

Sebuah field bisa dijangkau dari module lain hanya kalau ditandai `*` (`doc/language.md:546-549`). Dari luar
module, field tanpa tanda terbaca sebagai `undeclared field: 'hidden' for type Widget` — compiler tidak
membedakan "disembunyikan" dari "tidak ada", dan itulah intinya.

### Copy saat assignment

Object itu value. `var b = a` menyalin setiap field (`doc/language.md:564`), dan salinannya mandiri sesudahnya:

```nim
var a = Point(x: 1, y: 2)
var b = a
b.x = 99
echo a.x    # 1
echo b.x    # 99
```

Salinan itu masuk ke dalam field. Object yang menyimpan `seq` menyalin elemen sequence-nya, bukan buffer
bersama, jadi menulis lewat salinan tidak menyentuh aslinya:

```nim
type Bag = object
  items: seq[int]

var a = Bag(items: @[1, 2])
var b = a
b.items[0] = 99
echo a.items[0]    # 1
echo b.items[0]    # 99
```

Itu diukur di pin ini (`ch11-probes/o12.nim`), dan cocok dengan aturan yang disebut language reference untuk
tuple dan object: operator assignment menyalin tiap komponen (`doc/language.md:564`). Ini juga menjelaskan aturan
parameter dari Chapter 10. Parameter object by-value bukan place, jadi routine tidak bisa menulis object milik
pemanggil; `var` yang membuatnya bisa ditulis.

### Object itu nominal

Ini bagian yang harus dilepas pembaca berlatar C. Tuple itu struktural: dua tuple dengan tipe field sama dalam
urutan sama adalah tipe yang sama. Object itu nominal: dua object dengan field identik adalah tipe berbeda, dan
compiler mengatakannya (`doc/language.md:548-549`).

```nim
type A = object
  x: int
type B = object
  x: int

var a = A(x: 1)
var b = B(x: 2)
a = b    # Error: type mismatch: got: B but wanted: A
```

Aturan yang sama berlaku untuk perbandingan. `==` bekerja antara dua nilai bertipe object yang *sama* dan
membandingkan field per field, termasuk isi sequence (`ch11-probes/o17.nim`, `o18.nim`):

```nim
echo Point(x: 1, y: 2) == Point(x: 1, y: 2)    # true
echo Point(x: 1, y: 2) == Point(x: 1, y: 3)    # false
echo A(x: 1) == B(x: 1)                       # Error: A does not match constraint Enum ...
```

Kesamaan itu bukan magic compiler, dan bukan lagi pertanyaan terbuka: itu generic library
`func ==*[T: tuple|object](x, y: T): bool` di `lib/std/system.nim:463`, yang menelusuri `fields(x, y)` dan
mengembalikan false pada field pertama yang tidak sama, jadi field `seq` dibandingkan lewat `==` milik seq
(`lib/std/system.nim:470-480`). Error di atas juga menamainya, di kandidat keduanya:
`[2] expected: A but got: B (system.nim(463, 1))` (`ch11-probes/o16.nim`). `doc/language.md` tidak punya
paragraf tentang kesamaan object — itu documentation gap, dicatat di `ERRATA.md`, bukan defect di bahasanya.

Yang dibutuhkan pembaca adalah konsekuensinya: tipe berbeda tetap tipe berbeda, jadi sebuah nama untuk data
membeli pemeriksaan, bukan komentar.

### Mencetak object butuh `$`

`echo` menulis tipe bawaan. Object buatan lo bukan salah satunya, jadi `echo p` adalah type error yang
mendaftar setiap overload `write` yang dicoba compiler (`ch11-probes/o6.nim`):

```
write stdout, P(x: 1)
[2] expected: string but got: P
[2] expected: int64 but got: P
...
```

`echo` tidak menerapkan `$` untuk lo. Tulis sendiri dan terapkan sendiri:

```nim
func `$`(v: Point): string =
  "(" & $v.x & ", " & $v.y & ")"

echo $p     # (11, 9)
```

Hal yang sama berlaku untuk tipe distinct yang punya `$`: `echo $m` mencetak, `echo m` tidak. Itu
terdokumentasi, bukan bug. Template `echo` di Nimony mengulang `unpack()` dan menulis setiap argumen, tanpa
konverter `$` (`doc/language.md:466-471`, `lib/std/syncio.nim:465-468`), dan `doc/porting.md:346-347` menyatakan
object memang sengaja tidak punya `$` generik — definisikan satu untuk tipe object itu.

> **Nim 2 delta — `echo` tidak lagi menerapkan `$` lo**
>
> *Apa yang dilakukan Nim 2* → `echo p` menemukan overload `$` dan mencetak `P1`, dari source yang sama
> (`~/.local/opt/nim-2.4.0`, probe `nim2check.nim`).
> *Apa yang dilakukan Nimony* → template `echo` di atas menulis nilainya sendiri; `$` buatan lo adalah routine
> yang lo panggil, jadi tulis `echo $p`.
> *Apa yang rusak kalau kebiasaannya dibawa* → `echo` pada object gagal dengan `write stdout, P(x: 1)` plus
> daftar kandidat, dan perbaikannya bukan mendefinisikan `$` tapi menerapkannya.

## Enums

Enum menamai sekumpulan nilai tetap dan memberi mereka urutan (`doc/language.md:182`). Urutannya adalah urutan
deklarasi, dan `ord` mengembalikan posisinya:

```nim
type Color = enum
  red, green, blue

echo ord(red)      # 0
echo ord(blue)     # 2
echo red < blue    # true
echo Color.green   # green — a value may be qualified with its type
```

Perbandingan bekerja karena enum adalah ordinal type, dan itulah yang membuatnya bisa mengindeks array dan
membuat `for` bisa menelusurinya (`doc/language.md:223-224`, `ch11-probes/e5.nim`):

```nim
var counts: array[Color, int]
counts[green] = 5
echo counts.len     # 3

for c in Color:
  echo c            # red, green, blue
```

`$` bawaan mencetak nama nilai itu (`doc/language.md:228`), dan nama yang tercetak adalah teks yang sama dengan
saat nilai itu dideklarasikan — kecuali nilai itu membawa string terlampir, yang dibahas bagian berikutnya.

### Ordinal eksplisit, hole, dan nama

Sebuah nilai boleh diberi ordinal eksplisit. Manual menyatakan nilainya harus menaik, sementara nilai tanpa
ordinal mendapat nilai sebelumnya plus satu dan gap diperbolehkan (`doc/language.md:213-224`):

```nim
type Token = enum
  word = (2, "word")
  number = 4
  symbol = 89

echo ord(word)      # 2
echo ord(symbol)    # 89
echo word           # word
```

Manual mewajibkan ordinal menaik (`doc/language.md:213-215`), dan pin ini tidak menegakkannya: `a = 5, b = 3, c`
tetap compile (`ch11-probes/rv11.nim`), `c` tetap mengambil nilai sebelumnya plus satu sehingga `ord` memberi
`5` / `3` / `4`, dan perbandingan mengikuti nilainya, jadi `a < b` bernilai `false`. Enum-nya menjadi holey,
dengan konsekuensi di bawah. Tulis daftar menaik; daftar menurun diterima, bukan ditolak, jadi compiler tidak
akan menangkapnya untuk lo.

Bentuk pasangan melampirkan string ke nilai, dan string itulah yang dicetak `$` (`doc/language.md:228-240`).
Hole adalah harga dari ordinal eksplisit: enum-nya lalu **bukan ordinal**, jadi tidak bisa mengindeks array dan
`inc`, `dec`, `succ` serta `pred` tidak tersedia (`doc/language.md:223-225`). Pada enum tanpa hole semuanya
tersedia, dan tidak ada yang menghentikan mereka keluar dari himpunan:

```nim
var c = red
inc c
echo c            # green
echo succ(blue)   # ordinal 3 — not a member, prints an empty line
```

Dua sisi kasar, dua-duanya diukur di pin ini. Pertama, `low` dan `high` adalah proc bawaan atas sebuah
`typedesc` (`lib/std/system/basic_types.nim:113-116`), dan di posisi argumen nama tanpa kualifikasi merujuk ke
proc itu, bukan ke member enum: enum dengan member bernama `low` membuat `ord(low)` gagal dengan
`auto does not match constraint T (system.nim(207, 1))`, pesan yang tidak pernah menyebut enum lo
(`ch11-probes/e10.nim`). Member-nya sendiri utuh — `ord(Level.low)` adalah `0` (`rv9.nim`). Jadi kualifikasikan
nilainya sebagai `Level.low`, atau hindari kedua nama itu.

Kedua, enum tidak punya pemeriksaan batas atas pada `inc` maupun pada konversi. `inc` pada `blue` berhasil dan
meninggalkan nilai berordinal `3`, yang bukan member; ia tercetak sebagai baris kosong dan tidak sama dengan
`red` (`ch11-probes/e13.nim`). `Color(7)` pada enum tiga nilai compile dengan cara yang sama dan mencetak kosong
(`e14.nim`), begitu juga `Color(-1)` yang dibangun dari variabel (`rv17.nim`). Alasannya mekanis: pemeriksaannya
mengunci pada tipe `range` (`src/nimony/contracts_fir.nim:2551-2569`, `:2492-2500`), dan enum bukan tipe range.
Nim 2 menolak literal `Color(7)` saat compile, me-raise `RangeDefect` untuk yang dihitung, dan `OverflowDefect`
pada `inc blue`. Ini dicatat di `ERRATA.md` sebagai watch row, bukan diajarkan sebagai perilaku benar: jangan
menelusuri enum melewati nilai terakhirnya, dan validasi integer hasil konversi sebelum dipercaya.

## Tipe distinct

Tipe distinct adalah tipe baru yang diturunkan dari base type, tidak kompatibel dengannya, dengan konversi
eksplisit yang diizinkan dua arah (`doc/language.md:1058-1065`). Ia berbagi representasi base-nya dan tidak
berbagi apa pun selain itu.

```nim
type Meters = distinct int

let m = Meters(4)
echo int(m)          # 4
echo sizeof(Meters)  # 8
echo sizeof(int)     # 8
```

Konversinya harus ditulis. Tidak ada arah yang implisit:

```nim
var m: Meters = 5    # Error: type mismatch: got: int64 but wanted: Meters
var i: int = Meters(4)   # Error: type mismatch: got: Meters but wanted: int64
```

`int64` di pesan-pesan itu bukan salah tulis — di pin ini `int` dan `int64` adalah tipe yang sama, yang sudah
ditetapkan Chapter 9 dan ditunjukkan lagi oleh `ch11-probes/d1.nim` dan `d12.nim`. Nama yang dipakai sebuah pesan
mengikuti ekspresinya, bukan base tipe distinct-nya: literal `int` menamai `int64` bahkan untuk
`distinct int32` (`rv7.nim`), sementara nilai yang sudah bertipe `int32` menamai `int32` (`rv8.nim`). Baca pesan
yang lo dapat; jangan menganggapnya selalu `int64`.

Operator juga tidak diwarisi. `Meters(2) + Meters(3)` adalah type error, begitu juga
`Meters(2) == Meters(2)`, sampai lo menulisnya (`ch11-probes/d3.nim`, `d4.nim`). Tulis body-nya dulu — itu
menyatakan operasinya:

```nim
func `+`(lhs, rhs: Meters): Meters = Meters(int(lhs) + int(rhs))
func `$`(v: Meters): string = $int(v) & "m"

echo int(Meters(2) + Meters(3))   # 5
echo $Meters(4)                   # 4m
```

Kalau operasinya persis operasi base-nya, `{.borrow.}` adalah jalan pintasnya:

```nim
func `+`(lhs, rhs: Meters): Meters {.borrow.}
```

`borrow` tidak menyalin body. Compiler membangkitkan body yang mengonversi tiap operand distinct ke base,
memanggil operasi base, lalu mengonversi hasilnya kembali (`src/nimony/semborrow.nim:17-60`). Ia tidak membawa
`noSideEffect` ikut, jadi operator yang seharusnya murni adalah `func`, dan itulah bentuk yang ditunjukkan
`doc/porting.md:51-62`. Body yang ditulis tangan adalah hal yang sama yang dieja penuh, dan itulah yang lo
butuhkan ketika operasinya bukan operasi base.

Base-nya tidak harus numerik. Tipe distinct atas sebuah object mempertahankan akses field base-nya lewat
konversi, dan menambahkan nama yang tidak dibawa field itu sendiri:

```nim
type Reading = object
  value: int
type Sample = distinct Reading

var s = Sample(Reading(value: 7))
echo s.Reading.value    # 7
```

Apa yang dibeli tipe distinct, dalam satu kalimat: layout field-nya milik base, aritmetikanya bukan miliknya,
dan routine yang meminta `Meters` tidak bisa diberi `int` atau `Seconds` secara tidak sengaja.

## Samples

Satu berkas membuktikan chapter ini: `samples/11-objects-enums-distinct/objects.nim`.

```
~/.local/opt/nimony/4ba90a7/bin/nimony c -r samples/11-objects-enums-distinct/objects.nim
```

Lewat verifier:

```
$ ./tools/verify-samples.sh
PASS samples/11-objects-enums-distinct/objects.nim exit=0
SUMMARY 10/10 passed, 0 failed
```

Outputnya, berurutan:

```
1
2
9
0
0
new
4
a
1
b
99
10
11
(11, 9)
0
2
true
green
1
5
3
red
green
blue
2
89
word
number
symbol
4
4
8
8
5
4m
7
```

Lima baris pertama adalah intinya: `x`, `y`, `y` sesudah assignment, lalu dua default dari `Point()`. `new` dan
`4` adalah default field yang dideklarasikan dan override dari constructor. Lalu `a`, `1`, `b`, `99`: nama dan
elemen salinannya berubah sementara aslinya tetap miliknya sendiri. `10` dan `11` adalah penjumlahan by-value
dan `x` sesudah `moveRight`; `(11, 9)` adalah `$p`. Blok enum berjalan `0`, `2`, `true`, `green`, `1` untuk
ordinal, urutan, kualifikasi dan `ord` lewat method syntax, lalu `5`, `3`, dan tiga nilai yang ditelusuri `for`.
`2` dan `89` adalah ordinal eksplisitnya; `word`, `number`, `symbol` adalah yang dicetak `$`. Lalu `4`, `4`, `8`,
`8` — dua konversi dan dua ukuran — dan `5`, `4m` untuk `+` yang di-borrow dan `$` distinct. `7` terakhir adalah
pembacaan field lewat konversi distinct.

## Latihan

1. Deklarasikan `type Point = object` dengan `x, y: int`, lalu `echo Point(x: 1).y`. Harapan: `0`.
2. Beri sebuah field default (`label: string = "new"`), cetak `Badge().label` dan `Badge(label: "x").label`.
   Harapan: `new` dan `x`.
3. Konstruksi dengan field yang tidak dimiliki tipe. Harapan: `undeclared field: 'z' for type P`.
4. Salin sebuah object dan ubah field pada salinannya. Harapan: aslinya tidak berubah.
5. Salin object yang field-nya `seq`, lalu tulis `b.items[0] = 99`. Harapan: `a.items[0]` masih `1`.
6. Deklarasikan dua object dengan satu field yang sama dan assign satu ke yang lain. Harapan: `type mismatch:
   got: B but wanted: A`.
7. `echo` sebuah object tanpa `$`. Harapan: `write stdout, P(x: 1)` dan daftar kandidat. Definisikan `$` untuk
   tipe itu, lalu cetak `echo $p`. Harapan: tercetak.
8. Cetak `ord(blue)`, `red < blue` dan `Color.green` untuk enum tiga nilai. Harapan: `2`, `true`, `green`.
9. Indeks `array[Color, int]` dengan `green` dan cetak `.len`. Harapan: nilai yang lo simpan, lalu `3`.
10. Deklarasikan enum dengan `a = 2, b = 4, c = 89` dan panggil `inc` pada salah satu nilai. Harapan: tidak
    terbangun — enum-nya tidak lagi ordinal.
11. Namai sebuah nilai enum `low` atau `high` dan panggil `ord` padanya. Harapan: type error, bukan angka yang
    salah. Kualifikasikan sebagai `Level.low` dan `ord`-nya kembali `0`.
12. `inc` sebuah nilai enum di member terakhirnya. Harapan: terbangun dan nilainya tercetak sebagai baris
    kosong — jangan diandalkan; jangan `inc` nilai yang sudah `high`, bandingkan dulu.
13. Bangun `Meters(4)`, cetak `int(m)`, `sizeof(Meters)` dan `sizeof(int)`. Harapan: `4`, `8`, `8`.
14. Tulis `var m: Meters = 5`. Harapan: `got: int64 but wanted: Meters`.
15. Tulis `Meters(2) + Meters(3)` tanpa operator yang didefinisikan. Harapan: type error. Tambahkan
    `{.borrow.}` ke sebuah `+` dan cetak `int(...)`. Harapan: `5`.

## Checklist chapter

draft 2026-11-12 · tech_review Momo 2026-11-12 · editorial_pass 2026-11-12 · frozen 2026-11-12
