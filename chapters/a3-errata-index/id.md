---
appendix: C
title: The errata index
job: Say what an erratum is in this book, where the list lives, and how a reader reports one, so a frozen page is corrected in public rather than quietly rewritten.
nimony_version: 0.6.3
nimony_commit: 4ba90a781b0b22d0821efaa153c129c37cef6143
toolchain: ~/.local/opt/nimony/4ba90a7
host_compiler: ~/.local/opt/nim-2.4.0
status: frozen
tech_review: restates the ERRATA.md rule; no technical claim
editorial_pass: 2026-11-13
samples: []
glossary_added: []
---

# Indeks errata

## Aturannya

Bab yang sudah beku tidak ditulis ulang. Bab 1 sampai 24 beku di `4ba90a7`, dan pin tidak bergerak di bawah
mereka: kalau build kompiler berikutnya mengubah perilaku yang diajarkan buku ini, babnya tetap mengajarkan apa
yang benar saat ia terbit, dan perubahannya dicatat sebagai erratum. Pembaca yang memeriksa satu klaim terhadap
`nimony` yang lebih baru menemukan penjelasannya di halaman yang ia baca, bukan perbedaan yang diam-diam.

Itu biaya yang disengaja. Buku yang menyunting dirinya mengikuti kompiler tidak punya edisi yang bisa
diverifikasi, dan seluruh kalimat buku ini berdiri di atas satu commit.

## Di mana daftarnya

`ERRATA.md` di repositori buku. Isinya tiga bagian:

- **Open errata** — kerusakan yang ditemukan setelah bab beku. Satu baris pada edisi ini: Bab 23 menyebut
  `{.assert: cond.}` sebagai statement yang diterima, padahal di pin klaimnya juga harus terbukti, dan kalimatnya
  dikoreksi di `v0.1.19`.
- **Watch list** — masalah yang sudah diketahui di pin sebelum bab mana pun terbit. Ini batasan cara menulis bab,
  bukan koreksi: perilaku yang terdokumentasi tapi tidak ada di pin, pesan yang menyebut alasan keliru, atau
  pemeriksaan yang tidak eksis. Setiap baris menyebut buktinya, kalimat yang karena itu boleh dicetak buku, dan
  bab yang terikat.
- **Editorial corrections** — perubahan pada bab yang sudah beku tanpa menyentuh pin, di mana babnya benar tentang
  kompiler dan halamannya yang salah: edisinya, tanda kutip pada diagnostik yang dikutip, atau listing yang
  mencetak sesuatu yang tidak dihasilkan sample-nya.

## Bentuk satu baris

Satu baris per kerusakan, dengan bab dan bagiannya, apa yang rusak, versi atau commit tempat ia rusak, tanggal, dan
status. Baris membawa baris sumber kalau perilakunya bisa dibaca di kode kompiler, dan run mentah kalau harus
diamati. Kerusakan tanpa keduanya tidak masuk: "tiba-tiba tidak jalan lagi" bukan erratum sampai ada yang
menyebutkan apa yang berubah.

Cacat yang ditemukan saat menulis buku dipisahkan dari errata. Celah dokumentasi adalah baris yang mengatakan
manualnya salah dan kalimat buku berdiri. Cacat kompiler adalah baris yang mengatakan kompilernya salah dan babnya
mengajar di sekitarnya — dan, kalau layak, sebuah issue upstream. Satu cacat seperti itu sudah di-file pada edisi
ini: `delay()` tanpa titik suspensi setelahnya menghentikan pembangkitan kode dengan assertion alih-alih
diagnostik, `nim-lang/nimony#2985`, dengan perbaikannya di `nim-lang/nimony#2988`. Babnya tetap mengutip assertion
itu, karena pin masih menghasilkannya.

## Melaporkan satu

Buka issue di repositori buku dengan babnya, kalimatnya, versi dan commit toolchain, serta perintah yang
output-nya membantah halaman itu. Klaim tentang kompiler butuh berkas sumber atau commit di belakangnya; klaim
tentang prosa butuh halamannya. Editor memutuskan apakah itu erratum, cacat, atau koreksi editorial, dan menulis
barisnya pada edisi berikutnya.
