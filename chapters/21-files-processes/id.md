---
chapter: 21
title: Files, Processes, and the Outside World
job: Read and write files, read arguments and environment, return exit codes, and run a subprocess.
nimony_version: 0.6.3
nimony_commit: 4ba90a781b0b22d0821efaa153c129c37cef6143
toolchain: ~/.local/opt/nimony/4ba90a7
host_compiler: ~/.local/opt/nim-2.4.0
status: frozen
tech_review: Momo 2026-11-13
editorial_pass: 2026-11-13
samples: [samples/21-files-processes/files.nim]
glossary_added: [Path, process exit code, poEvalCommand, poUsePath, environment variable, temp directory]
---

# File, Proses, dan Dunia di Luar

## Untuk apa bab ini

Setiap program sampai titik ini masih kotak tertutup: dia membaca literalnya sendiri, menghitung, lalu mencetak.
Itu demonstrasi, bukan alat. Bab ini adalah tempat program mulai menyentuh hal-hal yang hidup lebih lama
daripadanya — file di disk, argumen yang dipakai saat dia dijalankan, environment yang dia warisi, exit code yang
dia kembalikan ke apa pun yang menjalankannya, dan program lain yang dia jalankan sendiri.

Dua aturan menata seluruh bab. Apa pun yang menjangkau ke luar proses bisa gagal, dan compiler memaksa kamu
mengatakannya: hampir semua routine di sini ditandai `{.raises.}`, jadi panggilan tanpa `try` adalah compile error,
bukan kejutan saat jalan. `execShellCmd` adalah pengecualian yang kamu temui nanti, dan dia melaporkan kegagalan
meluncurkan sebagai `-1`. Dan path punya tipenya sendiri di pin, bukan string berisi garis miring, dan di situlah
program Nim 2 yang ditulis terhadap `os` berhenti ter-compile.

## Satu file, dibaca dan ditulis utuh

Pasangan terkecil yang berguna adalah `writeFile` dan `readFile` (`lib/std/syncio.nim:590`, `:577`). Keduanya
`{.raises.}`, dan itu compiler yang memberi tahu kamu kebenaran tentang disk:

```nim
import std / [syncio]

try:
  writeFile("note.txt", "first\n")
  echo readFile("note.txt").len
except ErrorCode as e:
  echo "failed: ", e
```

Itu mencetak `6`: lima karakter plus newline. Kegagalannya adalah nilai dari enum yang sama dengan yang diajarkan
Bab 15, bukan objek exception; file yang tidak ada datang sebagai `IOError`, begitu juga pembacaan yang
diarahkan ke direktori alih-alih file. `readFile` tidak punya pemeriksaan "apakah ada" di dalamnya, dan tidak
butuh.

`writeFile` kedua ke nama yang sama menggantikan file itu. Dia tidak pernah menambahkan, dan tidak pernah
menggabungkan: setelah `writeFile("t.txt", "first version\n")` lalu `writeFile("t.txt", "second\n")`, `readFile`
mengembalikan `second`. Itu layak diketahui sebelum kamu memakai `writeFile` di dalam loop lalu bertanya-tanya ke
mana baris-baris sebelumnya pergi.

Menambahkan butuh handle file eksplisit dan mode buka (`lib/std/syncio.nim:400`):

```nim
var f: File
discard open(f, "note.txt", fmAppend)
f.writeLine("third")
close(f)
```

`open` dalam bentuk itu mengembalikan `bool` dan tidak raise. Sisi baca dari tipe yang sama punya dua bentuk:
`readLine(f, s: var string): bool` mengembalikan apakah satu baris terbaca (`lib/std/syncio.nim:506`), dan itulah
cara menghitung baris tanpa tahu ukuran file; `readAll(f)` mengembalikan semua yang tersisa
(`lib/std/syncio.nim:561`), dan dia `{.raises.}` sementara pasangan `readLine` tidak. `getFileSize`
(`lib/std/os.nim:443`) dan `fileExists` adalah dua ketukan di sisi file yang tidak membukanya.

Satu overload `open` adalah jebakan. `open(filename, mode)` — bentuk yang mengembalikan `File` alih-alih mengisi
`var` — tidak raise pada file yang tidak ada: dia mencetak `cannot open: missing.txt` lalu mengakhiri program
dengan exit code `1` (`lib/std/syncio.nim:453-461`). Docstring di atasnya masih bilang dia melempar `IOError`, dan
baris yang seharusnya melakukan itu dikomentari dengan `TODO` di sebelahnya. Baca body-nya, bukan docstring-nya:
bentuk yang quit itu bukan bentuk yang kamu mau di dalam `try`.

## Path bukan string

Di pin, path punya tipe, `Path`, dibangun dengan `path("...")` dan dikembalikan jadi string dengan `$`
(`lib/std/paths.nim:26`, `:30`). Gabungkan dua dengan `/`, bongkar satu dengan `extractFilename` atau `splitFile`,
dan selesaikan yang relatif terhadap working directory dengan `absolutePath` (`lib/std/paths.nim:63`, `:188`,
`:289`). Tipenya bukan hiasan. `echo somePath` ditolak, karena sembilan overload `write` dari Bab 20 tidak
punya `Path` di dalamnya, sementara `echo $somePath` mencetak; konversinya eksplisit dengan sengaja, sebab path
adalah data tentang filesystem, bukan teks yang ingin dibaca.

API-nya terbelah di dua modul, dan belahannya tidak simetris:

- mutator ada di `std/files` dan menerima `Path`: `removeFile`, `copyFile`, `moveFile`, `tryRemoveFile`
  (`lib/std/files.nim:65`, `:186`, `:261`, `:45`); `std/dirs` me-re-export kedua penghapus itu
  (`lib/std/dirs.nim:11`, `:15`), jadi modul yang sudah mengimpor `dirs` mencapainya tanpa impor kedua;
- predikat ada di `std/os` dan menerima `string`: `fileExists`, `dirExists`
  (`lib/std/private/oscommons.nim:111`, `:141`), di-re-export oleh `lib/std/os.nim:11`;
- operasi direktori ada di `std/dirs` dan menerima `Path`: `createDir`, `removeDir`
  (`lib/std/dirs.nim:49`, `:305`).

Jadi `fileExists(somePath)` adalah type mismatch dan `fileExists($somePath)` bukan, sementara `removeDir(somePath)`
menginginkan `Path` dan menolak string. Dua modul, dua konvensi, dan compiler tidak akan membiarkan kamu salah tebak
diam-diam — dia cuma membuat kamu melihat.

`tryRemoveFile` layak dapat paragrafnya sendiri. Dia mengembalikan `ErrorCode`, jadi panggilan telanjang adalah
`expression of type ErrorCode must be discarded`, dan nilai berhasilnya adalah anggota enum `Success`
(`lib/std/files.nim:45-62`). Discard saat kamu hanya ingin mencoba, atau bandingkan saat alasannya penting.
`removeFile` adalah operasi yang sama dengan kontrak `try` sebagai gantinya, dan dia memperlakukan file yang tidak
ada sebagai tidak ada urusan (`lib/std/files.nim:65-70`): langkah pembersihan tidak butuh pemeriksaan keberadaan,
juga tidak butuh `NameNotFound` yang ditangkap.

Kerja sementara tinggal di direktori sementara. `createTempDir(prefix, suffix)` mengembalikan `Path` di bawah
direktori temp sistem; `createTempFile` mengembalikan tuple `(File, Path)` yang handle-nya sudah terbuka dan
kontrak terdokumentasinya adalah kamu menutup handle dan menghapus path-nya (`lib/std/tempfiles.nim:181`,
`:156-171`); `genTempPath` memberi namanya tanpa membuat apa pun (`:103`). Sample yang menulis di sebelah
repository meninggalkan sampah; sample yang menulis ke direktori sementara menghapusnya di akhir dan aman
dijalankan dua kali.

Satu ambiguitas layak diketahui sebelum kamu menemuinya: mengimpor `dirs` dan `paths` bersama memberi dua
`getCurrentDir`, satu di tiap modul (`lib/std/dirs.nim:440`, `lib/std/paths.nim:255`), dan panggilannya lalu
`ambiguous call: 'getCurrentDir'`. Sebut modulnya, atau impor hanya yang kamu pakai. Keduanya mengembalikan tipe
yang sama; compiler sekadar tidak mau memilih untuk kamu.

## Argumen datang sebagai daftar

`paramCount` dan `paramStr` adalah pasangan primitifnya (`lib/std/cmdline.nim:211`, `:218`), dan
`commandLineParams` mengembalikannya sebagai `seq[string]` (`lib/std/cmdline.nim:262`). Ketiganya ikut `std/os`,
yang me-re-export modulnya (`lib/std/os.nim:8`).

Daftar itu adalah argument vector, bukan string yang perlu dipecah: argumen yang berisi spasi datang sebagai satu
elemen, dan argumen kosong datang sebagai string kosong. Menjalankan probe dengan `one "two three" ""` mencetak
`[one]`, `[two three]`, `[]` dari `paramStr`, dan tiga yang sama dari `commandLineParams`. Tidak ada quoting yang
harus benar dan tidak ada shell yang terlibat, karena shell sudah menyelesaikan kerjanya sebelum program kamu mulai.

`commandLineParams` adalah `seq`, artinya dia tidak bisa dicetak `echo` dengan alasan yang Bab 20 berikan:
cetak elemennya di loop, bukan sequence-nya.

Nama lain di modul itu tidak seperti yang diharapkan pembaca. `getAppFilename` mengembalikan executable yang
sedang jalan (`lib/std/os.nim:132-135`), dan di pin itu file di dalam `nimcache` — `nimcache/c/<hash>/main` di
sebuah probe — bukan nama sumber yang kamu compile. Pakai dia untuk tahu prosesnya apa, jangan untuk menemukan file
yang bersebelahan dengan sumber kamu. `getAppDir` adalah direktori yang sama dengan nama lain
(`lib/std/os.nim:138`).

## Environment yang kamu warisi

`getEnv` total dan menerima default, `existsEnv` menjawab pertanyaan, dan `putEnv`/`delEnv` adalah penulisannya
(`lib/std/envvars.nim:140`, `:177`, `:204`, `:244`). Pembacaannya tidak pernah raise; kedua penulisan raise, jadi
keduanya tempatnya di `try` seperti semua yang mengubah state di luar proses. `envPairs` mengiterasi seluruh
environment (`lib/std/envvars.nim:271`), dan itu cara jujur menjawab "apa yang kamu warisi" alih-alih menebak nama
variabel.

Variabel yang kamu set terlihat oleh proses anak yang kamu jalankan, karena environment diwarisi, bukan disalin ke
anak dengan tangan. Probe yang men-set `NIMONY_CHILD` lalu menjalankan `/usr/bin/env` lewat shell melihat nilainya.
Itulah seluruh mekanisme di balik konfigurasi lewat environment: tanpa API, sebuah tabel di tingkat proses.

## Exit code bagian dari antarmuka

Sebuah program mengatakan dua hal saat berakhir: apa yang dia cetak, dan apa yang dia kembalikan. `quit(value: int)`
mengatur yang kedua (`lib/std/syncio.nim:538`); program yang berakhir dengan `quit(3)` keluar dengan status `3`.
Bentuk string-nya yang jadi jebakan: `quit(msg)` mencetak pesannya ke **stdout** lalu keluar `1`
(`lib/std/syncio.nim:547`), dan `quit(msg, errorcode)` mencetak lalu keluar dengan kode kamu (`:551`). Wrapper script
yang memisahkan stdout dari stderr tidak akan menemukan pesan itu di tempat yang dia cari, dan inilah satu-satunya
kebiasaan di sini yang harus dilepas pembaca Nim 2: Nim 2.4.0 dan `doc/stdlib.md:232` sama-sama mengirim pesannya
ke stderr, pin mengirimnya ke stdout.

Di belakang driver, exit nonzero dilaporkan sebagai langkah build yang gagal: `nimony c -r` mencetak
`FAILURE: nimcache/c/<hash>/main` dan melaporkan gagal, tanpa menyebut kode kamu. Baris itu milik driver, bukan
milik kamu, dan itulah sebabnya probe yang sengaja gagal terlihat seperti build rusak sampai kamu membaca output di
atasnya.

Dari sisi lain, `execShellCmd` mengembalikan exit status perintah shell yang dia jalankan (`lib/std/os.nim:373`,
`:428`), jadi `execShellCmd("exit 5")` adalah `5`. Dia mewarisi stream kamu, jadi output anak muncul tanpa
ditangkap, dan itu pilihan yang tepat ketika anaknya adalah tujuannya — formatter, test runner — bukan data yang
ingin kamu periksa. Dia juga satu-satunya routine di bab ini yang tidak raise ketika peluncurannya sendiri
gagal: tidak ada shell untuk dijalankan, dan jawabannya `-1` (`lib/std/os.nim:425-428`).

## Menjalankan program lain

`std/osproc` adalah modul untuk anak yang ingin kamu ajak bicara, dan default-nya hal pertama yang harus dipahami.
`execProcess(command, args = [...])` terlihat seperti panggilan langsung, tapi options default-nya termasuk
`poEvalCommand` (`lib/std/osproc.nim:878-882`; set-nya di `:881-882`), dan command line yang dievaluasi shell tidak
bisa sekaligus menerima daftar argumen. Kombinasi yang terlihat alami karena itu assert saat jalan, dengan pesan
`args` has to be empty when using poEvalCommand. Perbaikannya adalah memberi options eksplisit, dan dua bentuk yang
berguna:

```nim
let printed = execProcess("/usr/bin/printf", args = ["%s|", "a b", "c"],
                          options = {poUsePath})
echo printed

let (noise, code) = execCmdEx("/bin/sh -c 'echo err 1>&2; exit 7'")
echo noise.len, " ", code
```

Yang pertama mengirim argument vector: tiap elemen adalah satu entri `argv`, jadi `a b` tetap satu argumen. Yang
kedua mengevaluasi baris shell, melipat stderr ke stdout — karena itulah `poStdErrToStdOut` ada di set default —
dan mengembalikan exit code di samping output. Output-nya berakhir dengan newline, jadi `echo noise` mencetak baris
kosong setelahnya; cetak panjang, perbandingan, atau baris pertamanya saja.

Perintah yang tidak ada bukan error code dari program kamu: shell yang melaporkannya, `execCmdEx` mengembalikan
status `127` dan pesannya sebagai output. Anak yang gagal karena alasannya sendiri mengembalikan kodenya sendiri,
dan perbedaan antara "kamu tidak bisa menjalankannya" dan "dia jalan lalu gagal" adalah exit status dan tidak ada
yang lain.

Ketika output-nya besar atau datang perlahan, bongkar prosesnya: `startProcess` (`lib/std/osproc.nim:331`),
`inputStream` dan `outputStream`, lalu `readLine` selagi dia jalan dan `waitForExit` di akhir
(`lib/std/osproc.nim:438`). `peekExitCode` menjawab `-1` selama anak masih jalan (`:483`), dan begitulah loop yang
membaca output dan loop yang tidak boleh memblokir tetap terpisah. `readLines(p)` adalah kemudahan yang melakukan
keduanya dan mengembalikan `(seq[string], int)` (`lib/std/osproc.nim:866-876`). Dengan `poParentStreams` alih-alih
options penangkap, anak menulis langsung ke terminal kamu dan tidak ada yang perlu dibaca
(`lib/std/osproc.nim:363`, `:376`).

Semua di bagian ini `{.raises.}`, dan tag pada deklarasinya menjelaskan kenapa: memulai proses adalah efek, dan
`fork` yang gagal, executable yang tidak ada, atau pipe yang mati semuanya datang sebagai `ErrorCode`. Bungkus
panggilannya, bukan loop-nya.

## Nim 2 delta

*Apa yang Nim 2 lakukan:* `import std/os` memberi kamu `removeFile(file: string)`, yang diam saja ketika file tidak
ada — dia jalan sampai selesai pada path yang tidak eksis. `std/files` yang menerima path sudah ada, tapi bentuk
string selalu dalam jangkauan.
*Apa yang Nimony lakukan:* `std/os` tidak lagi membawa `removeFile`; sekarang `std/files.removeFile(file: Path)`
dan dia `{.raises.}` (`lib/std/files.nim:65`), dengan `tryRemoveFile` mengembalikan alasannya sebagai `ErrorCode`.
Dia masih toleran pada file yang tidak ada (`lib/std/files.nim:68-70`), jadi yang berubah adalah modul dan tipenya,
bukan toleransinya. Predikatnya tinggal di `std/os` dan masih menerima `string`, jadi separuh program file Nim 2
ter-compile dan separuhnya tidak. Kebiasaan exit code juga patah: `quit(msg)` menulis ke stdout di pin dan ke stderr
di Nim 2.4.0.
*Apa yang rusak kalau kamu pertahankan kebiasaannya:* `removeFile("x.txt")` menjadi
`undeclared identifier: 'removeFile'` dengan hanya `std/os` yang diimpor, dan setelah impornya diperbaiki, string-nya
type mismatch sampai jadi `path("x.txt")`. Kebiasaan mengabaikan hasilnya juga jadi compile error, karena
`ErrorCode` tidak bisa di-discard diam-diam.

## Samples

`samples/21-files-processes/files.nim`, dijalankan di commit yang dipin:

```
nimony c -r samples/21-files-processes/files.nim
```

Output yang diharapkan, yang dicetak verifier sample secara penuh:

```
6
second

13
2
13
true false
Success
false
fallback
visible
false
0
a b|c|

4 7
```

Baris demi baris: panjang `first\n` (`6`); seluruh file setelah `writeFile` kedua, yang menggantikannya (`second`,
lalu baris kosong yang ditambahkan `echo` setelah string yang sudah berakhir dengan newline); panjang setelah
menambahkan `third\n` (`13`); jumlah baris dari loop `readLine` (`2`); `getFileSize` (`13`); keberadaan sebelum dan
sesudah penghapusan (`true false` lalu `Success`, `false`); fallback dari variabel yang tidak di-set (`fallback`),
nilai yang di-set (`visible`), dan jawaban setelah dihapus (`false`); tidak ada argumen di bawah verifier (`0`);
argument vector yang dipertahankan anak (`a b|c|`, dengan newline yang `execProcess` tambahkan setelahnya); dan
stderr yang digabung plus exit code dari anak shell (`4 7`).

## Cek

1. Tulis `"alpha\n"` ke sebuah file, baca kembali, dan cetak `true` ketika panjangnya `6`. Harapan: `true`.
2. Panggil `readFile` pada nama yang kamu tahu tidak ada, tanpa `try`. Harapan: compile error yang menyebut
   `.raises`, sebelum apa pun jalan.
3. Sekarang panggil di dalam `try`. Harapan: `ErrorCode` yang tertangkap tercetak sebagai `IOError`.
4. Jalankan binary kamu dengan `one "two three"` dari shell dan cetak tiap `paramStr(i)` di dalam kurung. Harapan:
   `[one]` dan `[two three]`, dua baris.
5. Set `BOOK21_VALUE`, jalankan `/usr/bin/env` lewat `execCmdEx`, dan cari nilainya di output. Harapan: nilainya
   muncul di output anak.
6. Jalankan `quit(7)` di akhir program. Harapan: driver melaporkan `FAILURE` dan exit status binary-nya sendiri
   `7` ketika kamu jalankan langsung.

## Chapter checklist

draft 2026-11-13 · tech_review 2026-11-13 · editorial_pass 2026-11-13 · frozen 2026-11-13
