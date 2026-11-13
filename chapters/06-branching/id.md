---
chapter: 6
title: Branching That Returns a Value
job: Use `if`, `case` and `when` as expressions, rely on exhaustive `case`, and label `break` because unlabelled `break` only leaves the innermost loop.
nimony_version: 0.6.3
nimony_commit: 4ba90a781b0b22d0821efaa153c129c37cef6143
toolchain: ~/.local/opt/nimony/4ba90a7
host_compiler: ~/.local/opt/nim-2.4.0
status: frozen
tech_review: Momo 2026-11-12
editorial_pass: 2026-11-12
samples: ["samples/06-branching/branching.nim"]
glossary_added: ["if expression", "case expression", "when", "exhaustive case", "labelled break", "block expression"]
---

# Percabangan yang Mengembalikan Nilai

## Untuk apa chapter ini

Di banyak bahasa, cabang adalah statement: dia menjalankan kode lalu selesai. Di Nimony keyword yang sama juga
menghasilkan **nilai**, jadi `if` dan `case` bisa berdiri di kanan `let`. Itu menghapus satu kelas kode
"deklarasikan dulu, isi di tiap cabang".

Ada dua aturan yang ikut fitur ini, dan keduanya ditegakkan compiler, bukan konvensi: `if` expression wajib
punya `else`, dan `case` atas tipe ordinal wajib menutup setiap nilai yang bisa dia tampung.

Chapter ini juga membahas dua cara keluar dari loop lebih awal, karena default-nya berubah dari Nim 2: `break`
tanpa label hanya keluar dari loop terdalam, jadi keluar dari dua loop bersarang butuh `block` berlabel.

## `if` sebagai statement

Bentuk statement-nya persis yang sudah kamu kenal (`doc/language.md:1737-1775`):

```
let score = 72
if score >= 90:
  echo "A"
elif score >= 70:
  echo "B"
else:
  echo "C"
```

Kondisi dievaluasi berurutan dan yang pertama benar menang. Di sini `else` opsional: kalau tidak ada cabang yang
diambil, eksekusi lanjut saja setelah `if`. Tiap cabang membuka scope sendiri, jadi nama yang dideklarasikan di
satu cabang tidak terlihat di cabang lain.

## `if` sebagai expression

Taruh konstruksi yang sama di tempat yang mengharapkan nilai, dan dia mengembalikan nilai cabang yang berjalan
(`doc/language.md:2069-2081`):

```
let score = 72
let label = if score >= 50: "pass" else: "fail"
echo label        # pass
```

Di bentuk ini `else` tidak opsional. Expression harus menghasilkan nilai di setiap jalur, dan compiler
menegakkannya lewat definite assignment, bukan lewat sintaks — errornya datang dari checker yang melacak apakah
sebuah variabel sudah ditulis sebelum dibaca (`src/nimony/contracts_fir.nim:4165`).

Diagnostiknya layak dilihat sekali, karena dia sama sekali tidak menyebut `else`:

```
let y = if false: 9
```

```
Error: cannot prove that `x has been initialized
```

Nama `x` di pesan itu bukan punyamu; sumber di atas tidak mendeklarasikan `x`. Dia tetap mencetak `x` apa pun
nama binding-nya: `let z = if false: 9` memberi baris yang sama, begitu juga kode yang sama di dalam proc. `x`
adalah temporary yang dibaca expression itu. Arti pesannya: nilai `y` tidak terbukti di jalur ketika kondisinya
salah. Tambahkan `else` dan dia compile:

```
let y = if false: 9 else: 0
echo y            # 0
```

Satu bentuk lolos dari pemeriksaan: ketika kondisinya literal `true`, jalur salahnya adalah dead code dan
dibuang, jadi `let y = if true: 9` compile. Jangan bergantung pada itu — tulis `else`-nya.

Rantai `elif` juga bekerja di bentuk expression, dan expression terakhir di dalam cabang adalah nilainya:

```
proc sign(n: int): string =
  result = if n < 0: "neg" elif n == 0: "zero" else: "pos"

echo sign(-2), " ", sign(0), " ", sign(7)   # neg zero pos
```

## `case` sebagai statement

`case` memilih berdasarkan nilai, bukan kondisi (`doc/language.md:1776-1804`):

```
let n = 3
case n
of 0: echo "zero"
of 1, 2: echo "small"
else: echo "large"
```

Cabang `of` menerima daftar nilai yang dipisah koma, dan entri rentang menutup satu span: `of 1..4`. Nilai di
cabang `of` harus constant expression — compiler memeriksa exhaustiveness, dan pemeriksaan itu perlu tahu
himpunannya lebih dulu.

Cabang `else` adalah fallback. Untuk selector ordinal dia opsional **hanya** kalau cabang-cabangnya sudah
menutup setiap nilai yang bisa ditampung tipe itu (`doc/language.md:1800-1804`).

## Exhaustiveness

Tutup semua nilai dan `else` tidak dibutuhkan:

```
type Color = enum red, green, blue
let c = green
let name = case c
  of red: "r"
  of green: "g"
  of blue: "b"
echo name         # g
```

Lewatkan satu dan compiler menolak, sambil menyebut yang hilang (`src/nimony/sem.nim:2746`):

```
of red: "r"
of green: "g"
```

```
Error: not all cases are covered; missing: {blue}
```

Pesan itu hadiah: tambahkan nilai yang dia sebut dan chapter soal fall-through tak sengaja tidak pernah terjadi.
Ketika selector-nya bukan enum — `int`, `char` — compiler tidak bisa mendaftar apa yang absen, jadi pesannya
telanjang (`src/nimony/sem.nim:2748`):

```
Error: not all cases are covered
```

Untuk tipe seperti itu obatnya `else`, dan domainnya jadi selebar tipenya. `of 0..59` plus `else` sudah
exhaustive. `of 'a'..'z'` dan `of 'A'..'Z'` **tidak** exhaustive untuk `char`, karena seluruh 256 nilai ada di
rentang itu; bentuk itu juga butuh `else`.

## `case` sebagai expression

Konstruksi yang sama menghasilkan nilai, dengan expression terakhir cabang sebagai hasilnya
(`doc/language.md:2086-2103`):

```
let grade = case score
  of 0..59: "F"
  else:
    if score >= 90: "A" else: "B"
echo grade        # B
```

Satu cabang boleh berisi beberapa statement; hanya yang terakhir jadi nilainya. Konsekuensi yang menarik:
`case` expression bisa membawa efek samping, yang biasanya tanda cabangnya melakukan terlalu banyak:

```
let label = case n
  of 1:
    echo "checking one"
    "one"
  of 2:
    echo "checking two"
    "two"
  else: "many"
```

Itu mencetak `checking two` dan mengikat `label` ke `"two"`. Pilih bentuk yang murni; pakai `case` statement
ketika cabangnya memang ada untuk menjalankan kode.

## Tidak ada `elif` di dalam `case`

Nim 2 mengizinkan `elif` setelah cabang `of` sebuah `case`. Nimony tidak, dan ini perlu diketahui sebelum kamu
menyalin contoh dari dokumentasi lama:

```
let r = case n
  of 0: "zero"
  elif n > 10: "medium"
  else: "small"
```

```
Error: not all cases are covered
Error: `elif` branch in a `case` is not supported; use `else:` with a nested `if`
Error: this branch in a `case` is not supported; use `else:` with a nested `if`
```

Baris pertama efek samping: `elif` yang ditolak tidak dihitung sebagai cakupan, jadi `case` yang sama juga
terlihat tidak exhaustive. Baris kedua dan ketiga adalah aturan yang sama menyala dua kali, pada `elif` dan pada
`else` yang mengikutinya. Selector string hanya menghasilkan dua baris itu. Obatnya yang disebut pesannya —
`if` bersarang biasa di dalam `else`, yang membersihkan ketiganya:

```
let r = case n
  of 0: "zero"
  else:
    if n > 10: "medium" else: "small"
```

Penolakannya disengaja dan masih baru: build sebelumnya membuang seluruh ekor setelah `elif` tanpa diagnostik,
yang diam-diam menghapus cabang default di source compiler itu sendiri (`src/nimony/sem.nim:3292-3307`).
Memunculkan error adalah pilihan yang lebih aman, jadi `case` di pin ini adalah `of`…`else`, dan apa pun yang
lebih kondisional masuk ke dalam `else`.

## Selector string: `else` tidak diwajibkan, jadi selalu tulis

`string` adalah pengecualian dari aturan di atas: `case` atas string tidak mewajibkan `else` atau `elif`
(`doc/language.md:1811-1812`), dan pemeriksaan exhaustiveness dilewati sepenuhnya untuknya
(`src/nimony/sem.nim:3287-3290`).

Melewati pemeriksaan tidak sama dengan menangani miss-nya. Di `case` **statement**, string yang tidak cocok
sekadar tidak melakukan apa-apa, dan itu tidak berbahaya:

```
var r = -1
case "zzz"
of "go": r = 111
of "stop": r = 222
echo r            # -1
```

Di `case` **expression**, miss-nya tidak berhenti di nilainya: di pin ini cabang `of` terakhir **dijalankan**
sebagai fallback, lengkap dengan efek sampingnya, dan expression itu mengambil nilainya.

```
var s = "zzz"
let r = case s
  of "go":
    echo "go branch"
    111
  of "stop":
    echo "stop branch"
    222
echo r
```

```
stop branch
222
```

Balik urutan cabangnya dan baris yang tercetak maupun angkanya ikut berubah. Tidak ada yang memperingatkanmu.
Karena itu aturan buku ini: **setiap `case` expression atas `string` diberi `else`**, diminta bahasa atau tidak.
Pemeriksaan yang dilewati itu terdokumentasi; fall-through ke cabang terakhir tidak. Diputuskan 2026-11-12:
pelewatan pemeriksaannya disengaja, fall-through-nya adalah defect yang belum diperbaiki di pin ini.

## `when`: bercabang saat compile time

`when` mirip `if` dan diselesaikan sebelum programnya ada (`doc/language.md:1872-1901`). Tiap kondisi harus
constant expression bertipe `bool`, dan hanya cabang yang diambil yang dikompilasi:

```
when sizeof(int) == 8:
  echo "64-bit int"
else:
  echo "not 64-bit"
```

Cabang yang tidak diambil tidak diperiksa secara semantik sama sekali, jadi dia boleh menyebut nama dan tipe yang
tidak ada:

```
when false:
  let q: int = "not an int"
echo "compiled"    # compiled
```

Begitulah program membawa kode khusus platform untuk platform yang tidak sedang dia bangun. Kondisinya sendiri
selalu diperiksa; kondisi yang tidak konstan ditolak, bukan ditunda:

```
let x = 5
when x > 0:
  echo "positive"
```

```
Error: cannot evaluate expression at compile time:
undeclared identifier: x
```

`when` tidak membuka scope baru, tidak seperti `if`. Definisi di dalam cabang yang diambil tetap terlihat
setelahnya:

```
proc f(): int =
  when true:
    let k = 41
  result = k + 1
echo f()          # 42
```

Jangan membangun apa pun di atas itu. Definisi hanya terlihat ketika cabangnya diambil, jadi nama yang
didefinisikan di dalam `when` sama kondisionalnya dengan cabang itu sendiri.

Bentuk expression-nya juga ada, dan itu cara jujur memilih konstanta:

```
let width = when sizeof(int) == 8: 64 else: 32
echo width        # 64
```

## `block`: expression dengan nama yang bisa kau tinggalkan

`block` mengelompokkan statement, dan yang bernama bisa ditinggalkan lebih awal (`doc/language.md:1946-1974`):

```
var found = false
block myblock:
  for i in 0..3:
    for j in 0..3:
      if i * j == 4:
        found = true
        break myblock
echo found        # true
```

`break myblock` meninggalkan block itu dan segala isinya, dan begitulah pencarian dua loop bersarang keluar
dalam satu langkah tanpa flag.

`block` juga bisa jadi expression, dan nilainya adalah expression terakhir di dalamnya
(`doc/language.md:2105-2119`):

```
let total = block:
  var sum = 0
  for i in 1..4:
    sum = sum + i
  sum
echo total        # 10
```

Bentuk itu menjaga variabel bantu tetap di luar scope sekitarnya: `sum` hanya ada di dalam block.

## Label: `break` default-nya keluar dari satu loop

Ini bagian yang menggigit kode Nim 2. `break` tanpa label hanya keluar dari loop terdalam
(`doc/language.md:1975-1990`), dan dia tidak pernah meninggalkan `block` (`doc/language.md:1963`;
`doc/differences.md:23`):

```
var pairs = 0
for i in 0..2:
  for j in 0..2:
    if j == 1:
      break
    pairs = pairs + 1
echo pairs        # 3
```

Tiga baris, masing-masing berhenti di `j == 1`: loop luarnya terus jalan. Untuk meninggalkan kedua loop, beri
nama block di sekelilingnya lalu break ke nama itu, seperti di bagian sebelumnya.

Dua aturan menjaga ini tetap lurus:

- `break <name>` meninggalkan block bernama itu, di mana pun `break`-nya berada di dalamnya.
- `break` tanpa nama meninggalkan loop terdalam, dan merupakan error di luar loop:
  ``Error: `break` only possible within a loop or a `block` statement``.

Block bernama bukan pengganti procedure. Kalau jalan keluarnya membawa nilai dari perhitungan yang layak diberi
nama, tulis proc-nya.

## Delta Nim 2: `break` berlabel, dan tidak ada `elif` di `case`

Dua kebiasaan dari Nim 2 berhenti bekerja di sini.

**Meninggalkan loop bersarang.** Di Nim 2, `break` tanpa label di dalam `block` di dalam loop bisa meninggalkan
block itu; di pin ini `break` tanpa label selalu berarti loop terdalam. Penggantinya `block` bernama plus
`break <name>` (`doc/differences.md:23`). `{.feature: "anonBlockBreaks".}` memulihkan bacaan lama per modul, tapi
buku ini tidak memakainya: bentuk bernama menyebut apa yang ditinggalkannya, dan itulah intinya.

**`elif` di dalam `case`.** Pin menolaknya dan menyuruhmu menyarangkan `if` di `else`
(`src/nimony/sem.nim:3305`). Contoh lama dan kebiasaan lama akan meraih rantai `elif`; tulis ulang.

Satu delta lagi, ke arah sebaliknya: bentuk **expression** `if`/`case`/`when` adalah cara normal menghasilkan
nilai, bukan trik. Kode Nim 2 yang mendeklarasikan variabel lalu mengisinya di tiap cabang biasanya bisa
dipadatkan jadi satu `let`.

## Sample

`samples/06-branching/branching.nim` — setiap konstruksi di chapter ini, berurutan:

```
B
pass
large
g
B
a
64-bit int
64
10
1
3
```

`B` dua kali bukan duplikat: yang pertama `if` statement, baris kelima nilai yang dihitung `case` dengan `if`
bersarang. `10` adalah block expression yang menjumlah `1..4`; `1` adalah labelled break yang menemukan
`i * j == 4` sekali; `3` adalah unlabelled break yang menghitung satu pasang per baris.

## Latihan

1. Tulis `let y = if false: 9`. Harapan: ``Error: cannot prove that `x has been initialized``. Tambahkan
   `else: 0` dan harapkan `0`.
2. Tulis `case` atas `enum red, green, blue` dengan hanya `red` dan `green` ditangani. Harapan:
   `not all cases are covered; missing: {blue}`. Tambahkan cabang `blue` dan harapkan compile.
3. Tulis `case` atas `int` dengan `of 0` dan `of 1` tanpa `else`. Harapan: `not all cases are covered`,
   tanpa nilai yang disebut.
4. Tulis `case` atas `char` dengan `of 'a'..'z'` dan `of 'A'..'Z'`. Harapan: `not all cases are covered` yang
   telanjang sama. Tambahkan `else: discard` dan harapkan compile.
5. Tulis bentuk `elif`-di-`case` dari chapter ini. Harapan: tiga error — `not all cases are covered`, lalu
   `` `elif` branch in a `case` is not supported; use `else:` with a nested `if` ``, lalu yang sama untuk
   `else` sesudahnya. Tulis ulang sebagai `else:` plus `if` dan harapkan compile.
6. Tulis `let r = case "zzz"` dengan `of "go": 111` dan `of "stop": 222`, tanpa `else`, dan satu `echo` di tiap
   cabang. Harapan: jalan pertama mencetak baris cabang terakhir lalu `222`. Tukar kedua cabang dan harapkan
   baris yang satunya lalu `111`. Lalu tambahkan `else: 999` dan harapkan `999` tanpa baris cabang.
7. Tulis `when x > 0` dengan `var x = 5` di atasnya. Harapan: `cannot evaluate expression at compile time` dan
   `undeclared identifier: x`.
8. Tulis `when false:` dengan `let q: int = "not an int"` di dalamnya. Harapan: compile. Hapus `when`-nya dan
   harapkan type mismatch.
9. Tulis `for` bersarang dua lapis dengan `break` tanpa label di loop dalam. Harapan: loop luar terus jalan.
   Bungkus keduanya dengan `block outer:` dan pakai `break outer`. Harapan: kedua loop berhenti.

## Checklist chapter

draft 2026-11-12 · tech_review Momo 2026-11-12 · editorial_pass 2026-11-12 · frozen 2026-11-12
