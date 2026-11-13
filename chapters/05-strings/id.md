---
chapter: 5
title: Strings
job: Treat `string` as an ordinary value with no null terminator: build, index, slice, and compare it, and know where `cstring` still appears.
nimony_version: 0.6.3
nimony_commit: 4ba90a781b0b22d0821efaa153c129c37cef6143
toolchain: ~/.local/opt/nimony/4ba90a7
host_compiler: ~/.local/opt/nim-2.4.0
status: frozen
tech_review: Momo 2026-11-12
editorial_pass: 2026-11-12
samples: ["samples/05-strings/strings.nim"]
glossary_added: ["string", "null terminator", "cstring", "slice", "escape sequence", "raw string", "concatenation"]
---

# String

## Untuk apa chapter ini

`string` di Nimony adalah nilai biasa: punya panjang, menyalin dirinya saat kamu assign, dan berupa urutan byte
yang bisa kamu index. Yang **tidak** dia punya adalah byte nol tak terlihat di ujungnya, dan perubahan tunggal
itulah yang paling sering membongkar kebiasaan dari bahasa lain.

Chapter ini mengajar nilai itu lebih dulu — bangun, index, slice, bandingkan — lalu batasnya, di mana `cstring`
masih muncul dan berapa harga konversinya.

## String adalah nilai

Setiap literal string bertipe `string` (`doc/language.md:280`), dan `len` bawaan mengembalikan panjangnya:

```
let title = "Nimony"
echo title.len        # 6
```

String adalah value type. Assignment menyalin atau memindahkan payload — tidak ada referensi, jadi dua nama tidak
pernah menunjuk karakter yang sama (`doc/language.md:284`):

```
var line = "abc"
var copy = line
copy.add "d"
echo line             # abc
echo copy             # abcd
```

Itu bukan catatan kaki. Ini yang menentukan apa yang dilakukan sebuah procedure terhadap string yang dia terima:
tanpa parameter `var`, dia bekerja di salinannya sendiri, dan string milik pemanggil tidak tersentuh. (Chapter 8
membahas parameter selengkapnya.)

## Membangun string

Operator `&` menyambung (`doc/language.md:303`). `add` menambahkan di tempat dan butuh `var`, jadi dia bentuk
yang lebih murah ketika kamu menumbuhkan satu string di dalam loop:

```
var line = "strings"
line.add " and "
line.add "values"
echo line             # strings and values
```

`add` menerima `string` atau satu `char`. `&` juga menerima `char` di sisi mana pun
(`lib/std/system/stringimpl.nim:1062-1063`), dan itu cara paling sederhana mengubah satu karakter menjadi string:

```
echo "" & 'z'         # z
```

Tidak ada konversi implisit ke arah sebaliknya. `"n=" & 42` tidak compile — compiler mencoba memuat sisi kanan ke
dalam `char` lalu melaporkan `expected: char but got: int64` (`lib/std/system/stringimpl.nim:1062`). Ubah dulu
angkanya jadi string:

```
echo "n=" & $42       # n=42
```

## Panjang, index, slice

String di-index seperti array, batas bawah `0` (`doc/language.md:287-288`), dan `s[i]` menghasilkan `char` ke-i,
yaitu satu byte (`doc/language.md:299-300`). Karakter terakhir adalah `s[^1]`:

```
echo title[0]         # N
echo ord(title[0])    # 78
echo title[^1]        # y
```

Index **diperiksa**. Routine indexing-nya membawa kontrak `i < len(s) and i >= 0`
(`lib/std/system/stringimpl.nim:686`), jadi membaca satu melewati ujung bukan `'\0'` yang tenang — programnya
berhenti:

```
echo "hello"[5]   # runtime: stringimpl.nim(686, 37): i < len(s) [AssertionDefect]
```

Runner-nya lalu mencetak `FAILURE: nimcache/c/.../probe` dan prosesnya keluar dengan kode non-nol.

Pemeriksaannya terjadi saat program jalan, bukan saat compile: compiler menerima `s[5]` pada string lima karakter
dan assertion-nya menyala belakangan. Index yang kamu hitung sendiri adalah tanggung jawabmu.

Pemeriksaan tetap hidup di bawah `-d:release`; hanya `-d:danger` yang mematikannya (`nimony --help`), dan setelah
itu `s[5]` membaca byte apa pun yang kebetulan ada setelah payload dan programnya lanjut. Gue sudah
mengonfirmasi keduanya di pin: default dan `-d:release` berhenti dengan `AssertionDefect` di atas, `-d:danger`
mencetak byte nyasar itu.

**Slice** berperilaku beda. `s[a..b]` dan `s[a..<b]` mengembalikan string baru, dan batasnya dijepit bukan
diperiksa (`lib/std/system.nim:649-652` memanggil `substr`, `lib/std/system/stringimpl.nim:706-717`): `first`
dinaikkan ke `0`, `last` diturunkan ke `high(s)`, dan rentang kosong menghasilkan `""`.

```
echo "clamped"[0..20]   # clamped
echo "abc"[2..1]        # (baris kosong)
```

Setiap slice adalah salinan. Jadi slicing aman, tapi tidak gratis: loop yang mengiris string panjang per iterasi
menyalin per iterasi.

Tidak ada **slice assignment**. `s[0..1] = "HE"` tidak compile — `string` punya `[]` untuk slice tapi tidak punya
`[]=` untuk itu. Satu karakter adalah satu-satunya penulisan yang diizinkan operator index:

```
var buffer = "hello"
buffer[0] = 'H'
echo buffer             # Hello
```

## Membandingkan string

String dibandingkan menurut urutan leksikografis, dan semua operator pembanding tersedia
(`doc/language.md:286-287`):

```
echo "abc" == "abc"     # true
echo "abc" < "abd"      # true
echo "ABC" < "abc"      # true
```

Baris ketiga layak direnungkan: perbandingannya byte demi byte, dan di ASCII huruf besar urut sebelum huruf kecil
pasangannya. Jadi `"ABC" < "abc"` adalah `true`, dan kode "urutkan nama-nama ini" mewarisi urutan itu kecuali dia
menormalkan huruf dulu.

`case` juga boleh mencocokkan literal string langsung (`doc/language.md:288`, `:290-295`), yang membuat dispatch
perintah enak dibaca:

```
let command = "start"
case command
of "start": echo "starting"
of "stop": echo "stopping"
else: echo "unknown command: " & command
```

## Escape, raw string, triple quote

Di dalam literal string biasa, backslash memulai escape sequence:

| Sequence | Arti |
| --- | --- |
| `\n` | baris baru |
| `\t` | tab |
| `\\` | backslash literal |
| `\"` | tanda kutip ganda literal |
| `\x41` | byte dengan nilai hex itu (`A`) |

String mentah `r"..."` mematikan escape sepenuhnya, dan itulah yang kamu mau untuk path Windows atau regular
expression:

```
echo "a\tb"   # a, lalu tab, lalu b
echo r"a\tb"  # a\tb
```

String triple-quoted melintasi baris dan mempertahankan baris barunya sendiri:

```
let block = """
  first
  second
  """
```

Baris baru yang mengikuti `"""` pembuka dibuang; sisa indentasinya dipertahankan apa adanya.

## Karakter adalah byte

Panduannya tegas: string adalah UTF-8 **berdasarkan konvensi**, bukan penegakan, dan `s[i]` adalah `char` ke-i —
satu byte — bukan karakter unicode ke-i (`doc/language.md:297-300`).

```
let utf = "héllo"
echo utf.len          # 6
echo ord(utf[1])      # 195
```

Lima huruf, enam byte, dan index `1` adalah byte pertama dari `é` dua byte, bukan `é` itu sendiri. Tidak ada yang
salah dengan string-nya; kontrak indexing-nya memang soal byte.

Kalau kamu butuh karakter dan bukan byte, itu pekerjaan decoding, dan itu bukan tugas `[]`: `std/unicode`
menyediakan `iterator runes*(s: string): Rune` (`lib/std/unicode.nim:1467`) dan `runeLen`.

## Terminator yang tidak ada

Nim 2 menyimpan `'\0'` setelah karakter terakhir setiap string. Nimony membuangnya (`doc/differences.md:15-18`):
payload adalah payload, dan panjangnya tinggal di header string itu sendiri.

Kamu bisa melihat desainnya dari source, bukan dari cerita. Mengubah string jadi pointer C adalah `toCString`,
dan langkah pertamanya adalah **menulis** nol itu:

```
func ensureTerminatingZero*(s: var string) =
  ## Appends '\0' at position s.len then shrinks back, so the null sits just
  ## past the data without changing the logical length — same as terminatingZero
  ## but in-place.
  let oldLen = s.len
  s.add '\0'
  s.shrink oldLen

func toCString*(s: var string): cstring not nil =
  ## Returns a null-terminated cstring pointer.
  ensureTerminatingZero(s)
  result = cast[cstring not nil](rawData(s))
```
(`lib/std/system/stringimpl.nim:1095-1106`)

Kalau string sudah membawa terminator, fungsi itu tidak ada kerjaan. Ini juga menjelaskan signature-nya:
`toCString` menerima `var string`, karena dia mengubah buffer. `let` tidak bisa dikonversi:

```
let s = "hello"
let c = toCString(s)   # Error: cannot pass s to var/out T parameter
```

Menambah lalu menyusutkan lewat `add`, yang membuat storage-nya unik dulu — jadi kalau buffer string dibagi,
konversinya menyalin. Itu alasan lain kenapa konversi ini tidak gratis dan bukan sesuatu yang dilakukan di dalam
loop.

Setengah lainnya adalah aturan yang sama: `cstring(s)`, konversi langsung yang ditulis program Nim 2, ditolak
kecuali `s` adalah literal:

```
var s = "hello"
let c = cstring(s)     # Error: Only string literals can be converted to cstring.
                       #        Use `toCString` for safe conversion.
```
(`src/nimony/sem.nim:880`)

Literal bisa dikonversi karena compiler C menyimpan literal dengan byte nol miliknya sendiri. String runtime
tidak punya byte seperti itu sampai ada yang menulisnya.

## Di mana `cstring` masih muncul

`cstring` adalah tipe pointer yang kompatibel dengan C (`doc/language.md:306-314`). Di buku ini dia muncul di
batas C dan hampir tidak di tempat lain: Chapter 22 mengikat fungsi C, dan chapter itulah yang bersandar padanya.

Aturan yang kamu butuh sebelum itu:

- **Panjang.** `len` pada `cstring` memanggil `strlen` milik C (`lib/std/system/stringimpl.nim:377`, `:369-375`),
  jadi dia menghitung sampai byte nol pertama. Beda dengan `len` pada `string`, biayanya bergantung pada isi.
- **Jadi string.** `fromCString` menyalin byte-nya ke `string` baru (`lib/std/system/stringimpl.nim:1108-1109`).
  Ada juga `$`, tapi dia tinggal di `strutils` (`lib/std/strutils.nim:230`), bukan di `system` — tanpa
  `import std/strutils`, `$c` tidak compile.
- **Mencetak.** `echo` tidak punya overload `cstring`. `echo c` gagal bahkan dengan `strutils` diimpor; tulis
  `echo $c`.
- **`case`.** `cstring` bekerja di `case` seperti string (`doc/language.md:341`).
- **Indexing.** Panduannya menyatakan tidak ada pemeriksaan batas pada index `cstring` (`doc/language.md:312-314`).
  Perlakukan `c[3]` sebagai pembacaan tidak aman: tidak ada yang menghentikanmu berjalan melewati ujung.
- **Nil.** Tipenya muncul sebagai `cstring not nil` di pesan error. Nilability adalah subjek Chapter 13; untuk
  sekarang, catat saja bahwa `cstring` tidak nil secara default.

Arah yang paling penting praktis satu arah: kamu konversi di batas, panggil fungsi C, lalu kembali dengan
salinan. Jangan simpan `cstring` sebagai representasi kerja teksmu.

## Modul yang mengerjakan teks

`string` memberimu panjang, indexing, slicing, perbandingan, dan `&`. Sisanya — memecah, mencari, memangkas,
mengubah huruf — adalah `std/strutils`, dan semuanya jalan di pin:

```
import std/strutils

let parts = "alpha,beta,gamma".split(",")   # tiga string
echo parts[1]                               # beta
echo "alpha".find("pha")                    # 2
echo "alpha".find("zzz")                    # -1
echo "alpha".toUpperAscii()                 # ALPHA
echo "  pad  ".strip()                      # pad
echo "a-b-c".replace("-", "+")              # a+b+c
```

`find` mengembalikan `-1` ketika yang dicari tidak ada, bukan optional. `split` mengembalikan `seq[string]`, jadi
Chapter 10 adalah tempat indexing dan pembongkarannya dibahas penuh.

Perhatikan apa yang **tidak** ada di sini: `insert` dan `delete` tidak ada untuk `string` di pin (`insert` adalah
identifier yang tidak dideklarasikan, dan `delete` hanya ketemu overload `seq` lalu gagal dengan type mismatch),
dan `setLen` menumbuhkan atau menyusutkan string alih-alih menyambung di tengah. Bangun string yang kamu mau
dengan `&`, `add`, dan slicing, bukan dengan editor in-place.

## Nim 2 delta: tanpa null terminator

> **Apa yang dilakukan Nim 2.** Setiap string membawa `'\0'` tepat setelah karakter terakhirnya. `cstring(s)`
> hanyalah cast, dan `s[s.len]` membaca nol itu.
>
> **Apa yang dilakukan Nimony.** Payload-nya tidak punya terminator (`doc/differences.md:15-18`).
> `toCString(var string)` menulis satu saat dibutuhkan dan mungkin membuat buffer-nya unik dulu
> (`lib/std/system/stringimpl.nim:1095-1106`). `fromCString` menyalin balik (`:1108-1109`).
>
> **Apa yang rusak kalau kebiasaannya dibawa.** `cstring(s)` pada variabel tidak lagi compile — `Only string
> literals can be converted to cstring. Use `toCString` for safe conversion.` — dan `toCString` menolak `let`
> dengan `cannot pass s to var/out T parameter`, karena menulis terminator di tempat butuh string yang mutable.
> `s[s.len]` yang dipakai sebagai sentinel menghentikan program dengan `i < len(s) [AssertionDefect]` alih-alih
> membaca nol (dengan pemeriksaan runtime hidup: `-d:danger` mematikan pemeriksaan itu dan kamu membaca byte
> nyasar). Dan kode yang menyimpan `cstring` melewati perubahan string sumbernya salah dua kali: pointernya
> mungkin berasal dari salinan, dan nolnya hanya ditulis pada saat konversi.

## Sample

`samples/05-strings/strings.nim`, di-compile dan dijalankan di commit yang dipatok:

```
nimony c -r samples/05-strings/strings.nim
```

Keluaran yang diharapkan, berurutan:

```
6
N
78
y
Nim
strings and values
true
true
true
strings and values
strings and values!
a	b
a\tb
AB
z
n=42
6
195
Hello
clamped
3
beta
2
-1
7
cstring
cstring
cstring case
```

Baris `a` lalu tab lalu `b` adalah satu baris yang berisi tab. Angka `195` adalah byte pertama dari `é`, dan `7`
adalah `strlen` yang berhenti di nol yang ditulis `toCString`.

## Latihan

1. Cetak `len`, `[0]`, `[^1]`, dan `[0..2]` dari `"Nimony"`. Harapan: `6`, `N`, `y`, `Nim`.
2. Tulis `echo "n=" & 42`. Harapan: type mismatch yang menyebut `char` dan `int64`. Ganti ke `$42` dan harapkan
   `n=42`.
3. Deklarasikan `let s = "abc"` lalu panggil `s.add "d"`. Harapan: `cannot pass s to var/out T parameter`. Ganti
   `let` jadi `var` dan harapkan compile.
4. Deklarasikan `let s = "hello"` dan cetak `s[5]`. Harapan: compile, lalu berhenti saat runtime dengan
   `i < len(s) [AssertionDefect]`.
5. Cetak `"abc"[0..5]` dan `"abc"[2..1]`. Harapan: `abc`, lalu baris kosong. Slice menjepit; index tidak.
6. Cetak `len("héllo")` dan `ord("héllo"[1])`. Harapan: `6` dan `195`.
7. Tulis `echo cstring"hi"`. Harapan: tidak ada overload `cstring` di `echo`. Tambahkan `import std/strutils` dan
   tulis `echo $cstring"hi"`. Harapan: `hi`.
8. Deklarasikan `var s = "hello"`, konversi dengan `toCString`, lalu cetak `len` hasilnya. Harapan: `5`. Ganti
   `var` jadi `let` dan harapkan `cannot pass s to var/out T parameter`.

## Checklist chapter

draft 2026-11-12 · tech_review Momo 2026-11-12 · editorial_pass 2026-11-12 · frozen 2026-11-12
