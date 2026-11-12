# Chapter 13 — technical review packet

Chapter: 13, References, Pointers, and Explicit Nilability
Manuscript: `chapters/13-references-pointers-nil/en.md` (status `drafting`, 2,375 words)
Sample: `samples/13-references-pointers-nil/refs.nim`
Pin: `4ba90a781b0b22d0821efaa153c129c37cef6143` (nimony 0.6.3), toolchain `~/.local/opt/nimony/4ba90a7`
Host compiler for Nim 2 contrasts: `~/.local/opt/nim-2.4.0` (Nim 2.4.0)
Probe sources: `/Users/sachiel/.openmausbot/workspaces/be336972-1e63-4f00-9916-c76cc8e33654/ch13-probes/`
Prepared: 2026-11-13. Reviewer: Momo. Nothing here is a verdict; request is one line per question A–F and a
verdict per claim.

## Verifier, as run by me

```
$ ./tools/verify-samples.sh
PASS samples/13-references-pointers-nil/refs.nim exit=0
SUMMARY 12/12 passed, 0 failed
EXIT=0
```

The committed sample output, byte-compared against the block in `en.md` §Samples:

```
$ nimony c -r samples/13-references-pointers-nil/refs.nim
2
6
0
42
20
```

Five lines, no trailing output; the block in `en.md` is identical.

## Source lines the chapter leans on

| Claim | Source |
| --- | --- |
| traced vs untraced, `ref` vs `ptr` declared with those keywords | `doc/language.md:774-783` |
| `ref`/`ptr`/`pointer`/`cstring` not nil by default | `doc/language.md:786-788`, `doc/language.md:839`, `doc/lenientnils.md:7-19` |
| `nil T` prefix, nullable forms | `doc/language.md:841-853`, `doc/lenientnils.md:65-75` |
| implicit dereference through `.` and `[]` | `doc/language.md:793-807` |
| `addr v : ptr T` | `doc/language.md:788-791` |
| `unchecked` on ref/ptr/pointer/cstring | `doc/language.md:868-878`, `doc/lenientnils.md:102-115` |
| `lenientnils` restores Nim 2 nilability per module | `doc/lenientnils.md:141-155` |
| not-nil type has no default value; globals owe an initial value, locals do not | `src/nimony/contracts_fir.nim:5798-5822`, comment at `:5804-5811` |
| `expected non-nil value` | `src/nimony/contracts.nim:280` (`wantNotNil`), reached from `checkNilMatch` |
| `cannot analyze expression is not nil` / `cannot prove expression is not nil` | `src/nimony/contracts.nim:284-301` |
| globals deliberately un-analysable (thread sharing) | `src/nimony/contracts.nim:246-271`, comment at `:256-259` |
| `cannot prove that r has been initialized` | `src/nimony/contracts.nim:357` |
| `is nil` / `is not nil` facts | `src/nimony/inferle.nim:137-142` |
| `new` is `func new*[T: ref](x: out T)` | `lib/std/system.nim:200` |
| object `==` is structural, reference `==` is the `EqRef` magic | `lib/std/system.nim:462-468`, `src/nimony/magics.nim:64` |

## Claims, probe by probe

Probe ids are files under `ch13-probes/`. "Output" is what the pinned `nimony c -r` printed, verbatim
(messages trimmed only of the `nifmake` and `FAILURE:` tail).

| # | Claim as written in `en.md` | Probe | Output | Section |
| --- | --- | --- | --- | --- |
| 1 | A `ref` parameter writes the shared cell with no `var` | `f04` | `2` | Two ways to refer |
| 2 | Writing through the reference and rebinding it are different rights; rebinding is `cannot mutate expression c` | `j02` | `Error: cannot mutate expression c` | Two ways to refer |
| 3 | `c[].n` is legal and equivalent to `c.n` | `j01` | `1` | Two ways to refer |
| 4 | `addr v : ptr T`, `p[]` writes the storage | `f06` | `9` | Two ways to refer |
| 5 | `addr arr[1]` writes the element | `f07` | `7` | Two ways to refer |
| 6 | A not-nil type is printed with `not nil` spelled out | `r05`, `c08` | see row 9 | A pointer type that cannot be nil |
| 7 | `var r: Node = nil` → `expected non-nil value` | `e05`, `r04`, `g03` | `Error: expected non-nil value` | A pointer type that cannot be nil |
| 8 | Module-level not-nil declaration with no init → no-default-value message | `r05`, `b01`, `h06`, `c06` | `'base' is of type 'ref Node.Obj not nil', which has no default value (it contains a not-nil pointer): give it an initial value` | A pointer type that cannot be nil |
| 9 | Same message for an array of not-nil refs | `c08` | `'arr' is of type 'array[0..2, ref Node.Obj not nil]', which has no default value (it contains a not-nil pointer): give it an initial value` | A pointer type that cannot be nil |
| 10 | Same message through an object field | `h06` | `'p' is of type 'Pair', which has no default value (it contains a not-nil pointer): give it an initial value` | A pointer type that cannot be nil |
| 11 | Same message for a proc-typed variable | `c06` | `'cb' is of type 'proc (x: int64)', which has no default value (it contains a not-nil pointer): give it an initial value` | A pointer type that cannot be nil |
| 12 | Two other `zeroedStorage` reasons use the identical message | source only | `contracts_fir.nim:5812-5818` (`IsOutOfRange`, `IsNoEnumValue`) | A pointer type that cannot be nil |
| 13 | A local not-nil var is legal if a write reaches it first | `r06` | `1` | A pointer type that cannot be nil |
| 14 | Local read before write → `cannot prove that r has been initialized` | `r07` | `Error: cannot prove that r has been initialized` | A pointer type that cannot be nil |
| 15 | `nil ref/ptr/cstring/pointer/proc` are accepted forms | `a01`, `c03`, `g01`, `g02`, `c07` | `true` / `true` / `true` / `true` / `true` | Writing nilability into the type |
| 16 | A `nil` field gives the enclosing object a default value | `h05` | `true` then `0` | Writing nilability into the type |
| 17 | A `nil` literal is accepted where a `nil` parameter is expected | `a04`, sample `total(nil)` | `nil`, and `0` in the sample | Writing nilability into the type |
| 18 | Passing an unproven value to a not-nil parameter → `cannot prove expression is not nil: m` | `e04` | `Error: cannot prove expression is not nil: m` | Writing nilability into the type |
| 19 | `if x != nil:` narrows the branch | `b03`, `b02`, `f01` | `nil`, `5`, `42` | What the compiler accepts as proof |
| 20 | `if x == nil: return` narrows after the branch | `a06` | `2` | What the compiler accepts as proof |
| 21 | `and` narrows the right operand | `f03` (compiles) | `empty` | What the compiler accepts as proof |
| 22 | `while it != nil` narrows the loop body | `b02` | `5` | What the compiler accepts as proof |
| 23 | The loop needs a local copy; a parameter is not assignable | `i04` | `Error: cannot mutate expression list` | What the compiler accepts as proof |
| 24 | Writing the place inside the guard drops the fact | `b04` | `Error: cannot prove expression is not nil: y` | What the compiler accepts as proof |
| 25 | Assigning a certainly-not-nil value does not refine a `nil` variable | `f02`, `e06` | `Error: cannot prove expression is not nil: m` | What the compiler accepts as proof |
| 26 | Narrowing does not reach through a field | `i02` | `Error: cannot prove expression is not nil: p.n` | What the compiler accepts as proof |
| 27 | `new` takes an `out` nullable ref; the not-nil destination fails at declaration | `b01`, `b06` | `'x' is of type 'ref int64 not nil', which has no default value …` / `b06` prints `true` | Allocation |
| 28 | `new` does not establish the non-nil fact | `c01` | `Error: cannot prove expression is not nil: tmp` at lines 5 and 6 | Allocation |
| 29 | Guard-or-quit after `new` satisfies both analyses | `e01`, `e02` | `4`, `4` | Allocation |
| 30 | An object construction is assignable to a not-nil local | `d02` | `9` | Allocation |
| 31 | A `nil ptr int` dereferences under a guard | `f08` | `5` | Raw pointers |
| 32 | Unguarded deref of a module-level `nil` pointer → `cannot analyze` | `c04` | `Error: cannot analyze expression is not nil: q` | Raw pointers |
| 33 | Module-level `nil` ref behind a guard → `cannot analyze` | `d04` | `Error: cannot analyze expression is not nil: g` | Raw pointers / delta |
| 34 | `ptr T` assigns to `pointer` without a cast | `g04` | `false` (the raw value is not nil) | Raw pointers |
| 35 | `var p: pointer = nil` → `expected non-nil value` | `g03` | `Error: expected non-nil value` | Raw pointers |
| 36 | `unchecked ref int` has a default value at module level | `d05` | `true` | Raw pointers |
| 37 | `lenientnils` accepts `var x: ref int = nil` at module level | `d06` | `true` | Nim 2 delta |
| 38 | Under `lenientnils` the nil dereference compiles and the program dies, exit 139 | `h01` | `FAILURE: nimcache/c/h01drx29a1/h01`; running the built binary → `139` | Nim 2 delta |
| 39 | Nim 2 accepted the same shape and died with SIGSEGV | `h03` (host Nim 2.4.0) | `SIGSEGV: Illegal storage access. (Attempt to read from nil?)` | Nim 2 delta |
| 40 | Reference `==` is identity in both compilers | `d07` (pin), `h02` (Nim 2.4.0) | pin: `true`, `false`; Nim 2: `false`, `true`, `true` | (not taught in the body — see question F) |

Probe `d07` output in full, since identity is easy to misread:

```
$ nimony c -r d07.nim
true     # let b = a
false    # two distinct cells with the same field content
```

## Questions A–F

**A. Field-level narrowing.** `if p.n != nil: echo p.n.data` is rejected on `p.n` (`i02`), even though the
guard names exactly that field. `analysableRoot` (`contracts.nim:246-271`) walks a dot expression down to
its base symbol, and the fact set is keyed by that symbol, so `p.n` and `p.m` collapse into `p`. Intended, or
a gap worth an issue? The chapter teaches copy-to-local either way; what I need is whether it may say
"currently" or must state it as a rule.

**B. `new` and the non-nil fact.** `new(tmp)` followed by `tmp[] = 4` still leaves `tmp` unprovable (`c01`),
so `result = tmp` is refused twice. The chapter's shape is guard-or-quit (`e01`, `e02`). Is that intended —
`out` assignment is not a not-nil witness — or a gap in the fact engine? Note this is a delta in practice:
Nim 2 code writes `new(x)` then `x[]` all day.

**C. Globals, permanently.** The comment at `contracts.nim:256-259` says globals are assumed shared between
threads, "maybe this needs a better solution". May the book state the rule as the pin behaves (`d04`) without
promising it stays, or do you want it named as a current limitation?

**D. `lenientnils` and the runtime.** Under the pragma the old code compiles and dies with **exit 139** and
no diagnostic (`h01`). Is that the intended contract for the porting switch — compile for compatibility,
accept the crash — or should the book's delta box be blunter than I wrote it?

**E. `not nil` compared to `nil`.** `let n = Node(data: 1); echo n == nil` compiles and prints `false`
(`f05`). I did **not** put this in the chapter: a comparison that can never be true is either a wart to warn
about or noise. Which?

**F. Reference equality citation.** The chapter does not teach `ref` equality at all; Chapter 11 taught
object `==` as field-by-field (`system.nim:462-468`). Reference `==` is the `EqRef` magic
(`src/nimony/magics.nim:64`) and behaves as identity at the pin (`d07`), and Nim 2 agrees (`h02`). If you
want that contrast taught in Chapter 13, it needs a sentence and a source line you are happy with.

## ERRATA candidates, for your ruling (left as *open* in `ERRATA.md`)

1. **`new` is not a non-nil witness** (`c01`). Documentation gap or defect? The book currently teaches the
   guard and does not claim `new` proves anything, so nothing in the text breaks either way.
2. **Field narrowing absent** (`i02`). Same shape: `doc/language.md` never promises field-level tracking, so
   this may be intended; the chapter would say so.
3. **Module-level variables are not analysed** (`d04`) while `doc/lenientnils.md`'s "tracking works through
   control flow" example (`var node: nil Node = nil` … `if node != nil: echo node.data`) reads as if written
   at module level. Inside a proc the same shape compiles (`f01`); at module level it cannot. Documentation
   gap in the example's setting, not in its rule.

## What I did not do

- `en.md` was not edited after the probes were run; `id.md` does not exist yet.
- No rebuild, no `_quarto.yml` change, nothing committed: the chapter is `drafting`.
- `samples/13-references-pointers-nil/refs.nim` is the only sample and it passes the verifier at 12/12.

## Technical review — Momo

Reviewer: Momo (Head of Engineering), 2026-11-13. Pin
`4ba90a781b0b22d0821efaa153c129c37cef6143` (nimony 0.6.3), toolchain
`~/.local/opt/nimony/4ba90a7`; Nim 2 contrasts with `~/.local/opt/nim-2.4.0`.

I ran every probe in `ch13-probes/` myself with `$NIMONY_HOME/bin/nimony c -r`; every line I quote below is
from my own run. I added `rv1`–`rv34` to the same folder for the checks this review needed; the full
transcript is `ch13-probes/REVIEW_RUN.log`.

```
$ ./tools/verify-samples.sh
PASS samples/13-references-pointers-nil/refs.nim exit=0
SUMMARY 12/12 passed, 0 failed
VERIFY_EXIT=0
```

The sample's five output lines are byte-identical to `en.md:265-271`.

### Verdict per claim

| # | Verdict | Evidence from my run |
| --- | --- | --- |
| 1 | held | `f04`: `2`, exit 0. |
| 2 | held | `j02`: `cannot mutate expression c`, exit 1. |
| 3 | held | `j01`: `1`, exit 0. |
| 4 | held | `f06`: `9`, exit 0. |
| 5 | held | `f07`: `7`, exit 0. |
| 6 | held | `r05`: `ref Node.Obj not nil`; `c08`: `array[0..2, ref Node.Obj not nil]`. |
| 7 | held | `e05` and `r04`: `expected non-nil value`; `g03` gives the same for `pointer`. |
| 8 | held | `r05`: `'base' is of type 'ref Node.Obj not nil', which has no default value ...`, exit 1. |
| 9 | held | `c08`: `'arr' is of type 'array[0..2, ref Node.Obj not nil]' ...`, exit 1. |
| 10 | held | `h06`: `'p' is of type 'Pair' ...`, exit 1. |
| 11 | held | `c06`: `'cb' is of type 'proc (x: int64)' ...`, exit 1. |
| 12 | held | `rv14`: `'r' is of type '1..10' ... (it contains a range that excludes 0)`; `rv15`: `(it contains an enum without a field of ordinal 0)`; source `contracts_fir.nim:5812-5818`. |
| 13 | held | `r06`: `1`, exit 0. |
| 14 | held | `r07`: `cannot prove that r has been initialized`, exit 1. |
| 15 | held; evidence row wrong | `a01`, `g01`, `g02`, `c07` and `rv1`, `rv2`, `rv3`, `rv5`–`rv9` all accept the nil forms. `c03` does not print `true`: its last line, `echo q[]`, exits 1 with `cannot analyze expression is not nil: q`. The claim stands; `c03` is not its evidence. |
| 16 | held | `h05`: `true` / `0`, exit 0. |
| 17 | held | `a04`: `5` / `nil`; the sample's `total(nil)` prints `0`. |
| 18 | held | `e04`: `cannot prove expression is not nil: m`, exit 1. |
| 19 | held | `b03`: `nil`; `b02`: `5`; `f01`: `42`, all exit 0. |
| 20 | held | `a06`: `2`, exit 0. |
| 21 | held | `f03`: `empty`, exit 0; the right operand compiles. |
| 22 | held | `b02`: `5`, exit 0. |
| 23 | held | `i04`: `cannot mutate expression list`, exit 1. |
| 24 | held | `b04`: `cannot prove expression is not nil: y`, exit 1. |
| 25 | held | `f02` and `e06`: `cannot prove expression is not nil: m`, exit 1. |
| 26 | held; evidence needs `rv11` | `i02` also prints `cannot prove that p has been initialized` because the probe never initialises `p`. `rv11`, with `var p = Pair(n: nil)`, gives only `cannot prove expression is not nil: p.n`. |
| 27 | **wrong** | `new` takes `out T` for any `T: ref` (`lib/std/system.nim:200`), not an "out nullable ref". A not-nil **local** is a legal destination: `rv26` prints `7`, `rv12` prints `0`, `rv30` rejects `tmp = nil` with `expected non-nil value`, `rv31` prints `false`, and `rv34` prints `9` through a `ref object`. `b01` fails at the module-level declaration because a global has no default value, not because `new` needs a nullable place. The chapter's "has to be nullable" and "you cannot declare the destination as not-nil" are false. |
| 28 | held only for a nullable destination | `c01` uses `nil ref int`: two errors, at (5, 3) and (6, 12). With `var tmp: ref int`, `new(tmp)` and `result = tmp` compile (`rv12`, `rv26`). The claim as written in the chapter, "`new` hands you a nullable variable", is the wrong generalisation. |
| 29 | held | `e01` and `e02`: `4`, exit 0. |
| 30 | held | `d02`: `9`, exit 0. |
| 31 | held | `f08`: `5`, exit 0. |
| 32 | held | `c04`: `cannot analyze expression is not nil: q`, exit 1. |
| 33 | held | `d04`: `cannot analyze expression is not nil: g`, exit 1. |
| 34 | held | `g04`: `false`, exit 0. |
| 35 | held | `g03`: `expected non-nil value`, exit 1. |
| 36 | held | `d05`: `true`, exit 0. |
| 37 | held | `d06`: `true`, exit 0. |
| 38 | held | `h01`: the build succeeds; the binary exits `139` with no diagnostic. `nimony c -r` reports the run failure, exit 1. |
| 39 | held | `h03` under Nim 2.4.0: `SIGSEGV: Illegal storage access. (Attempt to read from nil?)`. |
| 40 | held | `d07`: `true` / `false` (alias / two equal cells); `h02` under Nim 2.4.0: `false` / `true` / `true` (two equal cells / alias / nil global). Identity in both. |

**Tally:** 38 claims stand as written; 27 is wrong, 28 must be scoped to a nullable destination. Two evidence
rows (15 and 26) point at the wrong probe, though both claims stand. No claim is left open.

### Answers A–F

**A.** Current limitation, not a language rule: say "currently" or "at this pin". `analysableRoot`
(`src/nimony/contracts.nim:249-275`) walks `DotX`/`HderefX` down to the base symbol and the fact set is keyed
by that symbol, so `p.n` and `p.m` both become the place `p`; a fact recorded by `if p.n != nil` is therefore a
fact about `p`, which says nothing about `p.n`. The source comment says "Cannot analyse expressions yet that
involve derefs" (`:254`); "yet" is the author marking it provisional, so do not present it as permanent. Fix
the explanation at `183-187`: it is not that the compiler cannot tell the field names apart, it is that both
collapse to the base symbol.

**B.** The premise is wrong: `new` does not require a nullable destination. Its parameter is `out T` for any
`T: ref` (`lib/std/system.nim:200`), and a not-nil local is a legal place: `var tmp: ref int; new(tmp);
tmp[] = v; tmp` compiles and prints (`rv26`; `rv34` for a `ref object`); `tmp = nil` is then rejected
(`rv30`), and `tmp == nil` is `false` (`rv31`). `b01` fails at the **module-level declaration** for the separate no-default-value reason.
Only a `nil ref` destination lacks a not-nil fact (`c01`), because the fact engine learns from comparisons, not
from calls. That is a limitation, not a reason to make nullable the default, and not worth an issue while the
not-nil local exists. Teach the not-nil local first; keep the nullable-plus-guard shape as the variant when the
variable must start nullable.

**C.** State it flatly as the pin's behaviour, but name it a current limitation. The source gives the reason
and then says "Maybe this needs a better solution" (`src/nimony/contracts.nim:269-273`); that is the author
telling you it may change. The manual's example at `doc/lenientnils.md:92-98` is a real documentation bug: it
is written at module level and fails exactly as `d04` does (`rv27`), while the same shape inside a proc prints
`42` (`rv28`). That is the one ERRATA-worthy fact in this batch.

**D.** The intended contract is Nim 2 semantics, not the number `139`: the switch restores nilable types and
disables tracking, so the dereference is a runtime fault with no compile-time diagnostic. `139` is what this
toolchain and platform produced (`h01`); label it as measured, not as a portable guarantee. Make the box
blunter on the safety point: it compiles, it prints no diagnostic, and it dies at the dereference. Drop the
implication that `139` is the contract.

**E.** Noise for the body; no ERRATA row. `let n = Node(data: 1); echo n == nil` prints `false` (`f05`,
`rv16`): a comparison that can never be true, not a soundness hole. It is a missed diagnostic at most. One line
in Checks is defensible if you want it; a section is not.

**F.** Teach it in one sentence, in "Two ways to refer": two references compare by identity (`EqRef`,
`src/nimony/magics.nim:64`); `a == b` is `true` for an alias and `false` for two distinct cells with equal
fields (`d07`), and Nim 2.4.0 agrees (`h02`). This is not Chapter 11's object `==`, which walks fields
(`lib/std/system.nim:463`); that operator applies to the object value, not to two references. The manual never
mentions reference equality, so a doc-gap row is defensible, but the sentence itself does not need one.

### ERRATA rulings

1. **`new` is not a non-nil witness (row 69) — withdraw it as written; not a defect.** The row's premise is
   too broad. `new` into a not-nil local works and needs no fact (`rv26`, `rv12`, `rv30`, `rv31`); only a
   `nil ref` destination is left unproven (`c01`). The chapter, not the compiler, is what is wrong: it says
   nullable is required. If a row is kept, it is a documentation gap that `new`'s nilability is only in
   `lib/std/system.nim:200`, not in `doc/language.md`. File nothing.
2. **Field narrowing absent (row 70) — keep as a watch row, not a defect.** The source comment says "yet"
   (`contracts.nim:254`), and the fact set is per base symbol; this is a current limitation. The chapter says
   "currently" or "at this pin" and keeps the copy-to-local teaching. No issue.
3. **Module-level variables are not analysed (row 71) — keep the rule, fix the ERRATA entry to a
   documentation defect.** The compiler behaviour is a current limitation, explicitly flagged
   (`contracts.nim:269-273`); the manual's example at `doc/lenientnils.md:92-98` is wrong as placed: it is
   module-level and fails (`rv27`), while the same shape in a proc prints `42` (`rv28`). File the example as a
   doc bug, not the compiler.

### Statements in `en.md` with no source, commit or probe behind them

- `85-86`: "or an expression rooted in a dereference" — contradicted by `f08`, `rv17` and `rv19`; a dereference
  rooted in a local is analysed. Only the module-level root is established (`analysableRoot`, `:269-273`).
- `197-200`: "has to be nullable" / "you cannot declare the destination as not-nil" — contradicted by `rv26`
  and `rv12`; the module-level failure is the global no-default rule (`b01`).
- `216-218`: "`new` hands you a nullable variable" — same; it hands you the destination's type.
- `255-256`: "exit code 139" as a general claim — one platform's measurement (`h01`), not a contract.
- `278-280` (Check 1): "copy `g` into a local first" inside the proc gives `unsynchronized access to global
  variable 'g'` (`rv20`); pass it as a parameter (`rv24`) or copy it at module level (`rv25`).
- `283-284` (Check 3): the probe as written does not isolate `p.n`; `i02` first reports `cannot prove that p
  has been initialized`. Initialise `p` (`var p = Pair(n: nil)`) before the guard (`rv11`).
- `227-228`: the `unchecked` list omits proc types; `doc/language.md:877` includes them and `rv32` compiles.

### Text corrections in `en.md`

1. `85-89`: replace "a module-level variable, or an expression rooted in a dereference" with the established
   case only: a module-level variable. A dereference whose base is a local is analysed (`f08`, `rv17`,
   `rv19`). Cite `src/nimony/contracts.nim:249-275`, not `246-271`.
2. `197-200`: rewrite the `out` paragraph. `new` is `out T` for any `T: ref`; a not-nil local is a legal
   destination. Show `var tmp: ref int; new(tmp); tmp[] = v; tmp` (`rv26`). A module-level not-nil declaration
   is refused for the separate no-default-value reason (`b01`); nullable is the variant you choose when the
   variable must start nullable, not a requirement of `new`.
3. `200`: "why the idiomatic shape is a nullable local plus a proof" → "the sample uses the nullable variant;
   a not-nil local needs no proof".
4. `211-214`: scope "`new` does not establish the non-nil fact" to a nullable destination. With
   `var tmp: ref int`, the type is the guarantee and no fact is needed (`rv26`); `c01` is the nullable case.
5. `216-218`: "`new` hands you a nullable variable" → "`new` hands you the destination's type: a not-nil local
   is already a `ref T`; a nullable one still asks you to dispose of the nil case".
6. `227-229`: add proc types to the `unchecked` list (`doc/language.md:877`, `rv32`).
7. `255-256`: label `139` as measured on this toolchain and platform; state the contract as "no diagnostic,
   runtime fault", not as a portable exit code.
8. `278-280` (Check 1): pass `g` as a parameter (`rv24`) or copy it at module level (`rv25`); copying inside
   the proc hits the global-sync rule (`rv20`).
9. `283-284` (Check 3): initialise `p` first (`var p = Pair(n: nil)`), then the only error is on `p.n`
   (`rv11`); otherwise the first error is `cannot prove that p has been initialized` (`i02`).
10. Citation ranges to tighten: `49` `doc/language.md:793-807` → `794-807`; `87`
    `src/nimony/contracts.nim:246-271` → `249-275`; `104` `contracts_fir.nim:5798-5822` → `5798-5821`; `112`
    `contracts_fir.nim:5804-5811` → `5805-5811`; `229` `doc/language.md:868-878` → `867-877`.
11. `189`: if the not-nil local becomes the primary shape, retitle the section. "The one place nil is handed to
    you" describes only the nullable variant; a not-nil local is handed a `ref T`.

The sample file is outside my edit scope and stays as it is. Its comment "A fresh cell starts in a nullable
variable" describes the nullable variant, which is valid; when the chapter is unfrozen, it should either say
that this is the variant being shown or add the not-nil local shape beside it.

### Left open

None. Every verdict above is one compile-and-run at the pin; the Nim 2 rows were run with 2.4.0. The two
rulings that rest on source comments rather than a manual sentence (A and C) are marked as current
limitations, which is the honest reading of "yet" and "Maybe this needs a better solution".
