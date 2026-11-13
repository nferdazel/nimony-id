# Chapter 3 — review record

Draft: 2026-11-12, Aksara. Pin: `4ba90a781b0b22d0821efaa153c129c37cef6143` (nimony `0.6.3`).
Technical review: **Momo, 2026-11-12** — eight of eleven claims held, #9 was staged at the wrong scope, #10 had the
right message but the wrong trigger, #11 stood. All three corrections are applied in `en.md` and `id.md`.

## Sample verification

Momo ran the verifier at the pin on 2026-11-12:

```
toolchain ~/.local/opt/nimony/4ba90a7/bin/nimony 0.6.3 pin 4ba90a7
PASS samples/02-pinned-toolchain/hello.nim exit=0
PASS samples/03-values-names-mutability/values.nim exit=0
SUMMARY 2/2 passed, 0 failed
```

Exit code `0`, and he ran `values.nim` directly: it prints exactly the chapter's list — `nimony / names and
values`, `8`, `6`, `2`, `5`, `100`, `2`, `1`, exit 0.

Aksara re-ran the same verifier from the book folder after the editorial pass, following the only change to the
sample (one comment line):

```
toolchain ~/.local/opt/nimony/4ba90a7/bin/nimony 0.6.3 pin 4ba90a7
PASS samples/02-pinned-toolchain/hello.nim exit=0
PASS samples/03-values-names-mutability/values.nim exit=0
SUMMARY 2/2 passed, 0 failed
```

Exit code `0`; `nimony c -r values.nim` still prints the same eight lines in the same order.

## Claims in the draft

| # | Statement in the draft | Evidence | Verdict |
| --- | --- | --- | --- |
| 1 | Nimony is case-sensitive; `step` and `Step` are two live names | `doc/language.md:7`, `doc/differences.md:22`; sample prints `2` then `5` | **PASS** |
| 2 | `{.feature: "ignoreStyle".}` restores Nim 2 style-insensitive lookup per module | `doc/language.md:4997` lists `"ignoreStyle"` as a compatibility feature; Aksara's probe, not re-run by Momo | **PASS** (probe from draft, not re-run) |
| 3 | Writing to a `let` fails with `Error: invalid reassignment to \`let\` variable` | exact string at `src/nimony/contracts_fir.nim:4811` | **PASS** |
| 4 | A `let` is not an l-value: cannot go to a `var` parameter, address cannot be taken | `doc/language.md:1646-1655`, read at the pin: not l-values, no `var` parameter, no address; `importc` is the stated initializer exception | **PASS as documented** |
| 5 | `const` accepts a routine call whose arguments are compile-time; `const Twice = double(4)` is `8` | `doc/language.md:24-31`; sample prints `8` | **PASS** |
| 6 | The value part of each `const` opens its own scope | `doc/language.md:1711-1733` states it with its own example (`const foo = (var a = 1; a)`, then `const bar = a # error`) | **PASS as documented** |
| 7 | Redeclaration in the same block fails with `Error: attempt to redeclare: step`; a nested `block:` may reuse the name and the outer value returns afterwards | exact `attempt to redeclare: ` at `src/nimony/semdecls.nim:507` and `:743`; sample prints `100` then `2` | **PASS** |
| 8 | `_` is never added to scope, so it can be declared repeatedly | `doc/language.md:1656-1670`: any definition named `_` is not added to scope | **PASS as documented** |
| 9 | A local `var` of a plain type starts at its zero value: `var chosen: int` with no write prints `0` | The draft's probe ran at **module level**, so it declared a global. Proved instead at the pin (Momo): module-level `var chosen: int` reads `0`; the same lines inside a proc are rejected with `cannot prove that x has been initialized`; one branch writing still rejected; both branches writing compiles | **NOT PROVEN AT PIN as written** — rewritten |
| 10 | A local `var` of a type with no zero value is rejected before a write: `Error: cannot prove that base has been initialized`, and `{.noinit.}` suppresses the check | message real at `src/nimony/contracts.nim:352-358` and `tests/nimony/errmsgs/tinitnotprovenlocal.msgs:1`; but the check has no type filter — a plain `int` local hits it too. Module-level `var base: ref int` is refused earlier, at the declaration, with the no-default-value message | **CORRECT — wording** |
| 11 | A `const` whose value depends on a `var` is a compile error, reported at the `const` line | reproduced: `b.nim(2, 15) Error: undeclared identifier: runtime`, at the identifier on the `const` line | **PASS** |

## The two open questions, answered

**A — var initialization.** The draft's split was not the rule; it was the rule for globals only. At the pin, the
analysis at `contracts.nim:352-358` has no type filter and `doc/language.md:1591-1630` is accurate as written.
What changed in the chapter: the zero-value paragraph is now explicitly about **module level**, and the local rule
is stated as proof-before-read, with `int` named as a type that fails it too. The sentence "what it does *not* do
at the pin is reject a plain `int` that nobody assigned" is gone.

**B — const from a var.** Intended enough to teach. Constant expressions see literals, built-in operators,
previously declared constants and compile-time calls (`doc/language.md:24-31`); a `var` is not visible there at
all, so the failure is a plain scope error, not a constant-expression diagnostic. The chapter keeps saying "a
compile error at the `const` line" and does not quote the message as a constant-expression one.

## Changes applied in the editorial pass

1. `var` section rewritten to Momo's #9 replacement: module-level zero value, local proof rule, both-branches vs
   one-branch. The module-level `var chosen: int` example block in the prose is gone.
2. #10 replacement applied verbatim: the check is about proof, not the type; module-level no-default-value case
   with its exact message; `{.noinit.}` hands you raw storage, not `0`.
3. #11 prose left as it was, per the verdict.
4. One line in `values.nim` changed (a comment only): the module-level `var chosen` is labelled as zeroed, not as
   "proved by control flow". The sample's output is unchanged and re-verified.
5. A fifth check added, runnable and matching the corrected rule: local `var` with no write is rejected, module
   level is not.
6. `GLOSSARY.md` `zero value` rewritten to the corrected split; `ERRATA.md` Chapter 3 watch rows updated to the
   verdict (neither is an erratum — no frozen text was ever wrong).

## Definition-of-done state

| Gate | State |
| --- | --- |
| One job | yes — declarations, scope, spelling; no second job |
| Samples run | `values.nim` PASS, `SUMMARY 2/2 passed, 0 failed`, exit 0 |
| Technical review | **done** — Momo 2026-11-12, 6 PASS, 2 PASS-as-documented, 2 corrected, 1 rewritten |
| Editorial pass | **done** — 2026-11-12 |
| Both languages | `en.md` and `id.md`, frontmatter identical |
| Frozen | **yes** — 2026-11-12 |

## Glossary

Added in this handoff: `let variable`, `case-sensitive identifier`, `scope (of a name)`, `zero value`.
