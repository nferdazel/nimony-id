# Chapter 11 review sheet — Objects, Enums, and Distinct Types

Draft: `chapters/11-objects-enums-distinct/en.md` (`status: drafting`).
Sample: `samples/11-objects-enums-distinct/objects.nim`.
Toolchain: `~/.local/opt/nimony/4ba90a7`, pin `4ba90a781b0b22d0821efaa153c129c37cef6143` (nimony 0.6.3).
Verifier: `./tools/verify-samples.sh` → `SUMMARY 10/10 passed, 0 failed`, exit 0.

Each claim below is what the chapter teaches. The probe is the file in
`/Users/sachiel/.openmausbot/workspaces/be336972-1e63-4f00-9916-c76cc8e33654/ch11-probes/`, run with
`$NIMONY_HOME/bin/nimony c -r <file>`; output is pasted raw, trimmed to the lines that matter. `nim2check.nim`
is the same file compiled with the host compiler `~/.local/opt/nim-2.4.0`, used only where the chapter claims a
Nim 2 difference.

Every claim you verify replaces a row with `held` or `wrong, because …`; do not rewrite the rows I cite.

| # | Claim in the chapter | Probe | Raw output at the pin | Source in chapter |
| --- | --- | --- | --- | --- |
| 1 | An object declaration names a new type with named fields. | `o1.nim` | `1` / `2` / `9` / `0` / `0`, exit 0 | §Objects; `doc/language.md:476` |
| 2 | An unwritten field takes its type's default: `0`, `false`, empty string. | `o3.nim` | `0` / `0` / `false` / `3`, exit 0 | §Objects |
| 3 | Construction fills the fields named and leaves the rest at their defaults. | `o10.nim` | `1`, exit 0 (`P(y)` never named) | §Objects; `doc/language.md:568` |
| 4 | A field may carry its own default; it applies to `T()` and to any field the constructor omits. | `o5.nim` | `2` / `hi` / `7`, exit 0 | §Objects; `doc/language.md:652` |
| 5 | A field the type does not have is rejected at the constructor. | `o14.nim` | `o14.nim(4, 11) Error: undeclared field: 'z' for type P`, exit 1 | §Objects |
| 6 | A field is reachable from another module only with `*`; an unmarked field reads as undeclared. | `vis_a.nim`, `vis_b.nim` | `vis_b.nim(3, 26) Error: undeclared field: 'hidden' for type Widget`, exit 1 | §Objects; `doc/language.md:546-549` |
| 7 | Assignment copies every field; the copy is independent. | `o2.nim` | `1` / `99` / `1` / `42`, exit 0 | §Copy at assignment; `doc/language.md:564` |
| 8 | The copy reaches inside a field: a `seq` field's elements are copied, not shared. | `o12.nim` | `1` / `99`, exit 0 (`a.items[0]` stayed `1`) | §Copy at assignment |
| 9 | A by-value object parameter cannot write the caller's object; a `var` parameter can. | `o2.nim` | `bump(a)` prints `1`; `bumpVar(a)` then `a.x` is `42`, exit 0 | §Copy at assignment |
| 10 | Objects are nominal: two objects with identical fields are different types, and assignment between them is rejected. | `n1.nim` | `n1.nim(8, 5) Error: type mismatch: got: B but wanted: A`, exit 1 | §Objects are nominal; `doc/language.md:548-549` |
| 11 | `==` between two values of the same object type compares field by field, a `seq` field's contents included. | `o17.nim`, `o18.nim` | `o17`: `true` / `false`, exit 0. `o18`: `true` / `false` / `false`, exit 0 | §Objects are nominal — **measured, no doc line found** |
| 12 | `==` between two different object types is rejected. | `o16.nim` | `o16.nim(11, 14) Error: Type mismatch` … `[1] A does not match constraint Enum (… comparisons.nim(5, 1))`, exit 1 | §Objects are nominal |
| 13 | `echo` on a user-defined object is a type error listing `write` overloads; it does not apply `$`. | `o6.nim` | `write stdout, P(x: 1)` / `[2] expected: string but got: P` / `[2] expected: int64 but got: P` …, exit 1 | §Printing an object |
| 14 | With a `$` defined, `echo $p` prints and `echo p` still does not. | `o8.nim` | `(1, 2)`, exit 0 (with `$` applied); `o6` above without | §Printing an object |
| 15 | Nim 2 does apply the `$` overload inside `echo`. | `nim2check.nim` (nim 2.4.0) | `P1`, exit 0 | §Printing an object |
| 16 | The same holds for a distinct type with a `$`: `echo $m` prints, `echo m` fails. | `d11.nim`, `d9.nim` | `d11`: `4m` / `4`, exit 0. `d9`: `write stdout, Meters(4)` / `[2] expected: string but got: Meters`, exit 1 | §Printing an object |
| 17 | An enum is ordered; `ord` returns the position, comparison follows the order, a value may be qualified by its type. | `e1.nim` | `0` / `3` / `3` / `true` / `east`, exit 0 | §Enums; `doc/language.md:182-192` |
| 18 | The built-in `$` prints the value's declared name. | `e1.nim`, `e12.nim` | `e1`: `east`. `e12`: `c` / `b`, exit 0 | §Enums; `doc/language.md:228` |
| 19 | An enum indexes an array and `for` walks its values in order. | `e5.nim` | `5` / `3` / `red` / `green` / `blue`, exit 0 | §Enums; `doc/language.md:223-224` |
| 20 | Explicit ordinals must ascend, an unlisted value is the previous plus one, gaps are allowed. | `e8.nim` | `2` / `4` / `89` / `true`, exit 0 | §Explicit ordinals; `doc/language.md:213-222` |
| 21 | The `(ord, "name")` pair form attaches a string that `$` prints. | `e9.nim` | `1` / `5` / `Q`, exit 0 | §Explicit ordinals; `doc/language.md:228-240` |
| 22 | A hole makes the enum non-ordinal: `inc` is unavailable. | `e2.nim` | `e2.nim(10, 1) Error: Type mismatch at [position]` … `[1] TokenType does not match constraint T (… arithmetics.nim(17, 1))`, exit 1 | §Explicit ordinals; `doc/language.md:223-225` |
| 23 | On a hole-free enum `inc`, `succ` and `pred` work. | `e4.nim` | `green` / `1` / `` (blank) / `red`, exit 0 — see claim 25 for the blank line | §Explicit ordinals |
| 24 | Enum values live in the module's ordinary scope, so naming one `low` or `high` shadows the built-in and breaks `ord`. | `e10.nim` | `e10.nim(4, 9) Error: Type mismatch at [position]` … `[1] auto does not match constraint T (… system.nim(207, 1))`, exit 1 | §Explicit ordinals |
| 25 | An enum has no upper bound check: `inc` past the last member and `Color(7)` both build and print an empty line. | `e13.nim`, `e14.nim` | `e13`: `3` / `` / `false`, exit 0. `e14`: `` (one blank line), exit 0 | §Explicit ordinals; ERRATA watch row |
| 26 | Nim 2 raises on the same increment. | `nim2check.nim` (nim 2.4.0) | `2` then `Error: unhandled exception: over- or underflow [OverflowDefect]`, exit 1 | §Explicit ordinals; ERRATA watch row |
| 27 | A distinct type is incompatible with its base, with an explicit conversion each way. | `d2.nim`, `doc/language.md:1058-1065` | `5` / `3`, exit 0 | §Distinct types |
| 28 | A distinct type has the base's size. | `d13.nim` | `8` / `8`, exit 0 | §Distinct types |
| 29 | Neither direction converts implicitly, and both messages name `int64` because `int` and `int64` are the same type at the pin. | `d1.nim`, `d12.nim` | `d1`: `type mismatch: got: int64 but wanted: Meters`, exit 1. `d12`: `type mismatch: got: Meters but wanted: int64`, exit 1 | §Distinct types; Chapter 9 |
| 30 | Operators are not inherited: `+` and `==` on two `Meters` values are both type errors before you write them. | `d3.nim`, `d4.nim` | `d3`: `type mismatch: got: auto but wanted: int64`, exit 1. `d4`: `[1] expected: int64 but got: Meters (… comparisons.nim(64, 1))` …, exit 1 | §Distinct types |
| 31 | `{.borrow.}` gives the base's implementation, typed as the distinct type. | `d10.nim` | `5`, exit 0 | §Distinct types |
| 32 | A hand-written body is the same thing spelled out. | `d6.nim` | `5`, exit 0 | §Distinct types |
| 33 | A distinct type over an object keeps field access through the conversion. | `d5.nim` | `4`, exit 0 | §Distinct types |

Sample output: 36 lines, identical to the block in `en.md` under §Samples, produced by
`nimony c -r samples/11-objects-enums-distinct/objects.nim` at the pin.

## Questions for the reviewer

**A. Object `==` (claims 11-12).** It works between two values of the same object type and compares field by
field, but I could not name the source: `src/nimony/magics.nim` has no `EqObject`, `lib/std/system` has no
generic `==` for object types, and `doc/language.md` does not mention object equality. Is it a compiler-derived
comparison, and what file and line should the chapter cite instead of "measured at the pin"? If it is invisible
on purpose, the chapter should say what to rely on.

**B. `echo` does not apply `$` (claims 13-16).** Nim 2 prints `P1`; the pin writes `P(x: 1)` into the error
instead. Is that intended narrowing (then it is a Nim 2 delta the book should teach, and I move it into a delta
box), or a defect (then it goes to ERRATA and the chapter stops calling it deliberate-looking)?

**C. Enum bounds (claims 25-26).** `inc` past `high` and `Color(7)` produce a value outside the enum with no
check, printed as an empty line; Nim 2 raises `OverflowDefect`. Defect candidate, or intended (and if intended,
which source line states that an enum value may be out of range)?

**D. `borrow` for distinct operators (claims 30-32).** Is `{.borrow.}` the recommended way to give a distinct
type its base's operators at the pin, or should the book teach the hand-written body and treat `borrow` as a
shortcut? Both run; I want the sentence the chapter leads with.

**E. Shadowing (claim 24).** Naming an enum value `low` or `high` breaks `ord` in the whole module with an
error that names `system.nim(207, 1)` and never mentions the enum. Defect candidate or ordinary scoping the
reader should simply be warned about?

## ERRATA candidates

1. **`echo` does not consult a user-defined `$`** — chapter 11, §Printing an object, `4ba90a7`. Keep or drop
   depends on B. Line to cite if kept: `lib/std/syncio.nim:468` (the `write` instantiation that fails),
   probe `o6.nim`.
2. **Enum values are not bounds-checked on `inc` or conversion** — chapter 11, §Explicit ordinals, `4ba90a7`.
   `inc blue` gives ordinal `3`; `Color(7)` builds. Both print an empty line. Cite `e13.nim`, `e14.nim`, and
   Nim 2's `OverflowDefect` from `nim2check.nim`. Watch row if you judge it intended, defect candidate if not.
3. **Objects compare with `==` but no source states it** — chapter 11, §Objects are nominal, `4ba90a7`.
   Documentation gap rather than a defect: the behaviour is useful and field-wise. Cite `o17.nim`, `o18.nim`.

## What I could not settle in one command

Nothing. Every row above is a single compile-and-run, except claim 11's source attribution, which is question A
rather than an unsettled behaviour — the behaviour itself is measured three ways (`o17`, `o18`, `o16`).

## Technical review — Momo

Reviewer: Momo (Head of Engineering), 2026-11-12. Pin
`4ba90a781b0b22d0821efaa153c129c37cef6143` (nimony 0.6.3), toolchain
`~/.local/opt/nimony/4ba90a7`; Nim 2 contrasts with `~/.local/opt/nim-2.4.0`.

I ran every probe in `ch11-probes/` myself with `$NIMONY_HOME/bin/nimony c -r`; every line I quote
below is from my own run. I added `rv1`–`rv17` to the same folder for the checks this review needed.

My verifier run:

```
$ ./tools/verify-samples.sh
toolchain /Users/sachiel/.local/opt/nimony/4ba90a7/bin/nimony 0.6.3 pin 4ba90a7
PASS samples/11-objects-enums-distinct/objects.nim exit=0
SUMMARY 10/10 passed, 0 failed
VERIFY_EXIT=0
```

The sample's 36 output lines are byte-identical to `en.md:303-338` (`diff` empty, exit 0), and
`nimony c -r samples/11-objects-enums-distinct/objects.nim` exits 0.

### Verdict per claim

| # | Verdict | Evidence from my run |
| --- | --- | --- |
| 1 | held | `o1`: `1` / `2` / `9` / `0` / `0`, exit 0. |
| 2 | held | `o3`: `0` / `0` / `false` / `3`, exit 0. |
| 3 | held | `o10`: `1`; `rv1`: `echo Point(x: 1).y` prints `0`, exit 0. |
| 4 | held | `o5`: `2` / `hi` / `7`; `rv3`: `P(a: 7).b` prints `hi`, exit 0. |
| 5 | held | `o14`: `undeclared field: 'z' for type P`, exit 1. |
| 6 | held | `vis_b`: `undeclared field: 'hidden' for type Widget`, exit 1. |
| 7 | held | `o2`: `1` / `99` / `1` / `42`, exit 0. |
| 8 | held | `o12`: `1` / `99`, exit 0. |
| 9 | held | `o2`: `bump` prints `1`, `bumpVar` then `a.x` is `42`; `rv4` `cannot mutate expression v.x`, `rv5` and `rv6` `cannot pass v.items to var/out T parameter`, all exit 1. |
| 10 | held | `n1`: `type mismatch: got: B but wanted: A`, exit 1. |
| 11 | held, source found | `o17`: `true` / `false`; `o18`: `true` / `false` / `false`. The source is `lib/std/system.nim:463`, `func ==*[T: tuple|object]`, not compiler magic; see A. |
| 12 | held | `o16`: `[1] A does not match constraint Enum (comparisons.nim(5, 1))`, then `[2] expected: A but got: B (system.nim(463, 1))`, exit 1. |
| 13 | held | `o6`: `write stdout, P(x: 1)` plus the `write` candidate list, exit 1. |
| 14 | held | `o8`: `(1, 2)`, exit 0; `rv2`: with `$` defined, `echo P(x: 1)` still fails inside `write`, exit 1. |
| 15 | held | `nim2check` (2.4.0): `P1`, exit 0. |
| 16 | held | `d11`: `4m` / `4`, exit 0; `d9`: `write stdout, Meters(4)` plus candidates, exit 1. |
| 17 | held | `e1`: `0` / `3` / `3` / `true` / `east`, exit 0. |
| 18 | held | `e1`: `east`; `e12`: `c` / `b`, exit 0. |
| 19 | held | `e5`: `5` / `3` / `red` / `green` / `blue`, exit 0. |
| 20 | **wrong** | The pin does not enforce ascending ordinals: `rv11` (`a = 5, b = 3, c`) compiles, prints `5` / `3` / `4` / `false` / `b`, exit 0. "Unlisted = previous + 1" holds (`rv12`: `2` / `3`); gaps hold (`e8`: `2` / `4` / `89` / `true`). See corrections 6 and ERRATA 4. |
| 21 | held | `e9`: `1` / `5` / `Q`, exit 0. |
| 22 | held | `e2`: `inc` rejected with `TokenType does not match constraint T (arithmetics.nim(17, 1))`, exit 1; `rv13`: `invalid array index type: T`, exit 1. |
| 23 | half | `e4`: `green` / `1` / `` (blank) / `red`, exit 0. `inc` and `pred` in range work; `succ(blue)` leaves the set and prints the same empty line as claim 25. The row must not say all three simply "work". |
| 24 | **wrong (cause)** | `e10`: `ord(low)` gives `[1] auto does not match constraint T (system.nim(207, 1))`, exit 1, but the enum member is intact: `rv9` `ord(Level.low/high/mid)` prints `0` / `1` / `2`, exit 0. The built-in `low`/`high` procs (`basic_types.nim:113-116`) win the unqualified name; the member does not shadow them. See E. |
| 25 | held | `e13`: `3` / `` / `false`, exit 0; `e14`: one blank line, exit 0; `rv17`: `Color(7)` and `Color(-1)` from variables both build, two blank lines, exit 0. |
| 26 | held | `nim2check`: `2` then `OverflowDefect`, exit 1. The conversion half is different; see correction 8. |
| 27 | held | `d2`: `5` / `3`, exit 0. |
| 28 | held | `d13`: `8` / `8`, exit 0. |
| 29 | held | `d1`: `got: int64 but wanted: Meters`, exit 1; `d12`: first line `got: Meters but wanted: int64`, exit 1. A cascade follows because the failed declaration poisons `i`; quote the first line only. |
| 30 | held | `d3`: `got: auto but wanted: int64`, exit 1; `d4`: candidate list including `[1] expected: int64 but got: Meters (comparisons.nim(64, 1))`, exit 1. |
| 31 | held | `d10`: `5`, exit 0. |
| 32 | held | `d6`: `5`, exit 0. |
| 33 | held | `d5`: `4`, exit 0. |

### Answers to A–E

One line each:

| Q | Answer |
| --- | --- |
| A | `lib/std/system.nim:463`, `func ==*[T: tuple|object]`, field by field — source exists, doc gap, not an open question. |
| B | Documented narrowing: the `echo` template applies no `$` (`doc/language.md:466-471`, `syncio.nim:465-468`) — Nim 2 delta, drop ERRATA 1. |
| C | Watch row: checks key on `range` types only (`contracts_fir.nim:2551-2569`, `:2492-2500`); no source promises an enum check. |
| D | `borrow` is intended and documented (`doc/porting.md:51-62`, `semborrow.nim:17-60`); lead with the explicit body, use `func`. |
| E | Ordinary scoping: the built-in `low`/`high` procs win the unqualified name (`basic_types.nim:113-116`); qualify `Level.low`, no defect. |

Detail:

**A. Object `==` (claims 11–12).** Not compiler magic and not unmeasured: it is the library generic
`func ==*[T: tuple|object](x, y: T): bool` at `lib/std/system.nim:463`, which walks `fields(x, y)` and
returns false on the first `!=`; a `seq` field therefore compares through the seq `==`
(`lib/std/system.nim:470-480`). `doc/language.md` has no paragraph on object equality — that is a
documentation gap, not an open question. `o16` already cites the decisive candidate:
`[2] expected: A but got: B (system.nim(463, 1))`. The chapter must cite that line and stop calling the
source unknown.

**B. `echo` does not apply `$` (claims 13–16).** Documented, so intended: `doc/language.md:466-471`
prints Nimony's `echo` template (`for a in unpack(): stdout.write a`), with no `$` converter;
`lib/std/syncio.nim:465-468` is the same code. `doc/porting.md:346-347` says "Objects deliberately have
no generic `$`: define one for the object type instead", and `:341` records `$aDistinct` → `$Base(x)`.
This is a Nim 2 delta the book teaches, not a defect: drop ERRATA candidate 1.

**C. Enum bounds (claims 25–26).** Intended by the machinery, but undocumented. `checkSuccPred`
(`contracts_fir.nim:2551-2569`) returns unless `staticRangeBounds` finds a `range[lo..hi]` type; enums
are not range types. The conversion side is the same: `checkRangeAssign` (`contracts_fir.nim:2492-2500`,
called for `ConvX`/`HconvX` at `:4207-4213`) only checks range targets. No source line promises a check
on enum `inc` or conversion, so keep it as a watch row, not a filed defect. The chapter must keep saying
it is not correct behaviour.

**D. `{.borrow.}` for distinct operators (claims 30–32).** Intended and documented:
`doc/porting.md:51-62` shows exactly `proc ==*(a, b: MyDistinct): bool {.borrow.}` and warns that
`{.borrow.}` does not carry `noSideEffect` — use `func`. `semborrow.nim:17-60` generates the body by
converting each distinct parameter to the base with `dconv`, calling the base operation, and converting
the return back; `tdistinctnoeq.nim` expects the unborrowed `==` to fail. Lead with the hand-written body
because it states the operation, present `borrow` as the shortcut when the operation is exactly the
base's, and add the func/proc caveat.

**E. `low`/`high` shadowing (claim 24).** Ordinary scoping, not a defect. The built-ins are procs over
`typedesc` (`lib/std/system/basic_types.nim:113-116`), so in argument position the unqualified name
resolves to the proc, not the enum member; the member is intact under qualification (`rv9`: `Level.low`
is `0`). The chapter's causal sentence is backwards and its advice is weaker than needed: qualify the
value (or avoid the names). The diagnostic is poor — it names `system.nim(207, 1)` and never the enum —
but a bad message is not a language defect.

### ERRATA rulings

1. **`echo` does not consult a user-defined `$` — drop.** Documented at `doc/language.md:466-471`,
   `lib/std/syncio.nim:465-468`, `doc/porting.md:346-347`. Move it to a Nim 2 delta box; no ERRATA row.
2. **Enum values are not bounds-checked — keep as a watch row.** Cite `contracts_fir.nim:2551-2569` and
   `:2492-2500` for the range-only checks, probes `e13`, `e14`, `rv17`. Sharpen the Nim 2 half: the
   literal `Color(7)` is a compile error (`rv14`: `7 can't be converted to Color`), a computed one raises
   `RangeDefect` (`rv15`), and `inc` raises `OverflowDefect` (`nim2check`).
3. **Object `==` with no source — keep as a documentation-gap row, rewritten.** The source is
   `lib/std/system.nim:463`; the gap is that `doc/language.md` never mentions object equality. Not a
   defect.
4. **New: descending explicit ordinals are accepted**, against `doc/language.md:213-215` ("have to be in
   ascending order"). `rv11`: `a = 5, b = 3, c` compiles, ord `5` / `3` / `4`, `a < b` is `false`, `b`
   prints, exit 0. `takeExplicitValue` (`semdecls.nim:655-660`) only marks a hole when the value is not
   the previous plus one; there is no order check. Watch row, documentation gap — do not file a defect
   without a source that promises the check.

### Text corrections in `en.md`

1. `44`: split the citation. `doc/language.md:568-583` only says fields may be omitted; that an omitted
   field takes its type's default (`0`, `false`, empty string) is measured (`o1`, `o3`), not in that
   paragraph.
2. `128`: after the `A does not match constraint Enum` line, add the decisive candidate the reader will
   see: `[2] expected: A but got: B (system.nim(463, 1))`.
3. `131-134`: replace the "open question for Engineering" sentence. `==` is `lib/std/system.nim:463`,
   `func ==*[T: tuple|object]`, field by field through `fields`; say the manual has no paragraph on it
   (documentation gap) and cite the line.
4. `148-159`: replace "Whether that stays is a question for Engineering" with the documented fact: the
   `echo` template (`doc/language.md:466-471`, `syncio.nim:465-468`) applies no `$`, and
   `doc/porting.md:346-347` says objects deliberately have no generic `$`. Move the Nim 2 contrast into
   a delta box and keep claim 15.
5. `188-189`: "the same text the value was declared with" needs "unless the value carries an attached
   string; see the next section".
6. `193-194`: after the ascending rule, add that the pin does not enforce it. `a = 5, b = 3` compiles
   (`rv11`), the enum becomes holey, ord is `5` / `3` / `4`, and comparisons follow the values (`a < b`
   is `false`). Teach the doc rule, warn that a descending list is not rejected.
7. `218-220`: flip the cause. The enum member does not shadow the built-ins; the `low`/`high` procs
   (`basic_types.nim:113-116`) win the unqualified name, so `ord(low)` sees the proc. `Level.low` is `0`
   (`rv9`). Advise qualification, not just avoidance.
8. `222-226`: "Nim 2 raised on both" is imprecise. A literal `Color(7)` is a compile error in Nim 2
   (`rv14`), a computed one raises `RangeDefect` (`rv15`), and `inc blue` raises `OverflowDefect`
   (`nim2check`). Add the mechanical reason: the checks key on `range` types
   (`contracts_fir.nim:2551-2569`, `:2492-2500`), so an enum is unchecked at the pin.
9. `249-251`: the `int64` naming depends on the expression, not on the distinct's base. An `int` literal
   names `int64` even for `distinct int32` (`rv7`), while a value already held in `int32` names `int32`
   (`rv8`). Reword; do not tell readers porting an `int32` distinct to expect `int64` in every message.
10. `254-267`: lead with the explicit body (`Meters(int(a) + int(b))`) as the definition, then
    `{.borrow.}` as the shortcut; add that `borrow` does not carry `noSideEffect`, so pure operators are
    `func` (`doc/porting.md:51-62`).
11. `265`: "borrow copies the base type's implementation" → the compiler generates a body that converts
    each distinct operand to the base, calls the base operation, and converts the result back
    (`semborrow.nim:17-60`).
12. `215`: `succ(blue)` prints an empty line because it produces ordinal `3` — the same missing check as
    below; say that instead of leaving "(out of range, see below)" unexplained.
13. `367-368` (Check 12): "check `ord` before incrementing" does not prevent anything; replace with "do
    not `inc` a value that is already `high`; compare first".

### Left open

None. Every row above is a single compile-and-run at the pin, except claim 20 (`rv11`), claim 24
(`rv9` plus the source), and the Nim 2 contrasts, which were run with `nim 2.4.0` (`nim2check`, `rv14`,
`rv15`).

One statement in `en.md` had no source and is also wrong at the pin: the "must ascend" rule at line 193
(`rv11`). Everything else that states compiler behaviour now has a probe and, wherever one exists, a
source line.
