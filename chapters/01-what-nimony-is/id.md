---
chapter: 1
title: What Nimony Is
job: Give the reader a working mental model — Nimony is the Nim 3 line, built on a NIF pipeline, with plugins instead of macros — so later rules read as design choices rather than surprises.
nimony_version: 0.6.3
nimony_commit: 4ba90a781b0b22d0821efaa153c129c37cef6143
status: frozen
tech_review: Momo 2026-11-12 (10 claims at 4ba90a7: 8 PASS, 2 corrected in text)
editorial_pass: 2026-11-12
samples: []
glossary_added: [NIF, plugin, passive proc, polymorphic accessor, ErrorCode]
---

# Apa Itu Nimony

Nimony adalah implementasi baru Nim, ditulis untuk menjajaki seperti apa Nim 3 seharusnya. Ini bukan Nim 2
yang ditambal, dan ini belum selesai. Dua fakta itu menentukan cara kamu membaca semua yang menyusul: bahasa
yang akan kamu pelajari sengaja dibuat berbeda dari Nim yang mungkin kamu temui di buku, tulisan blog, dan
jawaban Stack Overflow, dan bahasa itu masih bergerak.

Chapter ini tidak punya kode. Isinya model yang diasumsikan seluruh buku, plus apa yang harus kamu lakukan
ketika dunia luar tidak setuju dengan kita.

## Satu garis bahasa, dua nama

Dokumen perbedaan milik proyek itu sendiri terbelah dua. Paruh pertamanya berjudul "The Future: Nim 3 (the
good)", dan dibuka dengan menyebut hubungannya: *Nimony* adalah implementasi yang masih dikerjakan untuk **Nim
3** (`doc/differences.md`, commit `4ba90a7`).

Kalimat itu melakukan banyak pekerjaan, jadi baca dua kali. Nimony adalah sebuah **implementasi**, bukan
dialek: ia compiler yang kamu jalankan, dengan standard library sendiri, model build sendiri, dan bug sendiri.
Dan sasarannya adalah **Nim 3**, yang belum ada sebagai bahasa rilis. Nim 2 yang bisa kamu pasang hari ini
adalah garis bahasa yang lain, dan FAQ di situsnya blak-blakan soal jaraknya: Nim 3 adalah Nimony plus kerja
kompatibilitas yang belum terjadi. Tidak ada bagian buku ini yang mengasumsikan kerja itu selesai sesuai
jadwal.

Paruh kedua dokumen yang sama berjudul "The present: Nimony (the bad)", dan isinya daftar hal yang belum bisa
dilakukan compiler. Daftar itu kita bahas sebentar lagi. Pemisahan itu layak dicatat karena jujur dengan cara
yang jarang ditemui di dokumentasi bahasa: rancangan dan kekurangan dicetak berdampingan, oleh orang yang
memegang keduanya.

## Apa yang compiler ini rancang untuk dikerjakan dengan baik

README menyebut keunggulannya tanpa banyak upacara (`README.md`, commit `4ba90a7`):

- rekompilasi inkremental
- build yang sepenuhnya paralel
- tanpa forward declaration untuk proc dan type
- generic yang di-type-check
- satu model konkurensi untuk event loop dan untuk thread
- dukungan editor

Itu bukan kata sifat pemasaran; tiap butir menghapus pekerjaan yang mungkin biasa kamu lakukan. Di Nim 2 kamu
menyusun deklarasi supaya compiler bertemu definisi sebelum pemakaiannya. Di sini tidak. Di Nim 2, rebuild
proyek besar sebagian besar memang rebuild. Di sini pipeline-nya ditata supaya sebagian besarnya bukan begitu.

Di bawahnya ada **NIF**, interchange format yang dibaca dan ditulis setiap tahap pipeline; `doc/design.md`
menyebutnya format yang dipakai untuk berkomunikasi antar fase compiler, dan tiap pass bekerja pada aliran token
NIF. Halaman filosofi desain menjabarkan untungnya: dengan NIF, banyak transformasi jadi lebih sederhana dan
bisa ditulis tanpa rekursi, dan plugin berjalan inkremental serta paralel seperti bagian lain pipeline
(nim-lang.org/araq/nimony.html, dibaca 2026-11-12). Bacalah itu sebagai argumen desain, bukan sebagai sifat yang
sudah terukur di pin ini — halamannya bertanggal 2025-05-10 dan ditulis dalam bentuk akan datang. Chapter 19
membahas artinya ketika kamu menulis plugin. Untuk sekarang akibatnya lebih kecil dan lebih berguna: tahap-tahap
compiler bisa dipisahkan, dan itulah sebabnya build berperilaku seperti kata README.

## Bahasa yang benar-benar akan kamu tulis

Tujuh perbedaan menentukan sebagian besar isi buku ini. Semuanya punya chapter sendiri; tidak ada yang jadi
catatan kaki. Sebagian besar diperdebatkan di paruh desain dokumen perbedaan, bukan di daftar yang kapal hari
ini, jadi sebuah chapter mengajarkan satu perbedaan hanya setelah perbedaan itu dibuktikan ulang di pin — untuk
itulah ada baris `tech_review` di tiap chapter.

**Nil-ability tinggal di dalam type.** Reference yang boleh nil ditulis `nil ref T`, dan reference yang tidak
boleh nil adalah type yang berbeda. Men-dereference tanpa memeriksa adalah masalah waktu compile, bukan crash
waktu jalan (Chapter 13).

**Alternatif adalah data.** `case` di dalam `object` mendapat sintaks baru, dan itulah yang memungkinkan
pattern matching bawaan. Kamu memodelkan "salah satu dari bentuk-bentuk ini" sebagai type, bukan sebagai flag
plus komentar (Chapter 12).

**Generic diperiksa, dan concept adalah cara membatasinya.** Kamu menulis `proc f[T: Concept](x: T)`, dan
batasannya diperiksa waktu compile, bukan ditemukan saat instansiasi (Chapter 17).

**Konkurensi kehilangan warnanya.** Di tempat Nim 2 menulis `async`, Nimony menulis `passive`; di tempat Nim 2
menulis `await`, kamu tidak menulis apa pun. Event loop dan multi-threading berbagi satu model (Chapter 24).

**Side effect dideklarasikan, bukan disimpulkan.** `func`, `iterator`, dan `converter` bebas side effect secara
default; `proc` tidak; tidak ada inferensi (Chapter 8 dan 15).

**Accessor bersifat polimorfik.** Nim 2 butuh satu accessor untuk container mutable dan satu lagi untuk yang
immutable. Nimony mendeklarasikan satu, ``func `[]`(x: Container): var Element``, dan membiarkan type system
melacak apakah penulisan diizinkan (Chapter 9).

**Aturan kecilnya juga berubah**, dan inilah yang diam-diam merusak kode yang kamu salin dari internet:
`string` kehilangan terminating zero dan tidak lagi terkonversi ke `cstring` tanpa salinan; identifier
case-sensitive secara default; `break` tanpa label keluar dari loop dan tidak pernah keluar dari block;
overflow integer bertanda membungkus alih-alih memunculkan `OverflowDefect`.

Dua di antaranya punya restore switch per-module: `{.feature: "ignoreStyle".}` dan
`{.feature: "anonBlockBreaks".}` mengembalikan perilaku Nim 2 untuk module yang memakainya. Perubahan `string`
tidak punya saklar apa pun, dan `{.keepOverflowFlag.}` bukan mode kompatibilitas — itu block yang membuat
`overflowFlag()` melaporkan `+`, `-`, atau `*` bertanda terakhir yang membungkus, supaya kamu bisa mendeteksi
pembungkusan yang baru saja terjadi. Deteksi bukan restorasi. Buku ini mengajarkan perilaku default di keempat
kasus tadi (Chapter 3, 4, 5, dan 6).

> **Nim 2 delta — ini bukan pengganti yang tinggal ditukar**
>
> *Apa yang dulu dilakukan Nim 2* → satu toolchain, `nim c`, dan sekumpulan kebiasaan yang berlaku antar versi.
> *Apa yang dilakukan Nimony* → implementasi terpisah pada satu commit yang dipaku, di mana `string`, overflow
> integer, effect system, dan sistem macro semuanya berperilaku berbeda dari Nim 2 yang mungkin kamu kenal.
> *Apa yang rusak kalau kebiasaannya dipertahankan* → menempel potongan kode Nim 2 lalu mengharapkannya compile
> apa adanya, membangun dengan Nim dari package manager, atau membaca dokumentasi hari ini seolah-olah itu
> menggambarkan pin ini.

## Apa yang belum ada di pin ini, dan kenapa itu batas

Pada commit yang jadi acuan buku ini, Nimony belum punya (`doc/differences.md`):

- sistem exception yang kompatibel dengan milik Nim — ia memakai sistem sendiri, berbasis enum `ErrorCode`
- effect system yang berjalan — `tags` dan `gcsafe` diabaikan, dan `raises: []` sekaligus jadi default dan
  diabaikan, sementara daftar `raises` dipetakan ke `{.raises.}`
- closure iterator
- generic implisit, yaitu routine yang tidak menulis `[T]` dan jadi generic lewat type class seperti `SomeInt`

Dan dua fitur Nim 2 sedang dalam perjalanan keluar, bukan sudah hilang di pin ini. Desainnya menggantikan macro
dengan plugin dan mengarah ke single dispatch, tetapi `macro` dan `method` masih compile dan jalan untuk
kompatibilitas Nim 2; buku ini mengajarkan plugin dan proc, dan memperlakukan `macro` yang berjalan sebagai
permukaan kompatibilitas, bukan sebagai bukti bahwa desainnya tidak berubah. Plugin yang dideklarasikan dengan
parameter `typed` berjalan setelah type checking dan menerima NIF yang sudah diperiksa secara semantik;
parameter `untyped` melewatkan kode lebih dulu.

Bacalah itu sebagai tepi peta, bukan sebagai daftar tugasmu. Kalau ada teknik yang kamu kenal bergantung pada
salah satu fitur di atas, jawaban di buku ini adalah penggantinya, bukan akal-akalan yang berpura-pura fitur itu
ada. Satu tempat yang penggantinya benar-benar keterampilan baru, bukan sekadar ganti nama, adalah Chapter 19:
plugin bukan macro dengan nama baru, dan makin cepat kamu berhenti meraih `macro`, makin tidak menyakitkan
chapter itu.

## Kenapa setiap klaim di sini membawa commit

Tag rilis terbaru adalah `v0.6.2`. Branch `master` pada commit yang dipakai buku ini melaporkan `0.6.3`. Itulah
seluruh alasan memakai commit, bukan tag: tag-nya sudah tertinggal dari compiler yang sedang dipakai orang
untuk membangun.

Jadi buku ini memaku satu commit — `4ba90a781b0b22d0821efaa153c129c37cef6143`, 12 November 2026 — yang dibangun
dari tarball resmi Nim 2.4.0, bukan paket Homebrew, yang tidak bisa membangun `nifler` dan karena itu tidak bisa
mem-parse apa pun (Chapter 2 menuntun pemasangan dan jebaknya). Setiap sample compile dan jalan lewat
`nimony c`. Backend native `nimony n` tidak ada di pin ini dan berada di luar cakupan, bukan "menyusul".

Dua aturan menyusul dari situ, dan keduanya akan kamu temui sambil membaca:

1. Klaim tentang bahasa hanya sekuat sumbernya di pin: berkas di repositori Nimony, sample yang dikompilasi dan
   dijalankan, atau review dari Engineering yang menyebut salah satunya. Di tempat buku ini belum bisa
   menyelesaikan sebuah pertanyaan, chapter-nya tetap terbuka dan mengatakannya.
2. Ketika pin bergerak dan chapter yang sudah beku rusak, kerusakannya dicatat di errata, bukan ditambal diam-diam.
   Kamu bisa mencocokkan errata dengan chapter yang sedang kamu baca dan tahu persis mana yang lebih tua.

## Cara membaca sisa buku ini

Chapter-chapter berjalan dalam satu urutan, karena tiap chapter bersandar pada yang sebelumnya. Tiga konvensi
layak diketahui sekarang.

**Delta box.** Di tempat kebiasaan Nim 2 benar-benar menyesatkan, chapter memuat box bernama "Nim 2 delta": *apa
yang dulu dilakukan Nim 2 → apa yang dilakukan Nimony → apa yang rusak kalau kamu mempertahankan kebiasaannya*.
Box itu hanya muncul di tempat ia berguna, dan tidak pernah jadi jalur utama. Kalau kamu belum pernah menulis
Nim, lewati saja; chapter-nya mengajarkan Nimony tanpanya. Kalau sudah, baca box-nya dulu, lalu kembali dan baca
chapter-nya seolah kamu belum membacanya.

**Sample adalah bukti.** Setiap blok kode yang diklaim berjalan sudah dikompilasi dan dijalankan di pin. Di
tempat sebuah sample hanya ilustrasi dan bukan hasil verifikasi, teksnya mengatakan begitu.

**Istilah dibekukan.** Kata yang punya makna khusus ada di glossary buku, dan chapter yang butuh istilah baru
menambahkannya saat itu juga. Kalau sebuah istilah terasa licin, itu bug, bukan pilihan gaya.

Chapter 2 memasang toolchain dan membuat satu program berjalan. Semua setelahnya mengasumsikan itu sudah
beres, karena buku tentang compiler yang tidak bisa mengompilasi hanyalah opini yang sangat panjang.

---

`draft 2026-11-12 · tech_review Momo 2026-11-12 · editorial_pass 2026-11-12 · frozen 2026-11-12`
