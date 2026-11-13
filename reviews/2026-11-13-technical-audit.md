# Technical audit, 2026-11-13

Compiler-level truth and quoted-output fidelity for the whole book. Audited at repository HEAD `773ace5`, `VERSION`
`0.1.20`, pin `4ba90a781b0b22d0821efaa153c129c37cef6143` (`nimony 0.6.3`, `~/.local/opt/nimony/4ba90a7`). The
brief named `v0.1.18` / `63eeff8`; `git diff 63eeff8..HEAD -- 'chapters/*/en.md'` touches one file (Chapter 23, nine
lines), so every check below was re-run at HEAD rather than carried over.

Verdict: no quoted diagnostic was found false, and every chapter's full expected-output block matches a fresh run
of its sample. Three blocks do not survive the page: Chapter 7's crash block silently drops the three lines the
program prints before the assertion, and two Chapter 24 blocks cannot be built as printed (`innerCont` is never
declared; the two-worker sketch uses names that exist only in the sample). Those three are FAILs below, with the
observed output. The two defects from the first pass (the `review.md` pointers in Appendices A/B, and Chapter 23's
unqualified `{.assert.}` sentence) are fixed in `0.1.20` and verified fixed here. Everything not re-run is marked
*open*, not cleared.

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
  blocks and the 3 in Appendix B: **91 have a fresh run behind them, 65 stay open, 3 fail.** The open ones are
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
| 7 | `loops.nim` | `en.md:378` | matches | 13 / 1 / 1 | **FAIL** at `en.md:143-145`: the block shows only the assertion line, but the program prints `a`, `b`, `c` first (observed below). The rest matched. |
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
| 24 | `passive.nim` | `en.md:359` | matches | 2 / 8 / 2 | **FAIL** `en.md:226-250`: `innerCont` is never declared, run stops at `Error: undeclared identifier: innerCont`; **FAIL** `en.md:188-205`: sketch uses `worker`, `resumeA`, `resumeB` (and `drive`) that exist only in the sample. |
| A2 | — | — | — | 0 / 3 / 0 | Appendix B quotes three shell sessions (`task verify`, toolchain line); not program output, open. |

### FAIL evidence

**`chapters/07-loops-ranges/en.md:143-145`** — the block presents the crash as its own output:

```
…/stringimpl.nim(686, 37): i < len(s) [AssertionDefect]
```

Observed from the chapter's own program (`for i in 0..len(word): echo word[i]` over `"abc"`):

```
…/lib/std/system/stringimpl.nim(686, 37): i < len(s) [AssertionDefect]
a
b
c
FAILURE: nimcache/c/mai3r4ykk/main
```

Three printed lines are silently dropped. The prose says "builds and then dies", not "ends with"; the block has to
say it elides, or show the three lines. Same defect in `id.md` (Raka's `2026-11-13-code-block-coverage.md`, id.md:139-145).

**`chapters/24-passive-procs/en.md:226-250`** — the chain-of-passive-procs block:

```
main.nim(5, 3) Error: undeclared identifier: innerCont
```

`innerCont = delay()` is a module-level assignment with no declaration anywhere in the chapter, the sample, or the
pin's library, so the block that claims `outer 1 / inner 1 / outer parked / inner 2 / outer 2` cannot run. Raka
reached the same finding at `id.md:229-244`; adding `var innerCont: Continuation` makes all five lines appear as
printed.

**`chapters/24-passive-procs/en.md:188-205`** — the two-worker sketch calls `drive(delay(worker("a", 0)))`,
`drive(resumeA)`, `drive(resumeB)`; `worker`, `resumeA` and `resumeB` are declared only in the chapter sample, so
the sketch does not build in place. Raka's finding again (id.md:193-199).

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

1. **Chapter 7 drops three printed lines — medium.** Evidence above. Text change to a frozen chapter: either show
   `a`/`b`/`c` before the assertion or label the block as elided, plus an ERRATA line. Owner: Aksara.
2. **Chapter 24's chain block cannot be built — medium.** `en.md:226-250`, `id.md` same shape. Needs
   `var innerCont: Continuation` in the block or a note that the declaration lives in the sample. Owner: Aksara;
   wording by Momo.
3. **Chapter 24's two-worker sketch is not self-contained — low-medium.** Names come only from the sample. Same
   handoff as finding 2.
4. **Fixed in `0.1.20`: Appendix A/B promised a `review.md` that 7 chapters did not have.** Verified at HEAD: 24
   `chapters/*/review.md` exist, `a1/en.md:28` and `a2/en.md:141` now resolve.
5. **Fixed in `0.1.20`: Chapter 23 said `{.assert.}` as a statement is accepted without saying it must be
   provable.** `en.md:176` now carries the condition and the `half.nim(4, 5)` message is unchanged.
6. **Watch row stands: `cps.nim:269` is still a compiler assert at the pin.** Reproduced today; fix is
   `nim-lang/nimony#2988`, open and unmerged, so the book's pin is unchanged.

## Not proven by this audit

- **65 output blocks stay open, and 3 fail.** Shell sessions, build logs, NIF dumps, multi-file module cases, and excerpts
  that depend on declarations made earlier in the chapter. Each is listed by chapter in Table A; none is cleared.
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
