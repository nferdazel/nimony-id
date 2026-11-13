---
chapter: 15
title: Errors as Values
job: Report failure with `ErrorCode`, `{.raises.}` and `except ErrorCode`, and explain why there is no exception object to catch.
nimony_version: 0.6.3
nimony_commit: 4ba90a781b0b22d0821efaa153c129c37cef6143
toolchain: ~/.local/opt/nimony/4ba90a7
host_compiler: ~/.local/opt/nim-2.4.0
status: frozen
tech_review: Momo 2026-11-13
editorial_pass: 2026-11-13
samples: [samples/15-errors-as-values/errors.nim]
glossary_added: [ErrorCode, raises pragma, except arm, canraise, ref exception]
---

# Error sebagai Nilai

## Untuk apa chapter ini

Chapter 8 memberi lo routine yang selalu mengembalikan apa yang signature-nya janjikan. Chapter ini soal
routine yang tidak bisa begitu: yang pemanggilnya harus diberi tahu bahwa pekerjaannya tidak jadi. Nimony punya
tepat dua cara mengatakan itu, sebuah nilai enum dan sebuah objek `ref`, dan yang polos tidak membawa data sama
sekali. Mencari ke mana payload-nya pergi adalah sebagian besar isi chapter ini.

Bentuk yang jadi dasar bahasa ini: sebuah routine **mengembalikan** `ErrorCode` saat gagal itu biasa dan
pemanggil diharapkan memutuskan, dan **me-raise** `ErrorCode` saat gagal harus menginterupsi seluruh rantai
panggilan. Keduanya enum yang sama. Yang tidak dimiliki Nimony adalah objek exception Nim 2, jadi `except` tidak
punya `.msg` untuk dibaca dan tidak ada stack trace untuk dibongkar.

## Kegagalan yang dicek pemanggil

`ErrorCode` adalah enum biasa, dideklarasikan di `lib/std/errorcodes/errorcodes.nim:4` dalam berkas yang
dihasilkan `tools/gen_errorcodes.nim`. Ia punya 63 anggota di pin ini, dari `Success` di ordinal `0` lewat
`OverflowError`, `Failure`, `BugError`, `IndexError`, `SyntaxError`, `IOError`, `KeyError`, `ValueError` dan
sisanya, ditutup sembilan slot `Reserved` yang disimpan untuk nanti. `sizeof(ErrorCode)` adalah 1.

Karena cuma enum dan tidak lebih, sebuah routine bisa langsung mengembalikannya:

```nim
proc classify(ch: char): ErrorCode =
  if ch < '0' or ch > '9': return SyntaxError
  Success
```

Pemanggilnya membandingkan:

```nim
let code = classify('x')
if code == Success:
  echo "fine"
else:
  echo "rejected with ", code
```

Tiga detail penting sebelum paruh yang me-raise.

`Success` ordinal `0` tapi ia bukan `bool`. `if code:` ditolak dengan ``Error: expected `bool` but got:
ErrorCode``, jadi perbandingan satu-satunya cara mengujinya — dan itu bagus, karena `== Success` mengatakan apa
maksudnya.

`$` didefinisikan untuk enum, jadi `echo code` mencetak nama anggotanya (`SyntaxError`), dan `ord code` memberi
nomornya. Nama itu adalah seluruh diagnostiknya. Tidak ada string pesan yang menempel pada sebuah code, tidak
ada yang bisa ditambahi konteks, dan tidak ada tempat untuk menaruh posisi sumber.

Dan code yang dikembalikan tidak bisa dibuang tanpa sengaja: panggilan telanjang di posisi statement ditolak
dengan ``Error: expression of type `ErrorCode` must be discarded``. Kalau memang mengabaikannya yang lo mau,
tandai routine-nya `{.discardable.}`; kalau tidak, compiler baru saja memaksa lo memutuskan, dan itulah gunanya
mengembalikan code.

## Kegagalan yang menginterupsi

Mengembalikan code hanya jalan selama setiap pemanggil ingat memeriksanya. Begitu sebuah kegagalan harus naik
melewati routine yang tidak bisa berbuat apa-apa soal itu, bahasa ini butuh mekanisme kedua, dan mekanismenya
adalah `raise`:

```nim
proc digitValue(ch: char): int {.raises.} =
  if ch < '0' or ch > '9': raise SyntaxError
  result = ord(ch) - ord('0')
```

Pragma-nya bukan hiasan. Default Nimony untuk sebuah routine adalah *non-raising*, kebalikan Nim 2
(`doc/porting.md:100-113`), dan compiler menegakkannya dari dua arah:

- `raise` di routine tanpa pragma-nya ditolak, ``Error: `raise` only allowed within a routine with `raises` pragma`` (`src/nimony/sem.nim:3736`). `raise` di luar routine mana pun ditolak dengan pesan yang lebih pendek, ``Error: `raise` only allowed within a routine`` (`src/nimony/sem.nim:3733`); tidak ada raising di level atas modul.
- Memanggil routine `{.raises.}` tanpa `try` ditolak, ``Error: cannot call a routine marked as `.raises` outside of a `try`..`except` block`` (`src/nimony/derefs.nim:674`).

Aturan kedua mengejutkan orang di satu kasus: ia soal signature, bukan body. Routine `{.raises.}` yang mustahil
gagal tetap harus dipanggil di dalam `try`, karena pemanggil dikompilasi terhadap deklarasinya.

`{.raises.}` adalah singkatan dari `{.raises: ErrorCode.}` (`doc/language.md:4135`), dan menulisnya panjang
tidak mengubah apa pun. `{.raises: [].}` diterima dan berarti apa yang sudah berarti default.

## Menangkap

```nim
try:
  echo digitValue('4')
  echo digitValue('z')
except ErrorCode as e:
  echo "caught ", e
```

`e` adalah code-nya, bukan objek. `e` mencetak `SyntaxError`, `ord e` adalah `7`, dan `e == SyntaxError` adalah
`true`. Yang tidak ada adalah `e.msg`: menulisnya ditolak dengan ``Error: undeclared field: 'msg' for type
ErrorCode``. Pembaca yang mem-port kode Nim 2 akan meraihnya karena kebiasaan; obatnya adalah informasi itu
memang tidak pernah disimpan, jadi ia harus dibangun di tempat raise atau di tempat tangkap.

Arm-nya adalah filter tipe, dicoba berurutan (`doc/language.md:4149-4163`). Dua bentuk mengikuti dari situ.

Pertama, `except` mencocokkan tipe dan bukan nilai. `except IOError:` kelihatan masuk akal dan ditolak dengan
pesan yang menyatakan aturannya lebih baik daripada manualnya:

```
Error: `IOError` is an `ErrorCode` value, not a type; write `except ErrorCode as e:` and test `e == IOError`
```

Ujiannya ditaruh di dalam arm, dan `case` atas sebuah `ErrorCode` butuh `else`, karena enum-nya punya 63
anggota dan tidak semuanya menarik:

```nim
try:
  f()
except ErrorCode as e:
  case e
  of KeyError: echo "key"
  of Failure: echo "general failure"
  else: echo "other ", e
```

Kedua, `except:` telanjang menangkap semuanya, apa pun keluarga yang me-raise, jadi ia berfungsi sebagai arm
terakhir di rantai mana pun. Arm dicoba dari atas, jadi penangkap-segala yang ditaruh pertama menaungi semuanya
di bawahnya.

Ikat sekali. Satu arm `except ErrorCode as e` dengan `case` di dalamnya adalah bentuk yang aman, dan alasannya
bukan soal gaya. Di pin ini dua arm `except ErrorCode as` dalam satu rantai tidak aman: nama yang diikat kedua
build dengan mulus selama body-nya mengabaikannya, lalu menghentikan backend C dengan `[Bug] could not find
symbol: e2.0`, exit 1, begitu body itu membacanya — setelah type checking lewat. Menaruh satu arm `ref` di mana
pun dalam rantai itu menghindarinya, dan itu punya sebab, bukan keberuntungan: raise `ref` yang mencapai frame
memilih lowering lain, `emitDispatcher` (`src/nimony/derefs.nim:1316-1317`), yang menulis ulang seluruh rantai
jadi satu handler sintetis dengan satu binding, sehingga binding kedua tidak pernah lewat jalur yang menghilangkan
nama itu. Tetap bukan bentuk yang pantas dirancang. Dispatch-nya masuk ke dalam satu arm.

### `finally` dan `defer`

`finally` jalan di kedua jalur, dan ia jalan sebelum error meninggalkan routine:

```nim
proc guarded(): int =
  try:
    result = digitValue('q')
  except ErrorCode as e:
    echo "handled ", e
    result = -1
  finally:
    echo "finally ran"
```

Keluarannya `handled SyntaxError`, lalu `finally ran`, lalu `-1`. `defer: cleanup()` dikompilasi jadi `finally`
luar yang sama dan jalan di jalur gagal juga (`doc/language.md:4222-4248`).

`try` yang hanya punya `finally` dan tanpa `except` **tidak** memenuhi aturan panggilan yang me-raise.
Pemeriksaannya minta penangkap, dan `finally` bukan penangkap.

### Sebuah `try` adalah ekspresi

`try` bisa menghasilkan nilai, dan arm `except`-nya harus sepakat soal tipenya:

```nim
let n = try:
    digitValue('5')
  except ErrorCode as e:
    echo "defaulted after ", e
    -1
```

Ini cara yang biasa untuk memberi panggilan yang bisa gagal sebuah fallback tanpa `result` mutable di antaranya.

## Inisialisasi `result` sebelum `try`

Satu jebakan ada di interaksinya dengan pemeriksaan definite assignment Chapter 8. Ketika satu-satunya
assignment ke `result` ada di dalam body `try`, pemeriksa tidak bisa membuktikan assignment itu terjadi —
body-nya bisa me-raise sebelum mencapainya. Build berhenti dengan:

```
Error: cannot prove that result has been initialized
```

Obatnya satu baris di atas routine:

```nim
proc readIt(path: string): string =
  result = ""
  try:
    result = readFile(path)
  except ErrorCode as e:
    result = "error: " & $e
```

`doc/porting.md:149-155` mencatat caveat yang sama untuk kode yang di-port, dan ini build break paling sering
ketika routine Nim 2 dikonversi secara mekanis.

## Keluarga lain: exception `ref`

Sebuah `ErrorCode` tidak membawa payload. Ketika sebuah kegagalan harus mengatakan *kunci mana* yang hilang atau
*di mana* parsing berhenti, tipe yang bisa di-raise adalah objek `ref` yang mewarisi `Exception`:

```nim
type ParseError = ref object of Exception
  at: int

proc checkAt(s: string; i: int) {.raises: ParseError.} =
  if i >= s.len: raise ParseError(at: i)
```

`Exception` dideklarasikan di `lib/std/system.nim:712` dengan satu field, `msg: string`, dan dari situ `.msg`
datang saat keluarga ini dipakai. Arm-nya filter tipe lagi, dan ia menerima tipe yang di-raise beserta
subtipe-nya:

```nim
try:
  checkAt("abc", 9)
except ParseError as e:
  echo "no character at ", e.at
```

Nenek moyangnya wajib. `ref object` polos tanpa `Exception` di rantainya tidak punya runtime type information,
dan `{.raises: T.}` maupun `except T` menolaknya: ``Error: `.raises` takes a `ref` object type with RTTI, not
`ref Bare.Obj not nil`; inherit its object from `Exception` ``. `object of Exception` juga tidak cukup; pragma-nya
minta yang `ref`.

Kedua keluarga tidak pernah terkonversi, dua arah, dan pesannya mengatakan itu alih-alih menafsirkan ulang diam-diam
(`src/nimony/derefs.nim:651-684`):

```
Error: `ErrorCode` raised here cannot leave a routine that raises `ref ParseError.Obj not nil`,
and nothing converts one into the other
```

Jadi sebuah routine me-raise code atau me-raise exception `ref`, dan rantai yang harus menyeberang dari satu ke
yang lain melakukannya eksplisit: tangkap code-nya, `raise` objek `ref` yang dibangun di arm `except`. Konversi
itu pernyataan di source lo, bukan perilaku compiler.

Satu baris di halaman itu salah, dan baris sebelahnya tidak. `doc/porting.md:106` memberi bentuk tangkapnya
sebagai `except IOError:` dengan "no `as`, no `.msg`"; di pin ini `as` wajib — `except IOError:` tidak compile —
dan `.msg` memang ada, di keluarga `ref`. Baris konstruksi di `:105` adalah kolom Nimony yang menjelaskan apa
yang dilakukan kode Nim 2, dan ia benar soal Nim 2: `newException(IOError, "text")` adalah yang dibawa sebuah
port, dan `:121` menyuruh lo mengonversinya. Dikonversi apa adanya, ia tidak jalan, karena `IOError` adalah
nilai, bukan tipe; panggilannya ditolak dengan ``expected: typedesc[T] but got: ErrorCode``. `newException` ditulis
untuk tipe `object of Exception` (`lib/std/system.nim:717-722`); untuk sebuah code, raise-nya *adalah* nilainya.

## Switch kompatibilitas yang menelan error

`doc/language.md:4994` mendaftar fitur `"canraise"`, "allows procs without a `raises` annotation to raise
exceptions". Ia compile, dan ia jebakan yang pantas satu paragraf. Dengan `{.feature: "canraise".}` di atas
modul, program ini build dan mencetak `before call`, `in f`, `after call`:

```nim
{.feature: "canraise".}

proc f() =
  echo "in f"
  raise KeyError

f()
echo "after call"
```

Raise-nya tidak mencapai pemanggil. Routine-nya return, pemanggilnya lanjut, dan error-nya hilang — tanpa
diagnostik, tanpa exit code, tanpa catch. Lowering-nya tidak punya kanal error untuk routine yang tidak
mendeklarasikannya, jadi raise-nya turun derajat jadi return (`src/hexer/eraiser.nim:690-712`), dan itu return
dari titik tersebut: statement setelah `raise` juga tidak jalan, jadi routine-nya berhenti lebih awal dan tetap
melaporkan sukses. Routine `{.raises.}` di modul yang sama tetap jalan normal; yang tidak dianotasi itulah yang
kehilangan kegagalannya. Jangan pakai fitur ini untuk membungkam compiler.

## Keluar dari program

Ketika sebuah kegagalan tidak bisa dipulihkan di tempat ia ditangkap, `quit` mengakhiri program dengan pesan dan
exit code 1. Pesannya pergi ke standard output, bukan standard error — layak diketahui sebelum lo mem-pipe hasil
sebuah program.

```nim
try:
  f()
except ErrorCode as e:
  quit "fatal: " & $e
```

`src/lib/compat2.nim:17-28` membungkus pola ini persis sebagai `onRaiseQuit(call)`, dan komentar di situ
menerangkan kenapa ia ada: untuk menghentikan `raises` menyebar lewat setiap lapisan tanpa diam-diam menelan
error-nya. Chapter 21 membahas exit code dan argumen dengan benar; untuk chapter ini, `quit` adalah cara sebuah
`main` mengubah code yang tertangkap jadi exit yang bukan nol.

## Nim 2 delta

*Apa yang Nim 2 lakukan.* `raise newException(IOError, "msg")` membangun objek di heap, membawa pesan dan stack
trace-nya, dan `except IOError as e: echo e.msg` membacanya kembali. Proc bebas me-raise kecuali dianotasi
`{.raises: [].}`.

*Apa yang Nimony lakukan.* Code adalah nilai: `raise IOError`, tanpa alokasi, tanpa pesan, tanpa trace.
Default-nya non-raising, dan routine yang me-raise mengatakannya dengan `{.raises.}`. Exception `ref` masih ada
untuk pembaca yang butuh payload, tapi ia keluarga terpisah, ia harus mewarisi `Exception`, dan ia tidak
terkonversi ke atau dari `ErrorCode`.

*Apa yang rusak kalau lo pertahankan kebiasaannya.* Tiga hal, dalam urutan yang ditemui sebuah port. `.msg` pada
code yang ditangkap adalah compile error. `newException(IOError, ...)` tidak build. Dan setiap routine di
sepanjang jalur yang me-raise harus dianotasi atau menangkap, jadi modul yang tidak pernah mendeklarasikan
`{.raises.}` tidak akan compile sama sekali — dan itu compiler memberi tahu di mana keputusannya harus ditaruh.

## Samples

`samples/15-errors-as-values/errors.nim`, dikompilasi dan dijalankan di commit yang di-pin:

```
$ nimony c -r samples/15-errors-as-values/errors.nim
digit 7
rejected x with SyntaxError
value 4
caught SyntaxError
number 12
second call failed with SyntaxError
no character at 9
inside guarded: SyntaxError
finally ran
guarded -1
```

Sepuluh baris, dalam urutan itu. `tools/verify-samples.sh` mengompilasi dan menjalankan setiap sample di buku ini
dan exit 0 hanya kalau semuanya jalan; ia tidak membandingkan stdout, jadi sepuluh baris di atas adalah keluaran
yang diharapkan dan hal yang dicek dengan mata.

## Cek

1. Tulis `proc half(n: int): ErrorCode` yang mengembalikan `RangeError` untuk input ganjil dan `Success` kalau
   tidak, lalu panggil tanpa memakai hasilnya. Baca error-nya, lalu buat panggilannya legal dengan dua cara
   berbeda dan katakan apa yang masing-masing janjikan ke pembaca.
2. Pindahkan `raise` di `digitValue` ke routine kedua tanpa `{.raises.}`. Catat pesannya, lalu tambahkan
   pragma-nya dan catat apa yang berubah di sisi *pemanggil*.
3. Ambil `try` di "Menangkap" dan pecah `case`-nya jadi tiga arm `except ErrorCode as`. Build, lalu tuliskan apa
   yang dilaporkan compiler dan di tahap mana.
4. Ganti `except ParseError as e: echo e.at` dengan `except ErrorCode as e:` dan baca pesannya. Lalu konversi
   keluarganya dengan benar: tangkap code-nya dan raise sebuah `ParseError` dengan kuncinya di dalam.
5. Compile program `{.feature: "canraise".}` apa adanya, lalu ubah `proc f()` jadi `proc f() {.raises.}`.
   Jalankan keduanya dan terangkan bedanya dalam satu kalimat.

## Chapter checklist

`draft 2026-11-13 · tech_review Momo 2026-11-13 · editorial_pass 2026-11-13 · frozen 2026-11-13`
