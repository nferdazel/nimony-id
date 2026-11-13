# Chapter 12 review sheet — Sum Types and Exhaustive `case`

Draft: `chapters/12-sum-types-case/en.md` (`status: drafting`).
Sample: `samples/12-sum-types-case/sumtypes.nim`.
Toolchain: `~/.local/opt/nimony/4ba90a7`, pin `4ba90a781b0b22d0821efaa153c129c37cef6143` (nimony 0.6.3).
Verifier: `./tools/verify-samples.sh` → `SUMMARY 11/11 passed, 0 failed`, exit 0.

Each claim below is what the chapter teaches. The probe is the file in
`probes/ch12/`, run with
`$NIMONY_HOME/bin/nimony c -r <file>`; output is pasted raw, trimmed to the lines that matter. Files under
`ch12-probes/nim2/` are the same shapes compiled with the host compiler `~/.local/opt/nim-2.4.0`, used only
where the chapter claims a Nim 2 difference.

Every claim you verify replaces a row with `held` or `wrong, because …`; do not rewrite the rows I cite.

| # | Claim in the chapter | Probe | Raw output at the pin | Source in chapter |
| --- | --- | --- | --- | --- |
| 1 | A `case` section inside an object declares alternatives; each branch owns its fields. | `c1.nim` | `12.566370614359172` / `12.0` / `Circle` / `2.0`, exit 0 | §The shape of a variant; `doc/language.md:592-655` |
| 2 | The discriminator must be an ordinal type; a `string` selector is rejected. | `c40.nim` | `c40.nim(4, 5) Error: selector must be of an ordinal type`, exit 1 | §The shape of a variant; `src/nimony/sem.nim:3207` |
| 3 | A holey enum cannot be a discriminator. | `c38.nim` | `[Error] c38.nim(8, 5) illformed AST inside object: (err . "selector must be of an ordinal type")`, exit 1 | §The shape of a variant |
| 4 | The `case` section must cover every value or end in `else`; a missing member is a build error, reported wrapped and escaped. | `c2.nim` | `[Error] c2.nim(5, 5) illformed AST inside case object: (err . "not all cases are covered; missing\3A \7BTriangle\7D")`, exit 1 | §The shape of a variant; `doc/language.md:627` |
| 5 | `else` is accepted in the section and covers the remaining values; its fields are constructible. | `c3.nim`, `c17.nim` | `c3`: `24`, exit 0. `c17`: `1.5` / `x` / `24`, exit 0 | §The shape of a variant |
| 6 | One field name may not appear in two branches. | `c24.nim` | `c24.nim(9, 7) Error: attempt to redeclare: radius` + `c24.nim(12, 11) Error: expected key/value pair in object constructor`, exit 1 | §The shape of a variant |
| 7 | The discriminator must be named; `case bool` without a name is a parse error. | `c30.nim` | `c30.nim(5, 5) Error: ':' or '=' expected, but got 'keyword of'`, exit 1 | §The shape of a variant |
| 8 | Construction names the discriminator and the active branch's fields; the rest default. | `c10.nim`, `c35.nim` | `c10`: `Circle` / `0.0` / `0.0`, exit 0. `c35`: `2.0`, exit 0 | §Constructing a variant; `doc/language.md:629-641` |
| 9 | A field from another branch, with a literal discriminator, is rejected with the "in conflict" message. | `c4.nim` | `c4.nim(11, 14) Error: a case selecting discriminator 'kind' with value 'Circle' appears in the object construction, but the field(s) 'width' are in conflict with this value.`, exit 1 | §Constructing a variant; `sem.nim:4570-4578` |
| 10 | Two branches' fields together are rejected. | `c5.nim` | `c5.nim(11, 14) Error: The fields 'radius' and 'width' cannot be initialized together, because they are from conflicting branches in the case object.`, exit 1 | §Constructing a variant; `sem.nim:4559` |
| 11 | Omitting the discriminator while naming a branch field is rejected. | `c51.nim` | `c51.nim(11, 14) Error: cannot prove that it's safe to initialize 'radius' with the runtime value for the discriminator 'kind'.`, exit 1 | §Constructing a variant; `sem.nim:4564-4568` |
| 12 | A discriminator held in a `const` or `let` is refused even when the value is right, and the message names the variable. | `c29.nim`, `c49.nim` | `c29.nim(12, 14) Error: a case selecting discriminator 'kind' with value 'k' appears in the object construction, but the field(s) 'radius' are in conflict with this value.`, exit 1; `c49` identical with `'width'` | §Constructing a variant |
| 13 | A qualified literal discriminator is accepted. | `c50.nim` | `Circle`, exit 0 | §Constructing a variant |
| 14 | With no branch field, a runtime discriminator is allowed. | `c31.nim` | `Circle` / `0.0`, exit 0 | §Constructing a variant |
| 15 | A `case` statement over an enum must be exhaustive; the message names the missing members. | `c13.nim` | `c13.nim(14, 3) Error: not all cases are covered; missing: {Triangle}`, exit 1 | §What the compiler checks; `sem.nim:2699-2748` |
| 16 | The check also runs on the `case` expression form. | `c55.nim` | `c55.nim(3, 3) Error: not all cases are covered`, exit 1 | §What the compiler checks |
| 17 | A non-enum selector gets the message with no missing list. | `c55.nim`, `c19.nim` | `c55` above; `c19.nim(4, 5) Error: not all cases are covered`, exit 1 | §What the compiler checks |
| 18 | A duplicated label is `value already handled`, reported at the duplicate. | `c57.nim`, `c37.nim` | `c57.nim(8, 6) Error: value already handled`, exit 1; `c37` also `missing: {Circle2}` | §What the compiler checks |
| 19 | A misspelled label is `undeclared identifier`, followed by the missing list. | `c59.nim` | `c59.nim(13, 6) Error: undeclared identifier: Cirlce` + `c59.nim(12, 3) Error: not all cases are covered; missing: {Circle}`, exit 1 | §What the compiler checks |
| 20 | One `of` may name several values, and a range is legal on an ordinal selector. | `c16.nim`, `c62.nim` | `c16`: `2.0` / `24`, exit 0. `c62`: `low` / `mid` / `high`, exit 0 | §What the compiler checks |
| 21 | `else` is allowed on a fully covered enum. | `c28.nim` | `circle`, exit 0 | §What the compiler checks |
| 22 | A `bool` has two values, so `of true` / `of false` need no `else`. | `c54.nim` | `yes`, exit 0 | §What the compiler checks |
| 23 | `case` accepts a holey enum as a selector even though such a type cannot be a discriminator. | `c39.nim`, `c56.nim` | `c39`: `number`, exit 0. `c56`: `wordish`, exit 0 | §What the compiler checks |
| 24 | A `discard` branch is legal. | `c58.nim` | `2.0`, exit 0 (Circle branch discarded) | §What the compiler checks |
| 25 | Reading a field of the inactive branch compiles and returns the shared storage; no runtime check. | `c7.nim` | `Circle` / `1.0` / `0.0`, exit 0 | §What the compiler does not check |
| 26 | Writing a field of the inactive branch compiles and leaves the discriminator alone. | `c8.nim` | `99.0` / `Circle`, exit 0 | §What the compiler does not check |
| 27 | Assigning the discriminator is legal on a `var` and reinterprets the old storage. | `c9.nim`, `c42.nim` | `c9`: `Rectangle` / `3.0` / `3.0`. `c42`: `Rectangle` / `1.0` / `1.0`, both exit 0 | §What the compiler does not check |
| 28 | On a `let`, the discriminator is not mutable. | `c36.nim` | `c36.nim(12, 2) Error: cannot mutate expression s.kind`, exit 1 | §What the compiler does not check |
| 29 | `sizeof` is one byte for a three-value enum plus the largest branch: `1` and `24`. | `c44.nim` | `1` / `24` / `8`, exit 0 | §What the compiler does not check |
| 30 | `==` between two values of the same variant type compares field by field. | `c22.nim` | `true` / `false`, exit 0 | §Samples; Chapter 11 (`lib/std/system.nim:463`) |
| 31 | A `$` is needed to print a variant. | `c26.nim` | `rect(2.0x3.0)`, exit 0 | §Samples; Chapter 11 |
| 32 | A variant is a value: assignment copies it, and a whole-value assignment replaces the branch. | `c11.nim`, `c61.nim` | `c11`: `1.0` / `99.0` / `Rectangle`, exit 0. `c61`: `Rectangle` / `3.0` / `4.0`, exit 0 | §Constructing a variant |
| 33 | A branch may hold a `seq` of the same type; the recursive walk builds and runs. | `c12.nim`, `c45.nim` | `c12`: `2` / `a` / `6`, exit 0. `c45`: `1` / `1`, exit 0 | §Nested variants |
| 34 | A `ref object` variant is constructed and matched the same way. | `c25.nim` | `Circle` / `1.5`, exit 0 | §Nested variants |
| 35 | A bare-value `of` branch plus an `else` branch holding a `for` loop crashes the compiler; writing `result =` in every branch builds. | `r2.nim`, `r3.nim`, `c46.nim`, `c47.nim` | `r2`: `Error: unhandled exception: xelim.nim(118, 3) \`result.typeKind != AutoT\` cannot compute type of: (expr (for …))`, exit 1. `r3`: `3`, exit 0 | §Nested variants; ERRATA candidate 3 |
| 36 | Nim 2 raises `FieldDefect` on a wrong-branch read and on a discriminator assignment, and accepts a `const` discriminator. | `nim2/n1.nim`, `n2.nim`, `n4.nim` (nim 2.4.0) | `n1`: `Error: unhandled exception: field 'width' is not accessible for type 'Shape' using 'kind = Circle' [FieldDefect]`. `n2`: `assignment to discriminant changes object branch … [FieldDefect]`. `n4`: `1.0`, exit 0 | Nim 2 delta box |

Sample output: 19 lines, identical to the block in `en.md` under §Samples, produced by
`nimony c -r samples/12-sum-types-case/sumtypes.nim` at the pin.

## Questions for the reviewer

**A. No runtime branch check (claims 25-27).** At the pin, reading or writing a field of the inactive branch
compiles and touches the shared storage, and assigning the discriminator reinterprets it; Nim 2 raised
`FieldDefect` on all three. Is the absence intended at this pin, or a defect? I could only prove absence by
grep — there is no `FieldDefect` symbol anywhere under `lib/` or `src/` — and a negative grep is the weakest
evidence in this sheet. If a source line states the policy, name it and I will cite it instead. If it is
intended, check that the chapter's wording (a guard you write, not one the compiler gives you) is right.

**B. The `const` discriminator (claim 12).** `const k = Circle; Shape(kind: k, radius: 1.0)` is refused with
the "in conflict" message, although nothing conflicts; Nim 2 accepts the same source (`nim2/n4`). The source
comment above `isConstDiscriminator` (`sem.nim:4600-4618`) says the constant evaluation is avoided deliberately
because it can re-run sem. Is that intended narrowness with an unacceptable message, a defect, or documented
somewhere I missed? Which line should the chapter cite?

**C. The `xelim` crash (claim 35).** `r2.nim` is minimal: `case b of true: 1 else: (result = 0; for …)`. The
compiler reports itself (`AssertionDefect` in `nimsem`, `xelim.nim:118`) rather than a diagnostic. Defect
candidate to file at `nim-lang/nimony`? The chapter currently tells the reader to assign in every branch and
points at `ERRATA.md`.

**D. The wrapped object message (claim 4).** The missing-member error for the object's own `case` section comes
out as `[Error] … illformed AST inside case object: (err . "not all cases are covered; missing\3A
\7BTriangle\7D")` — an error node left in the type body, printed with `\3A` and `\7B` escapes. Is that a
message-quality bug worth filing, or accepted output the chapter should quote verbatim (as it does now, with
the reading underneath)?

**E. `else` in a case section (claim 5).** `synthSumTypeDiscriminator` has `sum type case objects cannot have
an else branch` (`sem.nim:3075`), but a named discriminator with `else` builds here (`c3`), and the anonymous
form is a parse error before it can reach that line (`c30`). Is `else` in the section supported policy, or a
path that happens to work? The chapter says it works and prefers the full list.

**F. One check or two (claim 4 vs 15).** Both the object's section and the `case` statement go through
`checkExhaustiveness` (`sem.nim:2699-2748`, called at `:3290` for `NormalCase` and `ObjectCase`). The
difference in the message is the error node's location, not the check. Confirm that, so the chapter does not
promise a separate object checker — and, if the missing list is built by walking the enum declaration, say
whether its order is guaranteed.

**G. Holey enums (claim 3 vs 23).** A holey enum is refused as a discriminator (`c38`) but accepted as a
`case` selector (`c39`, `c56`). The chapter states both and blames ordinality. Is that the right cause, or is
the discriminator rejection a separate restriction I should name?

## ERRATA candidates

1. **No runtime branch check.** `c7` (read), `c8` (write), `c9`/`c42` (discriminator assignment) all build and
   run; Nim 2 raises `FieldDefect` for each (`nim2/n1`, `n2`). The chapter teaches the guard. Decide whether
   this is a watch row (intended) or a defect candidate — if a defect, it is the same family as Nim's
   `FieldDefect` and the repro is `c7`.
2. **A `const` discriminator is refused.** `c29`, `c49`; message claims a conflict that does not exist;
   `nim2/n4` accepts the same source. Defect candidate or documentation gap — `doc/language.md:629-641` says
   nothing about the discriminator having to be a literal.
3. **`xelim` assertion on a value branch plus an `else` with a `for` loop.** Minimal `r2.nim`; same crash from
   `c46`/`c47` through an enum selector. File at `nim-lang/nimony` with `r2`, not `c46`.
4. **The object case-section message is machine text.** `c2.nim` prints an `(err . …)` node inside the type
   body with `\3A` and `\7B`. Message-quality gap; the information is correct.

Two smaller things, for the record and not for ERRATA unless you disagree: `alignof` is an undeclared
identifier at the pin (`c21`), so the chapter does not mention alignment; and the two construction rejections
(`wrongBranchError` vs `badDiscriminatorError`) fire on different inputs — a named variable gives the "in
conflict" wording (`c6`), an absent discriminator gives "cannot prove that it's safe" (`c51`).

## Statements in `en.md` with no source, commit or probe behind them

None in the teaching text. Every compiler claim has a probe row above and, where one exists, a source line.
The two editorial sentences the chapter does not support with a source — that the missing-member list is the
reason to prefer a sum type over flags, and that `else` hides the member a later edit adds — are arguments
about the reader's workflow, not statements about the compiler, and are written that way.

## Technical review — Momo

Reviewer: Momo (Head of Engineering), 2026-11-12. Pin
`4ba90a781b0b22d0821efaa153c129c37cef6143` (nimony 0.6.3), toolchain
`~/.local/opt/nimony/4ba90a7`; Nim 2 contrasts with `~/.local/opt/nim-2.4.0`.

I ran every probe in `ch12-probes/` myself with `$NIMONY_HOME/bin/nimony c -r`; every line I quote below is
from my own run. I added `rv1`, `rv2`, `rv8`, `rv10`–`rv12`, `rv14`–`rv17` and `rv19` to the same folder for
the checks this review needed.

```
$ ./tools/verify-samples.sh
PASS samples/12-sum-types-case/sumtypes.nim exit=0
SUMMARY 11/11 passed, 0 failed
VERIFY_EXIT=0
```

The sample's 19 output lines are byte-identical to `en.md:303-321` (`diff` empty, exit 0).

### Verdict per claim

| # | Verdict | Evidence from my run |
| --- | --- | --- |
| 1 | held | `c1`: `12.566370614359172` / `12.0` / `Circle` / `2.0`, exit 0. |
| 2 | held | `c40`: `c40.nim(4, 5) Error: selector must be of an ordinal type`, exit 1 (`sem.nim:3207`). |
| 3 | held, packaging differs | `c38`: `[Error] c38.nim(8, 5) illformed AST inside object: (err . "selector must be of an ordinal type")`, exit 1. The cause is `isOrdinalType`, which excludes `HoleyEnumT` unless `allowEnumWithHoles` is set (`typeprops.nim:17-33`), called at `sem.nim:3207`. "Rejected the same way" at `en.md:54-55` has to name the wrapper. |
| 4 | held for `c2`, example pairing wrong | `c2`: exact wrapped line, exit 1. The wrapper is `sem.nim:4705` in the constructor's field walk (`fieldsPresentInBranch`), which meets the `(err)` node the check left in the type body. The chapter's snippet is a bare declaration: that alone prints the clean line, `rv17.nim(5, 5) Error: not all cases are covered; missing: {Triangle}` (`rv17`), and the wrapper needs a construction (`rv19`, which also has no branch field). Add a construction to the snippet or quote the clean line first. |
| 5 | held | `c3`: `24`, exit 0; `c17`: `1.5` / `x` / `24`, exit 0. `doc/language.md:627` documents `else` in the section. |
| 6 | held | `c24`: `c24.nim(9, 7) Error: attempt to redeclare: radius`, plus `expected key/value pair in object constructor`, exit 1. |
| 7 | held for the field form | `c30`: `':' or '=' expected, but got 'keyword of'`, exit 1. Not a language-wide rule: the anonymous sum type has no name (`tests/nimony/object/tjson_sumtype.nim:5-15`) and rejects `else` at `sem.nim:3075` (`rv14`). Scope the sentence. |
| 8 | held | `c10`: `Circle` / `0.0` / `0.0`, exit 0; `c35`: `2.0`, exit 0. |
| 9 | held | `c4`: exact `a case selecting discriminator 'kind' with value 'Circle' ... field(s) 'width' are in conflict` line, exit 1. |
| 10 | held | `c5`: exact `The fields 'radius' and 'width' cannot be initialized together` line, exit 1. |
| 11 | held | `c51`: exact `cannot prove that it's safe to initialize 'radius'` line, exit 1. |
| 12 | held (behaviour), message defective | `c29`/`c49` refuse. `rv1` (a `let`) and `rv2` (a qualified `const`) are refused identically; `rv15`/`rv16` show consts still work as `of` labels, so the restriction is constructor-only. `caseBranchMatchesExpr` builds the real diagnostic into a scratch buffer and then shrinks it (`sem.nim:4615-4624`), leaving only the false "in conflict" line. `en.md:115-117` says "variable" while its example is a `const`; say "a name". |
| 13 | held | `c50`: `Circle`, exit 0. |
| 14 | held | `c31`: `Circle` / `0.0`, exit 0. |
| 15 | held | `c13`: `c13.nim(14, 3) Error: not all cases are covered; missing: {Triangle}`, exit 1. |
| 16 | held | `c55`: `c55.nim(3, 3) Error: not all cases are covered`, exit 1. |
| 17 | held | `c55` and `c19`: no list for a non-enum selector, exit 1. |
| 18 | held | `c57`: `c57.nim(8, 6) Error: value already handled`, exit 1; `c37`: same plus `missing: {Circle2}`, exit 1. |
| 19 | held | `c59`: `undeclared identifier: Cirlce` then `not all cases are covered; missing: {Circle}`, exit 1. |
| 20 | held | `c16`: `2.0` / `24`, exit 0; `c62`: `low` / `mid` / `high`, exit 0. |
| 21 | held | `c28`: `circle`, exit 0. |
| 22 | held | `c54`: `yes`, exit 0. |
| 23 | held | `c39`: `number`, exit 0; `c56`: `wordish`, exit 0. |
| 24 | held | `c58`: `2.0`, exit 0. |
| 25 | **wrong (printed value)** | The rule holds — `c7` compiles and exits 0 — but the value is not `0.0`: `c7` prints `Circle` / `1.0` / `0.0`. `echo s.width` is `1.0` because the radius occupies that slot; only `s.height` is `0.0`. `en.md:194` and Check 8 are wrong. |
| 26 | held | `c8`: `99.0` / `Circle`, exit 0. |
| 27 | held | `c9`: `Rectangle` / `3.0` / `3.0`, exit 0; `c42`: `Rectangle` / `1.0` / `1.0`, exit 0. |
| 28 | held | `c36`: `cannot mutate expression s.kind`, exit 1. |
| 29 | **wrong (numbers)** | `c44` is a two-branch shape: `1` / `24` / `8`. The chapter's three-branch `Shape` is `1` / `32` / `8` (`rv10`): one byte for the discriminator plus the 24-byte payload, rounded to the 8-byte alignment of `float`. `en.md:221-223` and Check 13 are wrong. |
| 30 | held | `c22`: `true` / `false`, exit 0; source `lib/std/system.nim:463`. |
| 31 | held | `c26`: `rect(2.0x3.0)`, exit 0. `echo` has no generic `$` (Chapter 11, `lib/std/syncio.nim:465-468`). |
| 32 | held | `c11`: `1.0` / `99.0` / `Rectangle`, exit 0; `c61`: `Rectangle` / `3.0` / `4.0`, exit 0. |
| 33 | held | `c12`: `2` / `a` / `6`, exit 0; `c45`: `1` / `1`, exit 0. |
| 34 | held | `c25`: `Circle` / `1.5`, exit 0. |
| 35 | held, wording | `r2` asserts at `xelim.nim:118`; `rv8` shows the `else` keyword is not required — an `of false` branch ending in `for` crashes the same way. The input is already invalid by the pin's own rule: `rv12` gives `expression of type int64 must be discarded` for the bare value, so this is a missing diagnostic, not valid code rejected. Say "another branch", not "the `else` branch". |
| 36 | held | `n1`: `field 'width' is not accessible for type 'Shape' using 'kind = Circle' [FieldDefect]`; `n2`: `assignment to discriminant changes object branch ... [FieldDefect]`; `n4`: `1.0`, exit 0 (nim 2.4.0). |

### Answers A–G

**A.** Intended at this pin by construction, not a defect: the payload is a union whose size is the maximum of
its branches (`sizeof.nim:83-105`, `combineCaseObject` at `:34-37`) and no access carries a tag; cite that
layout instead of the negative grep (0 `FieldDefect` hits in `lib/` and `src/`), keep the watch row, and the
chapter's "the guard is yours" wording is correct.

**B.** Intended narrowing with a bad message: the constructor recognises only literal spellings
(`isConstDiscriminator`, `sem.nim:4601-4612`, states that constant evaluation is deliberately avoided), while
consts still work as `of` labels (`rv15`, `rv16`), so the restriction is constructor-only; the "in conflict"
line is a message defect because the real diagnostic is thrown away with the scratch buffer
(`sem.nim:4615-4624`), and `doc/language.md:629-641` is the documentation gap.

**C.** Defect, but not "valid code crashes": `rv12` shows the bare value is already rejected with `expression of
type int64 must be discarded`; the assertion replaces that diagnostic when another branch ends in `for` (`rv8`,
no `else` needed). File it as a missing-diagnostic assertion with `rv8` or `r2`; the chapter's assignment
advice stands.

**D.** Message quality, not a rule: `checkExhaustiveness` leaves an `(err)` node in the type body; a bare
declaration reports the clean line (`rv17`), and the wrapper appears only when a constructor walks the body and
hits the node at `sem.nim:4705` (`rv19`). The information is correct, so quote the wrapped line together with
the construction and do not file.

**E.** `else` in a named section is supported and documented (`doc/language.md:627`); the rejection at
`sem.nim:3075` is the anonymous sum type only (`rv14`), a separate form, so the chapter's claim holds and only
"the discriminator must be named" needs scoping.

**F.** One checker: the single call at `sem.nim:3290` serves `NormalCase` and `ObjectCase`; only the place the
`(err)` is left differs (statement body vs type body), which is why the same node renders as the clean
diagnostic in a `case` statement and as the wrapped line when a constructor walks the type body
(`sem.nim:4705`). The missing list is in declaration order because the loop walks the enum body from its first
field (`sem.nim:2719-2748`); that is the implementation, not a documented guarantee.

**G.** The cause is ordinality as the discriminator path defines it: `sem.nim:3207` calls `isOrdinalType` with
holes disallowed (`typeprops.nim:17-33`), while the `case` statement never calls it, so a holey enum is accepted
because nothing checks it, not because it counts as ordinal; say that rather than implying a positive rule.

### ERRATA rulings

1. **No runtime branch check — keep as a watch row, drop "defect candidate".** Intended by construction at
   this pin: the union is sized by the max of its branches and accesses are plain field writes/reads
   (`sizeof.nim:83-105`, `:34-37`); there are 0 `FieldDefect` occurrences in `lib/` and `src/`. Cite the
   layout, not just the absence. Do not file.
2. **A `const` or `let` discriminator is refused — keep, rewritten.** The behaviour is intended
   constructor-only narrowness (literal spellings only; `sem.nim:4601-4612`), and the "in conflict" message is
   the defect: the real diagnostic is discarded by `caseBranchMatchesExpr` (`sem.nim:4615-4624`). Not a
   behaviour defect; the documentation gap is `doc/language.md:629-641`. File nothing, or file only the
   message as low priority.
3. **The `xelim` assertion — keep as a defect candidate, reframed.** It is a missing diagnostic, not a
   rejected valid program: `rv12` rejects the same bare value properly, and `rv8` shows `else` is not needed.
   File at `nim-lang/nimony` with `rv8` (smaller) or `r2`; low priority. The book's assignment advice stands.
4. **The object case-section machine text — drop as a defect candidate.** The wrapper is the constructor
   walk's generic error (`sem.nim:4705`), the information is correct, and the chapter quotes it with a reading.
   Fix the row and the example: the declaration alone prints the clean line (`rv17`); the wrapped form needs a
   construction (`rv19`). Quote the wrapped line with the construction present. No issue.

### Statements in `en.md` with no source, commit or probe behind them

- `194` and Check 8: `# 0.0` for `echo s.width` — a probe exists and contradicts it (`c7` prints `1.0`).
- `221-223` and Check 13: `sizeof(Shape)` is `24` for the three-branch shape — `c44` is a two-branch shape;
  `rv10` gives `32`.
- `326`: "the triangle's `a`" — no probe; the sample never prints a triangle default. The two `0.0` lines are
  the rectangle's omitted `height` and then its omitted `width`.
- `89`: "The discriminator must be named" — no source, and false as a general rule (the anonymous sum type
  has no name).
- `54-55`: "rejected the same way" — the packaging differs: `c38` wraps the message inside
  `illformed AST inside object: (err . ...)`.
- `86-88`: "Branches share storage, so two live fields cannot have one name" — the storage sharing is probed
  (24/32 layout); the causal clause is reasoning, not a source claim.

Everything else that states compiler behaviour has a probe row above and, where one exists, a source line.

### Text corrections in `en.md`

1. `60-73`: the wrapped message needs a construction. A bare declaration prints the clean line,
   `c2.nim(5, 5) Error: not all cases are covered; missing: {Triangle}` (`rv17`); the wrapper appears when a
   constructor walks the type body (`rv19`, `sem.nim:4705`). Add `let s = Shape(kind: Circle, radius: 1.0)`
   to the snippet, or show the clean line first and the wrapped one as what the constructor reports.
2. `54-55`: for the holey enum, give the actual output — `[Error] c38.nim(8, 5) illformed AST inside object:
   (err . "selector must be of an ordinal type")` — and cite `sem.nim:3207` with `typeprops.nim:17-33`.
3. `89-90`: scope the rule to a field-style section: in this form the discriminator is a named field, and
   `case bool` is a syntax error. The anonymous sum type has no name and is a separate feature.
4. `115-117`: "a discriminator held in a variable" → "a discriminator spelled as a name (`let` or `const`)";
   `rv1` and `rv2` show both are refused, and `rv15`/`rv16` show consts still work as `of` labels, so the
   restriction is constructor-only.
5. `194`: `echo s.width` prints `1.0`, not `0.0` (`c7`: `Circle` / `1.0` / `0.0`); the radius occupies the
   slot. Only `height` is `0.0` there.
6. `221-223`: use the three-branch numbers — `sizeof(ShapeKind)` is `1`, `sizeof(Shape)` is `32` (`rv10`):
   1 byte discriminator + 24 bytes of payload, rounded to the 8-byte alignment of `float`. If `24` stays, say
   explicitly that it is the two-branch shape from `c44`.
7. `225-227`: say "another branch", not "the `else` branch" (`rv8`), and add that the bare value is already an
   error ("expression of type int64 must be discarded", `rv12`); the defect is that the `for` hides the
   diagnostic. Keep the assignment-in-every-branch advice.
8. `326`: the two `0.0` lines are the rectangle's omitted `height` and `width`, not "the triangle's `a`".
9. Check 8 (`347`): expected `1.0`, not `0.0`.
10. Check 13 (`353`): expected `1` and `32` for the three-branch version, not `1` and `24`.

### Left open

None. Every verdict above is one compile-and-run at the pin; the Nim 2 rows were run with 2.4.0. The two
unproven-by-source rulings (A and B) are marked as such and rest on the code path, not on a sentence in the
manual.
