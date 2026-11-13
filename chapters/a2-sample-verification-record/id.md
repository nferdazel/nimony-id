---
appendix: B
title: The sample verification record
job: Record the exact command, pin and output format behind every code sample in this book, so a reader can reproduce a chapter's evidence instead of trusting the page.
nimony_version: 0.6.3
nimony_commit: 4ba90a781b0b22d0821efaa153c129c37cef6143
toolchain: ~/.local/opt/nimony/4ba90a7
host_compiler: ~/.local/opt/nim-2.4.0
status: frozen
tech_review: Momo 2026-11-12 to 2026-11-13, chapter by chapter; this appendix restates the verifier behaviour Chapter 23 teaches
editorial_pass: 2026-11-13
samples: []
glossary_added: []
---

# Catatan verifikasi sampel

## Untuk apa lampiran ini

Buku pemrograman adalah klaim tentang sebuah kompiler. Buku ini membuat klaim itu dalam satu bentuk saja: setiap
sampel di `samples/` dikompilasi dan dijalankan oleh satu skrip terhadap satu toolchain, dan sebuah bab tidak beku
sebelum run itu hijau. Lampiran ini adalah catatan arti "hijau", perintahnya, dan bentuk outputnya di pin — hal
yang sama yang dibutuhkan pembaca untuk memeriksa buku alih-alih memercayainya.

## Pin

| Item | Nilai |
| --- | --- |
| Kompiler | `nimony` 0.6.3 |
| Commit | `4ba90a781b0b22d0821efaa153c129c37cef6143` (2026-11-12) |
| Path toolchain | `~/.local/opt/nimony/4ba90a7`, tetap; `$NIMONY_HOME` menimpanya dan diperiksa terhadap pin yang sama |
| Kompiler host | Nim 2.4.0, tarball resmi, sha256 `93a1e638289077b972b684e6e71cb11b2029602ccac4f8fd8dfa70f193fac7df` |
| Backend yang dipakai | Hanya `nimony c`; `nimony n` tidak ada di pin ini dan di luar cakupan |

Path-nya tetap dengan sengaja. Toolchain di direktori sementara, Nim dari Homebrew, atau checkout kedua dari commit
yang sama bukan pin: skrip menolak kompiler yang versi atau commit-nya tidak cocok, dan menolaknya sebelum
mengompilasi apa pun.

## Perintahnya

Dari akar repositori buku:

```
./task verify            # atau: bash tools/verify-samples.sh
```

`./task check` menjalankan verifier yang sama lalu merender kedua edisi; itulah gerbang sebelum commit. Kedua
perintah mencari toolchain lewat `$NIMONY_HOME` dan jatuh ke `~/.local/opt/nimony/4ba90a7`.

## Arti outputnya

Verifier membaca setiap `samples/*/*.nim`, mengompilasi masing-masing dengan `nimony c -r`, dan mencetak satu baris
per sampel diikuti ringkasan:

```
toolchain ~/.local/opt/nimony/4ba90a7/bin/nimony 0.6.3 pin 4ba90a7
PASS samples/02-pinned-toolchain/hello.nim exit=0
...
SUMMARY 23/23 passed, 0 failed
```

Tiga exit code, dan ketiganya tidak bisa ditukar:

- **0** — semua sampel kompil dan jalan.
- **1** — ada sampel yang gagal; baris yang gagal menyebut sampelnya dan exit code-nya.
- **2** — toolchain tidak ada atau bukan pin. Ini bukan putusan tentang sampel, dan ringkasan yang tampak hijau
  mustahil: skrip berhenti sebelum mengompilasi.

**Exit code sampel adalah seluruh putusannya.** Output yang diharapkan sebuah bab dicocokkan dengan blok yang
tercetak di bab itu, byte per byte, oleh editor dan independen oleh reviewer; verifier sendiri hanya menilai status
exit, karena nilai tercetak yang sekadar masuk akal justru hal yang tidak boleh diterima buku.

Satu akibat `nimony c -r` penting saat membaca exit code mana pun di buku ini: driver mengubah exit non-nol anak
jadi `1` dan mencetak `FAILURE: <path biner>`, sementara biner hasil kompilasi menyimpan kode yang sebenarnya. Bab
yang mengajarkan status exit tertentu mengatakan bahwa status itu datang dari biner di `nimcache/c/<hash>/main`,
bukan dari driver. Temuan itu ada di Bab 23.

## Run di pin

Output lengkap `./task verify`, 2026-11-13, macOS arm64, direktori home disingkat jadi `~`:

```
toolchain ~/.local/opt/nimony/4ba90a7/bin/nimony 0.6.3 pin 4ba90a7
PASS samples/02-pinned-toolchain/hello.nim exit=0
PASS samples/03-values-names-mutability/values.nim exit=0
PASS samples/04-numbers-types-conversion/numbers.nim exit=0
PASS samples/05-strings/strings.nim exit=0
PASS samples/06-branching/branching.nim exit=0
PASS samples/07-loops-ranges/loops.nim exit=0
PASS samples/08-procedures/procedures.nim exit=0
PASS samples/09-overloading/overloading.nim exit=0
PASS samples/10-arrays-sequences-tuples/collections.nim exit=0
PASS samples/11-objects-enums-distinct/objects.nim exit=0
PASS samples/12-sum-types-case/sumtypes.nim exit=0
PASS samples/13-references-pointers-nil/refs.nim exit=0
PASS samples/14-ownership-borrow/ownership.nim exit=0
PASS samples/15-errors-as-values/errors.nim exit=0
PASS samples/16-modules-visibility/modules.nim exit=0
PASS samples/17-generics-concepts/generics.nim exit=0
PASS samples/18-templates-compiletime/templates.nim exit=0
PASS samples/19-plugins-nif/plugins.nim exit=0
PASS samples/20-stdlib/stdlib.nim exit=0
PASS samples/21-files-processes/files.nim exit=0
PASS samples/22-cinterop/cinterop.nim exit=0
PASS samples/23-testing/testing.nim exit=0
PASS samples/24-passive-procs/passive.nim exit=0
SUMMARY 23/23 passed, 0 failed
```

Dua puluh tiga sampel untuk dua puluh empat bab, dan jumlah itu bukan salah hitung: Bab 1 tidak punya sampel. Bab
itu yang mengatakan apa itu Nimony, dan sampel di sana berarti harus jalan sebelum pembaca punya toolchain.

## Bab mana di belakang sampel mana

| Bab | Sampel | Catatan |
| --- | --- | --- |
| 2 | `samples/02-pinned-toolchain/hello.nim` | Membuktikan build dan run, bukan apa pun tentang bahasanya. |
| 3 | `samples/03-values-names-mutability/values.nim` | |
| 4 | `samples/04-numbers-types-conversion/numbers.nim` | Wrap adalah poin ajarnya, jadi sampelnya menjalankan wrap. |
| 5 | `samples/05-strings/strings.nim` | |
| 6 | `samples/06-branching/branching.nim` | |
| 7 | `samples/07-loops-ranges/loops.nim` | |
| 8 | `samples/08-procedures/procedures.nim` | |
| 9 | `samples/09-overloading/overloading.nim` | |
| 10 | `samples/10-arrays-sequences-tuples/collections.nim` | |
| 11 | `samples/11-objects-enums-distinct/objects.nim` | |
| 12 | `samples/12-sum-types-case/sumtypes.nim` | |
| 13 | `samples/13-references-pointers-nil/refs.nim` | |
| 14 | `samples/14-ownership-borrow/ownership.nim` | |
| 15 | `samples/15-errors-as-values/errors.nim` | |
| 16 | `samples/16-modules-visibility/modules.nim` | Satu-satunya sampel yang lebih dari satu berkas: modul pendukungnya ada di `support/`. |
| 17 | `samples/17-generics-concepts/generics.nim` | |
| 18 | `samples/18-templates-compiletime/templates.nim` | |
| 19 | `samples/19-plugins-nif/plugins.nim` | Plugin-nya ada di `deps/shape` dan dibangun selama run. |
| 20 | `samples/20-stdlib/stdlib.nim` | |
| 21 | `samples/21-files-processes/files.nim` | Membuat direktori sementara, membaca dan menulis berkas, dan menjalankan subproses. |
| 22 | `samples/22-cinterop/cinterop.nim` | Sengaja satu berkas, tanpa `{.compile.}` dan tanpa callback: bentuk callback jadi prosa di Bab 22 karena hanya diukur dengan clang. |
| 23 | `samples/23-testing/testing.nim` | |
| 24 | `samples/24-passive-procs/passive.nim` | Satu berkas, satu thread, tanpa I/O; thread pool jadi prosa. |

`review.md` di samping teks setiap bab menyimpan tabel probe per klaim yang berdiri di belakang sampel-sampel ini:
apa yang dijalankan, output mentahnya, dan baris sumber Nimony untuk hal yang output mentahnya saja tidak bisa
jelaskan.

## Menambah sampel

Sampel baru adalah satu berkas, `samples/NN-slug/nama.nim`, dengan output yang diharapkan tercetak di bagian
**Samples** bab itu dan diulang di catatan review. Ia dibuktikan oleh perintah yang sama, dan barisnya bergabung ke
blok output di atas. Tidak ada sampel yang dikecualikan, dan tidak ada bab yang beku di atas sampel yang dijalankan
dengan tangan.
