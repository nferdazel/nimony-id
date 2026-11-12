---
chapter: 2
title: The Pinned Toolchain
job: Build the pinned commit from source with the official Nim 2.4.0 tarball, compile and run a first program with `nimony c`, and recognize why Homebrew Nim and `nimony n` are both dead ends here.
nimony_version: 0.6.3
nimony_commit: 4ba90a781b0b22d0821efaa153c129c37cef6143
toolchain: /Users/sachiel/.local/opt/nimony/4ba90a7
host_compiler: /Users/sachiel/.local/opt/nim-2.4.0
status: frozen
tech_review: Momo 2026-11-12
editorial_pass: 2026-11-12
samples: ["samples/02-pinned-toolchain/hello.nim"]
glossary_added: ["pinned toolchain"]
---

# 2. The Pinned Toolchain

## Untuk apa chapter ini

Nimony sedang aktif dikembangkan, dan bahasa yang berubah tiap minggu akan diam-diam membatalkan buku mana pun
yang menyebut "Nimony" tanpa menyebut yang mana. Jadi buku ini menamai satu commit — `4ba90a781b0b`, yang
dilaporkan compiler sebagai `0.6.3` — dan setiap pernyataan di dalamnya benar untuk commit itu atau ditandai
sebagai niat desain.

Chapter ini memberimu compiler persis itu, dari source, lalu membuat satu program berjalan lewat compiler
tersebut. Ada juga satu halaman untuk dua jalan pintas yang terlihat masuk akal dan tidak bekerja: memasang Nim
dari package manager sistem, dan meminta backend native dari Nimony. Keduanya menghasilkan toolchain yang
kelihatan terpasang dan tidak mengompilasi apa pun.

Lakukan chapter ini sekali. Chapter-chapter berikutnya mengasumsikan path-nya sudah ada dan verifier mencetak
`SUMMARY n/n passed`.

## Pin adalah commit, bukan rilis

Tidak ada unduhan untuk ini. Repositori punya tag tapi tidak punya binary rilis, dan tag terbaru tertinggal
dari master: di pin, `master` melaporkan `0.6.3` sementara tag terbaru adalah `v0.6.2` (catatan toolchain
Engineering, 2026-11-12). Pakai tag di sini dan kamu sudah menggambarkan compiler yang tidak dipakai siapa pun
untuk membangun.

Dua angka mengidentifikasi pin, dan keduanya sebaiknya kamu periksa setelah build:

| Apa | Nilai |
|---|---|
| commit | `4ba90a781b0b22d0821efaa153c129c37cef6143` |
| versi yang dilaporkan | `0.6.3 [macosx; arm64]` |
| host compiler | Nim 2.4.0 resmi, `nim-2.4.0-macosx_arm64.tar.xz` |
| sha256 tarball | `93a1e638289077b972b684e6e71cb11b2029602ccac4f8fd8dfa70f193fac7df` |
| diverifikasi di | macOS arm64 saja |

String versi adalah yang lebih lemah dari keduanya. Ia berasal dari source tree, jadi branch di dekat pin bisa
melaporkan `0.6.3` sambil berperilaku lain. Perlakukan commit sebagai identitas dan versi sebagai pemeriksaan
kewajaran.

## Build

Kamu butuh Nim host untuk membangun build tool Nimony, `hastur`. Pakai tarball resmi, bukan salinan dari
package manager:

```
curl -LO https://nim-lang.org/download/nim-2.4.0-macosx_arm64.tar.xz
shasum -a 256 nim-2.4.0-macosx_arm64.tar.xz
# harap 93a1e638289077b972b684e6e71cb11b2029602ccac4f8fd8dfa70f193fac7df
tar xf nim-2.4.0-macosx_arm64.tar.xz
```

Lalu compiler-nya sendiri:

```
git clone https://github.com/nim-lang/nimony.git
cd nimony
git checkout 4ba90a781b0b22d0821efaa153c129c37cef6143
export PATH=/path/to/nim-2.4.0/bin:$PATH
nim c -r src/hastur/hastur build all
```

`build all` memakan waktu 1m02s di mesin macOS arm64 tempat buku ini dipaku. Exit `0` mengisi `bin/` dengan
pipeline: `nifler`, `nimsem`, `lengc`, `nifmake`, `niflink`, `nimony`, `hastur` dan sisanya. Nama-nama itu
kembali ke model mental Chapter 1 — NIF masuk, NIF keluar, tahap demi tahap — dan sekarang kamu punya satu
salinan tiap tahap di disk.

Pasang di tempat yang tetap. Build di bawah direktori temp sistem memang jalan dan itu sebuah kesalahan: macOS
menghapus folder temp menurut jadwalnya sendiri, dan toolchain yang hilang di tengah chapter membawa serta
verifikasimu. Taruh di path tetap seperti `~/.local/opt/nimony/4ba90a7`, dinamai menurut commit.

Periksa:

```
$ nimony --version
0.6.3 [macosx; arm64]
```

## Jebakan: jangan build dengan Nim dari package manager

Homebrew `nim 2.4.0` mengompilasi binary Nimony sendiri lalu gagal di `nifler`:

```
compiler/ast2nif.nim(19, 42) Error: cannot open file: ../dist/checksums/src/checksums/sha1
FAILURE nim c ... -o:bin/nifler src/nifler/nifler.nim
```

Sebabnya pengemasan, bukan ketidakcocokan versi. `nifler` mengimpor `ast2nif.nim` dari host compiler, dan
module itu butuh pohon `dist/checksums` di sebelahnya. Formula Homebrew tidak menyertakannya; tarball resmi
menyertakannya, bersama `dist/nimony` yang di-vendor.

Kenapa ini lebih penting dari kelihatannya: `build all` berhenti di tool pertama yang gagal, dan parser
cadangan `nifler2` dibangun paling akhir, jadi build yang mati di `nifler` tidak punya parser sama sekali.
Build-nya terlihat hampir lengkap — kamu punya executable `nimony` dan ia menjawab `--version` — dan setiap
compile tetap mati di front end. Kalau kamu melihat `FAILURE: nifler --portablePaths --deps parse hello.nim`,
inilah masalahnya, dan obatnya tarball, bukan flag.

## `nimony n` tidak tersedia di pin ini

Nimony didokumentasikan dengan dua backend, dan mudah menganggap yang native adalah yang menarik. Di commit ini
backend itu tidak ada. Build-nya mengatakan begitu, sambil lewat, dan itu layak dibaca alih-alih dilewati:

```
[build] ../nativenif not found — skipping arkham + nifasm; `nimony n` and a native boot need it (clone nim-lang/nativenif next to this repo)
```

Backend yang dirujuk nama-nama itu tinggal di repositori lain. Tanpanya tidak ada backend native untuk dipanggil,
dan menjalankan `nimony n` memberimu ini, bukan diagnostik compiler:

```
/bin/sh: arkham: command not found
nifmake: command failed (exit code 127): arkham --os:MacOSX --cpu:arm64 -o:…asm.nif …c.nif
FAILURE: …/bin/nifmake --rerun -j run --progress:50:100 nimcache/….final.build.nif
```

`arkham` adalah generator kode native, dan ia dikirim di repositori terpisah `nim-lang/nativenif`. Backend C
tidak pernah terlibat, jadi tidak ada yang perlu kamu perbaiki di sisimu.

Jadi: setiap sample di buku ini lewat `nimony c`, backend C, yang butuh `nifler` dan compiler C dan tidak butuh
apa pun lagi. `nimony n` muncul di buku ini nol kali sebagai instruksi. Ketika backend native kapal dan pin
bergerak, itu pin baru dan entri errata, bukan catatan kaki yang menjanjikan nanti.

## Program pertamamu

```
import std/syncio

echo "hello, world"
```

```
$ nimony c -r hello.nim
hello, world
```

Itulah seluruh loop yang dipakai sisa buku ini: `c` mengompilasi, `-r` menjalankan hasilnya. Dua detail layak
diketahui sekarang, karena keduanya menjelaskan kejutan-kejutan berikutnya. `std/syncio` diimpor secara
eksplisit — Nimony tidak menaruh `echo` di scope secara gratis. Dan `echo` menulis satu baris; Chapter 4 sampai
ke pertanyaan apa itu `string` di pin ini, yang bukan seperti yang diasumsikan kode Nim 2.

## Verifikasi seluruh buku, bukan cuma chapter-mu

Buku ini menyimpan sample di `samples/NN-slug/` dan membuktikannya dengan satu skrip, supaya klaim di Chapter
14 tidak bergantung pada chapter mana yang kebetulan kamu baca:

```
$ /Users/sachiel/.openmausbot/product/books/nimony-id/tools/verify-samples.sh
toolchain /Users/sachiel/.local/opt/nimony/4ba90a7/bin/nimony 0.6.3 pin 4ba90a7
PASS samples/02-pinned-toolchain/hello.nim exit=0
SUMMARY 1/1 passed, 0 failed
```

Skrip memeriksa commit sebelum mengompilasi apa pun, mengompilasi dan menjalankan setiap sample lewat
`nimony c -r`, mencetak satu baris per berkas, dan keluar non-nol kalau ada sample yang gagal — `0` semua lulus,
`1` ada sample gagal, `2` toolchain tidak ada atau bukan pin. Jalankan setelah setiap perubahan pada
pemasanganmu; ringkasan hijau adalah satu-satunya bukti yang diterima buku ini bahwa sebuah sample bekerja.

Satu batas yang jujur: verifier membuktikan compile, run, dan exit code. Ia tidak membandingkan stdout. Di
tempat sebuah chapter mengajarkan output yang bisa diamati, chapter-nya menyebutkan output yang diharapkan dan
pemeriksaan yang membuktikannya.

## Sample

- `samples/02-pinned-toolchain/hello.nim` — dibuktikan oleh `tools/verify-samples.sh`:

  ```
  PASS samples/02-pinned-toolchain/hello.nim exit=0
  ```

## Latihan

1. Build pin di path tetap lalu jalankan `nimony --version`. Harapan: `0.6.3 [macosx; arm64]`. Kalau versinya
   lain, kamu checkout commit yang lain — jalankan `git rev-parse HEAD` dan bandingkan.
2. Coba sekali build dengan Nim dari package manager, kalau kamu ingin melihat kegagalannya sendiri. Harapan:
   build `nifler` gagal dan menyebut `../dist/checksums/...`, lalu setiap compile berikutnya mati di tahap
   parse. Setelah itu buang build tersebut.
3. Jalankan `nimony n hello.nim`. Harapan: `/bin/sh: arkham: command not found`, satu baris `nifmake` dengan
   exit code 127, dan `FAILURE` di akhir. Itu jawaban di pin ini, bukan kesalahan pemasangan di sisimu.
4. Jalankan verifier sample dari direktori yang bukan folder buku. Harapan: tiga baris yang sama, ringkasan yang
   sama — skripnya mencari path-nya sendiri.

## Checklist chapter

draft 2026-11-12 · tech_review Momo 2026-11-12 · editorial_pass 2026-11-12 · frozen 2026-11-12
