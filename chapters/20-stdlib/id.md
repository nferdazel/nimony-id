---
chapter: 20
title: The Standard Library You Can Rely On
job: Tour only the modules proven at the pin (`syncio`, `strutils`, sequence helpers from `system` and `sequtils`, `tables`, `sets`, `atomics`) and state the rule for using any other.
nimony_version: 0.6.3
nimony_commit: 4ba90a781b0b22d0821efaa153c129c37cef6143
toolchain: ~/.local/opt/nimony/4ba90a7
host_compiler: ~/.local/opt/nim-2.4.0
status: frozen
tech_review: Momo 2026-11-13
editorial_pass: 2026-11-13
samples: [samples/20-stdlib/stdlib.nim]
glossary_added: [proven module, Table, Keyable, HashSet, sequtils, atomic operation, MemoryOrder]
---

# Standard Library yang Bisa Kamu Andalkan

## Untuk apa bab ini

Sebuah bahasa hanya seberguna kode yang tidak perlu kamu tulis sendiri. Bab ini menyusuri bagian standard
library yang terbukti jalan di commit yang dipin, dan memberimu tes yang menentukan apakah modul di luar
tur itu pantas masuk program kamu. Daftarnya pendek dengan sengaja. Sebuah modul layak diandalkan ketika
programnya jalan, bukan ketika filenya ada, dan bukan ketika dokumentasi Nim 2 masih mengingatnya.

## Aturannya: kehadiran, bukan reputasi

Tiga fakta kelihatan seperti izin, padahal bukan.

File bernama `lib/std/<name>.nim` di checkout pin memberitahumu bahwa modul itu dimaksudkan ada. Itu tidak
memberitahumu bahwa fungsi yang kamu mau diekspor dari sana, dan tidak memberitahumu bahwa modulnya
terkompilasi. `import std / <name>` yang berhasil memberitahumu sedikit lebih banyak: filenya ketemu dan
level atasnya ter-parse. Itu tidak memberitahumu bahwa bagian yang kamu butuhkan jalan. Hanya run yang
memberi tahu.

Tesnya dua baris dan satu perintah:

```nim
import std / [syncio, deques]

var q = initDeque[int]()
q.addLast(1)
echo q.len
```

Itu mencetak `1` di pin, jadi `std/deques` terpakai, dan kamu boleh lanjut. Ganti modul dan panggilannya dengan
yang kamu butuhkan. Kalau import-nya ditolak, modulnya tidak ada. Kalau aksinya gagal, modulnya ada dan tidak
terpakai untuk keperluan kamu.

Mode kegagalannya layak dikenali dari pesannya. Modul yang hilang ditolak di import dengan `file not found`
sambil menyebut path yang dicoba compiler: `std/strformat`, `std/re`, `std/seqs` dan `std/cookies` semuanya
gagal begitu di pin. Dua yang pertama adalah modul Nim 2 biasa — compiler host mencetak `a2` untuk
`fmt"a{1 + 1}"` dan `true` untuk satu pencocokan regex, jadi dokumentasi yang kamu ingat memang benar untuk Nim
2 — dan dua yang terakhir adalah nama yang tidak pernah jadi modul: Nim 2.4.0 pun menolak `std/seqs`, dengan
`cannot open file: std/seqs`. Modul yang ada tapi tidak mengekspor yang kamu mau gagal belakangan, di
panggilannya. Dua-duanya pesan yang menjawab.

Tur di bab ini bukan pengganti tes itu. Ia catatan bahwa tesnya sudah dijalankan, di commit ini, untuk
lima modul dan untuk helper collection yang menyertainya.

Pin juga membawa guide standard library sendiri, `doc/stdlib.md`, dengan bagian untuk `system`, `syncio`,
`strutils`, `unicode`, `hashes`, `tables`, `sets`, `paths`, `dirs`, `envvars`, `appdirs`, `memfiles`,
`encodings`, `wordwrap`, `logging`, `rawthreads`, `stacktraces`, `streamio`, `channels`, `tls` dan
modul-modul HTTP (`doc/stdlib.md:11-687`). Baca untuk signature dan untuk desain di balik sebuah modul.
Jangan baca sebagai bukti bahwa sebuah panggilan jalan: itu referensi, dan daftar di bab ini yang sudah
diperiksa terhadap referensi itu.

## `std/syncio`: `echo` dan overload-nya

Setiap contoh di buku ini dimulai dengan `import std / syncio`, dan `echo` sebabnya. Di pin `echo` adalah
template `varargs` (`lib/std/syncio.nim:465-469`) yang meneruskan tiap argumen ke overload `write`, dan
kumpulan overload-nya (`lib/std/syncio.nim:293-331`): `string`, `bool`, `int64`, `int32`, `uint64`, `uint32`,
sembarang tipe enum, `char`, dan `float`.

Sembilan itu kumpulan default, bukan daftar tertutup. `seq` tidak ada di dalamnya, begitu juga object
bikinan kamu sendiri, jadi `echo @[1, 2]` dan `echo p` sama-sama error, dan pesannya adalah seluruh kumpulan
overload yang dicetak balik ke kamu dengan tipe kamu setelah `expected:` (`lib/std/syncio.nim:468`). Tidak ada
konversi `$` yang dilihat; Bab 11 sudah bilang `$` bikinan sendiri tidak menolong. Yang ditambahkan
bab ini separuhnya lagi: overload `write` yang kamu deklarasikan sendiri tetap ketemu di call site, jadi
`proc write(f: File; p: P)` membuat `echo p` mencetak teks kamu, dan sembilan yang kamu terima di pesan error
adalah default modulnya, bukan satu-satunya kemungkinan. Cetak collection elemen per elemen, atau bangun
string lalu cetak itu.

Sisa modulnya sama literalnya. `write` menulis tanpa newline, `writeLine` menulis string plus newline, dan
`quit` menghentikan program dan tidak kembali (`lib/std/syncio.nim:538`). Membaca punya dua bentuk:
`readLine(f, s: var string): bool` mengembalikan apakah ada baris yang terbaca (`lib/std/syncio.nim:506`),
sedangkan `readLine(f): string` ditandai `{.raises.}` (`lib/std/syncio.nim:511`) karena stream-nya bisa
gagal. Sisi file dari modul ini, termasuk `readFile` dan `writeFile`, adalah bahan Bab 21.

## `std/strutils`: helper, dan yang bisa gagal

`std/strutils` berfokus ASCII menurut deskripsinya sendiri, dan sebagian besarnya total: diberi string, ia
mengembalikan string, angka, atau nilai kebenaran, dan tidak bisa gagal. `split`, `strip`, `join`, `repeat`,
`startsWith`, `endsWith`, `contains`, `replace`, `find`, `toUpperAscii` dan `toLowerAscii` semuanya punya
bentuk itu. Signature-nya layak dibaca sekali:

- `split(s, seps: set[char] = Whitespace, maxsplit = -1)` memecah pada sembarang karakter di sebuah set
  secara default, jadi `"a b".split` dan `"a,b".split(",")` adalah fungsi yang sama dengan pemisah berbeda
  (`lib/std/strutils.nim:405`, `:409`, `:413`).
- `strip(s, leading = true, trailing = true, chars: set[char] = Whitespace)` memangkas whitespace kecuali kamu
  menyebut karakternya (`lib/std/strutils.nim:1593`).
- `join(a: openArray[string], sep = "")` menerima sembarang sequence string, bukan cuma literal sequence
  (`lib/std/strutils.nim:489`).

Tiga nama tidak total, dan compiler bilang begitu sebelum kamu menjalankan apa pun. `parseInt(s): int` ditandai
`{.raises.}` (`lib/std/strutils.nim:1733`), begitu juga operator format `%` (`lib/std/strutils.nim:1474`) dan
`format` (`lib/std/strutils.nim:1588`). Memanggil salah satunya di luar blok `try` ditolak saat compile
dengan `cannot call a routine marked as `.raises` outside of a `try`..`except` block`, aturan yang sama yang
Bab 15 ajarkan untuk routine bikinan kamu sendiri. Tangkap `ErrorCode`, karena hanya itu yang dilempar:

```nim
proc number(s: string): int =
  try:
    result = parseInt(s)
  except ErrorCode as e:
    echo "not a number: ", s
    result = -1
```

`number("42")` mencetak `42` dari `echo` si pemanggil, dan `number("4x")` mencetak `not a number: 4x` lalu
mengembalikan `-1`. Operator `%` berperilaku sama: `"$1 and $2" % [a, b]` adalah compile error di luar
`try`, dan di dalamnya menghasilkan `tea and tea` untuk dua argumen yang identik.

`ErrorCode` tidak perlu import. Ia enum yang di-include ke `system` dari sebuah fragmen
(`lib/std/system.nim:256`), dan `KeyError` salah satu anggotanya (`lib/std/errorcodes/errorcodes.nim:18`).
Tidak ada modul `std/errorcodes` untuk di-import: `import std / errorcodes` gagal dengan `file not found`,
dan kegagalan itu bukan tanda enum-nya tidak tersedia.

## Sequence tanpa modul `seqs`

Programmer Nim 2 meraih modul `seqs`. Modul itu tidak ada di pin, dan tidak ada juga di Nim 2.4.0: helper
sequence-nya justru terbagi di dua tempat.

Dasar-dasarnya ada di `system`, yang tidak pernah kamu import. `add(s, elem)` menambahkan
(`lib/std/system/seqimpl.nim:213`), `setLen(s, newLen)` mengubah ukuran dan menuntut tipe elemen yang punya
nilai default (`lib/std/system/seqimpl.nim:337`), dan `delete(s, idx)` membuang satu elemen
(`lib/std/system/seqimpl.nim:370`). `pop(s)` juga di sana (`lib/std/system/seqimpl.nim:363`). Tiga nama itu
yang dibutuhkan program pertama, bukan seluruh permukaan `system`, dan itulah sebabnya program semacam itu
bisa ditulis tanpa satu pun import library.

Sebagian besar sisanya di `std/sequtils`: `map`, `filter`, `keepIf`, `apply`, `all`, `any`, `count`,
`deduplicate`, `minIndex`, `maxIndex`, `cycle`, `zip`, `unzip`, `minmax`, dan dua yang mengagetkan karena
tidak ada di `system` — `delete(s, first, last)` untuk rentang (`lib/std/sequtils.nim:189`) dan
`insert(dest, src, pos = 0)` untuk sequence (`lib/std/sequtils.nim:210`).

Satu operator lebih sempit daripada yang Nim 2 sarankan. `&` didefinisikan untuk `string` dan kombinasi
`string` dengan `char` (`lib/std/system/stringimpl.nim:1034`, `:1062`, `:1063`) dan tidak untuk yang lain,
jadi `xs & ys` pada dua sequence adalah type mismatch yang daftar kandidatnya berisi semua overload string.
Padanan sequence-nya `concat(a, b)` dari `sequtils` (`lib/std/sequtils.nim:27`), dan itu panggilan biasa,
bukan operator.

`map` dan `filter` menerima nilai routine, bukan argumen sintaks, jadi tipe elemen dan hasilnya ditulis di
signature routine yang kamu lewatkan:

```nim
let doubled = @[1, 2, 3].map(proc (n: int): int = n * 2)
let even = @[1, 2, 3, 4].filter(proc (n: int): bool = n mod 2 == 0)
```

Dua-duanya jalan: `doubled[2]` adalah `6`, dan `even.len` adalah `2`. `mapIt` dan `it` juga ada dan lebih
pendek, dan pilihan di antara keduanya soal gaya, bukan kemampuan.

## `std/tables`: key, lookup, dan ketiadaan

Sebuah `Table[K, V]` adalah hash map dengan satu aturan yang membentuk setiap baris yang kamu tulis: membaca
key yang tidak ada melempar, menulis tidak pernah gagal.

- `initTable[K, V]()` membuat tabel kosong (`lib/std/tables.nim:243`).
- `t[k] = v` menyimpan dan menimpa (`lib/std/tables.nim:158`), tanpa `{.raises.}`.
- `t[k]` membaca dan ditandai `{.raises.}`; saat key-nya tidak ada ia melempar `KeyError`
  (`lib/std/tables.nim:110-114`).
- `hasKey(t, k)` dan `contains(t, k)` menjawab tanpa melempar (`lib/std/tables.nim:78`, `:82`).
- `getOrDefault(t, k, fallback)` menjawab dengan nilai cadangan kamu (`lib/std/tables.nim:93`); bentuk satu
  argumennya menuntut tipe nilai yang punya default (`lib/std/tables.nim:86`).
- `getOrQuit(t, k)` mengakhiri program kalau key-nya hilang, setelah sebuah `assert`
  (`lib/std/tables.nim:101-107`). Itu fungsi yang tepat untuk key yang tanpanya program kamu tidak bisa
  lanjut, dan yang salah di semua tempat lain.

Karena satu pembacaan bisa melempar, membaca tabel di dalam routine yang tidak menangkap adalah compile
error, bukan kejutan saat runtime. Itu aturan yang sama dengan `parseInt`, dan perbaikannya sama bentuknya:
tangkap `ErrorCode`, atau tanya `hasKey` dulu, atau pakai `getOrDefault`. Sample bab ini memakai
ketiganya, dan itu gambaran yang jujur untuk kode tabel biasa di pin.

Iterasi memberimu `pairs`, `keys`, `values`, `mpairs` dan `mvalues` (`lib/std/tables.nim:189-209`). Di pin,
urutan yang mereka jalani adalah urutan penyisipan: tabelnya menyimpan pasangan di sebuah sequence, `pairs`
menjalani sequence itu (`lib/std/tables.nim:189-192`), dan `del` mempertahankan urutan dengan menggeser
entri (`:211-213`). Sumbernya bilang begitu di komentar pada tabel berurut (`:252`), dan `initOrderedTable`
(`:258`) didefinisikan sebagai `initTable` dengan body inline justru karena tabel biasa sudah berurut.
Guide-nya tidak menjanjikan urutan itu, dan penjumlahan atau pengurutan tidak bergantung padanya, jadi
akumulasikan jumlah, urutkan key sendiri, atau cetak satu key yang kamu cari daripada membandingkan tabel yang
dicetak.

Key harus memenuhi `Keyable`, yang dideklarasikan file yang sama sebagai `concept of Hashable` plus sebuah
`==` atas dua `Self` (`lib/std/tables.nim:6-7`), dengan `Hashable` dideklarasikan di `std/hashes`
(`lib/std/hashes.nim:13`). `string`, `int` dan tuple adalah key yang jelas. `seq[int]` juga key legal di
pin — `t[@[1, 2]] = "pair"` menyimpan dan tabelnya melaporkan panjang `1` — karena sequence punya `hash` dan
`==`. Itu layak diketahui sebelum kamu menyerialkan key gabungan jadi string.

## `std/sets`: nilai, bukan bitset

Sebuah `HashSet[T]` membungkus `Table[T, bool]` (`lib/std/sets.nim:5-6`), jadi semua yang dikatakan bagian
sebelumnya soal key berlaku apa adanya: `Hashable` syaratnya (`lib/std/sets.nim:5-8`), sequence elemen yang
legal, dan `HashSet[int]` tetap bukan `Table[int, bool]`.

Permukaannya kecil. `initHashSet[T]()` (`lib/std/sets.nim:8`), `incl` dan `excl` (`:12`, `:16`), `contains`
(`:24`), `len` (`:46`), `clear` (`:20`), `intersection` (`:61`), dan dua yang menjawab pertanyaan sambil
bekerja: `containsOrIncl` mengembalikan true kalau elemennya sudah ada dan menyisipkannya kalau belum
(`lib/std/sets.nim:28`), dan `missingOrExcl` mengembalikan true kalau elemennya hilang dan membuangnya kalau
ada (`lib/std/sets.nim:34`). Di sample, `containsOrIncl("milk")` mencetak `true` dan
`containsOrIncl("sugar")` mencetak `false` sambil menambah elemen. Menyisipkan duplikat tidak mengubah apa
pun, jadi `incl("hot")` dua kali menyisakan panjang `1`.

Jangan tertukar dengan `set[char]`, yang bitset atas rentang karakter dan milik `system`. Pakai `set[char]`
ketika domainnya kelas karakter — itu yang diterima `strutils` untuk `split` dan `strip` — dan `HashSet`
ketika elemennya nilai dari tipe yang bisa di-hash.

## `std/atomics`: operasi, bukan tipe

Ini satu-satunya modul di tur di mana kebiasaan Nim 2 harus dilepas, bukan disesuaikan. Nimony tidak punya
wrapper `Atomic[T]`. Header modulnya menyatakan desainnya dalam satu baris, "Atomics are operations, not type
properties" (`lib/std/atomics.nim:1-4`), dan kodenya cocok: kamu deklarasikan `var` biasa lalu panggil
`atomicLoad`, `atomicStore`, `atomicFetchAdd`, `atomicExchange`, `atomicCompareExchange` dan kerabatnya di
situ.

```nim
var hits = 0
discard atomicFetchAdd(hits, 1)
discard atomicFetchAdd(hits, 1)
echo atomicLoad(hits)      # 2
atomicStore(hits, 10)
echo atomicLoad(hits)      # 10
```

Setiap operasi menerima memory order dan default-nya `moSequentiallyConsistent` (`lib/std/atomics.nim:49-52`),
yang paling ketat, jadi default-nya adalah default yang aman dan order adalah optimasi yang kamu tambahkan
ketika kamu bisa menyebut apa yang sedang kamu urutkan. Enam order-nya adalah order C yang biasa
(`lib/std/atomics.nim:6-12`).

Ketakterbagiannya bukan sifat variabelnya. Tiap operasi di-lower ke builtin `__atomic_*` milik compiler C
dengan nama yang sama (`src/lengc/typenav.nim:87-100`), dan C yang dihasilkan tidak mendeklarasikan tipe
`_Atomic` (`lib/std/atomics.nim:2-3`): jaminannya datang dari builtin di panggilannya, dan itulah sebabnya
`var` biasa cukup.

Constraint-nya `Trivial`: integer, `bool`, enum, `ptr`, `pointer` (`lib/std/atomics.nim:14`). `string`
ditolak di panggilan dengan `string does not match constraint T`, sambil menyebut modul asal constraint-nya —
satu tempat lagi di mana pesannya memberi tahu aturannya. `AtomicFlag` ada sebagai `bool` tersendiri
(`lib/std/atomics.nim:16`) untuk kasus berbentuk flag.

Yang tidak diajarkan bab ini adalah thread kedua. Atomics soal operasinya yang tak terbagi, dan program
single-thread bisa memanggilnya dan melihat aritmetikanya. Bab 24 tempat sisi lain pertanyaan itu
tinggal.

## Modul lain mana pun

Untuk modul di luar tur, jalankan tes dua baris dan catat yang kamu lihat. Hasilnya punya tiga bentuk, dan
masing-masing memutuskan hal berbeda.

Modulnya tidak ada. `std/strformat` dan `std/re` gagal begitu di pin, dan `std/seqs` juga. Kalau kamu sedang
meraih `fmt"..."`, pakai `%` atau `&` dari `strutils`; kalau kamu meraih regex, `std/rex` bisa di-import dan
itu modul regex milik pin, belum terbukti di sini.

Modulnya ada dan panggilannya tidak. `std/json` bisa di-import dan `parseJson` menerima string, tapi
`node["a"]` ditolak dengan `JsonTree does not match constraint T` plus daftar kandidat penuh, karena `[]`
bukan accessor untuk pohon yang sudah di-parse. Jalur bacanya `node{"a"}`, yang memberimu `JsonNode`, lalu
`getInt`, `getStr` atau `kind` pada itu (`lib/std/json.nim:551`, `:383`, `:418-424`). Guide pin tidak punya
bagian `json` sama sekali (`doc/stdlib.md:11-687`), jadi pembaca yang mencarinya tidak menemukan apa pun,
dan bentuknya harus dipelajari dari satu run.

Modulnya ada dan panggilannya jalan. `std/deques`, `std/heapqueue`, `std/intsets`, `std/algorithm`,
`std/math`, `std/hashes`, `std/random`, `std/times` dan `std/streams` masing-masing lolos satu import dan
sedikitnya satu aksi di pin. Lolos tes adalah izin untuk panggilan yang benar-benar kamu jalankan, bukan untuk
seluruh dokumentasi modulnya, dan putaran yang sama membawa dua peringatan. `std/strtabs` bisa di-import lalu
menolak `newStringTable()` dengan `too few arguments`, karena satu-satunya konstruktor tanpa pasangan
menerima mode (`lib/std/strtabs.nim:251`). Dan `std/logging`, yang didokumentasikan penuh oleh guide pin
(`doc/stdlib.md:451-475`), terkompilasi, menjalankan `info("started")` dan mencetak kosong sama sekali: `info`
adalah template yang menulis ke handler terdaftar (`lib/std/logging.nim:404-409`), dan mengimpor modulnya
tidak mendaftarkan satu pun, jadi panggilannya sunyi sampai kamu menambahkannya.

Aturan buku ini mengikuti dari situ. Sebuah modul masuk tur ketika ada bab yang membawa run di pin, dan
pertanyaan terbuka di outline soal permukaan stdlib tetap terbuka: daftarnya tumbuh hanya dengan sample yang
terverifikasi, tidak pernah dari dokumentasi Nim 2 dan tidak pernah dari keberadaan sebuah file.

## Nim 2 delta

*Yang dilakukan Nim 2:* `std/strformat` dan `std/re` adalah import biasa, sequence punya operator `&`, dan
atomics berupa tipe wrapper, `var counter: Atomic[int]`, dengan anggota `load()` dan `store()`.
*Yang dilakukan Nimony:* `strformat` dan `re` tidak ada di pin, helper sequence tinggal di `system` dan
`std/sequtils`, `&` hanya untuk string, dan atomic adalah variabel biasa dengan fungsi bebas yang
beroperasi padanya.
*Yang rusak kalau kebiasaannya dibawa:* `import std / strformat` menghentikan build di import, `xs & ys`
resolvenya ke overload string lalu gagal dengan mismatch, dan `Atomic[int]` ditolak sebagai undeclared
identifier. Penggantinya satu panggilan jauhnya di tiap kasus: `%` dari `strutils`, `concat` dari
`sequtils`, dan `atomicLoad` pada `var` biasa.

## Samples

`samples/20-stdlib/stdlib.nim`, dijalankan di commit yang dipin:

```
nimony c -r samples/20-stdlib/stdlib.nim
```

Output yang diharapkan, yang dicetak verifier sample secara penuh:

```
42
not a number: 4x
-1
2
tea
2
tea and coffee
---
4
2 2
3 9
2 2
3
2 6
2
9
false
2
missing: milk
0
2
true
true
false
2
10
```

Baris demi baris: `parseInt` di balik `try` (`42`, lalu kegagalan yang tertangkap dan `-1`); `split` dan
`strip` pada record berpadding (`2`, `tea`, `2`); `join` dan `repeat` (`tea and coffee`, `---`); `add`,
`setLen` dan `delete` dari `system` (`4`, lalu `2 2`); `insert`, `delete` rentang dan `concat` dari
`sequtils` (`3 9`, `2 2`, `3`); `map` dan `filter` (`2 6`, `2`); jumlah tabel dengan satu jawaban `hasKey`
(`9`, `false`); pembacaan yang melempar ditangkap dan key hilang dilaporkan (`2`, `missing: milk`, `0`);
keanggotaan set (`2`, `true`, `true`, `false`); dan operasi atomic (`2`, `10`).

## Cek

1. Tulis probe dua baris untuk `std/heapqueue`: push tiga integer, cetak minimum yang di-pop. Output yang
   diharapkan: nilai terkecil yang kamu push.
2. `echo @[1, 2]` adalah error. Ubah satu hal supaya ia mencetak sesuatu yang informatif, tanpa menulis
   loop. Diharapkan: satu baris berisi kedua angkanya.
3. Panggil `parseInt` tanpa `try`. Diharapkan: compile error yang menyebut `.raises`, sebelum programnya
   jalan.
4. Baca `counts["milk"]` dari tabel di sample tanpa penjaga dan tanpa `try`. Diharapkan: compile error,
   bukan crash saat runtime.
5. Ganti `counts.getOrDefault("tea", 0) + 1` dengan `counts["tea"] + 1` dan bungkus barisnya dengan `try`.
   Diharapkan: output yang sama dengan sample.
6. Tanya apakah `std/cookies` ada di pin, dan jawab dari output sebuah perintah, bukan dari ingatan.

## Chapter checklist

draft 2026-11-13 · tech_review 2026-11-13 · editorial_pass 2026-11-13 · frozen 2026-11-13
