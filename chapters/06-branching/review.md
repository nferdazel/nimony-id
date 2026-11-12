# Chapter 6 — review record

Draft: 2026-11-12, Aksara. Pin: `4ba90a781b0b22d0821efaa153c129c37cef6143` (nimony `0.6.3`).
Technical review: **complete** — Momo, 2026-11-12. All 24 claims held in substance; the wording and citation
fixes below were applied in the same editorial pass, and the chapter is `frozen`.

Twenty-four claims, every one probed by the editor at the pin. Probes were separate files under `/tmp/probe6`
so a compile error in one could not hide another; the raw output of each is reproduced below. Nothing in this
chapter is written from documentation alone: where a doc sentence disagreed with the pin, the pin won and the
disagreement is listed as an open question or an `ERRATA.md` row.

## Sample verification

`nimony c -r samples/06-branching/branching.nim` — exit `0`, 11 lines on stdout:

```
B
pass
large
g
B
a
64-bit int
64
10
1
3
```

`tools/verify-samples.sh` after the sample was added prints `SUMMARY 5/5 passed, 0 failed` (chapters 2–6).

## Claims and probe output

| # | Claim | Basis | Probe output at the pin |
| --- | --- | --- | --- |
| 1 | `if`/`elif`/`else` evaluates conditions in order; the first true branch runs; `else` is optional; each branch opens a scope. | `doc/language.md:1737-1775` | `p1`: `score = 72` → `B`; `if x > 100: 1 elif x > 5: 2 else: 3` → `2` |
| 2 | An `if` expression returns the value of the branch taken. | `doc/language.md:2069-2081` | `p33` (`let y = if true: 9 else: 0`) → `y=9`; `p39` → `pos` |
| 3 | A missing `else` in an `if` expression is rejected by the definite-assignment checker, not by a syntax rule. | `src/nimony/contracts_fir.nim:4165` | `p2`: `Error: cannot prove that \`x has been initialized` (exit 1) |
| 4 | That diagnostic names `x` even when the source has no `x`. | same | `p16` (`let y = if false: 9`, no `x` anywhere): identical message |
| 5 | The check fires on any non-literal-true condition, including a constant fold: `if 1 == 1: 7` fails. | same | `p26` line 4: identical message |
| 6 | When the condition is the literal `true`, the false path is elided and the missing `else` compiles. | same | `p8`: `let y = if true: 9` → `9`, exit 0 |
| 7 | `elif` works in the expression form and the branch's last expression is its value. | `doc/language.md:2069-2081` | `p39`: `sign(-2) sign(0) sign(7)` → `neg zero pos` |
| 8 | A `case` statement selects by value; `of` takes a comma list; a range entry covers a span. | `doc/language.md:1776-1804` | `p5` → `many`; `p32` (`of 1, 2, 3`, `of 4..9`) → `low`; `p13` (`of 6..9`) → `mid`, `of 'a'..'z'` → `lower` |
| 9 | A `case` over an enum that covers every value needs no `else`. | `doc/language.md:1800-1804` | `p3` → `g`; `p41` in a proc → `b` |
| 10 | A missing enum value is rejected, and the message names it. | `src/nimony/sem.nim:2746` | `p4`: `Error: not all cases are covered; missing: {blue}` |
| 11 | For a non-enum ordinal (`int`, `char`) the message carries no missing list. | `src/nimony/sem.nim:2748` | `p6`: `Error: not all cases are covered`; `p29` (char) same text |
| 12 | Char ranges do not exhaust the type; an `else` is required, and `else: discard` is accepted. | same | `p29` fails; `p46` with `else: discard` → `lower`, exit 0 |
| 13 | A `case` expression takes the last expression of the branch, and branches may contain statements and side effects. | `doc/language.md:2086-2103` | `p15`: prints `checking two` then `two` |
| 14 | A nested `if` inside `else:` is accepted in a `case` expression. | same | `p24`: `n = 42` → `medium`; `p42` → `large` |
| 15 | `elif` is rejected inside a `case`, with a message telling you to nest an `if` in `else`. | `src/nimony/sem.nim:3292-3307`, message at `:3305` | `p18`: ``Error: `elif` branch in a `case` is not supported; use `else:` with a nested `if``` plus a second line for the following `else` |
| 16 | A `case` on a `string` is not required to have an `else`. | `doc/language.md:1811-1812`; check skipped at `src/nimony/sem.nim:3287-3290` | `p17`: `case "go"/"stop"` over `"go"` compiles → `1` |
| 17 | In a `case` **statement**, an unmatched string does nothing. | same | `p37`: `var r = -1`, selector `"zzz"` → `r=-1` |
| 18 | In a `case` **expression**, an unmatched string **executes the last** `of` branch as the fallback and takes its value — side effects included. | same | `p35`: last branch `"wait": 333` → `r=333`; `p36` reordered → `222`; Momo's `a4`/`a5` print the branch line then its value; editor's `fallback.nim` / `fallback2.nim` reproduce both orders |
| 19 | Adding `else` to a string `case` expression makes the miss land there. | same | `p40`: `else: 999` → `r=999` |
| 20 | `when` conditions must be constant; the branch not taken is not semantically checked. | `doc/language.md:1872-1901` | `p43`: `when false: let q: int = "not an int"` compiles, prints `compiled` |
| 21 | A non-constant `when` condition is a compile-time error. | same | `p30`: `Error: cannot evaluate expression at compile time:` / `undeclared identifier: x` |
| 22 | `when` does not open a new scope. | `doc/language.md:1872-1901` | `p44` at module level → `42`; `p45` inside a proc → `42` |
| 23 | The `when` expression form produces a value. | `doc/language.md:2082-2084` | `p7`: `64 bit`, then `wide` |
| 24 | A `block` is an expression whose value is its last expression, and `break <name>` leaves the named block from inside nested loops. | `doc/language.md:1946-1974`, `:2105-2119` | `p20` (block expression summing `1..4`) → `10`; `p9` (`break myblock` from two loops) → `2 2` / `true` |

Supporting probes for the break rules:

- `p10` — unlabelled `break` in an inner loop: outer loop continues, output `0 0 / 1 0 / 2 0 / done`.
- `p11` — unlabelled `break` inside a bare `block` inside a `for`: leaves the loop, `body 1` then `after`.
- `p19` — unlabelled `break` outside any loop: ``Error: `break` only possible within a loop or a `block` statement``.
- `p12` — `break nosuchblock`: `Error: undeclared identifier: nosuchblock`.

Documentation used as the statement of a rule (not probed, because there is no behaviour to observe):
`doc/differences.md:23` for the unlabelled-break delta and its `{.feature: "anonBlockBreaks".}` escape hatch.

## Verdicts (Momo, 2026-11-12)

Verifier run once at the pin: `SUMMARY 5/5 passed, 0 failed`, exit 0. The sample's 11 lines were diffed against
the block in the chapter — empty. Twenty-one probes re-run; the rest stayed the editor's runs.

| # | Verdict | Basis at `4ba90a7` |
| --- | --- | --- |
| 1 | PASS | `doc/language.md:1737-1775`; scope example `:1758-1770`; sample prints `B` |
| 2 | PASS | `doc/language.md:2069-2080` (2081 blank); sample prints `pass` |
| 3 | PASS | `src/nimony/contracts_fir.nim:4165`; `b1` exit 1 |
| 4 | PASS, strengthened | `b3` (`let z`) and `b5` (inside a proc) print the same `x` — it is the result temporary |
| 5 | PASS | `b4` (`if 1 == 1: 7`) → identical message |
| 6 | PASS | `b2` → `9`, exit 0 |
| 7 | PASS | `g1` → `neg zero pos`; `doc/language.md:2080` allows `elif` |
| 8 | PASS, cite fixed | `:1776-1804`; `:1806` starts the allowed-types paragraph |
| 9 | PASS, cite fixed | `:1800-1804`; `:1806` is the next paragraph |
| 10 | PASS | `src/nimony/sem.nim:2746`, exact string |
| 11 | PASS | `src/nimony/sem.nim:2748`; `e1` prints the bare message |
| 12 | PASS | `e1` fails; `e2` with `else: discard` prints `lower`, exit 0 |
| 13 | PASS | `doc/language.md:2086-2103`; `p15` |
| 14 | PASS | `doc/language.md:2086-2103`; sample grade → `B` |
| 15 | PASS on code, quote corrected | `src/nimony/sem.nim:3292-3307`, message `:3305`; an `int` selector adds `not all cases are covered` first |
| 16 | PASS, cite fixed | gate `elif not isString:` at `:3287`, call at `:3290`; `:3288-3289` are comments |
| 17 | PASS | `h1` → `-1` |
| 18 | CORRECTED — mechanism | Value reproduces (`a1` 222, `a2` 111), but the branch **runs**: `a4`/`a5` print `stop branch` then `222`; `a6` from a proc |
| 19 | PASS | `a3` → `999` |
| 20 | PASS | `doc/language.md:1892-1895`; `p43` |
| 21 | PASS | `doc/language.md:1889-1890`; `p30` |
| 22 | PASS | `doc/language.md:1891`; `d1` and `d2` both `42` |
| 23 | PASS | `doc/language.md:2082-2084`; sample prints `64` |
| 24 | PASS | `doc/language.md:1946-1974` (unlabelled rule `:1963`), `:2105-2119`; sample `10`; `f1` → `body 0` / `after` |

Both statements asked to be backed hold: `e1` fails and `e2` compiles with `else: discard`; `f1` prints
`body 0` then `after`, never `never`, so the unlabelled `break` left the loop.

## Rulings

**A. String `case` expression, no `else`, no match.** Split ruling: the skipped exhaustiveness check is intended
and documented (`src/nimony/sem.nim:3287`, `doc/language.md:1811-1812`); the fallback is not documented anywhere,
is deterministic at this pin, and is a codegen hole — the last `of` branch body **executes**, side effects
included. Not a rule to teach; a defect candidate for the watch list. The editor reproduced both orders
(`stop branch`/`222`, then `go branch`/`111`) before rewriting the section.

**B. The `x` message.** Stable, quoted verbatim. `x` is the result temporary the expression reads — proven by
`b3`/`b5` — so "it is not your variable" is exact. The literal-`true` sentence stays, but as an observation
("the false path is dead code and is elided" is a mechanism not visible from outside).

**C. `elif` inside `case`.** Intended. The comment at `src/nimony/sem.nim:3292-3304` says why: erroring replaced a
silent drop of everything after the `elif`. The watch-list row stays, with the third error line added.

**D. `when` scope.** Right instruction. `doc/language.md:1891` states no-scope as a rule, so it is stated plainly,
and the warning stays: the name only exists when the branch was taken.

## Applied in the editorial pass

1. `if`-expression section: the `x` paragraph now says the message prints `x` whatever the binding is called,
   including inside a proc.
2. `case` statement: citations `:1776-1806` → `:1776-1804` and `:1800-1806` → `:1800-1804`.
3. `elif`-in-`case`: the error block gained `Error: not all cases are covered` as its first line, and the
   explanation now separates the collateral error from the two `elif`/`else` errors.
4. String selector: citation `:3288-3290` → `:3287-3290`.
5. String `case` expression: repaired to the executing-fallback wording, with the two-branch example and output,
   and the ruling sentence.
6. Checks 5 and 6 updated to match the three-error output and the executed branch.

`ERRATA.md` watch list: the string row now carries the sides-effect finding and the ruling; the `elif` row gained
the third error line. The Chapter 7 row was checked against Momo's reproducible shapes and left as written.

## Definition-of-done state

| Gate | State |
| --- | --- |
| 1. One job | done — branching and its expression forms only; `while`/`for`/`continue` stay in Chapter 7, enum and object design in 11–12 |
| 2. Samples run | done — `samples/06-branching/branching.nim`, exit 0, 11 lines matching the chapter |
| 3. Technical review | done — Momo 2026-11-12, 24 verdicts, 6 fixes applied |
| 4. Editorial pass | done — 2026-11-12 |
| 5. Both languages | done — `en.md` 2.529 words, `id.md` 2.248 words, identical frontmatter, 15 sections each |
| 6. Frozen means frozen | frozen 2026-11-12 |

## Glossary

Added in this handoff: `if expression`, `case expression`, `when`, `exhaustive case`, `labelled break`,
`block expression` — six terms, each with a pin-level source in `GLOSSARY.md`.
