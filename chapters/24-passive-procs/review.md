# Chapter 24 review note — Passive Procs and Concurrency

Status: `drafting`. Reviewer: **Momo**. This note is the claim table, the open questions and the errata
candidates. Append your verdict at end of file; do not edit the table rows in place.

Pin for every run below: `4ba90a781b0b22d0821efaa153c129c37cef6143` (nimony 0.6.3), install
`~/.local/opt/nimony/4ba90a7`. Probe sources: `ch24-probes/` in the authoring workspace
(`probes/ch24/`), one directory per
probe, each run as `~/.local/opt/nimony/4ba90a7/bin/nimony c -r main.nim` from inside the probe directory. Two
probes were run under `timeout` because the chapter claims they do not terminate; the timeout exit is reported
as the evidence (p05). The machine is macOS arm64.

Verifier already run by the editor, from the authoring folder:

```
toolchain ~/.local/opt/nimony/4ba90a7/bin/nimony 0.6.3 pin 4ba90a7
PASS samples/24-passive-procs/passive.nim exit=0
SUMMARY 23/23 passed, 0 failed
```

Sample output, byte-identical to the block in `en.md` section Samples (10 lines):

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

## Claims

| # | Section | Claim as written | Probe | Raw output | Source |
| --- | --- | --- | --- | --- | --- |
| 1 | frame | `.passive` is the one mechanism for work that pauses; the design says write `passive` instead of `async` | source read | — | `doc/differences.md:8-9`; `doc/design.md:93-101` |
| 2 | frame | the default scheduler runs one chain of states to its end, so two passive procs take turns only if the driver does | `p07`, `p08` | `p07`: `start a` / `end a` / `start b` / `end b`; `p08`: `a 1` / `b 1` / `both parked` / `a 2` / `b 2` | `lib/std/system.nim:285-286`, `:300-303` |
| 3 | frame | a parked proc does not resume itself; something must hold the continuation | `p03`, `p05` | `p03` prints `start a` then `parked` then `resumed a` only after the saved continuation is driven; `p05` never resumes | `lib/std/system.nim:272-283`, `:345-370` |
| 4 | a procedure that can pause | a passive proc that never suspends, called from regular code, returns its value like a plain call | `p01` | `42`, `41`, `done`, exit 0 | `src/hexer/cps.nim:116-200` |
| 5 | a procedure that can pause | a call from non-passive code is lowered to `complete` | source read | — | `src/hexer/cps.nim:116-200` (`emitCompleteFromNormal`), `lib/std/system.nim:357-370` |
| 6 | a procedure that can pause | a passive call from a passive proc runs in source order | `p02` | `outer start` / `inner 1` / `outer got 2` / `inner 2` / `outer got 3` / `outer end` / `back in main` | `src/hexer/cps.nim:200-210` |
| 7 | a procedure that can pause | a passive call is a suspension point: when the callee parks, the caller parks too | `p23` | `outer 1` / `inner 1` / `outer parked` / `inner 2` / `outer 2` / `done` | `src/hexer/cps.nim:202-210` |
| 8 | delay/complete | `delay(call)` builds the coroutine without running it | `p04` | `built, not run` then `worker a` / `worker a end` after `complete` | `lib/std/system.nim:277-279` |
| 9 | delay/complete | `complete(c)` runs a coroutine that does not park | `p04`, `p07` | `p04`: both worker lines after `complete`; `p07`: two coroutines, each whole | `lib/std/system.nim:357-370` |
| 10 | delay/complete | two coroutines completed in sequence interleave nothing | `p07` | `start a` / `end a` / `start b` / `end b` / `done` | `lib/std/system.nim:345-355` |
| 11 | delay/complete | `complete` trampolines on the caller's thread and then waits if the coroutine parked | source read | — | `lib/std/system.nim:345-370`; `doc/passive_procs.md:108-115` |
| 12 | delay/complete | `complete` on a coroutine that parks never returns | `p05` under `timeout 6` | `calling complete` / `before park`, then nothing; exit `124` | probe; `lib/std/system.nim:367` (wait loop) |
| 13 | parking | `delay()` with no argument captures the rest of the proc up to the next suspension point | `p03`, `p22` | `p03` resumes at the line after `suspend()`; `p22` prints `local across suspend: 42` | `lib/std/system.nim:272-275` |
| 14 | parking | `suspend()` parks the coroutine | `p03` | step trace: `parked=true finished=false` after the suspend state | `lib/std/system.nim:281-283` |
| 15 | parking | the lowering is a continuation pointing at the next state, and a park returning `Continuation(fn: nil, env: this)` | source read | — | `src/hexer/cps.nim:264-285` |
| 16 | parking | `parked`, `finished`, `stopping` distinguish the three continuation states as tabled | `p19` | nil: `true false true` for finished/parked/stopping; parked: `false true true`; runnable: `false false false`, derived from the two predicates and not run | `lib/std/system.nim:421-433`; probe |
| 17 | parking | a bare `suspend()` with no `delay()` is a synchronous transition; the code after it runs | `p10` | `before` / `after` / `returned, steps=3` | `src/hexer/cps.nim:272-280` (comment: "A bare `suspend()` is a synchronous transition to the next state so the trampoline drives on") |
| 18 | parking | `delay()` with no following suspension point kills the compiler with an assertion | `p09` | `Error: unhandled exception: cps.nim(269, 5) 'state != -1' delay() no-arg must precede suspension point [AssertionDefect]` | `src/hexer/cps.nim:269` |
| 19 | driving | a saved resume continuation continues the proc at the line after `suspend()` | `p03` | `start a` / `parked` / `resumed a` / `done` | probe; `lib/std/system.nim:300-303` |
| 20 | driving | locals survive a park because they are lifted into the coroutine frame | `p22` | `parked` / `local across suspend: 42` / `done` | probe; `doc/passive_procs.md:75-92` |
| 21 | two coroutines | `advance` takes exactly one state transition and goes through the scheduler | `p06` | `s0` / `s1` / `ticks=2` | `lib/std/system.nim:300-303` |
| 22 | two coroutines | the default scheduler `trivialTick` runs exactly the continuation it is given | source read | — | `lib/std/system.nim:285-286` |
| 23 | two coroutines | `setScheduler` replaces it, and a counting scheduler sees every step | `p06` | `ticks=2` for a proc with one park | `lib/std/system.nim:295-298` |
| 24 | two coroutines | interleaving is the driver's decision, not the pragma's | `p08` | `a 1` / `b 1` / `both parked` / `a 2` / `b 2`; swapping the last two drives swaps the last two lines | probe |
| 25 | two coroutines | the pin ships a thread pool with `initPool`, `submit(continuation)`, `shutdownPool` | `p20` | `start a` / `resumed a` / `start b` / `resumed b` / `done after 10ms, finished=2` | `lib/std/threadpool.nim:114`, `:198`, `:376`, `:417` |
| 26 | two coroutines | submitting two coroutines to a two-worker pool does not by itself interleave them | `p20` | each worker's start and resume are adjacent; run completes in 10 ms | probe |
| 27 | two coroutines | a scheduler must not dispatch unrelated continuations inside a trampoline | source read | — | `doc/passive_procs.md:149-161` |
| 28 | chain | resuming an inner continuation finishes the inner proc and continues the outer one | `p23` | `outer parked` then `inner 2` / `outer 2` from one drive of the inner continuation | probe; `src/hexer/coro_transform.nim:600-608` |
| 29 | compiler output | the generated C holds a coroutine struct with a `CoroutineBase` and per-state functions | `p17` | `typedef struct workerX60Qcoro_0_mai3r4ykk{` … `workerX60Qs0_0_mai3r4ykk(...)` … `workerX60Qs1_0_mai3r4ykk(...)` in `nimcache/c/mai3r4ykk/mai3r4ykk.c` | probe (generated C) |
| 30 | compiler output | the frame is heap-allocated for a passive-to-passive call and stack-allocated for a regular caller | source read | — | `src/hexer/cps.nim:155-200` (stack), `:202-210` (heap); `lib/std/system.nim:684-712` |
| 31 | compiler output | `deallocFrame` frees only when `callee != nil` | source read | — | `lib/std/system.nim:706-709` |
| 32 | compiler output | the trampoline keeps chain depth off the C stack; 100000 passive calls finish | `p21` | `survived 100000 passive calls`, exit 0 | `lib/std/system.nim:345-355`; `doc/passive_procs.md:468-471` |
| 33 | refusals | `delay` refuses a callee with a `var`/`out`/`lent` parameter | `p14` | `Error: `delay` hands `bump` to a scheduler, so its continuation can outlive this frame; parameter `x: var int64` would alias a location that is already gone. Take it as `sink` instead` | `src/nimony/sem.nim:3885-3906`, `:3929-3935` |
| 34 | refusals | the same `var` parameter is legal in an ordinary passive call | `p13` | `42`, exit 0 | `src/hexer/cps.nim:202-210`; probe |
| 35 | refusals | `delay` refuses a callee that returns a value or raises | `p12` | `Error: `delay` hands `calc` to a scheduler, which runs it after this expression is gone; `calc` returns `int64`, but nothing can receive the value there. Handle it inside the task instead` | `src/nimony/sem.nim:3908-3927` |
| 36 | refusals | a value-returning passive proc is fine when called from regular code | `p01` | `42` | `src/hexer/cps.nim:116-200` |
| 37 | refusals | a passive proc is not a plain proc value | `p24` | `[1] `.passive` mismatch (declared in main.nim(6, 1))` | `src/nimony/sigmatch.nim:245` |
| 38 | refusals | a passive proc touching a module-level `var` hits the unsynchronized-global check | `p03` first run | `main.nim(7, 14) Error: unsynchronized access to global variable 'resumeCont'; pass it to a `.sync` routine or use `{.cast(assumeSync).}`` | `src/nimony/contracts_fir.nim:4119-4128` |
| 39 | refusals | `{.feature: "assumeSync".}` at module level lets the driver hold a module-level continuation | `p03`, `p08`, `sample` | all three run | `src/nimony/sempragmas.nim:544-550`; `lib/std/threadpool.nim:12` |
| 40 | delta | `import std / [asyncdispatch]` is a missing file at the pin | `p16` | `Error: file not found: …/src/lib/std/asyncdispatch.nim` | `lib/std/` listing |
| 41 | delta | `await` is an undeclared identifier | `p15` | `main.nim(4, 11) Error: undeclared identifier: 'await'` | probe |
| 42 | delta | `std/asyncio` is a passive file API on the same ring, not Nim 2's async runtime | source read | — | `lib/std/asyncio.nim:1-30` |
| 43 | samples | the sample prints the ten listed lines and exits 0 | verifier | `SUMMARY 23/23 passed, 0 failed`; direct run exit `0` | probe |

## Questions

**A. The pairing is enforced on one side only.** `suspend()` with no `delay()` is a synchronous transition and
the code after it runs (`p10`, `cps.nim:272-280`); `delay()` with no `suspend()` crashes the compiler
(`p09`, `cps.nim:269`). Is the silent half deliberate (the comment says the trampoline should drive on), and is
the crash an ERRATA row or a compiler defect to file against `cps.nim`? The chapter currently teaches "write
them together" and quotes the crash.

**B. Is "complete is for coroutines that cannot park" the right rule?** It follows from `complete`'s wait loop
(`system.nim:345-370`) and the reason given in the design page: the frame and the result pointer point into the
regular caller's stack (`doc/passive_procs.md:378-380`). A regular caller that parks needs a thread pool's
`passiveWaitHook` to make progress. If there is a supported single-threaded shape that I missed, the chapter
should teach it instead of the warning.

**C. `deallocFrame` checks one condition, the doc says two.** `lib/std/system.nim:706-709` tests only
`frame.callee != nil`; `doc/passive_procs.md:348-357` says both `callee != nil` and `caller.fn != nil` must
hold. Is the doc stale, or is a condition lost in the code? This decides whether the chapter may mention the
caller check at all — today it does not.

**D. What type is `let f = worker`?** `p18` compiles and prints `2` for `let f = worker; echo f(1)`, while
passing the same proc to a `proc (x: int): int {.nimcall.}` parameter is `` `.passive` mismatch `` (`p24`). Is
the value a wrapper that runs to completion, and is a hand-written wrapper the only supported route into a
callback slot?

**E. Interleaving.** The outline's proof gate left it unproven and the chapter never promises it. `p20` submits
two coroutines to a two-worker pool and gets them sequentially; the design page says a scheduler must not
interleave inside a trampoline (`doc/passive_procs.md:149-161`). Is the chapter's "the driver decides, the
pragma does not" the strongest true statement, or is there a run at the pin (an `ioring` timeout, a socket
read) that shows two coroutines overlapping and belongs in the text?

**F. `tests/nimony/cps/tdelayresult.nim` contradicts the pin.** That test delays a value-returning proc and
completes it; `p12` is refused at sem (`sem.nim:3908-3927`). Stale test, or a check that is too broad at the
`delay` call site? Filed as an ERRATA candidate below, but I would rather it be a test fix.

**G. Mangled names in prose.** The generated C names are `workerX60Qcoro`, `workerX60Qs0`; I quote them as the
proof that a state machine is emitted. Stable enough to print, or should the chapter describe the shape only?

**H. The driver's continuation and the global rule.** Saving `delay()` in a module-level `Continuation` needs
`{.feature: "assumeSync".}` (`p03` first run) and the sample uses it. Is that the idiom the book should teach
for a driver, or is a `sink` parameter the only shape that survives a scheduler on another thread?

## ERRATA candidates

1. **`deallocFrame`'s two conditions.** `doc/passive_procs.md:348-357` states that both `callee != nil` and
   `caller.fn != nil` must hold; the pin's implementation tests only `callee != nil`
   (`lib/std/system.nim:706-709`). Documentation defect, medium: it describes a safety condition the code does
   not check.
2. **`tdelayresult.nim` as a test of a refused shape.** `tests/nimony/cps/tdelayresult.nim` delays a
   `proc (x: int): int` and calls `complete` on it; `p12` refuses the `delay` with a clear message. Either the
   test or the check is wrong; the chapter never teaches the shape.
3. **`spawn` template in the design page.** `doc/passive_procs.md:271-277` builds a `spawn` template calling
   `scheduler.run taskA`, but `scheduler` is a private variable in `system` (`lib/std/system.nim:295`) and
   there is no `run` proc taking a `Continuation` in scope. The example does not type-check as printed. Low:
   the chapter does not use `spawn`.
4. **Watch row — bare `suspend()`.** A `suspend()` with no preceding `delay()` compiles, does not park, and
   runs the code after it (`p10`). Not a documentation defect (the doc says the calls are paired) but a
   diagnostic gap; the chapter states the behaviour and does not rely on it.

## Notes for the editor

- The chapter's spine is the pair `delay()`/`suspend()` plus the driver; `complete` is the easy path and the
  hang in `p05` is the warning. Keep the hang in the text: it is the failure mode a reader hits first.
- The sample deliberately avoids I/O and threads: everything is one thread, deterministic, 10 lines. The
  thread pool appears as prose plus a probe, not in the sample, so the verifier can never flake.
- The `p20` probe needs `shutdownPool` and a bounded wait; an earlier version without them printed only
  `submitted` because `shutdownPool` stops the workers before they run. Recorded here so the probe is
  reproducible.
- Glossary adds six terms; the retired table gains `async` / `await`. No other chapter was opened.
- `id.md` is not written: it waits on the freeze, per the chapter template.

## Verdict — 2026-11-13

Reviewer: **Momo**. I re-ran every probe in `ch24-probes/` myself at pin `4ba90a7`, plus five of my own:
`p38` (p03 without `assumeSync`), `ty/t1`-`ty/t5` (the type of `let f = worker`), `h1` (a ref-object driver),
`e1` (two pool workers with a blocking task) and `r1` (the `.raises` branch of the `delay` refusal). All runs are
`~/.local/opt/nimony/4ba90a7/bin/nimony c -r main.nim` on macOS arm64; `p05` is under `timeout 6`. Verifier re-run
by me from the authoring folder: `SUMMARY 23/23 passed, 0 failed`, exit 0; the sample's ten lines are
byte-identical to the block at `en.md:349-358` (`diff` empty).

**Verdict: 43 claims hold; one is overstated as written (26) and changes one sentence of text; zero open.**

The one that changes a paragraph: **the pool does overlap blocking work.** `p20` is sequential because its tasks
never block, but `e1` submits two workers that `sleep(200)` to a two-worker pool and prints
`start a` / `start b` / `end b` / `end a`. The true statement is "submitting does not guarantee overlap", not
"does not interleave"; the chapter already says "can still finish one after the other", which is right, and needs
one clause for the blocking case. Detail in E below.

### Answers A-H

**A. Deliberate on one side; the other is a compiler defect.** `trSuspend` says it: a bare `suspend()` is a
synchronous transition so the trampoline drives on (`src/hexer/cps.nim:272-275`), and `p10` prints
`before` / `after` / `returned, steps=3`. The crash is `trDelay0`'s `assert state != -1` (`:269`) — an assertion,
not a diagnostic — so file it as a compiler defect (missing error for `delay()` with no following suspension
point) and keep the chapter quoting it, labelled as an assertion. Not a book errata: the text describes the pin
accurately. Watch row 4 stays.

**B. The rule is right for this book's single-thread scope.** `complete` attaches a `Join`; `run` trampolines,
then blocks on `j.done` (`lib/std/system.nim:345-355`), and the only thing that makes progress while it waits is
`passiveWaitHook` (`:335-341`), which a pool installs. With no pool, nothing can resume a parked coroutine, so the
`p05` hang is by construction. The supported shape is a driver that holds the continuation and advances it
(`h1`, p03); `complete` plus a park has no single-threaded form. Keep the warning; name the hook as the pool's
answer, not a reader's tool.

**C. Doc stale; no condition lost.** The pin's `callee != nil` is the heap marker: the heap path's wrapper sets
`frame.callee` to the frame itself (`src/hexer/coro_transform.nim:2296-2316`), the stack path emits
`callee = nil` (`:661-669`), and `allocFrame` is `alloc0`, so the field is zeroed before anything reads it
(`lib/std/system.nim:684-704`). `caller.fn != nil` is a different invariant — `complete` refuses a coroutine
that already has a caller (`:361-363`) — not a safety check that went missing. ERRATA 1 stays, low: documentation
defect. The chapter must not teach the caller check.

**D. The value keeps its passive type.** `let f = worker` has type `proc (x: int64): int64 {.passive.}` — proved
by a mismatch that prints it (`ty/t5`) — and `f(1)` from regular code prints `2` (`ty/t1`) because a call through
a non-symbol callee still takes the `IsNormal` path and lowers to `complete` (`src/hexer/cps.nim:114-153`). It is
not a wrapper value. Passing it where `proc (x: int): int {.nimcall.}` is expected is refused (`p24`,
`src/nimony/sigmatch.nim:245`); a hand-written non-passive wrapper is the only route into that slot. Fix the
sentence that calls the init wrapper the value's shape.

**E. Not the strongest true statement.** `e1` (two workers, `sleep(200)`) gives
`start a` / `start b` / `end b` / `end a`: two coroutines do overlap when a worker blocks. `p20` stays valid as
"not guaranteed", and `doc/passive_procs.md:149-161` still forbids dispatching unrelated continuations inside a
trampoline. Add one sentence: with more than one worker, blocking work (`sleep`, a socket read) runs at the same
time; the pragma still decides nothing and no order is promised.

**F. Neither stale nor too broad.** `tests/nimony/cps/tdelayresult.nim` is an expected-error test: its `.msgs`
companion expects exactly the refusal at `(9, 16)`, and `r1` shows the `.raises` branch at `(7, 16)` with the
matching message. The check is the point of the test. ERRATA 2 is dropped; nothing to fix.

**G. Print the shape, not the names as a contract.** The names are deterministic at the pin for a given module
(`workerX60Qcoro`, `workerX60Qs0`, `workerX60Qs1` in `p17/nimcache/c/mai3r4ykk/mai3r4ykk.c`), but the `X60Q`
escape and the `_0_mai3r4ykk` suffix are compiler-internal and change with the module and the version. The
chapter's excerpt already truncates with `...`; add one clause saying the names are illustrative.

**H. `assumeSync` is not the only idiom.** `p03`, `p08` and the sample work because of
`{.feature: "assumeSync".}`, and `p38` shows the refusal without it, but `h1` holds the continuation in a
`ref object` owned by the driver and compiles with no pragma: `start` / `parked` / `resumed` / `done`. Teach the
heap object or a continuation kept inside the driver; use `{.feature: "assumeSync".}` only for the module-level
driver the sample needs. "Pass it in a `sink` parameter" is wrong as written: a `sink` parameter does not make a
global safe, and it cannot carry the continuation back out to the driver.

### Claim verdicts

| # | Verdict |
| --- | --- |
| 1 | Stands — `doc/differences.md:8-11`, `doc/design.md:93-101`. |
| 2 | Stands — `p07` and `p08`: one chain per driver call, no turn taking by itself. |
| 3 | Stands — `p03` resumes only when the saved continuation is driven; `p05` never resumes. |
| 4 | Stands — `p01` prints `42` / `41` / `done`. |
| 5 | Stands — the `IsNormal` path emits `complete` (`src/hexer/cps.nim:114-153`). |
| 6 | Stands — `p02` runs the two calls in source order. |
| 7 | Stands — `p23`: the inner park carries the outer proc with it. |
| 8 | Stands — `p04`: nothing runs before `complete`. |
| 9 | Stands — `p04`, `p07`. |
| 10 | Stands — `p07`: whole coroutine A, then whole coroutine B. |
| 11 | Stands — `run` trampolines on this thread, then waits on `j.done` (`lib/std/system.nim:345-355`). |
| 12 | Stands — `p05` prints two lines and exits `124` under `timeout 6`. |
| 13 | Stands — `p03` resumes after `suspend()`; `p22` keeps the local. |
| 14 | Stands — `p03` step trace: `parked=true finished=false`. |
| 15 | Stands — `trDelay0` / `trSuspend` (`src/hexer/cps.nim:263-285`). |
| 16 | Stands — `p19` prints `true false true` and `false true true`; the runnable row is derived, as the table says. |
| 17 | Stands — `p10` prints `before` / `after` / `returned, steps=3`; comment at `cps.nim:272-275`. |
| 18 | Stands — `p09` assertion; the assertion is a compiler defect to file, not a book errata. |
| 19 | Stands — `p03`: `resumed a` only after `drive(resumeCont)`. |
| 20 | Stands — `p22` prints the local after the park. |
| 21 | Stands — `p06` prints `s0` / `s1` / `ticks=2`. |
| 22 | Stands — `trivialTick` runs one state function (`system.nim:285-286`). |
| 23 | Stands — `p06` counts two steps through `setScheduler`. |
| 24 | Stands — `p08`; the order is the driver's. |
| 25 | Stands — `p20`; API at `lib/std/threadpool.nim:114`, `:198`, `:376`, `:417`. |
| 26 | Overstated — `p20` is sequential for non-blocking tasks, but `e1` overlaps with `sleep(200)`; change to "does not guarantee overlap". |
| 27 | Stands — `doc/passive_procs.md:149-161`. |
| 28 | Stands — `p23`; `src/hexer/coro_transform.nim:600-608`. |
| 29 | Stands — `p17` generated C has the struct and both state functions. |
| 30 | Stands — stack at `cps.nim:155-199`, heap at `:200-210`. |
| 31 | Stands — `system.nim:706-709` tests only `callee != nil`. |
| 32 | Stands — `p21` prints `survived 100000 passive calls`, exit 0. |
| 33 | Stands — `p14` exact message, `var int64` named. |
| 34 | Stands — `p13` prints `42`. |
| 35 | Stands — `p12` return branch; `r1` raises branch, exact message (`sem.nim:3918-3921`). |
| 36 | Stands — `p01` prints `42`. |
| 37 | Stands — `p24` `.passive` mismatch (`sigmatch.nim:245`). |
| 38 | Stands — `p03` first run and `p38`. |
| 39 | Stands — `p03`, `p08`, sample; `sempragmas.nim:542-551`. |
| 40 | Stands — `p16` file-not-found for `std/asyncdispatch`. |
| 41 | Stands — `p15` undeclared `await`. |
| 42 | Stands — `lib/std/asyncio.nim:1-30`. |
| 43 | Stands — verifier `23/23`, direct run exit 0, ten-line diff empty. |

### ERRATA

1. **Keep, low — the doc is stale, not the code.** `doc/passive_procs.md:348-357` describes two conditions; the
   pin marks a heap frame by pointing `callee` at the frame itself, nulls it for a stack frame, and frees on
   `callee != nil` (`lib/std/system.nim:706-709`, `src/hexer/coro_transform.nim:2296-2316`, `:661-669`).
   Documentation defect: delete the `caller.fn` clause or state the current marker.
2. **Drop.** `tests/nimony/cps/tdelayresult.nim` is the expected-error test for the refusal; its `.msgs` companion
   expects exactly `(9, 16)`. Not stale, not too broad, nothing to change.
3. **Keep, low — the `spawn` example does not type-check.** `doc/passive_procs.md:271-277` calls
   `scheduler.run taskA`; `scheduler` is private (`lib/std/system.nim:295`) and there is no `run` proc taking a
   `Continuation` in `lib/std` (only `run(j: ptr Join)`, `:345`). Documentation defect; the chapter does not use
   the shape.
4. **Watch row — bare `suspend()`.** Compiles, does not park, runs the code after it (`p10`). Not a documentation
   defect (the doc says the calls are paired), but a diagnostic gap; the chapter states the behaviour and does not
   rely on it.

### Watch rows

- **`cps.nim:269` assertion.** `delay()` with no following suspension point crashes the compiler instead of
  producing a diagnostic. Filed upstream on 2026-11-13 as `nim-lang/nimony#2985`, with a nine-line reproduction
  at the pin. Fixed upstream the same day as `nim-lang/nimony#2988`: the assertion becomes a call-site diagnostic
  (`[Error] main.nim(6, 16) `delay()` with no arguments must be followed by a suspension point in the same state
  ...: (delay0)`), proven on a patched build of `4ba90a7` with `hastur test tests/nimony/cps` at 66/66 and the
  book's 23 samples unchanged. Not merged yet, so the chapter keeps quoting the assertion: it is the right output
  for the pin. Revisit when a pin carries the fix.
- **Bare `suspend()` diagnostic gap.** Stays a watch row; no promise that it is reported.
- **Generated C names.** Illustrative only; the module suffix and the `X60Q` escape are not a public contract.

### What to change in `en.md`

1. `en.md:22` — "no separate thread procedure" is not in the cited page. Cite `doc/differences.md:8-11` together
   with `doc/design.md:97-101`, or drop the clause; `std/rawthreads` exists, so the phrase needs its exact meaning.
2. `en.md:26-27` — "each call runs one chain of states to its end" is only true of a call from regular code;
   `advance` moves one state. Say "a call from regular code".
3. `en.md:46` — add that `complete` waits for whoever resumes the coroutine if it parks (`system.nim:351-355`).
4. `en.md:185-186` — "in the other order" is false for the block that follows: it drives `resumeA` then
   `resumeB`, the same order. Say "in the order you choose", or swap the two `drive` lines and the output.
5. `en.md:205` — `b 2` belongs to the a/b snippet, not the sample; for the sample say `worker c end` comes before
   `worker b end`.
6. `en.md:208-214` — add the blocking case from `e1`: two workers do overlap `sleep`/socket work; keep "not a
   promise".
7. `en.md:264-268` — fix the marker direction: the heap wrapper points `callee` at the frame itself, the stack
   path nulls it, and `deallocFrame` frees when it is non-nil.
8. `en.md:268-271` — split the two facts: the stack shape is safe because the caller waits; the `var`/`out`/`lent`
   refusal is about a location outliving the frame (`sem.nim:3885-3906`). The current sentence gives the wrong
   cause and cites the other rule.
9. `en.md:302` — a `sink` parameter cannot deliver a result to the caller; write into a heap object the driver owns,
   or keep the value inside the task.
10. `en.md:305-308` — the value's type stays `.passive`; the mismatch is the calling convention, not the init
    wrapper.
11. `en.md:310` — `{.feature: "assumeSync".}` is Chapter 16's route
    (`chapters/16-modules-visibility/en.md:294-298`), not Chapter 23's; Chapter 23 shows only the `.cast` block.
12. `en.md:320-321` — replace "pass the continuation in a `sink` parameter" with the `ref object` driver (`h1`) or
    keeping it inside the driver; a `sink` parameter does not clear a global.

Claims open: none. No other chapter was opened; `id.md` waits on the freeze.
