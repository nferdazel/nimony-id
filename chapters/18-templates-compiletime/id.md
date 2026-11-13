---
chapter: 18
title: Templates and Compile-Time Evaluation
job: Remove repetition with hygienic templates and evaluate work at compile time with `const`.
nimony_version: 0.6.3
nimony_commit: 4ba90a781b0b22d0821efaa153c129c37cef6143
toolchain: ~/.local/opt/nimony/4ba90a7
host_compiler: ~/.local/opt/nim-2.4.0
status: frozen
tech_review: Momo 2026-11-13
editorial_pass: 2026-11-13
samples: [samples/18-templates-compiletime/templates.nim]
glossary_added: [template, hygienic template, injection, constant expression, compile-time evaluation]
---

# Template dan Evaluasi Compile-Time

## Untuk apa bab ini

Ada dua cara menulis sesuatu sekali saja, dan keduanya bukan alat yang sama. Template menghapus pengulangan di
sumber: compiler mengganti body-nya di tiap call site, dengan nama di dalamnya terikat ke tempat nama itu ditulis.
`const` menghapus pengulangan di nilai: compiler mengerjakan nilainya sebelum program mulai, dan program membawa
hasilnya. Template bisa mengubah kode mana yang ada; `const` cuma bisa menghasilkan nilai. Pembagian itu yang
menentukan pilihan: template kalau bentuknya berulang, `const` kalau angka atau string-nya berulang.

## Template itu diganti, bukan dipanggil

Manual menyebut mekanismenya dengan lugas di `doc/language.md:4504-4510`: template adalah "a simple substitution
mechanism that operates on Nim's abstract syntax trees", diproses di semantic pass, dan dipanggil dengan sintaks
panggilan. Body-nya bukan body routine.

```nim
template twice(x: untyped): untyped = x + x

echo twice(3)      # 6
```

Di program hasil kompilasi tidak ada panggilan di sini, tidak ada slot parameter, tidak ada frame. `twice(3)`
menjadi `3 + 3`. Itu sebabnya tipe parameternya bukan tipe: `x` adalah `untyped`, jadi argumennya datang sebagai
sumber dan diganti di tempat parameter itu ditulis.

Tiap ekspansi diperiksa sendiri. Kasih template tipe yang tidak bisa ia penuhi, dan error-nya datang di dalam body,
dengan trace ke call site:

```
main.nim(5, 1) Trace: instantiation from here
main.nim(4, 41) Error: Type mismatch at [position]
Plain(n: 1) + Plain(n: 1)
```

Baris kedua pesan itu adalah sumber hasil penggantian, bukan panggilan, dan trace-nya menunjuk baris yang harus kamu
betulkan. Jadi template diperiksa di tempat ia dipakai, terhadap argumen yang dipakai bersamanya, bukan sekali di
definisinya.

## Nama yang dideklarasikannya bukan nama kamu

```nim
template bump(): untyped =
  var tmp = 99
  tmp

var tmp = 1
echo bump()      # 99
echo tmp         # 1
```

Dua `tmp` yang berbeda. Deklarasi di dalam template diganti nama menjadi simbol privat template saat template
dikompilasi, jadi nama di level modul dengan ejaan yang sama tidak bisa bentrok dengannya dan template tidak bisa
mengambil alih variabel pemanggil. Penggantian nama itu default untuk setiap local yang dideklarasikan template, dan
`{.inject.}` adalah cara keluar dari aturan itu untuk satu deklarasi (`src/nimony/semuntyped.nim:214-232`;
mekanismenya `makeTemplateSym` dan gensym set yang mencatatnya).

`declared` menunjukkan fakta yang sama tanpa perlu ada bentrok untuk mendemonstrasikannya:

```nim
template twice(x: untyped): untyped =
  var acc = x
  acc + acc

echo twice(21)          # 42
echo declared(acc)      # false
```

## Dari mana nama template berasal

Hygiene punya paruh kedua: nama yang dipakai body diselesaikan di scope tempat template ditulis, bukan di scope
tempat ia diekspansi.

```nim
proc helper() = echo "module helper"

template callHelper() =
  helper()

proc scope() =
  proc helper() = echo "local helper"
  callHelper()          # module helper

scope()
```

`helper` lokal punya ejaan yang sama, arity yang sama, dan scope yang lebih dekat, dan tetap tidak menang: `helper`
di body itu ditulis di level modul, jadi di situ ia dicari. Penundaannya nyata, tapi: routine yang dideklarasikan di
bawah template tapi di atas panggilannya tetap resolve normal, jadi aturannya tertunda dalam waktu dan tetap di
tempatnya.

Itu paling penting di sebuah library. Template tidak bisa dibajak pemanggil yang kebetulan mendeklarasikan nama
dengan ejaan sama, dan itulah gunanya menulis template secara higienis; harganya, template juga tidak bisa meminjam
apa pun dari pemanggil.

## Yang kamu masukkan tidak bisa melihat yang dideklarasikan template

Block yang kamu lewatkan bukan teks yang ditempel sesudah deklarasi template. Ia ditulis di call site dan diperiksa di
sana.

```nim
template withValue(v: int, body: untyped) =
  block:
    let local = v
    body

withValue(5):
  echo local      # Error: undeclared identifier: local
```

Pesannya datang dengan dua baris Trace, satu untuk panggilan `withValue(5)` dan satu untuk block-nya, lalu
`undeclared identifier: local`. `local` milik template tidak pernah ada di scope block itu.

Contoh manual untuk bagian ini (`doc/language.md:4566-4583`) bilang block-nya jalan kalau parameternya `untyped` dan
gagal kalau `typed`. Di commit yang dipin, versi `untyped` juga gagal, dengan `undeclared identifier: 'p'`, karena
`proc p` yang dipanggil block itu dideklarasikan di dalam template dan karena itu higienis seperti local lain. Versi
`typed` gagal lebih dulu dan beda lagi, dengan `expression of type ``typed`` must be discarded`. Tidak ada dari dua
bentuk itu yang jadi jalan menuju nama tersebut; injection yang jadi jalan.

## Injection: mengeluarkan satu nama dengan sengaja

```nim
template setup() =
  proc report() {.inject.} = echo "report ready"
  let limit {.inject.} = 3

setup()
report()          # report ready
echo limit        # 3
```

`{.inject.}` pada deklarasi di dalam template mempertahankan namanya alih-alih menggantinya, jadi scope pemanggil
melihat `report` dan `limit` sesudah ekspansi. `{.gensym.}` menyatakan sebaliknya secara eksplisit, dan berguna di
tempat kamu ingin default-nya terlihat di sumber. Kedua pragma dibaca oleh `symBinding`
(`src/nimony/semuntyped.nim:183-191`) dan diterapkan di `addDecl` (`:214-232`). Field pada object adalah pengecualian
yang berlaku tetap: nama field di-inject, bukan diganti nama, karena field bukan local.

`{.dirty.}` adalah switch yang lain, dan switch yang tidak melakukan apa pun sendirian. `doc/porting.md:262-282`
menggambarkannya sebagai pragma untuk body template yang harus menyebut identifier milik scope *pemanggil*, dan
mengatakan template seperti itu butuh `{.feature: "untyped".}` di level modul. Kedua paruhnya diperlukan: tanpa
feature itu pragma-nya diam dan local template tetap tidak terlihat oleh pemanggil, dan dengan feature itu local-nya
di-inject ke pemanggil dan nama milik pemanggil resolve di body. Itu bekerja dua arah, jadi ia escape hatch untuk
mem-port kode lama dan bukan switch masuk-saja: template yang dirty memang menerbitkan namanya. Perlakukan sebagai
pilihan terakhir, bukan sebagai cara mengeluarkan nama dari template.

## Tipe parameter mana yang ditulis

`untyped` adalah pilihan yang bekerja untuk sebuah block atau untuk ekspresi apa pun yang mau kamu ganti, dan itulah
yang dipakai sample. Alternatifnya masing-masing punya satu tugas:

- **Tipe sungguhan** kalau argumen harus diperiksa sebelum penggantian. `template addOne(x: int): int = x + 1`
  menerima `addOne(41)` dan menolak `addOne("s")` dengan `[1] expected: int64 but got: string (declared in
  main.nim(2, 1))`, yang menamai daftar parameter template itu sendiri sebagai asal ketidakcocokannya. Pilih ini
  kalau argumennya ekspresi dengan tipe yang sudah diketahui: error-nya datang di argumen, bukan di dalam body.
- **`var`** kalau template harus menulis balik lewat parameter: `template bump(x: var int) = x = x + 2` meninggalkan
  variabel pemanggil di `7`.
- **Arity** membedakan template yang memakai nama sama, persis seperti pada routine: `tag` satu argumen dan `tag` dua
  argumen hidup berdampingan dan tiap panggilan memilih miliknya sendiri.

Dua bentuk terlihat tersedia dan ternyata tidak:

- **`varargs[untyped]`** menerima panggilannya dan meninggalkan parameter yang tidak bisa dibaca. Apa pun yang
  memeriksa nilainya gagal di pin ini: `args.len`, `echo args`, dan `for a in args`, yang terakhir dengan
  `expected: openArray[T] but got: int64`. Parameternya mengembang menjadi argumen pertama, bukan menjadi daftar
  argumen, jadi `args.len` menjadi `len(1)` dan `for a in args` menjadi `items(1)`. Hanya pemakaian yang tidak pernah
  melihat nilainya yang build: `discard args`, `let x = args`, atau meneruskan parameternya ke slot
  `varargs[untyped]` lain. Jangan ditulis.
- **`typed`** diterima dan tidak bisa dipakai. `template typedSlot(x: typed) = echo x` menolak `typedSlot(41)` dengan
  `expected: string but got: typed` untuk tiap overload `echo`, dan `template passThrough(x: typed): int = x` menolak
  dengan `got: typed but wanted: int64`. Argumennya bahkan tidak di-resolve di panggilan: `typedSlot(notDeclared)`
  build tanpa satu pun diagnostik, jadi parameternya placeholder, bukan argumen yang diperiksa. Nim 2.4.0 menjalankan
  kedua template itu dan mencetak `41` dan `42`, jadi ini perbedaan dari Nim 2 dan bukan kesalahan di template-nya: di
  pin ini parameter `typed` meneruskan meta-type ke body alih-alih tipe argumennya. Tulis `untyped`, atau tipe
  sungguhan.

## Statement atau expression, dan tanda kurung

Template yang body-nya tidak menghasilkan nilai adalah statement, dan memakainya di tempat yang mengharapkan nilai
adalah error di pemakaiannya, bukan di template-nya: `let v = note("hi")` memberi `expression 'note("hi")' has no
type (or is ambiguous)`, lalu error kedua dari `echo` atas `v` karena `v` bertipe `void`. Template yang berakhir
dengan ekspresi adalah nilai dan bisa menginisialisasi `const` (`const Six = twice(3)` adalah `6`).

Panggilan selalu pakai tanda kurung. Nama telanjang bukan panggilan dan juga bukan nilai proc: `greet` tanpa `()`
adalah `undeclared identifier: greet`, bagaimanapun template itu dideklarasikan. `doc/porting.md:255-262`
mendokumentasikan pesan yang berbeda untuk kesalahan ini, `expression of type proc() must be discarded`, yang tidak
dicetak pin ini.

## Konstanta adalah nilai yang dikerjakan compiler

`doc/language.md:26-31` mendefinisikan kelasnya: konstanta terikat ke constant expression, dan constant expression
hanya boleh bergantung pada literal, operator bawaan, konstanta yang dideklarasikan sebelumnya, dan panggilan routine
yang argumennya bisa dievaluasi di compile time. Daftarnya pendek dan konsekuensinya konkret.

```nim
const Start = 10
const Step = Start * 2 + 1       # 21

const Greeting = "hello" & ", " & "world"
const Width = Greeting.len        # 12

const Primes = [2, 3, 5, 7]
const Count = Primes.len          # 4
```

Konstanta memberi makan konstanta, operasi string dan array fold, dan `len` fold untuk sebuah array. `Primes[2]`
adalah `5`, dan indeks string fold menjadi `char`: `const First = Word[0]` pada `const Word = "nimony"` adalah `n`.
Literal object dan enum bekerja dengan cara yang sama, jadi `const Origin = Point(x: 0, y: 0)` adalah konstanta
object dan `Origin.x` adalah `0`.

Dua aturan urutan menangkap pembaca yang menganggap `const` sebagai variabel yang tidak bisa diubah:

- `const` tidak bisa diinisialisasi dari nilai runtime, dan `let` yang ditulis di atasnya tidak menolong. Error-nya
  `undeclared identifier: runtime`, bukan "not a constant": hanya konstanta sebelumnya yang ada di titik konstanta itu
  dievaluasi.
- Hal yang sama berlaku antar konstanta. `const A = B` sebelum `const B = 2` melaporkan `undeclared identifier: B`,
  lalu error kedua di tempat `A` dipakai, karena `A` kolaps menjadi `auto`.

Konstanta bukan variabel sesudahnya: `Floor = 2` pada `const Floor = 1` adalah `cannot mutate expression Floor`.
`const` di dalam body routine legal dan di-fold sekali, jadi faktor yang dideklarasikan begitu tidak memakan biaya
per panggilan.

## Apa yang benar-benar dihitung evaluator

`doc/language.md:33` mengatakan mesin compile-time-nya ada dan bahwa "the restrictions for this mechanism are
currently undocumented". Buku tidak bisa mengutip batas yang tidak didokumentasikan, jadi bagian ini hanya mengklaim
apa yang ditunjukkan pin ini.

Panggilan ke routine yang kamu tulis di-fold, dan body-nya boleh memuat alur kontrol biasa: `const Nine = square(3)`
adalah `9`; `for` dengan `if` di dalamnya `30`; `while` yang mengakumulasi `6`; rekursi `120` untuk `fact(5)`.
Container dan string juga dibangun selama evaluasi: `seq` yang ditumbuhkan dengan `add` memberi `4` dan `9` untuk
panjang dan elemen terakhirnya, dan string yang ditumbuhkan dengan `&` memberi `xxxx` dan panjang `4`.

Batasnya tidak seragam, dan satu asimetri layak diketahui sebelum menghabiskan satu sore. Membaca `.len` dari array
`const` fold, dan begitu juga membaca `.len` dari literal seq atau dari array yang dijangkau langsung. Seq yang
dijangkau lewat sebuah `const` bernama tidak:

```
main.nim(3, 20) Error: cannot evaluate expression at compile time: len(Table)

main.nim(2, 15) Error: undeclared field: 'len' for type seq[int64]
```

`(@[4, 5]).len` adalah `2` dan `len(@[1, 2, 3])` adalah `3`, jadi bentuk yang gagal adalah perantaraan const
bernama, bukan seq versus array. Seq-nya sendiri konstanta yang baik-baik saja: `Table.len` dan `Table[1]` jalan saat
runtime pada nilai yang sama. Cuma fold-nya yang tidak ada.

Saat evaluator tidak bisa menghasilkan nilai, pesannya menamai ekspresi yang ia lepaskan
(`src/nimony/expreval.nim:147-155`). Indeks di luar array konstanta salah satu kasusnya: `const Bad = [10, 20,
30][5]` melaporkan `cannot evaluate expression at compile time: [10, 20, 30][5]`, tanpa pesan bounds: evaluator tidak
punya pemeriksaan bounds, jadi ia menolak fold alih-alih gagal seperti indeks saat runtime. Aritmetika yang meluap
tipenya kasus lain, dan yang ini error pasti di pin ini: `const Overflow = 127'i8 + 1'i8` memberi `expression
overflow at compile time: 127'i8 + 1'i8` (`src/nimony/expreval.nim:466-472`).

Panggilan yang tidak bisa ditangani folder in-process diserahkan ke sub-compilation
(`src/nimony/expreval.nim:283-320`, `forwardToExecute`), dan begitulah panggilan routine bisa bekerja sama sekali.
Routine yang mencetak saat dievaluasi tidak mencetak apa pun dan hanya nilainya yang kembali, karena sub-compilation
menangkap stdout untuk mengambil nilainya. Itu bukan janji bahwa sisa body-nya diam: `writeFile` di dalam routine
yang sedang di-fold benar-benar menulis file selama kompilasi. Konstanta itu `40`, terminalnya tetap kosong.

Di tempat bahasa menuntut konstanta alih-alih ekspresi, nilai hasil fold diterima: panjang array yang ditulis
`array[Width, int]` untuk `const Width = 4` build, dan `array[Slots, int]` juga build, dengan `Slots` berasal dari
panggilan routine.

## Nim 2 delta

*Apa yang Nim 2 lakukan.* Sintaks template-nya sama, dan parameter `typed` bekerja: Nim 2.4.0 mencetak `41` dan `42`
untuk dua template yang ditolak pin ini. `macro` adalah cara biasa untuk membangkitkan kode, dan template
`{.dirty.}` adalah escape hatch untuk body yang butuh nama milik pemanggil.

*Apa yang Nimony lakukan.* Template adalah alat pengulangan yang didukung, diperiksa per call site, dengan nama di
body terikat di tempat ia ditulis. Parameter `typed` diterima dan tidak bisa dipakai, jadi `untyped` atau tipe
sungguhan adalah jalurnya. `macro` dengan parameter `untyped` masih build dan jalan di pin ini, sementara
`doc/differences.md` mendaftar macro sebagai digantikan plugin: permukaan kompatibilitas, bukan teknik yang diajarkan
buku ini (Bab 19). `const` dihitung oleh evaluator yang batasnya tidak didokumentasikan manual, jadi jaga
constant expression pada bentuk-bentuk di atas.

*Apa yang rusak kalau kebiasaan itu dibawa.* Template berparameter `typed` hasil port gagal di pemakaian pertamanya
dengan type error soal `typed` yang tidak mengatakan apa pun tentang template-nya, dan perbaikannya adalah mengubah
tipe parameternya, bukan body-nya. `macro` hasil port tetap build sementara desainnya bergerak menjauhinya. Dan `let`
yang dipakai menginisialisasi `const` gagal sebagai `undeclared identifier`, yang terbaca seperti salah tulis
alih-alih aturan.

## Samples

`samples/18-templates-compiletime/templates.nim`, dikompilasi dan dijalankan di commit yang dipin:

```
$ nimony c -r samples/18-templates-compiletime/templates.nim
6
100
report ready
3
3
9
6
```

Tujuh baris: `twice(3)`, lalu `acc` milik modul yang tetap `100` walaupun template yang sama mendeklarasikan local
dengan ejaan `acc`; `report` dan `limit` hasil injection dari `setup()`; `Folded.len` hasil fold; `Table[3]` dengan
`Table` dibangun routine saat compile time; dan `Folded[2]`.

## Cek

1. Tulis `template twice(x: untyped): untyped = x + x`, panggil dengan `int` dan dengan `string`, lalu panggil dengan
   `seq[int]`. Catat panggilan mana yang gagal dan ke mana pesannya menunjuk.
2. Deklarasikan `var total = 1` di level modul dan template yang mendeklarasikan `var total = 99` lalu
   mengembalikannya. Pastikan `total` milik modul tetap `1` sesudah panggilan, lalu ganti local tanpa pragma itu
   dengan `{.inject.}` dan sebutkan apa yang berubah bagi pemanggil.
3. Tulis template yang mendeklarasikan `let local = 1` dan menerima block `body: untyped`, ekspansi, lalu suruh
   block itu mencetak `local`. Baca dua trace-nya, lalu buat block itu compile dengan menambahkan `{.inject.}` pada
   deklarasinya.
4. Tulis `const` yang nilainya berasal dari routine dengan loop `for`, lalu coba inisialisasi `const` lain dari `let`
   yang dideklarasikan tepat di atasnya. Catat kedua pesannya.
5. Ambil `const` seq, baca `.len`-nya di `const` kedua, lalu baca `.len` yang sama saat runtime. Laporkan mana dari
   keduanya yang build dan kenapa bedanya penting untuk menentukan di mana konstanta itu ditaruh.

## Chapter checklist

`draft 2026-11-13 · tech_review Momo 2026-11-13 · editorial_pass 2026-11-13 · frozen 2026-11-13`
