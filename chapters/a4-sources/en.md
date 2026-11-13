---
appendix: D
title: Sources and references
job: Name the sources this book cites, in the form its own pages cite them, so a reader can check a claim at its source instead of trusting the page.
nimony_version: 0.6.3
nimony_commit: 4ba90a781b0b22d0821efaa153c129c37cef6143
toolchain: ~/.local/opt/nimony/4ba90a7
host_compiler: ~/.local/opt/nim-2.4.0
status: frozen
tech_review: lists sources and their locations; describes no compiler behaviour
editorial_pass: 2026-11-13
samples: []
glossary_added: ["references", "daftar pustaka"]
---

# Sources and references

## What this appendix lists

A sentence in this book rests on one of three things: what the pinned compiler does, what Nim 2 did instead, or a
decision the book makes about its own shape. The first two are checkable by anyone with the repository and one
download. The third is written down in `OUTLINE.md` and `ERRATA.md`. This appendix names the sources once, so a
reader who doubts a page does not have to reconstruct where the page came from.

## How the book cites

A claim about the language carries a path and a line range, relative to the root of the compiler's repository at
the pin: `doc/language.md:126-140`, `src/nimony/sem.nim:3305`, `lib/std/system.nim:123-126`. The address of one
citation is the tree at that commit, then the path, then the range:

`https://github.com/nim-lang/nimony/blob/4ba90a781b0b22d0821efaa153c129c37cef6143/doc/language.md#L126-L140`

The compiler prints only the short form, `4ba90a7`. The full hash is in every chapter's frontmatter as
`nimony_commit`, and it is the one that appears in these addresses.

Two limits belong on the same page as the convention:

- The audit behind this edition checked that every cited path exists at the pin and every range falls inside its
  file. It did not check that the line supports the sentence drawing on it. That is the job of the per-chapter
  `review.md` probe table, which prints what was run and what came back, one row per claim.
- A citation is not a quotation. The book paraphrases the reference and quotes the compiler. A chapter's evidence
  is therefore the output block and the citation together, never the citation alone.

## The pinned compiler

| Item | Value |
| --- | --- |
| Repository | `https://github.com/nim-lang/nimony` |
| Commit | `4ba90a781b0b22d0821efaa153c129c37cef6143`, 2026-11-12 |
| Version | `nimony 0.6.3`, as the compiler reports itself |
| Backend | `nimony c`; `nimony n` does not exist at this commit |
| Licence | MIT, the `LICENSE` file at that commit |

The sources inside that tree, ordered by how often the chapters lean on them. The count is `path:line`
citations in the English edition of Chapters 1 to 24, taken on 2026-11-13.

| Source | What it is | Where the book leans on it |
| --- | --- | --- |
| `doc/language.md` | The language reference shipped with the compiler; 149 citations | The description most chapters start from, before a sample or a probe confirms or corrects it |
| `lib/std/system.nim` | `system`, including the hooks `move` and `=wasMoved` are built from; 32 citations | Chapters 3, 14 and 20, and the moved-from state Chapter 14 teaches |
| `doc/differences.md` | Everything removed or changed from Nim 2; 25 citations | Every "Nim 2 delta" box, and the rows of Appendix A |
| `src/nimony/sem.nim` | The semantic pass; 21 citations | Where a chapter explains a refusal the reference does not, such as the `elif` rule in Chapter 6 |
| `src/nimony/contracts_fir.nim` | The analysis behind definite assignment and the checked contracts; 19 citations | Chapters 8, 15 and 24 |
| `lib/std/syncio.nim` | The output layer `echo` and `quit` go through; 17 citations | Chapter 21's `quit(msg)` row, where the pin writes stdout and `doc/stdlib.md` says stderr |
| `doc/porting.md` | Porting notes for code arriving from Nim 2; 8 citations | Chapters 11, 15 and 18 |
| `doc/plugins.md` | The plugin interface; 8 citations | Chapter 19 |

Every other path in a chapter appears for one question and is named where the question is: `sizeof.nim` for the
variant layout in Chapter 12, `duplifier.nim` for the last-usage check in Chapter 14, `tables.nim` for the hash
map in Chapter 20, `unicode.nim` for runes in Chapter 5. Where the reference and the compiler disagree, the
chapter says so and `ERRATA.md` carries the row.

## The host compiler

| Item | Value |
| --- | --- |
| Compiler | Nim 2.4.0, official tarball |
| Download | `https://nim-lang.org/download/nim-2.4.0-macosx_arm64.tar.xz` |
| sha256 | `93a1e638289077b972b684e6e71cb11b2029602ccac4f8fd8dfa70f193fac7df` |
| Role | Contrast only |

Nim 2.4.0 is never a source for what Nimony does. It is the thing the "Nim 2 delta" boxes compare against, and
the compiler whose messages Appendix A quotes on the other side of each row. Where the two disagree, the pin is
the answer and the host compiler is the observation.

## Upstream issues

| Reference | Kind | What it records |
| --- | --- | --- |
| `nim-lang/nimony#2985` | Issue, filed and closed 2026-11-13 | A `delay()` with no following suspension point hits an assert in `cps.nim` instead of producing a diagnostic |
| `nim-lang/nimony#2988` | Pull request, merged 2026-11-13 | The fix in `#2985`: the assert becomes a call-site diagnostic |

Chapter 24 quotes the assert the issue is about, Appendix A and Appendix C name the pair, and the chapter's
`review.md` records the reproduction. Both links resolve at
`https://github.com/nim-lang/nimony/issues/2985` and `https://github.com/nim-lang/nimony/pull/2988`.

## Standards named in the text

IEEE 754 is the one external standard the book names. Chapter 4 says `float` and `float64` follow it and that the
IEEE exceptions are not raised at the pin; the book quotes no clause from the standard and pins no revision of it.
Where a chapter could have cited a document outside the repository, it cites the thing the sample actually meets
instead: Chapter 22 names the C headers it imports from — `<string.h>`, `<stdio.h>`, `<sys/types.h>` — because
the compiler writes a declaration from them and the sample would not link without them.

## The book's own record

| Path in this repository | What it holds |
| --- | --- |
| `OUTLINE.md` | The book's contract: reader, pin, one job per chapter, prerequisites, and the status of every chapter |
| `ERRATA.md` | Open errata, the watch list of pin-level constraints, and the editorial corrections made to frozen chapters |
| `samples/` | One program per chapter, compiled and run at the pin; Appendix B records the gate |
| `chapters/NN-slug/review.md` | The claim-by-claim probe table behind a chapter: what was run, the raw output, the source line |
| `reviews/2026-11-13-*.md` | The whole-book reviews behind `v0.1.21`: editorial, technical, sample coverage, listing coverage, terminology |
| `tools/verify-samples.sh` | The verifier every sample passes through, and the only thing this book calls green |

## Licences

| Material | Licence | Where it is stated |
| --- | --- | --- |
| The text of this book, both editions | CC BY-SA 4.0 | `LICENSE`, and `https://creativecommons.org/licenses/by-sa/4.0/` |
| The code in `samples/` and in every listing | MIT | `LICENSE-CODE`, and `https://opensource.org/license/mit` |
| Quoted compiler source and output | MIT, the licence of Nimony at the pin | Named by file and line at each quotation; the full text is the pin's `LICENSE` |

Source excerpts are quoted by file and line so the reader can compare them with the commit, and compiler output is
quoted as output. Neither is redistributed here as a file.

## How the pages are built

Both editions render from the same sources through Quarto 1.10.19, the version the build refuses to substitute,
with a Typst template in `assets/typst/`. The toolchain for the samples is the one in Appendix B. A page that
prints a version number or a commit states it where it matters rather than here.
