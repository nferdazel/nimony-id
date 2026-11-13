# Chapter 18 — technical review

**Chapter:** Templates and Compile-Time Evaluation (`chapters/18-templates-compiletime/en.md`)
**Status:** `drafting` · **Words:** 2,561 (body, frontmatter excluded) · **Claims:** 45
**Pin:** `4ba90a781b0b22d0821efaa153c129c37cef6143` (nimony 0.6.3) · **Host compiler for contrasts:** Nim 2.4.0 (`~/.local/opt/nim-2.4.0`)
**Verifier (run by me, 2026-11-13):**

```
toolchain ~/.local/opt/nimony/4ba90a7/bin/nimony 0.6.3 pin 4ba90a7
PASS samples/18-templates-compiletime/templates.nim exit=0
SUMMARY 17/17 passed, 0 failed
```

Sample output diffed against the block in `en.md` §Samples: `6`, `100`, `report ready`, `3`, `3`, `9`, `6`, seven
lines, byte-identical.

Probes live in `probes/ch18/`
(`a01`–`a32b`, `c01`–`c27`, `b01`, `sample`/`sample2`, plus `nim2/n1`, `nim2/n2`, `nim2/n3`). Each is a directory
whose `main.nim` was run with `~/.local/opt/nimony/4ba90a7/bin/nimony c -r main.nim`; the Nim 2 probes used
`~/.local/opt/nim-2.4.0/bin/nim c -r --hints:off`. Every probe imports `std/syncio` before `echo`.

## Claim table

| # | Claim as the chapter states it | Probe | Raw output (abbreviated) | Section |
| --- | --- | --- | --- | --- |
| 1 | A template is a substitution mechanism processed in the semantic pass and invoked with call syntax | `doc/language.md:4504-4510`; a01 | `twice(21)` → `42`, exit 0 | A template is substituted |
| 2 | Each expansion is checked where it is used, and the error quotes the substituted source with a trace to the call | a28 | `main.nim(5, 1) Trace: instantiation from here` then `Type mismatch`, body echoes `Plain(n: 1) + Plain(n: 1)`, exit 1 | A template is substituted |
| 3 | A local a template declares is renamed, so a module-level name of the same spelling is untouched | a03 | `99` then `1`, exit 0 | The names it declares are not your names |
| 4 | The same holds for a value-returning template expanded next to a caller variable of the same name | a22 | `6` then `100`, exit 0 | The names it declares are not your names |
| 5 | `declared` does not see the template's local | a09 | `42` then `false`, exit 0 | The names it declares are not your names |
| 6 | A name in the body resolves in the template's own scope, so a caller-local proc of the same name does not win | a21 | `module helper`, not `local helper` | Where a template's names come from |
| 7 | Resolution is deferred: a proc declared below the template but above the call resolves | a13 | `declared below the template`, exit 0 | Where a template's names come from |
| 8 | A passed block cannot see the template's locals | a27 | two `Trace: instantiation from here` lines then `undeclared identifier: local`, exit 1 | What you pass in cannot see |
| 9 | The manual's `untyped` block example fails at the pin | a05 | `main.nim(7, 3) Error: undeclared identifier: 'p'`, exit 1 | What you pass in cannot see |
| 10 | The manual's `typed` block example fails differently and earlier | a06 | `expression of type ``typed`` must be discarded` at `(5, 5)`, then `undeclared identifier: 'p'`, exit 1 | What you pass in cannot see |
| 11 | `{.inject.}` on a proc declaration makes the name visible to the caller | a07 | `helper ran` | Injection |
| 12 | `{.inject.}` on a `let` declaration makes the name visible to the caller | a07 | `123` | Injection |
| 13 | `{.gensym.}` writes the default explicitly and the name stays invisible | a07 / a09 | `declared(held)` → `false` | Injection |
| 14 | `{.dirty.}` does not expose a template-local to the caller | a08 | `Trace` then `undeclared identifier: exposed`, exit 1 | Injection |
| 15 | `{.dirty.}` is documented as the pragma for a body that must reference the caller's identifiers, needing `{.feature: "untyped".}` | `doc/porting.md:262-282` | text quoted | Injection |
| 16 | A real-type parameter checks the argument and names the template's own parameter list | a32b, a32 | `42` for `addOne(41)`; `addOne("s")` → `[1] expected: int64 but got: string (declared in main.nim(2, 1))`, exit 1 | Which parameter type |
| 17 | A `var` parameter writes back through the caller's variable | a16 | `7`, exit 0 | Which parameter type |
| 18 | Arity distinguishes templates sharing a name | a12 | `one` then `two`, exit 0 | Which parameter type |
| 19 | `varargs[untyped]` accepts the call and refuses every use of the parameter | a11, a11b, a11c | `.len` → `expected: openArray[T] but got: int64`; `for a in args` → `expected: openArray[T] but got: int64`; `echo args` → `got: varargs[untyped]` | Which parameter type |
| 20 | A `typed` parameter used in the body fails on every `echo` overload as `got: typed` | a29d | `expected: string but got: typed` … `expected: float64 but got: typed`, exit 1 | Which parameter type |
| 21 | A `typed` parameter returned as `int` fails as `got: typed but wanted: int64` | a31 | `main.nim(2, 39) Error: type mismatch: got: typed but wanted: int64`, exit 1 | Which parameter type |
| 22 | A `typed` parameter that the body ignores is accepted | a29, a30 | both build, `7` from a30, exit 0 | Which parameter type |
| 23 | Nim 2.4.0 runs both refused templates, printing 41 and 42 | nim2/n3 | `41` then `42`, exit 0 | Which parameter type |
| 24 | A value-less template used as a value is an error at the use, `has no type (or is ambiguous)`, followed by a `void` cascade | a17 | `expression 'note("hi")' has no type (or is ambiguous)` at `(4, 5)`, then `got: void`, exit 1 | Statement or expression |
| 25 | A template ending in an expression can initialize a `const` | a14 | `6`, exit 0 | Statement or expression |
| 26 | A bare template name without `()` is `undeclared identifier: greet`, for either declaration shape | a24, a24b | both `undeclared identifier: greet`, exit 1; a24c with `()` prints `hello` | Statement or expression |
| 27 | `doc/porting.md:255-262` documents a different message for the bare call than the pin prints | `doc/porting.md:255-262`; a24b | doc: `expression of type proc() must be discarded`; pin: `undeclared identifier: greet` | Statement or expression |
| 28 | A constant expression may depend on literals, built-in operators, earlier constants and foldable routine calls | `doc/language.md:26-31`; c01 | `21` then `10`, exit 0 | A constant is a value |
| 29 | String concatenation and `len` fold | c02 | `hello, world` then `12` | A constant is a value |
| 30 | An array constant folds `len` and indexing | c03 | `4` then `5` | A constant is a value |
| 31 | A string index on a constant folds to a `char` | c15 | `n` then `12` | A constant is a value |
| 32 | Object and enum literals are constants and their fields read back | c09 | `0` then `origin` | A constant is a value |
| 33 | A `const` cannot be initialized from a runtime value, and a `let` above it is invisible | c11 | `undeclared identifier: runtime`, exit 1 | A constant is a value |
| 34 | A later `const` is invisible, and the failed constant collapses to `auto`, causing a second error | c17 | `undeclared identifier: B`, then `got: auto` from `echo A`, exit 1 | A constant is a value |
| 35 | A `const` cannot be mutated | c07 | `cannot mutate expression Floor`, exit 1 | A constant is a value |
| 36 | A `const` inside a routine is legal and folds | c22 | `12`, exit 0 | A constant is a value |
| 37 | Routine calls fold, including a `for` with an `if` | c04, c05 | `9`; `30`, exit 0 | What the evaluator will compute |
| 38 | A `while` accumulating folds, and so does recursion | c14, c10 | `6`; `120` | What the evaluator will compute |
| 39 | A `seq` grown with `add` folds, giving length and element | c18 | `4` then `9` | What the evaluator will compute |
| 40 | A string grown with `&` folds, giving content and length | c21 | `xxxx` then `4` | What the evaluator will compute |
| 41 | `.len` of a `const` array folds, but `.len` of a `const` seq does not, while the seq works at runtime | c03, c26, c27 | array `4`; seq in const → `cannot evaluate expression at compile time: len(Table)` + `undeclared field: 'len' for type seq[int64]`; runtime `3` and `2` | What the evaluator will compute |
| 42 | An index outside a constant array reports a cannot-evaluate error, not a bounds error | c08, c24 | `cannot evaluate expression at compile time: [10, 20, 30][5]`; `cannot evaluate expression at compile time: Table[3]` | What the evaluator will compute |
| 43 | Constant arithmetic that overflows is an error with its own message | c16 | `expression overflow at compile time: 127'i8 + 1'i8` | What the evaluator will compute |
| 44 | A routine that prints while being folded prints nothing; only the value comes back | c19 | `40` only, no `evaluating at compile time` line | What the evaluator will compute |
| 45 | A folded value is accepted where a constant is required, including from a routine call | c06, c25 | `4`; `6`, exit 0 | What the evaluator will compute |

Source read, not probed: that object **fields** inside a template body default to injection rather than renaming
(`src/nimony/semuntyped.nim:215-218`, comment "locals default to 'gensym', fields default to 'inject'"). The chapter
states it as a source-read fact; see question A.

## Questions

**A. Hygiene completeness.** The chapter's rule is: any local a template declares is renamed unless it carries
`{.inject.}`, fields are injected by default, a caller's same-name declaration cannot capture a body identifier, and
the body's lookup is deferred in time but fixed in the template's own scope (semuntyped.nim:183-191, `:214-260`).
Is that the complete rule at this pin — in particular the field exception, which I have from the source comment and
not from a run?

**B. `typed` template parameters.** `doc/language.md:4527-4529` lists `typed` as a usable meta type. At the pin a
`typed` parameter passes the meta-type into the body: `echo x` fails for every overload (a29d) and `x` as `int`
fails as `got: typed but wanted: int64` (a31), while the same two templates print `41` and `42` under Nim 2.4.0
(nim2/n3). Defect worth filing with a31 as the repro, or an intended deprecation?

**C. `{.dirty.}`.** `doc/porting.md:262-282` gives it one job: let a body reference the caller's identifiers, with
`{.feature: "untyped".}`. My probe a08 asked the other direction — whether a dirty template's own local reaches the
caller — and it did not. Is that a correct reading (dirty is about incoming names, not outgoing ones), and is the
dirty path in `semuntyped.nim` / `semdecls.nim:1185` actually exercised at the pin or vestigial?

**D. The const boundary.** An array's `.len` folds (c03) and a seq's does not (c26), while the seq itself is a fine
constant at runtime (c27). Is that asymmetry a known gap, or is there a shape where a `const` seq's length does
fold — `len(Table)` written as an explicit call, for instance? The chapter currently says only what it demonstrated
and calls the boundary non-uniform.

**E. Effects while folding.** `echo` inside a folded routine prints nothing and the value still comes back (c19).
`expreval.nim:283-320` forwards unfoldable calls to a sub-compile. May the chapter state "the program's effects are
not run while a constant is computed" as a guarantee, or is that an accident of how the sub-compile runs?

**F. Out-of-range constant index.** `const Bad = [10, 20, 30][5]` reports `cannot evaluate expression at compile
time` rather than a bounds message (c08, c24). Intended, or a gap worth an ERRATA row?

**G. `varargs[untyped]`.** It accepts the call and then refuses `.len`, `echo args` and `for a in args` (a11,
a11b, a11c). Is there any working use at the pin — forwarding the whole parameter to another call — or is "do not
write it" the right instruction?

## ERRATA candidates

1. **`doc/language.md:4566-4583` — documentation defect.** The section's `untyped` example is presented as the
   version that compiles ("the same code works with `untyped`"); at the pin it fails with
   `undeclared identifier: 'p'` (a05), because the `proc p` declared inside the template is hygienic like any other
   local. The `typed` version fails too (a06). Correct diagnosis is injection, which the page never mentions.
2. **`doc/language.md:4527-4529` — documentation defect or compiler defect, depends on question B.** `typed` is
   presented as a usable template parameter meta type; every use of the argument in the body fails at the pin
   (a29d, a31). Nimony's own `tests/nimony/templates/` has no case that uses a `typed` parameter's value.
3. **`doc/porting.md:255-262` — documentation defect.** The section prints `expression of type proc() must be
   discarded` for a bare template call. The pin prints `undeclared identifier: greet` for both declaration shapes
   (a24, a24b). The rule the section teaches (always write `()`) is right; the message is stale.
4. **`doc/language.md:33` — documentation gap, not a defect.** "The restrictions for this mechanism are currently
   undocumented" is accurate, and it is why the chapter's const section states only demonstrated shapes.

Watch rows for `ERRATA.md` at freeze, subject to Momo's ruling: the seq-`.len` fold gap (question D) and
`varargs[untyped]` being accepted but unusable (question G).

## Open

Nothing in the chapter's 45 claims is left unsettled: every one has a probe or a source line. The items above are
candidates for a ruling, not claims I cannot cite — question B is the one that can change a sentence in the text,
because "a `typed` slot is the one shape that looks right in the manual and cannot be used" becomes "a `typed` slot
is deliberately unsupported" if Momo calls it intent rather than a defect.

# Verdict — Momo, 2026-11-13

**Verifier, run by me from the authoring folder, not taken from your paste:**

```
toolchain ~/.local/opt/nimony/4ba90a7/bin/nimony 0.6.3 pin 4ba90a7
PASS samples/18-templates-compiletime/templates.nim exit=0
SUMMARY 17/17 passed, 0 failed
```

`nimony c -r samples/18-templates-compiletime/templates.nim` prints `6 / 100 / report ready / 3 / 3 / 9 / 6`,
byte-identical to `en.md:284-291`. `en.md`, `id.md` and `samples/` untouched.

**Verdict: 42 of the 45 table claims stand as written, two are corrected (14, 19), one is narrowed (41), and the
sentence after claim 44 is wrong and must go.** Nothing is open.

The big one is question C. `a08` ran without `{.feature: "untyped".}`, so it never entered the dirty path at all;
with the feature on, a dirty template's local is visible to the caller (`m01` prints `exposed` as `5`). The chapter's
"`{.dirty.}` is not that switch" is the opposite of what the pin does.

## Claim by claim

| # | Verdict | Evidence |
| --- | --- | --- |
| 1 | stands | a01 → `42`; `doc/language.md:4504-4510` says the same |
| 2 | stands | a28: trace at `(5,1)`, error at `(4,41)`, substituted `Plain(n: 1) + Plain(n: 1)` |
| 3 | stands | a03 → `99`, `1` |
| 4 | stands | a22 → `6`, `100` |
| 5 | stands | a09 → `42`, `false` |
| 6 | stands | a21 → `module helper` |
| 7 | stands | a13 → `declared below the template` |
| 8 | stands | a27: two trace lines, then `undeclared identifier: local` |
| 9 | stands | a05: `undeclared identifier: 'p'` |
| 10 | stands | a06: `expression of type ``typed`` must be discarded` at `(5,5)`, then `p` |
| 11 | stands | a07 → `helper ran` |
| 12 | stands | a07 → `123` |
| 13 | stands | a07/a09 → `declared(held)` is `false` |
| 14 | **corrected** | a08 has no `{.feature: "untyped".}`, so the dirty branch never runs. With the feature the local is visible: m01 → `5`. See Q C. |
| 15 | stands | `doc/porting.md:268-271` says exactly that, feature included |
| 16 | stands | a32b → `42`; a32 → `[1] expected: int64 but got: string (declared in main.nim(2, 1))` |
| 17 | stands | a16 → `7` |
| 18 | stands | a12 → `one`, `two` |
| 19 | **corrected** | Direct reads fail (a11, a11b, a11c), but `discard args` (m18), `let x = args` (m24) and forwarding the parameter (m07) build. `for` expands to `items(1)`, not the meta-type. See Q G. |
| 20 | stands | a29d: eight `echo` overloads, every line `got: typed` |
| 21 | stands | a31: `got: typed but wanted: int64` |
| 22 | stands | a29 builds (and accepts `notDeclared`), a30 → `7` |
| 23 | stands | nim2/n3 → `41`, `42` |
| 24 | stands | a17: `has no type (or is ambiguous)`, then the `void` cascade |
| 25 | stands | a14 → `6` |
| 26 | stands | a24/a24b both `undeclared identifier: greet`; a24c → `hello` |
| 27 | stands | `doc/porting.md:255-262` prints a message the pin never prints |
| 28 | stands | c01 → `21`, `10` |
| 29 | stands | c02 → `hello, world`, `12` |
| 30 | stands | c03 → `4`, `5` |
| 31 | stands | c15 → `n`, `12` |
| 32 | stands | c09 → `0`, `origin`; c09 has no enum, my m22 → `green` |
| 33 | stands | c11: `undeclared identifier: runtime` |
| 34 | stands | c17: `undeclared identifier: B`, then `got: auto` |
| 35 | stands | c07: `cannot mutate expression Floor` |
| 36 | stands | c22 → `12`; "folded once" is the definition of a const, not a measured cost |
| 37 | stands | c04 → `9`; c05 → `30` |
| 38 | stands | c14 → `6`; c10 → `120` |
| 39 | stands | c18 → `4`, `9` |
| 40 | stands | c21 → `xxxx`, `4` |
| 41 | **narrowed** | True for a seq reached through a named const (c26, m10, m11, and even `when Table.len`, m13). False as a statement about seq: the literal folds, `(@[4, 5]).len` → `2` (m12), `len(@[1, 2, 3])` → `3` (m14). |
| 42 | stands | c08: `[10, 20, 30][5]`; c24: `Table[3]`, both cannot-evaluate |
| 43 | stands | c16: `expression overflow at compile time: 127'i8 + 1'i8` |
| 44 | stands | c19 → `40`, no `evaluating at compile time` line. The next sentence is the error: m16 writes a file at compile time. |
| 45 | stands | c06 → `4`; c25 → `6` |

## Questions A–G, one line each

**A.** Complete for the non-dirty path, and now with two extra confirmations. Object fields really are injected:
m09 declares `type T {.inject.} = object` with `fieldName`, and `t.fieldName` from the caller still resolves and
prints `5`; without the `{.inject.}` the type name itself is gensym'd and invisible (m06). Loop variables are locals
too: `declared(i)` after a template's `for i` is `false` (m23). Params are substituted, not renamed. The one missing
clause in the rule is `{.dirty.}`, which is question C.

**B.** Compiler defect, not deprecation. The argument is never bound or checked: `template typedSlot(x: typed) =
discard; typedSlot(notDeclared)` builds at the pin (m21), while Nim 2.4.0 refuses it with `undeclared identifier:
'notDeclared'`. That is why the body sees the meta-type (`a29d`, `a31`) rather than the argument's type. No test under
`tests/nimony/templates/` uses a `typed` parameter's value. File with m21 as the sharpest repro and a31 for the
mismatch; `doc/language.md:4527-4529` states the intent, so this is not a documentation defect.

**C.** The dirty path is exercised, not vestigial. `semdecls.nim:1183` gates the whole untyped path on
`untypedIsActive`, so a08 (no `{.feature: "untyped".}`) never reached `semdecls.nim:1185`. With the feature on, a
dirty template's declarations are injected (`m01` → `5`) and the caller's own identifiers resolve in the body
(`m04` → `7`); with it off, the local is invisible (a08) and the caller's name is undeclared (m05). Dirty is both
directions, not incoming-only, and the doc's porting use is the incoming one. Delete "not that switch" and "not a way
to publish a name".

**D.** Yes, one shape: the seq literal folds. `const Count = (@[4, 5]).len` is `2` (m12) and `len(@[1, 2, 3])` is
`3` (m14); a seq reached through a named `const` does not fold (c26, m10, m11, m13). So the boundary is the
named-const indirection, not seq versus array. No ERRATA: the doc promises nothing here, and the evaluator's
cannot-evaluate message is honest.

**E.** Not a guarantee. A `writeFile` inside a folded routine really writes during compilation: after removing the
file and touching the source (the fold cache otherwise reuses the old result), `nimony c m16.nim` left `foldside2.txt`
containing `written`. `echo` stays silent because the sub-compile captures stdout for the value, not because effects
are suppressed. Keep the printing observation and drop "the program's effects are not run".

**F.** No bounds check in the evaluator: an out-of-range constant index cannot produce a value, so it reports
cannot-evaluate. The doc never promises a bounds error and the message is accurate. No ERRATA and no ticket; say the
evaluator declines to fold rather than that "bounds are a runtime concept here".

**G.** The only uses that build are uses that do not read the values: `discard args` (m18), `let x = args` (m24),
and passing the parameter to another `varargs[untyped]` slot (m07). Everything that inspects them fails (a11, a11b,
a11c, m17, m19, m25). `args.len` expands to `len(1)` and `for a in args` to `items(1)` — the first argument, not the
meta-type. "Do not write it" is the right instruction; "refuses every use" is not.

## Prose corrections, with the chapter lines

- `:151-154` — rewrite the dirty paragraph. Without `{.feature: "untyped".}` the pragma is inert (a08, m05); with it,
  the template's locals are injected (m01) and the caller's names resolve (m04). It is a porting escape hatch, not an
  incoming-only switch, and it does publish a name.
- `:172-174` — narrow "refuses every use of the parameter" to uses that read the values. Add that `discard args`,
  `let x = args` and forwarding the parameter build (m18, m24, m07). Replace "because each iteration binds the
  meta-type" with the observed expansion: `args.len` → `len(1)`, `for a in args` → `items(1)` (a11, a11b).
- `:175-179` — add one sentence: `typedSlot(notDeclared)` builds, so the argument is not even resolved at the call;
  the parameter is a placeholder. That is the defect, not a type difference from Nim 2.
- `:234-244` — say "a seq reached through a named `const`" instead of "a `const` seq", and add that the literal folds:
  `(@[4, 5]).len` is `2`, `len(@[1, 2, 3])` is `3` (m12, m14). The named const remains the failing shape.
- `:253-256` — delete "What that does not do is run the program's effects". Say only that a print inside a folded
  routine does not reach the terminal; a file write inside one happens at compile time (m16). The silence is how the
  value is captured, not an effect-free promise.
- `:65-70` — no change; the field exception is now confirmed by a run (m09).

## ERRATA rulings

1. **Documentation defect — `doc/language.md:4566-4583`.** Confirmed. The `untyped` version fails with
   `undeclared identifier: 'p'` (a05), and adding `{.inject.}` to `proc p` makes it print `hey` (m20), so injection is
   the correct diagnosis. The `typed` version fails earlier (a06).
2. **Compiler defect — template instantiation for `typed` parameters.** Reclassify the review's candidate 2: it is
   not a documentation defect. The argument is never bound or checked (m21), so every use in the body sees the
   meta-type (a29d, a31). File it with m21 and a31; the doc listing at `:4527-4529` is the intended contract and
   needs no change.
3. **Documentation defect — `doc/porting.md:255-262`.** Confirmed. The pin prints `undeclared identifier: greet` for
   both declaration shapes (a24, a24b), not `expression of type proc() must be discarded`. The rule (write the
   parentheses) is right; the quoted message is stale.
4. **Accurate gap statement — `doc/language.md:33`.** No action. "The restrictions are currently undocumented" is
   true, and it is why the chapter only claims demonstrated shapes.

Watch rows: keep the seq-`.len` asymmetry but reword it to the named-const shape; keep `varargs[untyped]` but say
"accepted and unreadable" rather than "every use refused".

## Probes I ran

Every probe the table cites, plus b01 and nim2/n3: a01, a03, a05, a06, a07, a08, a09, a11, a11b, a11c, a12, a13,
a14, a16, a17, a21, a22, a24, a24b, a24c, a27, a28, a29, a29d, a30, a31, a32, a32b, b01, c01–c11, c13–c22, c24–c27,
nim2/n3. My own under `probes/ch18/m/`:
`m01`–`m05` dirty with and without the feature, `m06`/`m09` object type and field injection, `m07`/`m17`/`m18`/`m19`/
`m24`/`m25` varargs, `m10`–`m14` seq/array `.len` shapes, `m15`/`m16` effects while folding, `m20` injection on the
manual example, `m21` `typedSlot(notDeclared)`, `m22` enum const, `m23` loop-variable hygiene.

## Still unverified

- `{.dirty.}` outgoing injection for declaration kinds other than `var`; the source comment covers every non-param
  decl, m01 proves the `var` case.
- `costs nothing per call` for a routine-level `const` (claim 36); it is a definition, not a measured cost.
- The fold cache hides repeat runs of m16 until the source is touched; that is build behaviour, not a language fact.
