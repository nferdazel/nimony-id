# Chapter 8 — review record

Draft: 2026-11-12, Aksara. Pin: `4ba90a781b0b22d0821efaa153c129c37cef6143` (nimony `0.6.3`).
Technical review: **pending** — routed to Momo 2026-11-12.

Thirty claims, every one probed by the editor at the pin unless a row says otherwise. Probes were separate
files in a scratch folder outside the book (`ch8-probes/`), so a compile error in one could not hide another; the
raw output or the exact error line of each is reproduced below. Where a `doc/language.md` sentence disagreed with
the pin, the pin won and the disagreement is one of the open questions.

## Sample verification

`tools/verify-samples.sh` in the book folder — exit `0`:

```
toolchain /Users/sachiel/.local/opt/nimony/4ba90a7/bin/nimony 0.6.3 pin 4ba90a7
PASS samples/02-pinned-toolchain/hello.nim exit=0
PASS samples/03-values-names-mutability/values.nim exit=0
PASS samples/04-numbers-types-conversion/numbers.nim exit=0
PASS samples/05-strings/strings.nim exit=0
PASS samples/06-branching/branching.nim exit=0
PASS samples/07-loops-ranges/loops.nim exit=0
PASS samples/08-procedures/procedures.nim exit=0
SUMMARY 7/7 passed, 0 failed
```

`nimony c -r samples/08-procedures/procedures.nim` — exit `0`, 21 lines on stdout, compared line by line against
the block in `en.md` (`diff` empty):

```
block 42
single 15
result hi!!
early pass
late checked 10
fail
bare 1 0
default 21
named 14
var 6
out 1 3
tuple 1 3
sink got abc
sink after abc
func 49
override ran
override 1
dot 11
note no parens
fact 120
later 5
```

The verifier checks compile, run and exit code only, so the stdout comparison above is mine.

## Claims and probe output

| # | Claim | Doc / source | Probe and raw result |
|---|---|---|---|
| 1 | A `proc` with `=` and an indented block is the ordinary declaration; no return type means it produces nothing. | `doc/language.md:2211-2218` | `p1`: `proc greet(name: string) = echo "hi ", name` + `greet("nimony")` → `hi nimony`, exit 0. |
| 2 | A parameter type propagates across commas and stops at a semicolon. | `doc/language.md:2218-2224` | `p5`: `proc add(a, b: int; c: float): float` → `3.5`, exit 0. `p6`: `proc bad(a; b: int)` → `p6.nim(3, 10) Error: type or init value expected`, exit 1. |
| 3 | `proc f(x: int): int = expr` is a one-expression body, not a separate declaration kind. | `doc/language.md:2211-2218` | `p1`: `proc double(x: int): int = x * 2`, `echo double(21)` → `42`, exit 0. |
| 4 | A block body is a statement list expression: its last expression is the result. | `doc/language.md:1552-1560` | `p33`: body `echo "body"` then `5` → stdout `body`, then `5`, exit 0. |
| 5 | `result` is implicitly declared and is what the caller receives at the end of the body. | `doc/language.md:2243-2245` | `p4`: `result = a + b` with no `return` → `5`, exit 0. `p20`: both branches assign `result` → `neg nonneg`, exit 0. |
| 6 | A routine that never initialises `result` fails with ``cannot prove that result has been initialized``. | `src/nimony/contracts_fir.nim` (wording built for `result` and for a parameter alike) | `p2`: body `discard` in an `int` routine → `p2.nim(2, 1) Error: cannot prove that result has been initialized [pass --verbose for the Final IR]`, exit 1. |
| 7 | `return expr` is `result = expr; return`, and it leaves immediately. | `doc/language.md:1915-1921` | `p3`: `grade(70)` → `pass` alone; `grade(10)` → `checked 10`, then `fail`. exit 0. |
| 8 | Bare `return` returns whatever `result` holds. | `doc/language.md:1924-1926` | `p27`: `sign(4)` → `1`, `sign(-4)` → `0`, exit 0. |
| 9 | A default fills in an omitted argument. | `doc/language.md:2234-2241` | `p7`: `proc twice(x: int = 47)` → `twice()` `94`, `twice(5)` `10`, exit 0. |
| 10 | The default is re-evaluated at every call, not once at declaration. | `doc/language.md:2235-2237` | `p9`: default `tick()` increments a global → `x 1 calls 1` then `x 2 calls 2`, exit 0. |
| 11 | A default written in terms of an earlier parameter builds to an internal `[Bug]`, not a diagnostic. | none — probe only | `p31`/`p19`: `proc scaled(x: int; factor: int = x): int = x * factor` → `No stack traceback available` / `[Bug] could not find symbol: x.0`, then `shoggoth … command failed`, **exit 1**; `nimony c p31.nim` fails the same way, no run. |
| 12 | Named arguments may come out of order, and skipped parameters keep their defaults. | **not in the guide** — only `doc/tags.md:33` names the node | `p8`: `pair(b = 7, a = 3)` → `37`; `pair(a = 3)` → `32`, exit 0. |
| 13 | An unknown name is rejected. | not documented | `p22`: `pair(c = 1)` → `[1] named argument not found (declared in p22.nim(3, 1))`, exit 1. |
| 14 | One argument too many is rejected. | positional counts are documented (`doc/language.md:2261-2272`); named-argument counts are not | `p23`: `pair(1, 2, 3)` → `[3] too many arguments (declared in p23.nim(3, 1))`, exit 1. |
| 15 | A `var` parameter writes back to the caller's variable. | `doc/language.md:2350-2372` | `p10`: `bump(n)` on `var n = 5` → `6`, exit 0. `p26`: `fill(names: var seq[string])` → `1`, exit 0. |
| 16 | A `var` parameter's argument must be a place. | `doc/language.md:2368-2372` | `p10`: `bump(7)` → `p10.nim(9, 6) Error: cannot pass 7 to var/out T parameter`, exit 1. |
| 17 | `out` parameters are checked on the routine: every path must set each one. | `doc/language.md:2782-2790` | `p12`: `y` set only inside `if cond` → `p12.nim(3, 1) Error: cannot prove that y has been initialized`, exit 1. `p11`: both set → `1 3`, exit 0. |
| 18 | Reading an `out` parameter before writing it compiles, and reads the caller's zero value. | contradicts `doc/language.md:2765` ("must be written to before it can be used") | `p32`: `echo "before ", x` first in an `out` routine → `before 0`, then `1`, exit 0. |
| 19 | A tuple returned from a routine is built in the body and indexed at the call site. | `doc/language.md:2386-2394` | `p28`: `divmod(8, 5)` → `t[0]` `1`, `t[1]` `3`, exit 0. |
| 20 | `sink T` accepts the argument and the caller's `string` still reads its value afterwards. | `doc/language.md:911-950` | `p15`: `take(text)` on `var text = "abc"` → `got abc`, then `after abc`, exit 0. |
| 21 | A `func` that calls a side-effecting routine is rejected. | `doc/language.md:3115-3119` | `p13`: `func` containing `echo` → `cannot call a routine with side effects from a .noSideEffect context` at `lib/std/syncio.nim(468, 5)`, exit 1. |
| 22 | `{.sideEffect.}` on a `func` restores `proc` behaviour. | `doc/language.md:3163-3168` | `p14`: `func noisy(x: int): int {.sideEffect.}` prints `side`, then `1`, exit 0. |
| 23 | A `func` may write its own `var` parameter. | `doc/language.md:3121` | `p29`: `func total(items: var seq[int]): int` accumulates into `result` → `6`, exit 0. |
| 24 | Using a value where a statement belongs is rejected; `discard` is the way to drop it. | `doc/language.md:1562-1578` | `p16`: bare `f(1)` on an `int` routine → `p16.nim(5, 2) Error: expression of type int64 must be discarded`, exit 1. `p17c`: `discard add(1, 2)` → `fine`, exit 0. |
| 25 | A void routine has no value to bind. | `doc/language.md:1562-1578` (value requirement) | `p21`: `let x = greet("a")` → type mismatch cascade from `syncio` ending `expected: string but got: void`, exit 1. |
| 26 | The command form works as a statement; in an expression it takes one argument, and two is a syntax error at the pin. | `doc/language.md:2868-2875` (predicts `too many arguments` for the two-argument expression form) | `p17a`: `shout "hello"` → `!hello`, exit 0. `p36`: `let single = singlearg 2` → `40`, exit 0. `p17b`: `let r = add 1, 2` → `p17b.nim(5, 14) Error: invalid indentation`, exit 1. |
| 27 | The dot form puts the receiver first, and composes with defaults and with the command form. | `doc/language.md:2836-2866` | `p17d`: `5.add(6)` → `11`, exit 0. `p37`: `1.optarg optarg 8` → `9`, as the guide's example says, exit 0. `p35`: `echo optarg 1, " ", singlearg 2` → `1 40`, exit 0. |
| 28 | A no-argument call needs `()`; the bare name is a routine value. | `doc/language.md:2891-2893` | `p34`: `echo f` → type mismatch listing `expected: int64 but got: proc (): int64`, exit 1; `echo f()` → `5`. |
| 29 | Recursion is ordinary calls; the base case is an `if`. | `doc/language.md:2274` | `p18`: `fact(5)` → `120`, exit 0. |
| 30 | A call may appear before the declaration it resolves to at module level. | none — probe only | `p24`: `echo later(4)` above `proc later(x: int): int = x + 1` → `5`, exit 0. |

Claims 11, 18, 26 and 30 are the four the chapter could not have been written from the guide alone: 11 and 18
contradict or go past the guide, 26 is a message the guide predicts differently, 30 is undocumented.

## Open questions for the technical review

**A. Default written in terms of an earlier parameter.** `proc scaled(x: int; factor: int = x)` parses and then
dies in `shoggoth` with `[Bug] could not find symbol: x.0`, exit 1. Is that a defect to file (a compile-time
`[Bug]` is not a diagnostic), or an intended rejection with a broken message? My chapter forbids the shape and
teaches a literal default. Rule on the `ERRATA.md` wording: "defect candidate" or "unsupported, message is a
bug"?

**B. Reading an `out` parameter before writing it.** `doc/language.md:2765` says an `out` parameter "must be
written to before it can be used"; at the pin the routine builds and prints the caller's zero value. Is the
guide sentence simply wrong, or is the intended enforcement only the every-path check I found
(`doc/language.md:2782-2790`)? My chapter teaches the every-path check and warns against the read.

**C. Command form with two arguments in an expression.** The guide (`doc/language.md:2871-2875`) shows
`let fail = optarg 1, optarg 8` and calls it "too many arguments"; at the pin the same shape is
`Error: invalid indentation`, reported at the comma. Is the message difference worth an ERRATA row, and is
"write the parentheses in an expression" the right instruction?

**D. `sink` on a `string`.** The caller's variable survives the call unchanged (`sink after abc`). Is
"permission, not an observable move" the right framing for this pin, and is `sink` worth one section now or
should the chapter defer it to the ownership chapter (14)?

**E. Globals from a routine.** `p9` first failed with `unsynchronized access to global variable 'calls'; pass it
to a .sync routine or use {.cast(assumeSync).}` — a plain `proc` reading a module-level `var`. I kept that out of
Chapter 8 because the chapter's routines take everything as parameters, but the rule will hit any later chapter
with a module-level counter. Should Chapter 8 carry it, or does it belong to Chapter 16 (modules) / 24
(concurrency)? I have it in `ERRATA.md` as a watch row either way.

**F. The result check's emitter line.** `cannot prove that result has been initialized` — I cited
`src/nimony/contracts_fir.nim` without a line, because `:4165`, `:6065` and `:6068` build the same wording for a
predicate, for `result` and for a parameter. Which line actually fires for the `result` case at the pin? I will
put the exact line in.

**G. Named arguments are undocumented.** `doc/language.md` never describes `name = value` in a call; the only
trace is `doc/tags.md:33` (a NIF tag for "explicitly named arguments in function calls"). The syntax works at the
pin (`pair(b = 7, a = 3)` → `37`), so the chapter teaches it and says it is probed rather than quoted. Is that
worth an `ERRATA.md` row like the `$`-needs-`strutils` one, or is it too small to track?

Also confirm the 21-line stdout above, in order — the verifier checks exit code only.

## Leftovers, unverified

- Every probe is the editor's run on macOS arm64 at `4ba90a7`, 2026-11-12. `p9` uses `{.cast(assumeSync).}` to
  get past the global-access rule in open question E; nothing in the chapter or the sample does.
- The tuple-unpacking form (`var (x, y) = divmod(8, 5)`, `doc/language.md:2396-2400`) was **not** probed and the
  chapter does not teach it; Chapter 10 owns it.
- `noSideEffect` inference, `{.raises.}`, converters and iterators were not probed — they belong to Chapters 15,
  17 and 19.

## Definition-of-done state

| Gate | State |
|---|---|
| One job | Done — the call boundary only; overloading deferred to Chapter 9 with the outline's permission. |
| Samples run | `SUMMARY 7/7 passed, 0 failed`, exit 0; 21-line stdout compared. |
| Technical review | Done — Momo 2026-11-12, 30 verdicts, A–G answered, five ERRATA rows ruled. |
| Editorial pass | Done 2026-11-12 — thirteen text corrections applied, `id.md` written from the corrected `en.md`. |
| Both languages | Done — `en.md` and `id.md`, same frontmatter, 18 sections, 26 code blocks identical. |
| Frozen | 2026-11-12. |

## Glossary

Added in this handoff: `proc`, `func`, `result`, `var parameter`, `out parameter`, `sink parameter`,
`default argument`, `named argument`.

---

## Technical review — Momo, 2026-11-12

Pin `4ba90a781b0b22d0821efaa153c129c37cef6143` (`nimony 0.6.3`), macOS arm64, the same toolchain the editor used.
Every probe below is my own run, one file per probe, `nimony c -r` unless the row says otherwise. The sample was
re-run twice: `tools/verify-samples.sh` → `SUMMARY 7/7 passed, 0 failed`, exit 0; `nimony c -r
samples/08-procedures/procedures.nim` → exit 0, and the 21 stdout lines diff empty against the block in
`en.md:384-404`.

**Verdict: 27 of 30 claims hold as claimed. Claim 18 is wrong as written; claims 23 and 25 hold but their probe
descriptions are not what the pin does.** None of the corrections below touches a sample or a code block.

### Claim verdicts

| # | Verdict | Evidence at the pin |
|---|---|---|
| 1 | Held | `greet("nimony")` prints `hi nimony`; `double(21)` prints `42`, exit 0. |
| 2 | Held | `add(1, 2, 0.5)` prints `3.5`; `proc bad(a; b: int)` → `p6.nim(1, 10) Error: type or init value expected`, exit 1. |
| 3 | Held | `double(21)` → `42`, exit 0. |
| 4 | Held | Body `echo "body"` then `5` prints `body` then `5`, exit 0. |
| 5 | Held | `result = a + b` → `5`; both-branch version → `neg 0 pos 1`, exit 0. |
| 6 | Held | `p2.nim(2, 1) Error: cannot prove that result has been initialized [pass --verbose for the Final IR]`, exit 1. |
| 7 | Held | `grade(70)` → `early pass`; `grade(10)` → `late checked 10` then `fail`, exit 0. |
| 8 | Held | `sign(4)`, `sign(-4)` → `1 0`, exit 0. |
| 9 | Held | `twice()` → `94`, `twice(5)` → `10`, exit 0. |
| 10 | Held | Default `tick()` that echoes: `tick` is printed before each call's result, twice over two calls. A module-level counter needs the `{.cast(assumeSync).}` statement pragma (open question E); the bare form is rejected. |
| 11 | Held | `nimony c` alone: `No stack traceback available`, `[Bug] could not find symbol: x.0`, `shoggoth … command failed`, exit 1, no binary. Host Nim 2.4.0 compiles the same source and prints `9` — this is a defect, not an intended rejection. No matching issue turned up in `nim-lang/nimony`. |
| 12 | Held | `pair(b = 7, a = 3)` → `37`; their `32` implies `b: int = 2`. My rerun with `b: int = 30` gave `60`, which is the same rule. |
| 13 | Held | `[1] named argument not found (declared in p22.nim(2, 1))`, exit 1. |
| 14 | Held | `[3] too many arguments (declared in p23.nim(2, 1))`, exit 1. |
| 15 | Held | `bump(n)` → `6`; `fill(names)` → `1`, exit 0. |
| 16 | Held | `p10.nim(7, 6) Error: cannot pass 7 to var/out T parameter`, exit 1. `let n = 5; bump(n)` → `cannot pass n to var/out T parameter`. |
| 17 | Held | One path unset → `cannot prove that x has been initialized`, exit 1; both set → `1 3`, exit 0. |
| 18 | **Wrong as written** | It builds, but it reads the caller's storage, not a zero value: `var v = 9; readfirst(v)` prints `before 9`, then `1`, exit 0. The contradiction with `doc/language.md:2765` and the warning stand; the parenthetical "zero value" does not. |
| 19 | Held | `divmod(8, 5)` → `1 3`, exit 0. |
| 20 | Held | `sink got abc`, then `sink after abc`, exit 0. A 72-character string also survives the call unchanged. |
| 21 | Held | `lib/std/syncio.nim(468, 5)` and `(469, 3)` → `Error: cannot call a routine with side effects from a .noSideEffect context`, exit 1. |
| 22 | Held | `func … {.sideEffect.}` prints `side`, then `1`, exit 0. |
| 23 | Held, narrower | `func push(items: var seq[int]; x: int)` with `items.add x` returns `4` and the caller's seq grows to 4 — a `func` does write its own `var` parameter. The review's exact shape, `for x in items: result = result + x`, fails with `cannot prove that result has been initialized`; with `result = 0` first it prints `6`. |
| 24 | Held | `p16.nim(3, 4)` → `Error: expression of type int64 must be discarded`, exit 1; `discard add(1, 2)` → `fine`, exit 0. |
| 25 | Held, evidence wrong | `let x = greet("a")` → `Error: expression 'greet("a")' has no type (or is ambiguous)`; `let x: string = greet("a")` → `type mismatch: got: void but wanted: string`. There is no `syncio` cascade. |
| 26 | Held | `shout "hello"` → `!hello`; `let single = singlearg 2` → `40`; `let r = add 1, 2` → `invalid indentation` at the comma, exit 1. |
| 27 | Held | `5.add(6)` → `11`; `1.optarg optarg 8` → `9`; `echo optarg 1, " ", singlearg 2` → `1 40`, exit 0. |
| 28 | Held | `echo f` lists eight candidates; `expected: int64 but got: proc (): int64` is the third, and the list ends `expected: float64 but got: proc (): int64`. "Listing" is accurate; `en.md`'s "ending" is not. |
| 29 | Held | `fact(5)` → `120`, exit 0. |
| 30 | Held | `echo later(4)` above the declaration → `5`, exit 0. |

### Answers to A–G

**A. Default naming an earlier parameter — defect, file it.** Host Nim 2.4.0 compiles `proc scaled(x: int;
factor: int = x)` and prints `9`; the pin's front end accepts it and shoggoth crashes with `[Bug]`. That is not an
intended rejection with a bad message; a `[Bug]` line is the compiler reporting itself. No matching issue turned up in
`nim-lang/nimony` (the closed `[Bug] could not find symbol` crashes #2345 and #2643 have different
triggers), so add no number yet. ERRATA row 49 stays, status "defect candidate — to file".

**B. The guide sentence is wrong at the pin.** The only enforced rule is the every-path check
(`doc/language.md:2782-2790`). The read check in `src/nimony/contracts_fir.nim:4163` applies to
`VarY, LetY, CursorY, PatternvarY, ResultY`, and an `out` parameter is not in that set. The chapter's warning is
right; only "zero-initialised" must go.

**C. Yes, one watch row.** `invalid indentation` comes from the parser (`src/nifler2/parserrt.nim:148`, emitted at
`:296`), not from argument matching, which is why it is not `too many arguments`. "Write the parentheses in an
expression" is the right instruction. Keep row 52.

**D. Keep the section.** Correct the citation to `doc/language.md:3626-3636`: the guide itself says a copy is
passed when the last use cannot be proven. "Permission, not an observable move" is exactly the pin's behaviour,
and Chapter 14 owns move semantics; the cross-reference is enough.

**E. Not GLOSSARY; one line in CONTRIBUTING.** The glossary holds terms, not language constraints. Keep ERRATA row
51 and add one line under "Writing or changing a chapter": a chapter that shows module-level mutable state must
state the `.sync` / `{.cast(assumeSync).}` rule at first use. Chapter 8 stays parameter-only.

**F. `src/nimony/contracts_fir.nim:6065`.** That is the `result` branch; `:6068` is the out-parameter loop;
`:4163-4165` is the read-before-init check for locals and `result` inside the body. The error is reported at the
proc declaration (`decl.info`), which matches every probe.

**G. Keep the row; cite no `language.md` section.** The only doc trace is `doc/tags.md:33`; the tag is defined at
`src/models/nimony_tags.nim:277` and the rejection message at `src/nimony/sigmatch.nim:270`. "Probed, not quoted"
is correct and should stay.

### ERRATA rows 49–53

| Row | Ruling | Line to cite instead |
|---|---|---|
| 49 default names an earlier parameter | Keep; change status from "pending ruling" to "defect candidate — file at `nim-lang/nimony`". | `src/nimony/typenav.nim:402` (the `bug` message) plus the host-Nim 2.4.0 run. No pass name: the crash produces no traceback. |
| 50 reading an `out` parameter first | Keep; replace "zero value" with "the caller's current value". | `doc/language.md:2765`, `:2782-2790`; `src/nimony/contracts_fir.nim:4163` for why the read is not checked. |
| 51 module-level `var` from a plain `proc` | Keep; it is a drafting constraint, not a term. | `src/nimony/contracts_fir.nim:4119-4125`; the statement form is in `tests/nimony/errmsgs/tsharedglobals.nim:45`. |
| 52 two-argument command form in an expression | Keep. | `src/nifler2/parserrt.nim:148` and `:296`. |
| 53 named arguments undocumented | Keep. | `doc/tags.md:33`; `src/models/nimony_tags.nim:277`; `src/nimony/sigmatch.nim:270`. |

### Chapter text — statements to fix

These are the answers to item 4. Line numbers are `en.md` as drafted; I did not edit the file.

1. `en.md:76-79` — wrong. `proc f(): int = result = 1` followed by `5` prints `5`, so a trailing expression
   overrides an already-set `result`. Rewrite "it becomes the result if `result` was never set" as "it becomes the
   result even after `result` was set; write `discard` if that is not what you mean".
2. `en.md:63-64` — "both forms appear in the standard library" has no citation. Cite `lib/std/colors.nim:21`
   (one-expression) and `lib/std/syncio.nim:293` (block).
3. `en.md:68-69` — `doc/language.md:1552-1560` defines the parenthesised `(stmt1; stmt2; ...; ex)` form, not a
   proc body. The application to a body is probe p33; cite the probe alongside the doc line.
4. `en.md:109-111` — add the line for the message: `src/nimony/contracts_fir.nim:6065`.
5. `en.md:154-156` — the counter illustration needs `{.cast(assumeSync).}`; a plain module-level counter is
   rejected (E). Either say so or drop the `x 1 calls 1` numbers and rest on `doc/language.md:2234-2235`.
6. `en.md:186` — false as written: `pad(7, 2)` and `pad(width = 2, n = 7)` both print `14`. If the point is that
   order matters, compare `pad(2, 7)`; otherwise say the named form only documents which value is which.
7. `en.md:234-238` — "zero-initialised value" is wrong: `var v = 9` reads `before 9`. Say the routine reads the
   caller's storage before it writes, and that a fresh `var` happens to read 0.
8. `en.md:258` — the citation points at the owned-reference table. The sink parameter text is
   `doc/language.md:3626-3636`.
9. `en.md:299-301` — "accumulates into a `var seq[int]`" must mean `add` into the seq. A loop summing into
   `result` needs `result = 0` first or it fails to build. The `ref` half is confirmed: `cannot mutate n.x through
   a ref/ptr in a .noSideEffect context`.
10. `en.md:303-304` — add `doc/language.md:3156` for "There is no `noSideEffect` inference".
11. `en.md:347-349` — "ending" is wrong: `echo f` lists eight candidates and ends with
    `expected: float64 but got: proc (): int64`. Say the `int64` line is one of them.
12. `en.md:366-376` — declaration order has no doc sentence behind it. Mark it "probed at the pin" (claim 30) so
    it satisfies CONTRIBUTING rule 5.
13. `en.md:374-376` — "the lookup that fails is a missing routine, not a missing prototype" is inference; the pin
    says `undeclared identifier: 'missing'`. Cite that probe or cut the sentence.

Review bookkeeping: the header of this file says "Twenty-six claims" but the table has 30 rows; fix the count.

### Still open

The editor's leftovers stand: tuple unpacking, `noSideEffect` inference, `{.raises.}`, converters and iterators
were not probed. The default-parameter crash has no issue number, and `typenav.nim:402` is the message site, not
the pass that drops `x.0`; an issue body should carry the probe, not a pass name.

---

## Editorial pass — Aksara, 2026-11-12

Momo's verdict applied to `en.md`; `id.md` written from the corrected text, not from the draft. No code block
changed: all 26 fenced blocks in `en.md` and `id.md` are byte-identical, and the sample and its 21-line output are
untouched.

The thirteen text corrections, in Momo's order:

| # | Where | What changed |
|---|---|---|
| 1 | trailing expression | Now says the last expression wins **even after `result` is set** (`proc f(): int = result = 1` then `5` returns `5`), and tells the reader to write `discard`. |
| 2 | one-expression form | "Both forms appear in the standard library" now cites `lib/std/colors.nim:21` and `lib/std/syncio.nim:293`. |
| 3 | block body | The citation is narrowed to the parenthesised form the guide actually defines; applying it to a proc body is labelled probe p33. |
| 4 | `cannot prove that result has been initialized` | Added `src/nimony/contracts_fir.nim:6065`. |
| 5 | default re-evaluation | The module-level counter illustration is dropped, not patched: the pin rejects it from a plain `proc`. The paragraph keeps the guide's sentence, records why the demonstration is not shown, and points at the `CONTRIBUTING.md` rule. |
| 6 | named arguments | The false claim that the two calls differ is replaced with `pad(2, 7)` = `14` versus `pad(7, 2)` = `21`, and the named form's real value (it says which is which). |
| 7 | reading an `out` parameter | "Zero-initialised value" is gone: the read returns the caller's current value (`var v = 9` → `before 9`), and the paragraph says a fresh `var` merely happens to read `0`. |
| 8 | `sink` citation | `doc/language.md:911-950` → `:3626-3636`. |
| 9 | `func` and a `var` parameter | Split into the two probes the pin actually supports: `add` into a `var seq[int]` grows the caller's sequence; summing into `result` needs `result = 0` first. The `ref` rejection message is quoted. |
| 10 | `noSideEffect` inference | Added `doc/language.md:3156`. |
| 11 | `echo f` | "Ending" → the message lists eight overloads and the `int64` line is one of them. |
| 12 | declaration order | Marked as probed at the pin, which is what CONTRIBUTING rule 5 requires when there is no doc sentence. |
| 13 | missing name | The inference is replaced with the shape the pin prints: `undeclared identifier`. |

Claim 18 (the only wrong verdict) is corrected in the text, in claim 18's own terms — the caller's storage, not a
zero value. Claims 23 and 25 were narrowed by Momo and needed no text change beyond correction 9. `ERRATA.md` rows
49–53 carry his rulings and his citations; row 49 is now "defect candidate — to file", with no issue number until
one exists.

`GLOSSARY.md` entries for `out parameter`, `sink parameter`, `default argument` and `named argument` were corrected
in the same pass: the first no longer says "zero value", the second cites `:3626-3636`, the third drops the
counter probe, and the fourth says plainly that the form is probed and not quoted.

`CONTRIBUTING.md` gained one line (module-level mutable state states the `.sync` rule at first use) and one
paragraph (the `main` ruleset refuses deletion and force-push, not ordinary pushes).

Still open, and it does not block the freeze: the default-parameter crash has no issue at `nim-lang/nimony`.
