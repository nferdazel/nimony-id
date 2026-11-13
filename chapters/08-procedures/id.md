---
chapter: 8
title: Procedures, Parameters, and Results
job: Define `proc` and `func`, return through `result`, pass by `var` and `sink`, and use default and named arguments.
nimony_version: 0.6.3
nimony_commit: 4ba90a781b0b22d0821efaa153c129c37cef6143
toolchain: ~/.local/opt/nimony/4ba90a7
host_compiler: ~/.local/opt/nim-2.4.0
status: frozen
tech_review: Momo 2026-11-12
editorial_pass: 2026-11-12
samples: ["samples/08-procedures/procedures.nim"]
glossary_added: ["proc", "func", "result", "var parameter", "out parameter", "sink parameter", "default argument", "named argument"]
---

# Prosedur, Parameter, dan Hasil

## Untuk apa chapter ini

Semua chapter sebelumnya adalah program yang tersusun dari statement. Routine memberi satu rangkaian statement
sebuah nama dan signature, supaya bagian lain buku ini bisa memanggilnya alih-alih mengulanginya. Nimony punya
dua deklarasi untuk itu: `proc`, yang boleh melakukan apa saja, dan `func`, yang tidak boleh menyentuh apa pun di
luar argumen dan hasilnya sendiri.

Pekerjaan chapter ini adalah seluruh batas sebuah pemanggilan — bagaimana argumen datang, bagaimana hasil keluar,
dan bentuk parameter mana yang dipakai. Overloading dan method dispatch ada di Chapter 9; chapter ini
mengasumsikan satu routine per nama.

## `proc` adalah blok statement dengan nama

```
proc greet(name: string) =
  echo "hi ", name

greet("nimony")
```

```
hi nimony
```

`=` memulai body, dan body adalah blok statement satu indent lebih dalam (`doc/language.md:2211-2218`). Tidak ada
tipe kembalian setelah `)` berarti routine itu tidak menghasilkan apa pun: kamu memanggilnya untuk apa yang
dikerjakannya.

Parameter ditulis di dalam tanda kurung sebagai `name: type`. Tipenya berlaku untuk setiap nama sebelumnya,
melewati koma, dan berhenti di titik koma (`doc/language.md:2218-2224`). Jadi ini legal dan `c` punya tipenya
sendiri:

```
proc add(a, b: int; c: float): float =
  float(a + b) + c
```

`add(1, 2, 0.5)` mencetak `3.5`. Peringatan di guide itu nyata di pin ini: buang tipe dari grup pertama dan
deklarasinya ditolak — `proc bad(a; b: int)` gagal dengan `type or init value expected`, dilaporkan di nama
parameternya.

Tipe kembalian ditulis setelah tanda kurung penutup. Body-nya lalu bisa ditulis dalam dua bentuk. Bentuk blok
yang dipakai `greet`. Bentuk satu ekspresi menulis nilainya di baris yang sama:

```
proc triple(x: int): int = x * 3
```

`triple(5)` adalah `15`. Ini bukan bentuk deklarasi kedua yang dipilih sesuai selera — ini routine yang sama
dengan body satu ekspresi, dan kedua bentuk ada di standard library: `lib/std/colors.nim:21` menulis satu dengan
cara ini, `lib/std/syncio.nim:293` memakai blok.

## Ekspresi terakhir body adalah hasil

Body blok adalah statement list expression, dan statement list expression bernilai ekspresi terakhirnya
(`doc/language.md:1552-1560` mendefinisikan bentuk berkurung `(stmt1; stmt2; …; ex)`; menerapkannya ke body proc
adalah probe p33). Jadi ini compile dan mengembalikan `5`:

```
proc f(): int =
  echo "body"
  5
```

`echo` adalah statement yang jalan lebih dulu; `5` adalah nilai yang dihasilkan body. Tidak ada penanda bahwa
baris terakhir istimewa, dan itulah kenapa ekspresi sisa di routine yang sudah mengisi `result` layak
diwaspadai: ekspresi itu menjadi hasil meskipun `result` sudah diisi. `proc f(): int = result = 1` yang diikuti
`5` mengembalikan `5`, bukan `1`. Tulis `discard` kalau itu bukan maksudmu.

## `result` adalah variabel

Routine dengan tipe kembalian punya variabel yang dideklarasikan implisit bernama `result` yang menyimpan nilai
kembaliannya (`doc/language.md:2243-2245`). Isi di mana saja di dalam body; saat body selesai, `result` itulah
yang diterima pemanggil:

```
proc f(a, b: int): int =
  result = a + b

echo f(2, 3)
```

Itu mencetak `5` tanpa satu pun `return`. Karena `result` adalah variabel biasa, pengisiannya bisa dipecah ke
beberapa cabang, dan aturan Chapter 3 berlaku untuknya: setiap jalur yang sampai ke akhir harus sudah menulisnya.
Routine yang tidak pernah menulisnya gagal di-build:

```
proc counter(): int =
  discard

echo counter()
```

```
Error: cannot prove that result has been initialized
```

Itu pemeriksaan definite assignment yang sama yang menangkap `if` expression tanpa `else`; nama di pesannya
`result` karena kali ini memang variabel itu (`src/nimony/contracts_fir.nim:6065`, yang membangun kalimat ini
untuk `result` dan untuk parameter dengan cara yang sama).

## `return`

`return expr` itu gula, dan guide mengatakannya dengan jelas: artinya `result = expr` lalu `return`
(`doc/language.md:1915-1921`). `return` tanpa ekspresi adalah singkatan dari `return result`
(`doc/language.md:1924-1926`), yang hanya berguna setelah ada yang sudah mengisi `result`:

```
proc sign(n: int): int =
  if n > 0:
    result = 1
    return
  result = 0
```

`sign(4)` adalah `1`, `sign(-4)` adalah `0`. `return` telanjang itu keluar di baris tersebut dengan apa pun yang
sedang dipegang `result`.

Dengan nilai, dia keluar lebih awal dan melewati sisa body:

```
proc grade(n: int): string =
  if n >= 50:
    return "pass"
  echo "checked ", n
  "fail"
```

`grade(70)` adalah `pass` dan tidak mencetak apa pun lagi; `grade(10)` mencetak `checked 10` lalu mengembalikan
`fail` lewat ekspresi terakhir body. Keluar lebih awal itu alat kontrol alur, bukan gaya — pakai `result` plus
ekspresi terakhir kalau routine-nya terbaca dari atas ke bawah.

## Nilai default

Parameter boleh punya default (`doc/language.md:2234-2241`):

```
proc pad(n: int; width: int = 3): int = n * width

echo pad(7)
echo pad(7, 2)
```

`21` dan `14`. Guide menambahkan satu detail yang mudah terlewat: default **dihitung ulang setiap kali routine
dipanggil**, bukan sekali saat deklarasi (`doc/language.md:2234-2241`). Ilustrasinya butuh penghitung di level
modul, dan pin ini menolak itu dari `proc` biasa dengan `unsynchronized access to global variable`; karena itu
demonstrasinya tercatat di `ERRATA.md` dan tidak ditampilkan di sini, dan aturan bukunya adalah aturan
`CONTRIBUTING.md`: chapter yang menampilkan state mutable level modul menyebut aturan `.sync` di pemakaian
pertama.

Satu bentuk tidak boleh ditulis di pin ini: default yang ditulis dalam bentuk parameter sebelumnya.

```
proc scaled(x: int; factor: int = x): int = x * factor
```

Itu bukan diagnostik. Front end menerimanya dan build mati di backend C dengan `[Bug] could not find symbol:
x.0`, exit 1. Bentuk itu tercatat di `ERRATA.md`; aturan bukunya: default adalah literal atau ekspresi yang tidak
menyebut parameter mana pun dari routine yang sama.

## Argumen bernama

Argumen boleh diberikan dengan nama alih-alih posisi. Guide tidak mendeskripsikan bentuk ini — satu-satunya jejak
di `doc/` adalah tag NIF untuk "explicitly named arguments in function calls" (`doc/tags.md:33`) — jadi seluruh
bagian ini hasil probe di pin, bukan kutipan:

```
proc pad(n: int; width: int = 3): int = n * width

echo pad(width = 2, n = 7)
```

`14`. Nama boleh datang tidak berurutan, dan parameter yang kamu lewati tetap memakai default-nya: `pad(n = 7)`
adalah `21`. Namanya diperiksa — `pad(count = 1)` gagal dengan `named argument not found` — dan jumlahnya juga:
`pad(1, 2, 3)` gagal dengan `too many arguments`. Keduanya dilaporkan di call site dengan deklarasinya disebut di
bawahnya, dan itu bagian yang berguna ketika sebuah default membuatmu mengirim satu argumen lebih banyak.

Pakai nama kalau pemanggilan punya dua argumen bertipe sama dan urutannya tidak jelas dari nama fungsinya.
`pad(2, 7)` adalah `14` dan `pad(7, 2)` adalah `21`; bentuk bernama `pad(width = 2, n = 7)` juga `14`, tapi dia
mengatakan angka mana yang mana, dan pembaca yang salah menebak urutannya tidak bisa salah membacanya.

## Parameter `var`

Awali tipenya dengan `var` dan parameternya menjadi pegangan ke variabel pemanggil
(`doc/language.md:2350-2372`):

```
proc bump(x: var int) =
  x = x + 1

var n = 5
bump(n)
echo n
```

`6`. Penulisan di dalam routine terlihat di luarnya, karena parameter `var` adalah pointer tersembunyi ke
argumennya (`doc/language.md:2370-2372`).

Argumennya harus sebuah place, bukan nilai. `bump(7)` ditolak:

```
Error: cannot pass 7 to var/out T parameter
```

Aturannya sama dengan yang dipakai Chapter 3 untuk assignment: yang di kiri harus variabel yang punya
penyimpanan. `let` juga tidak bisa.

## Parameter `out`

`out T` adalah saudara yang hanya menulis (`doc/language.md:2765-2790`). Dia ada untuk kasus di mana routine
harus menghasilkan lebih dari satu hasil dan nilai kembalian saja tidak cukup:

```
proc split(a, b: int; q, r: out int) =
  q = a div b
  r = a mod b

var q, r: int
split(8, 5, q, r)
echo q, " ", r
```

`1 3`. Compiler memeriksa routine-nya, bukan tiap pemanggilan: setiap jalur sebelum return harus mengisi setiap
parameter `out` (`doc/language.md:2782-2790`). Buang pengisian di dalam `if`-nya dan routine berhenti bisa di-build
dengan `cannot prove that y has been initialized` — kalimat yang sama dengan variabel lokal yang mungkin
dilewati sebuah cabang tanpa diisi.

Satu perbedaan dari deskripsi guide layak disebut terus terang. `doc/language.md:2765` bilang parameter `out`
"must be written to before it can be used"; di pin ini routine-nya tetap bisa di-build kalau kamu membacanya
lebih dulu. Yang dibaca adalah nilai pemanggil saat itu, bukan nilai baru: `var v = 9` yang dikirim ke routine
yang meng-echo parameternya sebelum mengisinya mencetak `before 9`. Variabel yang baru saja dideklarasikan
pemanggil kebetulan bernilai `0`, dan itu sebabnya bentuk ini terlihat aman di percobaan pertama. Yang ditegakkan
adalah pemeriksaan setiap jalur pada routine-nya, bukan penghalang baca. Jangan tulis routine yang membaca
parameter `out` sebelum mengisinya — dia tetap bisa di-build, dan yang dibacanya adalah isi penyimpanan pemanggil.

## Lebih dari satu hasil, dua cara

Parameter `var` dan `out` adalah satu cara mengembalikan beberapa nilai. Tuple cara lainnya, dan dia menaruh
hasilnya di tipe kembalian tempat pemanggil bisa melihatnya (`doc/language.md:2386-2394`):

```
proc divmod(a, b: int): (int, int) = (a div b, a mod b)

let t = divmod(8, 5)
echo t[0], " ", t[1]
```

`1 3`. Tuple-nya dibangun di body ekspresi dan di-index di call site. Chapter 10 membahas akses tuple dengan
benar; yang penting di sini adalah pilihannya: parameter kalau routine-nya juga punya efek samping yang harus
dilaporkan, tuple kalau nilainya adalah seluruh jawabannya.

## Parameter `sink`

`sink T` menandai parameter yang boleh diambil alih routine (`doc/language.md:3626-3636`):

```
proc take(s: sink string) =
  echo "sink got ", s

var text = "abc"
take(text)
echo "sink after ", text
```

```
sink got abc
sink after abc
```

Variabel pemanggil masih berisi `abc` setelah pemanggilan, jadi di pin ini `sink` pada `string` adalah izin, bukan
perpindahan yang terlihat: dia memberitahu compiler bahwa callee boleh menyimpan penyimpanan argumennya alih-alih
menyalinnya, dan tidak ada yang berubah di call site. Tulis kalau routine-nya memang menyimpan apa yang
diberikan — kode container di standard library melakukannya — dan jangan berharap dia mengosongkan variabelmu
atau membuat pemanggilan lebih murah dengan cara yang bisa kamu ukur.

## `func` adalah proc tanpa efek samping

`func` mendeklarasikan routine yang diperlakukan `noSideEffect` secara default, sementara `proc` diperlakukan
punya efek samping (`doc/language.md:3115-3119`). Bebas efek samping berarti, dalam kata-kata guide, tidak ada
akses ke variabel global atau thread-local, tidak ada pemanggilan routine yang punya efek samping, dan tidak ada
mutasi lewat `ref` atau `ptr`.

Aturan praktisnya pendek: kalau routine-nya hanya membaca argumen dan menghitung, tulis `func`. Kalau dia
meng-echo, menulis file, atau mengubah sesuatu yang bisa dilihat pemanggil, tulis `proc`.

Mencoba menipu akan tertangkap. `func` yang meng-echo gagal di-build:

```
Error: cannot call a routine with side effects from a `.noSideEffect` context
```

Errornya menunjuk ke dalam `syncio`, karena `echo` adalah routine berefek samping yang dipanggil. Kalau efeknya
memang disengaja, deklarasinya bisa mengatakan itu — `{.sideEffect.}` pada `func` mengembalikan perilaku `proc`
dan pemanggilannya compile lalu jalan.

Satu nuansa yang guide sebutkan dan compiler tegakkan: `func` boleh menulis parameter `var`-nya sendiri —
variabel yang disebut pemanggil — tapi tidak apa pun di balik `ref` atau `ptr` (`doc/language.md:3121`). `func`
yang menambah ke `var seq[int]` lolos dan sequence pemanggil bertambah; `func` yang menulis `n.x` lewat objek
`ref` ditolak dengan `cannot mutate n.x through a ref/ptr in a .noSideEffect context`. Menjumlah ke `result` di
atas sequence itu urusan lain: body-nya harus mengisi `result = 0` sebelum loop, atau routine-nya gagal di-build
dengan `cannot prove that result has been initialized` yang sama dengan jalur lain yang meninggalkannya kosong.

Tidak ada inferensi `noSideEffect` (`doc/language.md:3156`): `proc` tidak diam-diam diperlakukan murni karena
body-nya terlihat murni. Default-nya berasal dari deklarasinya, dan anotasinya yang menimpa.

## Nilai bukan statement

Posisi statement tidak menerima nilai. Memanggil routine yang mengembalikan sesuatu lalu mengabaikan hasilnya
adalah error statis (`doc/language.md:1577-1578`):

```
proc add(a, b: int): int = a + b

add(1, 2)
```

```
Error: expression of type `int64` must be discarded
```

Tulis `discard add(1, 2)` kalau nilainya memang tidak diinginkan (`doc/language.md:1562-1578`). Aturan yang sama
membuat routine void tidak bisa dipakai sebagai nilai: `let x = greet("a")` tidak bisa di-build, karena tidak ada
yang bisa diikat.

## Bentuk pemanggilan

Tiga bentuk, pemanggilan yang sama (`doc/language.md:2261-2272`).

**Posisional**, dengan tanda kurung: `add(1, 2)`, `5.add(6)`.

**Bentuk dot**, di mana receiver menjadi argumen pertama (`doc/language.md:2836-2866`): `5.add(6)` adalah
`add(5, 6)` dan mencetak `11`. Dia berpadu dengan default: `1.optarg optarg 8` memanggil `optarg(1, optarg(8))`
dan mencetak `9`, persis seperti contoh di guide.

**Bentuk command**, tanpa tanda kurung, hanya di tempat pemanggilannya berupa statement
(`doc/language.md:2868-2875`):

```
proc note(msg: string) =
  echo "note ", msg

note "no parens"
```

Di posisi ekspresi, bentuk command hanya menerima satu argumen: `let single = singlearg 2` compile. Dua argumen
di posisi itu adalah syntax error di pin ini — `let r = add 1, 2` melaporkan `invalid indentation`, sementara
contoh di guide sendiri memperkirakan `too many arguments`. Tulis tanda kurungnya kalau di posisi ekspresi.

Dan pemanggilan tanpa argumen selalu butuh tanda kurungnya: nama telanjang adalah routine-nya sendiri, sebuah
nilai bertipe routine itu. `echo f` di mana `f` tidak butuh argumen adalah type mismatch; pesannya mendaftar
delapan kandidat overload `echo` dan satu baris di daftar itu adalah `expected: int64 but got: proc (): int64`
(`doc/language.md:2891-2893`).

## Rekursi dan urutan deklarasi

Routine boleh memanggil dirinya sendiri (`doc/language.md:2274`):

```
proc fact(n: int): int =
  if n <= 1:
    1
  else:
    n * fact(n - 1)
```

`fact(5)` adalah `120`. Rekursinya adalah pemanggilan biasa, bukan bentuk khusus; base case-nya adalah `if` yang
kembali tanpa memanggil dirinya lagi.

Urutan deklarasi tidak penting di level modul. Pemanggilan boleh muncul di atas deklarasi yang jadi tujuannya —
ini hasil probe di pin, bukan kutipan, karena guide tidak punya kalimat tentangnya:

```
echo later(4)

proc later(x: int): int = x + 1
```

Itu mencetak `5`. Seluruh modul ada dalam cakupan resolusi nama, jadi `proc` tidak butuh forward declaration
seperti prototype di C. Nama yang tidak ada di mana pun adalah error lain, dilaporkan sebagai `undeclared
identifier` — pencarian seluruh modul itulah yang membuat pemanggilan di atas deklarasinya bekerja.

## Sample

`samples/08-procedures/procedures.nim` — setiap konstruk di chapter ini, berurutan, di commit yang di-pin:

```
$ nimony c -r samples/08-procedures/procedures.nim
block 42
single 15
result hi!!
early pass
late checked 10
fail
bare 1 0
default 21
named 14
var 6
out 1 3
tuple 1 3
sink got abc
sink after abc
func 49
override ran
override 1
dot 11
note no parens
fact 120
later 5
```

Tiga baris membawa pelajarannya sendiri. `late checked 10` dan `fail` sesudahnya adalah satu routine: `echo`-nya
jalan, lalu ekspresi terakhir body menjadi hasilnya, jadi label dan nilainya mendarat di baris terpisah.
`override ran` sebelum `override 1` adalah `func` ber-`{.sideEffect.}` yang mencetak sebelum nilainya dipakai.
`sink after abc` adalah parameter `sink` yang meninggalkan variabel pemanggil apa adanya.

## Latihan

1. Tulis `proc double(x: int): int` dengan body blok `x * 2`, lalu bentuk satu ekspresi dari routine yang sama.
   Harapan: nilai yang sama dari keduanya.
2. Tulis body blok yang meng-echo `body` lalu punya `5` sebagai baris terakhirnya. Harapan: `body`, lalu `5`.
3. Tulis `proc counter(): int` dengan body `discard`. Harapan: `cannot prove that result has been
   initialized`.
4. Jalankan contoh `sign`. Harapan: `1` untuk `4` dan `0` untuk `-4`. Ganti `return` telanjang dengan `return
   result`. Harapan: tidak berubah.
5. Jalankan contoh `grade` dengan `70` dan dengan `10`. Harapan: `pass` saja, lalu `checked 10` diikuti `fail`.
6. Tulis `pad(n: int; width: int = 3)`. Harapan: `pad(7)` adalah `21`, `pad(7, 2)` adalah `14`, `pad(width = 2,
   n = 7)` adalah `14`. Coba `pad(count = 1)`. Harapan: `named argument not found`. Coba `pad(1, 2, 3)`.
   Harapan: `too many arguments`.
7. Tulis `proc scaled(x: int; factor: int = x): int`. Harapan: build mati dengan `[Bug] could not find symbol:
   x.0`. Ganti default-nya jadi `3`. Harapan: compile.
8. Jalankan contoh `bump`. Harapan: `6`. Ganti panggilannya jadi `bump(7)`. Harapan: `cannot pass 7 to var/out T
   parameter`.
9. Jalankan contoh `split`. Harapan: `1 3`. Pindahkan `r = a mod b` ke dalam `if false:` lalu build ulang.
   Harapan: `cannot prove that r has been initialized`.
10. Jalankan contoh `divmod`. Harapan: `1 3`.
11. Jalankan contoh `take`. Harapan: `sink got abc` lalu `sink after abc`.
12. Tulis `func square(x: int): int = x * x`. Harapan: `49`. Tambahkan `echo "side"` ke body-nya. Harapan:
    `cannot call a routine with side effects from a .noSideEffect context`. Tambahkan `{.sideEffect.}` ke
    deklarasinya. Harapan: compile dan mencetak.
13. Panggil routine yang mengembalikan `int` sebagai statement. Harapan: `expression of type int64 must be
    discarded`. Bungkus dengan `discard`. Harapan: compile.
14. Tulis contoh `note` dengan `note "no parens"`. Harapan: `note no parens`. Coba `let r = add 1, 2` dengan
    `add` dua argumen. Harapan: `invalid indentation`. Tambahkan tanda kurungnya. Harapan: compile.
15. Tulis `echo f` di mana `f` routine `int` tanpa argumen. Harapan: type mismatch yang memuat `proc ():
    int64`. Tulis `echo f()`. Harapan: nilainya.
16. Jalankan contoh `fact`. Harapan: `120`. Tulis `echo later(4)` di atas `proc later(x: int): int = x + 1`.
    Harapan: `5`.

## Checklist chapter

draft 2026-11-12 · tech_review Momo 2026-11-12 · editorial_pass 2026-11-12 · frozen 2026-11-12
