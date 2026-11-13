# Chapter 23 review note — Testing and the Sample Verifier

Status: `drafting`. Reviewer: **Momo**. This note is the claim table, the open questions and the errata
candidates. Append your verdict at end of file; do not edit the table rows in place.

Pin for every run below: `4ba90a781b0b22d0821efaa153c129c37cef6143` (nimony 0.6.3), install
`~/.local/opt/nimony/4ba90a7`. Probe sources: `ch23-probes/` in the authoring workspace
(`probes/ch23/`), one directory per
probe, each run as `~/.local/opt/nimony/4ba90a7/bin/nimony c -r main.nim` from inside the probe directory. Probes
about exit codes were then run as the compiled binary `nimcache/c/<hash>/main`, because `nimony c -r` does not
forward the child's code (claim 15). Host comparisons are not used in this chapter: every claim here is about
the pin's own testing surface.

Verifier already run by the editor, from the authoring folder:

```
toolchain ~/.local/opt/nimony/4ba90a7/bin/nimony 0.6.3 pin 4ba90a7
PASS samples/23-testing/testing.nim exit=0
SUMMARY 22/22 passed, 0 failed
```

Sample output, byte-identical to the block in `en.md` section Samples (4 lines):

```
ok - double of 4
ok - length of hello
ok - empty string
3 checks, 0 failed
```

## Claims

| # | Section | Claim as written | Probe | Raw output | Source |
| --- | --- | --- | --- | --- | --- |
| 1 | chapter frame | `assert` is not in `system`; it needs `std/assertions` | `a01` | `main.nim(2, 1) Error: undeclared identifier: 'assert'`, twice | `lib/std/assertions.nim:23` is the only definition; `lib/std/system.nim` declares no `assert` |
| 2 | chapter frame | `std/unittest` does not exist at the pin | `a09` | `main.nim(1, 1) Error: file not found: …/src/lib/std/unittest.nim` | `lib/std/` listing has no `unittest.nim` |
| 3 | chapter frame | `doAssert` is not declared | `a16` | `main.nim(2, 1) Error: undeclared identifier: 'doAssert'` | no definition in `lib/std` |
| 4 | `assert` | `assertionsEnabled` is `not defined(danger) and not defined(noAssertions)` | `d03` under four flag sets | `true`, `true`, `false`, `false` | `lib/std/assertions.nim:3` |
| 5 | `assert` | a passing assertion prints nothing | `b01` | `survived` only | `lib/std/assertions.nim:23-31` |
| 6 | `assert` | a failing assertion prints `[Assertion Failure] ` plus the message on stdout and exits 1 | `b02` | `[Assertion Failure] got 2`; binary exit `1`; stderr empty | `lib/std/assertions.nim:11-13` (`echo` then `quit 1`) |
| 7 | `assert` | with no message the line ends after the trailing space | `b03` | `[Assertion Failure] ` (nothing after) | `lib/std/assertions.nim:11` |
| 8 | `assert` | `assert` is usable inside a `func` | `b07` | `7` | `lib/std/assertions.nim:15-22` (`{.cast(noSideEffect).}` inside `failedAssertImpl`) |
| 9 | harness | a mutable module-level `var` touched inside a proc is refused unless the routine is `.sync` or the access is in a pragma block | `b10` | `Error: unsynchronized access to global variable 'checks'; pass it to a '.sync' routine or use '{.cast(assumeSync).}'` (and the same for `failures`) | `src/nimony/contracts_fir.nim:4120-4127` |
| 10 | harness | the escape that works inside a proc is the block `{.cast(assumeSync).}:` | `d01` | `ok - addition` then `1 0` | `src/nimony/sempragmas.nim:544-550` |
| 11 | harness | putting `{.cast(assumeSync).}` on the variable declaration is refused | `c03` | `main.nim(3, 19) Error: too many arguments for pragma` (and `(4, 21)`) | `src/nimony/sempragmas.nim:1008` lists the accepted `cast` arguments |
| 12 | harness | `{.feature: "assumeSync".}` at module level also permits the mutation | `g01` | `1` | `src/nimony/models/programs.nim:9` uses it on the compiler's own globals; `src/nimony/sempragmas.nim:750` trusts the module's globals |
| 13 | harness | passing the counters as `var int` parameters works and keeps the routine honest | `c02` | `ok - addition` / `not ok - subtraction` / `2 checks, 1 failed`, exit `1` | probe |
| 14 | harness | `quit(if failures == 0: 0 else: 1)` compiles at module level | `c01` | `2 checks, 1 failed`; binary exit `1` | probe |
| 15 | running | `nimony c -r` exits 1 and prints a `FAILURE:` line naming the binary for any non-zero child exit; it does not forward the code | `e01` | child `quit 3` → `before` / `FAILURE: nimcache/c/mai3r4ykk/main`, driver exit `1` | driver output; no flag found that forwards |
| 16 | running | the same binary run directly returns the child's code | `e01` binary | `3` | probe |
| 17 | running | a passing program under `nimony c -r` exits 0 and prints only its own output | `e03` | `fine`, exit `0` | probe |
| 18 | flags | `-d:danger` and `-d:noAssertions` compile assertions out; `-d:release` keeps them | `b03` with three flag sets | none: `[Assertion Failure] ` exit 1; `-d:release`: same; `-d:danger`: continues, exit 0; `-d:noAssertions`: continues, exit 0 | `lib/std/assertions.nim:3`, `:23-31` |
| 19 | flags | hand-written checks survive `-d:danger` because only `assert` disappears | `h01` (the chapter sample with `-d:danger`) | the same four lines, exit `0` | probe |
| 20 | compile time | `static:` is not a statement the compiler accepts | `a07` | `main.nim(2, 1) Error: unsupported statement: staticstmt` | `src/nimony/sem.nim:5873` |
| 21 | compile time | `when` plus `{.error.}` stops the build with the message and a position | `b09` | `main.nim(3, 5) Error: arithmetic broke`, exit 1 | `src/nimony/sem.nim` pragma-error path |
| 22 | compile time | `{.assert: cond.}` — the pragma the manual documents — crashes the compiler | `a10` | `assertions.nim(38) raiseAssert` then `Error: unhandled exception: nifcore.nim(1875, 3) 'b.openTags.len > 0' closeTag with no matching openTag [AssertionDefect]` | `doc/language.md:3237-3264`, `:3251`; `src/nimony/contracts_fir.nim:5908` |
| 23 | compile time | a type error inside `assert` is reported through the template, naming `assertions.nim` | `g04` | `main.nim(2, 1) Error: Type mismatch at [position]` then the source line then `[1] expected: bool but got: int64 (declared in …/lib/std/assertions.nim(23, 1))` | `lib/std/assertions.nim:23` |
| 24 | verifier | the verifier globs `samples/*/*.nim`; zero matches is a SKIP with exit 0 | script read, chapter run | `SUMMARY 22/22 passed, 0 failed` | `tools/verify-samples.sh:16-17` (`nullglob`), `:55-59` |
| 25 | verifier | it refuses a wrong toolchain version or commit with exit 2 | script read | not triggered (toolchain correct) | `tools/verify-samples.sh:27-52` |
| 26 | verifier | each sample runs from the repository root, and every transcript goes to `tools/verify-samples.log` with the exit code in the header | script read | log inspected after the run | `tools/verify-samples.sh:67-74` |
| 27 | verifier | the script prints `PASS`/`FAIL` per file, a `SUMMARY` line, and its exit status is the last test | script read, chapter run | `PASS samples/23-testing/testing.nim exit=0`; `SUMMARY 22/22 passed, 0 failed` | `tools/verify-samples.sh:76-88` |
| 28 | verifier | CI runs the same gate as `./task check`, in a job limited to fifteen minutes | workflow read | — | `.github/workflows/ci.yml:21`, `:77` |
| 29 | Samples | the chapter sample compiles, prints four lines and exits 0 | chapter run | the four lines above, `exit=0` | `samples/23-testing/testing.nim` |
| 30 | Samples | the sample avoids external files, so the verifier can run it from the root | sample read | — | `samples/23-testing/testing.nim` uses only strings and a `func` |

## Questions

**A.** Is `assert` being out of `system` and only in `std/assertions` deliberate at this pin, or an import-path
accident? The chapter teaches the import; if the module is meant to be re-exported later, the text still stands
for now, but I would like the intent on record.

**B.** `{.assert: cond.}` is documented at `doc/language.md:3237-3264` as the claim the compiler must prove, and
at the pin it kills the sem process with an internal `nifcore` assertion (`a10`, trivial body:
`proc half(x: int): int {.assert: x mod 2 == 0.} = x div 2`). Compiler defect to file, or is there a supported
shape of the pragma the chapter should show instead?

**C.** The unsynchronized-global rule fires in a single-threaded program with no threads in it, and its message
offers `{.cast(assumeSync).}` in a form that the compiler then refuses on a `var` declaration (`c03`,
"too many arguments for pragma"). Is the block form the intended one and the message just loose, and would
`{.sync.}` on the harness proc be the shape Engineering prefers over either?

**D.** `nimony c -r` turns any non-zero child exit into exit `1` and prints `FAILURE: <path>`; the binary keeps
the real code (`e01`: `3`). Intended driver behaviour, and is the `nimcache/c/<hash>/main` path stable enough for
the book to print it?

**E.** `static:` is refused as `unsupported statement: staticstmt` (`a07`). Is `when` plus `{.error.}` the
supported compile-time check at this pin, or is there another door (a `{.assert.}`-like pragma that does work, a
`const` fold that fails the build) the chapter should teach instead?

**F.** `-d:release` keeps assertions while `-d:danger` and `-d:noAssertions` remove them; the comment at
`lib/std/assertions.nim:3` states that convention explicitly. Is that comment authoritative for the pin (it is
what the probes show), and does the book's verifier deliberately run with no flags?

**G.** The same message gap as C, seen from the reader's side: is there any flag or invocation that makes
`nimony c -r` forward the child's exit code, or should the chapter always point at the compiled binary when a
test distinguishes failure kinds?

**H.** `std/assertions` also ships `assertRc` and `assertRcAlive` for ref-count tracking (`:41-72`). Are those
supported surface worth one sentence in this chapter, or compiler-internal diagnostics the book should leave
alone? I have not probed them, so the chapter does not mention them.

## ERRATA candidates

1. **`doAssert` in the manual's examples.** `doc/language.md:1446-1447` uses `doAssert which(1) == "local-int"`
   as the demonstration for name resolution; `doAssert` is undeclared at the pin (`a16`). Low priority: the
   example's point survives with `assert` plus an import, but as printed it does not compile.
2. **`{.assert: cond.}` documented as supported, crashing sem.** `doc/language.md:3237-3264` describes the pragma
   and shows it inside a routine; at the pin any use kills sem with the `nifcore` assertion (`a10`). This reads
   as a compiler defect rather than an errata row, but the manual is the reason a reader will try it, so it
   belongs on the list either way.
3. **Message gap, unsynchronized globals.** The error at `contracts_fir.nim:4125` suggests
   `{.cast(assumeSync).}`, which is only valid as a block (`sempragmas.nim:550`, `:1008`); the same text on a
   `var` declaration is `too many arguments for pragma` (`c03`). Low priority, and the fix is one clause in the
   message.
4. **Watch row — `nimony c -r` flattens exit codes.** Not a defect: the driver reports "the program failed" with
   the binary path, and the binary reports why. The chapter states it and shows the workaround rather than
   filing it.

## Notes for the editor

- The chapter's spine is claim 1: an import that Nim 2 readers will not expect. Every code block in the body
  needs `std / [assertions]` in its import line, and the first one should be the failing one, not the passing
  one, so the error is the lesson.
- Claims 9-12 are one paragraph each in `en.md`; if Momo rules the block form is the recommended shape, the
  `var`-parameter harness stays as the sample and the block stays as the explanation.
- `a10` is the only compiler crash in the probe set. If it is filed, the repro is four lines and the chapter
  cites it as a defect once, without teaching the pragma.
- Sample verified: 4 lines, byte-identical; verifier `22/22`. No sample change after the first run except
  replacing a `(1..3).len` check that the pin refuses with `undeclared field: 'len' for type HSlice[int64,int64]`
  — noted in the transcript, not in the text.
- No other chapter was opened.

## Verdict — 2026-11-13

Reviewer: **Momo**. I re-ran every probe directory in `ch23-probes/` myself at pin `4ba90a7`
(`~/.local/opt/nimony/4ba90a7/bin/nimony c -r main.nim`; exit codes read from the compiled
`nimcache/c/<hash>/main` where the claim is about the code), plus my own `v1`–`v7` (the `{.assert.}` positions),
`s1`–`s5` (the `.sync` shapes), `st1` (`static: echo 1`), `e42` (`quit 42`) and the chapter sample under
`-d:danger`. Verifier re-run by me from the authoring folder: `SUMMARY 23/23 passed, 0 failed`, exit 0; the
sample's four lines are byte-identical to the block at `en.md:280-283` (`diff` empty).

**Verdict: 24 claims stand as written; four stand with a citation, probe reference or table cell fixed (12, 18,
19, 28); two change the text (9, 22); zero open.**

The two that change a paragraph:

- **9 is wrong about `{.sync.}`.** A routine declared `{.sync.}` that does `inc checks` directly is refused
  with the same error (`s1`). What the message means is passing the global to a `var`/`ptr` parameter of a
  `.sync` routine; that compiles (`s2`, and `s5` is the `ptr` form). The `{.cast(assumeSync).}:` block (`d01`) is
  the direct-access escape.
  The sample's var-parameter harness is the right shape; only the sentence and the delta line need fixing.
- **22 is wrong about `{.assert.}`.** The documented form is a statement inside a body
  (`doc/language.md:3235-3237`), and it works: the pin's own `tests/nimony/contracts/tassertpragma.nim` passes,
  and `tests/nimony/errmsgs/tassertpragma.msgs` expects exactly the three diagnostics (`v4`, `v2`). The crash is
  only the pragma in **routine-pragma position** (`proc half(x: int): int {.assert: x mod 2 == 0.}`, `v1`/`v7`,
  with or without `{.feature: "staticContracts".}`). That is a compiler defect to file, not the documented shape
  and not an errata row against the manual.

### Answers A-H

**A. The split is the pin's design, not an import-path accident.** `lib/std/system.nim:1-8` includes only
`system/basic_types` and declares types/magics; `assert` is an exported template in
`lib/std/assertions.nim:23`, and no module re-exports it; the stdlib's own modules import it explicitly
(`lib/std/strutils.nim:11`, `lib/std/json.nim:42`). The pin makes no promise of a future re-export; the chapter
should teach the import and not predict one.

**B. The supported shape exists: a statement inside a body.** `{.assert: cond.}` is judged at compile time and
works in the documented position under a guard (`v2`, `v4`; `tests/nimony/contracts/tassertpragma.nim` exits 0,
`tests/nimony/errmsgs/tassertpragma.msgs` matches exactly). The crash is the pragma attached to a **routine
declaration**, including with a constant `true` and with `{.feature: "staticContracts".}` (`v1`, `v7`). File it
as a compiler defect with the four-line repro
(`import std/assertions`; `proc half(x: int): int {.assert: x mod 2 == 0.} = x div 2`; `echo half(4)`;
`echo half(3)`) and the `nifcore.nim(1875, 3)` assertion. ERRATA 2 is dropped as a documentation errata; the
manual says "Inside a body" (`:3235`), so it does not document the crashing position.

**C. The block is the intended direct-access escape; `{.sync.}` on the harness proc is not a substitute.**
`proc bump() {.sync.} = inc checks` is refused (`s1`). The message's `.sync` half is accurate once read as
"pass the global to a `.sync` routine": `proc bump(x: var int) {.sync.} = inc x` called from another proc
compiles (`s2`), and the `ptr` form is `s5`. A non-`.sync` `var` parameter is still refused (`s4`). The preferred
harness shape stays the var parameters, because it keeps the mutation explicit.
ERRATA 3 stays low: add the word "block" to the `{.cast(assumeSync).}` clause in the message.

**D. Flattening is by construction, not a flag.** `-r` only sets `doRun` (`src/nimony/nimony.nim:284-287`), the
run goes through `exec` (`src/nimony/deps.nim:2772`), and `exec` does `execShellCmd` then
`quit("FAILURE: " & cmd)` on non-zero (`src/nimony/semos.nim:175-176`) — a string `quit` is exit 1
(`lib/std/syncio.nim:547-549`). There is no forwarding flag. The path is `nimcache/c/<moduleSuffix>/main`, where
`moduleSuffix` is the first three characters of the module name plus base36 `uhash` of the path relative to the
CWD or a search path (`src/gear2/modnames.nim:15`, `:45-82`): deterministic for one invocation, not across
working directories. Print the pattern and glob `nimcache/c/*/main` in a script; do not hardcode the hash.

**E. `static:` is unimplemented; `when` plus `{.error.}` is the module-level gate, and `{.assert.}` is the
other door inside a body.** `StaticstmtS` is grouped with `ImportasS` and `AsmS` (`src/nimony/sem.nim:5871-5873`);
any body fails (`st1`). `when` plus `{.error.}` is the statement-level path (`src/nimony/sempragmas.nim:1306-1312`,
`b09`). `{.assert: cond.}` works as a statement inside a guarded body (`v2`, `v4`, the contract tests), but not at
module top level (`v6` gives `expected bool but got: auto`) and not as a routine pragma (`v7` crashes). Teach both,
for different jobs: `when` for a build gate, `{.assert.}` for a proof obligation a guard carries.

**F. The comment is authoritative for the pin's behaviour, and the probes match it.**
`assertionsEnabled = not defined(danger) and not defined(noAssertions)` (`lib/std/assertions.nim:3-9`);
`-d:release` only raises the optimisation level while keeping runtime checks
(`src/nimony/nimony.nim:264-271`). The verifier runs with no flags (`tools/verify-samples.sh:67`), so it always
tests the assertion-enabled build.

**G. No flag forwards the child's code.** `-r` is a boolean, the run goes through `exec`, and a non-zero child is
`quit "FAILURE: …"` → 1 (`src/nimony/nimony.nim:284-287`, `src/nimony/deps.nim:2772`,
`src/nimony/semos.nim:175-176`). The binary keeps the real code (`e01` 3, `e42` 42). Point at the binary when the
kind of failure matters; the chapter's advice is right.

**H. Leave `assertRc`/`assertRcAlive` alone.** They are exported ARC diagnostics that read the ref-count header
at offset 0 (`lib/std/assertions.nim:38-72`); no compiler source outside the module uses them, and their contract
is the runtime layout, not the testing surface. One sentence would be a promise the chapter cannot keep; if ARC
gets a chapter, they belong there. No probe, no text.

### Claim verdicts

| # | Verdict |
| --- | --- |
| 1 | Stands — `a01`; `lib/std/assertions.nim:23` is the only definition and `system.nim` has only a comment at `:550`. |
| 2 | Stands — `a09`; `lib/std/` has no `unittest.nim`. |
| 3 | Stands — `a16`. |
| 4 | Stands — `:3`; `d03` prints `true`, `true`, `false`, `false`. |
| 5 | Stands — `b01` prints `survived` only. |
| 6 | Stands — `b02`; stdout `[Assertion Failure] got 2`, stderr empty, exit 1. |
| 7 | Stands — `b03`; `od -c` shows `] \n`, so the trailing space is real. |
| 8 | Stands — `b07` prints 7; `:15-22`. |
| 9 | **Narrow** — the refusal stands (`b10`), but `{.sync.}` on the routine does not permit direct access (`s1`); the route is a `var`/`ptr` parameter of a `.sync` routine (`s2`, `s5`). The sample's var-parameter `check` needs no `.sync.` because the driver calls it at module level, where the check does not fire. Fix `en.md:105-107` and `:262`. |
| 10 | Stands — `d01`; `sempragmas.nim:544-550`. |
| 11 | Stands — `c03`; the accepted cast arguments are `sempragmas.nim:1000-1009`. |
| 12 | Stands — `g01`; **citation path is `src/nimony/programs.nim:9`, not `src/nimony/models/programs.nim:9`**. |
| 13 | Stands — `c02`, exit 1. |
| 14 | Stands — `c01`. |
| 15 | Stands — `e01` (`quit 3`), my `e42` (`quit 42`); driver 1, `FAILURE: nimcache/c/mai3r4ykk/main`. |
| 16 | Stands — `e01` binary 3, `e42` binary 42. |
| 17 | Stands — `e03`, `fine`, exit 0. |
| 18 | Stands — `-d:release` fails, `-d:danger`/`-d:noAssertions` continue at 0; **but the `en.md` table at `:193-194` says "nothing", while `b03` prints `not reached`** — change the cell or the probe. |
| 19 | Stands — the sample with `-d:danger` prints the same four lines, exit 0; **`h01` does not exist in `ch23-probes/`**, cite the sample run instead. |
| 20 | Stands — `a07`; `static: echo 1` fails the same way (`st1`), so "any body" is right. |
| 21 | Stands — `b09`; the statement-level path is `sempragmas.nim:1306-1312` (more precise than the table's `sem.nim`). |
| 22 | **Wrong as stated** — the documented statement form works (`v2`, `v4`, `tests/nimony/contracts/tassertpragma.nim`); only routine-pragma position crashes (`v1`, `v7`). Rewrite `en.md:172-176`; drop ERRATA 2. |
| 23 | Stands — `g04`, exact. |
| 24 | Stands — `tools/verify-samples.sh:55-58`. |
| 25 | Stands — `:33-52`, exit 2 on version and commit. |
| 26 | Stands — `:67` runs from `$ROOT`; `:70-74` writes the header. |
| 27 | Stands — `:77`, `:87`, `:88`. |
| 28 | Stands — `timeout-minutes: 15` at `ci.yml:21`; **`./task check` is `:73`, not `:77`**. |
| 29 | Stands — verifier PASS; four lines byte-identical (`diff` empty). |
| 30 | Stands — the sample uses only strings and a `func`. |

### ERRATA

1. **Keep, low — `doAssert` in the manual.** `doc/language.md:1446-1447` uses `doAssert` as the name-resolution
   demonstration; it is undeclared at the pin (`a16`). Documentation defect, not a chapter break.
2. **Drop.** The documented `{.assert: cond.}` shape works (B). The routine-pragma crash is a compiler defect to
   file, not a documentation errata; keep it in the watch list and let the chapter name the position once.
3. **Keep, low — message gap.** The `.sync` clause is accurate but terse (`s1`/`s2`); the
   `{.cast(assumeSync).}` clause should say "block". One clause in the message.
4. **Keep, reframed — flattening is intended by construction.** `exec` calls `quit "FAILURE: …"` → 1; no flag
   controls it. The chapter's workaround is the documented route, not a defect.

### Watch rows

- **Routine-pragma `{.assert.}` crash.** Compiler defect to file; four-line repro above. The book teaches the
  statement form and may name the crash once.
- **`static:` unsupported.** Known, `sem.nim:5871-5873`; re-check before any chapter leans on it.
- **`nimcache` path hash.** `moduleSuffix` hashes the path relative to the CWD or a search path; print the
  pattern and glob in scripts, never hardcode the hash.
- **`{.sync.}` message ambiguity.** Low; the `.sync` half is right, the `{.cast(assumeSync).}` half needs "block".
- **`{.assert.}` at module top level.** Not a module pragma (`v6`: `expected bool but got: auto`); keep the
  statement-form rule.

### What to change in `en.md`

1. `en.md:105-107` — replace "unless the routine is declared `{.sync.}`" with the var/ptr-parameter route and the
   block, and say why the sample's `check` needs no `.sync.`: its driver is module-level, where the check does not
   fire. Keep var parameters as the taught shape.
2. `en.md:121-133` — after the block, add one clause that the `.sync` half of the message means passing the global
   to a `.sync` routine, not declaring the harness `.sync`.
3. `en.md:172-176` — rewrite: `{.assert.}` is a statement inside a body; it works; the routine-pragma position is
   the crash, a defect to file.
4. `en.md:189-194` — the `-d:danger` and `-d:noAssertions` rows print `not reached` with `b03`; if "nothing" is
   wanted, use a probe with no trailing `echo`.
5. `en.md:223-226` — the hash comes from the module path, not just the module; glob in a script.
6. `en.md:247` — CI citation is `:73`, not `:77`.
7. `en.md:262` — Nim 2 delta: the `.sync` route is a var/ptr parameter.
8. `OUTLINE.md:300` — narrow "crashes sem" to routine-pragma position; the statement form works.
9. `ERRATA.md:26` — the Chapter 23 `unittest` watch row can be closed as proven absent (`a09`) when the chapter
   freezes.
10. `GLOSSARY.md` `sample verifier` — the evidence line says `SUMMARY 22/22`; my run is 23/23 because Chapter 24's
    sample is now in the tree. Update the number at freeze.

Claims open: none. `en.md`, `id.md` and `samples/` were not touched; no other chapter was opened.

## Addendum — 2026-11-13, after the whole-book audit

Reason B above is right about the position and too generous about acceptance: `{.assert: cond.}` in a body is
accepted only when the prover discharges the claim. Re-run by Momo at the pin
(`reviews/2026-11-13-technical-audit.md`, finding 2): `proc half(x: int): int = {.assert: x mod 2 == 0.}` called
with `4` stops the build at `half.nim(4, 5) Error: cannot prove assertion: x mod 2 == 0`. The chapter text said
"accepted" and cited the test without saying why the test's assertions hold, so a reader copying the sentence met
a hard compile error. One sentence added to `en.md` and `id.md` (§Checks that run at compile time), and the
correction is recorded in `ERRATA.md` under open errata. The claim table is unchanged; the guard in `v2`/`v4` is
what makes the statement form work.
