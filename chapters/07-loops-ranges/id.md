---
chapter: 7
title: Loops and Ranges
job: Iterate ordinals with `for`, control repetition with `while` and `continue`, and prove a `range` only in the local form the compiler accepts.
nimony_version: 0.6.3
nimony_commit: 4ba90a781b0b22d0821efaa153c129c37cef6143
toolchain: ~/.local/opt/nimony/4ba90a7
host_compiler: ~/.local/opt/nim-2.4.0
status: frozen
tech_review: Momo 2026-11-12
editorial_pass: 2026-11-12
samples: ["samples/07-loops-ranges/loops.nim"]
glossary_added: ["for loop", "loop variable", "iterator", "countup", "countdown", "range proof"]
---

# Loop dan Range

## Untuk apa bab ini

Perulangan punya dua bentuk di sini. `for` menjalankan body sekali untuk tiap nilai yang dihasilkan iterator —
cara biasa untuk menyusuri rentang angka atau karakter. `while` menjalankan body selama kondisi terpenuhi, dan itu
yang kamu mau kalau jumlah putarannya belum diketahui di depan.

Paruh kedua bab ini soal `range`, tipe yang sudah diperkenalkan Bab 4. Loop adalah tempat range paling
sering muncul: batas index, batas loop, angka kecil yang dikirim ke routine yang cuma menerima digit. Di pin ini
compiler membela sebuah range dengan **bukti**, bukan dengan runtime check, dan bukti itu punya cakupan — harus
terlihat di tempat nilainya dipakai, dan tidak ikut nilainya masuk ke routine lain.

## `for` atas range

```
for i in 0..3:
  echo i
```

```
0
1
2
3
```

`0..3` itu iterator, bukan container (`lib/std/system/iterators.nim:14-44`). Dia menghitung naik dan ikut
menyertakan kedua ujung. Loop mendeklarasikan variabelnya sendiri, tipenya adalah tipe yang dihasilkan iterator
(`int` di sini), dan cakupannya berakhir bersama body (`doc/language.md:4041-4056`). Memakai `i` setelah loop
adalah error: `undeclared identifier: i`.

Batasnya tidak harus literal:

```
let n = 3
for i in 0..n:
  echo i
```

Pasangan menurun jadi kosong, bukan dibalik, karena `..` hanya menghitung naik (`iterators.nim:14-44`):

```
var seen = 0
for i in 3..0:
  seen = seen + 1
echo seen
```

```
0
```

Body-nya tidak pernah jalan. Turun butuh iterator di bagian dua setelah ini.

Satu batas atas ditolak saat compile. `for i in 0..high(int)` tidak mau dibangun:

```
Error: contract violated: b < 9223372036854775807'i64 or sizeof(int64) == 1 and …
```

Elipsis itu tidak menyembunyikan aturan kedua: baris lengkapnya mengulang batas yang sama untuk kasus `sizeof`
lainnya, dan berakhir dengan `[pass --verbose for the Final IR]`.

Alasannya ada di komentar iterator itu sendiri (`iterators.nim:15-32`): loop selesai dengan menaikkan nilai
melewati `b`, dan di `high(T)` nilai seperti itu tidak ada — `inc` wrap, dan loop-nya tidak akan pernah berhenti.
Jadi iterator inklusif butuh batas di bawah `high(T)`, atau tipe yang masih punya bit sisa.

Range yang disimpan di variabel bukan batas loop:

```
let r = 0..3
for i in r:
  echo i
```

```
Error: Type mismatch at [position]
items(r)
[1] expected: typedesc[T] but got: HSlice[int64,int64] …
```

Di statement `for`, `a..b` diselesaikan sebagai iterator. `let r = 0..3` malah membangun nilai slice
(`lib/std/system.nim:610-616`), dan tidak ada overload `items` yang menerimanya. Tulis batasnya langsung di loop.

## Bentuk setengah terbuka: `..<`

```
for i in 0..<3:
  echo i
```

```
0
1
2
```

`a..<b` adalah rentang yang sama dengan batas atas tidak ikut; sebagai nilai dia `a..pred(b)`
(`system.nim:610-616`), dan sebagai loop dia menghitung naik lalu berhenti sebelum `b` (`iterators.nim:1-12`).
Batas yang sama besarnya menghasilkan kosong: `for i in 3..<3` tidak pernah jalan.

Bentuk ini berguna saat berhadapan dengan panjang:

```
let word = "abc"
for i in 0..<len(word):
  echo i, " ", word[i]
```

```
0 a
1 b
2 c
```

Compiler menerima `word[i]` karena iterator mendeklarasikan `ensures: (a <= result and result < b)`
(`iterators.nim:1-12`). Klausa itulah yang membuat rentang variabel loop bisa dibuktikan di index, dan komentar di
atas iterator mengatakannya terang-terangan: iterator inline baru di-inline jauh setelah analisis contract, jadi
rentangnya harus dinyatakan, bukan diturunkan.

Versi inklusifnya lolos compile lalu mati:

```
for i in 0..len(word):
  echo word[i]
```

```
…/stringimpl.nim(686, 37): i < len(s) [AssertionDefect]
```

Rentang loop-nya menjanjikan `i <= len(word)`, satu nilai lebih banyak dari yang diizinkan index, jadi assertion
di `[]` (`lib/std/system/stringimpl.nim:686`) menghentikan program di `i == len(word)`. Setengah terbuka bukan
selera gaya di pola ini; dia yang membedakan bisa dibuktikan dengan crash.

## Menghitung turun, dan step

Tiga cara turun di pin ini:

```
for i in countdown(3, 1):
  echo i          # 3 2 1
```

```
for i in 3 >.. 0:
  echo i          # 3 2 1
```

`countdown` menghitung dari `a` turun ke `b`, keduanya ikut (`iterators.nim:59-74`). Iterator `>..` adalah
saudara menurun dari `..`, ditulis dengan nilai lebih besar di kiri (`iterators.nim:46-53`).

`countup` menerima step, begitu juga `countdown`:

```
for i in countup(0, 6, 2):
  echo i          # 0 2 4 6

for i in countdown(5, 1, 2):
  echo i          # 5 3 1
```

`countup` menerima `step: Positive` (`iterators.nim:76`), jadi step negatif tidak compile: `countup(0, 6, -2)`
gagal dengan `value out of range: -2 notin 1..9223372036854775807`. `countdown` menerima step ordinal biasa
(`V: Ordinal`, `:59`); hanya komentarnya yang bilang step-nya positif (`:64`), dan step negatif tetap compile lalu
memanjat menjauh dari `b` alih-alih turun — `countdown(5, 1, -1)` mencetak `5 6 7 8 …` dan tidak pernah berhenti.
`countup` juga membawa syarat `b < high(T)` yang dimiliki `..` (`:77-82`); `countdown` tidak punya `requires`
seperti itu, cuma catatan bahwa dia gagal kalau `a >= b and b + step > high(T)` (`:66-67`).

## `char` juga ordinal

`char` punya urutan, jadi iterator yang sama berlaku:

```
for c in 'a'..'c':
  echo c
```

```
a
b
c
```

`ord(c)` di loop yang sama mencetak `97`, `98`, `99`, karena `char` adalah integer kecil dengan wajah yang bisa
dicetak. Turun butuh bantuan yang sama seperti `int`: `countdown('c', 'a')` dan `'c' >.. 'a'` sama-sama mencetak
`c`, `b`, `a`, sedangkan `'c'..'a'` kosong.

## Variabel loop adalah variabel

Cakupannya berakhir bersama body, tapi di pin ini dia bukan read-only. Menulisnya menggeser loop:

```
for i in 0..5:
  if i == 1:
    i = 3
  echo i
```

```
0
3
4
5
```

Penulisan itu menyetel counter ke `3`, dan putaran berikutnya lanjut dari `4`. Menulis melewati batas malah
mengakhiri loop: `for i in 0..2: i = 5; echo i` mencetak `5` sekali lalu berhenti.

Aturan buku ini: baca variabel loop, jangan tulis. Tidak ada sample di sini yang menulisnya, dan tidak ada bab
berikutnya yang bergantung padanya — perilakunya dicatat di `ERRATA.md` sebagai observasi pin, bukan diajarkan
sebagai teknik.

## `continue`

`continue` melompat ke iterasi berikutnya dari loop yang membungkusnya (`doc/language.md:2010-2015`):

```
for i in 0..5:
  if i mod 2 == 0:
    continue
  echo i
```

```
1
3
5
```

Dia tetap menyasar loop walaupun dipanggil dari dalam `block` telanjang:

```
for i in 0..2:
  block:
    let x = i
    if x == 1:
      continue
    echo x
```

```
0
2
```

Itu aturan yang sama dengan `break` di Bab 6: loop terdalam, bukan block. Dua keyword itu beda di arah
tujuannya — `continue` ke putaran berikutnya, `break` keluar dari loop — bukan di apa yang mereka anggap konstruk
pembungkusnya.

## `while`

`while` menguji dulu, jadi body-nya boleh tidak pernah jalan:

```
while false:
  echo "never"
echo "after"
```

```
after
```

Loop tanpa akhir bukan error di pin ini (`doc/language.md:1992-2006`). Jalan keluarnya `break`, dan itu bekerja
karena `while` membuka block implisit. `continue` menguji ulang kondisinya, bukan melewatinya:

```
var i = 0
while i < 5:
  i = i + 1
  if i == 3:
    continue
  echo i
```

```
1
2
4
5
```

Increment-nya duduk sebelum `continue`; pindahkan ke belakang dan loop berhenti bergerak. Itu satu-satunya
kesalahan `while` yang layak disebut, karena compiler tidak akan menyebutkannya untukmu.

## Parameter `range`: buktinya lokal

Bab 4 sudah menunjukkan tipe dan konversinya. Dalam praktik range biasanya ditemui di batas — routine yang
hanya menerima digit:

```
proc clamped(x: range[0..9]) =
  echo "digit ", x

proc showDigit(n: int) =
  if n >= 0 and n <= 9:
    clamped(n)
  else:
    echo "not a digit"
```

Itu compile dan mencetak `digit 7` untuk `showDigit(7)`. Hapus `if`-nya dan panggilannya ditolak:

```
Error: cannot prove 'n' is in range 0..9
```

(`src/nimony/contracts_fir.nim:2386-2387`.) Tidak ada runtime check yang dihasilkan, ke dua arah
(`doc/differences.md:58-62`): nilai yang sampai ke parameter `range` entah dibuktikan sebelum panggilan, atau
programnya tidak dibangun.

Empat detail menentukan apakah buktinya diterima.

1. **Bukti harus terlihat di tempat nilainya dipakai.** Pemanggil yang menjaga `n`, lalu memanggil routine yang
   memanggil `clamped` tanpa menjaga lagi, gagal di panggilan dalam itu. Buktinya tidak ikut berpindah.
2. **Dua perbandingan bekerja di mana saja**, termasuk pada parameter: `n >= 0 and n <= 9`, atau
   `0 <= n and n <= 9`.
3. **`n in 0..9` bukan bukti yang sama.** Bentuk itu diterima untuk `var` lokal atau `var` tingkat modul, tapi
   tidak untuk parameter prosedur, di mana panggilan yang sama tetap gagal dengan
   `cannot prove 'n' is in range 0..9`. Contoh di guide ditulis dengan `in` (`doc/differences.md:64-65`); pada
   parameter, tulis perbandingannya.
4. **Nilai hasil hitungan butuh bukti yang mencakup hitungannya.** Engine mengikuti offset konstan: dengan
   penjagaan `n >= 0 and n <= 9`, `clamped(n + 0)` lolos, dan `clamped(n + 1)` gagal dengan
   `cannot prove 'n' stays in range 0..9` karena penjagaan itu menjanjikan `n <= 9`, bukan `n <= 8`. Sempitkan
   penjagaannya ke `n <= 8` dan `n + 1` lolos. Verb-nya berubah dari "is" ke "stays"; kewajibannya tidak.

Assignment ke variabel range adalah konversi, jadi aturan yang sama berlaku dari sisi lain. Literal di luar batas
ditolak saat deklarasi (`value out of range: 7 notin 0..4`, `doc/differences.md:63-64`), dan nilai bertipe lain
ditolak dengan pesan bukti:

```
var r: range[0..4] = 3
var n = 7
r = n
# Error: cannot prove 'n' is in range 0..4
```

Jadi aturan buku ini: taruh penjagaannya di routine yang butuh range itu, tulis sebagai dua perbandingan, dan
buktikan ulang nilai hasil hitungan terhadap batas yang benar-benar dijanjikan penjagaannya.

## Nim 2 delta: bukti range bersifat lokal

> **Apa yang dilakukan Nim 2.** Sebuah `range` dibela saat runtime ketika nilainya mencapai tipe, jadi nilai yang
> benar pada saat dipakai diterima sejauh apa pun dia sudah berjalan untuk sampai ke sana. Dicek di host
> compiler, Nim 2.4.0: mengisikan `7` ke `var r: range[0..4]` berhenti dengan `RangeDefect`, begitu juga `70`
> yang dikirim ke parameter `range[0..9]`.
>
> **Apa yang dilakukan Nimony.** Kewajiban `lo <= value <= hi` pergi ke contracts engine saat compile time dan
> tidak ada runtime check yang dihasilkan (`doc/differences.md:58-62`). Apa pun yang tidak bisa dibuktikan engine
> adalah compile error, walaupun nilainya masuk akal saat program jalan.
>
> **Apa yang patah kalau kebiasaan lama dibawa.** Pola "validasi sekali, terus teruskan" berhenti compile:
> penjagaannya harus terlihat di routine tempat tipe range dibutuhkan. Penjagaan yang ditulis `x in a..b` pada
> parameter tidak dihitung, jadi baris yang tadinya terbaca sebagai pengecekan sekarang gagal dibangun. Dan
> hitungan yang dibangun dari nilai terjaga bisa melewati penjagaannya: dengan penjagaan `n <= 9`, `n + 1` butuh
> `n <= 8`, jadi buktinya harus mencakup hasilnya, bukan cuma nilainya.

## Samples

`samples/07-loops-ranges/loops.nim` — setiap konstruksi di bab ini, berurutan, di commit yang dipatok:

```
$ nimony c -r samples/07-loops-ranges/loops.nim
incl 0
incl 1
incl 2
incl 3
half 0
half 1
half 2
descending count 0
down 3
down 2
down 1
step 0
step 2
step 4
step 6
char a
char b
char c
index 0 a
index 1 b
index 2 c
odd 1
odd 3
odd 5
while 0
while 1
while 2
total 10
digit 7
not a digit
```

`descending count 0` adalah inti `3..0`: loop-nya jalan nol kali. `total 10` adalah `1 + 2 + 3 + 4` yang
diakumulasi `var` di luar loop. Dua baris terakhir adalah parameter range yang menerima `7` lewat penjagaan
perbandingan dan menolak `70` di `else`.

## Cek

1. Tulis `for i in 0..3: echo i`. Harapan: `0 1 2 3`, empat baris. Ubah ke `0..<3`. Harapan: tiga baris.
2. Hitung putaran `for i in 3..0`. Harapan: `0`. Ganti header-nya dengan `countdown(3, 1)`. Harapan: `3 2 1`.
   Coba `3 >.. 0`. Harapan: sama.
3. Tulis `for i in countup(0, 6, 2)`. Harapan: `0 2 4 6`. Coba `countdown(5, 1, 2)`. Harapan: `5 3 1`. Coba
   `countup(0, 6, -2)`. Harapan: `value out of range: -2 notin 1..9223372036854775807`.
4. Tulis `for c in 'a'..'c': echo c`. Harapan: `a b c`. Ganti header-nya ke `'c'..'a'`. Harapan: kosong.
5. Tulis `for i in 0..len("abc"): echo "abc"[i]`. Harapan: dia compile, mencetak `a`, `b`, `c`, lalu berhenti
   dengan `i < len(s) [AssertionDefect]`, exit 1. Ganti header ke `0..<len("abc")`. Harapan: tiga baris, exit 0.
6. Tulis `for i in 0..high(int): echo i`. Harapan: `contract violated:` dengan syarat `b < …`. Ganti batasnya ke
   `high(int) - 1`. Harapan: compile dan jalan (jangan dijalankan sampai habis).
7. Tulis contoh variabel loop dari bab ini. Harapan: `0 3 4 5`. Pindahkan penulisannya melewati batas
   (`for i in 0..2: i = 5; echo i`). Harapan: `5` sekali.
8. Tulis contoh `continue`. Harapan: `1 3 5`. Taruh di dalam `block` telanjang. Harapan: `0 2`.
9. Tulis contoh `while` + `continue`. Harapan: `1 2 4 5`. Pindahkan increment-nya setelah `continue`. Harapan:
   loop berhenti bergerak.
10. Tulis contoh range dua proc. Harapan: `digit 7` dan `not a digit`. Hapus penjagaannya. Harapan:
    `cannot prove 'n' is in range 0..9`. Ganti `n >= 0 and n <= 9` dengan `n in 0..9`. Harapan: error yang sama.
    Ganti panggilannya jadi `clamped(n + 1)`. Harapan: `cannot prove 'n' stays in range 0..9`. Ganti jadi
    `clamped(n + 0)`. Harapan: compile — offset nol bukan hitungan.

## Checklist chapter

draft 2026-11-12 · tech_review Momo 2026-11-12 · editorial_pass 2026-11-12 · frozen 2026-11-12
