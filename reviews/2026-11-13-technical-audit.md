# Technical audit, 2026-11-13

Compiler-level truth and quoted-output fidelity for the whole book. Audited at repository HEAD `b645f97`, `VERSION`
`0.1.21`, pin `4ba90a781b0b22d0821efaa153c129c37cef6143` (`nimony 0.6.3`, `~/.local/opt/nimony/4ba90a7`). The
brief named `v0.1.18` / `63eeff8`. First pass at `773ace5` (`0.1.20`) found three failing blocks; this pass re-ran
them at `0.1.21`, where Chapters 7 and 24 were edited, and re-ran the citation and block checks against HEAD.

Verdict: at `0.1.21` no chapter carries a failing output block. No quoted diagnostic was found false, and every
chapter's full expected-output block matches a fresh run of its sample. The three FAILs from the `0.1.20` pass are
fixed in the text and were re-verified here by running the fixed blocks (Chapter 7 now prints `a`, `b`, `c` before
the assertion; Chapter 24's chain block declares `innerCont` and prints its five lines as printed; the two-worker
sketch is now the sample's own five lines). The two defects from the first pass (the `review.md` pointers in
Appendices A/B, and Chapter 23's unqualified `{.assert.}` sentence) remain fixed and were re-checked. Everything not
re-run is marked *open*, not cleared.

## What was re-run

```
$ bash tools/verify-samples.sh
SUMMARY 23/23 passed, 0 failed
```

- **Full expected-output blocks.** Twenty-one of the twenty-three chapters with a sample print one fenced block
  claiming to be the sample's complete output; all twenty-one match the fresh run byte-for-byte, blank lines
  included (Chapters 3 and 4 quote outputs as trailing `#` comments instead, see the table).
- **Other output blocks.** Every remaining block that claims program output was either matched against the sample
  run or rebuilt: the immediately preceding code block was compiled at the pin, and where the failing shape is
  described in prose rather than shown, the shape was reconstructed (12 reconstructions). Across the 159 chapter
  blocks and the 3 in Appendix B: **94 have a fresh run behind them, 65 stay open, 0 fail.** The open ones are
  shell sessions, NIF dumps, multi-file module cases or excerpts that need declarations made earlier in the
  chapter.
- **Transcripts.** Thirteen `$ nimony` transcripts executed from the repository root: **12 byte-exact**. The
  thirteenth is Chapter 2's `nimony c -r hello.nim`, which the chapter tells the reader to run in a scratch
  directory; run that way it prints `hello, world`, so the block is right and not reproducible from the root.
- **Citations.** 469 line-numbered citations across the book, resolved against the pin: **0 missing files, 0 line
  ranges outside the cited file**. Existence only; the sentence-to-line relationship was read only for the
  passages named below.
- **Diagnostics.** Sixteen distinct quoted `Error:`/`Warning:` strings re-compiled at the pin (Chapters 3, 4, 5, 6,
  10, 14, 15, 23, 24) plus the twelve reconstructions counted above. Every one reproduced its quoted text.

## Table A — quoted output, per chapter

`Full block` is the line of the block that claims the sample's complete output. The counts cover every fenced
output/transcript block in the chapter: matched against a fresh run or rebuilt, still open, and failing.

| Ch | Sample | Full block | Fresh run | Run / open / fail | Verdict |
| --- | --- | --- | --- | --- | --- |
| 1 | none | — | — | 0 / 0 / 0 | No fenced output block; prose only. Empty by design. |
| 2 | `hello.nim` | `en.md:139` | matches | 1 / 6 / 0 | Full block matches (`hello, world`). Other blocks are shell and build-log sessions, not program output; left open. |
| 3 | `values.nim` | none | sample runs | 2 / 2 / 0 | Outputs are diagnostics, not a full block: `invalid reassignment to 'let'` and `undeclared identifier: my_value` rebuilt and matched. `{.feature: "ignoreStyle".}` and the `ref`-no-default block left open (prose-described shapes). |
| 4 | `numbers.nim` | none | sample runs | 0 / 0 / 0 | No fenced output block; every quoted result is a trailing `#` comment in a code block. Not covered by this check, not cleared. |
| 5 | `strings.nim` | `en.md:325` | matches | 1 / 2 / 0 | Full block matches. The two leftovers are a shell transcript and a `let block = """…` code block the checker misclassified as output. |
| 6 | `branching.nim` | `en.md:393` | matches | 5 / 2 / 0 | Full block matches. Two `not all cases are covered` messages rebuilt and matched. |
| 7 | `loops.nim` | `en.md:378` | matches | 14 / 1 / 0 | Full block matches. Fixed in `0.1.21`: `en.md:143-150` now prints `a`, `b`, `c` after the abort line and says why the abort line comes first (re-run below). The block still elides the absolute path prefix and the driver's `FAILURE:` line, which Chapter 21 explains is the driver's line, not the program's. |
| 8 | `procedures.nim` | `en.md:396` | matches | 6 / 1 / 0 | Full block matches. `cannot pass 7 to var/out T parameter` rebuilt and matched. |
| 9 | `overloading.nim` | `en.md:362` | matches | 10 / 2 / 0 | Full block matches. The `[]=` rejection rebuilt and matched; the borrow rejection at `:291` matched on re-run. |
| 10 | `collections.nim` | `en.md:655` | matches | 29 / 5 / 0 | Full block matches. Every array/seq/tuple diagnostic in the chapter that could be rebuilt matched; five NIF/candidate-list blocks open. |
| 11 | `objects.nim` | `en.md:341` | matches | 1 / 2 / 0 | Full block matches. Enum-out-of-range and object-equality blocks are prose-described probes; open. |
| 12 | `sumtypes.nim` | `en.md:328` | matches | 3 / 3 / 0 | Full block matches. `selector must be of an ordinal type` and the clean `not all cases` line rebuilt and matched; wrapped-AST and multi-file variants open. |
| 13 | `refs.nim` | `en.md:292` | matches | 2 / 0 / 0 | Full block matches. The no-default-value message rebuilt and matched. |
| 14 | `ownership.nim` | `en.md:324` | matches | 2 / 2 / 0 | Full block matches. `mutable argument aliases…` matched on re-run; two borrowed-value blocks open. |
| 15 | `errors.nim` | `en.md:312` | matches | 1 / 3 / 0 | Full block matches. Three error-message blocks need multi-routine context; open. |
| 16 | `modules.nim` | `en.md:329` | matches | 1 / 3 / 0 | Full block matches. Import-cycle, `secret` visibility and shared-global blocks need two modules; open. |
| 17 | `generics.nim` | `en.md:308` | matches | 2 / 1 / 0 | Full block matches. `undeclared field: 'nonexistent' for type T` rebuilt and matched; the instantiation trace is open. |
| 18 | `templates.nim` | `en.md:293` | matches | 3 / 0 / 0 | Full block matches. The template type-mismatch trace and `cannot evaluate … len(Table)` rebuilt and matched. |
| 19 | `plugins.nim` | `en.md:293` | matches | 1 / 12 / 0 | Full block matches. Twelve NIF/plugin blocks are not one-command checks; open, not cleared. |
| 20 | `stdlib.nim` | `en.md:301` | matches | 1 / 1 / 0 | Full block matches (26 lines). The `$-` shell probe is open. |
| 21 | `files.nim` | `en.md:233` | matches | 1 / 1 / 0 | Full block matches (16 lines). File-system side effects are not re-run by this check; open. |
| 22 | `cinterop.nim` | `en.md:253` | matches | 1 / 1 / 0 | Full block matches. The clang callback block is open (host toolchain and `qsort` ABI). |
| 23 | `testing.nim` | `en.md:291` | matches | 4 / 3 / 0 | Full block matches. `[Assertion Failure] got 2`, the `when`/`{.error.}` line and `FAILURE:` after `quit 3` rebuilt and matched. |
| 24 | `passive.nim` | `en.md:359` | matches | 4 / 8 / 0 | Full block matches. Fixed in `0.1.21`: the chain block at `en.md:228-250` declares `var innerCont: Continuation` and prints its five lines in the order shown (re-run below); the two-worker sketch at `en.md:193-199` is now the sample's own five lines with the sample's output. Copying the chain block alone still needs the module-level `assumeSync` rule taught later in the chapter, which the prose names at `en.md:226`. |
| A2 | — | — | — | 0 / 3 / 0 | Appendix B quotes three shell sessions (`task verify`, toolchain line); not program output, open. |

### Fixed in `0.1.21`, re-verified

**`chapters/07-loops-ranges/en.md:143-150`** — the block now shows the abort line and the three lines the program
printed before it, and the prose says why the abort line comes first. Fresh run of the chapter's own shape
(`let word = "abc"`, `for i in 0..len(word): echo word[i]`) at the pin:

```
…/lib/std/system/stringimpl.nim(686, 37): i < len(s) [AssertionDefect]
a
b
c
FAILURE: nimcache/c/craebhlm8/crash
```

The block keeps `a`, `b`, `c` in that order after the abort line; the absolute path prefix and the driver's
trailing `FAILURE:` line are elided, which the book does throughout.

**`chapters/24-passive-procs/en.md:228-250`** — the chain block now declares `var innerCont: Continuation`. Built
with the chapter's own `{.feature: "assumeSync".}` rule and the sample's `drive`, it prints exactly the block:

```
outer 1
inner 1
outer parked
inner 2
outer 2
```

Without the feature line the compiler rejects the module-level write (`unsynchronized access to global variable
'innerCont'`), which is the module-level rule the chapter teaches at `en.md:330` and points to at `en.md:226`.

**`chapters/24-passive-procs/en.md:193-199`** — the two-worker sketch is now the sample's own last five lines; the
sample run prints `worker b start` / `worker c start` / `both parked` / `worker b end` / `worker c end`, which is
the block's output.

## Table B — contradiction sweep, per chapter

Method: every ERRATA row was tied to the chapter it names and its chapter-side statement was located in the frozen
text by the row's distinctive terms; the six rows whose terms do not appear verbatim in the chapter were read by
hand. This finds textual drift from the rulings, not a fresh semantic review of claims that already have a ruling
(those were re-proved in the chapter reviews).

| Ch | ERRATA rows | Conflict |
| --- | --- | --- |
| 1 | 2 | None. |
| 2 | 3 | None. The new `23/23` sentence and the `0 failed` reading are present; Chapters 11–12 still print their own `10/10` and `11/11`, which the row allows. |
| 3 | 2 | None. |
| 4 | 2 | None. |
| 5 | 4 | None. The chapter never claims Nimony lacks Unicode iteration; the `std/unicode` row is satisfied. |
| 6 | 3 | None. The message is quoted verbatim and the `else` rule is stated. |
| 7 | 4 | None against ERRATA; the output-elision defect above is not an ERRATA row. |
| 8 | 5 | None. |
| 9 | 3 | None. |
| 10 | 3 | None. Teaches growth by loop; no sequence concatenation. |
| 11 | 3 | None. Enum bounds and object equality match their rulings. |
| 12 | 5 | None. |
| 13 | 4 | None. |
| 14 | 4 | None. |
| 15 | 3 | None. |
| 16 | 4 | None. |
| 17 | 4 | None. |
| 18 | 4 | None. |
| 19 | 6 | None. |
| 20 | 3 | None. `getOrQuit` is described as "after an `assert`", as the row requires. |
| 21 | 4 | None. |
| 22 | 3 | None. |
| 23 | 4 | None. The edited `{.assert.}` sentence now says the claim must be provable, which is the row's ruling; `doAssert` and `.sync` rows still hold. |
| 24 | 4 | None. The `delay()` watch row still describes the chapter correctly: the pin asserts, the chapter quotes it. |

## Findings

1. **Fixed in `0.1.21`: Chapter 7 dropped three printed lines — medium.** `en.md:143-150` now shows `a`, `b`, `c`
   and explains the order; re-run above. `id.md` carries the same fix.
2. **Fixed in `0.1.21`: Chapter 24's chain block could not be built — medium.** `en.md:228-250` declares
   `var innerCont: Continuation` and prints as written; re-run above.
3. **Fixed in `0.1.21`: Chapter 24's two-worker sketch was not self-contained — low-medium.** It is now the
   sample's own five lines with the sample's output.
4. **Fixed in `0.1.20`: Appendix A/B promised a `review.md` that 7 chapters did not have.** Verified at HEAD: 24
   `chapters/*/review.md` exist, `a1/en.md:28` and `a2/en.md:141` now resolve.
5. **Fixed in `0.1.20`: Chapter 23 said `{.assert.}` as a statement is accepted without saying it must be
   provable.** `en.md:176` now carries the condition and the `half.nim(4, 5)` message is unchanged.
6. **Watch row stands: `cps.nim:269` is still a compiler assert at the pin.** Reproduced today; fix is
   `nim-lang/nimony#2988`, open and unmerged, so the book's pin is unchanged.

## Not proven by this audit

- **65 output blocks stay open; none fail.** Shell sessions, build logs, NIF dumps, multi-file module cases, and
  excerpts that depend on declarations made earlier in the chapter. Each is listed by chapter in Table A; none is
  cleared. The citation and block checks were re-run at `0.1.21`: still 469 line-numbered citations, 0 missing
  files and 0 ranges out of bounds.
- **Chapter 4's outputs are inline `#` comments**, not fenced blocks; this audit did not run those comments as
  assertions.
- **The 469 citations were checked for existence and bounds, not read.** A range can be in bounds and still have
  drifted from the sentence it supports; only the passages named in the tables were read.
- **The per-chapter probe tables inside the 24 `review.md` files were not re-executed.**
- **Nim 2.4.0 columns of the delta table were not re-measured**; this audit ran the pin only.

## Artifacts

Scripts behind the numbers, outside the repository:
`~/.openmausbot/workspaces/49df9f87-8857-46c0-b9b8-8f066a10a55e/audit-blocks.py` (block classification and sample
match), `audit-snippets2.py` (snippet re-run), `audit-probes2.py` (twelve reconstructions), `audit-citations2.py`
(citation resolution), `audit-transcripts.py`, plus the JSON outputs next to them.
