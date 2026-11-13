---
chapter: 19
title: Plugins and the NIF Pipeline
job: Replace the macro habit with plugins that operate on NIF, and explain what NIF buys in incremental and parallel builds.
nimony_version: 0.6.3
nimony_commit: 4ba90a781b0b22d0821efaa153c129c37cef6143
toolchain: ~/.local/opt/nimony/4ba90a7
host_compiler: ~/.local/opt/nim-2.4.0
status: frozen
tech_review: Momo 2026-11-13
editorial_pass: 2026-11-13
samples: [samples/19-plugins-nif/plugins.nim]
glossary_added: [plugin, NIF, template plugin, module plugin, for-loop plugin, plugin cache]
---

# Plugin dan Pipeline NIF

## Untuk apa bab ini

Macro dulu adalah routine yang jalan di dalam compiler dan mengembalikan kode. Nimony tidak punya routine
semacam itu: `doc/differences.md:19` bilang macro diganti compiler plugin. Plugin adalah program Nim terpisah
yang dikompilasi compiler, dijalankan sebagai subprocess, dan dikirimi satu pohon, lalu menjawab dengan pohon.
Semua yang bisa dilihat plugin dan semua yang bisa ia hasilkan adalah NIF, representasi yang sama dengan yang
dipakai fase-fase compiler sendiri untuk saling bicara. Itu inti desainnya, dan itu juga yang membuat plugin
lebih gampang dinalar daripada macro: input dan outputnya adalah file yang bisa kamu buka.

## Plugin itu template tanpa body

Deklarasinya kelihatan seperti template. Body-nya adalah pragma yang menunjuk file lain:

```nim
# main.nim
import std / syncio

template generateEcho(s: string) {.plugin: "deps/mplugin1".}

generateEcho("Hello, world!")
```

```nim
# deps/mplugin1.nim
import plugins

proc transform(n: NifCursor): NifBuilder =
  result = createTree()
  let info = n.info
  var arg = callArgs(n)
  result.withTree StmtsS, info:
    result.withTree CallS, info:
      result.addIdent "echo"
      result.takeTree arg

var inp = loadPluginInput()
saveTree transform(inp)
```

Dikompilasi dan dijalankan, itu mencetak `Hello, world!`. `doc/language.md:5307-5309` menyatakan aturannya:
plugin adalah template yang tidak punya body dan membawa pragma `{.plugin.}` berisi program Nim yang
mengimplementasikannya.

Baca file kedua sebagai program biasa, karena memang itu. Ia mengimpor satu module, `plugins`, yang API-nya
berupa cursor NIF untuk membaca dan builder untuk menulis. `loadPluginInput()` membuka file yang dikirim
compiler sebagai argumen pertama. `saveTree` menulis hasilnya ke file yang disebut argumen kedua. Tidak ada
yang menghubungkan dua proses itu selain file. Compiler menulis input, menjalankan executable, membaca output,
lalu menyisipkan hasilnya ke module yang sedang ia periksa (`doc/design.md:86-90`, `src/nimony/semos.nim:973-1020`).

Dua konsekuensi ikut dari kalimat "program biasa". Plugin dikompilasi ke kode native oleh Nimony sendiri
dengan `-d:nimonyPlugin`, jadi plugin yang tidak bisa dibangun sudah gagal sebelum kode yang memakainya
diperiksa. Dan plugin jalan di ruang alamatnya sendiri: ia tidak bisa meraih tabel simbol compiler, dan itu
sebabnya bagian menarik dari API-nya adalah soal meminta apa yang belum ia punya, bukan menelusuri struktur
yang tidak bisa ia lihat.

## Yang datang tergantung parameternya

Argumen panggilan yang sama bisa datang ke plugin dalam dua bentuk. Deklarasikan parameter `untyped` dan ia
datang sebagai sumber, sebelum name resolution. Deklarasikan `typed` dan ia datang setelah semantic analysis,
sudah di-lower dan di-resolve.

```nim
import std / syncio

template shape(x: untyped) {.plugin: "deps/shape".}
template typedShape(x: typed) {.plugin: "deps/shape".}

shape(2 + 3 * 4)
typedShape(2 + 3 * 4)
```

Plugin yang mencetak tag argumen pertama melaporkan `infix` untuk panggilan pertama dan `add` untuk yang kedua.
Bedanya ada di file input yang di-cache, dan compiler menyimpannya: tiap invocation menulis inputnya ke file
`.in.nif` di bawah `nimcache`, dalam bentuk biner NIF dengan ekstensi yang biasa. `tools/niftools bif2nif`
men-decode-nya di tempat. Input `untyped` untuk panggilan di atas berbunyi, dengan path dan indeks dihilangkan:

```
(stmts shape (infix \+ a~2 1))
```

Input `typed` untuk sumber yang sama berbunyi:

```
(stmts typedShape (add (i 64)a.0.main~2 1))
```

Empat hal berubah. Gula operatornya hilang: `2 + 3 * 4` tadinya node `infix` dengan token operator, sekarang
node `add`. Identifier `a` menjadi `a.0.main`, simbol yang menyebut deklarasinya dan module-nya. Simbolnya
membawa tipe, `(i 64)`, jadi tipe sebuah argumen bisa dibaca tanpa meminta deklarasi ke compiler. Dan pohonnya
menulis `2` di tempat sumber menulis literal sebagai operand ekspresi infix. Itu arti "NIF yang sudah diperiksa
dan di-lower" dalam praktik.

Input mentah tidak diperiksa, dan itu bukan detail. Plugin yang membuang argumennya bisa dipanggil dengan nama
yang tidak ada:

```nim
template ignore(x: untyped) {.plugin: "deps/drop".}

ignore(notDeclared + 1)
echo "survived"
```

Itu bisa dibangun dan mencetak `survived`, karena argumennya tidak pernah di-resolve: plugin dikirimi
`(infix \+ notDeclared 1)` dan menjawab dengan hal lain. Ubah parameternya ke `typed` dan panggilan yang sama
tetap bisa dibangun kalau plugin tetap membuangnya, dan itulah pelajarannya: jenis parameter menentukan apa
yang dikirim ke plugin, bukan kapan argumennya diperiksa. Argumen yang diteruskan plugin diperiksa saat output
plugin diperiksa.

Wrapper-nya perlu dihafal karena setiap plugin menulis terhadapnya. Inputnya node `(stmts <nama template>
<argumen>...)`, dan `callArgs` ada untuk melewati wrapper sekaligus namanya (`src/nimony/lib/plugins.nim:1095-1105`).
Plugin dengan dua argumen memanggil `callArgs` sekali lalu mengiterasi dari situ.

Jenis parameter juga satu-satunya tempat template plugin berbeda dari template biasa dengan cara yang menggigit.
Plugin yang menghasilkan nilai butuh tipe kembalian ditulis di deklarasinya:

```nim
proc twice(n: int): int = n + n

template double(x: typed): int {.plugin: "deps/double".}

echo double(21)      # 42
```

Hilangkan `: int` dan ekspansinya tidak punya tipe: `let b = double(21)` gagal dengan `type mismatch: got:
void but wanted: int64`. Template biasa menyimpulkan nilai dari body-nya; template plugin tidak punya body
untuk disimpulkan, jadi deklarasinya harus bilang.

## Menulis pohon kembali

Builder-nya kecil, dan sample-nya memakai hampir semuanya. `withTree` membuka node, menjalankan blok, lalu
menutupnya. `addIdent` menulis nama yang akan di-resolve compiler di scope pemanggil. `addStrLit` menulis string
literal. `takeTree` menyalin subtree sekarang dari input dan memajukan cursor. `addSubtree` menyalin tanpa
memajukan, dan begitulah satu argumen menjadi dua:

```nim
proc transform(n: NifCursor): NifBuilder =
  result = createTree()
  let info = n.info
  var arg = callArgs(n)
  result.withTree CallX, info:
    result.addIdent "twice"
    result.addSubtree arg

var inp = loadPluginInput()
saveTree transform(inp)
```

Plugin itu mengganti `double(21)` dengan panggilan ke `twice(21)`, dan `twice` di-resolve sesudahnya, di module
yang membuat panggilan. Jadi plugin mengeluarkan nama, bukan simbol yang sudah terikat, kecuali ia sengaja
menyalin simbol dari inputnya.

Tag ditulis sebagai nilai enum (`StmtsS`, `CallS`, `CallX`, `AddX`), bukan string. Kelima kelasnya, statement,
expression, type, pragma, dan substruktur yang bukan salah satunya, berbagi satu ruang ordinal dengan tag id
compiler (`doc/plugins.md:65-85`). Imbalannya error kompilasi di dalam plugin untuk nama tag yang salah ketik,
bukan pohon rusak saat run time.

Compiler memvalidasi apa yang kembali, dan ia melakukannya saat plugin dibangun, bukan saat pohonnya disisipkan.
Builder yang menghasilkan `(add ...)` dengan dua anak ditolak dengan sumber plugin disebut di pesannya:

```
deps/double.nim(7, 3) Error: expected 3..3 children, got 2 [transform builds (add)]
FAILURE: .../bin/validator --nimcache:nimcache/double_v deps/double.nim
```

Tiga anak, karena tag aritmetika membawa lebih dari dua operand yang kelihatan di sumber: satu tipe di slot 0,
lalu operand kiri dan kanan. Input milik compiler untuk `2 + 3 * 4` menulis `(add (i 64)a.0.main 1)`, yang
terbaca sebagai dua anak hanya karena tipenya menumpang di simbol. Operator yang dibangun tangan memasok tipenya
sendiri:

```nim
result.withTree AddX, info:
  result.withTree IT, info: result.addIntLit 64
  result.addIntLit 2
  result.addIntLit 3
```

Node itu bernilai `5`. Menyalin argumen bertipe ke slot tipe malah lolos cek arity dan mati kemudian di semantic
analysis, jadi aturannya: node tipe dulu, atau bentuk dua anak milik compiler tanpa menambah apa pun.

## Empat scope, satu mekanisme

Template plugin jalan di tiap call site. Jenis lainnya jalan di scope berbeda, dan `doc/plugins.md:8-20`
mendaftarnya: for-loop plugin yang dideklarasikan pada `iterator`, module plugin yang dideklarasikan sebagai
statement, type plugin yang menempel ke sebuah tipe, dan import plugin yang menempel ke sebuah `import`.

Module plugin menerima seluruh module setelah semantic analysis dan harus mengembalikan seluruh module. Begitulah
transformasi satu module tetap berupa suntingan pohon, bukan sekumpulan hook per call site:

```nim
{.plugin: "deps/erase".}

echo "kept"
block:
  echo "erased"
```

Dengan plugin yang melewati statement `block` di top level, program mencetak `kept` saja. Block yang dihapus
hilang sebelum code generation, bukan dilewati saat run time.

For-loop plugin dideklarasikan pada iterator tanpa body, dan ia dipanggil untuk `for` loop yang memanggil
iterator itu. Inputnya seluruh loop, bukan call site. Variabel loop-nya bertipe sesuai element type yang
dideklarasikan iterator, jadi iterator yang menyebutkannya memberi plugin variabel bertipe dan body yang bersih:

```
(forcall countTo
 (callargs 3)
 (unpackflat (let :i.0 . . (i@G 64).))
 (stmts (discard (add (i 64)i.0 1))))
```

Itu `iterator countTo(n: int): int {.plugin: "deps/peek".}` dengan body berbunyi `discard i + 1`, dan `: int`
yang dideklarasikan itulah asal `(i@G 64)`. Hilangkan tipe kembaliannya dan element type-nya jadi `void`, jadi
variabelnya datang tanpa tipe dan body yang menyebut `i` sudah berupa node error saat plugin melihatnya:

```
(stmts
 (discard i.0
  (err "expression of type `void` must not be discarded")))
```

Jadi jenis ini bisa dipakai untuk transformasi body asal iterator-nya bilang apa yang ia hasilkan, dan body yang
diterima plugin sudah diperiksa penuh, dan itulah yang membuat penulisan ulang sadar-tipe mungkin. Dokumentasi
mendaftar jenis ini di satu baris tabel (`doc/plugins.md:8-20`) tanpa aturan maupun contoh, jadi bab ini
menyebut scope dan syaratnya sekaligus, bukan mengajarkan jenisnya.

Import plugin adalah yang paling lain, dan layak dipisahkan di kepala pembaca. `import (path/foo) {.plugin:
"v2".}` menyebut module path dan executable yang sudah dibangun, bukan file `.nim` yang di-resolve terhadap
module pengimpor (`doc/plugins.md:415-437`). Di pin, menulisnya tanpa executable di tempat berhenti di module
path:

```
main.nim(2, 1) Error: file not found: .../src/lib/path/foo.nim
```

Path-nya dicari di direktori library toolchain, jadi string import plugin itu nama module di search path biasa,
dan executable-nya harus ada sebelum build mencapainya. Contoh in-tree-nya `src/v2`, yang memanggil compiler Nim
2 lewat shell dan mengisi cache dengan NIF hasil sem untuk satu module penuh.

## Di mana plugin tinggal

Path di pragma di-resolve relatif terhadap file yang memuat string-nya, bukan relatif terhadap call site.
Perbedaan itu punya akibat yang kelihatan saat template diekspor:

```
a/lib.nim            mendeklarasikan template tagged*(s: string) {.plugin: "deps/tagger".}
a/deps/tagger.nim    plugin yang disebut lib.nim
b/main.nim           mengimpor ../a/lib dan memanggil tagged("hi")
b/deps/tagger.nim    umpan dengan nama plugin yang sama
```

Dikompilasi dari `b`, dengan plugin bernama sama duduk di sebelah `b`, program mencetak hasil
`a/deps/tagger.nim`, dan `b/deps/tagger.nim` tidak pernah dikompilasi. Executable-nya mendarat di cache build
yang sedang jalan, bukan di cache module yang mendeklarasikan pragma: build ini menulis `b/nimcache/tagger`,
dan `a/nimcache` tidak pernah dibuat. Program kedua di dalam `a` mengompilasi sumber yang sama lagi ke cache-nya
sendiri, dan itu sebabnya cache ini per build, bukan per plugin. `doc/plugins.md:172-191` menyatakan aturan
resolusinya; probe-nya adalah cek bahwa aturan itu berlaku saat dua kandidat ada.

Build graph memperlakukan plugin sebagai leaf: node module mendaftar executable plugin yang mungkin ia jalankan
sebagai input, dan executable itu output dari node `pluginbuild`, jadi driver membangunnya lebih dulu dan
memeriksa ulang module saat salah satunya berubah (`src/nimony/deps.nim:2025-2027`). Itu sebabnya suntingan
plugin bukan rebuild penuh, dan plugin yang tidak pernah dipanggil module yang berubah juga tidak dibangun ulang.

## Cache, dan satu panggilan yang menjaganya jujur

Invocation plugin di-cache berdasarkan checksum pohon inputnya, bukan jam. `runPlugin` menghitung checksum itu,
menamai file input dan output menurutnya, dan memakai ulang outputnya saat file-file itu masih berlaku
(`src/nimony/semos.nim:1000-1015`). Dua call site menghasilkan dua input dan dua kali jalan; call site yang sama
di build berikutnya menghasilkan satu file dan nol kali jalan.

Itu benar untuk plugin yang jawabannya cuma bergantung pada inputnya, dan salah untuk plugin yang membaca hal
lain. Plugin yang membaca file skema, tabel konstanta, atau template akan ter-memo selamanya: file-nya berubah,
inputnya tidak, dan build terus memakai ekspansi lama. Obatnya satu panggilan:

```nim
dependsOn "extra.txt"
```

`dependsOn` melaporkan pembacaannya, dan compiler menjalankan ulang plugin saat file yang disebut lebih baru
dari output yang di-cache (`doc/plugins.md:649-687`). Bedanya gampang dilihat dengan plugin yang menggemakan isi
file:

```
             build pertama   setelah extra.txt diubah
tanpa dependsOn    first                  first
dependsOn          first                  second
```

Ada dua batas saat file-nya bukan satu path. Hanya path yang ada yang dicatat, jadi membuat file yang plugin
cari dan tidak temukan tidak membatalkan apa pun. Menyebut direktori bukan berarti menyebut isinya: file yang
dibuat di dalam subdirektori langsung menjalankan ulang plugin walaupun timestamp direktori itu sendiri tidak
bergerak, sementara mengubah file yang sudah ada di bawah situ tidak mengubah apa pun. Sebut tiap file kalau isi
sebuah pohon penting.

Sumber plugin itu sendiri satu-satunya file yang tidak jatuh ke perangkap itu. Ia input bagi node module, jadi
mengubahnya menjalankan ulang plugin dan memeriksa ulang module, sementara file data yang dibaca plugin tetap
tak terlihat sampai `dependsOn` menyebutnya.

Ada satu hal lagi sebelum menulis plugin yang membaca file: di pin, `readFile` dideklarasikan `.raises`
(`lib/std/syncio.nim:577`), jadi plugin yang memanggilnya harus menangkapnya:

```
deps/note.nim(7, 25) Error: cannot call a routine marked as `.raises` outside of a `try`..`except` block
```

## Apa yang NIF beli di sebuah build

Job kedua bab ini adalah alasan desain ini ada, dan versi jujurnya lebih kecil dari "NIF bikin build
cepat". Tiga sifat yang bekerja, dan ketiganya sifat format, bukan sifat sistem plugin.

Deklarasi dan pemakaian adalah token kind yang berbeda (`doc/design.md:75-81`). Compiler bisa menjawab "ini
dideklarasikan di mana" dan "siapa yang memakai ini" dari representasinya, tanpa mencocokkan nama atas teks,
dan plugin mendapat informasi yang sama gratis: `symText` dan simbol di pohon adalah identitasnya, bukan ejaan
yang harus di-resolve lagi.

Simbol dimuat malas. NIF punya format indeks pendamping yang memungkinkan compiler menarik satu simbol saat
dibutuhkan, bukan membaca satu module penuh, dan `doc/design.md:81` menyebutnya "most essential for incremental
compilations". Header sebuah module bisa dibaca tanpa membaca body-nya, jadi perubahan di satu module tidak
memaksa compiler membaca ulang antarmuka semua module di atasnya.

Module adalah node terpisah dalam satu graph. Tiap module punya node pemeriksaan semantiknya sendiri, dan driver
menjalankan graph, bukan daftar: nifmake adalah "a make-like tool that is used by Nimony to implement parallel
and incremental compilation" (`src/nifmake/nifmake.nim:7-9`), menjadwalkan dari ready queue (`:458-470`), dan
baris perintah di build yang gagal berbunyi `nifmake -j run`. Plugin adalah node lain di graph itu. Karena itu
ia tidak menyerialkan build yang ia ikuti: ia dibangun sekali, di-cache per input, dan dipakai bersama oleh
setiap module yang memanggilnya. Bagian paralelnya milik build graph, bukan milik plugin. Tidak ada di bab
ini yang membuat plugin konkuren, dan plugin yang menulis file bersama dari dua module sekaligus adalah bug yang
kamu tulis sendiri.

Biaya NIF sama konkretnya. Penulis plugin bekerja dengan tag sebuah IR compiler, bukan dengan AST yang dirancang
untuk manusia, dan inputnya snapshot yang dibekukan: plugin tidak bisa bertanya ke compiler kecuali dengan
meminta deklarasi tipe yang ia butuhkan. Itu pokok bahasan `needTypes`, yang membuat compiler menambahkan
deklarasi yang disebut plugin ke input kedua dan menjalankan plugin lagi (`doc/plugins.md:226-273`). Plugin yang
tidak pernah memeriksa tipe tidak membayar apa pun, dan yang memeriksa memintanya satu level sekaligus, bukan
satu simbol sekaligus.

## Saat plugin salah

Ada empat kegagalan yang perlu dikenali, karena pesannya tidak menyebut "plugin".

Plugin yang menulis pohon kosong menghentikan build dengan `??? Error: expression expected`, menunjuk call site.
`???` itu posisi sumber yang hilang dari output plugin, bukan diagnostic yang rusak: outputnya tidak punya
lokasi karena builder-nya tidak menulis satu pun.

Plugin yang ingin melaporkan masalah mengembalikan `errorTree`, dan compiler mencetaknya sebagai error
compile-time:

```
??? Error: stop here
```

Itu cara yang didokumentasikan untuk menolak argumen (`doc/plugins.md:688-702`), dan pesannya datang tanpa file
dan baris kecuali plugin menyediakannya. Kedua bentuk jalan. Kembalikan sebagai seluruh output, atau tambahkan
di dalam builder lain (`result.addTree errorTree("must be an integer", arg)`), di mana overload yang menerima
cursor melaporkan posisi argumennya sebagai `main.nim(4, 11) Error: must be an integer`. Yang benar-benar
meng-assert di dalam builder adalah `tagText` yang dipanggil pada simbol: ia mengindeks tabel tag dengan tag id
cursor (`src/nimony/lib/plugins.nim:167-169`), dan simbol tidak punya tag id.

Sumber plugin yang tidak ada tidak dilaporkan sebagai plugin yang hilang. Namanya di-resolve di direktori
library toolchain, dan build mati di parser:

```
nifler2: cannot read the input file
FAILURE: .../nifler2 --portablePaths --deps parse .../src/lib/deps/nothere.nim ...
```

Baca path di baris itu: ia memberi tahu di mana compiler mencari. Path yang mulai dengan direktori proyek kamu
adalah yang kamu maksud; path di bawah `src/lib` toolchain berarti string pragmanya di-resolve sebagai module
library, dan file plugin-nya tidak ada di path yang disebut.

Bentuk keempat tidak punya pesan compiler sama sekali. Plugin yang namanya resolve tapi executable-nya tidak ada
dijalankan sebagai perintah, dan shell yang mengeluh:

```
/bin/sh: nosuchplugin: command not found
nifmake: command failed (exit code 127): nosuchplugin mymod/foo.nim nimcache/...
```

Jadi build yang berhenti dengan exit code 127 dan satu baris shell bukan toolchain rusak: path di pragma
me-resolve ke sesuatu yang tidak ada di situ.

## Nim 2 delta

*Apa yang dilakukan Nim 2.* Macro adalah routine dengan dua bagian: kode Nim yang jalan di compiler dan pohon
`NimNode` yang ia kembalikan. `std/macros` adalah API-nya, dan macro dipanggil seperti template.

*Apa yang dilakukan Nimony.* Plugin adalah program terpisah yang dikompilasi ke kode native, dijalankan sebagai
subprocess, membaca NIF dan menulis NIF. Tidak ada API pohon in-process, tidak ada `NimNode`, dan tidak ada cara
menyerahkan callback ke compiler.

*Apa yang rusak kalau kamu mempertahankan kebiasaan itu.* Macro yang diport dan membangun hasilnya dengan memanggil
proc helper di module yang sama sekarang jadi program yang harus memuat input, mentransformasinya, dan
menyimpannya, dan helper-nya harus ada di dalam plugin, bukan di module yang memakainya. Macro yang
mengembalikan `NimNode` tidak akan kompilasi sama sekali. Di pin, `macro` dengan parameter `untyped` masih bisa
dikompilasi dan dijalankan, yang membuat kebiasaan lama terlihat didukung: `doc/differences.md:19` bilang macro
diganti, jadi perlakukan macro yang masih hidup sebagai compatibility surface dan tulis transformasi baru sebagai
plugin.

## Samples

`samples/19-plugins-nif/plugins.nim`, dikompilasi dan dijalankan di commit yang di-pin:

```
$ nimony c -r samples/19-plugins-nif/plugins.nim
infix
add
42
```

Tiga baris. Dua yang pertama datang dari satu plugin yang dipakai dua kali, sekali lewat parameter `untyped` dan
sekali lewat yang `typed`: plugin melaporkan tag yang diterimanya, dan tag-nya berbeda karena argumen kedua sudah
di-resolve dan di-lower. Yang ketiga adalah plugin yang mengganti `double(21)` dengan `twice(21)`, yang kemudian
di-resolve dan dijalankan compiler. `block` yang dihapus module plugin mencetak apa pun tidak, dan itu hal
keempat yang dicek sample ini.

## Cek

1. Tulis template plugin yang menerima satu argumen `untyped` dan mengembalikannya apa adanya, lalu panggil
   dengan ekspresi yang nilainya kamu cetak. Jelaskan kenapa output program adalah ekspresinya, bukan input
   plugin-nya.
2. Ubah parameternya ke `typed` dan decode kedua input yang di-cache dengan `tools/niftools bif2nif`. Sebutkan
   tiga perbedaan di antara keduanya, satu di antaranya harus berupa simbol.
3. Tulis plugin yang membaca file teks dan mengeluarkan isinya sebagai string literal. Build dua kali dengan file
   diubah di antaranya, catat bahwa outputnya tidak berubah, lalu tambahkan `dependsOn` dan build lagi.
4. Buat plugin mengeluarkan `(add ...)` dengan tangan dan dua anak, lalu catat pesan validator-nya. Sesudah itu
   taruh node tipe di slot pertama dan dua int literal sesudahnya, dan catat apa yang dicetak programnya. Coba
   juga mengirim argumen bertipe di tempat tipe itu seharusnya.
5. Pindahkan sumber plugin ke direktori kedua dan tinggalkan umpan bernama sama di direktori module pemanggil.
   Catat mana yang jalan, dan di mana executable-nya ditulis.

## Chapter checklist

`draft 2026-11-13 · tech_review Momo 2026-11-13 · editorial_pass 2026-11-13 · frozen 2026-11-13`
