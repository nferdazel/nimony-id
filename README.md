# nimony-id — book folder

Editorial home of the Nimony book. This folder is the book's plan and manuscript; it is never inside a
project repository, and no chapter work happens outside it.

## Files

| File | What it is |
| --- | --- |
| `OUTLINE.md` | The contract for this book: reader, pin, language policy, 24 chapters with one job each, prerequisites, status. |
| `CHAPTER_TEMPLATE.md` | Frontmatter, section order, and the six gates a chapter must pass before `frozen`. |
| `GLOSSARY.md` | Every term used with a special meaning, plus the terms Nimony retired. |
| `ERRATA.md` | Breaks found after a chapter froze; plus the watch list of known pin-level constraints. |
| `DEVIATIONS.md` | Every place this book departs from the nim-id writing baseline. |
| `chapters/` | One folder per chapter: `NN-slug/en.md` and `NN-slug/id.md`. Created with the first drafted chapter. |
| `index.en.qmd`, `index.id.qmd` | The book's preface, one file per edition, same shape and the same pin statement. The Indonesian file is a translation, not a second preface. |

## Where the rules come from

- Editorial contract: `/Users/sachiel/.openmausbot/product/specs/nimony-id/2026-11-12-nimony-book-editorial-contract.md`
- Chapter sequences cites, structure and terminology: this folder.
- Technical truth: Engineering's review, named per chapter. Toolchain pin: `4ba90a7`, `nimony 0.6.3`, `nimony c` only.

## Status

Four chapters are frozen at pin `4ba90a7` (`nimony 0.6.3`), each with `en.md` and `id.md`:

- Chapter 1, `chapters/01-what-nimony-is/` — draft 2026-11-12, tech_review Momo 2026-11-12,
  editorial_pass 2026-11-12. No code samples; the compile gate does not apply.
- Chapter 2, `chapters/02-the-pinned-toolchain/` — same dates, with `samples/02-pinned-toolchain/hello.nim`
  proven by `tools/verify-samples.sh`.
- Chapter 3, `chapters/03-values-names-mutability/` — same dates, with
  `samples/03-values-names-mutability/values.nim`. Its review corrected the initialization rule: a module-level
  `var` is zeroed, a local must be proven written.
- Chapter 4, `chapters/04-numbers-types-conversion/` — same dates, with
  `samples/04-numbers-types-conversion/numbers.nim`. Its review corrected the `toInt`/`toFloat` claim (they exist
  only for `Rational[T]` at the pin) and recorded signed narrowing as intended, documented as a guide gap.

The verifier prints `SUMMARY 3/3 passed, 0 failed` because chapters 2, 3 and 4 each own a sample.

Chapters 5 onwards: `planned`. A chapter with an open **Proof gate** line in `OUTLINE.md` does not draft; a chapter
without one may.
