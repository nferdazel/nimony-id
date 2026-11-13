---
appendix: D
title: Sources and references
job: Name the sources this book cites, in the form its own pages cite them, so a reader can check a claim at its source instead of trusting the page.
nimony_version: 0.6.3
nimony_commit: 4ba90a781b0b22d0821efaa153c129c37cef6143
toolchain: ~/.local/opt/nimony/4ba90a7
host_compiler: ~/.local/opt/nim-2.4.0
status: frozen
tech_review: lists sources and their locations; describes no compiler behaviour
editorial_pass: 2026-11-13
samples: []
glossary_added: ["references", "daftar pustaka"]
---

# Sumber dan daftar pustaka

## Untuk apa lampiran ini

Sebuah kalimat di buku ini bersandar pada salah satu dari tiga hal: apa yang dilakukan kompiler yang di-pin, apa
yang dulu dilakukan Nim 2, atau keputusan buku ini tentang bentuknya sendiri. Dua yang pertama bisa kamu periksa
sendiri dengan repositori dan satu unduhan. Yang ketiga tertulis di `OUTLINE.md` dan `ERRATA.md`. Lampiran ini
menyebut sumbernya sekali, supaya kamu yang meragukan satu halaman tidak perlu menebak dari mana halaman itu
datang.

## Cara buku ini mengutip

Klaim tentang bahasanya membawa path dan rentang baris, relatif terhadap akar repositori kompiler di pin:
`doc/language.md:126-140`, `src/nimony/sem.nim:3305`, `lib/std/system.nim:123-126`. Alamat satu sitasi adalah
pohon berkas di commit itu, lalu path-nya, lalu rentangnya:

`https://github.com/nim-lang/nimony/blob/4ba90a781b0b22d0821efaa153c129c37cef6143/doc/language.md#L126-L140`

Kompiler hanya mencetak bentuk pendeknya, `4ba90a7`. Hash lengkapnya ada di frontmatter setiap bab sebagai
`nimony_commit`, dan itulah yang dipakai di alamat-alamat ini.

Dua batasnya perlu disebut di halaman yang sama dengan konvensinya:

- Audit di edisi ini memeriksa bahwa setiap path yang dikutip ada di pin dan setiap rentangnya jatuh di dalam
  berkasnya. Audit itu tidak memeriksa bahwa baris tersebut menopang kalimat yang mengutipnya. Itu tugas tabel
  probe `review.md` tiap bab, yang mencetak apa yang dijalankan dan apa yang keluar, satu baris per klaim.
- Sitasi bukan kutipan. Buku ini memparafrase rujukannya dan mengutip kompilernya. Jadi bukti sebuah bab adalah
  blok output dan sitasinya bersama-sama, tidak pernah sitasinya saja.

## Kompiler yang di-pin

| Item | Nilai |
| --- | --- |
| Repositori | `https://github.com/nim-lang/nimony` |
| Commit | `4ba90a781b0b22d0821efaa153c129c37cef6143`, 2026-11-12 |
| Versi | `nimony 0.6.3`, seperti yang dilaporkan kompilernya sendiri |
| Backend | `nimony c`; `nimony n` tidak ada di commit ini |
| Lisensi | MIT, berkas `LICENSE` di commit itu |

Sumber di dalam pohon itu, diurutkan dari yang paling sering dipakai bab-bab. Hitungannya adalah sitasi
`path:baris` di edisi Inggris Bab 1 sampai 24, diambil 2026-11-13.

| Sumber | Apa itu | Di mana buku ini bersandar padanya |
| --- | --- | --- |
| `doc/language.md` | Referensi bahasa yang ikut dalam kompiler; 149 sitasi | Deskripsi yang jadi titik awal hampir semua bab, sebelum sample atau probe membenarkan atau membetulkannya |
| `lib/std/system.nim` | `system`, termasuk hook yang jadi bahan `move` dan `=wasMoved`; 32 sitasi | Bab 3, 14 dan 20, dan keadaan setelah `move` yang diajarkan Bab 14 |
| `doc/differences.md` | Semua yang dihapus atau berubah dari Nim 2; 25 sitasi | Setiap kotak "Nim 2 delta", dan baris-baris Lampiran A |
| `src/nimony/sem.nim` | Pass semantik; 21 sitasi | Saat sebuah bab menjelaskan penolakan yang tidak dijelaskan referensinya, seperti aturan `elif` di Bab 6 |
| `src/nimony/contracts_fir.nim` | Analisis di balik definite assignment dan kontrak yang diperiksa; 19 sitasi | Bab 8, 15 dan 24 |
| `lib/std/syncio.nim` | Lapisan output yang dilewati `echo` dan `quit`; 17 sitasi | Baris `quit(msg)` di Bab 21, di mana pin menulis ke stdout sedangkan `doc/stdlib.md` bilang stderr |
| `doc/porting.md` | Catatan porting untuk kode yang datang dari Nim 2; 8 sitasi | Bab 11, 15 dan 18 |
| `doc/plugins.md` | Antarmuka plugin; 8 sitasi | Bab 19 |

Path lain di sebuah bab muncul untuk satu pertanyaan dan disebut di tempat pertanyaan itu: `sizeof.nim` untuk
layout variant di Bab 12, `duplifier.nim` untuk pemeriksaan last usage di Bab 14, `tables.nim` untuk hash map di
Bab 20, `unicode.nim` untuk rune di Bab 5. Kalau referensi dan kompilernya tidak sependapat, babnya mengatakan
itu dan `ERRATA.md` menyimpan barisnya.

## Kompiler host

| Item | Nilai |
| --- | --- |
| Kompiler | Nim 2.4.0, tarball resmi |
| Unduhan | `https://nim-lang.org/download/nim-2.4.0-macosx_arm64.tar.xz` |
| sha256 | `93a1e638289077b972b684e6e71cb11b2029602ccac4f8fd8dfa70f193fac7df` |
| Peran | Pembanding saja |

Nim 2.4.0 tidak pernah jadi sumber tentang apa yang dilakukan Nimony. Ia adalah pembanding kotak "Nim 2 delta",
dan kompiler yang pesannya dikutip Lampiran A di sisi lain tiap baris. Kalau keduanya berbeda, pin yang jadi
jawaban dan kompiler host hanya observasi.

## Issue di hulu

| Rujukan | Jenis | Yang dicatatnya |
| --- | --- | --- |
| `nim-lang/nimony#2985` | Issue, dibuka dan ditutup 2026-11-13 | `delay()` tanpa titik suspend setelahnya menabrak assert di `cps.nim`, bukan menghasilkan diagnostik |
| `nim-lang/nimony#2988` | Pull request, di-merge 2026-11-13 | Perbaikan `#2985`: assert-nya jadi diagnostik di call-site |

Bab 24 mengutip assert yang jadi soal issue itu, Lampiran A dan Lampiran C menyebut pasangannya, dan `review.md`
bab itu menyimpan reproduksinya. Kedua tautannya hidup di `https://github.com/nim-lang/nimony/issues/2985` dan
`https://github.com/nim-lang/nimony/pull/2988`.

## Standar yang disebut di teks

IEEE 754 satu-satunya standar luar yang disebut namanya. Bab 4 mengatakan `float` dan `float64` mengikutinya dan
bahwa pengecualian IEEE tidak dilempar di pin; buku ini tidak mengutip satu pasal pun dari standar itu dan tidak
mematok revisinya. Di tempat yang sebenarnya bisa mengutip dokumen di luar repositori, babnya mengutip hal yang
benar-benar ditemui samplenya: Bab 22 menyebut header C yang di-import — `<string.h>`, `<stdio.h>`,
`<sys/types.h>` — karena kompilernya menulis deklarasi dari situ dan tanpa header sample-nya tidak akan link.

## Catatan buku ini sendiri

| Path di repositori ini | Isinya |
| --- | --- |
| `OUTLINE.md` | Kontrak buku ini: pembaca, pin, satu pekerjaan per bab, prasyarat, dan status tiap bab |
| `ERRATA.md` | Errata terbuka, watch list berisi batasan di pin, dan koreksi editorial pada bab yang sudah beku |
| `samples/` | Satu program per bab, dikompilasi dan dijalankan di pin; Lampiran B mencatat gate-nya |
| `chapters/NN-slug/review.md` | Tabel probe per klaim di belakang sebuah bab: apa yang dijalankan, output mentahnya, baris sumbernya |
| `reviews/2026-11-13-*.md` | Review seluruh buku di belakang `v0.1.21`: editorial, teknis, cakupan sample, cakupan listing, terminologi |
| `tools/verify-samples.sh` | Verifier yang dilewati setiap sample, dan satu-satunya hal yang buku ini sebut hijau |

## Lisensi

| Materi | Lisensi | Di mana dinyatakannya |
| --- | --- | --- |
| Teks buku ini, kedua edisi | CC BY-SA 4.0 | `LICENSE`, dan `https://creativecommons.org/licenses/by-sa/4.0/` |
| Kode di `samples/` dan di setiap listing | MIT | `LICENSE-CODE`, dan `https://opensource.org/license/mit` |
| Sumber dan output kompiler yang dikutip | MIT, lisensi Nimony di pin | Disebut dengan berkas dan barisnya di tiap kutipan; teks lengkapnya `LICENSE` di pin |

Kutipan sumber ditulis dengan berkas dan baris supaya kamu bisa membandingkannya dengan commit-nya, dan output
kompiler dikutip sebagai output. Keduanya tidak didistribusikan ulang di sini sebagai berkas.

## Cara halamannya dibangun

Kedua edisi dirender dari sumber yang sama lewat Quarto 1.10.19, versi yang ditolak diganti oleh build-nya, dengan
template Typst di `assets/typst/`. Toolchain untuk sample-nya adalah yang ada di Lampiran B. Halaman yang mencetak
nomor versi atau commit menyebutkannya di tempat yang penting, bukan di sini.
