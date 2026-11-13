# Chapter 17 — technical review

**Chapter:** Generics and Concepts (`chapters/17-generics-concepts/en.md`)
**Status:** `drafting` · **Words:** 1,994 (body, frontmatter excluded) · **Claims:** 30
**Pin:** `4ba90a781b0b22d0821efaa153c129c37cef6143` (nimony 0.6.3) · **Host compiler for contrasts:** Nim 2.4.0 (`~/.local/opt/nim-2.4.0`)
**Verifier (run by me, 2026-11-13):**

```
toolchain ~/.local/opt/nimony/4ba90a7/bin/nimony 0.6.3 pin 4ba90a7
PASS samples/17-generics-concepts/generics.nim exit=0
SUMMARY 16/16 passed, 0 failed
```

Sample output diffed against the block in `en.md` §Samples: `42`, `6`, `12`, three lines, byte-identical.

Probes live in `/Users/sachiel/.openmausbot/workspaces/be336972-1e63-4f00-9916-c76cc8e33654/ch17-probes/`
(`g01`–`g27`, plus `nim2/n1`, `nim2/n2`). Each is a directory whose `main.nim` was run with
`~/.local/opt/nimony/4ba90a7/bin/nimony c -r main.nim`; the Nim 2 probes used
`~/.local/opt/nim-2.4.0/bin/nim c -r --hints:off`. Every probe imports `std/syncio` before `echo`.

## Claim table

| # | Claim as the chapter states it | Probe | Raw output (abbreviated) | Section |
| --- | --- | --- | --- | --- |
| 1 | Brackets after the routine name introduce type parameters, inferred from the argument | g01 | `3` then `s`, exit 0 | A type parameter on a proc |
| 2 | The instantiation can be written out, `id[int](3)` | g02 | `3`, exit 0 | A type parameter on a proc |
| 3 | A concrete routine beats a generic one; the generic is the fallback | g19 | `concrete` then `generic`, exit 0 | A type parameter on a proc |
| 4 | A `type` takes the same bracket and the constructor names the instance | g03 | `Box[int](v: 3)` → `3`, exit 0 | Generic types |
| 5 | A constraint may sit on a type parameter and every instance must satisfy it | g15 | `Box[T: Addable]` with `int` → `3`, exit 0 | Generic types |
| 6 | Several parameters are independent; a returned tuple keeps each half's type | g14 | `pair(1, "x")[1]` → `x`, exit 0 | Several parameters |
| 7 | A generic may return a container of its parameter type without spelling it | g09 | `pairUp(7).len` → `2`, exit 0 | Several parameters |
| 8 | `static int` is a compile-time value parameter supplied in brackets | g16b | `fill[3](7).len` → `3`, exit 0 | A static parameter |
| 9 | A generic body is checked at the definition against its parameters' promises | g18 | `main.nim(2, 28) Error: undeclared field: 'nonexistent' for type T`, exit 1 | Checked, not pasted |
| 10 | A type-dependent `when` is checked as a constant `if`; each branch is its own scope, so the name is not visible after it, and the error arrives at instantiation | g10b | `main.nim(7, 3) Trace: instantiation from here` then `main.nim(7, 8) Error: undeclared identifier: y`, exit 1 | Checked, not pasted |
| 11 | `{.untyped.}` moves the check to the instantiation, where `when` is an ordinary conditional and branches share the scope | g11 | `str: a` then `int: 2`, exit 0 | Checked, not pasted |
| 12 | A concept is a list of routine signatures, and `Self` stands for the checked type | `doc/language.md:4301-4313`; g04 | text quoted; `twice(3)` → `6`, exit 0 | Concepts |
| 13 | A type satisfies a concept when each requirement, read as a call, resolves by ordinary overload resolution and returns something assignable | `doc/language.md:4317-4339`; g04, g13 | text quoted; both conforming calls run | Concepts |
| 14 | A container concept binds its parameter from the requirements; the manual's `Findable[T]` works with a custom collection | g06 | `find(myCollection, 3)` → `2`, exit 0 | Concepts |
| 15 | `proc find[T](x: Findable[T]; elem: T)` builds but is refused at the call | g25 | `[1] expected: Findable[T] but got: MyCollection` at `(17, 10)`, exit 1 | Concepts |
| 16 | The mismatch message names the type, the constraint and the constraint's declaration site, with a trace line for the instantiation | g05 | `NoAdd does not match constraint Addable (declared in main.nim(6, 1))`, exit 1 | When a type does not satisfy it |
| 17 | The message does not print a `missing: proc ...` line | g05, g15, g22, g25 | no `missing:` line in any of the four failures | When a type does not satisfy it |
| 18 | `concept of` adds the parent's requirements and both are checked the same way | g12 | `describe(Person(...))` → `ada 3`, exit 0 | Concept inheritance |
| 19 | A `var Self` requirement is met only by a `var` candidate, and `run[T: Bumpable](x: var T)` can pass it along | g13 | `c.v` becomes `2`, exit 0 | `Self` and `var Self` |
| 20 | The manual says `var T` cannot be inferred; at the pin the same program compiles, runs and mutates the caller's variable | `doc/language.md:4477-4499`; g23 | text quoted; `g(v, i)` → prints `42`, then `i` is `100`, exit 0 | Two manual rules |
| 21 | The explicit form `g[var int](v, i)` builds | g26 | `i` is `100`, exit 0 | Two manual rules |
| 22 | A concept in a plain parameter position is accepted, and one instantiation runs | `doc/language.md:4427`; g21 | text quoted; `f(3)` → `took it`, exit 0 | Two manual rules |
| 23 | A second conforming instantiation dies in the backend | g24 | `Error: unhandled exception: Symbol not found in NIF module: Addable.0.mai3r4ykk [AssertionDefect]`, exit 1 | Two manual rules |
| 24 | Using the concept's own name where `Self` belongs is accepted at the declaration | g17 | exit 0, no diagnostic | Two manual rules |
| 25 | The same declaration is refused at the call | g22 | `[1] expected: Comparable but got: int64 (declared in main.nim(4, 1))`, exit 1 | Two manual rules |
| 26 | Nim 2 accepts a concept in parameter position as an implicit generic and runs two types | nim2/n1 | `ok` twice, exit 0 | Nim 2 delta |
| 27 | Nim 2 refuses the concept-name-instead-of-`Self` shape at the call with a candidate list | nim2/n2 | `[1] proc smaller(a, b: Comparable): bool` plus a mismatch list, exit 1 | Nim 2 delta |
| 28 | The manual's `{.untyped.}` snippet names an undeclared `process` in its first `echo` | `doc/language.md:4464-4473`; g27 | `main.nim(10, 6) Error: undeclared identifier: 'process'`, exit 1 | Two manual rules (not stated in the chapter) |
| 29 | The sample prints `42`, `6`, `12` in that order, one concept constraining three instantiations of two routines | sample | verifier output above | Samples |
| 30 | A concept in a plain parameter position is not a supported route; write `[T: Addable]` | g21, g24 | first call runs, second crashes | Two manual rules |

## Questions for the Head of Engineering

**A. Concept in a plain parameter position — is the acceptance intended?** `proc f(x: Addable)` builds, `f(3)`
runs, and `f(Money(...))` — the same concept, a second conforming type — crashes the backend with
`Symbol not found in NIF module: Addable.0` and an `AssertionDefect` (g21, g24). `doc/language.md:4427` says a
concept can only be a constraint of a type parameter, which reads as if the declaration should have been refused.
Is the sem acceptance deliberate (a Nim 2 compatibility window) or a gap, and is the crash worth filing with g24
as the repro?

**B. `var T` inference — which side is wrong?** `doc/language.md:4477-4499` marks the `g(v, i)` shape as invalid
("not valid: `T` is not inferred to be of type `var int`") and also rejects `g[var int](v, i)`. At the pin both
compile and the callee mutates the caller's `i` to `100` (g23, g26). I wrote the chapter as "the pin is right, the
doc is stale" and said the signature should stay explicit anyway. Confirm, or tell me what the inference actually
infers there.

**C. Concept name in place of `Self`.** `proc `<`(a, b: Comparable): bool` builds with no diagnostic (g17) and
the call fails with `expected: Comparable but got: int64` (g22). `doc/language.md:4313` calls that form invalid.
Is accepting the declaration and failing at the call a deliberate deferral, or the same leniency as A?

**D. Is there any shape that prints `missing: proc ...`?** The proof gate says not to promise it. Six failures in
this chapter (`g05`, `g15`, `g22`, `g25`, `g27`, `nim2/n2`) print a mismatch line and, in two cases, a candidate
list, never a `missing:` detail. Do not claim a shape exists unless you have a probe for it; my chapter sentence
says the message names the constraint and not the missing requirement.

**E. The satisfaction leniency.** `doc/language.md:4333-4336` says that if several candidates match a requirement
the requirement is satisfied, and ambiguity is only decided at instantiation. I could not build a probe where
that changes the answer, so the chapter says nothing about it. Worth a probe, or is it a rule with no observable
consequence at this pin?

**F. `doc/language.md:4472` calls `process`, which is never declared.** The snippet defines `processUntyped` and
then echoes both `process("hello")` and `processUntyped("hello")`; the first line fails with `undeclared
identifier: 'process'` (g27). Documentation defect, not a compiler issue, and it is the same snippet the sentence
above it uses to introduce `{.untyped.}`.

**G. Passing a generic routine as a `proc` value.** I did not test `mapEach(@[1, 2, 3], twice)`, so the chapter
never shows a generic passed as a parameter. Is that supported, and does the type parameter get inferred from the
expected `proc` type? If it is a one-command answer I will add a sentence; I am not adding one on guesswork.

## ERRATA candidates

1. **Documentation defect — `doc/language.md:4477-4499`.** The generic-inference-restriction section shows a
   program that the pin compiles and runs, including the line it labels "not valid". Evidence: g23 prints `42`
   then `100`, g26 prints `100`, both exit 0; doc text read at `:4477-4499`. Either the section describes an
   older compiler or it describes an intention that is not enforced.
2. **Compiler defect candidate — concept in a plain parameter position.** Minimal repro g21 (accepted, runs once)
   plus g24 (second conforming type → `AssertionDefect: Symbol not found in NIF module: Addable.0`). The pairs
   with `doc/language.md:4427`, which says the form is not allowed; the front end and the backend disagree with
   the manual and with each other. If filed, g24 is the repro and the ask is either a sem-time refusal or a
   working instantiation.
3. **Documentation defect — `doc/language.md:4472`.** The `{.untyped.}` example's first `echo` calls `process`,
   which is not declared anywhere in the snippet; the program fails before `processUntyped` is ever used (g27).
   The example needs `echo process("hello")` removed or the routine renamed.

## What I did not test

- `typedesc[T]` inference, the second half of the restriction section at `:4479-4499`.
- Whether a concept requirement may be satisfied by an inherited method through subtyping beyond the plain
  `Self` case; `doc/language.md:4319-4330` lists conversions and subtyping as part of ordinary resolution.
- Concept requirements that are templates or funcs versus procs (`doc/language.md:4325-4328`).
- Generic iterators and generic templates, both of which the manual's bracket syntax covers and Chapter 18 needs.
- Passing a generic routine as a value (question G).
- Overload resolution among two generic candidates with different constraints.

---

# Verdict — Momo, 2026-11-13

**Verifier, run by me from the authoring folder, not taken from your paste:**

```
$ ./tools/verify-samples.sh
toolchain /Users/sachiel/.local/opt/nimony/4ba90a7/bin/nimony 0.6.3 pin 4ba90a7
PASS samples/17-generics-concepts/generics.nim exit=0
...
SUMMARY 17/17 passed, 0 failed
```

`17` and not `16` because Chapter 18's sample already sits in `samples/`; Chapter 17's sample is one of the seventeen. Direct run of the sample:

```
$ ~/.local/opt/nimony/4ba90a7/bin/nimony c -r samples/17-generics-concepts/generics.nim
42
6
12
EXIT=0
```

Byte-identical to the block at `en.md:285-290`. Every probe below I ran myself with `~/.local/opt/nimony/4ba90a7/bin/nimony c -r <probe>/main.nim` (the two Nim 2 contrasts with `~/.local/opt/nim-2.4.0/bin/nim c -r --hints:off`). `en.md`, `id.md` and `samples/` were not touched.

**Verdict: 24 of 30 table claims stand, four are corrected (4, 15, 18, 19), two are narrowed (17, 24), none is open.** One further claim in the prose, outside the table, is wrong: the meaning of the `[N]` marker.

## Claim by claim

| # | Verdict | Evidence from my run |
| --- | --- | --- |
| 1 | stands | g01 → `3`, `s`, exit 0 |
| 2 | stands | g02 → `3`, exit 0 |
| 3 | stands | g19 → `concrete`, `generic`, exit 0 |
| 4 | **corrected** | `Box[int](v: 3)` works (g03, `3`), but `Box(v: 3)` also works and prints `3` (h12, exit 0). The field alone does tell `T`; the causal clause "because the field alone cannot tell it which `T` you meant" is false. |
| 5 | stands, strengthened | g15 → `3`, exit 0; and `Box[NoAdd]` is refused with `NoAdd does not match constraint Addable` plus `missing: proc +(a: Self, b: Self)` (d1) |
| 6 | stands | g14 → `x`, exit 0 |
| 7 | stands | g09 → `2`, exit 0 |
| 8 | stands | g16b → `3`, exit 0 (g16, the plain `var s: seq[int]`, fails with `cannot prove that s has been initialized`) |
| 9 | stands | g18 → `main.nim(2, 28) Error: undeclared field: 'nonexistent' for type T`, exit 1 |
| 10 | stands | g10b → trace at `(7, 3)`, `undeclared identifier: y` at `(7, 8)`, exit 1 |
| 11 | stands | g11 → `str: a`, `int: 2`, exit 0; h1 proves the shared scope: a `var y` declared in each branch is read after the `when` and prints `1`, `1`, `2`, `2` |
| 12 | stands | doc :4301-4319; g04 → `6`. Quote :4319 for "Self replaced by the checked type"; :4313 says something narrower ("the currently defined concept itself"). |
| 13 | stands | doc :4319-4329; g04 and g13 both run |
| 14 | stands | g06 → `2`, exit 0; the citation should be :4429-4441, not :4405-4432 — the `MyCollection` block is at :4431-4440 and the `echo find` line is :4440 |
| 15 | **corrected** | The call-site message is real: g25 → `[1] expected: Findable[T] but got: MyCollection` at `(17, 10)`. But the form does **not** build: d2 is the same `find` with no call at all and already fails at `(8, 17)` (`items(x)`) and `(9, 10)` (`a == elem`). "builds and is refused at the call" is wrong on the verb. |
| 16 | stands | g05 → `[1] NoAdd does not match constraint Addable (declared in g05/main.nim(6, 1))` with the trace line at `(8, 1)` |
| 17 | narrowed | True for the routine-call check: no `missing:` in g05, g22, g25. Not true in general: a generic *type* argument failure prints it (d1, `Box[NoAdd]`). Also g15 is a success, not one of "the four failures". |
| 18 | **corrected** | The working case stands (g12 → `ada 3`). The failure sentence does not: h2 (a `P2` with `age` but no `name`) prints `P2 does not match constraint Aged (declared in h2/main.nim(9, 1))` — the **child**, and nothing names `Named`. |
| 19 | **corrected** | g13 → `2` and h7's `cannot pass x to var/out T parameter` prove the `var T` half. The `Self` qualifier claim is false in both directions: h5 (`var Self` requirement, value candidate `proc bump(x: C)`) is satisfied and prints `value only` with `c.v == 1`; h3 (plain `Self` requirement, `var` candidate) is satisfied **and the mutation happens** (`2`). h8/h10 show the concept check is active in both shapes, so this is not a vacuous pass. |
| 20 | stands | g23 → `42` then `100`, exit 0 |
| 21 | stands | g26 → `100`, exit 0; e2 shows the explicit argument is a real type: `[1] expected: var int64 but got: int64` |
| 22 | stands | g21 → `took it`, exit 0 |
| 23 | stands | g24 → `Symbol not found in NIF module: Addable.0.maizgahfi [AssertionDefect]`, exit 1 |
| 24 | narrowed | g17 (the requirement `proc <(a, b: Comparable): bool` inside the concept) is accepted silently, exit 0. A proc **outside** the concept with that signature is not: e1 fails at its definition `(4, 42)` with the candidate list. So "the declaration is accepted, the use is not" must say which declaration. |
| 25 | stands | g22 → `[1] expected: Comparable but got: int64 (declared in g22/main.nim(4, 1))` at `(5, 13)`. Note there is an earlier error inside the definition at `(4, 42)`; the quoted line is the call site. |
| 26 | stands | nim2/n1 with Nim 2.4.0 → `ok`, `ok`, exit 0; h11 adds the mechanism: Nim 2 defers the body error to instantiation and substitutes `int` (`undeclared field: 'nonexistent' for type system.int`) |
| 27 | stands | nim2/n2 → `[1] proc smaller(a, b: Comparable): bool` with the mismatch list, exit 1 |
| 28 | stands | g27 → `undeclared identifier: 'process'` at `(10, 6)`, exit 1; doc :4472 confirmed |
| 29 | stands | sample run above, `42`/`6`/`12`, exit 0, byte-identical |
| 30 | stands | guidance backed by g21/g24 |

## Questions A–G, one line each

**A.** Deliberate on the front end, not an accident: `matchSymbol` has an explicit `elif isConceptSym(fs): matchConceptSym` branch (`src/nimony/sigmatch.nim:1825-1827`), so a concept symbol in a parameter position is matched as a constraint on purpose; the backend has no lowering for the concept type and asserts. File the assertion, g24 as the repro; the ask is a sem refusal or a working instantiation. Any body that touches `x` fails at the definition first (e1), so the repro must keep a body that ignores the argument — an empty concept is refused cleanly (`concept must declare at least one requirement or inherit from another concept`, h13), so one requirement is the floor.

**B.** `T` is inferred as `var int`: g26 builds and mutates, e2 shows `var int` is a real type argument (`expected: var int64 but got: int64`), and with `T = int` the `proc(y: var int)` formal could not have been passed at all. `doc/language.md:4479` and `:4494-4498` are both stale — documentation defect, which is what your ERRATA row 1 says.

**C.** Same leniency as A, same branch: the requirement declaration inside the concept is accepted (g17), but the concept symbol is only usable as a constraint, so a proc that takes it as a parameter type is refused at **its definition** (e1) and again at the call (g22). The manual's "invalid" at :4313 is right in effect; the mechanism is not a deferral to call time, and the chapter must add the definition-time failure.

**D.** Yes, exactly one shape: a generic **type** argument that fails its constraint prints it — `Box[NoAdd]` gives `NoAdd does not match constraint Addable` then `missing: proc +(a: Self, b: Self)` (d1), from `genericArgErrorMsg` (`sigmatch.nim:281-285`) which is called only from type instantiation (`semtypes.nim:636`). Routine-call checks never print it. Your sentence is right as written ("here"); do not generalise it.

**E.** No probe produced an observable consequence, so the chapter's silence is correct and no claim depends on it. Fix the citation: the leniency bullet is `doc/language.md:4327`, not :4333-4336 (that range is the "Atoms and containers" heading).

**F.** Confirmed documentation defect: :4472 calls `process`, which the snippet never declares; g27 fails before `processUntyped` is used.

**G.** Not supported at this pin: `mapEach(@[1, 2, 3], twice)` with `twice[T: Addable]` fails at the call with `[2] expected: int64 but got: T` (d3b), so the type parameter is not inferred from the expected proc type. No sentence to add; if you want one, it is "does not work here".

## One more prose claim, outside the table

`en.md:189-191` says "The `[1]` marks which candidate was tried first". It does not: `[N]` is the **argument position** where the match failed (`sigmatch.nim:188` sets `pos: m.pos+1`, `:296` prints it, and `:2879` increments `m.pos` per argument). d3b shows `[2]` for the second argument, and every candidate line in g25 carries `[1]` because all of them failed at argument 1. Rewrite: the `[N]` is the position of the argument that did not match, and the list below it is the candidates tried at that position.

## Prose corrections, with the chapter lines

- `:60-61` — drop "because the field alone cannot tell it which `T` you meant"; `Box(v: 3)` builds (h12).
- `:86-93` — keep `var s = @[0]; s.setLen(0)`, but say why: `var s: seq[int]` followed by `s.add` is refused with `cannot prove that s has been initialized` (h4). That is Chapter 3's definite-assignment rule, not a generic rule; one clause pointing there stops the reader copying the trick superstitiously.
- `:189-191` — the `[N]` correction above.
- `:209-211` — the message names the child constraint (`Aged`), not the parent (h2).
- `:230-231` — delete "would accept only a value-taking candidate and then refuse the mutation"; h3 and h5 show the qualifier is not enforced at satisfaction. What is enforced is the body's own call: `run[T](x: var T)` can pass `x` (g13), `run[T](x: T)` cannot (`cannot pass x to var/out T parameter`, h7).
- `:256-258` — "builds and is refused at the call" → "is refused at the definition, and the call site repeats it"; keep the quoted message (g25).
- `:260-262` — say that the requirement inside the concept is accepted (g17) and the proc that uses the concept as a parameter type is refused at its definition (e1) before the call (g22).
- `:175` — citation :4405-4432 → :4429-4441.
- Claim 12's citation — :4313 → :4319 for "Self stands for the type being checked".

## ERRATA rulings

1. **Documentation defect — `doc/language.md:4477-4499`.** Confirmed. Both claims are false at the pin: `g(v, i)` prints `42` then mutates `i` to `100` (g23), and `g[var int](v, i)` builds (g26). The false text is at `:4479` and `:4494-4498`. Note the direction cannot be settled from intent: this install's git history is a single commit (`4ba90a7`), so there is no history to show whether the doc or the compiler changed last. Classify as documentation defect; if maintainers say the compiler should refuse, it becomes a compiler defect instead.
2. **Compiler defect — concept in a plain parameter position.** Confirmed and worth filing. The acceptance is deliberate sem code (`sigmatch.nim:1825-1827`), but the second instantiation kills the backend with an `AssertionDefect` instead of a diagnostic (g24). Repro must keep a body that never uses `x`; g24 satisfies that. The empty-concept diagnostic (h13) is clean, so the repro is near minimal.
3. **Documentation defect — `doc/language.md:4472`.** Confirmed (g27). The first `echo` names `process`, which the snippet never declares.
4. **New — `doc/language.md:4324` (the `var Self` bullet) is false at this pin.** h5: a `var Self` requirement is satisfied by a value candidate (`proc bump(x: C)`), and the mutation the requirement promises does not happen. h3: a plain `Self` requirement is satisfied by a `var` candidate and the mutation does happen. The direction (doc stale, or the satisfaction check too lenient) is not decidable from the pin; either way the chapter cannot teach the sentence, and ERRATA needs a row for it.

## Probes I ran

All of `ch17-probes` g01-g27 (no g08), `nim2/n1`, `nim2/n2` with the host compiler, plus my own under `/Users/sachiel/.openmausbot/workspaces/49df9f87-8857-46c0-b9b8-8f066a10a55e/ch17-verify/`:

- `d1` `Box[NoAdd]` → the `missing:` line; `d2` `find[T](x: Findable[T])` with no call; `d3b` generic routine as a proc value.
- `e1` `proc smaller(a, b: Comparable)` with no call; `e2` `g[var int](c, i)`.
- `h1` untyped `when` branch scope; `h2` inherited requirement message; `h3`/`h5` `Self`/`var Self` candidates; `h7` `run[T](x: T)` body; `h8`/`h10` active-check controls; `h11` Nim 2 deferral; `h12` `Box(v: 3)`; `h13` empty concept; `h4` `var s: seq[int]`.

`g16` (plain `var s: seq[int]`) and `g10` (the `echo f(1)` variant) both fail with an extra error each; the table cites `g16b` and `g10b`, which are the shapes in the chapter. Neither changes a verdict.

## Still unverified

- `typedesc[T]`, the second half of the restriction section (:4479).
- Generic iterators and generic templates; that belongs to Chapter 18.
- Two generic candidates with different constraints competing for one call.
- The ambiguity leniency at :4327 (question E) — no observable case found.
- Whether `doc/language.md:4324` is stale or the satisfaction check is too lenient. One-commit history, no intent to read.

