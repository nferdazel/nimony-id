---
chapter: 10
title: Arrays, Sequences, and Tuples
job: Choose between fixed-size `array`, growable `seq` and heterogeneous `tuple`, with their slicing and unpacking rules.
nimony_version: 0.6.3
nimony_commit: 4ba90a781b0b22d0821efaa153c129c37cef6143
toolchain: /Users/sachiel/.local/opt/nimony/4ba90a7
host_compiler: /Users/sachiel/.local/opt/nim-2.4.0
status: frozen
tech_review: Momo 2026-11-12
editorial_pass: 2026-11-12
samples: ["samples/10-arrays-sequences-tuples/collections.nim"]
glossary_added: ["openArray", "view", "place", "tuple unpacking", "value semantics"]
---

# 10. Arrays, Sequences, and Tuples

## Untuk apa chapter ini

Chapter 9 memilih routine berdasarkan tipe argumen. Chapter ini memilih container berdasarkan apa yang harus
dilakukan data. Tiga bentuk menutupi sebagian besar kebutuhan: `array` kalau panjangnya sudah diketahui sebelum
program jalan, `seq` kalau tumbuh selama program jalan, dan `tuple` kalau bagian-bagiannya adalah sekumpulan
field tetap dengan tipe berbeda.

Ketiganya value. Meng-assign satu menyalinnya. Parameter by-value bukan place, jadi routine tidak bisa
menulisnya; lewatkan sebagai `var` kalau memang harus menulis. Itulah kenapa menulis satu elemen array tidak
mengubah array asal salinannya, dan kenapa parameter `seq` tidak bisa ditumbuhkan di tempat: `add` butuh `var`,
jadi routine yang mau lebih banyak elemen menyalin parameter ke `var` lokal dulu. Pilihan di antara ketiganya
soal bentuk dan izin, bukan kecepatan: mana yang bisa tumbuh, apa yang boleh mengindeksnya, dan apa yang
dikembalikan sebuah slice.

## Tiga bentuk, satu keputusan

| Bentuk | Panjang | Tipe elemen | Akses |
| --- | --- | --- | --- |
| `array[N, T]` | tetap sebelum program jalan | satu, semuanya `T` | posisi, oleh tipe ordinal apa pun |
| `seq[T]` | tumbuh selama program jalan | satu, semuanya `T` | posisi dari 0, plus `add` dan `pop` |
| `tuple` | tetap, satu slot per field | satu per field, dan boleh berbeda | nama field atau posisi |

`doc/language.md:344-355` mendefinisikan array, `:376-408` sequence, dan `:476-495` tuple. Garis yang memisahkan
dua yang pertama dari yang ketiga adalah homogenitas: `array` dan `seq` menyimpan satu tipe elemen, sementara
tuple adalah storage heterogen. Tuple boleh mencampur tipenya:

```
let mixed = (1, "a", true)
echo mixed[0]
echo mixed[1]
echo mixed[2]
```

```
1
a
true
```

## Array: panjangnya bagian dari tipe

Konstruktor array adalah sepasang kurung siku. Tipe elemennya datang dari elemen pertama, dan setiap elemen lain
harus terkonversi ke situ (`doc/language.md:356-358`):

```
let a = [10, 20, 30]
echo a.len
echo a.low
echo a.high
let f = [1.0, 2, 3]
echo f[1]
```

```
3
0
2
2.0
```

`2` menjadi `2.0` karena elemen pertama memutuskan tipe elemennya `float`. Tipenya bukan `array[10, 20, 30]`:
sintaks kurung siku itu konstruktor, sedangkan `array[N, T]` adalah tipenya. Dua peran berbeda untuk kurung yang
sama, dan deklarasi `var xs: array[3, int] = [1, 2, 3]` memakai keduanya dalam satu baris.

Panjangnya harus diketahui sebelum program jalan. Menulisnya dari sebuah variabel ditolak, dan pesannya
menyebut nama variabelnya, bukan "not constant":

```
var n = 3
var a: array[n, int]
```

```
Error: invalid array index type: n
```

Pemeriksaannya di `src/nimony/semtypes.nim:776`; panjang berupa konstanta jalan (`const N = 3; var a: array[N,
int]`, sudah diprobe). Sintaksnya punya dua bentuk, dan keduanya tidak berarti sama (`doc/language.md:353-355`):

```
var five: array[5, int]
var six: array[0..5, int]
echo five.len
echo six.len
```

```
5
6
```

`array[5, T]` itu panjang: lima elemen, indeks `0..4`. `array[0..5, T]` itu rentang: batas bawahnya 0 dan batas
atasnya 5, jadi isinya enam. Bentuk panjang diubah menjadi rentang indeks `0 .. length-1` di
`src/nimony/semtypes.nim:779-791`. Kalau mau jumlah, tulis jumlahnya; kalau mau batas eksplisit, tulis batasnya
dan perkirakan satu elemen lebih banyak dari selisihnya.

Rentang dengan batas bawah berbeda menggeser indeks yang sah dan mempertahankan panjangnya:

```
type Row = array[1..3, int]
var row: Row = [5, 6, 7]
echo row[1]
echo row.low
echo row.high
for x in row:
  echo x
```

```
5
1
3
5
6
7
```

Konstruktornya tetap mengisi dari posisi pertama array, bukan dari indeks 1, dan loop `for` tetap mengunjungi
elemennya berurutan. Mengindeks dengan 0 adalah error compile, karena compiler tahu nilainya di luar rentang:

```
type Row = array[1..3, int]
var row: Row = [5, 6, 7]
echo row[0]
```

```
value out of range: 0 notin 1..3
```

Pesan itu pemeriksaan statis atas indeks literal. Dengan indeks berupa variabel, kesalahan yang sama
tertangkap saat runtime, dan program keluar dengan pesan dari `lib/std/system/panics.nim:86`:

```
let a = [10, 20, 30]
var i = 5
echo a[i]
```

```
index out of bounds: 5 notin 0..2
```

Exit code 1, tidak ada nilai yang dicetak.

Tipe ordinal apa pun boleh mengindeks array (`doc/language.md:351`), termasuk enum:

```
type Color = enum red, green, blue
var counts: array[Color, int]
counts[green] = 5
echo counts[green]
echo counts.len
echo counts.low
echo counts.high
```

```
5
3
red
blue
```

Array-nya tiga elemen karena `Color` punya tiga nilai, dan `low` serta `high` mengembalikan nilai bertipe indeks
— dicetak lewat `$`-nya, itu sebabnya terbaca sebagai nama, bukan angka. Elemen yang tidak pernah ditulis terbaca
sebagai zero value-nya, pendefaultan yang sama dengan `var` di level modul (Chapter 3); `five[4]` di sample
mencetak `0` justru karena itu.

Array bisa ditulis di sebuah indeks hanya kalau array-nya sendiri bisa ditulis. `[]` bawaan mengembalikan `var T`
(`lib/std/system.nim:25`), jadi `var` array bisa ditulis lewat situ; `let` array tidak bisa:

```
let a = [1, 2, 3]
a[0] = 9
```

```
/.../lib/std/system.nim(37, 4) Error: cannot mutate expression a[0]
```

Penolakannya datang dari salah satu template `[]=` untuk array di `lib/std/system.nim:34-37` — pesannya menunjuk
yang kedua, `:37` — jadi penulisannya tidak pernah sampai ke storage. Dan array menyalin saat di-assign, jadi
salinannya mandiri:

```
var a = [1, 2]
var b = a
b[0] = 9
echo a[0]
echo b[0]
```

```
1
9
```

Array bersarang tanpa sintaks khusus: `array[2, array[2, int]]` adalah tabel dua-kali-dua, dan `grid[1][0]`
menelusurinya dalam dua langkah indeks.

## Seq: storage yang tumbuh

Sequence ditulis dengan konstruktor array yang sama plus `@` (`doc/language.md:376-380`):

```
var xs = @[1, 2, 3]
xs.add 4
echo xs.len
echo xs.pop
echo xs.len
echo xs[0]
echo xs.high
```

```
4
4
3
1
2
```

`add` menambahkan satu elemen (`lib/std/system/seqimpl.nim:213`), `pop` membuang dan mengembalikan yang terakhir
dan mensyaratkan sequence-nya tidak kosong (`lib/std/system/seqimpl.nim:363`). Tidak ada operator konkatenasi di
pin ini: `xs & ys` tidak punya kandidat untuk `seq`, dan `xs.add ys` gagal karena `add` menerima satu `sink T`,
bukan sequence. Overload `&` yang ada cuma untuk string dan char
(`lib/std/system/stringimpl.nim:1034-1063`). Untuk tumbuh dari sequence lain, tambahkan elemennya dalam loop.

Cara lain mendapat storage adalah `newSeq`, yang mengisi elemennya dengan nilai default (`0` untuk `int`,
`lib/std/system/seqimpl.nim:76-77`):

```
var ys = newSeq[int](4)
echo ys.len
echo ys[3]
```

```
4
0
```

Literal kosong tidak punya tipe elemen untuk diinfer, jadi perlu anotasi di kiri:

```
let e = @[]
```

```
Error: could not infer type for T.141.sysvq0asl
```

Angka dan huruf setelah `T.` adalah nama mangled untuk instansiasi itu. Itu nama internal yang tidak stabil antar
rilis, jadi jangan mencocokkan sufiksnya; bagian yang perlu dibaca adalah `could not infer type`.

`let e: seq[int] = @[]` terbangun. Panjang sequence kosong adalah `0` dan `high`-nya `-1`
(`lib/std/system/seqimpl.nim:354-358`); beda dengan array, sequence kosong adalah nilai normal yang bisa lo
tumbuhkan.

Sequence menyalin seperti value lain: assignment menyalin elemennya, dan routine yang menerima sequence by-value
sama sekali tidak bisa mengubah sequence pemanggil. Menumbuhkan salinannya tidak menyentuh aslinya:

```
var a = @[1, 2]
var b = a
b.add 3
echo a.len
echo b.len
```

```
2
3
```

Di batas panggilan aturannya lebih ketat dari "salinannya mandiri": parameter sequence adalah value, dan `add`
butuh `var`, jadi menumbuhkan parameter itu sendiri ditolak.

```
proc grow(xs: seq[int]): int =
  xs.add 3
  result = xs.len
```

```
Error: cannot pass xs to var/out T parameter
```

Salin dulu ke `var` lokal. Barulah routine mengembalikan panjang yang lebih besar dan sequence pemanggil tidak
berubah:

```
proc grow(xs: seq[int]): int =
  var copy = xs
  copy.add 3
  result = copy.len

var s = @[1, 2]
echo grow(s)
echo s.len
```

```
3
2
```

Ini aturan parameter `var` yang sama dengan yang dinyatakan Chapter 8, dilihat dari sisi container: argumen `add`
harus sebuah place, dan parameter by-value bukan place.

Mengindeks sequence diperiksa berbeda dari array. `[]` untuk `seq` membawa klausa `requires`,
`i < s.len and i >= 0` (`lib/std/system/seqimpl.nim:239`), dan indeks yang salah memicu klausa itu sebagai
assertion, bukan mencetak baris "index out of bounds":

```
var xs = @[1, 2, 3, 4]
var i = 9
echo xs[i]
```

```
/.../lib/std/system/seqimpl.nim(239, 41): i < s.len [AssertionDefect]
```

Exit code 1. Dua container menolak kesalahan yang sama dengan dua cara berbeda; tidak ada yang mengembalikan
nilai.

`@` juga mengonversi array menjadi sequence, dan konversinya menyalin:

```
let fixed = [7, 8]
var grown = @fixed
grown.add 9
echo grown.len
echo fixed.len
```

```
3
2
```

## Slicing: salinan untuk `seq`, view untuk `array`

Slice ditulis dengan `..` atau `..<` di dalam kurung siku. Untuk sequence hasilnya sequence baru berisi salinan
elemen (`lib/std/system.nim:658-668`), jadi menumbuhkannya tidak menyentuh sumber:

```
var xs = @[1, 2, 3, 4]
var mid = xs[1..2]
mid.add 99
echo mid.len
echo xs.len
```

```
3
4
```

Batasnya di-clamp, bukan diperiksa: `xs[2..10]` mengambil apa pun yang ada di sumber mulai indeks 2, dan batas
bawah di atas batas atas menghasilkan sequence kosong, bukan error. Implementasinya meng-clamp dengan
`max(x.a, 0)` dan `min(x.b, s.len - 1)` dan menghitung panjangnya hanya kalau `b >= a`.

```
let xs = @[1, 2, 3, 4]
echo xs[2..10].len
echo xs[5..1].len
echo xs[1..^1].len
echo xs[0..<2].len
```

```
2
0
3
2
```

`^1` adalah indeks terakhir, jadi `xs[1..^1]` membuang elemen pertama; `..<` mengecualikan batas atasnya
(`lib/std/system.nim:610-616`, `:626`, `:672-673`).

Array tidak punya operator slice. `a[1..2]` gagal, karena overload slice hanya dideklarasikan untuk `string` dan
`seq` (`lib/std/system.nim:649`, `:658`, `:672`) dan array tidak punya kandidat:

```
let a = [1, 2, 3, 4]
let sl = a[1..2]
```

```
Type mismatch at [position]
a[1 .. 2]
[1] array[0..3, int64] does not match constraint T (declared in .../lib/std/system.nim(24, 1))
[2] expected: int64 but got: HSlice[int64,int64] (declared in .../lib/std/system.nim(25, 1))
... 18 more candidate lines
[2] expected: BackwardsIndex but got: HSlice[int64,int64] (declared in .../lib/std/system.nim(632, 1))
```

Daftar itu 21 baris kandidat, setiap overload `[]` dan slice yang bisa dicoba compiler. Slice `seq` yang
sebenarnya dibutuhkan panggilan ini ada di tengahnya (`lib/std/system.nim:658`); dua baris terakhir adalah
compiler mencoba bentuk `^`, `BackwardsIndex`, yang bukan tipe argumennya. Intinya baris pertama — `[]` milik
array menerima indeks integer, dan tidak ada overload yang menerima array plus rentang.

Perkirakan juga derau lanjutan: binding yang gagal meninggalkan `sl` tanpa tipe, jadi `sl.len` dan `sl[0]`
masing-masing menghasilkan error sendiri dengan daftar kandidatnya sendiri. Dari situ asal 59 baris kalau lo
hitung semuanya — tiga daftar, bukan satu.

Jalur array adalah `toOpenArray`, converter yang membangun `openArray` (`lib/std/system/openarrays.nim:25`). Itu
bukan salinan; itu view atas storage array, dideklarasikan `{.view.}` di `lib/std/system/openarrays.nim:6-9`:

```
var letters = [10, 20, 30, 40]
let view = letters.toOpenArray(1, 2)
view[0] = 99
echo view.len
echo letters[1]
```

```
2
99
```

Menulis lewat view mengubah array-nya. `let` mengikat view-nya, bukan storage-nya: view adalah pointer plus
panjang (`lib/std/system/openarrays.nim:6-9`), dan `[]`-nya mengembalikan `var T`
(`lib/std/system/openarrays.nim:10`). Pemeriksaan read-only setuju, lewat aturan khusus: sebuah `let` itu
readonly kecuali tipenya view, dan di situ compiler memeriksa ulang dari apa view itu dibangun
(`src/nimony/derefs.nim:399-407`, komentar di `:406`). Jadi ini jalan di atas storage `var` dan ditolak di atas
array `let`. Ini satu-satunya tempat di chapter ini di mana nama `let` masih berujung ke penulisan, dan itu
memang inti sebuah view.

Tipe yang sama dipakai routine untuk menerima kedua container tanpa konversi (`doc/language.md:412-425`):

```
func total(v: openArray[int]): int =
  result = 0
  for x in v:
    result = result + x

let arr = [1, 2, 3]
let sq = @[4, 5]
echo total(arr)
echo total(sq)
echo total([6, 7, 8])
```

```
6
9
21
```

Parameter `var openArray` menulis balik ke pemanggil, baik pemanggil melewatkan array maupun sequence:

```
proc bump(v: var openArray[int]) =
  v[0] = v[0] + 100

var a = [1, 2, 3]
bump(a)
echo a[0]
```

```
101
```

Tanpa `var`, penulisannya ditolak: `v[0] = 0` menjadi panggilan `[]=`, yang parameter pertamanya `var
openArray[T]` (`lib/std/system/openarrays.nim:13`), dan error-nya `cannot pass v to var/out T parameter`.
Lewatkan view sebagai `var` kalau routine memang dimaksudkan mengubahnya.

Satu aturan dari Chapter 9 berlaku di sini, dan chapter ini tidak mengulangnya: `[]` bawaan untuk array dan untuk
sequence mengembalikan `var T` (`lib/std/system.nim:25`, `lib/std/system/seqimpl.nim:239`), itu sebabnya dua
container ini bisa ditulis tanpa mendeklarasikan `[]=`. Container yang lo tulis sendiri mengikuti aturan di
Chapter 9, bukan salinannya di sini.

## Tuple: field, urutan, dan salinan

Tuple adalah produk terurut: rangkaian field tetap, masing-masing dengan tipenya sendiri. Dua tipe tuple adalah
tipe yang sama kalau menyebut field yang sama dalam urutan yang sama, dan panduannya menambahkan nama field-nya
juga harus sama (`doc/language.md:482-487`). Bangun dengan tanda kurung, dalam urutan field
(`doc/language.md:478-482`):

```
type Person = tuple[name: string, age: int]
var p: Person = (name: "Ada", age: 36)
var q: Person = ("Bob", 20)
echo p.name
echo p.age
echo p[0]
echo q.name
```

```
Ada
36
Ada
Bob
```

Konstruksi posisional dan bernama adalah tuple yang sama: tipe yang dideklarasikan menyediakan namanya, jadi
`q.name` jalan walau literalnya tidak punya nama. Urutan tidak opsional — `(36, "Ada")` untuk `Person` ditolak
dengan type mismatch yang mencetak kedua tuple, `got: tuple[int64, string] but wanted: tuple[name: string,
age: int64]`.

Yang tidak jalan adalah sintaks konstruktor object. `Person(name: "Ada", age: 36)` ditolak:

```
Error: expected type symbol for object constructor
```

Tuple memakai bentuk tanda kurung; sintaks panggilan bernama-field milik `object`, yang dibahas Chapter 11.

Nama tinggal di tipe, bukan di literal. Tuple yang ditulis tanpa tipe yang diharapkan hanya punya field
posisional, jadi meminta nama gagal:

```
let q = ("Bob", 20)
echo q.name
```

```
Error: undeclared field: 'name' for type tuple[string, int64]
```

Kebalikannya juga berlaku di pin ini, dan panduannya berbeda. Dua tipe tuple dengan tipe field sama dalam urutan
sama tapi nama field berbeda bisa di-assign:

```
type P = tuple[name: string, age: int]
type Q = tuple[label: string, years: int]
var p: P = ("Ada", 36)
var q: Q = p
echo q.label, q.years
```

```
Ada36
```

`doc/language.md:485` bilang namanya juga harus sama; pin hanya membandingkan tipe field dan urutannya, dan
sumbernya menyatakan itu terang-terangan — "only the type of the field is important"
(`src/nimony/sigmatch.nim:2435`). Itu memang disengaja, bukan defect, jadi buku ini mengajarkan pin-nya dan
mencatat `doc/language.md:485` sebagai documentation gap di `ERRATA.md`. Jangan pakai ini sebagai rename — tidak
ada yang menjanjikan dua nama itu tetap bisa saling tukar — dan jangan menganggap compiler akan menolaknya juga.

Tipenya tetap harus cocok. Mengganti tipe satu field gagal, dan pesannya menunjukkan kedua sisi:

```
type R = tuple[label: string, years: string]
var r: R = p
```

```
Error: type mismatch: got: tuple[name: string, age: int64] but wanted: tuple[label: string, years: string]
```

Tuple menyalin field demi field saat assignment (`doc/language.md:564`). Routine yang menerima tuple by-value
tidak bisa menulisnya: penulisan field pada parameter ditolak template `[]=` yang read-only
(`lib/std/system.nim:24`, `:32-33`).

```
type Person = tuple[name: string, age: int]
var person: Person = ("Ada", 36)
var other = person
other.age = 37
echo person.age
echo other.age
```

```
36
37
```

Tuple `let` tidak bisa ditulis, dan pesannya menyebut field berdasarkan posisi, bukan nama, karena akses field
diturunkan ke `[]` (`lib/std/system.nim:24`) dan penulisannya lewat template `[]=`:

```
let p: Person = ("Ada", 36)
p.age = 37
```

```
Error: cannot mutate expression p[1]
```

Unpacking adalah alasan tuple sering jadi tipe kembalian untuk beberapa nilai. Ia jalan di statement `var`,
`let` dan `const` (`doc/language.md:1669-1671`), `_` melewati satu field (`:1672-1678`), dan polanya bersarang
(`:1702-1708`):

```
proc pair(): (int, int) = (4, 2)
let (a, b) = pair()
echo a
echo b
let (x, _, z) = (1, 2, 3)
echo x
echo z
let (m, (n, o)) = (1, (2, 3))
echo m
echo n
echo o
```

```
4
2
1
3
1
2
3
```

Kalau nilainya literal tuple, setiap nama di-assign langsung tanpa temporer (`doc/language.md:1689-1699`); kalau
nilainya panggilan, tuple-nya dibangun sekali dan dibaca per posisi (`doc/language.md:1680-1688`), yang penting
kalau panggilannya punya efek.

Dua bentuk kecil melengkapi tipenya. Tuple satu field ditulis dengan koma di ekor, `(1,)`, dan koma itu
diperbolehkan di konstruksi tuple mana pun (`doc/language.md:499-510`); tipenya juga bisa ditulis di bagian
`type` dengan indentasi alih-alih daftar field (`:515-523`).

## Memilih

- Panjang diketahui saat lo menulis program, satu tipe elemen, tanpa pertumbuhan: `array`. Utamakan bentuk jumlah
  `array[N, T]`; pakai rentang hanya kalau indeksnya sendiri bermakna.
- Panjang ditentukan saat program jalan, satu tipe elemen: `seq`. Tumbuhkan dengan `add`, baca dengan `[]`.
- Sekumpulan field tetap dengan tipe berbeda, biasanya dikembalikan routine atau disimpan sebagai satu baris:
  `tuple`.
- Routine yang harus menerima kedua container: ambil `openArray[T]`. Tambahkan `var` hanya kalau harus menulis
  balik.
- Slice `seq` adalah salinan; slice `array` ditulis `toOpenArray` dan merupakan view. Putuskan mana yang lo
  butuh sebelum menulis kurung sikunya.

## Sample

`samples/10-arrays-sequences-tuples/collections.nim` — tiga bentuk, slicing dua arah, dan unpacking, di commit
yang di-pin:

```
$ nimony c -r samples/10-arrays-sequences-tuples/collections.nim
2
3
5
6
0
5
1
3
5
red
4
4
3
1
2
3
3
1
0
2
2
4
3
6
6
2
99
Ada
36
36
37
4
2
1
3
1
2
3
```

Empat angka pertama adalah array dua-kali-dua: panjangnya `2`, lalu `grid[1][0]`, lalu `5` dan `6` untuk bentuk
jumlah melawan bentuk rentang. `0` adalah `five[4]`, elemen yang tidak ditulis dan terbaca zero value-nya. `5`,
`1`, `3` adalah row yang tidak berbasis nol: elemen, `low`, `high`; `5` dan `red` adalah nilai array berindeks
enum dan `low`-nya. Bagian sequence menjalankan `4`, `4`, `3`, `1`, `2`: panjang setelah `add`, elemen yang
di-pop, panjang baru, elemen pertama, `high`. `3` dan `3` adalah panjang slice setelah `add`-nya sendiri dan
panjang sumber yang tidak berubah; `1`, `0`, `2` adalah slice yang di-clamp, yang terbalik, dan yang `^1`. Lalu
`2`, `4`, `3` membandingkan salinan array-ke-sequence dengan dua sequence yang di-assign, dan `6`, `6` adalah dua
panggilan `openArray`. `2` dan `99` adalah panjang view dan elemen array yang ia ubah. Sisanya tuple: `Ada`,
`36`, `36`, `37` untuk field bernama, akses posisional dan salinannya, lalu tiga unpacking.

## Latihan

1. Tulis `let a = [10, 20, 30]` dan cetak `a.len`, `a.low`, `a.high`. Harapan: `3`, `0`, `2`.
2. Tulis `let f = [1.0, 2, 3]` dan cetak `f[1]`. Harapan: `2.0`.
3. Tulis `var n = 3; var a: array[n, int]`. Harapan: `invalid array index type: n`. Ganti `n` dengan
   `const N = 3`. Harapan: terbangun.
4. Deklarasikan `array[5, int]` dan `array[0..5, int]`. Harapan panjang `5` dan `6`.
5. Deklarasikan `array[1..3, int] = [5, 6, 7]`, cetak `[1]`, `low`, `high`, lalu indeks `[0]`. Harapan: `5`,
   `1`, `3`, lalu `value out of range: 0 notin 1..3`.
6. Indeks array tiga elemen dengan variabel berisi `5`. Harapan: `index out of bounds: 5 notin 0..2`, exit code
   1.
7. Tulis `var xs = @[1, 2, 3]; xs.add 4; echo xs.pop`. Harapan: `4`, dan `xs.len` jadi `3` sesudahnya.
8. Tulis `let e = @[]`. Harapan: `could not infer type`. Tambahkan `: seq[int]`. Harapan: terbangun dan
   `high`-nya `-1`.
9. Tulis `var a = @[1, 2]; var b = a; b.add 3`. Harapan: `a.len` `2`, `b.len` `3`.
10. Slice `@[1, 2, 3, 4]` dengan `[2..10]`, `[5..1]` dan `[1..^1]`. Harapan panjang `2`, `0`, `3`.
11. Slice `[1, 2, 3, 4]` dengan `[1..2]`. Harapan: daftar 21 baris kandidat; slice `seq` yang dibutuhkannya ada
    di tengah daftar. Ganti dengan `toOpenArray(1, 2)` dan tulis `view[0] = 99`. Harapan: elemen 1 array-nya
    jadi `99`.
12. Tulis `func total(v: openArray[int])` dan panggil dengan array, sequence, dan literal. Harapan: nilai yang
    sama dengan yang dicetak sample, dari ketiganya.
13. Deklarasikan `type P = tuple[name: string, age: int]` dan dua nilai `("Ada", 36)` serta
    `(name: "Bob", age: 20)`. Cetak `p.name` dan `p[0]`. Harapan: `Ada` dan `Ada`.
14. Tulis `Person(name: "Ada", age: 36)` untuk tipe tuple. Harapan: `expected type symbol for object
    constructor`.
15. Unpack `(1, (2, 3))` sebagai `let (m, (n, o)) = ...` dan cetak ketiganya. Harapan: `1`, `2`, `3`. Ganti `n`
    dengan `_`. Harapan: tetap terbangun.

## Checklist chapter

draft 2026-11-12 · tech_review Momo 2026-11-12 · editorial_pass 2026-11-12 · frozen 2026-11-12
