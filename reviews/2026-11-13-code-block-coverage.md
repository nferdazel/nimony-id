# Code-block coverage audit, 2026-11-13

What the sample gate proves about the code a reader is shown, for the whole book at `v0.1.20`, repository HEAD
`773ace5`, pin `4ba90a781b0b22d0821efaa153c129c37cef6143` (`nimony 0.6.3`). This is the item the whole-book
review left with Raka; the slices owned by Momo (`2026-11-13-technical-audit.md`), Wulan
(`2026-11-13-id-terminology.md`) and Aksara (`2026-11-13-whole-book.md`) are not repeated here.

Verdict: the gate is sound and green, and the code it does not touch mostly holds up — 45 printed blocks that
print output were compiled and run at the pin today, and 42 of them reproduce what the page shows. Two blocks in
Chapter 24 name identifiers the chapter never declares, and one output block in Chapter 7 drops lines the program
actually prints. None of these is a false claim about the language.

## What the gate proves, and what it does not

`tools/verify-samples.sh` compiles 23 programs, one per chapter from 2 to 24, and checks exit status. Appendix B
states the rest of the contract: the expected output printed in a chapter is matched against the block shown in
that chapter, byte by byte, by the editor and independently by the reviewer.

The Indonesian edition contains **435 fenced blocks**: 274 Nim code blocks, 136 output blocks, 24 shell/console
blocks, 1 empty. The English edition has the same 274 Nim blocks. Of the 274, **26 appear verbatim inside the
chapter's verified program**, and 6 more have every line present in it but not as one contiguous piece.

So the gate proves one program per chapter. It does not prove the 248 other Nim blocks on the page; those are
reviewer-checked, and the reviewer check is what this audit re-ran.

| Chapter | Nim blocks | verbatim in sample | all lines present | code+output pairs | pair not covered |
| --- | --- | --- | --- | --- | --- |
| 02-the-pinned-toolchain | 1 | 1 | 0 | 1 | 0 |
| 03-values-names-mutability | 6 | 2 | 1 | 2 | 1 |
| 04-numbers-types-conversion | 9 | 0 | 0 | 0 | 0 |
| 05-strings | 18 | 0 | 0 | 0 | 0 |
| 06-branching | 21 | 3 | 0 | 5 | 5 |
| 07-loops-ranges | 18 | 1 | 0 | 13 | 12 |
| 08-procedures | 19 | 6 | 0 | 4 | 3 |
| 09-overloading-and-ufcs | 18 | 0 | 4 | 10 | 10 |
| 10-arrays-sequences-tuples | 31 | 4 | 1 | 31 | 27 |
| 11-objects-enums-distinct | 17 | 2 | 0 | 0 | 0 |
| 12-sum-types-case | 11 | 4 | 0 | 1 | 1 |
| 13-references-pointers-nil | 10 | 3 | 0 | 0 | 0 |
| 14-ownership-borrow | 10 | 0 | 0 | 1 | 1 |
| 15-errors-as-values | 12 | 0 | 0 | 0 | 0 |
| 16-modules-visibility | 12 | 0 | 0 | 0 | 0 |
| 17-generics-concepts | 14 | 0 | 0 | 0 | 0 |
| 18-templates-compiletime | 7 | 0 | 0 | 0 | 0 |
| 19-plugins-nif | 9 | 0 | 0 | 0 | 0 |
| 20-stdlib | 4 | 0 | 0 | 0 | 0 |
| 21-files-processes | 3 | 0 | 0 | 0 | 0 |
| 22-cinterop | 9 | 0 | 0 | 0 | 0 |
| 23-testing | 8 | 0 | 0 | 2 | 2 |
| 24-passive-procs | 7 | 0 | 0 | 4 | 4 |
| **total** | **274** | **26** | **6** | **74** | **66** |

A "code+output pair" is a Nim block with an output block directly under it: the shape that asserts "this program
printed this". There are 74 in the Indonesian edition, 8 of them covered verbatim by the chapter's sample. Of the
66 that are not, 21 are error transcripts (Momo's list: 16 of 81 quoted diagnostics re-run, 64 not), 5 have all
their lines in the sample, and **40 have code that appears nowhere in the verified program**.

## What was re-run

```
bash tools/verify-samples.sh
SUMMARY 23/23 passed, 0 failed
```

Then every one of the 45 non-diagnostic pairs from the last two groups above (40 not in the sample, 5 present but
not contiguous) was extracted, compiled with `nimony c -r` at the pin, and its merged output diffed against the
block on the page (`audit-code-blocks.py`, outside the repository):

- **36 reproduce byte-exactly**, once the book's own abbreviations are undone (`/.../lib/...` for the install
  path, `... N more candidate lines` for the truncated overload lists).
- **6 needed declarations from an earlier block in the same chapter** (a `let word`, a `func count`, a
  `type Box`, three coroutine procs). Five were re-assembled with their preamble and then reproduce exactly; the
  sixth is the two-worker sketch in Chapter 24, whose dependencies exist only in the sample (finding 2).
- **3 differed**, and all three are explained: one is my pairing heuristic catching the wrong output block
  (Chapter 6, where the program does print the `g` the line comment promises), and two are presentation only —
  Chapter 10 prints the message without the `file(line, col) Error:` prefix and the `[in code expanded from …]`
  suffix the compiler adds.

That leaves one printed block that cannot be run as printed at all: finding 1.

## Findings

### 1. Chapter 24's `innerCont` is never declared — medium-low, both editions

`chapters/24-passive-procs/id.md:229-244` and `en.md:226-241` build a chain of passive procs that stores
`delay()` into `innerCont`. The chapter declares `resumeCont` (line 117 in `id.md`), the sample declares
`resumeA, resumeB`, and **nothing anywhere declares `innerCont`**: not the chapter, not the sample, not the pin's
stdlib (`grep -rn innerCont ~/.local/opt/nimony/4ba90a7/lib/std` → no match).

Typing the block as printed:

```
main.nim(4, 3) Error: undeclared identifier: innerCont
```

Add the missing line and the block prints exactly the five lines the page promises:

```
var innerCont: Continuation
```

```
outer 1
inner 1
outer parked
inner 2
outer 2
```

(verified with `{.feature: "assumeSync".}` at module level, which the chapter explains at `id.md:330`; without it
the block stops at the unsynchronized-global rule, also explained there).

### 2. The two-worker sketch names procs the chapter never defines — low, both editions

`chapters/24-passive-procs/id.md:193-199` calls `worker("a", 0)`, `worker("b", 1)`, `resumeA` and `resumeB`. The
`worker` declared in the chapter takes one argument and stores into `resumeCont`; the two-argument `worker` and
both resume slots exist only in `samples/24-passive-procs/passive.nim`. The paragraph after the block does say
the sample "takes the same shape", so the reader has a pointer, but the block itself does not compile and today
nothing on the page says so.

Cheapest fix: one sentence naming the sample as the definition of `worker(name, which)`, `resumeA` and `resumeB`.

### 3. Chapter 7's crash transcript drops the lines printed before the crash — low, both editions

`chapters/07-loops-ranges/id.md:139-145` claims `for i in 0..len(word): echo word[i]` fails with

```
…/stringimpl.nim(686, 37): i < len(s) [AssertionDefect]
```

At the pin the program prints `a`, `b`, `c` first and then that line. The assertion text is exact; the transcript
is incomplete, and Appendix B promises byte-per-byte matching. Either add the three lines or mark the elision the
way Chapter 10 marks its truncated candidate lists.

### 4. Not a finding: the assertion-gated blocks in Chapter 24

Blocks at `id.md:117`, `:159` and the two above touch module-level `Continuation` variables, so a reader who
types them gets `Error: unsynchronized access to global variable …` before anything runs. The chapter explains
the rule at `id.md:322-333` and names `{.feature: "assumeSync".}` as what the sample uses. No change needed
unless the editor wants the pragma repeated inside the blocks.

## Not proven by this audit

- **21 error transcripts in these 66 pairs were not re-run by me.** They overlap Momo's diagnostic list, which
  has 64 of 81 still unverified; the two counts are not the same set and I did not merge them.
- **The 66 pairs are the shape "code then output".** The other 200 Nim blocks have no printed output block: they
  are fragments, some of them a signature or a single statement, and nothing on the page claims they run. I did
  not compile them.
- **Nim 2.4.0 columns were not exercised.** This audit only ran the pin.
- **The `review.md` probe tables were not re-executed**, same limitation Momo recorded.
- Chapter 1 has no code blocks and no sample; nothing here applies to it.

## Recommendation

1. Two prose fixes and one output fix for Aksara: declare `innerCont`, point the two-worker sketch at the sample,
   and complete or mark the Chapter 7 transcript. All three are editorial additions inside frozen chapters, so
   they need ERRATA rows in the same pass.
2. One sentence in Appendix B, after the paragraph that promises byte-for-byte matching: the gate compiles one
   program per chapter, and the printed blocks are checked by the reviewer against the pin, not by
   `verify-samples.sh`. Without that sentence the appendix implies the gate covers 274 blocks; it covers 23.
3. For future chapters, the rule I would hold: a code block with an output block under it must be reproducible by
   pasting it, with only the chapter's own preamble, or carry an explicit note saying what it leaves out.

## Artifacts

Scripts outside the repository, in
`~/.openmausbot/workspaces/3e91cc5a-81ae-418a-82dc-1876effb8fc8/`:
`coverage-table.py` (block classification and the table above), `audit-code-blocks.py` (the 45-block re-run,
merged output diff). Temporary programs under `$TMPDIR/blk-*`, `$TMPDIR/ctx24/`, `$TMPDIR/frag/`.
