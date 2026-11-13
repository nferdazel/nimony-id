---
chapter: 17
title: Generics and Concepts
job: Parameterize routines, types and constraints that are checked structurally, using concepts instead of implicit type-class generics.
nimony_version: 0.6.3
nimony_commit: 4ba90a781b0b22d0821efaa153c129c37cef6143
toolchain: ~/.local/opt/nimony/4ba90a7
host_compiler: ~/.local/opt/nim-2.4.0
status: frozen
tech_review: Momo 2026-11-13
editorial_pass: 2026-11-13
samples: [samples/17-generics-concepts/generics.nim]
glossary_added: [type parameter, static parameter, concept inheritance, Self, deferred body check]
---

# Generic dan Concept

## Untuk apa chapter ini

Sebuah routine generic adalah satu potong sumber yang menjadi beberapa routine, satu per tipe yang memakainya.
Concept adalah constraint yang menentukan tipe mana yang boleh dipakai sama sekali. Nimony memeriksa keduanya di
definisi, bukan dengan menempel teks lalu berharap: body generic diperiksa tipenya sekali, terhadap apa yang
dijanjikan parameternya, dan concept diperiksa sebagai sekumpulan panggilan terhadap tipenya saat instansiasi. Itu
sebabnya error di chapter ini datang sebelum program berjalan, dan sebabnya pesannya menyebut sebuah constraint
alih-alih hasil ekspansi template.

## Type parameter pada proc

Kurung siku sesudah nama routine memperkenalkan type parameter:

```nim
proc id[T](x: T): T = x

echo id(3)        # 3
echo id("s")      # s
```

Tipenya diinfer dari argumen, dan routine-nya diinstansiasi sekali per tipe. Instansiasinya juga bisa ditulis
eksplisit saat inferensi bukan yang lo mau:

```nim
echo id[int](3)   # 3
```

Dua nama bersaing saat dua-duanya cocok. Routine konkret mengalahkan yang generic: dengan `pick(x: int)` dan
`pick[T](x: T)` di scope, `pick(3)` memanggil yang konkret dan `pick("s")` jatuh ke yang generic. Kandidat generic
dipertimbangkan sesudah yang biasa, jadi routine generic adalah cadangan kecuali tidak ada kandidat konkret sama
sekali.

## Tipe generic

`type` menerima kurung siku yang sama, dan parameternya bisa dipakai di field-nya dan di constructor:

```nim
type Box[T] = object
  v: T

let b = Box[int](v: 3)
echo b.v          # 3
```

Bentuk eksplisitnya menamai instance-nya, `Box[int](v: 3)`. `Box(v: 3)` yang telanjang juga build, karena tipe
field-nya adalah `T` dan argumennya yang menentukan; tulis instance-nya saat lo mau panggilannya menyebut `T` mana
yang dihasilkan. Constraint boleh duduk di type parameter juga, dan tiap instance lalu harus memenuhinya:

```nim
type Box[T: Addable] = object
  v: T
```

## Beberapa parameter, dan apa yang kembali

Parameter dipisah koma di dalam satu kurung siku, dan mereka independen: `proc pair[A, B](a: A, b: B): (A, B)`
mengembalikan tuple yang kedua belahnya mempertahankan tipenya sendiri, jadi `pair(1, "x")[1]` adalah `string`.
Routine generic juga boleh membangun dan mengembalikan container bertipe parameternya:

```nim
proc pairUp[T](a: T): seq[T] = @[a, a]
echo pairUp(7).len   # 2
```

Tidak ada bagian dari tipe hasil yang perlu dieja di call site; instansiasinya mengikuti argumennya.

## Parameter static

`static int` adalah parameter nilai yang diketahui saat compile, bukan tipe:

```nim
proc fill[N: static int](x: int): seq[int] =
  var s = @[0]
  s.setLen(0)
  for i in 0..<N: s.add x
  s

echo fill[3](7).len   # 3
```

Dua baris yang memulai `s` bukan upacara. `var s: seq[int]` lalu `s.add x` ditolak dengan `cannot prove that s has
been initialized`, yang merupakan aturan definite assignment Chapter 3 dan bukan urusan parameter static; `seq`
kosong yang dibangun dari literal memberi body sebuah nilai yang bisa dibuktikan sudah ditulis.

Bentuk kurung siku adalah cara nilainya disuplai, karena tidak ada argumen untuk menginfernya. Body boleh memakai
`N` di mana pun sebuah konstanta diizinkan.

## Diperiksa, bukan ditempel

Body generic diperiksa di titik definisi terhadap apa yang dijanjikan parameternya. Menulis field yang tidak
dimiliki parameter gagal di sana, bukan di panggilan:

```
main.nim(2, 28) Error: undeclared field: 'nonexistent' for type T
```

Konsekuensinya, routine generic ter-compile untuk tiap tipe yang memenuhi atau tidak sama sekali, dan compiler tidak
menunggu instansiasi untuk memberi tahu bahwa body-nya omong kosong.

`when` yang kondisinya bergantung pada type parameter adalah pengecualian yang terlihat seperti lubang. Ia
diperiksa sebagai `if` dengan kondisi konstan: tiap cabang diperiksa terhadap constraint-nya, dan tiap cabang punya
scope sendiri. Nama yang dideklarasikan di dalam cabang seperti itu karena itu tidak terlihat sesudahnya, dan
error-nya datang saat routine diinstansiasi:

```nim
proc f[T](x: T) =
  when T is int:
    var y = 1
  else:
    var y = "a"
  echo y          # Error: undeclared identifier: y
```

Deklarasikan namanya sebelum `when` saat kedua cabang membutuhkannya. `{.untyped.}` menghapus batasan ini dan
memindahkan pemeriksaannya sepenuhnya ke instansiasi, di mana `when` adalah conditional biasa dan cabang-cabangnya
berbagi scope:

```nim
proc show[T](x: T): string {.untyped.} =
  when T is string:
    "str: " & x
  elif T is int:
    "int: " & $x
  else:
    "other"

echo show("a")    # str: a
echo show(2)      # int: 2
```

Pilih bentuk yang diperiksa. `{.untyped.}` adalah janji bahwa tiap instansiasi ter-compile, dibuat sebelum lo
melihat satu pun.

## Concept: constraint adalah daftar panggilan

Concept menjelaskan apa yang harus bisa dilakukan sebuah tipe, sebagai daftar signature routine:

```nim
type Addable = concept
  proc `+`(a, b: Self): Self
```

`Self` berarti tipe yang sedang diperiksa (`doc/language.md:4319`). Sebuah tipe memenuhi concept saat tiap
requirement, dibaca sebagai panggilan dengan `Self` diganti tipe itu, resolve lewat overload resolution biasa dan
mengembalikan sesuatu yang bisa di-assign ke hasil yang dideklarasikan (`doc/language.md:4317-4339`). Jadi ini
menerima `int` karena `+` pada dua `int` ada dan mengembalikan `int`:

```nim
proc twice[T: Addable](x: T): T = x + x
echo twice(3)     # 6
```

Concept dengan type parameter adalah concept container, dan parameternya diikat dari requirement-nya. `Findable[T]`
dari manual adalah contoh kerjanya: `iterator items(x: Self): T` plus `==` pada `T` memberi generic itu tipe elemen
sekaligus perbandingan yang dibutuhkannya, jadi collection bikinan sendiri jalan tanpa satu deklarasi pun yang
menyebutnya:

```nim
type Findable[T] = concept
  iterator items(x: Self): T
  proc `==`(a, b: T): bool

proc find[T; C: Findable[T]](x: C; elem: T): int = ...
```

Dengan `MyCollection` yang menyediakan `items`, `find(myCollection, 3)` mencetak `2` (`doc/language.md:4429-4441`).
Parameter `C: Findable[T]` juga bukan hiasan; bagian terakhir chapter ini menunjukkan apa yang dilakukan ejaan
`x: Findable[T]` sebagai gantinya.

## Saat sebuah tipe tidak memenuhinya

Concept diperiksa di panggilan, dan pesannya menyebut tipe, constraint-nya, dan di mana constraint itu
dideklarasikan:

```
main.nim(8, 1) Trace: instantiation from here
main.nim(8, 11) Error: Type mismatch at [position]
twice(n)
[1] NoAdd does not match constraint Addable (declared in main.nim(6, 1))
```

Tiga hal di pesan itu layak dibaca, bukan di-skim. Baris trace adalah instansiasinya, bukan deklarasinya. `[N]`
adalah posisi argumen yang gagal cocok, dan baris yang tercetak di bawahnya adalah kandidat yang dicoba di posisi
itu, jadi panggilan dua argumen yang gagal di argumen kedua melaporkan `[2]`. Dan kegagalannya dilaporkan terhadap
constraint, bukan terhadap routine yang hilang: panggilan routine tidak mencetak baris `missing: proc ...`, jadi
jangan berharap pesannya mendaftar requirement mana yang kurang. Kalimat yang perlu dibaca adalah yang terakhir.

Satu bentuk memang mencetak baris kedua itu, dan itu tipe, bukan panggilan: `Box[NoAdd]` memberi `NoAdd does not
match constraint Addable` lalu `missing: proc +(a: Self, b: Self)`. Argumen tipe generic yang gagal menamai
requirement-nya; panggilan routine yang gagal cuma menamai constraint-nya.

## Pewarisan concept

`concept of` menambahkan requirement induk ke milik anak, dan keduanya diperiksa dengan cara yang sama:

```nim
type
  Named = concept
    proc name(x: Self): string
  Aged = concept of Named
    proc age(x: Self): int

proc describe[T: Aged](x: T): string = name(x) & " " & $age(x)
```

`Person` dengan kedua routine memenuhi `Aged`, dan `describe` mencetak `ada 3`. Tipe yang punya `age` tapi tidak
punya `name` gagal di requirement warisannya, dan pesannya menamai anaknya: `P2 does not match constraint Aged`.
Requirement induknya yang gagal, tapi pesannya tidak bilang yang mana dari keduanya, jadi bacalah constraint yang
lo tulis, bukan yang lo warisi.

## `Self` dan `var Self`

`Self` di sebuah requirement berarti tipe yang sedang diperiksa, dan qualifier-nya mengatakan apa yang boleh
dilakukan routine itu pada argumennya. Requirement `var Self` adalah yang ditulis untuk routine yang memutasi, dan
routine yang type parameter-nya `var T` bisa meneruskannya:

```nim
type Bumpable = concept
  proc bump(x: var Self)

proc bump(x: var C) = x.v += 1
proc run[T: Bumpable](x: var T) = bump(x)

var c = C(v: 1)
run(c)            # c.v becomes 2
```

Qualifier-nya tidak ditegakkan saat concept dipenuhi. Requirement `var Self` menerima kandidat yang mengambil
nilai, dan mutasi yang dijanjikan requirement itu tidak pernah terjadi; requirement `Self` biasa menerima kandidat
`var`, dan mutasinya terjadi. Yang ditegakkan adalah panggilan di body-nya sendiri: `run[T](x: var T)` bisa
meneruskan `x`, dan `run[T](x: T)` tidak bisa — `cannot pass x to var/out T parameter`. Tulis qualifier yang lo
maksud, lalu biarkan panggilan di body yang jadi pemeriksanya, bukan requirement-nya.

## Dua aturan manual yang tidak dijaga pin ini

Dua-duanya ada di `doc/language.md`, dan dua-duanya salah di commit ini. Layak diketahui karena pembaca yang
mengikutinya menulis kode yang jalan tapi percaya seharusnya tidak.

Yang pertama adalah batasan inferensi. `doc/language.md:4477-4499` bilang `var T` tidak bisa diinfer, dan contohnya
ditolak. Di pin ini program yang sama ter-compile, jalan, dan memutasi variabel si pemanggil lewat parameter `var` —
`g(v, i)` meninggalkan `i` di `100` — dan bentuk eksplisit `g[var int](v, i)` juga build. Perlakukan inferensi
`var T` sebagai didukung, sambil tetap menulis signature eksplisit saat inferensinya akan melakukan kerja nyata:
compiler adalah separuh yang kurang bisa diandalkan dari pasangan itu.

Yang kedua adalah kalimat di `doc/language.md:4427`: concept "hanya bisa dipakai sebagai constraint sebuah type
parameter". Pin ini menerima concept di posisi parameter biasa, `proc f(x: Addable)`, dan satu instansiasi jalan:

```nim
proc f(x: Addable) = echo "took it"
f(3)              # took it
```

Panggil dengan tipe kedua yang memenuhi dan build-nya mati di backend dengan `Symbol not found in NIF module:
Addable.0` dan sebuah `AssertionDefect`. Jadi deklarasinya diterima, instansiasi pertamanya jalan, dan programnya
tidak bisa dipakai. Itu defect, bukan fitur untuk dipelajari; chapter ini menulis constraint-nya di type parameter,
`[T: Addable]`, setiap kali.

Contoh manual yang berhubungan, `proc find[T](x: Findable[T]; elem: T)`, gagal satu langkah lebih awal dan karena
sebab yang sama: ia ditolak di definisinya, pada `items(x)` dan pada `a == elem`, sebelum ada panggilan. Memanggilnya
mengulang penolakan itu di call site — `expected: Findable[T] but got: MyCollection` — tapi pesan itu bukan yang
memperbaikinya; signature-nya. Tulis container-nya sebagai parameter sendiri, `proc find[T; C: Findable[T]](x: C;
elem: T)`, yang merupakan bentuk yang dipakai bagian di atas.

Bentuk yang sama muncul saat nama concept itu sendiri dipakai di tempat `Self`. Requirement di dalam concept-nya,
``proc `<`(a, b: Comparable): bool``, diterima tanpa satu diagnostik pun; proc yang lalu mengambil `Comparable`
sebagai tipe parameter ditolak di definisinya sendiri, dan panggilannya mengulangnya sebagai `expected: Comparable
but got: int64`. Di dalam concept, nama yang ditulis adalah `Self`; di luarnya, concept bukan tipe parameter.

## Nim 2 delta

*Apa yang Nim 2 lakukan.* Type class di posisi parameter membuat generic implisit: `proc f(x: Addable)` adalah
singkatan untuk routine yang diinstansiasi per tipe yang memenuhi, dan Nim 2 menyubstitusi tipe argumennya ke body
tanpa memeriksanya lebih dulu. Template, concept dan generic semuanya berbagi rasa tempel-lalu-coba itu, dan
sebuah body bisa memuat akses field yang cuma gagal untuk tipe yang tidak memilikinya.

*Apa yang Nimony lakukan.* Bentuk kurung siku `[T]` adalah generic-nya, concept ditulis sebagai `[T: Addable]` di
tempat yang seharusnya, dan body-nya diperiksa di definisi. Concept di posisi parameter biasa diterima front end
tapi merusak backend pada instansiasi kedua, jadi itu bukan jalur sama sekali. `{.untyped.}` adalah opt-out
eksplisit untuk kebiasaan tempel-lalu-coba itu.

*Apa yang rusak kalau kebiasaannya dibawa.* `proc f(x: Addable)` memindahkan generic-nya jadi crash runtime
alih-alih error compile, dan body yang ditulis untuk satu tipe gagal di definisi walau tiap call site-nya
sebenarnya baik-baik saja. Tulis kurung sikunya, taruh concept di type parameter, dan raih `{.untyped.}` hanya saat
body-nya benar-benar perlu melihat tipenya.

## Samples

`samples/17-generics-concepts/generics.nim`, di-compile dan dijalankan di pin commit:

```
$ nimony c -r samples/17-generics-concepts/generics.nim
42
6
12
```

Tiga baris itu adalah `twice(21)`, `sumAll` atas `@[1, 2, 3]`, dan `sumAll` atas dua nilai `Money`, jadi satu
concept mengikat tiga instansiasi dari dua routine, dan panggilan kedua meraih `+` yang dideklarasikan di berkas
yang sama.

## Cek

1. Tulis `proc id[T](x: T): T` dan panggil dengan `int` dan `string`. Lalu ganti body-nya dengan akses field yang
   tidak dimiliki parameternya, dan baca di mana error-nya mendarat.
2. Tambahkan tipe `Box[T]`, lalu `Box[T: Addable]` yang dibatasi, dan coba instansiasi yang kedua dengan tipe yang
   tidak punya `+`.
3. Pindahkan deklarasi nama ke dalam cabang `when T is int` dan panggil routine-nya. Baca error-nya, lalu
   deklarasikan namanya sebelum `when` dan pastikan ia build.
4. Tulis concept dengan dua requirement dan `concept of` sebuah concept ketiga. Hapus salah satu routine induk
   dari tipe itu dan sebutkan constraint mana yang dinamai pesannya.
5. Tulis `proc f(x: Addable)`, panggil sekali dengan `int`, lalu dengan tipe kedua yang memenuhi. Catat apa yang
   terjadi di tiap langkah dan bentuk mana yang seharusnya lo tulis.

## Chapter checklist

`draft 2026-11-13 · tech_review Momo 2026-11-13 · editorial_pass 2026-11-13 · frozen 2026-11-13`
