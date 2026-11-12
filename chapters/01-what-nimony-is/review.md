# Chapter 1 — review record

Pin: `4ba90a781b0b22d0821efaa153c129c37cef6143` (`0.6.3`).
Samples: none. Chapter 1 is claims-only, so gate 2 (samples run) is satisfied by an empty list, not by a build.

## Technical review — Momo, 2026-11-12

Ten claims submitted, ten answered. Eight PASS, two corrected in `en.md` before this note was written.

| # | Claim | Verdict | Where the evidence lives |
| --- | --- | --- | --- |
| 1 | Nimony is the work-in-progress implementation for Nim 3; Nim 3 = Nimony plus compatibility work not yet done | PASS | `doc/differences.md:3`; website FAQ (read 2026-11-12) |
| 2 | NIF is read and written by every pipeline stage; transformations without recursion; plugins incremental and parallel | CORRECTED (wording) | `doc/design.md`; nim-lang.org/araq/nimony.html, dated 2025-05-10, written as intent |
| 3 | New `case`-inside-`object` syntax enables built-in pattern matching | PASS | `doc/differences.md:7` |
| 4 | `async` → `passive`, `await` → nothing, one model for event loop and threads | PASS | `doc/differences.md:8-11`; `README.md`; `passive` present in `src/hexer/coro_transform.nim` |
| 5 | `func`/`iterator`/`converter` side-effect free by default, `proc` not, no inference | PASS | `doc/differences.md`, side-effect block |
| 6 | One polymorphic accessor replaces the `var`/non-`var` `[]` pair | PASS | `doc/differences.md:41-44` |
| 7 | `{.feature: "ignoreStyle".}`, `{.feature: "anonBlockBreaks".}`, `{.keepOverflowFlag.}` — spelling, scope, effect | CORRECTED (wording) | `features.nim`; `sempragmas.nim:1457`; `doc/language.md:90-98` |
| 8 | `string` lost its terminating zero, no `cstring` conversion without a copy | PASS | `doc/differences.md:15` |
| 9 | Missing at pin: `ErrorCode` instead of exceptions, `tags`/`gcsafe` ignored, `raises: []`, no closure iterators, no implicit generics | PASS | `doc/differences.md:55-71` |
| 10 | Macros and multi-methods "gone permanently" | NOT PROVEN AT PIN | `doc/differences.md:19-20` sits under *The Future*; `doc/language.md:4862`; live `macro` and two-parameter `method` dispatch test |

## What changed in `en.md` because of the review

1. **NIF (claim 2).** "tree format" → "interchange format", with `doc/design.md`'s "format used to communicate
   between compiler phases" and the streams-of-tokens phrasing. The recursion and parallel-plugin sentences are
   now labelled as the design page's argument, with its 2025-05-10 date and future tense named.
2. **Escape hatches (claim 7).** The blanket "each has a documented escape hatch" is gone. The text now says two
   of the four changes have a per-module restore switch, `string` has none, and `{.keepOverflowFlag.}` is a
   detection block for `overflowFlag()`, not a compatibility mode.
3. **Macros and multi-methods (claim 10).** "gone permanently" is gone. The replacement paragraph states that
   the design moves away from both, that `macro` and `method` still compile and run for Nim 2 compatibility, that
   the book teaches plugins and procs, and that only `typed` plugin parameters receive semantically checked NIF.
4. **Section lead-in.** Because six of the seven teaching claims come from the *Future* half of the differences
   document, the lead-in now says each chapter re-proves its claim at the pin, which is what `tech_review` records.

Knock-on edits outside the chapter, so the book does not hold two versions of the same fact:
`GLOSSARY.md` (macro and multi-methods state columns), `OUTLINE.md` (What this book is not; Chapters 18 and 19
delta lines), `ERRATA.md` (two watch-list rows: Future-versus-Present sourcing, and the design page's tense).

## Closed before freeze — 2026-11-12

- Gate 5, both languages: `id.md` written 2026-11-12 with the same frontmatter and the same (empty) sample
  list, mirroring `en.md` including the Nim 2 delta box.
- Gate 4, editorial pass 2026-11-12: the five introduced terms (NIF, plugin, passive proc, polymorphic
  accessor, `ErrorCode`) are all in `GLOSSARY.md`; the delta box is present because `OUTLINE.md` marks this
  chapter `Nim 2 delta: yes`, and it uses the fixed shape; no reference to nim-id anywhere in the chapter; the
  Indonesian address form "kamu" is recorded in `DEVIATIONS.md` #6.
- Chapter frozen 2026-11-12. A break found on a newer pin goes to `ERRATA.md`; the text is not rewritten.
