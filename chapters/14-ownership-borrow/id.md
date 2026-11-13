---
chapter: 14
title: Ownership and Borrow Checking
job: Show who owns a value, which aliasing and escaping-borrow shapes the compiler rejects, and why `move` is not a checked operation at this pin.
nimony_version: 0.6.3
nimony_commit: 4ba90a781b0b22d0821efaa153c129c37cef6143
toolchain: ~/.local/opt/nimony/4ba90a7
host_compiler: ~/.local/opt/nim-2.4.0
status: frozen
tech_review: Momo 2026-11-13
editorial_pass: 2026-11-13
samples: [samples/14-ownership-borrow/ownership.nim]
glossary_added: [ownership, borrow, alias, moved-from state, ensureMove]
---

# Ownership dan Pemeriksaan Borrow

## Untuk apa chapter ini

Chapter 13 memberi lo dua cara mencapai storage milik nama lain: `ref` yang dikelola dan `ptr` mentah. Chapter
ini soal aturan yang datang bersama cara itu. Siapa yang bertanggung jawab atas sebuah nilai, kapan dua nama
boleh menunjuk storage yang tumpang tindih, dan apa yang compiler tolak sebelum program lo sempat jalan.

Di pin ini compiler menegakkan tiga aturan, dan cuma tiga. Sebuah panggilan tidak boleh mengirim lokasi yang
sama sekali sebagai argumen mutable dan sekali sebagai argumen yang membaca storage pemanggil. Sebuah borrow
tidak boleh hidup lebih lama dari storage yang ia pinjam. Sebuah jalur yang sedang di-borrow tidak boleh
dimutasi selama borrow-nya berjalan. Sebagian besar yang programmer Nim 2 kelompokkan sebagai "ownership" tidak
ditegakkan di sini, pemeriksaan move yang paling atas, jadi paruh kedua chapter ini menuliskan apa yang pin
lakukan, bukan mengajarkan aturan yang tidak dimiliki compiler-nya.

## Apa artinya "memiliki" sebuah nilai

Mulai dari yang assignment sudah lakukan. `var b = a` menyalin, dan kedua nama mencapai storage terpisah,
kecuali tipenya `ref`, yang berarti kedua nama mencapai satu cell (Chapter 13). Jadi pemilik sebuah nilai
adalah nama yang salinannya dihancurkan di akhir scope-nya. Tidak ada yang menandainya di tipe, dan tidak ada
yang melacaknya saat runtime.

Compiler punya hook untuk momen itu — `=destroy`, `=dup`, `=copy`, `=wasMoved`, `=sink` — dideklarasikan di
`lib/std/system.nim:112-116`. Itu routine biasa yang dipanggil runtime; bukan flow analysis, dan sebuah tipe
bebas mendefinisikannya atau tidak. `string` dan `seq` memakainya untuk melepas buffer. `int` tidak butuh sama
sekali, itu sebabnya memindahkan `int` nanti di chapter ini tidak mengubah apa pun.

`doc/language.md:893-960` mendokumentasikan anotasi `owned` yang opt-in untuk `ref` dan closure di balik
`{.feature: "ownedRefs".}`. Chapter ini tidak memakainya, dan tidak ada aturan di bawah yang bergantung padanya.

## Pemeriksaan aliasing di titik panggilan

Setiap panggilan diperiksa soal argumen yang tumpang tindih. Pemeriksaannya `borrowCheckForCall`, di
`src/nimony/contracts_fir.nim:4242-4289`, dan ia punya dua paruh.

Argumen mutable tidak boleh tumpang tindih dengan argumen immutable, kalau argumen immutable itu membaca storage
pemanggil. Kalau iya, panggilannya ditolak:

```
Error: mutable argument aliases with immutable parameter
```

Dua argumen mutable juga tidak boleh tumpang tindih, dan paruh itu menyala begitu jalurnya bertumpuk:

```
Error: mutable argument aliases with mutable parameter
```

Kapan paruh kedua menyala mudah dilihat. `swap(x, x)` pada dua parameter `int` ditolak
(`src/nimony/contracts_fir.nim:4282`), karena dua penulisan lewat satu lokasi membuat hasilnya bergantung pada
urutan callee menulis, dan tidak ada properti tipe yang bisa menyelamatkan itu. Field yang berbeda dari satu
object aman, dan `swap(p.x, p.y)` jalan — itu blok pertama sample chapter ini.

Paruh pertama bergantung pada tipe, dan itu bagian yang layak dipelajari. `passedByPointer`
(`src/nimony/contracts_fir.nim:4340-4351`) menjawab satu pertanyaan — bisakah salinan milik callee berubah
karena mutasi lewat argumen lain? — dan ia menjawab iya pada empat kondisi:

- parameternya `lent`, atau `varargs`;
- tipenya view, misalnya `openArray`;
- nilainya cukup besar untuk dikirim sebagai const reference: di atas 24 byte, kecuali tipe atau parameternya
  membawa `{.bycopy.}` (`passByConstRef`, `src/nimony/sizeof.nim:306-318`; ambangnya `getSize > 24` di
  `:282-288`);
- tipenya bisa memiliki heap.

`ownsNoHeap` (`src/nimony/contracts_fir.nim:4285-4338`) adalah daftar untuk yang keempat: integer, float, `bool`,
`char`, enum, range, `ptr`, `pointer`, `cstring`, set, array dan tuple dari semua itu, plus object tanpa destroy
hook yang semua field-nya ada di daftar. Apa pun yang tidak ia pahami diperlakukan sebagai memiliki heap,
sengaja konservatif.

Kondisi ketiga yang mengejutkan pembaca, karena tidak ada hubungannya dengan heap. Object polos berisi tiga
`int` berukuran 24 byte dan tetap disalin, jadi panggilannya compile; satu `int` lagi membuatnya 32 byte,
compiler mengirimnya sebagai const reference, dan panggilan yang sama ditolak:

```nim
type Obj24 = object
  a, b, c: int

type Obj32 = object
  a, b, c, d: int

proc f(x: var int, y: Obj24) = x = y.a
proc g(x: var int, y: Obj32) = x = y.a

var t = Obj24(a: 1)
var u = Obj32(a: 1)

f(t.a, t)     # compiles, prints 1: 24 bytes, disalin
g(u.a, u)     # Error: mutable argument aliases with immutable parameter: 32 bytes, const ref
```

Menambahkan `{.bycopy.}` ke `Obj32` membuat `g(u.a, u)` compile lagi, tanpa mengubah field-nya — pragma itulah
yang dibaca `passByConstRef` (`src/nimony/sizeof.nim:310-312`), jadi ukuran saja bukan aturannya.

Kondisi keempat punya satu titik buta yang disengaja. **Object warisan atau variant selalu dihitung memiliki
heap**, apa pun field-nya: `ownsNoHeap` mengembalikan false untuk object dengan penanda warisan — komentarnya
bilang "a derived value may own more" (`src/nimony/contracts_fir.nim:4328-4329`) — dan untuk object `case`, jadi
parameter by-value dari salah satu bentuk itu adalah pointer untuk pemeriksaan ini, bahkan saat isinya cuma 16
byte data polos. Warisan belum jadi topik buku ini; kalimatnya ada di sini supaya pembaca tidak terkejut oleh
penolakan yang tidak bisa ia jelaskan dari field-nya.

Cabang heap adalah yang pertama ditemui pembaca, dan satu field membalikkannya:

```nim
type Plain = object
  x, y: int

type Named = object
  x: int
  name: string

proc update(a: var int, b: Plain) = a = b.x
proc updateNamed(a: var int, b: Named) = a = b.x

var plain = Plain(x: 1, y: 2)
var named = Named(x: 1, name: "n")

update(plain.x, plain)        # compiles, prints 1
updateNamed(named.x, named)   # Error: mutable argument aliases with immutable parameter
```

Aturan yang ditunjukkan kedua panggilan itu bukan "argumen tidak boleh tumpang tindih dengan induknya". Bunyinya:
**parameter by-value memblokir tumpang tindih dengan argumen mutable setiap kali ia membaca storage pemanggil** —
view, `lent`, `varargs`, nilai yang cukup besar untuk dikirim sebagai const reference (di atas 24 byte, kecuali
`{.bycopy.}`), atau tipe yang bisa memiliki heap. Hanya kalau keempatnya salah, seperti pada salinan data polos
yang pendek, panggilannya compile.

`doc/language.md:2507-2517` memperlihatkan pemeriksaan ini dengan object dua `int` dan menyatakan panggilannya
error. Di pin ini program yang sama compile dan mencetak `1`. Contoh manual itu hanya benar untuk object dengan
field heap atau yang melewati 24 byte; buku mengajarkan aturan di atas, bukan contoh itu, dan ketidakcocokannya
tercatat di `ERRATA.md`.

## Borrow yang hidup lebih lama dari subjeknya

Aturan kedua soal view: `openArray`, `lent`, dan apa pun yang dikembalikan hasil `var T`. Nilai seperti itu
memegang borrow atas storage yang ia tuju, dan borrow-nya harus berakhir sebelum storage itu berakhir.

Menyimpannya di tempat yang hidup lebih lama dari pemiliknya ditolak. Menulisnya ke global adalah kasus paling
blak-blakan:

```nim
var g: openArray[int]

proc escape =
  var a = [1, 2, 3]
  g = toOpenArray(a)
```

```
Error: borrow of 'a' escapes the proc; it does not live long enough
Error: unsynchronized access to global variable 'g'; pass it to a `.sync` routine or use `{.cast(assumeSync).}`
```

Dua error, dan yang kedua sama sekali bukan soal borrow: aturan akses global dari Chapter 13 menyala di baris
yang sama (`src/nimony/contracts_fir.nim:4125`). Pembaca yang cuma membaca baris pertama tidak akan tahu kenapa
assignment biasa ke global jadi masalah; harapkan keduanya.

Aturan yang sama berlaku di dalam satu proc, antar scope:

```nim
proc outlivesSource =
  var view: openArray[int]
  block:
    var a = [1, 2, 3]
    view = toOpenArray(a)   # Error: borrow of 'a' escapes its scope; it does not live long enough
```

View yang dikembalikan adalah bentuk ketiga, dan ia punya kalimat sendiri karena perbaikannya berbeda: ia hanya
boleh meminjam dari parameter pertama, dan tidak dari yang lain.

```nim
proc head(i: int; s: string): openArray[char] =
  result = s.toOpenArray(0, 1)   # Error: borrow of 's' escapes the proc;
                                 # a returned view can only borrow from the first parameter
```

Sebabnya calling convention. Parameter pertama routine yang mengembalikan view dikirim by reference, jadi
view-nya menunjuk ke storage pemanggil. Parameter setelahnya bisa jadi salinan milik callee — string pendek
menyimpan karakternya inline — dan view atas salinan akan menggantung. Pemeriksaannya `checkResultBorrow`
(`src/nimony/contracts_fir.nim:680-695`); paruh parameter pertama itulah sebabnya
`proc window(s: seq[int]): openArray[int]` di sample legal.

Hasil `var T` mengikuti aturan yang sama, dan dari situ pernyataan Chapter 9 berasal. `validBorrowsFrom`
(`src/nimony/derefs.nim:258-314`) menjawab satu pertanyaan — apakah ekspresi ini diturunkan dari parameter
pertama routine, atau dari pointer? — dan `trReturn` (`src/nimony/derefs.nim:461-470`) menolak sisanya:

```nim
proc p(a: int; b: var int): var int =
  result = b            # Error: cannot borrow from b
```

Pesannya menyebut ekspresinya, bukan aturannya. `cannot borrow from b` itu semua yang lo dapat; sebabnya, `b`
adalah parameter kedua. Merantai lewat proc penerus berbunyi sama: `result = forward(x)` gagal dengan
`cannot borrow from forward(x)`.

`doc/language.md:2448-2472` menyatakan aturan ini dengan pesan `location is derived from x which is not p's
first parameter and lives on the stack`. Kata-katanya bukan yang dicetak compiler di pin ini; perilakunya sama
dan errornya lebih pendek.

Membaca nilai lewat borrow menyalinnya, jadi ia bebas keluar. Proc yang menyusuri seq dan mengembalikan elemen
pertamanya bukan mengembalikan view:

```nim
proc first(s: seq[int]): int =
  for x in s: return x
  return -1
```

## Jalur borrow selama iterasi

Iterasi meminjam jalur yang ia susuri. Selama loop berjalan, jalur itu tidak boleh dimutasi, dan aturannya
prefix exclusion: kalau `a.b.c` di-borrow, `a`, `a.b`, maupun `a.b.c` tidak boleh ditulisi, sementara saudara di
level yang sama tetap bisa ditulis (`doc/language.md:2540-2567`).

```nim
proc addItem(s: var seq[int]; val: int) = s.add val

var s = @[1, 2, 3]
for x in s:
  addItem(s, x)     # Error: 's' is borrowed and cannot be mutated
```

Errornya dibangkitkan di `src/nimony/contracts_fir.nim:621`, dan ia menyebut jalur yang di-borrow, bukan
callee-nya. Blok kedua sample adalah paruh yang legal: mengiterasi `c.elements` sambil menulis `c.name` compile
dan jalan, karena `name` adalah saudara dari jalur yang di-borrow. Menyusuri seq yang sama lewat indeks juga
legal — `for i in 0 ..< s.len: s[i] += 1` tidak pernah mengambil borrow yang diambil bentuk `for x in`.

## `move` itu panggilan library; yang diperiksa adalah `ensureMove`

`move` bukan konstruksi bahasa. Isinya ini, di `lib/std/system.nim:123-126`:

```nim
func move*[T](x: var T): T {.nodestroy, inline, noSideEffect.} =
  result = x
  `=wasMoved`(x)
```

Salinan, lalu hook. Sistem tipe tidak punya status moved dan flow analysis tidak menyimpan flag moved, jadi
membaca nama setelah `move` tidak pernah jadi error. Yang tertinggal adalah *nilai kosong yang sah*, karena
itulah yang dilakukan `=wasMoved` untuk tipe yang mendefinisikannya:

| nilai yang dipindah | isi nama lama sesudahnya | probe |
| --- | --- | --- |
| `string` | `""`, `len` 0 | `c01` |
| `seq[int]` | kosong, `len` 0 | `c02` |
| `ref object` | `nil` | `c04` |
| object dengan field `seq` dan `string` | kedua field dikosongkan | `c05` |
| `int` | tidak berubah, tetap 5 | `c03` |

Baris terakhir yang perlu diinternalisasi: `=wasMoved` adalah magic (`lib/std/system.nim:116`,
`src/nimony/magics.nim:128`) yang hanya bekerja di tempat sebuah tipe punya spesialisasi — `string`
(`lib/std/system/stringimpl.nim:296-297`), `seq[T]` (`lib/std/system/seqimpl.nim:59-61`), dan beberapa tipe
handle. `int` tidak punya, jadi panggilannya tidak melakukan apa pun dan move-nya jadi salinan dengan langkah
ekstra. Compiler tidak akan memberi tahu bahwa lo memakainya lagi.

Membaca nama lama setelah `move` compile dan jalan di setiap baris tabel di atas; tidak ada error untuk
ditangkap. Itu sebabnya chapter ini tidak mengajarkan "compiler menghentikan use after move". Di pin ini ia
tidak, dan aturan yang diajarkan di sini akan salah di program berikutnya.

**`ensureMove` adalah yang diperiksa.** Ia duduk dua baris di atas `move` di berkas yang sama
(`lib/std/system.nim:120-121`, magic, bukan routine) dan ia menanyakan analisis last-usage sebelum bertindak. Di
dalam proc, memakai nama setelah `ensureMove` menghentikan build:

```nim
proc handover =
  var a = "text"
  let b = ensureMove(a)
  echo b
  echo a          # Error: not the last usage of: a
```

Buang baris terakhir dan proc yang sama compile dan mencetak `text`, jadi beda yang dilihat pembaca persis
pembacaan kedua itu. Analisisnya `trEnsureMove` (`src/hexer/duplifier.nim:1573`), errornya dibangun di `:1611`,
dan `doc/language.md:3591-3594` mendokumentasikannya sebagai error statis saat move tidak bisa dibuktikan aman.
Jadi kalimat yang jujur harus dibatasi: membaca nama setelah `move` compile, membacanya setelah `ensureMove`
tidak. Pakai `ensureMove` kalau lo mau compiler memeriksa penyerahannya.

Satu catatan lagi sebelum lo memakainya: analisisnya hanya berjalan pada nama yang bisa ia lacak — `var`, `let`,
atau parameter `sink` di scope lokal. Variabel module-level ditolak apa pun yang menyusul, karena `isLastRead`
memang sengaja memperlakukan global sebagai tidak bisa dianalisis (`src/hexer/duplifier.nim:124-129`). Jaga
penyerahannya di dalam proc.

Hal yang sama berlaku untuk `sink`. Parameter `sink` menerima argumennya dan callee memiliki salinannya;
variabel pemanggil tidak tersentuh sesudahnya. Mengirim `string` ke parameter `sink string` membiarkan nilai dan
panjang milik pemanggil utuh (`c06`, `rv40`), dan `sink seq[int]` membiarkan panjangnya (`rv39`). Apa yang
compiler lakukan di balik itu bukan urusan chapter ini; bentuk yang bisa diamati itulah yang ia ajarkan.

## Delta Nim 2

Nim 2 meng-compile panggilan yang Nimony tolak, dan bedanya ada pada kapan lo tahu.

*Apa yang Nim 2 lakukan.* `take(s, s)` dengan `(var seq[int], seq[int])` compile dan mencetak `1` di Nim 2.4.0;
begitu juga loop yang menambahkan ke seq yang sedang ia iterasi, yang lalu mati saat runtime dengan
`the length of the seq changed while iterating over it`.

*Apa yang Nimony lakukan.* Keduanya ditolak sebelum apa pun berjalan, di baris yang bermasalah:
`mutable argument aliases with immutable parameter` dan `'s' is borrowed and cannot be mutated`.

*Apa yang rusak kalau kebiasaannya dibawa.* Kode yang mengirim container dan elemennya ke panggilan yang sama —
bentuk `gotcha(myseq, myseq[0])` — berhenti compile, dan perbaikannya menyalin elemennya dulu atau memecah
panggilannya. Kode yang memutasi koleksi di tengah iterasi juga berhenti compile, dan perbaikannya loop indeks.
Kedua kegagalan itu murah; kegagalan Nim 2 adalah jawaban yang salah dan assertion runtime.

`move` dan `sink` berperilaku sama di kedua compiler, termasuk nilai kosong yang tertinggal, jadi program Nim 2
yang memindahkan string tetap jalan. Yang tidak ikut pindah adalah anggapan bahwa compiler melacak move-nya
tanpa diminta; `ensureMove` ada di keduanya, tapi Nim 2.4.0 merumuskan penolakannya berbeda
(`cannot move 'a', which introduces an implicit copy`) dari `not the last usage of: a` di pin ini.

## Samples

`samples/14-ownership-borrow/ownership.nim`, dikompilasi dan dijalankan di commit yang di-pin:

```
$ nimony c -r samples/14-ownership-borrow/ownership.nim
pair 2 1
during 1
during 2
name new
window 3 first 10
taken payload left 0
cell 7 gone true
kept shared payload shared
```

Delapan baris, dalam urutan itu. `tools/verify-samples.sh` meng-compile dan menjalankannya bersama semua sample
lain di buku ini dan keluar 0 hanya kalau semuanya jalan; ia tidak membandingkan stdout, jadi delapan baris di
atas adalah output yang diharapkan dan hal yang dicek dengan mata.

## Checks

1. Tulis `take(a: var int, b: int)` lalu panggil `take(x, x)`. Ia compile. Ubah `b` jadi `seq[int]` dan panggil
   `take(s, s)`. Ia tidak. Sekarang buat `b` bertipe `array[25, uint8]` dan panggil `take(v[0], v)`, yang juga
   gagal. Sebutkan properti parameter kedua yang memutuskan di tiap kasus, satu kalimat masing-masing.
2. Ambil pasangan `Plain`/`Named` dari chapter ini dan tambahkan satu field `string` ke `Plain`. Compile kedua
   panggilannya lagi dan sebutkan mana yang sekarang gagal, dan kenapa errornya menunjuk `plain.x`, argumen
   mutable itu.
3. Tulis ulang loop `addItem(s, x)` sebagai loop indeks. Kedua versi melakukan kerja yang sama; sebutkan apa yang
   tidak diambil versi indeks.
4. Pindahkan sebuah `string` ke sebuah `let`, cetak panjang nama lamanya, lalu cetak nama lamanya itu sendiri.
   Tuliskan dugaan lo sebelum menjalankannya, dan periksa nilai moved-from-nya cocok dengan kolom kedua tabel.
   Lalu ganti `move` dengan `ensureMove`: catat apa yang berubah, dan kenapa kegagalannya datang sebelum program
   berjalan.

## Chapter checklist

`draft 2026-11-13 · tech_review Momo 2026-11-13 · editorial_pass 2026-11-13 · frozen 2026-11-13`
