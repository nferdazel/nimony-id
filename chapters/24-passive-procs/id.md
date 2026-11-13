---
chapter: 24
title: Passive Procs and Concurrency
job: Suspend and resume work with passive procs, the single mechanism standing in for both async and threaded procedures, and state the scheduling limit instead of implying parallelism.
nimony_version: 0.6.3
nimony_commit: 4ba90a781b0b22d0821efaa153c129c37cef6143
toolchain: ~/.local/opt/nimony/4ba90a7
host_compiler: ~/.local/opt/nim-2.4.0
status: frozen
tech_review: Momo 2026-11-13
editorial_pass: 2026-11-13
samples: [samples/24-passive-procs/passive.nim]
glossary_added: [passive proc, continuation, park, scheduler, state function, trampoline]
---

# Passive Proc dan Concurrency

## Untuk apa chapter ini

Nimony punya satu mekanisme untuk pekerjaan yang berhenti sejenak: pragma `.passive`. Passive proc dikompilasi
jadi state machine yang bisa berhenti di titik pilihan, menyerahkan nilai balik ke siapa pun yang menjalankannya,
dan melanjutkan nanti dari baris yang sama dengan local-nya utuh. Tidak ada `async` dan tidak ada `await`:
halaman differences mengatakannya lugas, "instead of `async` write `passive`" (`doc/differences.md:8-11`), dan
halaman design menaruh passive proc di tempat Nim 2 menaruh async sekaligus thread procedure
(`doc/design.md:97-101`).

Dua hal tidak boleh lo anggap, karena dua-duanya tidak benar di pin. Passive proc tidak otomatis concurrent:
dengan scheduler default, panggilan dari kode biasa menjalankan satu rantai state sampai habis (`advance`
memindahkan satu state), jadi dua passive proc bergiliran hanya kalau kode yang menggerakkannya bergiliran. Dan
proc yang park tidak melanjutkan dirinya sendiri: harus ada yang memegang continuation-nya dan menjalankannya
lagi. Chapter ini mengajarkan suspend, resume, dan batas scheduler, dan menyebut di mana batasnya alih-alih
mengisyaratkan pekerjaan jalan paralel.

## Procedure yang bisa berhenti sejenak

Pragma-nya dipasang di `proc` biasa. Tidak ada bagian lain dari body yang berubah:

```nim
import std/syncio

proc double(x: int): int {.passive.} =
  result = x * 2

echo double(21)
```

Itu mencetak `42`. Dipanggil dari kode biasa, passive proc yang tidak pernah suspend berperilaku seperti
panggilan biasa: pemanggilnya dapat nilainya lalu lanjut. Compiler mengubah panggilan dari routine non-passive
jadi panggilan `complete` (`src/hexer/cps.nim:116-200`), dan `complete` menjalankan coroutine itu di thread
pemanggil sampai selesai — atau, kalau coroutine-nya park, sampai siapa pun yang memegang continuation-nya
melanjutkannya (`lib/std/system.nim:340-370`).

Passive proc yang memanggil passive proc juga jalur normal, dan urutannya urutan yang lo tulis:

```nim
proc inner(n: int): int {.passive.} =
  echo "inner ", n
  result = n + 1

proc outer() {.passive.} =
  echo "outer start"
  let a = inner(1)
  echo "outer got ", a
  echo "outer end"

outer()
```

```
outer start
inner 1
outer got 2
outer end
```

Tapi panggilannya juga titik suspend. Saat callee park, pemanggilnya ikut park, dan frame pemanggilnya menunggu
di heap, bukan di hardware stack (`src/hexer/cps.nim:200-210`). Itulah mekanisme di balik dua bagian berikutnya.

## delay membangun continuation, complete menjalankannya

`delay(call)` membangun coroutine tanpa menjalankannya, dan `complete(c)` menjalankannya:

```nim
let c = delay(solo("a"))
echo "built, not run"
complete(c)
```

`solo("a")` tidak mencetak apa pun sebelum `complete`; seluruh body-nya jalan di dalam `complete`. `delay`
signature-nya `func delay*(x: typed): Continuation` (`lib/std/system.nim:277`), dan doc-nya menyebut hasilnya "a
continuation representation of this call" (`:272-278`). Dua coroutine yang di-complete berurutan tidak
menginterleave apa pun:

```
start a
end a
start b
end b
```

Itu defaultnya, dan layak dibaca sebagai aturan, bukan kebetulan. `complete` membuat `Join` miliknya sendiri
sebagai pemanggil coroutine-nya, lalu men-trampoline coroutine itu di thread ini sampai selesai *atau park*, dan
kalau park dia menunggu yang melanjutkannya (`lib/std/system.nim:340-370`). Coroutine yang park dan tidak pernah
dilanjutkan apa pun mengubah `complete` jadi tunggu tanpa akhir: program mencetak semuanya sampai park lalu diam.
Itu bukan deadlock yang bisa dilihat compiler, dan itu cara paling umum program passive pertama lo hang.

Jadi: `complete` untuk coroutine yang tidak bisa park. Kalau callee-nya bisa park, lo yang menggerakkannya, dan
itu bagian berikutnya.

## Park di titik yang lo pilih

`delay()` tanpa argumen menangkap sisa proc yang sedang jalan, dari titik panggilannya sampai titik suspend
berikutnya, sebagai continuation (`lib/std/system.nim:272-275`). `suspend()` mem-park coroutine-nya (`:281-283`).
Pasangan itu jabat tangan: tangkap mau balik ke mana, lalu park.

```nim
var resumeCont: Continuation

proc worker(name: string) {.passive.} =
  echo "start ", name
  resumeCont = delay()
  suspend()
  echo "resumed ", name
```

Compiler menurunkan `delay()` jadi continuation yang menunjuk state function berikutnya, dan `suspend()` jadi
return `Continuation(fn: nil, env: this)` (`src/hexer/cps.nim:264-285`). `env` itulah yang membedakan
continuation yang park dari yang sudah selesai:

| Continuation | `parked` | `finished` | `stopping` |
| --- | --- | --- | --- |
| nil (`fn` nil, `env` nil) | `false` | `true` | `true` |
| parked (`fn` nil, `env` ada) | `true` | `false` | `true` |
| runnable (`fn` ada) | `false` | `false` | `false` |

Ketiga predikatnya didefinisikan di `lib/std/system.nim:421-433`.

Dua-duanya harus ada di body yang sama, dan pin menegakkan pasangannya secara asimetris. `suspend()` telanjang
tanpa `delay()` sebelumnya sama sekali bukan park: compiler memperlakukannya sebagai transisi sinkron ke state
berikutnya, jadi kode sesudahnya jalan di lintasan yang sama (`src/hexer/cps.nim:272-280`; probe yang mencetak
sebelum dan sesudah `suspend()` telanjang mencetak dua baris itu dan kembali normal). `delay()` tanpa titik
suspend sesudahnya lebih buruk: compiler meng-assert saat menghasilkan kode lalu mati dengan

```
'state != -1' delay() no-arg must precede suspension point
```

(`src/hexer/cps.nim:269`). Satu bagian diabaikan diam-diam, yang lain membuat compiler mati. Tulis dua-duanya
bersama.

## Menggerakkan coroutine yang park

Begitu `worker` park, continuation yang tersimpan di `resumeCont` adalah continuation yang runnable: `fn`
menunjuk state sesudah `suspend()`, `env` menunjuk frame coroutine-nya. Menjalankannya melanjutkan proc di baris
sesudah `suspend()`, dengan setiap local masih memegang nilainya. Driver adalah loop atas `advance`, yang meminta
scheduler tepat satu transisi state (`lib/std/system.nim:300-303`):

```nim
proc drive(c: Continuation) =
  var c = c
  while not stopping(c):
    c = advance(c)

drive(delay(worker("a")))
echo "parked"
drive(resumeCont)
echo "done"
```

```
start a
parked
resumed a
done
```

Local-nya selamat melewati park karena diangkat ke frame coroutine: counter yang `1` sebelum `suspend()` dan
di-increment sesudahnya mencetak `42`, bukan `1` dan bukan crash. Itu bedanya continuation dengan callback yang
disimpan: stack frame, variabel, dan posisinya kembali bersama-sama.

## Dua coroutine, satu thread

Tidak ada apa pun di bahasa yang memilih interleaving. `advance` memanggil scheduler yang aktif, dan defaultnya
`trivialTick`, yang menjalankan tepat continuation yang diberikan (`lib/std/system.nim:285-286`). Ganti dengan
`setScheduler` (`:295-298`) dan lo bisa menghitung atau membelokkan setiap langkah; scheduler penghitung di
sekitar proc yang echo, suspend, lalu echo lagi melihat dua tick. Yang tidak bisa dilakukan scheduler sendirian
adalah membuat coroutine yang park jadi runnable lagi, karena titik resume-nya tinggal di coroutine, bukan di
scheduler.

Interleaving karena itu sifat driver, bukan sifat pragma. Park dua worker, lalu jalankan continuation
tersimpannya dalam urutan yang lo pilih:

```nim
drive(delay(worker("a", 0)))
drive(delay(worker("b", 1)))
echo "both parked"
drive(resumeA)
drive(resumeB)
```

```
a 1
b 1
both parked
a 2
b 2
```

Dua-duanya dimulai, dua-duanya park, dan paruh kedua masing-masing jalan setelah paruh pertama keduanya. Tukar
dua `drive` terakhir itu dan `b 2` datang lebih dulu. Sample buku ini mengambil bentuk yang sama dengan dua
worker, dan di sana `worker c end` datang sebelum `worker b end` karena driver melanjutkan `c` lebih dulu.
Scheduler yang menentukan, dan di sini scheduler-nya adalah lo.

Pin juga membawa thread pool, `std/threadpool`, dengan `initPool`, `submit(continuation)`, dan `shutdownPool`
(`lib/std/threadpool.nim:114`, `:198`, `:376`, `:417`). Continuation yang diserahkan ke pool jalan di worker,
dan begitulah modul IO di-resume dari polling thread. Dia scheduler, bukan janji: dua coroutine yang diserahkan
ke pool dua worker tetap bisa selesai bergantian, seperti probe-nya, karena pekerjaan non-blocking jalan langsung
sampai habis di worker mana pun yang mengambilnya. Pekerjaan yang benar-benar memblokir itu tempat overlap
kelihatan — dua task yang masing-masing `sleep(200)` selesai bersamaan dalam waktu sekitar itu, bukan dua kali
lipat — jadi overlap adalah sifat dari apa yang dikerjakan task-nya, dan chapter ini tidak pernah menjanjikannya
dari pragmanya saja. Halaman passive-procs memperingatkan bahwa scheduler yang men-dispatch continuation tak
terkait di dalam trampoline menahan stack frame perantara tetap hidup (`doc/passive_procs.md:149-161`). Buku ini
tidak mengajarkan bahwa menyerahkan dua proc membuat mereka overlap. Dia mengajarkan di mana keputusannya tinggal.

## Rantai passive proc

Saat passive proc memanggil yang lain, park di dalamnya merambat ke luar:

```nim
proc inner() {.passive.} =
  echo "inner 1"
  innerCont = delay()
  suspend()
  echo "inner 2"

proc outer() {.passive.} =
  echo "outer 1"
  inner()
  echo "outer 2"

drive(delay(outer()))
echo "outer parked"
drive(innerCont)
```

```
outer 1
inner 1
outer parked
inner 2
outer 2
```

Melanjutkan continuation yang di dalam menyelesaikan proc yang di dalam *dan* melanjutkan yang di luar, karena
setiap state mengembalikan continuation pemanggilnya saat tidak punya langkah berikutnya
(`src/hexer/coro_transform.nim:600-608`). Satu `drive` menyelesaikan seluruh rantai: rantainya bukan kumpulan
task independen, dia satu stack coroutine yang tinggal di heap.

## Apa yang compiler tulis

State machine-nya kelihatan di C hasil generate. Mengompilasi berkas dengan satu passive proc bernama `worker`
menghasilkan struct `workerX60Qcoro` yang memegang `CoroutineBase`, dan state function bernama `workerX60Qs0`
serta, saat proc-nya suspend, `workerX60Qs1`:

```
typedef struct workerX60Qcoro_0_mai3r4ykk{
CoroutineBase_0_sysvq0asl Q;
...
Continuation_0_sysvq0asl workerX60Qs0_0_mai3r4ykk(workerX60Qcoro_0_mai3r4ykk*...
Continuation_0_sysvq0asl workerX60Qs1_0_mai3r4ykk(workerX60Qcoro_0_mai3r4ykk*...
```

Frame-nya dialokasikan di heap saat passive proc memanggil yang lain (`allocFrame`, `src/hexer/cps.nim:200-210`),
dan di stack saat kode biasa memanggilnya, karena pemanggil itu menunggu hasilnya dan frame-nya sendiri hidup
sepanjang panggilan (`src/hexer/cps.nim:155-200`). Pembungkus heap menandai frame-nya dengan menunjuk `callee` ke
frame itu sendiri; jalur stack membiarkan field itu nil. Penanda itulah seluruh tesnya: `deallocFrame`
membebaskan frame saat `callee` tidak nil dan tidak melakukan apa pun selain itu (`lib/std/system.nim:706-709`).
Bentuk stack aman justru karena pemanggilnya diam di tempat sepanjang panggilan, dan bentuk itu salah untuk
coroutine yang mau lo park lalu lanjutkan nanti, di mana frame-nya akan hidup lebih lama dari pemanggilnya.

Trampoline itulah yang menjaga rantai panjang tidak menghabiskan stack: setiap state kembali ke loop alih-alih
memanggil state berikutnya (`doc/passive_procs.md:468-471`). Loop berisi seratus ribu panggilan passive biasa
selesai di probe, dan rantai panggilan rekursif sepanjang itu tidak akan selesai.

## Apa yang pin tolak, dan kenapa

Tiga penolakan menangkap kebiasaan Nim 2 sebelum jadi crash.

`delay` tidak boleh menerima callee yang parameternya mengalias frame pemanggil. Parameter `var`, `out`, dan
`lent` disimpan sebagai pointer telanjang di frame coroutine, dan frame itu bisa hidup lebih lama dari call
site-nya:

```
Error: `delay` hands `bump` to a scheduler, so its continuation can outlive this frame;
parameter `x: var int64` would alias a location that is already gone. Take it as `sink` instead
```

(`src/nimony/sem.nim:3885-3906`, `:3929-3935`). Proc yang sama yang dipanggil biasa, bukan lewat `delay`, aman,
karena frame pemanggilnya tetap hidup sepanjang panggilan. Ambil parameternya sebagai `sink` kalau coroutine-nya
harus memiliki nilai itu.

`delay` tidak boleh menerima callee yang mengembalikan nilai atau raise, karena nilainya atau errornya tidak
punya tempat tujuan setelah ekspresi pembangunnya hilang:

```
Error: `delay` hands `calc` to a scheduler, which runs it after this expression is gone;
`calc` returns `int64`, but nothing can receive the value there. Handle it inside the task instead
```

(`src/nimony/sem.nim:3908-3927`). Passive proc yang mengembalikan nilai aman kalau dipanggil dari kode biasa,
seperti contoh pertama tadi; `delay`-nya yang tidak bisa membawa hasil. Tulis hasilnya ke objek heap milik
driver, atau simpan di dalam task-nya: parameter `sink` tidak bisa menyerahkan nilai balik ke pemanggil. Atau
panggil proc-nya langsung dan biarkan `complete` menunggu.

Passive proc bukan proc value biasa. `let f = worker` tetap bertipe `proc ... {.passive.}`, dan menyerahkan tipe
itu ke tempat yang mengharapkan `proc (x: int): int {.nimcall.}` ditolak dengan ``[1] `.passive` mismatch``
(`src/nimony/sigmatch.nim:245`): calling convention-nya beda, dan compiler tidak mengonversi yang satu ke yang
lain. Rutenya pembungkus kecil non-passive yang memanggil passive proc-nya, dan di situ juga tunggu `complete`
jadi kelihatan.

Satu aturan lagi datang dari janji single-threaded Chapter 16 dan berlaku tanpa perubahan: passive proc yang
menyentuh variabel mutable di level modul kena pemeriksaan global unsynchronized, karena coroutine-nya bisa jalan
di thread lain. Probe chapter ini kena saat menyimpan `delay()` ke `Continuation` di level modul:

```
Error: unsynchronized access to global variable 'resumeCont'; pass it to a `.sync` routine or use
`{.cast(assumeSync).}`
```

(`src/nimony/contracts_fir.nim:4119-4128`). Sample-nya memakai `{.feature: "assumeSync".}` di level modul, dan
itu janji yang dibuat pool milik compiler untuk dirinya sendiri (`lib/std/threadpool.nim:12`). Di kode nyata,
simpan continuation-nya di `ref object` milik driver — sel heap bukan milik siapa pun selain driver, jadi tidak
butuh janji — atau simpan di dalam driver-nya. `assumeSync` untuk global yang memang harus tetap global.

## Delta Nim 2

*Apa yang Nim 2 lakukan:* proc `async`, `await`, future dari `std/asyncdispatch`, dan `thread`/`spawn` untuk
kerja paralel. Callback atau future adalah pegangan ke pekerjaan yang belum selesai.

*Apa yang Nimony lakukan:* `.passive` menggantikan `async` (`doc/differences.md:8-9`); `Continuation`
menggantikan future; `delay` dan `complete` menggantikan spawn task; dan pragma yang sama menutup pekerjaan yang
dulu dilakukan thread procedure, karena continuation yang sama bisa diserahkan ke pool. `std/asyncdispatch` tidak
ada di pin, dan `await` adalah identifier yang tidak dideklarasikan.

*Apa yang rusak kalau lo mempertahankan kebiasaan lama:* `import std / [asyncdispatch]` jadi berkas yang tidak
ketemu; `await` gagal di pemakaian pertama; dan korban sebenarnya adalah model mental, karena `complete`
memblokir. Kode Nim 2 menunggu lalu jalan terus, sementara panggilan passive dari kode biasa menunggu seluruh
rantai, termasuk park-nya. Kode yang ditulis seolah panggilannya kembali lebih awal akan hang, bukan lanjut.

## Samples

`samples/24-passive-procs/passive.nim`, dijalankan di commit yang dipin:

```
nimony c -r samples/24-passive-procs/passive.nim
```

Output yang diharapkan, yang dicetak verifier sample secara penuh:

```
double 21 = 42
built, not run
solo a start
solo a end
worker b start
worker c start
both parked
worker b end
worker c end
done
```

Baris per baris: passive proc yang dipanggil dari kode biasa mengembalikan nilainya; `delay` membangun tanpa
menjalankan; `complete` menjalankan coroutine yang tidak pernah park; dua worker mulai lalu park; driver
melanjutkan mereka dalam urutan yang dia pilih; dan programnya keluar `0`, dan itu yang dibaca verifier.
Sample-nya memakai `{.feature: "assumeSync".}` karena continuation resume-nya adalah variabel di level modul,
seperti yang aturan di atas minta.

## Latihan

1. Tulis proc `.passive` yang mengembalikan `x + 1` lalu panggil dari kode biasa. Harapan: nilainya, tanpa park.
2. Bangun panggilan yang sama dengan `delay`, cetak satu baris, lalu `complete`. Harapan: baris cetakannya lebih
   dulu.
3. Taruh `suspend()` di callee lalu `complete`. Harapan: program mencetak sampai park lalu hang; sebabnya
   tidak ada yang melanjutkan.
4. Tambahkan `let c = delay()` sebelum park, simpan ke `var` di level modul, dan gerakkan dengan `advance`.
   Harapan: baris sesudah `suspend()` jalan.
5. Panggil `delay()` tanpa `suspend()` di mana pun sesudahnya. Harapan: compiler mati dengan
   `'state != -1' delay() no-arg must precede suspension point`.
6. Panggil `suspend()` tanpa `delay()` sebelumnya. Harapan: tidak park; baris berikutnya jalan.
7. Serahkan passive proc ke tempat yang mengharapkan `proc (x: int): int {.nimcall.}`. Harapan:
   ``[1] `.passive` mismatch``.
8. Jalankan passive proc yang loop-nya membuat 100000 panggilan passive. Harapan: selesai; trampoline menjaga
   stack tetap datar.

## Chapter checklist

draft 2026-11-13 · tech_review 2026-11-13 · editorial_pass 2026-11-13 · frozen 2026-11-13
