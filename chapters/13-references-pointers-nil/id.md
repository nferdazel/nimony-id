---
chapter: 13
title: References, Pointers, and Explicit Nilability
job: Separate managed `ref` from raw `ptr`, write the nil-ability into the type (`nil ref T`), and dereference only after proving non-nil.
nimony_version: 0.6.3
nimony_commit: 4ba90a781b0b22d0821efaa153c129c37cef6143
toolchain: ~/.local/opt/nimony/4ba90a7
host_compiler: ~/.local/opt/nim-2.4.0
status: frozen
tech_review: Momo 2026-11-13
editorial_pass: 2026-11-13
samples: ["samples/13-references-pointers-nil/refs.nim"]
glossary_added: ["ref (sourced)", "ptr (sourced)", "explicit nilability (extended)", "nil narrowing"]
---

# Reference, Pointer, dan Nilability Eksplisit

## Untuk apa bab ini

Setiap nilai yang kamu bangun sejauh ini di-copy saat di-assign, dan sebuah parameter adalah copy dari yang
dikirim pemanggil. Model itu patah begitu dua bagian program harus melihat cell yang sama, atau satu bagian
program mau menyentuh storage milik bagian lain. Nimony menjawab dengan dua alat berbeda — `ref` yang dikelola
dan `ptr` mentah — dan, di atas keduanya, satu batasan yang disengaja: **nilai mirip-pointer bukan nil kecuali
tipenya bilang begitu**.

Bab ini punya tiga kerjaan, berurutan: memilih antara `ref` dan `ptr`, menuliskan nil-ability ke dalam tipe
saat kamu butuh, dan melewati syarat pembuktian compiler di titik kamu melakukan dereference.

## Dua cara menunjuk sesuatu

`ref T` adalah reference yang dikelola: cell-nya hidup di managed heap, runtime menjaganya tetap hidup selama
masih ada reference ke sana, dan beberapa nama bisa menunjuk cell yang sama. `ptr T` adalah bentuk yang tidak
di-trace — alamat mentah yang kamu dapat sendiri, tanpa lifetime di belakangnya. `doc/language.md:774-783`
menarik garis antara reference yang di-trace dan yang tidak dengan cara ini.

Konsekuensi praktisnya adalah aliasing, dan itu mengubah perilaku sebuah parameter. Di Bab 11 aturannya:
parameter object by-value bukan place, jadi menulis ke sana sia-sia dan ditolak. Parameter `ref` kebalikannya:
copy-nya adalah copy dari *reference*-nya, dan menulis lewat situ mencapai cell-nya.

```nim
type Counter = ref object
  n: int

proc bump(c: Counter) =
  c.n += 1
```

Tidak ada `var` pada parameter, dan pemanggil melihat kedua increment. `c.n` adalah singkatan: `.` pada
reference melakukan dereference otomatis, dan `[]` melakukan hal yang sama untuk akses berindeks
(`doc/language.md:794-807`). Menulis `c[].n` legal dan, kata dokumentasinya, tidak dianjurkan — hasilnya sama.

Dua reference dibandingkan berdasarkan identitas, bukan isi: `a == b` bernilai `true` kalau kedua nama mencapai
cell yang sama, dan `false` untuk dua cell berbeda yang field-nya sama, karena kesetaraan reference adalah magic
`EqRef` (`src/nimony/magics.nim:64`). Ini bukan kesetaraan object yang Bab 11 ajarkan. Operator itu berjalan
field per field, dan ia berlaku pada nilai object — `a[] == b[]` — bukan pada dua reference ke object itu.

Menulis lewat parameter dan mengikat ulang parameter adalah dua hak berbeda. `c.n += 1` boleh;
`c = Counter(n: 9)` ditolak dengan `cannot mutate expression c`, karena parameternya adalah copy dari reference
dan parameter tidak bisa di-assign. Kamu boleh mengubah cell-nya; kamu tidak boleh mengubah cell mana yang dinamai
parameter itu.

Pointer mentah mulai dengan `addr`. Kalau `v` bertipe `T`, maka `addr v` bertipe `ptr T`, dan `p[]` membaca atau
menulis storage yang sama dengan yang dinamai `v`:

```nim
var local = 10
let p: ptr int = addr local
p[] = 20
echo local          # 20
```

`addr` berlaku pada satu variabel utuh atau pada satu elemen, jadi `addr arr[1]` memberi `ptr int` yang menulis
ke dalam array. Ini paruh bahasa yang tidak aman: tidak ada yang mengecek storage-nya masih ada saat kamu menulis
lewat pointer. Sisa bab ini soal satu hal yang *akan* dicek compiler untuk kamu, yaitu apakah pointer-nya nil.

## Tipe pointer yang tidak bisa nil

`ref`, `ptr`, `pointer`, `cstring` dan tipe prosedural tidak bisa memuat `nil` kecuali tipenya bilang begitu
(`doc/language.md:839`, dan pembahasan lebih penuh di `doc/lenientnils.md:7-19`). Compiler mencetak tipe seperti
itu dengan faktanya dieja — `ref Node.Obj not nil` — jadi pesan yang terlihat aneh pada awalnya sebenarnya
sedang mengutip tipe balik ke kamu.

Tiga error berbeda menjaga tiga cara berbeda untuk salah, dan layak dikenali satu per satu, karena masing-masing
punya perbaikan sendiri.

**Kamu menyerahkan nil.** `var r: Node = nil` untuk `Node` yang not-nil ditolak dengan `expected non-nil value`
(`src/nimony/contracts.nim:280`, dicapai dari `checkNilMatch`). Tidak ada yang dianalisis: nil memang bukan nilai
dari tipe itu.

**Tidak ada yang bisa dianalisis.** `cannot analyze expression is not nil: g` berarti akar ekspresinya bukan
place yang mau compiler pertimbangkan. Di pin ini kasusnya satu: variabel module-level. `analysableRoot`
(`src/nimony/contracts.nim:249-275`) menelusuri dot, subscript dan dereference turun ke simbol dasarnya, lalu
menolak simbol itu kalau ia global, karena global diasumsikan dibagi antar thread, jadi
`if glob != nil: use glob[]` tidak bisa dibuktikan benar. Dereference tidak dikecualikan:
`if q != nil: echo q[].data` dianalisis dengan baik selama `q` lokal. Komentar di cabang itu ditutup dengan
"Maybe this needs a better solution", jadi perlakukan ini sebagai perilaku pin, bukan aturan permanen.

**Ini lokal dan tidak ada faktanya.** `cannot prove expression is not nil: x` berarti kamu melakukan dereference
pada lokal nilable yang belum ditutup guard mana pun. Perbaikannya sebuah guard, dan section berikutnya soal di
mana compiler menerima guard.

Yang pertama punya wajah kedua. Tipe yang tidak bisa nil **tidak punya default value**, karena zeroed storage
terbaca nil dan itu persis yang ditiadakan tipe itu. Jadi deklarasi module-level tanpa nilai awal ditolak:

```
Error: 'base' is of type 'ref Node.Obj not nil', which has no default value
(it contains a not-nil pointer): give it an initial value
```

`src/nimony/contracts_fir.nim:5798-5821` membangun pesan itu. Aturan yang sama menangkap array dari tipe itu
(`array[0..2, ref Node.Obj not nil]`), object dengan field seperti itu (`'p' is of type 'Pair'`), dan tipe
prosedural (`'cb' is of type 'proc (x: int64)'`). Dua alasan `zeroedStorage` lain memakai pesan yang identik —
range yang mengecualikan nol, dan enum tanpa anggota berordinal 0 — dan keduanya milik Bab 4 dan 11.

**Lokal** diperlakukan berbeda, dan sumbernya menyebut alasannya: lokal tidak berutang apa pun pada
deklarasinya, karena flow analysis membiarkan `var r: ref int` berdiri selama sebuah penulisan mencapainya
sebelum pembacaan apa pun, yang lebih permisif dan sama amannya (`src/nimony/contracts_fir.nim:5805-5811`).
Baca terlalu cepat dan errornya berubah jadi lain — `cannot prove that r has been initialized`
(`src/nimony/contracts.nim:357`).

```nim
proc ok =
  var r: ref int
  r = make()          # a write first
  echo r[]

proc notOk =
  var r: ref int
  echo r[]            # Error: cannot prove that r has been initialized
```

## Menuliskan nilability ke dalam tipe

Awali tipe dengan `nil` dan ia boleh memuat nil: `nil ref int`, `nil ptr int`, `nil cstring`, `nil pointer`,
`nil proc (x: int)`, `nil Node` (`doc/language.md:841-853`, `doc/lenientnils.md:65-75`). Sebuah linked list
mengatakannya di setiap sambungan:

```nim
type Node = ref object
  data: int
  next: nil Node
```

Biaya menuliskannya adalah kewajiban: setiap dereference atas nilai `nil` harus dijaga oleh pemeriksaan yang
bisa dilihat compiler. Manfaatnya, `nil` berhenti jadi kejutan runtime dan menjadi argumen yang bisa dibawa type
checker.

Literal nil adalah argumen yang sah di tempat parameter `nil` diharapkan, jadi `total(nil)` adalah panggilan
normal untuk `proc total(list: nil Node)`. Mengirim nilai yang belum terbukti not-nil ke tempat parameter
**not-nil** diharapkan adalah error pertama lagi: `cannot prove expression is not nil: m`.

### Yang diterima compiler sebagai bukti

Pemeriksaannya adalah fakta yang menempel pada **place**, dan faktanya dilacak per lokal
(`src/nimony/inferle.nim:137-142` adalah tempat fakta `is not nil` dan `is nil` dibangun). Empat bentuk bekerja:

- `if x != nil:` menyempitkan `x` di dalam cabang.
- `if x == nil: return` menyempitkan `x` setelah cabang, karena cabang itu tidak berlanjut.
- `x != nil and x.field > 0` menyempitkan operand kanan.
- `while it != nil:` menyempitkan badan loop, dan itulah yang membuat walk list legal.

Walk-nya butuh satu detail hati-hati. Kondisi loop harus menguji **lokal**, jadi sample menyalin parameter ke
`var it = list` lalu memajukan `it`. Menguji parameternya langsung gagal karena alasan Bab 8 yang tidak
berkaitan — parameter tidak mutable, dan `list = list.next` ditolak dengan `cannot mutate expression list`.

Fakta terikat pada place, bukan pada cell, jadi apa pun yang menulis place itu menggugurkannya:

```nim
if x != nil:
  x = nil
  echo x[]        # Error: cannot prove expression is not nil: x
```

Dua jebakan mengikuti desain yang sama, dan keduanya memakan satu sore kalau kamu bertemu tanpa persiapan.

**Meng-assign nilai yang pasti not-nil tidak memperbaiki faktanya.** Nilability-nya ada di tipe, jadi ia
bertahan melewati assignment:

```nim
let m: nil Node = Node(data: 3)
echo m.data        # Error: cannot prove expression is not nil: m
```

Tipe `m` adalah `nil Node`; fact set tidak punya apa pun untuk dikatakan tentangnya, karena fakta adalah apa
yang dibangun sebuah perbandingan, bukan apa yang jadi initialiser-nya. Tambahkan guard, dan ia compile.

**Narrowing tidak menembus field.** `if p.n != nil: echo p.n.data` ditolak dengan
`cannot prove expression is not nil: p.n`. `analysableRoot` menelusuri ekspresi dot turun ke simbol dasarnya,
jadi `p.n` dan `p.m` sama-sama place `p` di fact set: fakta yang dicatat `if p.n != nil` adalah fakta tentang
`p`, yang tidak mengatakan apa pun tentang `p.n`. Ini keterbatasan analisisnya sebagaimana adanya, bukan aturan
sistem tipe, dan sumbernya menandainya sebagai sementara. Salin field-nya ke lokal, uji lokal itu, lalu pakai
lokal itu. Itulah persisnya kenapa walk list di sample bekerja lewat `it` dan bukan lewat `list.next`.

## Allocation, dan place yang kamu serahkan ke `new`

`new` adalah cara mendapat managed cell untuk tipe yang bukan konstruksi object:

```nim
func new*[T: ref](x: out T) {.inline.} = x = newConstr(T)
```

(`lib/std/system.nim:200`.) Parameternya `out T` untuk sembarang `T` yang memang ref, dan `T` boleh berbentuk
not-nil. Jadi lokal not-nil adalah tujuan yang sah, dan tipenya adalah bukti yang kamu butuhkan:

```nim
proc boxedNotNil(v: int): ref int =
  var tmp: ref int        # not-nil, no default value, no complaint at the declaration
  new(tmp)
  tmp[] = v
  tmp
```

Tidak ada yang perlu dijaga di sini. `tmp` adalah `ref int` sebelum panggilan dan `ref int` terisi sesudahnya,
jadi `return` menerimanya tanpa pemeriksaan. Yang tidak bisa kamu lakukan adalah berubah pikiran sesudahnya:
`tmp = nil` ditolak dengan `expected non-nil value`, dan `tmp == nil` dievaluasi jadi `false`.

Deklarasi not-nil di module level adalah kegagalan yang lain, dan itu bukan soal `new`: `var x: ref int` di
module level tidak punya default value, jadi deklarasinya ditolak sebelum `new` melihatnya.

`boxed` di sample mengambil varian nullable, untuk nilai yang harus dicek saat program berjalan:

```nim
proc boxed(v: int): ref int =
  var tmp: nil ref int = nil
  new(tmp)
  if tmp == nil: quit "out of memory"
  tmp[] = v
  tmp
```

Dengan tujuan nullable, `new` tidak membangun fakta apa pun sendiri: mesin fakta belajar dari perbandingan, bukan
dari pemanggilan, jadi `result = tmp` tepat setelah `new(tmp)` ditolak dengan `cannot prove expression is not
nil: tmp`, di setiap pemakaian `tmp`. Guard-nya menanggung beban, bukan hiasan; `quit` di cabang nil memuaskan
kedua analisis sekaligus, karena cabang itu tidak berlanjut dan `result` di-assign di satu-satunya jalur yang
berlanjut.

Konstruksi object adalah kasus mudah, dan layak diketahui bahwa keduanya tidak setara: `Node(data: 9)`
bertipe not-nil `Node` dan bisa langsung di-assign ke `var r: Node`, sementara `new` menyerahkan tipe tujuan —
lokal not-nil sudah berupa `ref T`, dan yang nullable masih meminta kamu membereskan kasus nil secara tertulis.

## Pointer mentah, `unchecked`, dan saklar porting

`nil ptr int` mengikuti aturan yang sama dengan `nil ref int`: ia memuat nil, ia melakukan dereference di bawah
guard, dan ia ditolak tanpa guard. `ptr T` di-assign ke `pointer` tanpa cast, dan `pointer` sendiri adalah tipe
mirip-pointer yang tidak bisa nil, jadi `var p: pointer = nil` adalah `expected non-nil value`.

Saat kasus nil benar-benar di luar jangkauan sistem tipe — handle FFI, invarian seperti "field status bilang
sukses berarti pointer-nya terpasang" — kamu keluar dengan `unchecked`, yang diterima pada `ref`, `ptr`,
`pointer`, `cstring` dan tipe prosedural, dan mematikan pelacakan nil untuk tipe itu (`doc/language.md:867-877`,
`doc/lenientnils.md:102-115`):

```nim
type Handle = object
  h: unchecked ref int

var x: Handle      # fine: an unchecked pointer has a default value
```

Pakai di tempat kamu bisa membuktikan not-nil dengan cara lain, dan tidak di tempat lain. Ia satu-satunya ejaan di
bab ini yang menyerahkan jaminan alih-alih memenuhinya.

## Nim 2 delta

> **Apa yang Nim 2 lakukan.** Setiap `ref`, `ptr`, `pointer` dan `cstring` bisa memuat nil, dan setiap deklarasi
> mendapat zeroed storage, jadi `var x: ref int` di module level legal dan diam-diam nil. Membacanya adalah
> fault runtime: program yang sama compile lalu mati dengan
> `SIGSEGV: Illegal storage access. (Attempt to read from nil?)`.
>
> **Apa yang Nimony lakukan.** Nil-ability adalah bagian dari tipe. `ref T` biasa tidak bisa nil, deklarasi
> dengan pointer not-nil tidak punya default value, dan dereference tanpa guard tidak compile. Bentuk nullable
> dieja `nil T`.
>
> **Apa yang patah kalau kamu pertahankan kebiasaannya.** Buffer module-level, field object dan variabel
> prosedural yang dulu mengandalkan zeroing sekarang butuh nilai awal. Helper yang menerima nil berarti
> "tidak ada" butuh `nil T` di signature-nya. Dan jalan keluarnya jujur soal harganya: di bawah
> `{.feature: "lenientnils".}` (`doc/lenientnils.md:141-155`) kode lama compile lagi, tanpa satu pun diagnostik
> saat compile, dan dereference nil-nya jadi fault runtime: prosesnya mati di titik dereference itu. Di
> toolchain dan platform yang dipakai buku ini itu exit 139, yang merupakan hasil pengukuran dan bukan janji;
> yang dipulihkan saklar itu adalah semantik Nim 2, pointer yang dicek saat runtime alih-alih saat compile.

## Samples

`samples/13-references-pointers-nil/refs.nim` adalah berkas di balik fragmen di atas: counter bersama, list yang
di-walk di bawah `while it != nil`, cell yang dialokasikan lewat `new` dan dijaga, dan pointer mentah yang
menulis sebuah lokal. Jalankan di pin:

```
$ nimony c -r samples/13-references-pointers-nil/refs.nim
2
6
0
42
20
```

Lima barisnya adalah counter setelah dua panggilan `bump`, total list, total list kosong yang dikirim sebagai
`nil`, nilai boxed plus satu, dan lokal yang ditulis lewat `p[]`.

## Cek

1. Deklarasikan `var g: nil Node = nil` di module level dan baca `g.data` di dalam proc di bawah `if g != nil:`.
   Hasil yang diharapkan: ia **tidak** compile, dan pesannya `cannot analyze expression is not nil: g`.
   Menyalin `g` ke lokal di dalam proc tidak menolong — copy itu pembacaan global yang tidak tersinkronisasi,
   ditolak dengan `unsynchronized access to global variable 'g'`. Kirim `g` sebagai parameter, atau ambil
   copy-nya di module level, dan ia compile.
2. Tulis `let m: nil Node = Node(data: 3)` lalu baca `m.data`. Harapan: `cannot prove expression is not nil:
   m`. Tambahkan `if m != nil:` dan pastikan lolos.
3. Tulis `type Holder = object` dengan field `n: nil Node`, isi sebuah `Holder` dengan node sungguhan, lalu
   `if h.n != nil: echo h.n.data`. Harapan: ditolak pada `h.n` dengan `cannot prove expression is not nil:
   h.n`, dan itu satu-satunya error; biarkan `h` tanpa inisialisasi dan keluhan pertamanya justru
   `cannot prove that h has been initialized`. Salin field-nya ke lokal dan pastikan lolos.
4. Ubah `total` supaya menerima `Node` alih-alih `nil Node` dan panggil dengan `nil`. Harapan: argumennya
   ditolak sebelum badan proc diperiksa.

## Checklist chapter

draft 2026-11-13 · tech_review Momo 2026-11-13 · editorial_pass 2026-11-13 · frozen 2026-11-13
