# Chapter 16 — technical review

**Chapter:** Modules and Visibility (`chapters/16-modules-visibility/en.md`)
**Status:** `drafting` · **Words:** 2,455 · **Claims:** 50
**Pin:** `4ba90a781b0b22d0821efaa153c129c37cef6143` (nimony 0.6.3) · **Host compiler for contrasts:** Nim 2.4.0 (`~/.local/opt/nim-2.4.0`)
**Verifier (run by me, 2026-11-13):**

```
toolchain ~/.local/opt/nimony/4ba90a7/bin/nimony 0.6.3 pin 4ba90a7
PASS samples/16-modules-visibility/modules.nim exit=0
SUMMARY 15/15 passed, 0 failed        VERIFY_EXIT=0
```

Sample output diffed against the block in `en.md` §Samples: `diff` empty, 6 lines. The sample is four files:
`modules.nim` plus `support/{shapes,report,notes}.nim`; `tools/verify-samples.sh` compiles only `samples/*/*.nim`,
so the `support/` files are inputs, not samples.

Probes live in `probes/ch16/`
(`p01`–`p45`, `p08b`, `p08c`, `p11a`/`p11b`, `p12b`, `p22b`, `p24b`, `p26b`, `p26c`, `p37`–`p44`, `h1`–`h3`,
`nim2/n1`, `nim2/n2`). Each probe is a directory whose `main.nim` was run with
`~/.local/opt/nimony/4ba90a7/bin/nimony c -r main.nim`; the Nim 2 probes used `nim c -r --hints:off`.
Every module-level probe needs `import std/syncio` before `echo`; a probe without it fails on `echo` first and
hides the thing being tested (that mistake cost me the first run of the whole set).

## Claim table

| # | Claim as the chapter states it | Probe | Raw output (abbreviated) | Section |
| --- | --- | --- | --- | --- |
| 1 | The file name is the module name, minus `.nim` | p12b | `import sub/helper` then `helper.help()` → `helped` | A module is a file |
| 2 | The import takes a path with `/`; the qualified call takes the module name | p12, p12b | `import sub/helper` + `help()` → `helped`; `helper.help()` → `helped` | A module is a file |
| 3 | Two `shapes.nim` in different directories are two modules both called `shapes` | p44 | `import one/shapes, two/shapes` → `1` / `2`, exit 0 | A module is a file |
| 4 | Both can be imported by path while the calls stay unqualified | p44 | `aval()` prints `1`, `bval()` prints `2`, exit 0 | A module is a file |
| 5 | A qualified `shapes.aval()` then fails with `ambiguous identifier` | p44b | `main.nim(3, 6) Error: ambiguous identifier`, exit 1 | A module is a file |
| 6 | An imported module's module-level statements run before the importing file's body | p18 | `module init` then `main start` then `ready 1` | A module is a file |
| 7 | That holds even when the import sits in the middle of the file | p18 | the import is line 3, after `echo "main start"`; output order unchanged | A module is a file |
| 8 | `import` brings exported top-level names in unqualified | p01 | `import util` + `greet("ada")` → `hello ada` | What `import` brings |
| 9 | There is no implicit prelude: `std/syncio` is needed before `echo` | every first attempt | `util.nim(2, 3) Error: undeclared identifier: 'echo'` | What `import` brings |
| 10 | Imports are not transitive | p19 | `b` and `c` import `d`; `main` imports `b, c`; `shared()` → `undeclared identifier: 'shared'`, exit 1 | What `import` brings |
| 11 | A declaration without `*` is private; the call fails as undeclared | p02, p27 | `main.nim(3, 1) Error: undeclared identifier: 'secret'` | The export marker |
| 12 | The message never says private or "declared here but not exported" | p02, p27, p40 | all three give the same `undeclared identifier` line, no second line | The export marker |
| 13 | `*` goes on `proc`, `type`, `const`, `let`, `var` | p01, p03, p28, p08c | proc and type from p01/p03; `echo Answer` → `42`, `echo label` → `util`; `counter = 9` at module level → `9` | The export marker |
| 14 | Object fields carry `*` separately from the type | p03 | `p.y` prints; `p.x` → `Error: undeclared field: 'x' for type Point`, exit 1 | The export marker |
| 15 | The refused field read names the type, not the module | p03 | the message above, at `main.nim(5, 7)`, plus `Trace: instantiation from here` | The export marker |
| 16 | Exporting an enum makes its members usable by name | p04 | `import util` + `echo green` → `green` | The export marker |
| 17 | A constructor from outside does not have to name a private field | p24, p24b | `Point(y: 2)` builds and prints `2` | The export marker |
| 18 | The private field takes its default, with no warning | p24b | `x 0 y 2`, exit 0, no diagnostic | The export marker |
| 19 | A private type returned by an exported routine is a usable handle | p22 | `let h = make()` then `show(h)` → `hidden 5` | Reading what a name is not |
| 20 | The caller cannot name that type | p22b | `var other: Hidden` → `main.nim(5, 12) Error: undeclared identifier: Hidden` | Reading what a name is not |
| 21 | `import util as u` takes the module name away | p17 | `util.greet("ada")` → `undeclared identifier: util`, exit 1 | Five import spellings |
| 22 | The alias does not hide the unqualified names | p06 | `import util as u` then both `u.greet("ada")` and `greet("ada")` → `hello ada` twice | Five import spellings |
| 23 | `import util except greet` imports the rest | p07 | `other("ada")` prints; `greet("ada")` → `undeclared identifier: 'greet'` | Five import spellings |
| 24 | The `except` list is not checked against what the module exports | p42 | `import util except secret` where `secret` is private → `hello ada`, exit 0 | Five import spellings |
| 25 | `from util import greet` imports that name only | p05 | `greet` prints; a second exported routine `other` → `undeclared identifier: 'other'` | Five import spellings |
| 26 | `from` on a private name is refused with the same message | p27 | `from util import secret` → `undeclared identifier: 'secret'` | Five import spellings |
| 27 | `from util import nil` keeps the qualified form and nothing unqualified | p16 | `util.greet("ada")` → `hello ada` | Five import spellings |
| 28 | Attached routines: for an argument of a nominal type from another module, that module's exported routines with the call's name and a parameter of the type become candidates | `doc/language.md:1280-1315`; p37 | text quoted; `from inner import Thing` + `show(t)` → `thing 3` | Routines attached to argument types |
| 29 | It works with only the type imported | p37 | `thing 3`, exit 0 | Routines attached to argument types |
| 30 | Routines that never mention the type are not attached | p37, p26c | `banner()` → `undeclared identifier: 'banner'`, exit 1 | Routines attached to argument types |
| 31 | A routine declared in a third module that takes the type is not attached | p38 | `a` declares `A`, `b` declares `showA(x: A)`, `main` imports `a` only → `undeclared identifier: 'showA'` | Routines attached to argument types |
| 32 | A non-exported routine is never attached | p40 | private `hide(t: Thing)` → `undeclared identifier: 'hide'` | Routines attached to argument types |
| 33 | It works with `from m import nil` and a `var` receiver | p39 | `c.inc()` then `value(c)` → `1`, exit 0 | Routines attached to argument types |
| 34 | `export shapes` forwards the module to the importer | p10, t3 | `main` imports `wrap`/`report` only, constructs `Thing`/`Shape` and calls `show`/`describe` | `export` re-exports |
| 35 | `export shapes.Shape` forwards one symbol, and the attached routines still arrive | p26c | `show(t)` builds; `banner()` → `undeclared identifier: 'banner'` | `export` re-exports |
| 36 | The name in `export` is a module name resolved relative to the exporting file | h3, t3 | `support/report.nim` does `import shapes` + `export shapes`; `main` at the root gets `Thing` and prints `7` | `export` re-exports |
| 37 | A path in an export statement is not accepted, and the failure can be a hang | h1, h2 | h1 (import only): `Error: file not found: …/4ba90a7/src/lib/support/shapes.nim`; h2 (same line plus `export support/shapes`): no output, still running at 40 s, `RC=124` | `export` re-exports |
| 38 | `include` pastes the file's text; no `*` is needed and nothing is exported | p09, p43 | `include part` + `echo twice(4)` → `8`, with `part.nim` declaring `proc twice(n: int)` and no `*` | `include` |
| 39 | A two-module cycle is refused and the message names the file that lacks the pragma | p11a | `Error: import cycle: 'b.nim' imports 'a.nim' without {.cyclic.}; every import on a cycle needs it`, exit 1 | Cycles |
| 40 | `{.cyclic.}` on each import on the cycle makes it build | p11b | `a`, exit 0 | Cycles |
| 41 | The same name from two imports is an ambiguous call, and both declarations are named | p13 | `main.nim(3, 5) Error: ambiguous call: 'show'` + `proc (n: int64) (declared in one.nim(2, 1))` + the same for `two.nim` | When two modules export the same name |
| 42 | Writing an exported `var` from a routine body is refused, in its own module too | p08, p30 | `util.nim(5, 7) Error: unsynchronized access to global variable 'counter'; pass it to a `.sync` routine or use `{.cast(assumeSync).}`` and the same from a proc in `main.nim` | Mutable globals across a module boundary |
| 43 | Module-level statements are exempt | p08c | `counter = 9` at the top of `main` → `9`, exit 0 | Mutable globals across a module boundary |
| 44 | `{.cast(assumeSync).}:` around the block permits it | p31 | `bump()` twice then `echo counter` → `2` | Mutable globals across a module boundary |
| 45 | `{.sync.}` on your own routine does not silence the check | p08b | `proc bump*() {.sync.}` → the same `unsynchronized access` error at `inc counter` | Mutable globals across a module boundary |
| 46 | `{.feature: "assumeSync".}` switches it off for the whole module | p45 | `2`, exit 0; the rule is stated at `src/nimony/contracts_fir.nim:4105-4109` and `src/nimony/features.nim:59-63` | Mutable globals across a module boundary |
| 47 | `import` inside a routine is accepted and takes effect for the whole module | p23, p41 | p23 builds and prints `hello ada`; p41 also prints `hello outside` from a call outside the proc | Two places the manual does not match the pin |
| 48 | A missing module is reported as `file not found`, naming the toolchain's `src/lib` path | p25, h1 | `main.nim(2, 1) Error: file not found: ~/…/4ba90a7/src/lib/help.nim` | Two places the manual does not match the pin |
| 49 | Nim 2 has no attached-routine lookup for an ordinary call | nim2/n1 | Nim 2.4.0: `main.nim(3, 1) Error: undeclared identifier: 'show'`, exit 1 | Nim 2 delta |
| 50 | Nim 2 needs no import before `echo` | nim2/n2 | Nim 2.4.0: `plain echo`, exit 0 | Nim 2 delta |

## Questions for the Head of Engineering

**A. Is `doc/language.md:1280-1315` the complete attached-routine rule at the pin?** I tested the by-value case
(`p37`), a `var` receiver under `from m import nil` (`p39`), a third-module routine (`p38`) and a private routine
(`p40`). Untested: the qualifier list the doc gives (`sink`, `lent`, `out`, `ref`, `ptr`), generic instances
(`G[A]` attaching to the module that declares `G`), and whether an argument that is a `seq[Thing]` or `array[3,
Thing]` attaches `Thing`'s routines. If any of those is wrong, the chapter's one-sentence rule needs the qualifier
list removed or the container case added.

**B. Is #35 the intended split?** `export shapes.Shape` makes the type nameable and still lets `show(t)` resolve,
while `banner()` stays invisible. That is what I would predict from the two rules being independent, but it means
"export one symbol" never removes the type's operations, which a reader may read as a leak. Confirm intended, so I
can say it as a rule rather than an observation.

**C. `import` inside a routine (#47).** `doc/language.md` says "The `import` statement is only allowed at the top
level", and at the pin `p23` builds with the import in a proc body and `p41` shows it applying to the whole module,
calls outside the proc included. Is that hoisting by design (the statement is processed as a module directive
wherever it is written), or an accepted-but-unintended shape? It changes whether I call the doc line wrong in
`ERRATA.md` or describe a quirk to avoid.

**D. The hang (#37).** `h2` is four lines per file: `import support/shapes` in `support/report.nim` (unresolvable
from there) plus `export support/shapes` on the next line. `h1`, with the same import and no export, prints
`file not found` and exits 0 after listing errors. With the export line the compiler produces nothing and is still
running at 40 s, at 0% CPU. Is `h2` minimal enough to file, and is the hang in path resolution or in the NIF job
runner?

**E. Mutable globals (#42-#46).** Is "module-level statements, or `{.cast(assumeSync).}` / `{.feature:
"assumeSync".}`" the complete set of ways to write an exported `var` from a routine body? The message offers
"pass it to a `.sync` routine", and `{.sync.}` on my own proc does not help (`p08b`), so I read that clause as
being about `.sync` library routines only. I also want to know whether `.sync` is a pragma the compiler trusts
with no body check, which is what `src/nimony/contracts_fir.nim:4095-4109` says in the comment.

**F. Ambiguity (#41).** Does `from one import show` always resolve it, or is there a shape where one of the two
wins by declaration order or by scope distance? `p13` gives the two-candidate message; I have not tried three
modules or a `var` versus non-`var` pair.

**G. Constructor and a private field (#17-#18).** `Point(y: 2)` from outside the module builds and the private `x`
is `0`. I read that as "the constructor is not an exhaustiveness check", which is consistent with Chapter 12's
findings, but it also means a private field is not really private if it can be left unset from outside. Intended?

## ERRATA candidates

1. **`doc/language.md`, "The `import` statement is only allowed at the top level" — documentation gap or defect,
   ruling requested.** `p23` builds with the import inside a proc and `p41` shows it taking effect for the whole
   module. Either the sentence is wrong or the pin is lenient; the chapter teaches the top-level form meanwhile.
2. **A path in an `export` statement can hang the build instead of failing — defect candidate.** `h2`: the same
   unresolvable path that `h1` reports as `file not found` produces no output and no exit when it also appears in
   `export`. A hang with no diagnostic is worse than a wrong path, and a subdirectory module is exactly where a
   reader will write it: `import support/shapes` inside `support/report.nim` is the natural mistake, because the
   correct form is `import shapes`.
3. **A missing module names only the toolchain's `src/lib` path — message gap, low priority.** `p25` and `h1` both
   print `file not found: <toolchain>/src/lib/<name>.nim` for a module that was looked for next to the importing
   file. The reader is told to look in the Nimony install for a file that belongs to their project.

## What I did not test

- `import "path/to/module"` with the string form, and `import` with a `.nim` suffix.
- Three or more modules on one cycle, and `{.cyclic.}` on one side only (the message says every import on the cycle
  needs it; I tested both sides, not one).
- Whether an `export` of a generic module forwards its instances.
- `include` with a path outside the including file's directory beyond `include support/notes` in the sample.

---

## Technical review — Momo (Head of Engineering), 2026-11-13

**Verdict: 48 of 50 claims stand. Two are corrected (#37, #42), none open. Two sentences outside the claim table also change (E and F). The attached-routine rule, which is the chapter's centre, is complete as written.**

Verified myself at `~/.local/opt/nimony/4ba90a7` (0.6.3, pin `4ba90a7`), not from the pasted output:

```
$ ./tools/verify-samples.sh
SUMMARY 15/15 passed, 0 failed                  VERIFY_EXIT=0

$ nimony c -r samples/16-modules-visibility/modules.nim
square: 4 sides, 360 degrees
4 sides
square: 4 sides, 360 degrees
SQUARE
note: square
square has 4 sides
diff against en.md:321-326 -> empty
```

All `p01`-`p45`, `nim2/n1`, `nim2/n2` re-run. Every other row in the table reproduced.

Three evidence notes first. `h1`, `h2`, `h3` are **not in** `ch16-probes/`; I rebuilt them from your description under `/tmp/ch16x/hang/`. `h1` exits **1**, not 0. `h2` is not at 0% CPU: `nimsem` spins at 100%, and its RSS was 4.0 GB at 35 s; the one-line `export 3` repro reaches 1.3 GB in 5 s. Extra probes for A/E/F live in `/tmp/ch16x/{sink,lent,out,ptrp,refp,genp,seqp,arrp,f1..f7,sync1..sync4,c1,alias44}`.

### Corrections that change the chapter

1. **#37 is too narrow, and the failure is worse than "hangs".** A one-line module containing `export 3` is enough: `nimsem` spins at 100% CPU, allocates 1.3 GB in 5 s, prints nothing, and was still running at 20 s (`RC=124`). The path form is one instance of "the operand is not a name". Mechanism: `semExport` loops on `while x.hasMore` (`semimport.nim:411-414`) and calls `semExportSymbol`; for a non-ident, non-dot operand, `takeIdent` returns 0 without advancing the cursor (`asthelpers.nim:27-45`, the fall-through at `:43-45`), so the same node is re-read and `buildErr` (`semimport.nim:338-341`) appends to `dest` forever. Rewrite the section's sentence as: an `export` operand that is not a plain name or `module.name` spins with no diagnostic and grows memory; `export support/shapes` is the realistic way to hit it.
2. **#42 is true for direct writes only.** `let p* = addr counter` at module level, then `p[] = 5` inside a routine, builds and prints `5` (`sync3`), because `sharedRootPos` treats a deref as leaving the global (`contracts_fir.nim:4129-4139`). A direct write, a field, an element and `(addr counter)[]` are refused (`p08`, `p30`, `sync4`). Say "a direct write" in the chapter and record the alias escape as a check gap in ERRATA; it is not a trick to teach.
3. **E: `.sync` is a real route, not only a message.** `proc own(p: var int) {.sync.}` plus `own(counter)` from another routine compiles and prints `2` (`sync1`). `p08b` only proves that `{.sync.}` does not silence a direct `inc counter`; it does not prove the pragma is useless on your own proc. `.sync` is trusted, not checked (`contracts_fir.nim:4097-4106`, `:4369`). Add one sentence: the paragraph currently reads as if the only routes are the two `assumeSync` switches.
4. **F: `from one import show` does not fix the ambiguity.** With `import two` also present, `from one import show` leaves both candidates and the call is still ambiguous (`f3b`), with both declarations listed. What works: `import one except show` (`f5` prints `two`), a qualified `one.show(...)` (`f6` prints `one`), or narrowing both sides (`from one import show` plus `from two import nil`, `f7` prints `one`). Drop `from` from the fix sentence, or qualify it as "only when it is the only import of that module".

### Answers A-G

**A. Complete; keep it.** All six qualifiers attach (`sink` prints `ate 3`, `lent` `peek 3`, `out` `filled 9`, `ptr` `ptr 3`, `ref` `ref 3`); a generic instance attaches the module that declares the generic (`Box[int]` prints `3`); `seq[Thing]` and `array[3, Thing]` do not attach (`undeclared identifier: 'showSeq'` and `'showArr'`), because `nominalRoot` resolves them to `seq`/`array` in `system` and `addTypeboundOps` skips `system` (`semcall.nim:451-501`, `:745`; `typeprops.nim:267-304`). The doc's singular list is exact: one `ref`/`ptr` level, not two.

**B. Intended by construction, no leak either way.** `export shapes.Shape` only registers the name in the exporter's filter (`semimport.nim:344-357`, `:359-397`); attachment is computed from the type symbol's home module via `pool.symModule(s)` (`semcall.nim:464-501`). The two rules are independent, so a forwarded type always drags its home module's matching routines, and unrelated procs (`banner`) stay invisible.

**C. The doc line is wrong at the pin; whether it is intended is not proven.** `ImportS` is dispatched without `toplevelGuard` (`sem.nim:5947-5953`) while calls and assignments are guarded, and `c1` builds and prints `hello outside` with the proc that contains the import never called. Ruling: documentation defect. Keep teaching the top-level form.

**D. `h2` is not minimal and the failure is not a wait.** Minimal repro is `export 3`; the hang is `nimsem` spinning in `semExport`/`semExportSymbol` (correction 1), not path resolution or the NIF job runner. File with `export 3` and keep `export support/shapes` as the realistic case.

**E. Not the complete set.** The routes are: module-level statements (exempt), `{.cast(assumeSync).}:`, `{.feature: "assumeSync".}`, and passing the global (or a field or element) to a `var`/`ptr` parameter of a `.sync` routine, including your own proc (correction 3). Separately, the check does not follow a pointer stored in a module-level `let` (correction 2), so "refused everywhere" is not literal.

**F. No tie-break by declaration order or mutability.** Three modules give three candidates (`f1`), and a `var int` versus `int` pair stays ambiguous (`f2`). The own module's declaration wins by scope distance (`f4` prints `own`). `from` alone does not resolve an existing plain import (correction 4); `except` and qualification do.

**G. Intended; keep the paragraph.** Construction is a partial field-init expression and unmentioned fields take their default (`doc/language.md:654-670`), so `Point(y: 2)` is not an exhaustiveness check and a private field is a name rule, not an init rule. No ERRATA.

### Claim verdicts

| # | verdict | evidence |
| --- | --- | --- |
| 1 | stands | p12b `helped` |
| 2 | stands | p12 and p12b: path import and `helper.help()` |
| 3 | stands | p44 prints `1` then `2` |
| 4 | stands | p44; the alias repair also works (`alias44`: `import one/shapes as s1, two/shapes as s2` prints `1`/`2`) |
| 5 | stands | p44b `ambiguous identifier` at (3, 6) |
| 6 | stands | p18 `module init` before `main start` |
| 7 | stands | p18 import is line 3; order unchanged |
| 8 | stands | p01 `hello ada` |
| 9 | stands | echo1: `util.nim(1, 29) Error: undeclared identifier: 'echo'` |
| 10 | stands | p19 `undeclared identifier: 'shared'` |
| 11 | stands | p02 and p27 `undeclared identifier: 'secret'` |
| 12 | stands | p02, p27, p40: one line, no "declared here" line |
| 13 | stands | p28 `42` and `util`; p08c `9` |
| 14 | stands | p03 `p.y` prints, `p.x` refused |
| 15 | stands | p03 message names `Point` |
| 16 | stands | p04 `green` |
| 17 | stands | p24 `2`; p24b `x 0 y 2` |
| 18 | stands | p24b exit 0, no diagnostic |
| 19 | stands | p22 `hidden 5` |
| 20 | stands | p22b `undeclared identifier: Hidden` |
| 21 | stands | p17 `undeclared identifier: util` |
| 22 | stands | p06 `hello ada` twice, qualified and unqualified |
| 23 | stands | p07 `other` prints, `greet` undeclared |
| 24 | stands | p42 `hello ada`, exit 0 |
| 25 | stands | p05 `other` undeclared |
| 26 | stands | p27 same undeclared message |
| 27 | stands | p16 `util.greet` prints |
| 28 | stands | doc/language.md:1280-1314; qualifier, generic and container probes above |
| 29 | stands | p37 `thing 3` |
| 30 | stands | p37/p26c `banner` undeclared |
| 31 | stands | p38 `showA` undeclared |
| 32 | stands | p40 `hide` undeclared |
| 33 | stands | p39 `1` |
| 34 | stands | p10 `thing 3` |
| 35 | stands | p26c (it uses `export inner.Thing`, same shape) `show` builds, `banner` undeclared |
| 36 | stands | h3 rebuilt: `import shapes` + `export shapes` in `support/report.nim`, main prints `thing 7` |
| 37 | **corrected** | h1 exits 1; h2 spins at 100% CPU and grows memory; `export 3` reproduces it. Trigger is any non-name operand, not the path as such |
| 38 | stands | p09 and p43 print `8` |
| 39 | stands | p11a names `b.nim` and the missing pragma |
| 40 | stands | p11b exit 0 |
| 41 | stands | p13 both declarations with file and line |
| 42 | **corrected** | Direct writes refused (p08, p30, sync4); a stored `let` pointer escapes (sync3 prints `5`) |
| 43 | stands | p08c `9` |
| 44 | stands | p31 `2` |
| 45 | stands | p08b direct `inc` still refused; but an own `{.sync.}` var param works (sync1 `2`), so the paragraph after it changes |
| 46 | stands | p45 `2`; contracts_fir.nim:4108-4117, features.nim:57-61 |
| 47 | stands | p23 and p41; c1 prints `hello outside` with the enclosing proc never called |
| 48 | stands | p25 and h1 name the toolchain `src/lib` path |
| 49 | stands | nim2/n1: Nim 2.4.0 `undeclared identifier: 'show'`, exit 1 |
| 50 | stands | nim2/n2: `plain echo`, exit 0 |

### ERRATA rulings

1. **Documentation defect.** `doc/language.md:4646` says the import statement is only allowed at the top level; the pin accepts it inside a proc, applies it module-wide, and `sem.nim:5953` dispatches `ImportS` without the `toplevelGuard` used for calls and assignments. `c1` proves it works even when the proc is never called. The doc line is wrong; the compiler behaviour is coherent enough not to file as a defect.
2. **Compiler defect, reframed.** Not "a path in export": any non-identifier operand. Minimal repro `export 3`; `export support/shapes` is the realistic case. `nimsem` spins in `semExport` (`semimport.nim:411-414`) because `takeIdent` does not advance the cursor on a non-ident (`asthelpers.nim:27-45`) and `buildErr` (`semimport.nim:338-341`) accumulates forever. It is a runaway loop with unbounded allocation, not a passive hang. Fix: consume or skip the operand and emit one error.
3. **Message gap, low priority.** Unchanged: a missing module names only the toolchain's `src/lib` path (`p25`, `h1`), which sends the reader to the install directory.
4. **New candidate: the shared-global check is syntactic, not an alias analysis.** `let p* = addr counter` at module level followed by `p[] = 5` in a routine builds and writes the global (`sync3` prints `5`); `(addr counter)[]` is caught (`sync4`), so the boundary is the stored pointer, and `sharedRootPos` documents that a deref leaves the global (`contracts_fir.nim:4129-4139`). Either the check follows a `let` pointer to a `gvar` or the documentation says the check is syntactic. Not for the chapter to teach; the #42 wording covers it.

### Still unverified

- The design intent of import-in-proc: the behaviour is proven, the intent is not. The doc defect ruling does not need it.
- Your own untested list: `export` of a generic module's instances, `import "path"`, a `.nim` suffix, three-module cycles, one-sided `{.cyclic.}`, and `include` outside its directory. None of them is a claim in this chapter.
- Whether the `export` loop ever terminates on its own; I killed it at 20 s and 45 s.
