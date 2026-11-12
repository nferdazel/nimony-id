# Chapter 7 — review record

Draft: 2026-11-12, Aksara. Pin: `4ba90a781b0b22d0821efaa153c129c37cef6143` (nimony `0.6.3`).
Technical review: **complete** — Momo, 2026-11-12. All 28 claims held in substance; two were wrong as written and
are corrected below in the same editorial pass. The chapter is `frozen`.

Twenty-eight claims, every one probed by the editor at the pin except where a row says otherwise. Probes were
separate files in a scratch folder outside the book, so a compile error in one could not hide another; the raw
output or the exact error line of each is reproduced below. Nothing here is written from documentation alone:
where a doc sentence disagreed with the pin, the pin won and the disagreement is listed as an open question or an
`ERRATA.md` row.

## Sample verification

`nimony c -r samples/07-loops-ranges/loops.nim` — exit `0`, 30 lines on stdout, in this order:

```
incl 0
incl 1
incl 2
incl 3
half 0
half 1
half 2
descending count 0
down 3
down 2
down 1
step 0
step 2
step 4
step 6
char a
char b
char c
index 0 a
index 1 b
index 2 c
odd 1
odd 3
odd 5
while 0
while 1
while 2
total 10
digit 7
not a digit
```

`tools/verify-samples.sh` in the book folder after the sample was added prints `SUMMARY 6/6 passed, 0 failed`
(chapters 2–7), exit `0`.

## Claims and probe output

| # | Claim | Basis | Probe output at the pin |
| --- | --- | --- | --- |
| 1 | `for i in 0..3` counts up and includes both ends. | `lib/std/system/iterators.nim:14-42` | `p1` → `0 1 2 3`, exit 0 |
| 2 | The loop declares its variable and its scope ends with the body. | `doc/language.md:4041-4056` | `p53`: `for i in 0..2: discard` then `echo i` → `Error: undeclared identifier: i` |
| 3 | Bounds may be ordinary values, not only literals. | same | `p52`: `let n = 3; for i in 0..n` → `0 1 2 3` |
| 4 | A descending pair is empty, not reversed. | `iterators.nim:14-42` (`while i <= b`) | `p3`, `p16`: `for i in 3..0` with a counter → counter `0` |
| 5 | `for i in 0..high(int)` is a compile error, because `inc` at `high(T)` would wrap forever. | `iterators.nim:15-32` | `p58`: `Error: contract violated: b < 9223372036854775807'i64 or sizeof(int64) == 1 and …`, exit 1 |
| 6 | A slice value is not iterable; `for` needs the iterator. | `lib/std/system.nim:610-616` | `p28`: `let r = 0..3; for i in r` → `Type mismatch at [position] items(r) … got: HSlice[int64,int64]` |
| 7 | `a..<b` excludes the upper bound, and equal bounds give nothing. | `iterators.nim:1-9` | `p2` → `0 1 2`; `p17` (`3..<3`) → no output |
| 8 | As a value, `a..<b` is `a..pred(b)`. | `system.nim:610-616` | source read; the value form is not exercised by a probe (the chapter only says it) |
| 9 | `0..<len(s)` makes `s[i]` provable because the iterator states `ensures: (a <= result and result < b)`. | `iterators.nim:1-9` | `p29`, `p55`, `p66` → `0a 1b 2c`, exit 0 |
| 10 | `0..len(s)` with `s[i]` builds and then dies at runtime with `i < len(s) [AssertionDefect]`. | `lib/std/system/stringimpl.nim:686` | `p60`, `p65` → prints `a b c`, then `stringimpl.nim(686, 37): i < len(s) [AssertionDefect]`, exit 1 |
| 11 | `countdown`, `>..` and stepped `countup`/`countdown` behave as printed. | `iterators.nim:59-74`, `:46-52`, `:76-93` | `p4` → `3 2 1`; `p59` (`3 >.. 0`) → `3 2 1`; `p21` → `0 2 4 6`; `p30` → `5 3 1` |
| 12 | The step is positive only. **Corrected 2026-11-12:** true of `countup` (`step: Positive`), not of `countdown`, whose step is an unconstrained ordinal. | `iterators.nim:76`; `countup` at `:76-82`, `countdown` at `:59`, its comment `:64` | `b`-series: `countup(0, 6, -2)` → `value out of range: -2 notin 1..9223372036854775807`; `countdown(5, 1, -1)` compiles and climbs (`5 6 7 8 …`), never descending |
| 13 | `char` ranges iterate; `ord` counts; descending needs `countdown` or `>..`. | `iterators.nim:14-42`, `:59`, `:46` | `p6` → `a b c`; `p54` → `97 98 99`; `p7` (`'c'..'a'`) → nothing; `p62`/`p63` → `c b a` |
| 14 | The loop variable is writable at this pin, and writing it moves the counter. | pin behaviour, not in `doc/` | `p34`: `for i in 0..5: if i == 1: i = 3; echo i` → `0 3 4 5`, exit 0. `p40` (writing the same value) → `0 1 2` |
| 15 | Writing the loop variable past the bound ends the loop. | same | `p10`, `p33`: `for i in 0..2: i = 5; echo i` → `5` once, then the loop ends |
| 16 | `continue` goes to the next iteration of the surrounding loop. | `doc/language.md:2010-2015` | `p8` → `1 3 5` |
| 17 | `continue` inside a bare `block` inside a `for` still targets the loop. | same | `p24` → `0 2` |
| 18 | `while` tests first, so the body may never run. | `doc/language.md:1992-2006` | `p15`: `while false` → only `after` |
| 19 | `continue` in a `while` re-tests the condition. | `doc/language.md:2010-2015` | `p22` → `1 2 4 5` |
| 20 | An endless `while` is legal, and `break` leaves it through the implicit block. | `doc/language.md:1992-2006` | `p37`: `while true` with a counter and `break` at 3 → `3`, exit 0 |
| 21 | A comparison guard on an `int` parameter supplies the proof for a `range` parameter, and for a conversion. | `src/nimony/contracts_fir.nim:2386-2387`; pin behaviour | `p26` (`n >= 0 and n <= 9` then call) → `5`; `p39` (`0 <= n and n <= 9`) → `5`; `p27` (conversion) → `5` |
| 22 | Without a visible guard the call is rejected, and the message names the value and the range. | `contracts_fir.nim:2386-2387` | `p12`: `Error: cannot prove 'n' is in range 0..9`, exit 1 |
| 23 | An `in` guard proves a local or module-level `var`, but not a procedure parameter. | pin behaviour, contradicts `doc/differences.md:64-65` | works: `p41` (`var` at module level), `p44` (call), `p46` (local `var`). Fails: `p11`, `p47` → `cannot prove 'n' is in range 0..9` on a parameter |
| 24 | The proof does not travel from a caller into the routine that needs it. | pin behaviour | `p51`: guard in `outer`, `takes(n)` inside `inner` → `cannot prove 'n' is in range 0..9` |
| 25 | A computed value needs a fresh proof, with the wording `stays in range`. **Corrected 2026-11-12:** `n + 0` needs no new proof; the offset has to clear the guard's bound. | `contracts_fir.nim:2215-2216` | editor's `p50` (`n + 0` → `stays in range`) did not reproduce. Momo's `b1` `n + 0` → `digit 7`, exit 0; `b2` `n + 1` under `n <= 9` → `cannot prove 'n' stays in range 0..9`; `b3` `n + 1` under `n <= 8` → `digit 8`, exit 0 |
| 26 | Range assignment follows the same rule; an out-of-range literal has its own message. | `doc/differences.md:58-62` | `p13`: `r = n` → `cannot prove 'n' is in range 0..4`; `p14`: `var r: range[0..4] = 7` → `value out of range: 7 notin 0..4` |
| 27 | No runtime check is emitted for a range. | `doc/differences.md:58-62` | documented only; absence of emitted checks was not demonstrated by a probe |
| 28 | The sample prints the 30 lines above, in order, exit 0. | `nimony c -r` at the pin | run directly and compared line by line; the verifier checks exit code only |

## Open questions for the technical review

**A. The Nim 2 sentence in the delta box.** It says a `range` was defended at runtime when the value reached the
type. That is a statement about Nim 2, not about the pin, and I have no run behind it — the pin's own doc only
says Nimony emits no runtime check (`doc/differences.md:58-62`). Keep it, reword it as background, or cut it?

**B. `in` versus two comparisons (claim 23).** `doc/differences.md:64-65` writes the guard as
`if a in 0..10: (var x: range[0..10] = a)` and that form fails on a procedure parameter at the pin, while it
works on a local or module `var`. Is that intended — parameters are not tracked by the `in` form — or a prover
gap to file? The chapter currently teaches the comparison form everywhere and says `in` is not the same proof.
If it is a gap, does `ERRATA.md` carry it as a documentation gap?

**C. A stored slice is not a loop bound (claim 6).** `let r = 0..3; for i in r` fails with `items(r)` overload
errors. I read that as intended (`..` in a `for` header is the iterator; `let r = 0..3` builds `HSlice`), and the
chapter teaches writing bounds at the loop. Confirm, or should this be recorded as a rough edge?

**D. The writable loop variable (claims 14, 15).** Writing the loop variable compiles at the pin and moves the
counter. Nothing in `doc/` says it is allowed or forbidden. Is it intended, and should `ERRATA.md` carry it as an
observation with "the book teaches reading it only" as the consequence? Chapter 6's fallthrough row is the
precedent.

**E. The `contract violated` message for `0..high(int)`.** The full line names every `sizeof` alternative. The
chapter quotes the first clause and elides the rest with `…`. Acceptable, or does the chapter need the whole line
or none of it?

**F. Sample stdout.** The verifier checks exit code only; confirm the 30 lines are what the pin prints, in order.

## Claim 8 and 12 note

Both rest on source read rather than a probe: `a..<b` as a value is `a..pred(b)` (`system.nim:610-616`), and the
step parameter is `Positive` (`iterators.nim:76`). Neither is load-bearing for a rule the reader must follow.

## Leftovers, unverified

The editor's `p1`-`p66` remain the editor's runs at `4ba90a7`, macOS arm64, through `nimony c` / `nimony c -r`,
except the twenty-eight Momo repeated (`p1`-`p7`, `c1`-`c6`, `d1`-`d3`, `b1`-`b4`, `e1`). His `p50` check did not
reproduce the editor's shape and is what forced claim 25's correction.

## Verdicts (Momo, 2026-11-12)

Verifier run once at the pin: `SUMMARY 6/6 passed, 0 failed`, exit 0. The sample's 30 lines were diffed against
the block in the chapter — empty. Twenty-eight probes repeated where wording depended on them.

| # | Verdict | Basis at `4ba90a7` |
| --- | --- | --- |
| 1 | PASS, cite fixed | `iterators.nim:14-44`; `while i <= b` at 42, `inc i` at 44; run `0 1 2 3` |
| 2 | PASS | `doc/language.md:4041-4056`; `e1` prints `undeclared identifier: i`, no quotes |
| 3 | PASS | `p52` shape reproduced by the sample's `0..3` |
| 4 | PASS | `iterators.nim:42` (`while i <= b`); sample `descending count 0` |
| 5 | PASS | `iterators.nim:15-30`; `p1` first clause exact |
| 6 | PASS | `system.nim:610-616`; `p2` gives `items(r)` + `HSlice[int64,int64]`, four overloads |
| 7 | PASS, cite fixed | `iterators.nim:1-12`; `while i < b` is line 10; `d3` `3..<3` prints nothing then `done` |
| 8 | PASS | `system.nim:610-616`, `pred(b)` on 616; source only, as the row says |
| 9 | PASS | `iterators.nim:1-12`, `ensures` on line 2; sample `index 0 a` |
| 10 | PASS | `stringimpl.nim:686`; `p6` stdout `a b c`, then `i < len(s) [AssertionDefect]`, exit 1 |
| 11 | PASS, cite fixed | `>..` is `:46-53`; sample `down 3 2 1`, `step 0 2 4 6`, `5 3 1` |
| 12 | CORRECTED — half wrong | `countup` is `Positive` (`:76`), `countdown` is `V: Ordinal` (`:59`); negative step climbs |
| 13 | PASS | `iterators.nim:14-44`, `:59`, `:46`; sample `char a b c` |
| 14 | PASS | `p3` → `0 3 4 5`, exit 0 |
| 15 | PASS | `c1` → `5` once, exit 0 |
| 16 | PASS | `doc/language.md:2010-2015`; sample `odd 1 3 5` |
| 17 | PASS | `p24` → `0 2`, unchanged by a bare block |
| 18 | PASS | `doc/language.md:1992-2006`; `p15` |
| 19 | PASS | same section; `p22` → `1 2 4 5` |
| 20 | PASS | same section; `p37` |
| 21 | PASS | `contracts_fir.nim:2386-2387`; `d2` converts under the comparison guard, exit 0 |
| 22 | PASS | `p4` → `cannot prove 'n' is in range 0..9`, exit 1 |
| 23 | PASS | `c2` (module `var`) and `d1` (local `var`) compile; `p4` (parameter) fails |
| 24 | PASS | `c3` fails, but the message is `cannot prove value is in range 0..9` for a captured value — not quoted |
| 25 | CORRECTED — wrong example | `n + 0` passes; `n + 1` under `n <= 9` gives `stays in range`; `n + 1` under `n <= 8` passes |
| 26 | PASS | `c4` → `cannot prove 'n' is in range 0..4`; literal message matches `p14`; literal cite `:63-64` |
| 27 | PASS as documented | `differences.md:61` is the sentence; not demonstrable from outside, as the row says |
| 28 | PASS | 30 lines, in order, `diff` empty, exit 0 |

Both backed statements hold: `e1` fails and `e2` with `else: discard` compiles; `f1` prints `body 0` then
`after`, never `never`, so the unlabelled `break` left the loop.

## Rulings

**A. The Nim 2 sentence.** Keep it, but label the source: Nim 2.4.0, the host compiler already in the frontmatter,
stops with `RangeDefect` on `var r: range[0..4] = 7` and on `70` passed to a `range[0..9]` parameter. True, but a
host-compiler check, not a pin claim.

**B. `in` versus two comparisons.** Nothing in the tree states intent. The `in` form is a `contains` call whose
fact is tracked for locals and module vars but not for parameters; treat it as a rough edge, keep the watch row,
teach comparisons, and never write "the parameter guard is intended to fail".

**C. A stored slice is not a loop bound.** Intended split by construction: the value `..` is `system.nim:598-608`;
`items` has overloads only for `typedesc`, `set`, `string` and `openArray` (`iterators.nim:55`, `setops.nim:44`,
`stringimpl.nim:245`, `openarrays.nim:61`), none for `HSlice`. The row stays as an observation.

**D. The writable loop variable.** Right instruction and right row: no document allows or forbids the write, the
behaviour is real (`0 3 4 5`), and teaching the reader to read only is the conservative line.

**E. The `contract violated` line.** Acceptable with the ellipsis, provided the elision is accounted for: the rest
of the line repeats the same bound for the other `sizeof` cases, and the real line ends with
`[pass --verbose for the Final IR]`. Both are now stated after the block.

**F. Sample stdout.** Confirmed: 30 lines, in order, `diff` against the block empty, exit 0.

## Applied in the editorial pass

1. Stepping section rewritten: `countup`'s `Positive` step, `countdown`'s unconstrained ordinal step, the climbing
   negative step, and the split of their upper-bound requirements.
2. `range` parameter detail 4 rewritten: `n + 0` passes, `n + 1` needs the guard narrowed to `n <= 8`, and the
   "stays in range" obligation explained as an offset from the guard's bound.
3. Nim 2 delta box: the runtime-defence sentence is labelled as checked on the host compiler, and the closing
   sentence now says the proof must cover the result rather than "the engine tracks the value".
4. Checks 3 and 10 updated: negative `countup` step, and the `n + 1` / `n + 0` pair in that order.
5. Citations fixed: `iterators.nim:14-42` → `:14-44` (twice), `:1-9` → `:1-12` (twice), `:46-52` → `:46-53`;
   the out-of-range literal now cites `doc/differences.md:63-64`.
6. The `contract violated` block gained the elision sentence, and the step paragraph no longer claims both
   iterators share the upper-bound restriction.
7. The rule sentence now says "re-prove a computed value against the bound the guard actually promised".

`ERRATA.md`: the Chapter 7 ranges row had its false `n + 0` evidence clause replaced and its consequence cell
rewritten; a `countdown` step row was added with Momo's ruling; the loop-variable and stored-slice rows passed
as written.

## Definition-of-done state

| Gate | State |
| --- | --- |
| 1. One job | done — iteration and its range proof only; `if`/`case`/`when` stay in Chapter 6, collections in 8–9 |
| 2. Samples run | done — `samples/07-loops-ranges/loops.nim`, exit 0, 30 lines matching the chapter |
| 3. Technical review | done — Momo 2026-11-12, 28 verdicts, 7 fixes applied |
| 4. Editorial pass | done — 2026-11-12 |
| 5. Both languages | done — `en.md` 2.467 words, `id.md` 2.215 words, identical frontmatter, 13 sections each |
| 6. Frozen means frozen | frozen 2026-11-12; later breaks go to `ERRATA.md` |

## Glossary

Six terms added with this chapter: `for loop`, `loop variable`, `iterator`, `countup`, `countdown`, `range proof`.
