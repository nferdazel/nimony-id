# Sample coverage against rule 3, 2026-11-13

Repository `~/Projects/nimony-id`, HEAD `773ace5`, `VERSION` 0.1.20 (the brief and
`2026-11-13-whole-book.md` say v0.1.18; the tree on disk is 0.1.20), pin
`4ba90a781b0b22d0821efaa153c129c37cef6143` (`nimony 0.6.3`). This file answers one question: does every Nimony
code block in the book have a sample behind it, as `CONTRIBUTING.md` rule 3 claims. Compiling the blocks that are
*not* in a sample and checking what they print is the other audit,
`2026-11-13-code-block-coverage.md`, and is not repeated here. That file counts only fences tagged `nim`; this one
counts every fence that carries Nimony source, tagged or not, which is why its totals are larger.

## The rule under test

> 3. Every code block in a chapter has a file under `samples/NN-slug/` that the verifier runs. A block with no
>    sample behind it is prose that nobody has compiled.

## What was checked

- All 27 chapter folders, both editions, all 880 fenced blocks (440 per edition). Fence counts match per edition,
  so the two editions pair block by block. Their code is identical for every source pair; the only source pairs
  whose text differs at all differ in a translated trailing comment (`05-strings` at EN lines 109, 167 and 277,
  `14-ownership-borrow` at EN line 88). One row therefore covers both editions, with both opening-fence line
  numbers.
- 272 of the 440 blocks per edition carry Nimony source: tagged `nim`, or a bare fence whose first non-comment
  line is code. The other 168 are compiler diagnostics (58), expected-output blocks, shell and console
  transcripts, NIF dumps and one C typedef dump. Rule 3 does not reach those, and none is counted below.
- For each source block, its code lines (comments and blank lines dropped, whitespace collapsed, trailing
  comments removed outside string literals) were searched in every `*.nim` under the chapter's `samples/NN-*`
  folder, `nimcache/` excluded. Chapter 9 is the one folder whose sample directory is not the chapter slug:
  `samples/09-overloading/`, not `09-overloading-and-ufcs`.
- Coverage is the share of a block's code lines found in that chapter's sample files. A line match proves the
  line is present somewhere in the verified program; it does not prove the block compiles, and it says nothing
  about stdout. Inside `IN`, *one run* means the block's code appears as one contiguous sequence in the sample;
  *not one run* means every line is there but assembled from more than one place.

## Verdicts

| Verdict | Meaning | Rule 3 |
| --- | --- | --- |
| `IN` | Every code line is in the chapter's sample. *One run*: as printed. *Not one run*: assembled from more than one place. | met |
| `IN-DIFF` | At least half the code lines are in the sample, at least one is not: a reader copying the block gets a program the verifier never ran. | not met unless the prose marks it as an excerpt — none does |
| `FAIL-PARTIAL` | Fewer than half the lines are in the sample. The block does not appear. | not met |
| `FAIL-MISSING` | No code line appears anywhere in the chapter's sample. | not met |
| `ELIDED` | The block is an extract of the sample and the prose says so. | met |

`ELIDED` has no rows. Neither edition uses "excerpt" for a listing (zero matches in all 54 chapter files), and no
source block is introduced as a cut-down copy of its sample. The `...` that appears in the book is either a
compiler transcript's truncation or Nim syntax such as `find(...)`; it is never an editorial elision.

## Result

272 source blocks per edition, one row each below:

| Verdict | Blocks | Share |
| --- | --- | --- |
| `IN` | 82 | 30% |
| `IN-DIFF` | 47 | 17% |
| `FAIL-PARTIAL` | 30 | 11% |
| `FAIL-MISSING` | 113 | 42% |
| `ELIDED` | 0 | 0% |
| **not met** | **190** | **70%** |

Of the 82 `IN` blocks, 66 appear as one contiguous run in the sample and 16 have every line present but not as a
run. No chapter is fully clean except 02, whose single block is in the sample; 03 is next at 6 of 7. Chapter 1 has
no code blocks and no rows. The worst are 10 (5 of 31 in), 14 (0 of 10), 17 (0 of 14) and 24 (0 of 7).

Every block that does not meet the rule is a row with its chapter and opening-fence line: 190 in all, 47 of them
`IN-DIFF` and 143 that appear nowhere in it.

The chapter table below is the summary; the per-chapter tables list every block. In those tables `#` is the
fence's ordinal within the edition, `EN line` and `ID line` are the line of the opening fence in each edition,
and `sample` is the file the verifier runs for that chapter.

| Chapter | Source blocks | IN | IN-DIFF | FAIL-PARTIAL | FAIL-MISSING | Rule 3 met |
| --- | --- | --- | --- | --- | --- | --- |
| 02-the-pinned-toolchain | 1 | 1 | 0 | 0 | 0 | 100% |
| 03-values-names-mutability | 7 | 6 | 0 | 0 | 1 | 86% |
| 04-numbers-types-conversion | 9 | 3 | 2 | 0 | 4 | 33% |
| 05-strings | 18 | 8 | 3 | 1 | 6 | 44% |
| 06-branching | 22 | 10 | 0 | 2 | 10 | 45% |
| 07-loops-ranges | 18 | 1 | 7 | 4 | 6 | 6% |
| 08-procedures | 19 | 6 | 6 | 1 | 6 | 32% |
| 09-overloading-and-ufcs | 15 | 4 | 2 | 1 | 8 | 27% |
| 10-arrays-sequences-tuples | 31 | 5 | 5 | 3 | 18 | 16% |
| 11-objects-enums-distinct | 17 | 9 | 3 | 3 | 2 | 53% |
| 12-sum-types-case | 11 | 5 | 1 | 0 | 5 | 45% |
| 13-references-pointers-nil | 10 | 4 | 1 | 0 | 5 | 40% |
| 14-ownership-borrow | 10 | 0 | 0 | 1 | 9 | 0% |
| 15-errors-as-values | 12 | 4 | 2 | 5 | 1 | 33% |
| 16-modules-visibility | 11 | 1 | 1 | 0 | 9 | 9% |
| 17-generics-concepts | 14 | 0 | 2 | 1 | 11 | 0% |
| 18-templates-compiletime | 7 | 1 | 2 | 0 | 4 | 14% |
| 19-plugins-nif | 9 | 3 | 2 | 1 | 3 | 33% |
| 20-stdlib | 4 | 3 | 0 | 0 | 1 | 75% |
| 21-files-processes | 3 | 1 | 2 | 0 | 0 | 33% |
| 22-cinterop | 9 | 6 | 0 | 1 | 2 | 67% |
| 23-testing | 8 | 1 | 3 | 3 | 1 | 12% |
| 24-passive-procs | 7 | 0 | 3 | 3 | 1 | 0% |
| **total** | **272** | **82** | **47** | **30** | **113** | **30%** |


## Blocks, chapter by chapter

### 02-the-pinned-toolchain

1 source blocks — IN 1.

| # | EN line | ID line | verdict | sample | note |
| --- | --- | --- | --- | --- | --- |
| 7 | 132 | 138 | IN | samples/02-pinned-toolchain/hello.nim | all 2 code lines present, one run in the sample |

### 03-values-names-mutability

7 source blocks — FAIL-MISSING 1, IN 6.

| # | EN line | ID line | verdict | sample | note |
| --- | --- | --- | --- | --- | --- |
| 1 | 37 | 38 | IN | samples/03-values-names-mutability/values.nim | all 2 code lines present, one run in the sample |
| 2 | 44 | 46 | IN | samples/03-values-names-mutability/values.nim | all 2 code lines present, one run in the sample |
| 3 | 58 | 61 | IN | samples/03-values-names-mutability/values.nim | all 1 code lines present, one run in the sample |
| 5 | 78 | 81 | IN | samples/03-values-names-mutability/values.nim | all 3 code lines present, one run in the sample |
| 7 | 108 | 112 | IN | samples/03-values-names-mutability/values.nim | all 4 code lines present, one run in the sample |
| 9 | 127 | 131 | FAIL-MISSING | samples/03-values-names-mutability/values.nim | no code line found |
| 10 | 140 | 144 | IN | samples/03-values-names-mutability/values.nim | all 4 code lines present, one run in the sample |

### 04-numbers-types-conversion

9 source blocks — FAIL-MISSING 4, IN 3, IN-DIFF 2.

| # | EN line | ID line | verdict | sample | note |
| --- | --- | --- | --- | --- | --- |
| 1 | 36 | 37 | FAIL-MISSING | samples/04-numbers-types-conversion/numbers.nim | no code line found |
| 2 | 62 | 63 | IN-DIFF | samples/04-numbers-types-conversion/numbers.nim | 5/6 lines present; missing: var top = 9223372036854775807'i64 |
| 3 | 88 | 89 | FAIL-MISSING | samples/04-numbers-types-conversion/numbers.nim | no code line found |
| 4 | 100 | 101 | IN-DIFF | samples/04-numbers-types-conversion/numbers.nim | 2/3 lines present; missing: echo 6 / 2 |
| 5 | 114 | 115 | IN | samples/04-numbers-types-conversion/numbers.nim | all 3 code lines present, one run in the sample |
| 6 | 142 | 145 | IN | samples/04-numbers-types-conversion/numbers.nim | all 3 code lines present, one run in the sample |
| 7 | 156 | 159 | IN | samples/04-numbers-types-conversion/numbers.nim | all 3 code lines present, not one run in the sample |
| 8 | 166 | 169 | FAIL-MISSING | samples/04-numbers-types-conversion/numbers.nim | no code line found |
| 9 | 174 | 177 | FAIL-MISSING | samples/04-numbers-types-conversion/numbers.nim | no code line found |

### 05-strings

18 source blocks — FAIL-MISSING 6, FAIL-PARTIAL 1, IN 8, IN-DIFF 3.

| # | EN line | ID line | verdict | sample | note |
| --- | --- | --- | --- | --- | --- |
| 1 | 31 | 31 | IN | samples/05-strings/strings.nim | all 2 code lines present, one run in the sample |
| 2 | 39 | 39 | FAIL-PARTIAL | samples/05-strings/strings.nim | 1/5 lines present; missing: var line = "abc"; var copy = line; copy.add "d"; echo copy |
| 3 | 55 | 56 | IN-DIFF | samples/05-strings/strings.nim | 3/4 lines present; missing: line.add "values" |
| 4 | 65 | 66 | IN | samples/05-strings/strings.nim | all 1 code lines present, one run in the sample |
| 5 | 73 | 74 | IN | samples/05-strings/strings.nim | all 1 code lines present, one run in the sample |
| 6 | 83 | 83 | IN | samples/05-strings/strings.nim | all 3 code lines present, one run in the sample |
| 7 | 92 | 93 | FAIL-MISSING | samples/05-strings/strings.nim | no code line found |
| 8 | 109 | 111 | IN-DIFF | samples/05-strings/strings.nim | 1/2 lines present; missing: echo "abc"[2..1] |
| 9 | 120 | 122 | IN | samples/05-strings/strings.nim | all 3 code lines present, one run in the sample |
| 10 | 131 | 133 | IN | samples/05-strings/strings.nim | all 3 code lines present, one run in the sample |
| 11 | 144 | 146 | FAIL-MISSING | samples/05-strings/strings.nim | no code line found |
| 12 | 167 | 169 | IN | samples/05-strings/strings.nim | all 2 code lines present, one run in the sample |
| 13 | 174 | 176 | FAIL-MISSING | samples/05-strings/strings.nim | no code line found |
| 14 | 188 | 190 | IN | samples/05-strings/strings.nim | all 3 code lines present, one run in the sample |
| 15 | 208 | 210 | FAIL-MISSING | samples/05-strings/strings.nim | no code line found |
| 16 | 227 | 229 | FAIL-MISSING | samples/05-strings/strings.nim | no code line found |
| 17 | 239 | 241 | FAIL-MISSING | samples/05-strings/strings.nim | no code line found |
| 18 | 277 | 279 | IN-DIFF | samples/05-strings/strings.nim | 5/8 lines present; missing: echo "alpha".toUpperAscii(); echo " pad ".strip(); echo "a-b-c".replace("-", "+") |

### 06-branching

22 source blocks — FAIL-MISSING 10, FAIL-PARTIAL 2, IN 10.

| # | EN line | ID line | verdict | sample | note |
| --- | --- | --- | --- | --- | --- |
| 1 | 34 | 34 | IN | samples/06-branching/branching.nim | all 7 code lines present, one run in the sample |
| 2 | 53 | 53 | IN | samples/06-branching/branching.nim | all 3 code lines present, not one run in the sample |
| 3 | 65 | 65 | FAIL-MISSING | samples/06-branching/branching.nim | no code line found |
| 5 | 78 | 78 | FAIL-MISSING | samples/06-branching/branching.nim | no code line found |
| 6 | 88 | 88 | FAIL-MISSING | samples/06-branching/branching.nim | no code line found |
| 7 | 99 | 99 | IN | samples/06-branching/branching.nim | all 5 code lines present, one run in the sample |
| 8 | 118 | 118 | IN | samples/06-branching/branching.nim | all 7 code lines present, one run in the sample |
| 9 | 130 | 130 | IN | samples/06-branching/branching.nim | all 2 code lines present, one run in the sample |
| 12 | 156 | 156 | IN | samples/06-branching/branching.nim | all 5 code lines present, one run in the sample |
| 13 | 167 | 167 | FAIL-MISSING | samples/06-branching/branching.nim | no code line found |
| 14 | 186 | 186 | FAIL-MISSING | samples/06-branching/branching.nim | no code line found |
| 16 | 204 | 204 | FAIL-PARTIAL | samples/06-branching/branching.nim | 1/4 lines present; missing: let r = case n; of 0: "zero"; if n > 10: "medium" else: "small" |
| 17 | 225 | 225 | FAIL-MISSING | samples/06-branching/branching.nim | no code line found |
| 18 | 236 | 236 | FAIL-MISSING | samples/06-branching/branching.nim | no code line found |
| 20 | 263 | 263 | IN | samples/06-branching/branching.nim | all 4 code lines present, one run in the sample |
| 21 | 273 | 273 | FAIL-MISSING | samples/06-branching/branching.nim | no code line found |
| 22 | 282 | 282 | FAIL-MISSING | samples/06-branching/branching.nim | no code line found |
| 24 | 295 | 296 | FAIL-MISSING | samples/06-branching/branching.nim | no code line found |
| 25 | 308 | 309 | IN | samples/06-branching/branching.nim | all 2 code lines present, one run in the sample |
| 26 | 317 | 318 | FAIL-PARTIAL | samples/06-branching/branching.nim | 3/8 lines present; missing: var found = false; block myblock:; found = true; break myblock; echo found |
| 27 | 334 | 335 | IN | samples/06-branching/branching.nim | all 6 code lines present, one run in the sample |
| 28 | 350 | 352 | IN | samples/06-branching/branching.nim | all 7 code lines present, one run in the sample |

### 07-loops-ranges

18 source blocks — FAIL-MISSING 6, FAIL-PARTIAL 4, IN 1, IN-DIFF 7.

| # | EN line | ID line | verdict | sample | note |
| --- | --- | --- | --- | --- | --- |
| 1 | 31 | 31 | IN-DIFF | samples/07-loops-ranges/loops.nim | 1/2 lines present; missing: echo i |
| 3 | 50 | 50 | FAIL-MISSING | samples/07-loops-ranges/loops.nim | no code line found |
| 4 | 58 | 58 | IN-DIFF | samples/07-loops-ranges/loops.nim | 3/4 lines present; missing: echo seen |
| 7 | 86 | 86 | FAIL-MISSING | samples/07-loops-ranges/loops.nim | no code line found |
| 9 | 103 | 103 | IN-DIFF | samples/07-loops-ranges/loops.nim | 1/2 lines present; missing: echo i |
| 11 | 120 | 120 | IN-DIFF | samples/07-loops-ranges/loops.nim | 2/3 lines present; missing: echo i, " ", word[i] |
| 13 | 139 | 139 | FAIL-MISSING | samples/07-loops-ranges/loops.nim | no code line found |
| 15 | 156 | 156 | IN-DIFF | samples/07-loops-ranges/loops.nim | 1/2 lines present; missing: echo i |
| 16 | 161 | 161 | FAIL-MISSING | samples/07-loops-ranges/loops.nim | no code line found |
| 17 | 171 | 171 | FAIL-PARTIAL | samples/07-loops-ranges/loops.nim | 1/4 lines present; missing: echo i; for i in countdown(5, 1, 2):; echo i |
| 18 | 190 | 190 | IN-DIFF | samples/07-loops-ranges/loops.nim | 1/2 lines present; missing: echo c |
| 20 | 209 | 209 | FAIL-PARTIAL | samples/07-loops-ranges/loops.nim | 1/4 lines present; missing: if i == 1:; i = 3; echo i |
| 22 | 234 | 234 | IN-DIFF | samples/07-loops-ranges/loops.nim | 3/4 lines present; missing: echo i |
| 24 | 249 | 249 | FAIL-PARTIAL | samples/07-loops-ranges/loops.nim | 1/6 lines present; missing: for i in 0..2:; block:; let x = i; if x == 1:; echo x |
| 26 | 271 | 271 | FAIL-MISSING | samples/07-loops-ranges/loops.nim | no code line found |
| 28 | 284 | 284 | FAIL-PARTIAL | samples/07-loops-ranges/loops.nim | 1/6 lines present; missing: var i = 0; while i < 5:; i = i + 1; if i == 3:; echo i |
| 30 | 308 | 308 | IN | samples/07-loops-ranges/loops.nim | all 7 code lines present, one run in the sample |
| 32 | 346 | 348 | FAIL-MISSING | samples/07-loops-ranges/loops.nim | no code line found |

### 08-procedures

19 source blocks — FAIL-MISSING 6, FAIL-PARTIAL 1, IN 6, IN-DIFF 6.

| # | EN line | ID line | verdict | sample | note |
| --- | --- | --- | --- | --- | --- |
| 1 | 29 | 31 | FAIL-MISSING | samples/08-procedures/procedures.nim | no code line found |
| 3 | 47 | 50 | FAIL-MISSING | samples/08-procedures/procedures.nim | no code line found |
| 4 | 59 | 62 | IN | samples/08-procedures/procedures.nim | all 1 code lines present, one run in the sample |
| 5 | 73 | 76 | FAIL-MISSING | samples/08-procedures/procedures.nim | no code line found |
| 6 | 90 | 93 | FAIL-MISSING | samples/08-procedures/procedures.nim | no code line found |
| 7 | 101 | 104 | FAIL-MISSING | samples/08-procedures/procedures.nim | no code line found |
| 9 | 122 | 125 | IN | samples/08-procedures/procedures.nim | all 5 code lines present, one run in the sample |
| 10 | 134 | 138 | IN | samples/08-procedures/procedures.nim | all 5 code lines present, one run in the sample |
| 11 | 150 | 154 | FAIL-PARTIAL | samples/08-procedures/procedures.nim | 1/3 lines present; missing: echo pad(7); echo pad(7, 2) |
| 12 | 165 | 170 | FAIL-MISSING | samples/08-procedures/procedures.nim | no code line found |
| 13 | 179 | 184 | IN-DIFF | samples/08-procedures/procedures.nim | 1/2 lines present; missing: echo pad(width = 2, n = 7) |
| 14 | 199 | 204 | IN-DIFF | samples/08-procedures/procedures.nim | 4/5 lines present; missing: echo n |
| 16 | 225 | 230 | IN-DIFF | samples/08-procedures/procedures.nim | 5/6 lines present; missing: echo q, " ", r |
| 17 | 253 | 258 | IN-DIFF | samples/08-procedures/procedures.nim | 2/3 lines present; missing: echo t[0], " ", t[1] |
| 18 | 268 | 273 | IN | samples/08-procedures/procedures.nim | all 5 code lines present, one run in the sample |
| 21 | 322 | 328 | IN-DIFF | samples/08-procedures/procedures.nim | 1/2 lines present; missing: add(1, 2) |
| 23 | 347 | 355 | IN | samples/08-procedures/procedures.nim | all 3 code lines present, one run in the sample |
| 24 | 367 | 375 | IN | samples/08-procedures/procedures.nim | all 5 code lines present, one run in the sample |
| 25 | 381 | 389 | IN-DIFF | samples/08-procedures/procedures.nim | 1/2 lines present; missing: echo later(4) |

### 09-overloading-and-ufcs

15 source blocks — FAIL-MISSING 8, FAIL-PARTIAL 1, IN 4, IN-DIFF 2.

| # | EN line | ID line | verdict | sample | note |
| --- | --- | --- | --- | --- | --- |
| 1 | 40 | 43 | IN | samples/09-overloading/overloading.nim | all 4 code lines present, not one run in the sample |
| 3 | 55 | 58 | IN | samples/09-overloading/overloading.nim | all 4 code lines present, not one run in the sample |
| 5 | 71 | 74 | FAIL-MISSING | samples/09-overloading/overloading.nim | no code line found |
| 7 | 109 | 113 | FAIL-MISSING | samples/09-overloading/overloading.nim | no code line found |
| 9 | 127 | 132 | FAIL-MISSING | samples/09-overloading/overloading.nim | no code line found |
| 11 | 144 | 149 | FAIL-MISSING | samples/09-overloading/overloading.nim | no code line found |
| 13 | 178 | 184 | IN | samples/09-overloading/overloading.nim | all 4 code lines present, not one run in the sample |
| 15 | 201 | 207 | IN-DIFF | samples/09-overloading/overloading.nim | 1/2 lines present; missing: echo 1.wrap("a") |
| 17 | 220 | 226 | FAIL-MISSING | samples/09-overloading/overloading.nim | no code line found |
| 19 | 233 | 238 | FAIL-MISSING | samples/09-overloading/overloading.nim | no code line found |
| 21 | 253 | 258 | FAIL-MISSING | samples/09-overloading/overloading.nim | no code line found |
| 22 | 268 | 273 | FAIL-PARTIAL | samples/09-overloading/overloading.nim | 1/4 lines present; missing: func get(b: var Box, i: int): var int = b.v; func get(b: Box, i: int): int = b.v; echo get(b, 0) |
| 24 | 286 | 291 | FAIL-MISSING | samples/09-overloading/overloading.nim | no code line found |
| 26 | 302 | 307 | IN-DIFF | samples/09-overloading/overloading.nim | 2/3 lines present; missing: func `[]`(x: Container, i: int): var int = x.data[i] |
| 28 | 329 | 334 | IN | samples/09-overloading/overloading.nim | all 5 code lines present, not one run in the sample |

### 10-arrays-sequences-tuples

31 source blocks — FAIL-MISSING 18, FAIL-PARTIAL 3, IN 5, IN-DIFF 5.

| # | EN line | ID line | verdict | sample | note |
| --- | --- | --- | --- | --- | --- |
| 1 | 42 | 44 | FAIL-MISSING | samples/10-arrays-sequences-tuples/collections.nim | no code line found |
| 3 | 60 | 62 | FAIL-MISSING | samples/10-arrays-sequences-tuples/collections.nim | no code line found |
| 5 | 83 | 85 | FAIL-MISSING | samples/10-arrays-sequences-tuples/collections.nim | no code line found |
| 7 | 95 | 97 | IN | samples/10-arrays-sequences-tuples/collections.nim | all 4 code lines present, one run in the sample |
| 9 | 114 | 116 | IN-DIFF | samples/10-arrays-sequences-tuples/collections.nim | 6/7 lines present; missing: for x in row: |
| 11 | 136 | 138 | IN-DIFF | samples/10-arrays-sequences-tuples/collections.nim | 2/3 lines present; missing: echo row[0] |
| 13 | 149 | 151 | FAIL-MISSING | samples/10-arrays-sequences-tuples/collections.nim | no code line found |
| 15 | 163 | 165 | IN-DIFF | samples/10-arrays-sequences-tuples/collections.nim | 5/7 lines present; missing: echo counts.len; echo counts.high |
| 17 | 188 | 190 | FAIL-MISSING | samples/10-arrays-sequences-tuples/collections.nim | no code line found |
| 19 | 201 | 203 | FAIL-MISSING | samples/10-arrays-sequences-tuples/collections.nim | no code line found |
| 21 | 221 | 223 | IN | samples/10-arrays-sequences-tuples/collections.nim | all 7 code lines present, one run in the sample |
| 23 | 248 | 250 | FAIL-MISSING | samples/10-arrays-sequences-tuples/collections.nim | no code line found |
| 25 | 261 | 263 | FAIL-MISSING | samples/10-arrays-sequences-tuples/collections.nim | no code line found |
| 27 | 278 | 281 | FAIL-MISSING | samples/10-arrays-sequences-tuples/collections.nim | no code line found |
| 29 | 294 | 297 | FAIL-MISSING | samples/10-arrays-sequences-tuples/collections.nim | no code line found |
| 31 | 307 | 310 | FAIL-PARTIAL | samples/10-arrays-sequences-tuples/collections.nim | 1/7 lines present; missing: proc grow(xs: seq[int]): int =; copy.add 3; result = copy.len; var s = @[1, 2]; echo grow(s); echo s.len |
| 33 | 330 | 333 | FAIL-MISSING | samples/10-arrays-sequences-tuples/collections.nim | no code line found |
| 35 | 344 | 348 | FAIL-MISSING | samples/10-arrays-sequences-tuples/collections.nim | no code line found |
| 37 | 362 | 366 | IN-DIFF | samples/10-arrays-sequences-tuples/collections.nim | 4/5 lines present; missing: var xs = @[1, 2, 3, 4] |
| 39 | 379 | 383 | IN-DIFF | samples/10-arrays-sequences-tuples/collections.nim | 3/5 lines present; missing: let xs = @[1, 2, 3, 4]; echo xs[0..<2].len |
| 41 | 400 | 404 | FAIL-MISSING | samples/10-arrays-sequences-tuples/collections.nim | no code line found |
| 43 | 427 | 430 | IN | samples/10-arrays-sequences-tuples/collections.nim | all 5 code lines present, one run in the sample |
| 45 | 451 | 453 | FAIL-PARTIAL | samples/10-arrays-sequences-tuples/collections.nim | 4/9 lines present; missing: let arr = [1, 2, 3]; let sq = @[4, 5]; echo total(arr); echo total(sq); echo total([6, 7, 8]) |
| 47 | 472 | 474 | FAIL-MISSING | samples/10-arrays-sequences-tuples/collections.nim | no code line found |
| 49 | 500 | 503 | FAIL-PARTIAL | samples/10-arrays-sequences-tuples/collections.nim | 1/7 lines present; missing: var p: Person = (name: "Ada", age: 36); var q: Person = ("Bob", 20); echo p.name; echo p.age; echo p[0]; echo q.name |
| 52 | 532 | 536 | FAIL-MISSING | samples/10-arrays-sequences-tuples/collections.nim | no code line found |
| 54 | 544 | 548 | FAIL-MISSING | samples/10-arrays-sequences-tuples/collections.nim | no code line found |
| 56 | 564 | 568 | FAIL-MISSING | samples/10-arrays-sequences-tuples/collections.nim | no code line found |
| 58 | 577 | 581 | IN | samples/10-arrays-sequences-tuples/collections.nim | all 6 code lines present, not one run in the sample |
| 60 | 594 | 598 | FAIL-MISSING | samples/10-arrays-sequences-tuples/collections.nim | no code line found |
| 62 | 607 | 611 | IN | samples/10-arrays-sequences-tuples/collections.nim | all 11 code lines present, one run in the sample |

### 11-objects-enums-distinct

17 source blocks — FAIL-MISSING 2, FAIL-PARTIAL 3, IN 9, IN-DIFF 3.

| # | EN line | ID line | verdict | sample | note |
| --- | --- | --- | --- | --- | --- |
| 1 | 36 | 37 | IN | samples/11-objects-enums-distinct/objects.nim | all 3 code lines present, one run in the sample |
| 2 | 47 | 48 | IN-DIFF | samples/11-objects-enums-distinct/objects.nim | 3/4 lines present; missing: echo Point(x: 1).y |
| 3 | 57 | 58 | IN | samples/11-objects-enums-distinct/objects.nim | all 5 code lines present, one run in the sample |
| 4 | 79 | 79 | FAIL-PARTIAL | samples/11-objects-enums-distinct/objects.nim | 1/5 lines present; missing: var a = Point(x: 1, y: 2); b.x = 99; echo a.x; echo b.x |
| 5 | 90 | 90 | IN-DIFF | samples/11-objects-enums-distinct/objects.nim | 6/7 lines present; missing: var a = Bag(items: @[1, 2]) |
| 6 | 112 | 112 | FAIL-PARTIAL | samples/11-objects-enums-distinct/objects.nim | 2/7 lines present; missing: type A = object; type B = object; var a = A(x: 1); var b = B(x: 2); a = b |
| 7 | 126 | 126 | FAIL-MISSING | samples/11-objects-enums-distinct/objects.nim | no code line found |
| 9 | 156 | 156 | IN | samples/11-objects-enums-distinct/objects.nim | all 3 code lines present, one run in the sample |
| 10 | 182 | 182 | IN | samples/11-objects-enums-distinct/objects.nim | all 6 code lines present, one run in the sample |
| 11 | 195 | 195 | IN | samples/11-objects-enums-distinct/objects.nim | all 5 code lines present, not one run in the sample |
| 12 | 212 | 212 | IN | samples/11-objects-enums-distinct/objects.nim | all 7 code lines present, one run in the sample |
| 13 | 234 | 234 | FAIL-PARTIAL | samples/11-objects-enums-distinct/objects.nim | 1/4 lines present; missing: var c = red; inc c; echo succ(blue) |
| 14 | 262 | 263 | IN | samples/11-objects-enums-distinct/objects.nim | all 5 code lines present, not one run in the sample |
| 15 | 273 | 274 | FAIL-MISSING | samples/11-objects-enums-distinct/objects.nim | no code line found |
| 16 | 287 | 289 | IN-DIFF | samples/11-objects-enums-distinct/objects.nim | 2/4 lines present; missing: func `+`(lhs, rhs: Meters): Meters = Meters(int(lhs) + int(rhs)); echo $Meters(4) |
| 17 | 297 | 299 | IN | samples/11-objects-enums-distinct/objects.nim | all 1 code lines present, one run in the sample |
| 18 | 310 | 312 | IN | samples/11-objects-enums-distinct/objects.nim | all 5 code lines present, one run in the sample |

### 12-sum-types-case

11 source blocks — FAIL-MISSING 5, IN 5, IN-DIFF 1.

| # | EN line | ID line | verdict | sample | note |
| --- | --- | --- | --- | --- | --- |
| 1 | 37 | 37 | IN | samples/12-sum-types-case/sumtypes.nim | all 11 code lines present, one run in the sample |
| 3 | 65 | 65 | IN-DIFF | samples/12-sum-types-case/sumtypes.nim | 6/8 lines present; missing: Kind = enum Circle, Rectangle, Triangle; case kind: Kind |
| 6 | 114 | 114 | IN | samples/12-sum-types-case/sumtypes.nim | all 5 code lines present, not one run in the sample |
| 7 | 137 | 137 | FAIL-MISSING | samples/12-sum-types-case/sumtypes.nim | no code line found |
| 8 | 154 | 154 | IN | samples/12-sum-types-case/sumtypes.nim | all 9 code lines present, one run in the sample |
| 9 | 170 | 170 | IN | samples/12-sum-types-case/sumtypes.nim | all 5 code lines present, one run in the sample |
| 11 | 212 | 213 | FAIL-MISSING | samples/12-sum-types-case/sumtypes.nim | no code line found |
| 12 | 220 | 221 | FAIL-MISSING | samples/12-sum-types-case/sumtypes.nim | no code line found |
| 13 | 230 | 231 | FAIL-MISSING | samples/12-sum-types-case/sumtypes.nim | no code line found |
| 14 | 254 | 257 | FAIL-MISSING | samples/12-sum-types-case/sumtypes.nim | no code line found |
| 15 | 272 | 275 | IN | samples/12-sum-types-case/sumtypes.nim | all 18 code lines present, one run in the sample |

### 13-references-pointers-nil

10 source blocks — FAIL-MISSING 5, IN 4, IN-DIFF 1.

| # | EN line | ID line | verdict | sample | note |
| --- | --- | --- | --- | --- | --- |
| 1 | 40 | 40 | IN | samples/13-references-pointers-nil/refs.nim | all 4 code lines present, one run in the sample |
| 2 | 64 | 65 | IN | samples/13-references-pointers-nil/refs.nim | all 4 code lines present, one run in the sample |
| 4 | 123 | 121 | FAIL-MISSING | samples/13-references-pointers-nil/refs.nim | no code line found |
| 5 | 140 | 138 | IN | samples/13-references-pointers-nil/refs.nim | all 3 code lines present, one run in the sample |
| 6 | 171 | 168 | FAIL-MISSING | samples/13-references-pointers-nil/refs.nim | no code line found |
| 7 | 182 | 179 | FAIL-MISSING | samples/13-references-pointers-nil/refs.nim | no code line found |
| 8 | 201 | 198 | FAIL-MISSING | samples/13-references-pointers-nil/refs.nim | no code line found |
| 9 | 208 | 205 | IN-DIFF | samples/13-references-pointers-nil/refs.nim | 3/5 lines present; missing: proc boxedNotNil(v: int): ref int =; var tmp: ref int |
| 10 | 226 | 222 | IN | samples/13-references-pointers-nil/refs.nim | all 6 code lines present, one run in the sample |
| 11 | 256 | 252 | FAIL-MISSING | samples/13-references-pointers-nil/refs.nim | no code line found |

### 14-ownership-borrow

10 source blocks — FAIL-MISSING 9, FAIL-PARTIAL 1.

| # | EN line | ID line | verdict | sample | note |
| --- | --- | --- | --- | --- | --- |
| 3 | 88 | 89 | FAIL-MISSING | samples/14-ownership-borrow/ownership.nim | no code line found |
| 4 | 117 | 118 | FAIL-PARTIAL | samples/14-ownership-borrow/ownership.nim | 2/11 lines present; missing: type Plain = object; type Named = object; x: int; proc update(a: var int, b: Plain) = a = b.x; proc updateNamed(a: var int, b: Named) = a = b.x; var plain = Plain(x: 1, y: 2); var named = Named(x: 1, name: "n"); update(plain.x, plain) |
| 5 | 152 | 155 | FAIL-MISSING | samples/14-ownership-borrow/ownership.nim | no code line found |
| 7 | 171 | 174 | FAIL-MISSING | samples/14-ownership-borrow/ownership.nim | no code line found |
| 8 | 182 | 185 | FAIL-MISSING | samples/14-ownership-borrow/ownership.nim | no code line found |
| 9 | 198 | 201 | FAIL-MISSING | samples/14-ownership-borrow/ownership.nim | no code line found |
| 10 | 214 | 217 | FAIL-MISSING | samples/14-ownership-borrow/ownership.nim | no code line found |
| 11 | 226 | 229 | FAIL-MISSING | samples/14-ownership-borrow/ownership.nim | no code line found |
| 12 | 243 | 246 | FAIL-MISSING | samples/14-ownership-borrow/ownership.nim | no code line found |
| 13 | 274 | 278 | FAIL-MISSING | samples/14-ownership-borrow/ownership.nim | no code line found |

### 15-errors-as-values

12 source blocks — FAIL-MISSING 1, FAIL-PARTIAL 5, IN 4, IN-DIFF 2.

| # | EN line | ID line | verdict | sample | note |
| --- | --- | --- | --- | --- | --- |
| 1 | 39 | 39 | IN | samples/15-errors-as-values/errors.nim | all 3 code lines present, one run in the sample |
| 2 | 47 | 47 | FAIL-PARTIAL | samples/15-errors-as-values/errors.nim | 2/5 lines present; missing: let code = classify('x'); echo "fine"; echo "rejected with ", code |
| 3 | 74 | 76 | IN | samples/15-errors-as-values/errors.nim | all 3 code lines present, one run in the sample |
| 4 | 95 | 96 | FAIL-PARTIAL | samples/15-errors-as-values/errors.nim | 2/5 lines present; missing: echo digitValue('4'); echo digitValue('z'); echo "caught ", e |
| 6 | 120 | 121 | FAIL-PARTIAL | samples/15-errors-as-values/errors.nim | 3/7 lines present; missing: f(); of KeyError: echo "key"; of Failure: echo "general failure"; else: echo "other ", e |
| 7 | 146 | 148 | IN-DIFF | samples/15-errors-as-values/errors.nim | 7/8 lines present; missing: echo "handled ", e |
| 8 | 167 | 169 | FAIL-PARTIAL | samples/15-errors-as-values/errors.nim | 1/5 lines present; missing: let n = try:; digitValue('5'); echo "defaulted after ", e; -1 |
| 10 | 189 | 191 | FAIL-PARTIAL | samples/15-errors-as-values/errors.nim | 2/6 lines present; missing: proc readIt(path: string): string =; result = ""; result = readFile(path); result = "error: " & $e |
| 11 | 206 | 208 | IN | samples/15-errors-as-values/errors.nim | all 4 code lines present, one run in the sample |
| 12 | 218 | 220 | IN | samples/15-errors-as-values/errors.nim | all 4 code lines present, one run in the sample |
| 14 | 256 | 258 | FAIL-MISSING | samples/15-errors-as-values/errors.nim | no code line found |
| 15 | 279 | 282 | IN-DIFF | samples/15-errors-as-values/errors.nim | 2/4 lines present; missing: f(); quit "fatal: " & $e |

### 16-modules-visibility

11 source blocks — FAIL-MISSING 9, IN 1, IN-DIFF 1.

| # | EN line | ID line | verdict | sample | note |
| --- | --- | --- | --- | --- | --- |
| 1 | 35 | 35 | IN-DIFF | samples/16-modules-visibility/modules.nim | 1/2 lines present; missing: import support/shapes |
| 2 | 48 | 49 | FAIL-MISSING | samples/16-modules-visibility/modules.nim | no code line found |
| 3 | 67 | 67 | FAIL-MISSING | samples/16-modules-visibility/modules.nim | no code line found |
| 5 | 99 | 99 | FAIL-MISSING | samples/16-modules-visibility/modules.nim | no code line found |
| 6 | 120 | 120 | FAIL-MISSING | samples/16-modules-visibility/modules.nim | no code line found |
| 7 | 132 | 132 | FAIL-MISSING | samples/16-modules-visibility/modules.nim | no code line found |
| 8 | 153 | 153 | FAIL-MISSING | samples/16-modules-visibility/modules.nim | no code line found |
| 9 | 185 | 189 | FAIL-MISSING | samples/16-modules-visibility/modules.nim | no code line found |
| 10 | 211 | 215 | IN | samples/16-modules-visibility/support/report.nim | all 2 code lines present, one run in the sample |
| 11 | 235 | 239 | FAIL-MISSING | samples/16-modules-visibility/modules.nim | no code line found |
| 15 | 288 | 292 | FAIL-MISSING | samples/16-modules-visibility/modules.nim | no code line found |

### 17-generics-concepts

14 source blocks — FAIL-MISSING 11, FAIL-PARTIAL 1, IN-DIFF 2.

| # | EN line | ID line | verdict | sample | note |
| --- | --- | --- | --- | --- | --- |
| 1 | 30 | 31 | FAIL-MISSING | samples/17-generics-concepts/generics.nim | no code line found |
| 2 | 40 | 41 | FAIL-MISSING | samples/17-generics-concepts/generics.nim | no code line found |
| 3 | 52 | 54 | FAIL-MISSING | samples/17-generics-concepts/generics.nim | no code line found |
| 4 | 64 | 66 | FAIL-MISSING | samples/17-generics-concepts/generics.nim | no code line found |
| 5 | 75 | 77 | FAIL-MISSING | samples/17-generics-concepts/generics.nim | no code line found |
| 6 | 86 | 88 | FAIL-MISSING | samples/17-generics-concepts/generics.nim | no code line found |
| 8 | 120 | 122 | FAIL-MISSING | samples/17-generics-concepts/generics.nim | no code line found |
| 9 | 132 | 135 | FAIL-MISSING | samples/17-generics-concepts/generics.nim | no code line found |
| 10 | 152 | 155 | IN-DIFF | samples/17-generics-concepts/generics.nim | 1/2 lines present; missing: type Addable = concept |
| 11 | 162 | 165 | IN-DIFF | samples/17-generics-concepts/generics.nim | 1/2 lines present; missing: echo twice(3) |
| 12 | 172 | 175 | FAIL-MISSING | samples/17-generics-concepts/generics.nim | no code line found |
| 14 | 211 | 213 | FAIL-PARTIAL | samples/17-generics-concepts/generics.nim | 1/6 lines present; missing: Named = concept; proc name(x: Self): string; Aged = concept of Named; proc age(x: Self): int; proc describe[T: Aged](x: T): string = name(x) & " " & $age(x) |
| 15 | 232 | 234 | FAIL-MISSING | samples/17-generics-concepts/generics.nim | no code line found |
| 16 | 264 | 265 | FAIL-MISSING | samples/17-generics-concepts/generics.nim | no code line found |

### 18-templates-compiletime

7 source blocks — FAIL-MISSING 4, IN 1, IN-DIFF 2.

| # | EN line | ID line | verdict | sample | note |
| --- | --- | --- | --- | --- | --- |
| 1 | 32 | 32 | IN-DIFF | samples/18-templates-compiletime/templates.nim | 1/2 lines present; missing: template twice(x: untyped): untyped = x + x |
| 3 | 56 | 57 | FAIL-MISSING | samples/18-templates-compiletime/templates.nim | no code line found |
| 4 | 74 | 75 | IN-DIFF | samples/18-templates-compiletime/templates.nim | 3/5 lines present; missing: echo twice(21); echo declared(acc) |
| 5 | 88 | 89 | FAIL-MISSING | samples/18-templates-compiletime/templates.nim | no code line found |
| 6 | 114 | 116 | FAIL-MISSING | samples/18-templates-compiletime/templates.nim | no code line found |
| 7 | 135 | 137 | IN | samples/18-templates-compiletime/templates.nim | all 6 code lines present, not one run in the sample |
| 8 | 204 | 209 | FAIL-MISSING | samples/18-templates-compiletime/templates.nim | no code line found |

### 19-plugins-nif

9 source blocks — FAIL-MISSING 3, FAIL-PARTIAL 1, IN 3, IN-DIFF 2.

| # | EN line | ID line | verdict | sample | note |
| --- | --- | --- | --- | --- | --- |
| 1 | 26 | 31 | FAIL-PARTIAL | samples/19-plugins-nif/plugins.nim | 1/3 lines present; missing: template generateEcho(s: string) {.plugin: "deps/mplugin1".}; generateEcho("Hello, world!") |
| 2 | 35 | 40 | IN-DIFF | samples/19-plugins-nif/deps/shape.nim | 10/11 lines present; missing: result.takeTree arg |
| 3 | 62 | 79 | IN | samples/19-plugins-nif/plugins.nim | all 5 code lines present, one run in the sample |
| 6 | 88 | 113 | FAIL-MISSING | samples/19-plugins-nif/deps/double.nim | no code line found |
| 7 | 101 | 133 | IN | samples/19-plugins-nif/plugins.nim | all 3 code lines present, one run in the sample |
| 8 | 115 | 152 | IN | samples/19-plugins-nif/deps/double.nim | all 9 code lines present, one run in the sample |
| 10 | 141 | 187 | FAIL-MISSING | samples/19-plugins-nif/deps/double.nim | no code line found |
| 11 | 156 | 206 | IN-DIFF | samples/19-plugins-nif/plugins.nim | 3/4 lines present; missing: echo "kept" |
| 16 | 214 | 291 | FAIL-MISSING | samples/19-plugins-nif/deps/double.nim | no code line found |

### 20-stdlib

4 source blocks — FAIL-MISSING 1, IN 3.

| # | EN line | ID line | verdict | sample | note |
| --- | --- | --- | --- | --- | --- |
| 1 | 36 | 37 | FAIL-MISSING | samples/20-stdlib/stdlib.nim | no code line found |
| 2 | 109 | 110 | IN | samples/20-stdlib/stdlib.nim | all 6 code lines present, one run in the sample |
| 3 | 152 | 154 | IN | samples/20-stdlib/stdlib.nim | all 2 code lines present, not one run in the sample |
| 4 | 221 | 224 | IN | samples/20-stdlib/stdlib.nim | all 6 code lines present, one run in the sample |

### 21-files-processes

3 source blocks — IN 1, IN-DIFF 2.

| # | EN line | ID line | verdict | sample | note |
| --- | --- | --- | --- | --- | --- |
| 1 | 36 | 36 | IN-DIFF | samples/21-files-processes/files.nim | 3/6 lines present; missing: import std / [syncio]; writeFile("note.txt", "first\n"); echo readFile("note.txt").len |
| 2 | 56 | 58 | IN-DIFF | samples/21-files-processes/files.nim | 3/4 lines present; missing: discard open(f, "note.txt", fmAppend) |
| 3 | 176 | 181 | IN | samples/21-files-processes/files.nim | all 5 code lines present, one run in the sample |

### 22-cinterop

9 source blocks — FAIL-MISSING 2, FAIL-PARTIAL 1, IN 6.

| # | EN line | ID line | verdict | sample | note |
| --- | --- | --- | --- | --- | --- |
| 1 | 34 | 34 | FAIL-PARTIAL | samples/22-cinterop/cinterop.nim | 1/3 lines present; missing: import std / [syncio]; echo strlen(cstring"hello") |
| 2 | 55 | 55 | FAIL-MISSING | samples/22-cinterop/cinterop.nim | no code line found |
| 3 | 83 | 83 | IN | samples/22-cinterop/cinterop.nim | all 3 code lines present, not one run in the sample |
| 4 | 94 | 93 | IN | samples/22-cinterop/cinterop.nim | all 6 code lines present, not one run in the sample |
| 5 | 123 | 123 | IN | samples/22-cinterop/cinterop.nim | all 5 code lines present, not one run in the sample |
| 6 | 142 | 142 | IN | samples/22-cinterop/cinterop.nim | all 2 code lines present, one run in the sample |
| 7 | 156 | 156 | IN | samples/22-cinterop/cinterop.nim | all 3 code lines present, not one run in the sample |
| 8 | 174 | 174 | IN | samples/22-cinterop/cinterop.nim | all 6 code lines present, one run in the sample |
| 9 | 196 | 197 | FAIL-MISSING | samples/22-cinterop/cinterop.nim | no code line found |

### 23-testing

8 source blocks — FAIL-MISSING 1, FAIL-PARTIAL 3, IN 1, IN-DIFF 3.

| # | EN line | ID line | verdict | sample | note |
| --- | --- | --- | --- | --- | --- |
| 2 | 43 | 43 | FAIL-PARTIAL | samples/23-testing/testing.nim | 1/4 lines present; missing: assert 1 + 1 == 2; assert true, "never printed"; echo "survived" |
| 4 | 72 | 72 | FAIL-PARTIAL | samples/23-testing/testing.nim | 1/5 lines present; missing: func clampPositive(x: int): int =; assert x >= 0, "negative"; x; echo clampPositive(7) |
| 5 | 93 | 93 | IN-DIFF | samples/23-testing/testing.nim | 2/3 lines present; missing: proc bump() = |
| 7 | 112 | 112 | IN | samples/23-testing/testing.nim | all 7 code lines present, one run in the sample |
| 8 | 126 | 126 | FAIL-PARTIAL | samples/23-testing/testing.nim | 1/3 lines present; missing: proc bump() =; {.cast(assumeSync).}: |
| 9 | 143 | 144 | IN-DIFF | samples/23-testing/testing.nim | 5/6 lines present; missing: check("addition", 1 + 1 == 2, checks, failures) |
| 10 | 167 | 168 | FAIL-MISSING | samples/23-testing/testing.nim | no code line found |
| 12 | 207 | 209 | IN-DIFF | samples/23-testing/testing.nim | 1/2 lines present; missing: echo assertionsEnabled |

### 24-passive-procs

7 source blocks — FAIL-MISSING 1, FAIL-PARTIAL 3, IN-DIFF 3.

| # | EN line | ID line | verdict | sample | note |
| --- | --- | --- | --- | --- | --- |
| 1 | 37 | 38 | IN-DIFF | samples/24-passive-procs/passive.nim | 3/4 lines present; missing: echo double(21) |
| 2 | 53 | 55 | FAIL-MISSING | samples/24-passive-procs/passive.nim | no code line found |
| 4 | 82 | 83 | FAIL-PARTIAL | samples/24-passive-procs/passive.nim | 1/3 lines present; missing: let c = delay(solo("a")); complete(c) |
| 6 | 115 | 116 | FAIL-PARTIAL | samples/24-passive-procs/passive.nim | 1/6 lines present; missing: var resumeCont: Continuation; proc worker(name: string) {.passive.} =; echo "start ", name; resumeCont = delay(); echo "resumed ", name |
| 8 | 156 | 158 | IN-DIFF | samples/24-passive-procs/passive.nim | 5/8 lines present; missing: drive(delay(worker("a"))); echo "parked"; drive(resumeCont) |
| 10 | 190 | 193 | IN-DIFF | samples/24-passive-procs/passive.nim | 3/5 lines present; missing: drive(delay(worker("a", 0))); drive(delay(worker("b", 1))) |
| 12 | 226 | 229 | FAIL-PARTIAL | samples/24-passive-procs/passive.nim | 1/12 lines present; missing: proc inner() {.passive.} =; echo "inner 1"; innerCont = delay(); echo "inner 2"; proc outer() {.passive.} =; echo "outer 1"; inner(); echo "outer 2" |

## Copyable differences (`IN-DIFF`)

These 47 blocks have at least half their code lines in the sample, but none of them is the sample: a reader who
copies one writes a program the verifier never ran, and no chapter says the listing is an excerpt. The table
names the lines that are on the page and not in the file. Most fall into five shapes:

- **a dropped statement**, usually the `echo` that produces the output block under the listing: `07:31` prints
  `echo i` where the sample prints `echo "incl ", i`; `08:199` drops `echo n`; `15:146` drops
  `echo "handled ", e`; `23:143` drops the `check(...)` call that is the point of the block.
- **a changed literal or annotation**: `04:62` declares `var top = 9223372036854775807'i64` where the sample has
  `var top: int64 = 9223372036854775807'i64`.
- **a renamed type or parameter**: `12:65` calls the enum `Kind` where the sample calls it `ShapeKind`; `09:302`
  writes `func `[]`(x: Container, i: int)` where the sample writes `c: Container`.
- **a different import form**: `16:35` writes `import support/shapes` where the sample writes
  `from support/shapes import nil`. Both compile; only one is the file the verifier ran, and the chapter is
  about that difference.
- **a different declaration or implementation**: `18:32` shows `template twice(x: untyped): untyped = x + x`
  where the sample's `twice` binds `acc` and adds it to itself; `11:287` writes the body of `+` for `Meters`
  where the sample borrows the base operator with `{.borrow.}`. Same name, different code a reader would copy.

| Chapter | EN line | ID line | line(s) in the book that the sample does not have |
| --- | --- | --- | --- |
| 04-numbers-types-conversion | 62 | 63 | `var top = 9223372036854775807'i64` |
| 04-numbers-types-conversion | 100 | 101 | `echo 6 / 2` |
| 05-strings | 55 | 56 | `line.add "values"` |
| 05-strings | 109 | 111 | `echo "abc"[2..1]` |
| 05-strings | 277 | 279 | `echo "alpha".toUpperAscii()`; `echo " pad ".strip()`; `echo "a-b-c".replace("-", "+")` |
| 07-loops-ranges | 31 | 31 | `echo i` |
| 07-loops-ranges | 58 | 58 | `echo seen` |
| 07-loops-ranges | 103 | 103 | `echo i` |
| 07-loops-ranges | 120 | 120 | `echo i, " ", word[i]` |
| 07-loops-ranges | 156 | 156 | `echo i` |
| 07-loops-ranges | 190 | 190 | `echo c` |
| 07-loops-ranges | 234 | 234 | `echo i` |
| 08-procedures | 179 | 184 | `echo pad(width = 2, n = 7)` |
| 08-procedures | 199 | 204 | `echo n` |
| 08-procedures | 225 | 230 | `echo q, " ", r` |
| 08-procedures | 253 | 258 | `echo t[0], " ", t[1]` |
| 08-procedures | 322 | 328 | `add(1, 2)` |
| 08-procedures | 381 | 389 | `echo later(4)` |
| 09-overloading-and-ufcs | 201 | 207 | `echo 1.wrap("a")` |
| 09-overloading-and-ufcs | 302 | 307 | `func `[]`(x: Container, i: int): var int = x.data[i]` |
| 10-arrays-sequences-tuples | 114 | 116 | `for x in row:` |
| 10-arrays-sequences-tuples | 136 | 138 | `echo row[0]` |
| 10-arrays-sequences-tuples | 163 | 165 | `echo counts.len`; `echo counts.high` |
| 10-arrays-sequences-tuples | 362 | 366 | `var xs = @[1, 2, 3, 4]` |
| 10-arrays-sequences-tuples | 379 | 383 | `let xs = @[1, 2, 3, 4]`; `echo xs[0..<2].len` |
| 11-objects-enums-distinct | 47 | 48 | `echo Point(x: 1).y` |
| 11-objects-enums-distinct | 90 | 90 | `var a = Bag(items: @[1, 2])` |
| 11-objects-enums-distinct | 287 | 289 | `func `+`(lhs, rhs: Meters): Meters = Meters(int(lhs) + int(rhs))`; `echo $Meters(4)` |
| 12-sum-types-case | 65 | 65 | `Kind = enum Circle, Rectangle, Triangle`; `case kind: Kind` |
| 13-references-pointers-nil | 208 | 205 | `proc boxedNotNil(v: int): ref int =`; `var tmp: ref int` |
| 15-errors-as-values | 146 | 148 | `echo "handled ", e` |
| 15-errors-as-values | 279 | 282 | `f()`; `quit "fatal: " & $e` |
| 16-modules-visibility | 35 | 35 | `import support/shapes` |
| 17-generics-concepts | 152 | 155 | `type Addable = concept` |
| 17-generics-concepts | 162 | 165 | `echo twice(3)` |
| 18-templates-compiletime | 32 | 32 | `template twice(x: untyped): untyped = x + x` |
| 18-templates-compiletime | 74 | 75 | `echo twice(21)`; `echo declared(acc)` |
| 19-plugins-nif | 35 | 40 | `result.takeTree arg` |
| 19-plugins-nif | 156 | 206 | `echo "kept"` |
| 21-files-processes | 36 | 36 | `import std / [syncio]`; `writeFile("note.txt", "first\n")`; `echo readFile("note.txt").len` |
| 21-files-processes | 56 | 58 | `discard open(f, "note.txt", fmAppend)` |
| 23-testing | 93 | 93 | `proc bump() =` |
| 23-testing | 143 | 144 | `check("addition", 1 + 1 == 2, checks, failures)` |
| 23-testing | 207 | 209 | `echo assertionsEnabled` |
| 24-passive-procs | 37 | 38 | `echo double(21)` |
| 24-passive-procs | 156 | 158 | `drive(delay(worker("a")))`; `echo "parked"`; `drive(resumeCont)` |
| 24-passive-procs | 190 | 193 | `drive(delay(worker("a", 0)))`; `drive(delay(worker("b", 1)))` |

## Does rule 3 need narrowing?

**Yes.** Rule 3 describes a gate this repository does not have and, at this shape, cannot have. Three facts
decide it.

**1. The gate runs 23 programs, not 272 files.** `tools/verify-samples.sh` globs `samples/*/*.nim`, compiles and
runs each with `nimony c -r`, and reports `PASS` only on exit status 0; there are 23 such files, one per chapter
2–24. `./task verify` refuses a green run only when the whole tree has no sample at all (`task:55-62`), and no
tool in `tools/` reads a chapter, finds its fenced blocks, or checks them against a sample. A block "has a file"
only in the sense that its chapter has one program.

**2. The samples are parallel programs, not supersets of the page.** Chapter 7's sample prints
`echo "incl ", i`; the page prints `echo i` and shows `0 1 2 3` under it. The sample proves that the construct
compiles and runs; the page's output block is matched by the editor and the reviewer, which
`CHAPTER_TEMPLATE.md:89` states outright: "The verifier checks compile, run and exit code only. It does not
compare stdout." So even a block whose lines are all in the sample is usually reworded there, and a rule that
says every block is *the* sample overstates the gate by design. The template's own definition of done is per
sample, not per block: "**Samples run.** Every sample compiles and runs at `nimony_commit`"
(`CHAPTER_TEMPLATE.md:67-69`), and the frontmatter field it points at is a list of paths, not a mapping from
blocks.

**3. 58 listings are invalid on purpose.** Each edition has 58 fenced compiler diagnostics, each the answer to a
listing directly above it: a `let` reassigned, an ambiguous call, a `case` missing a branch, a borrow that
escapes. The verifier fails any program that exits non-zero, so those listings can never live under `samples/`.
Rule 3 as written has no legal home for them.

**Chapter 1.** `chapters/01-what-nimony-is/{en,id}.md` contain zero fenced blocks and the chapter carries
`samples: []`. Rule 3 is vacuously true there; a sample file would have to invent code the chapter does not show,
and a reviewer should not ask for one. The single-file-per-chapter shape is right for Chapters 2–24 and simply
does not apply to Chapter 1. The rule should say that instead of leaving it to inference.

**Appendices A–C.** A1 and A3 contain zero fenced blocks. A2 has three: the `./task verify` command and two
copies of the verifier's output. None is Nimony source; a sample for A2 would be a program the appendix never
shows, and it would make the record of the gate depend on the gate. Exempt.

**Proposed wording.** Replace rule 3 with:

```
3. Every Nimony listing that is meant to compile has a home in the chapter's sample: it appears in the file
   the verifier runs, or the prose says it is an excerpt and where the whole is. Fragments, before/after
   shapes and listings whose point is the diagnostic are marked as such where they appear and never added to
   samples/ — the verifier fails any program that exits non-zero. A chapter with no Nimony code carries
   `samples: []` and no sample file.
```

That keeps what the rule is for — a block nobody compiled is prose — while matching what the tools can enforce
and giving the invalid listings a legal home.

**If the owners keep the rule as written**, the bill is 190 blocks: 47 to reconcile line by line and 143 to
write samples for. Fifty-eight listings in each edition exist only to produce a diagnostic, and the verifier
fails any sample that exits non-zero, so no sample can be written for those under the rule as it stands. That is
a redesign of the gate, not a review fix. Narrowing the sentence is the cheaper correct change.

**One more defect in the rule's path pattern.** `samples/NN-slug/` is not the directory for Chapter 9: its
sample is `samples/09-overloading/`. And the verifier's `samples/*/*.nim` glob does not run the support modules
under `samples/16-modules-visibility/support/` or `samples/19-plugins-nif/deps/`; they compile only through the
program that imports them. If the rule keeps a path pattern, it should be `samples/NN-*/`.

## What this audit did not check

- Whether a block compiles or prints what the page says. `2026-11-13-code-block-coverage.md` re-ran the printed
  pairs at the pin; this file only asks whether the code is in the sample.
- Whether the samples exercise every construct a chapter teaches. Coverage here runs one way: block to sample.
- The Indonesian prose. The code is identical in both editions for every source pair, so only the EN prose is
  quoted; the ID line numbers are given so a reader can check the same block in `id.md`.
- Whether any block was changed after its sample last ran. The repository is frozen and `./task verify` was
  green today at `23/23`, which is the evidence the samples still run; it says nothing about the 190 blocks that
  are not in them.

Method, for reproduction: a throwaway extraction script outside the repository read each `en.md` and `id.md`,
paired fences by index, dropped comment-only and blank lines, normalised whitespace, stripped trailing comments
outside string literals, and searched the chapter's `samples/NN-*/*.nim` files (`nimcache/` excluded) for each
code line. No chapter, sample or tool file was modified for this audit.
