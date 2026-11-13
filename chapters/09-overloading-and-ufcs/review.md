# Chapter 9 review sheet — Overloading and UFCS

Draft: `chapters/09-overloading-and-ufcs/en.md` (`status: drafting`, 2,402 words).
Sample: `samples/09-overloading/overloading.nim`.
Toolchain: `~/.local/opt/nimony/4ba90a7`, pin `4ba90a781b0b22d0821efaa153c129c37cef6143` (nimony 0.6.3).
Verifier: `./tools/verify-samples.sh` → `SUMMARY 8/8 passed, 0 failed`, exit 0.

Each claim below is what the chapter teaches. The probe is the file in
`~/.openmausbot/workspaces/be336972-1e63-4f00-9916-c76cc8e33654/ch9-probes/`, run with
`$NIMONY_HOME/bin/nimony c -r <file>`; the output is pasted raw, trimmed to the lines that matter. Every claim
you verify replaces a row with `held` or `wrong, because …`; do not rewrite the rows I cite.

| # | Claim in the chapter | Probe | Raw output at the pin | Source in chapter |
| --- | --- | --- | --- | --- |
| 1 | Two routines may share a name when their parameter lists differ, and the argument type picks the candidate. | `q1.nim` | `int 3` / `str a`, exit 0 | §One name, several routines |
| 2 | Arity is part of the parameter list, so `twice(x)` and `twice(x, y)` coexist. | `q5.nim` | `one` / `two`, exit 0 | same |
| 3 | The return type is not part of the parameter list: the same list twice compiles, and the call is ambiguous. | `q4.nim` | `q4.nim(4, 7) Error: ambiguous call: 'g'` + two candidate lines (`int64`/`int64`), exit 1 | same |
| 4 | The guide describes resolution as a symbol choice and says ambiguity is reported during semantic analysis. | — | `doc/language.md:1318`, `:1325-1326` | §How the compiler chooses |
| 5 | Category matching ranks exact > literal > generic > subrange/subtype > integral > conversion. | — | `doc/language.md:1328-1345` | same |
| 6 | With `pick(x: int)` beside `pick(x: int32)`, `pick(5)` picks `int`. | `q2.nim` | `int`, exit 0 | same |
| 7 | With `pick(x: int)` beside `pick(x: float)`, `pick(5)` is `int` and `pick(5.0)` is `float`. | `v1.nim` | `int` / `float`, exit 0 | same |
| 8 | With `amb(x: int32)` beside `amb(x: float)`, `amb(5)` is ambiguous and lists both. | `v4.nim` | `Error: ambiguous call: 'amb'` + `int32` and `float64` lines, exit 1 | same |
| 9 | `int` and `int64` are the same type at the pin, so a pair overloading on both is two identical candidates. | `t1.nim`, `t4.nim` | `t1`: `int64` / `8` / `8`, exit 0. `t4`: `ambiguous call: 'once'` with two identical `(x: int64)` lines, exit 1 | same |
| 10 | Passing an `int` value to `show(x: int32)` fails with `[1] expected: 32 but got: 64`. | `v2.nim` | `v2.nim(4, 10) Error: Type mismatch at [position]` + `[1] expected: 32 but got: 64`, exit 1 | §Checks 6 |
| 11 | Module-of-origin prefers a routine declared in the calling module. | — | `doc/language.md:1375-1400` (documented, **not probed** — needs two modules) | §How the compiler chooses |
| 12 | `5.twice` and `5.twice()` are the same call; `5.twice(1)` resolves the two-argument candidate. | `q6.nim`, sample | `10` / `10`; sample prints `10` / `11` | §Method call syntax |
| 13 | The receiver must match the first parameter, and the message rewrites the call to `1.(wrap, "a")` with `expected: string but got: int64`. | `r4.nim` | `r4.nim(3, 12) Error: Type mismatch at [position]` / `1.(wrap, "a")` / `[1] expected: string but got: int64`, exit 1 | same |
| 14 | `3.count[int](4)` parses as `(3.count)[int]` and fails with `undeclared field: 'count' for type int64`. | `u3.nim` | `u3.nim(3, 7) Error: undeclared field: 'count' for type int64`, exit 1; message site `src/nimony/sem.nim:5162` | same |
| 15 | `3.count[:int](4)` works and prints `2`. | `u2.nim` | `2`, exit 0 | same |
| 16 | The bare call form `count[:int](3, 4)` does **not** parse at the pin: `invalid indentation` at the bracket. | `u1.nim` | `u1.nim(3, 11) Error: invalid indentation`, exit 1 | same (labelled probed, not quoted) |
| 17 | A `var` and a non-`var` overload are not two candidates: the call is ambiguous. | `r5.nim` | `Error: ambiguous call: 'get'` + `(b: var Box, …)` and `(b: Box, …)` lines, exit 1 | §Nim 2 delta |
| 18 | A `var` result cannot be borrowed from a non-`var` parameter: `cannot borrow from b.v`. | `r2.nim` | `r2.nim(4, 39) Error: cannot borrow from b.v`, exit 1; message site `src/nimony/derefs.nim:448` | same |
| 19 | With `b: var Box` and a `var int` result, reading `b[0]` builds and prints `7`. | `q9.nim` | `7`, exit 0 | same |
| 20 | Assignment to an index without a `[]=` fails at the assignment with a wall of built-in candidates that never mention the user type. | `s1.nim`, `s2.nim` | `s1.nim(6, 1) Error: Type mismatch at [position]` / `b[0] = 9` / `[1] Box does not match constraint T …` + 10 built-in candidate lines, exit 1; same from inside a `proc` (`s2`, `(6, 3)`) | same |
| 21 | Declaring `[]=` makes the same assignment compile and print `9`. | `s3.nim` | `9`, exit 0 | same, and the sample |
| 22 | `doc/differences.md:31-43` is the source of the delta (Nim 2 pair → one polymorphic accessor). | — | quoted verbatim from that file | same |
| 23 | The ambiguity message is built at `src/nimony/semcall.nim:1397`; the `[: ]` rewrite is parser-level, `doc/language.md:2855-2866`. | — | grep of `src/` and `doc/` at the pin | §One name / §Method |

## Questions

**A.** Claim 9 (`int` is `int64`) is measured but not documented anywhere I can find in `doc/`. Is that
intended at the pin, and is there a file or commit line I should cite instead of only probes?

**B.** Claim 16 — bare `p[:T](x)` failing with `invalid indentation` — is not predicted by
`doc/language.md:2862-2866`, which describes only the receiver form. Documentation/message gap, or defect
candidate for `ERRATA.md`? I marked it probed, not quoted, and teach the receiver form only.

**C.** Claim 20 — the assignment resolving to built-in `[]` candidates instead of saying "no `[]=` for Box" —
intended message, or defect candidate?

**D.** Claim 18 — is `cannot borrow from` the borrow checker in `derefs.nim`, i.e. the intended replacement for
the removed `var T` overload, or did I attach the wrong cause to a coincidence? The chapter presents it as the
check that does the overload's old work.

**E.** Should the `[]=` rule (an accessor alone does not make a type writable) become a book-wide line in
`CONTRIBUTING.md`, or stay a Chapter 9 fact with a pointer from later container chapters?

**F.** Claims 11 and 4–5 rest on `doc/language.md` sections that Chapter 9 quotes but does not re-derive. Is
quoting the guide enough for those three, or do you want a run for module-of-origin as well?

## ERRATA candidates from this chapter

Not written into `ERRATA.md` yet — I need your ruling first, same as Chapter 8.

1. `int` and `int64` are one type at the pin (probe `t1`), which makes any Nim 2 port that overloaded on both
   widths ambiguous (`t4`). Citation available: probes only.
2. `p[:T](x)` in call position → `invalid indentation` (`u1`), against `doc/language.md:2862-2866`.
3. Index assignment with no `[]=` reports the built-in candidate list rather than the missing setter (`s1`).

---

## Technical review — Momo, 2026-11-12

Pin `4ba90a781b0b22d0821efaa153c129c37cef6143` (`nimony 0.6.3`), macOS arm64. I re-ran all twenty probe files
named in the table, then added probes where the table's claim needed a second command. Every result below is my
own run. The sample was re-run twice: `tools/verify-samples.sh` → `SUMMARY 8/8 passed, 0 failed`, exit 0;
`nimony c -r samples/09-overloading/overloading.nim` → exit 0, and the eight stdout lines diff empty against
`en.md:335-342`.

**Verdict: 21 of 23 claims hold. Claim 18 is wrong as generalised; claim 20 is right in substance but wrong
about what the error message contains.** Claim 9 now has a source instead of probes only, and claim 11 is no
longer unprobed: I ran it with two modules.

### Claim verdicts

| # | Verdict | Evidence at the pin |
|---|---|---|
| 1 | Held | `q1`: `int 3` / `str a`, exit 0. |
| 2 | Held | `q5`: `one` / `two`, exit 0. |
| 3 | Held | `q4`: `ambiguous call: 'g'` + two `(x: int64)` candidate lines, exit 1. |
| 4 | Held | `doc/language.md:1318-1326`; the symbol-choice sentence is 1320-1322. |
| 5 | Held for the guide; pin wider | The list is the guide's. At the pin an integer literal also ties with a `float` candidate (`v4`, `x8`), which the list does not say. See the literal note below. |
| 6 | Held | `q2`: `int`, exit 0. |
| 7 | Held | `v1`: `int` / `float`, exit 0. |
| 8 | Held | `v4`: `ambiguous call: 'amb'`, int32 and float64 listed, exit 1. |
| 9 | Held, now sourced | `t1`: `int64` / `8` / `8`; `t4`: `ambiguous call: 'once'` with two identical `(x: int64)` lines. Source: `src/nimony/builtintypes.nim:160-163` builds `int` as `(i configBits)`, `:197-199` builds `int64` as `(i 64)`, and `src/nimony/semmain.nim:652` passes the target bits, 64 here. |
| 10 | Held | `v2`: `[1] expected: 32 but got: 64`, exit 1. |
| 11 | Held, now probed | Two modules: a local `pick` wins (`main`), and without a local the imported one is used (`lib`), both exit 0. |
| 12 | Held | `q6`: `10` / `10`; sample: `10` / `11`. |
| 13 | Held | `r4`: `1.(wrap, "a")`, `[1] expected: string but got: int64`, exit 1. |
| 14 | Held | `u3`: `undeclared field: 'count' for type int64`; message site `src/nimony/sem.nim:5162`. |
| 15 | Held | `u2`: `2`, exit 0. |
| 16 | Held | `u1`: `invalid indentation` at (3, 11), exit 1. |
| 17 | Held | `r5`: `ambiguous call: 'get'`, both candidates listed, exit 1. |
| 18 | **Wrong as generalised** | `r2`'s message is real for an inline field, but a value parameter over heap storage returns `var` fine: `func [](x: Container, i: int): var int = x.data[i]` prints `1`, exit 0 (`y7`). `validBorrowsFrom` (`src/nimony/derefs.nim:258-314`) allows a first parameter that is `var`/`out`/`lent`, or a path through indirection. So "a non-`var` parameter" is not the rule. The message site is `derefs.nim:466-468`, not 448; 448 is the tuple-constructor branch. |
| 19 | Held | `q9`: `7`, exit 0. |
| 20 | Held in substance, wrong detail | `s1`/`s2` fail at the assignment with the built-in candidate wall, exit 1. But the wall's first line is `[1] Box does not match constraint T`, so it does name the type; what it lacks is a sentence saying the setter is missing. |
| 21 | Held | `s3`: `9`, exit 0. |
| 22 | Held | `doc/differences.md:31` is the bullet; the two code blocks run to 44. |
| 23 | Held | `src/nimony/semcall.nim:1397` builds the ambiguity message; `src/nimony/sem.nim:5162`; `doc/language.md:2855-2866`. |

### Answers to A–F

**A. Intended by construction, not a defect.** `int` is not a distinct magic type here: `src/nimony/builtintypes.nim:160-163`
makes it `(i configBits)` and `:197-199` makes `int64` `(i 64)`; `src/nimony/semmain.nim:652` supplies the target
bits, 64 on every target this book builds for. Cite those three instead of probes only. Scope the sentence to a
64-bit target: on a 32-bit target `int` would be `(i 32)` and the pair would be distinct.

**B. Documentation gap, not a defect.** `doc/language.md:2862-2866` defines only the receiver form, so the bare
form was never promised. Keep "probed, not quoted"; a watch row can cite `src/nifler2/parserrt.nim:148` and
`:296`.

**C. Intended resolution path; message quality only.** The assignment is resolved as `[]=`, and with no setter of
yours the built-in templates are the only candidates. That is the design, not a bug. The row should say the wall
names the type once and then lists built-ins, and cite `src/nimony/semcall.nim:1436` (the `Type mismatch at
[position]` builder) and `lib/std/system.nim:32` (first built-in candidate).

**D. It is the borrow checker, but your cause is attached too broadly.** `trReturn` at `src/nimony/derefs.nim:466-468`
calls `validBorrowsFrom` (`:258-314`), and that is what rejects `b.v`. The removed `var T` overload is a
resolution rule (`doc/differences.md:31`), a separate mechanism. More importantly, borrowing from a plain
parameter is allowed when the access path goes through indirection, which is exactly what a real container does:
`x.data[i]` over a `seq` field compiles and returns `var` from a value parameter. Rewrite the section as "a
`var` result needs a path that can be borrowed: `var`/`out`/`lent` parameter or heap indirection; an inline field
of a by-value object has none".

**E. Not CONTRIBUTING.** It is language behaviour, and Chapter 9 is the right owner. Add a pointer from Chapter 10
(arrays, sequences, tuples) and Chapter 14 (ownership and borrow checking) rather than a book-wide drafting rule.

**F. Quoting is enough for 4 and 5, not for 11.** Claims 4 and 5 are statements about the guide's model, so
quoting it is honest if the chapter says "the guide's ranking". Claim 11 is a statement about pin behaviour, and
the body presents it as fact; I probed it (local wins, imported otherwise), so cite that probe or label the
paragraph "documented model, probed 2026-11-12". A doc quote alone does not satisfy CONTRIBUTING rule 5 for a
behaviour claim.

### ERRATA candidates

| # | Ruling | Line to cite instead |
|---|---|---|
| 1 | Keep as a watch row, not a defect. Scope it to 64-bit targets. | `src/nimony/builtintypes.nim:160-163`, `:197-199`, `src/nimony/semmain.nim:652`. |
| 2 | Keep as a watch row; documentation/message gap, not a bug. | `src/nifler2/parserrt.nim:148`, `:296`; `doc/language.md:2862-2866`. |
| 3 | Keep, but rewrite: the wall does name the type in its first line. What is missing is "no `[]=` for Box". | `src/nimony/semcall.nim:1436`; `lib/std/system.nim:32`. |

### Chapter text — statements to fix

Line numbers are `en.md` as drafted; I did not edit the file.

1. `en.md:20-23` — wrong example. `echo` is one declaration, `template echo*() {.varargs.}` at
   `lib/std/syncio.nim:465`, so "`echo` with one argument and `echo` with three are two declarations" is false.
   The `$` half is real: `lib/std/system/formatint.nim:104` and `lib/std/system/dollars.nim:41`.
2. `en.md:103-105` — "an integer literal does not have a type until a candidate gives it one" has no source.
   Mark it probed, or drop the explanation and keep the observed result.
3. `en.md:120-121` — "an integer literal also matches a float parameter at the literal category" is not what
   `doc/language.md:1333-1347` says: the list gives integer literals integer targets and float literals float
   targets. The tie is real at the pin (`v4`, `x8`: `f(5)` ambiguous between int32 and float64), but it is a
   probe finding. Say so, and do not present it as the documented category.
4. `en.md:154-156` — add the source lines for `int` = `int64` from question A, and say "on a 64-bit target".
5. `en.md:158-161` — module-of-origin is now probed; add the two-module result or the "probed" marker.
6. `en.md:183-185` — "`f 1, 2` is two statements" is wrong. `add 1, 2` in statement position parses as one call
   and fails with `expression of type int64 must be discarded`, not as two statements. Contrast the expression
   form from Chapter 8 instead.
7. `en.md:269-271` — the bold heading "a `var` result cannot be borrowed from a non-`var` parameter" is false in
   general; see claim 18 and `y7`. Restrict it to inline storage.
8. `en.md:281` — the cited line is wrong: `src/nimony/derefs.nim:466-468`, with `validBorrowsFrom` at `:258-314`.
9. `en.md:283-284` — "the check that does the work the removed overload used to do" overstates it. The removal is
   a resolution rule; the borrow check constrains where a `var` result may point. Reword.
10. `en.md:286-288` — "a wall of built-in candidates that do not mention your type" is false; the first line is
    `[1] Box does not match constraint T`.
11. `en.md:318-319` — "only if it can borrow from a parameter that is itself `var`" is too narrow: `lent` works
    (`y3`, `y5`) and indirection works with a plain parameter (`y7`). Use the wording from question D.
12. `en.md:29-30` — "this pin enforces it in a specific place rather than everywhere" is vague; once the section
    is rewritten, name the two places: overload resolution (no `var`-ness dimension) and the borrow pass
    (`validBorrowsFrom`).
13. Citation range: `doc/language.md:1328-1345` misses the sixth category, which is at 1346-1347. Use
    `1328-1347`.

### Left open

None of the 23 claims is left open. Claim 9 is settled for every target this book builds for (64-bit); the
32-bit case is out of scope, not unproven. The ad-hoc probes for `lent` and `ptr` borrowing are not in the book's
probe set; they are evidence for the wording fix, not new chapter claims.

---

## Editorial pass — 2026-11-12

Momo's thirteen text corrections are applied in `en.md`; `id.md` is written from the corrected text, not from
the draft. What changed beyond a line edit:

1. The borrow section is rebuilt around Momo's answer D: "a `var` result needs a path it can borrow", with
   `trReturn` (`derefs.nim:466-468`) and `validBorrowsFrom` (`:258-314`), and the `seq`-backed counter-example.
2. That counter-example is now part of the sample instead of prose: `samples/09-overloading/overloading.nim`
   ends with a `Container` over `data: seq[int]`, `echo c[0]` → `1`, then a direct write to `c.data[0]` and
   `echo c[0]` → `5`. Verified by `tools/verify-samples.sh` (8/8, exit 0), so the claim rests on the book's own
   probe set, not on an ad-hoc run.
3. Three ERRATA watch rows written with the ruled citations, plus a fourth for the borrow rule shared with
   Chapters 10 and 14.
4. `GLOSSARY.md`: `overload resolution` citation range corrected to `1318-1347`, `polymorphic accessor` now
   states the borrow constraint, and `module-of-origin` added — it is used in the chapter's prose.
5. Wording that stated a probe result as the guide's rule now carries "probed, not quoted" (`pick`, the
   `int32`/`float` tie, module-of-origin, `add 1, 2` in statement position).
