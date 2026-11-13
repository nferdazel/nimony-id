---
chapter: 16
title: Modules and Visibility
job: Split a program across files, mark what leaves a module with `*`, and import selectively.
nimony_version: 0.6.3
nimony_commit: 4ba90a781b0b22d0821efaa153c129c37cef6143
toolchain: ~/.local/opt/nimony/4ba90a7
host_compiler: ~/.local/opt/nim-2.4.0
status: frozen
tech_review: Momo 2026-11-13
editorial_pass: 2026-11-13
samples: [samples/16-modules-visibility/modules.nim]
glossary_added: [module, export marker, attached routine, re-export, include]
---

# Module dan Visibilitas

## Untuk apa bab ini

Semua program sampai sekarang cuma satu berkas. Program sungguhan tidak begitu, dan alasannya bukan kerapian:
batas berkas adalah tempat bahasa memutuskan siapa boleh memanggil apa. Keputusan itulah seluruh isi bab ini.
Nimony tidak punya manifest paket, tidak punya header module, dan tidak punya deklarasi namespace. Sebuah berkas
adalah module, namanya adalah namanya, dan satu `*` pada deklarasi adalah yang membuat berkas lain bisa melihatnya.

Urutan di bawah mengikuti pembaca yang memecah satu berkas jadi dua: bagaimana berkas kedua ikut ter-compile,
apa yang sebenarnya dibawa `import`, apa yang tetap privat dan apa kata compiler saat kamu meraihnya, lima ejaan
import dan apa yang disembunyikan masing-masing, lalu aturan yang jarang ditemui pembaca di bahasa lain — sebuah
panggilan juga melihat routine yang menempel ke tipe argumennya, diimpor atau tidak.

## Module adalah berkas

Nama berkas adalah nama module, tanpa `.nim`. `support/shapes.nim` adalah module `shapes`, dan itulah nama yang
dipakai sebuah import dan sebuah panggilan berkualifikasi, bukan path-nya:

```nim
import support/shapes
echo shapes.describe(square)
```

Kedua baris jalan di pin ini: import menerima path dengan `/`, dan bentuk berkualifikasi menerima nama module.
Subdirektori bukan namespace, jadi dua berkas bernama `shapes.nim` di direktori berbeda adalah dua module yang
sama-sama bernama `shapes`. Mengimpor keduanya lewat path tidak masalah selama panggilannya tanpa kualifikasi;
`shapes.aval()` yang berkualifikasi lalu gagal dengan `ambiguous identifier`, dan perbaikannya adalah alias pada
salah satu import.

Statement level module dari module yang diimpor berjalan sebelum body berkas yang mengimpornya, bahkan saat import
berada di tengah berkas:

```nim
# util.nim
echo "module init"
var ready* = 1

# main.nim
echo "main start"
import util
echo "ready ", ready
```

Itu mencetak `module init`, `main start`, `ready 1`. Import adalah statement waktu compile yang posisinya di
sumber tidak mengurutkan apa pun: statement module yang diimpor sudah berjalan saat `main start` muncul.

## Apa yang dibawa `import`

`import` membawa nama top-level yang diekspor dari module ke scope, tanpa kualifikasi:

```nim
# util.nim
proc greet*(name: string) =
  echo "hello ", name

# main.nim
import util
greet("ada")
```

Tidak ada prelude implisit untuk diwarisi. Tiap module menyebut apa yang dipakainya, termasuk `std/syncio` sebelum
ia bisa memanggil `echo`, dan itulah sebabnya setiap module di buku ini dimulai dengan import itu.

Import tidak transitif. Kalau `b` dan `c` sama-sama mengimpor `d`, berkas yang mengimpor `b` dan `c` tetap tidak
bisa memanggil routine `d`; ia harus mengimpor `d` sendiri. Itu disengaja, dan sifat itulah yang menahan perubahan
di `d` supaya tidak diam-diam melebarkan apa yang dilihat pemanggil `b`.

## Penanda export

Deklarasi tanpa `*` bersifat privat bagi module-nya. Panggilan ke sana dari berkas lain gagal, dan pesannya tidak
memakai kata privat:

```
main.nim(3, 1) Error: undeclared identifier: 'secret'
```

Itu pesan yang sama dengan nama yang tidak dideklarasikan, dan hanya itu diagnostiknya. Tidak ada baris "declared
here but not exported" untuk dibaca, jadi pembaca memeriksa deklarasi untuk `*` lebih dulu.

Penanda itu dipasang pada tiap deklarasi yang mau kamu lepaskan dari module: `proc`, `type`, `const`, `let` atau
`var`. Untuk field object ia dipasang terpisah, dan field adalah tempat aturannya paling mudah dilihat:

```nim
# util.nim
type Point* = object
  x: int
  y*: int

proc make*(a, b: int): Point = Point(x: a, y: b)

# main.nim
let p = make(1, 2)
echo p.y
echo p.x
```

`p.y` tercetak, dan `p.x` ditolak dengan `undeclared field: 'x' for type Point`. Tipenya diekspor dan field-nya
tidak, jadi pemanggil bisa memegang `Point` dan tidak bisa membaca separuhnya. Enum berbeda: mengekspor tipenya
membuat anggotanya bisa dipakai dengan nama, dan tidak ada penanda untuk mengekspor satu anggota tanpa saudaranya.

Aturan field punya satu sisi lunak yang perlu diketahui sebelum kamu bergantung padanya. Pemanggilan constructor
dari luar module tidak harus menyebut field privatnya:

```nim
let p = Point(y: 2)
```

Itu ter-compile, dan `x` yang privat mengambil nilai default, `0`. Tidak ada peringatan. Constructor bukan
pemeriksaan bahwa tiap field sudah dipertimbangkan, jadi object dengan field privat butuh routine constructor yang
mengisinya, dan pemanggil sebaiknya tidak membangun object itu sendiri.

## Membaca apa yang bukan nama

Tipe privat yang dikembalikan routine yang diekspor adalah handle yang bisa dipakai:

```nim
# util.nim
type Hidden = object
  v: int
proc make*(): Hidden = Hidden(v: 5)
proc show*(h: Hidden) = echo "hidden ", h.v

# main.nim
let h = make()
show(h)
```

Itu mencetak `hidden 5`. Pemanggil tidak bisa menyebut `Hidden`, tidak bisa mendeklarasikan variabel bertipe itu,
dan tidak bisa membaca `h.v`; ia bisa memegang nilainya, mengembalikannya, dan membiarkan routine module itu
bekerja padanya. Ini enkapsulasi termurah yang disediakan bahasa, dan harganya satu `*` yang tidak ditulis.

## Lima ejaan import

`import m` yang polos adalah yang di atas. Empat lainnya mempersempitnya, dan bedanya ada pada apa yang tetap
terlihat, bukan pada apa yang dimuat.

```nim
import util as u        # calls go through u., and util. is no longer a name
import util except greet
from util import greet  # only greet, unqualified
from util import nil    # nothing unqualified; util.greet still works
```

`import util as u` memberi module nama kedua dan mengambil nama pertamanya: sesudahnya `u.greet("ada")` build dan
`util.greet("ada")` gagal dengan `undeclared identifier: util`. Yang tidak dilakukannya adalah menyembunyikan nama
tanpa kualifikasi — `greet("ada")` tetap jalan, karena alias mengganti nama kualifiernya, bukan simbol yang
diimpor.

`import util except greet` mengimpor semuanya kecuali `greet`, dan memanggil `greet` lalu gagal sebagai identifier
yang tidak dideklarasikan. Daftarnya tidak diperiksa terhadap apa yang diekspor module: menyebut routine privat di
sana diterima diam-diam, jadi salah ketik di daftar `except` tidak mempersempit apa pun dan tidak melaporkan apa
pun.

`from util import greet` mengimpor satu nama itu saja dan tidak yang lain; routine kedua yang diekspor dari module
yang sama jadi tidak dideklarasikan. Menyebut routine privat di sana ditolak dengan pesan `undeclared identifier`
yang sama.

`from util import nil` tidak mengimpor nama apa pun dan mempertahankan bentuk berkualifikasi, yang merupakan cara
sebuah module dipakai sepenuhnya lewat panggilan `util.name`. Ia berpasangan dengan bagian berikutnya: routine
yang menempel ke sebuah tipe tetap resolve walau tidak ada yang diimpor tanpa kualifikasi.

## Routine yang menempel ke tipe argumen

Inilah aturan yang membuat sebuah panggilan ter-compile padahal tidak ada apa pun di scope yang mendeklarasikan
routine itu. `doc/language.md:1280-1315` menyebutkannya: untuk tiap argumen yang tipenya tipe nominal yang
dideklarasikan di module lain, routine top-level yang diekspor dari module itu dengan nama panggilan tersebut dan
sebuah parameter bertipe itu ikut jadi kandidat, seolah diimpor. Tipe itu boleh berada di balik `var`, `sink`,
`lent`, `out`, `ref` atau `ptr`, dan untuk instance generic yang dipakai adalah module yang mendeklarasikan
generic-nya.

Jadi ini ter-compile dengan hanya tipenya diimpor:

```nim
# inner.nim
type Thing* = object
  v*: int
proc show*(t: Thing) = echo "thing ", t.v
proc banner*() = echo "unrelated"

# main.nim
from inner import Thing
let t = Thing(v: 3)
show(t)
```

`show` resolve dan `banner` tidak, karena `banner` tidak pernah menyebut `Thing`. Batasnya adalah daftar parameter,
bukan module-nya: routine dari module yang sama yang mengambil tipe itu bisa diraih, dan yang tidak mengambilnya
tidak. Ini juga bukan module si argumen secara umum — routine yang dideklarasikan di module ketiga yang kebetulan
mengambil `Thing` tidak menempel, dan tetap tak terlihat kecuali diimpor.

Dua konsekuensi penting dalam praktik. Sebuah module bisa diimpor dengan `from m import nil` dan tetap dipakai
lewat routine tipe-tipenya, berkualifikasi atau tidak. Dan routine yang tidak diekspor tidak pernah menempel, jadi
menandai routine privat sudah cukup untuk mengeluarkannya dari pencarian ini juga.

## `export` meneruskan

Module yang membungkus module lain bisa meneruskannya, supaya pemanggilnya tidak perlu mengimpor keduanya:

```nim
# support/report.nim
import shapes
export shapes
```

Sesudah itu, berkas yang mengimpor `support/report` melihat `Shape`, `shape` dan `describe` tanpa mengimpor
`shapes`. Penerusan juga bisa menyebut satu simbol, `export shapes.Shape`, dan tipenya menyeberang sementara
routine lain module itu tidak — kecuali yang menempel padanya, yang datang lewat aturan bagian sebelumnya.

Nama dalam statement `export` adalah nama module, bukan path, dan ia resolve seperti import: relatif terhadap
berkas yang mengekspornya. Module di dalam subdirektori karena itu mengimpor saudaranya sebagai `import shapes`,
bukan `import support/shapes`, dan mengekspornya dengan cara yang sama.

Pembedaan terakhir itu bukan soal kerapian. Operand `export` yang bukan nama polos atau `module.name` — path adalah
cara realistis memicunya, tapi `export 3` yang telanjang sudah cukup — tidak pernah melaporkan apa pun: front end
berputar di CPU penuh dan membengkakkan memori tanpa satu baris output, dan ia tidak berhenti sendiri. Kegagalannya
ada di statement export itu, bukan di resolusi path, jadi `import` yang benar di atasnya tidak menyelamatkan build.

## `include`

`include` bukan import. Ia menempelkan teks berkas ke module yang mengincludenya, jadi tidak ada yang diekspor dan
tidak ada visibilitas yang berlaku:

```nim
# part.nim
proc twice(n: int): int = n * 2

# main.nim
include part
echo twice(4)
```

Itu mencetak `8` tanpa `*` di mana pun, karena `twice` sekarang adalah deklarasi milik `main`. Pakai `include`
untuk memecah body satu module ke beberapa berkas, jangan untuk berbagi kode antar module: apa yang dideklarasikan
berkas yang di-include menjadi milik peng-include-nya, termasuk nama privatnya.

## Siklus

Dua module yang saling mengimpor ditolak:

```
Error: import cycle: 'b.nim' imports 'a.nim' without {.cyclic.}; every import on a cycle needs it
```

Pragma pada tiap import di siklus itu membuatnya build. Ia opt-in yang disengaja, dan pesannya menyebut berkas dan
import yang kurang, jadi perbaikannya tertulis jelas: pasang `{.cyclic.}` di keduanya.

## Saat dua module mengekspor nama yang sama

Dua import yang membawa nama sama membuat panggilannya ambigu, dan pesannya mendaftar kedua deklarasi dengan
berkas dan baris masing-masing:

```
main.nim(3, 5) Error: ambiguous call: 'show'
proc (n: int64) (declared in one.nim(2, 1))
proc (n: int64) (declared in two.nim(2, 1))
```

Perbaikannya adalah mengeluarkan satu sisi dari import polos: `import one except show`, atau `one.show(...)` yang
berkualifikasi, atau mempersempit kedua sisi, `from one import show` bersama `from two import nil`. `from` di satu
sisi saja tidak menyelesaikannya selama sisi lain masih import polos — kedua deklarasi tetap di scope dan
panggilannya tetap ambigu.

## Global mutable melintasi batas module

`var` yang diekspor bukan shared state yang diharapkan pembaca. Penulisan langsung ke sana dari body routine
ditolak, di module-nya sendiri maupun di module lain:

```
util.nim(5, 7) Error: unsynchronized access to global variable 'counter'; pass it to a `.sync` routine or use `{.cast(assumeSync).}`
```

Statement level module dikecualikan, karena inisialisasi module berjalan single-threaded, jadi `counter = 9` di
atas berkas ter-compile dan bekerja. Body routine butuh pemeriksaan itu dimatikan untuk akses tersebut, dan
`{.cast(assumeSync).}:` di sekitar blok melakukannya:

```nim
proc bump() =
  {.cast(assumeSync).}:
    inc counter
```

Saran di pesan itu adalah jalur keempat dan ia nyata: serahkan global itu — atau salah satu field atau elemennya —
ke parameter `var` atau `ptr` sebuah routine `.sync`, yang boleh routine tulisan kamu sendiri:
`proc own(p: var int) {.sync.}` lalu `own(counter)` build dan menaikkan nilainya. `.sync` dipercaya, bukan diperiksa.
Jadi jalurnya adalah statement level module, `{.cast(assumeSync).}:`, `{.feature: "assumeSync".}`, dan routine
`.sync`. Keempatnya janji yang kamu buat, bukan pemeriksaan yang dibuang compiler.

## Dua tempat manual tidak cocok dengan pin

Statement import diterima di dalam body routine, padahal `doc/language.md` bilang ia hanya boleh di level top, dan
ia berlaku untuk seluruh module: panggilan sesudah routine yang memuat import itu juga build. Bab ini mengajar
bentuk top-level. Yang lain lebih buruk. Operand `export` yang bukan nama memutar front end tanpa output alih-alih
gagal, seperti yang bagian `export` sebutkan. Keduanya ada di catatan review dan di `ERRATA.md`; tidak satu pun
mengubah apa yang diajarkan bab ini.

## Nim 2 delta

*Apa yang Nim 2 lakukan.* Module juga sebuah berkas, `*` berarti ekspor, dan `import x as y`, daftar `except` serta
`from ... import` ada dengan ejaan yang sama. Nim 2 juga menyuntikkan `system` ke mana-mana, jadi `echo` tidak
butuh import, dan resolusi overload-nya tidak mencapai module sebuah tipe untuk panggilan biasa.

*Apa yang Nimony lakukan.* Ejaannya bertahan; dua kebiasaan tidak. Tiap module mengimpor `std/syncio` sebelum ia
meng-echo, dan sebuah panggilan bisa menemukan routine yang menempel ke tipe argumennya walau module itu diimpor
dengan `from m import nil`. Aturan variabel yang diekspor juga baru dalam praktik: global mutable ditolak dari body
routine kecuali pemeriksaannya dimatikan untuk akses itu.

*Apa yang rusak kalau kebiasaannya dibawa.* Module yang disalin dari Nim 2 gagal build pada `echo` sampai
`std/syncio` diimpor, dan import yang diganti nama sebagai cara menyembunyikan nama tidak menyembunyikannya —
`import util as u` tetap membuat `greet` bisa dipanggil. Raih `from` atau `except` saat yang kamu maksud adalah
mempersempit.

## Samples

`samples/16-modules-visibility/modules.nim`, dengan tiga berkas di bawah `samples/16-modules-visibility/support/`,
di-compile dan dijalankan di pin commit:

```
$ nimony c -r samples/16-modules-visibility/modules.nim
square: 4 sides, 360 degrees
4 sides
square: 4 sides, 360 degrees
SQUARE
note: square
square has 4 sides
```

Enam baris, dengan urutan itu. Yang pertama datang lewat module yang diteruskan ulang, yang kedua dari routine yang
ditambahkan module itu, yang ketiga routine yang sama dipanggil lewat nama module, dan tiga terakhir menunjukkan
routine module kedua, routine berkas yang di-include, dan pembacaan field. `tools/verify-samples.sh` mengompilasi
dan menjalankannya bersama sisa buku dan tidak membandingkan stdout, jadi enam baris ini yang diperiksa dengan mata.

## Cek

1. Pecah program satu berkas jadi dua, ekspor hanya routine yang dibutuhkan yang lain. Baca pesan yang kamu dapat
   sebelum menambahkan `*`, lalu tambahkan dan pastikan tidak ada yang lain berubah.
2. Ambil `Point` dari bab ini dan bangun satu dari `main` tanpa menyebut `x`. Cetak `p.y`, lalu tambahkan
   routine di module yang mencetak `p.x` dan terangkan kenapa nilai yang kamu lihat adalah `0`.
3. Ubah `import util` jadi `from util import nil` dan buat tiap panggilan berkualifikasi. Lalu hapus kualifikasi
   dari panggilan yang argumennya tipe yang diekspor itu dan terangkan kenapa ia tetap build.
4. Buat dua module saling mengimpor, baca pesan siklusnya, lalu tambahkan `{.cyclic.}` di tempat yang diminta.
   Sebutkan apa yang harus kamu ubah di module kedua, bukan cuma yang pertama.
5. Ekspor sebuah `var` dan tulis dari body routine. Baca pesannya, lalu perbaiki dengan `{.cast(assumeSync).}` dan
   tulis apa yang kamu janjikan ke compiler.

## Chapter checklist

`draft 2026-11-13 · tech_review Momo 2026-11-13 · editorial_pass 2026-11-13 · frozen 2026-11-13`
