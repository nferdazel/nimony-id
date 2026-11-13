# Technical audit, 2026-11-13

Compiler-level truth and quoted-output fidelity for the whole book at `v0.1.18`, repository HEAD `63eeff8`, pin
`4ba90a781b0b22d0821efaa153c129c37cef6143` (`nimony 0.6.3`). This is the audit the whole-book review handed to
Momo; editorial findings are in `2026-11-13-whole-book.md` and are not repeated here.

Verdict: the technical claims that were re-run still hold. Nothing in the book was found false by this audit. Two
defects are in this file — one broken pointer in the appendices, one missing sentence in Chapter 23 — and the rest
of the quoted diagnostics are *not proven*, not cleared.

## What was re-run

```
bash tools/verify-samples.sh
SUMMARY 23/23 passed, 0 failed
```

Every `$ nimony ...` transcript in the book, re-executed from the repository root and diffed line by line
(`audit-transcripts.py`): **12 of 13 byte-exact**. The thirteenth is Chapter 2's `nimony c -r hello.nim`, which
the chapter asks the reader to write in a scratch directory; run that way it prints `hello, world`, so the block
is right and simply not reproducible from the repository root as written.

Every source citation that carries a line number, resolved against the pin (`audit-citations.py`): **469
citations across 75 distinct source files, 0 missing files, 0 line ranges outside the file**. That check proves
the citations point at real, existing lines; it does not prove the sentence belongs to those lines.

`deviations` of the Indonesian edition: the compiler messages quoted in `id.md` are byte-identical to `en.md` in
all 27 folders — no diagnostic was translated, which is what a reader needs to match a message to their own run.

Sixteen of the distinct `Error:`/`Warning:` strings the book quotes were compiled again at the pin and matched
exactly, covering Chapters 3, 4, 5, 6, 10, 14, 15, 23 and 24. The ones that carry the most weight:

| Book | Re-run at the pin |
| --- | --- |
| `attempt to redeclare: step` (Ch 3) | `redeclare.nim(2, 5) Error: attempt to redeclare: step` |
| `expression overflow at compile time: 127'i8 + 1'i8` (Ch 4) | identical, plus source position |
| `value out of range: 10 notin 0..9` (Ch 4) | identical, plus source position |
| `expected: char but got: int64` (Ch 5) | one line of the three-overload mismatch list, verbatim |
| `not all cases are covered; missing: {blue}` (Ch 6) | identical, plus source position |
| `invalid array index type: n` (Ch 10) | identical, plus source position |
| `cannot mutate expression a[0]` (Ch 10) | identical, reported inside `lib/std/system.nim` |
| `'s' is borrowed and cannot be mutated` (Ch 14) | identical, at the `for` loop's call site |
| `mutable argument aliases with mutable parameter` (Ch 14) | fires on `swap(x, x)`; `swap(p.x, p.y)` runs and prints `2 1`, as the chapter says |
| `not the last usage of: a` (Ch 14) | identical, at the `echo a` after `ensureMove` |
| `expression of type \`ErrorCode\` must be discarded` (Ch 15) | identical, plus source position |
| `undeclared field: 'msg' for type ErrorCode` (Ch 15) | identical |
| `Type mismatch at [position]` for `assert 1` (Ch 23) | identical, and the `[1] expected: bool but got: int64 (declared in …/assertions.nim(23, 1))` line is byte-identical |
| the four-flag assertion table (Ch 23) | `none` and `-d:release` print `[Assertion Failure]` and exit 1; `-d:danger` and `-d:noAssertions` print `not reached` and exit 0. `assertionsEnabled` prints `true true false false` |
| `{.assert: …}` in the routine-pragma position (Ch 23) | crashes with the quoted `nifcore.nim(1875, 3) … closeTag with no matching openTag` |
| `cps.nim:269` (Ch 24) | `Error: unhandled exception: cps.nim(269, 5) \`state != -1\` delay() no-arg must precede suspension point [AssertionDefect]` |

## Findings

### 1. Appendices A and B point at a `review.md` that seven chapters do not have — medium

`chapters/a1-nim2-delta-table/en.md:28` and `chapters/a2-sample-verification-record/en.md:141` both tell the
reader that the chapter's `review.md` holds the probe behind the claim. The public repository carries 17
`chapters/*/review.md`: Chapters 1–17. Chapters 18–24 have none, and never had one in this repository's history
(`git log --all -- chapters/18-templates-compiletime/review.md` is empty).

The seven files exist in the authoring mirror at `~/.openmausbot/product/books/nimony-id`, which is at `0.1.17`
and is not the source of truth. So an appendix in the released book promises a file the reader cannot open, for
29% of the chapters. Fix: commit the seven artifacts with their machine paths written home-relative, as the other
fourteen now are, or reword both lines to say the reviews exist for Chapters 1–17. Owner: Aksara.

### 2. Chapter 23 says `{.assert.}` as a statement is accepted, without saying it must be provable — low-medium

`chapters/23-testing/en.md:176-177` reads: "As a statement inside a body it is accepted, which is the form
`tests/nimony/contracts/tassertpragma.nim` exercises." The position claim is true, but acceptance is conditional
on the prover discharging the claim:

```
$ nimony c -r half.nim
half.nim(5, 5) Error: cannot prove assertion: x mod 2 == 0 [pass --verbose for the Final IR]
```

with `proc half(x: int): int = {.assert: x mod 2 == 0.}` and `half(4)`. The cited test passes only because every
assertion in it is guarded by a condition the prover can use (`if i >= 0 and i < s.len:` before
`{.assert: i + 1 <= s.len.}`). A reader who copies the sentence gets a hard compile error on the first try. One
sentence fixes it: the statement form is accepted *and the claim must be provable there*, which is why the test's
assertions sit behind guards. Owner: Aksara applies, wording by Momo; it is a text change to a frozen chapter, so
it needs an ERRATA row like the Chapter 23 corrections before it.

### 3. Watch row stands: `cps.nim:269` is still a compiler assert at the pin

Reproduced verbatim today, quoted above. The fix is `nim-lang/nimony#2988`, open and unmerged; the book's pin is
unchanged and Chapter 24 keeps quoting the assert. No action for the book.

## Not proven by this audit

Stated plainly, because "23/23 passed" is a much smaller claim than "every technical claim is true":

- **64 of the 81 distinct quoted diagnostics were not re-run.** The unverified ones sit in Chapters 2, 7, 8, 9,
  11, 12, 13, 16, 17, 18, 19, 20, 21 and 22. They are cited to a source line that exists; they were not compiled.
- **The 469 citation ranges were checked for existence, not read.** A range can be in bounds and still have
  drifted from the sentence it supports. Only the passages named in the table above were confirmed against the
  cited lines.
- **The per-chapter probe tables inside the 17 `review.md` files were not re-executed.** Those tables are the
  original evidence for the claims this audit only sampled.
- Nim 2.4.0 columns of the delta table were not re-measured; this audit ran the pin only.

## Artifacts

Scripts behind the numbers, outside the repository:
`~/.openmausbot/workspaces/49df9f87-8857-46c0-b9b8-8f066a10a55e/audit-citations.py`,
`audit-transcripts.py`, `audit-output.py`, `probe-diags.sh`, and the compiled probes under `probe/` and `probe2/`.
