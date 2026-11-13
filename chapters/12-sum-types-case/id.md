---
chapter: 12
title: Sum Types and Exhaustive `case`
job: Express alternatives as variants and match the discriminator with an exhaustive `case`, preferring that over sentinel fields and flags.
nimony_version: 0.6.3
nimony_commit: 4ba90a781b0b22d0821efaa153c129c37cef6143
toolchain: ~/.local/opt/nimony/4ba90a7
host_compiler: ~/.local/opt/nim-2.4.0
status: frozen
tech_review: Momo 2026-11-12
editorial_pass: 2026-11-12
samples: ["samples/12-sum-types-case/sumtypes.nim"]
glossary_added: ["sum type", "discriminator", "exhaustive case"]
---

# Sum Type dan `case` yang Exhaustive

## Untuk apa bab ini

Sebuah bentuk bisa lingkaran, persegi panjang, atau segitiga, dan masing-masing butuh data berbeda untuk
menjelaskannya. Godaannya satu object dengan semua field dan flag `kind`, di mana separuh field mati pada nilai
mana pun. Godaan berikutnya boolean: `isCircle`, lalu `isRectangle`, lalu flag ketiga untuk kasus yang tidak
dicakup keduanya.

**Sum type** — object varian — mengatakannya sekali. Object-nya punya **discriminator**: field yang menyimpan
alternatif mana nilai ini. Tiap alternatif punya field sendiri, dan field alternatif lain bukan bagian dari
nilai itu sama sekali. `case` atas discriminator lalu mendaftar setiap alternatif, dan compiler menolak
membangun `case` yang melewatkan satu.

Penolakan itulah inti bab ini. Ia cek saat compile, dan itulah alasan memilih bentuk ini dibanding flag:
alternatif baru mematahkan setiap `case` yang lupa menanganinya, saat build, bukan di production.

## Bentuk sebuah varian

Section `case` di dalam object mendeklarasikan alternatifnya (`doc/language.md:592-655`):

```nim
type
  ShapeKind = enum
    Circle, Rectangle, Triangle

  Shape = object
    case kind: ShapeKind
    of Circle:
      radius: float
    of Rectangle:
      width, height: float
    of Triangle:
      a, b, c: float
```

`kind` adalah discriminator-nya, dan tipenya harus ordinal — enum, integer, `bool`. Selector `string` ditolak
dengan `selector must be of an ordinal type` (`ch12-probes/c40.nim`, `src/nimony/sem.nim:3207`). Holey enum,
yang Bab 11 tunjukkan dengan ordinal eksplisit dan celah, ditolak karena alasan yang sama: tes yang
menerima tipe di sini menolak tipe bercelah (`src/nimony/typeprops.nim:17-33`), dan barisnya datang terbungkus:

```
[Error] c38.nim(8, 5) illformed AST inside object: (err . "selector must be of an ordinal type")
```

Section-nya harus mencakup setiap nilai, atau diakhiri `else` (`doc/language.md:627`). Melewatkan satu berarti
error build. Deklarasi sendirian melaporkannya dengan bersih, dengan daftar yang sama seperti yang diberikan
statement `case`:

```nim
type
  Kind = enum Circle, Rectangle, Triangle
  Shape = object
    case kind: Kind
    of Circle:
      radius: float
    of Rectangle:
      width, height: float
```

```
rv17.nim(5, 5) Error: not all cases are covered; missing: {Triangle}
```

Konstruksi satu nilai dari tipe itu dan constructor-nya melaporkan informasi yang sama lewat error generiknya,
dengan baris terbungkus (`rv19.nim` adalah deklarasi di atas plus satu konstruksi):

```
[Error] rv19.nim(5, 5) illformed AST inside case object: (err . "not all cases are covered; missing\3A \7BTriangle\7D")
```

Bacalah sebagai `not all cases are covered; missing: {Triangle}`. Informasinya ada dan lokasinya baris `case`,
tapi compiler melaporkannya sebagai nilai error yang tertinggal di dalam badan tipe: barisnya dimulai
`illformed AST inside case object:` dan pesannya datang ter-escape (`\3A` untuk `:`, `\7B` dan `\7D` untuk
kurung kurawal). Constructor menemui node error itu saat menyusuri badan tipe (`src/nimony/sem.nim:4705`),
itulah kenapa bungkusnya butuh konstruksi. Kemasannya jelek, dan itu dicatat di `ERRATA.md`, bukan diajarkan
sebagai output normal.

`else` diterima di section itu (`c3.nim`, `c17.nim`), dan field-nya jadi milik setiap nilai yang tidak disebut
cabang `of`. Untuk enum, menuliskan setiap anggota adalah kebiasaan yang lebih baik: `else` menyembunyikan
anggota yang ditambahkan suntingan berikutnya.

Dua aturan lagi, keduanya ditolak saat deklarasi:

- Satu nama tidak boleh muncul di dua cabang: `of Circle: radius: float` di samping `of Rectangle: radius: float`
  memberi `attempt to redeclare: radius` (`c24.nim`). Cabang-cabangnya berbagi storage, seperti yang diukur
  angka `sizeof` di bawah, jadi satu nama field tidak bisa mewakili dua cabang dari satu nilai.
- Dalam bentuk ini discriminator adalah field bernama, dan menghilangkan namanya adalah parse error: `case bool`
  memberi `':' or '=' expected, but got 'keyword of'` (`c30.nim`). Anonymous sum type — `case` tanpa nama dan
  tanpa selector — adalah bentuk terpisah yang tidak punya nama untuk diwajibkan; `else` di dalamnya justru
  ditolak, dengan `[Error] ... illformed AST inside object: (err . "sum type case objects cannot have an else
  branch")` (`rv14.nim`, `src/nimony/sem.nim:3075`).

## Mengonstruksi varian

Konstruksi menyebut discriminator dan field milik satu alternatif itu. Field alternatif lain tidak ditulis, dan
yang dilewatkan mengambil default tipe-nya (`doc/language.md:629-641`, `c10.nim`, `c35.nim`):

```nim
let c = Shape(kind: Circle, radius: 1.0)
let r = Shape(kind: Rectangle, width: 2.0, height: 3.0)
let t = Shape(kind: Triangle, a: 3.0, b: 4.0, c: 5.0)

echo Shape(kind: Rectangle, width: 1.0).height   # 0.0
echo Shape(kind: Rectangle).width                # 0.0
```

Discriminator dicek terhadap field yang kamu sebut, dan ada tiga penolakan yang layak dikenali dari pesannya
(`src/nimony/sem.nim:4559-4578`):

| Yang kamu tulis | Yang dikatakan compiler |
| --- | --- |
| `Shape(kind: Circle, width: 3.0)` | `a case selecting discriminator 'kind' with value 'Circle' appears in the object construction, but the field(s) 'width' are in conflict with this value.` (`c4.nim`) |
| `Shape(kind: Circle, radius: 1.0, width: 3.0)` | `The fields 'radius' and 'width' cannot be initialized together, because they are from conflicting branches in the case object.` (`c5.nim`) |
| `Shape(radius: 1.0)` — tanpa discriminator | `cannot prove that it's safe to initialize 'radius' with the runtime value for the discriminator 'kind'.` (`c51.nim`) |

Baris pertama itulah alasannya discriminator harus nilai enum *literal* saat field cabang disebut. Pin ini
hanya mengenali ejaan literal di constructor (`src/nimony/sem.nim:4601-4612`), jadi discriminator yang ditulis
sebagai nama — `let` atau `const` — ditolak walaupun nilainya benar, dan pesannya mengklaim konflik yang tidak
ada:

```nim
const k = Circle
let s = Shape(kind: k, radius: 1.0)   # refused: "...with value 'k' ... field(s) 'radius' are in conflict"
let ok = Shape(kind: Circle, radius: 1.0)   # builds
let ok2 = Shape(kind: ShapeKind.Circle, radius: 1.0)   # builds, qualified name is still a literal
```

Probe `c29.nim`, `c49.nim`, `c50.nim`, `rv1.nim`, `rv2.nim`. Tulis nilainya langsung; `ShapeKind.Circle` yang
berkualifikasi baik-baik saja. Batasannya milik constructor saja: `const` yang sama tetap bekerja sebagai
label `of` di `case` (`rv15.nim`, `rv16.nim`). Tanpa field cabang sama sekali, discriminator runtime
diperbolehkan — `Shape(kind: k)` build dan field cabangnya mulai dari default (`c31.nim`).

## Mencocokkan dengan `case`

Statement `case` dari Bab 6 adalah alatnya di sini. Ia mengambil discriminator dan mendaftar alternatifnya
(`doc/language.md:1776-1840`):

```nim
func area(s: Shape): float =
  case s.kind
  of Circle:
    result = PI * s.radius * s.radius
  of Rectangle:
    result = s.width * s.height
  of Triangle:
    let p = (s.a + s.b + s.c) / 2.0
    result = sqrt(p * (p - s.a) * (p - s.b) * (p - s.c))
```

`PI` dan `sqrt` berasal dari `std/math`, yang diimpor sample.

Bentuk ekspresi bekerja sama dan menghasilkan nilai (`doc/language.md:2086-2100`):

```nim
let label =
  case r.kind
  of Circle: "round"
  of Rectangle: "boxy"
  else: "pointy"
```

### Yang dicek compiler

Di pin ini ceknya adalah `checkExhaustiveness` (`src/nimony/sem.nim:2699-2748`), dan satu pemanggilan melayani
statement `case`, ekspresi `case`, dan section `case` milik object sendiri (`sem.nim:3290`); hanya tempat ia
meninggalkan error yang berbeda. Lewatkan satu anggota enum dan build berhenti di kepala `case` dengan nilai
yang hilang disebut:

```
c13.nim(14, 3) Error: not all cases are covered; missing: {Triangle}
```

Daftar itulah alasan memilih bentuk ini. Tambahkan alternatif keempat ke `ShapeKind` dan setiap `case` yang
men-switch-nya gagal build sampai alternatif itu ditangani. Dengan `bool` dan dua flag, tidak ada yang gagal.

Sisa aturan yang akan ditemui pembaca, masing-masing satu probe:

- Selector yang bukan enum mendapat pesan yang sama tanpa daftar: `case` `int` tanpa `else` memberi
  `not all cases are covered` (`c55.nim`, `c19.nim`). `int` tidak pernah bisa tercakup, jadi compiler tidak
  berpura-pura menyebut apa yang hilang.
- Label duplikat adalah `value already handled`, dilaporkan di duplikatnya (`c57.nim`, `c37.nim`).
- Label yang salah ketik adalah `undeclared identifier: Cirlce`, diikuti daftar yang hilang (`c59.nim`).
- Dua nilai enum dalam satu `of` legal — `of Square, Rectangle:` — dan begitu juga range pada selector ordinal,
  `of 0..3:` (`c16.nim`, `c62.nim`).
- `else` diperbolehkan walaupun enum-nya tercakup penuh (`c28.nim`). Itu dead code; pilih daftar penuh.
- `bool` punya dua nilai, jadi `of true:` dan `of false:` tidak butuh `else` (`c54.nim`).
- `case` juga menerima holey enum sebagai selector: jalur statement tidak pernah menjalankan tes yang dijalur
  discriminator, jadi tipe itu diterima karena tidak ada yang mengeceknya, bukan karena ia memenuhi syarat
  (`c39.nim`, `c56.nim`).

### Yang tidak dicek compiler

Ini bagian yang memakan satu sesi debugging kalau tidak dikatakan terang-terangan. Field cabang berbagi satu
blok storage, dan pin ini tidak mengeluarkan **cek runtime** sama sekali atas cabang mana yang aktif. Membaca
field cabang yang tidak aktif tetap compile dan mengembalikan apa pun yang ada di storage:

```nim
let s = Shape(kind: Circle, radius: 1.0)
echo s.width     # 1.0 — the radius occupies that slot; nothing complains
echo s.height    # 0.0 — this slot is untouched
```

Menulis berjalan sebaliknya, ke storage yang sama, dan membiarkan discriminator-nya:

```nim
var s = Shape(kind: Circle, radius: 1.0)
s.width = 99.0
echo s.width     # 99.0
echo s.kind      # Circle
```

Probe `c7.nim` dan `c8.nim`. Meng-assign discriminator langsung legal pada `var`, dan itu tidak membersihkan
atau membangun ulang apa pun — byte lama tetap dan ditafsirkan ulang:

```nim
var s = Shape(kind: Circle, radius: 1.0)
s.kind = Rectangle
s.width = 3.0
echo s.radius    # 3.0 — the radius slot now holds the width
```

Probe `c9.nim`. Pada `let`, assignment yang sama ditolak lebih awal dengan `cannot mutate expression s.kind`
(`c36.nim`). Layout di bawah inilah alasannya tidak ada yang mengecek: cabang-cabangnya union tanpa tag yang
dibaca saat akses, dan `FieldDefect`, nama Nim 2 untuk cek semacam ini, tidak muncul di mana pun di bawah
`lib/` atau `src/`. Guard-nya kerjaan kamu. `case` adalah cara menulisnya; apa yang dibaca cabang harus cabang
yang cocok dengan `kind`.

`sizeof` menunjukkan layout tempat biayanya berasal: satu byte untuk discriminator, lalu cabang terbesar,
dibulatkan ke alignment `float`. Untuk `Shape` tiga cabang di atas, `sizeof(ShapeKind)` adalah `1` dan
`sizeof(Shape)` adalah `32` — satu byte plus cabang segitiga 24 byte, dipadkan ke 8 (`rv10.nim`). Bentuk dua
cabang sejenis berukuran `24` (`c44.nim`). Cabang yang field-nya beririsan ukuran berbagi ruang itu; tidak ada
yang menandai setiap akses.

Satu bentuk lagi yang harus dihindari, dan ini diagnostik yang hilang, bukan aturan: statement `case` yang
cabang `of`-nya nilai telanjang dan cabang *lainnya* berisi loop `for` mati di dalam compiler dengan
``xelim.nim(118, 3) `result.typeKind != AutoT` ``. Nilai telanjangnya sudah salah sendiri — ia ditolak dengan
``expression of type `int64` must be discarded`` (`rv12.nim`) — jadi ini diagnostik yang disembunyikan `for`,
bukan kode yang bekerja tapi ditolak compiler. `else` tidak diperlukan untuk memicunya: `of false` melakukan
hal yang sama (`rv8.nim`). Bentuk minimalnya probe `r2.nim`:

```nim
proc f(b: bool): int =
  case b
  of true:
    1
  else:
    for i in 0..2:
      result = result + 1
```

Tulis assignment di setiap cabang — `of true: result = 1` — dan ia build (`r3.nim`). Dicatat di `ERRATA.md`
bersama probe-nya.

## Varian bersarang

Satu cabang boleh memuat `seq` bertipe sama, begitulah tree ditulis
(`doc/language.md:635-655`):

```nim
type
  NodeKind = enum
    Leaf, Branch

  Node = object
    id: int
    case kind: NodeKind
    of Leaf:
      value: string
    of Branch:
      children: seq[Node]

func total(n: Node): int =
  case n.kind
  of Leaf:
    result = n.id
  of Branch:
    result = n.id
    for child in n.children:
      result = result + total(child)
```

Probe `c12.nim` membangun tree yang sama, mencetak `2`, `a`, `6`. Varian `ref object` juga bekerja, dengan
konstruksi dan `case` yang sama (`c25.nim`).

> **Nim 2 delta — cek field runtime hilang**
>
> *Apa yang Nim 2 lakukan* → membaca field cabang yang tidak aktif memunculkan `FieldDefect: field 'width' is
> not accessible for type 'Shape' using 'kind = Circle'`, dan meng-assign discriminator memunculkan
> `FieldDefect: assignment to discriminant changes object branch` (`nim2/n1.nim`, `nim2/n2.nim` di compiler
> host).
> *Apa yang Nimony lakukan* → keduanya tidak dicek. Pembacaan mengembalikan storage union-nya, dan assignment
> hanyalah penulisan field biasa (`c7.nim`, `c9.nim`).
> *Apa yang rusak kalau kamu mempertahankan kebiasaan lama* → kode yang bersandar pada defect itu untuk menangkap
> cabang yang salah sekarang mencetak angka yang masuk akal, dan port yang men-switch `kind` pada nilai yang
> sudah ada mempertahankan byte lama. Jaga dengan `case` sebelum setiap pembacaan cabang; jangan bergantung
> pada compiler untuk menangkap sisanya.

## Samples

Satu berkas membuktikan bab ini: `samples/12-sum-types-case/sumtypes.nim`.

```
~/.local/opt/nimony/4ba90a7/bin/nimony c -r samples/12-sum-types-case/sumtypes.nim
```

Lewat verifier:

```
$ ./tools/verify-samples.sh
PASS samples/12-sum-types-case/sumtypes.nim exit=0
SUMMARY 11/11 passed, 0 failed
```

Output-nya, berurutan:

```
circle(1.0)
rect(2.0x3.0)
tri(3.0,4.0,5.0)
3.141592653589793
6.0
6.0
boxy
0
4
0.0
0.0
2.0
99.0
Rectangle
true
Branch
2
a
6
```

Tiga baris pertama adalah `$` pada tiap varian. Lalu tiga luas: lingkaran, persegi `2x3`, dan segitiga `3-4-5`
lewat rumus Heron. `boxy` adalah ekspresi `case` dengan `else`. `0` dan `4` adalah dua jawaban `sides`. `0.0`
dan `0.0` adalah field persegi yang dilewatkan: `height` saat hanya `width` ditulis, lalu `width` saat keduanya
tidak. Lalu `2.0` dan `99.0`: salinannya berubah, aslinya tidak, dan `Rectangle` serta `true` adalah
discriminator salinan dan kesamaan field-per-field. Empat terakhir adalah tree-nya: `Branch`, dua anak, nilai
leaf pertama, dan `6` — jumlah tiga `id`-nya.

## Cek

1. Deklarasikan `Shape` dari bab ini lalu konstruksi `Circle` dan `Rectangle`. Harapan: keduanya build;
   lingkaran tidak punya `width` dan persegi tidak punya `radius`.
2. Beri `ShapeKind` anggota keempat lalu build ulang tanpa menyentuh `area`. Harapan:
   `not all cases are covered; missing: {<anggota baru>}` di kepala `case`.
3. Hapus `of Triangle` dari section `case` milik object-nya sendiri. Harapan: build berhenti dengan baris
   `illformed AST inside case object`, dan `missing: {Triangle}` di dalamnya.
4. Konstruksi `Shape(kind: Circle, width: 3.0)`. Harapan: baris `...field(s) 'width' are in conflict with this
   value.`
5. Konstruksi dengan `radius` dan `width` sekaligus. Harapan: `The fields 'radius' and 'width' cannot be
   initialized together...`.
6. Konstruksi `Shape(radius: 1.0)` tanpa discriminator. Harapan: `cannot prove that it's safe to initialize
   'radius' with the runtime value for the discriminator 'kind'.`
7. Taruh `Circle` di sebuah `const` lalu konstruksi `Shape(kind: k, radius: 1.0)`. Harapan: ditolak, dan
   pesannya menyebut `k`. Tulis `Shape(kind: ShapeKind.Circle, ...)` sebagai gantinya. Harapan: build.
8. Bangun `Circle` dengan `radius: 1.0`, lalu cetak `s.width` dan `s.height`. Harapan: `1.0` dan `0.0`, tanpa
   diagnostik — pembacaannya tidak dicek, dan radius menempati slot pertama.
9. Pada `var` `Circle`, assign `s.kind = Rectangle` dan `s.width = 3.0`, lalu cetak `s.radius`. Harapan:
   `3.0`, dari storage yang dibagi.
10. Lakukan assignment discriminator yang sama pada `let`. Harapan: `cannot mutate expression s.kind`.
11. Tulis `case` atas `ShapeKind` yang mengulang `of Circle` dua kali. Harapan: `value already handled`.
12. Tulis `of Cirlce`. Harapan: `undeclared identifier: Cirlce` plus daftar yang hilang.
13. Cetak `sizeof(ShapeKind)` dan `sizeof(Shape)` untuk versi tiga cabang. Harapan: `1` dan `32`.
14. Bangun tree `Node` dari bab ini dan cetak `total`. Harapan: `6`.

## Checklist chapter

draft 2026-11-12 · tech_review Momo 2026-11-12 · editorial_pass 2026-11-12 · frozen 2026-11-12
