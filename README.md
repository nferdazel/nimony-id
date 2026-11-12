# nimony-id — book folder

Editorial home of the Nimony book. This folder is the book's plan and manuscript; it is never inside a
project repository, and no chapter work happens outside it.

**Title:** *Nimony: A Pinned Guide* — *Learning the language against one fixed commit*. Decided 2026-11-12 by
the editor on the owner's delegation. The title stays English in both editions (it is a label, not prose); it
lives in `_quarto.yml` as `book.title` and `book.subtitle`.

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
| `CONTRIBUTING.md` | What a reader can send, the gate before sending it, and how a chapter change reaches `frozen`. |
| `SECURITY.md` | What counts as a security report in a book repository, and what to send to Nimony instead. |
| `LICENSE`, `LICENSE-CODE` | Book text is CC BY-SA 4.0; samples, `task` and `tools/` are MIT. |
| `VERSION` | The book's version. `./task release` bumps it and tags the commit; CI refuses a tag that does not match it. |
| `site/` | The published site's root page: it offers the two editions. Copied into the release root at deploy. |
| `.github/` | The CI workflow, Dependabot for the action pins, a pull-request checklist, and two issue forms: errata and chapter proposal. |

## The published site

Both editions are served from Cloudflare at <https://nimony.qouver.com>. The origin is the VPS, not GitHub
Pages: a webhook on push to `main` calls `ops/scripts/deploy-static.sh`, which renders both editions and
publishes them to `/srv/qouver/apps/nimony-id/releases/<sha>` with a `web` symlink that Caddy reads. `/en/` is
the English edition, `/id/` the Indonesian, and `/` is `site/index.html`, copied into the release root. A pull
request cannot reach the deploy script.

Anything published there is a render of `main`. The deploy runs `./task build` — both editions, and it fails
closed on an unpaired chapter. The sample gate is the separate `ci.yml`, which runs on every pull request and
push. The DNS A record already points at the VPS; the Caddy block is mirrored in
`ops/caddy/Caddyfile.nimony-id.example`, so nothing in this repository touches DNS.

## Where the rules come from

- Editorial contract: private, held by the editor (2026-11-12). The parts a contributor needs — one job per
  chapter, the six gates, the terminology rule — are in `OUTLINE.md`, `CHAPTER_TEMPLATE.md` and `CONTRIBUTING.md`.
- Chapter sequences cites, structure and terminology: this folder.
- Technical truth: Engineering's review, named per chapter. Toolchain pin: `4ba90a7`, `nimony 0.6.3`, `nimony c` only.

## Status

Eight chapters are frozen at pin `4ba90a7` (`nimony 0.6.3`), each with `en.md` and `id.md`:

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

- Chapter 5, `chapters/05-strings/` — same dates, with `samples/05-strings/strings.nim`. Its review corrected the
  rune claim (the pin does ship `std/unicode`'s `runes` and `runeLen`), tightened four citations, restored the
  `ensureTerminatingZero` excerpt verbatim, and recorded the `$c`-needs-`strutils` gap as a guide gap.
- Chapter 6, `chapters/06-branching/` — same dates, with `samples/06-branching/branching.nim`. Its review kept all
  24 claims and corrected one mechanism: an unmatched string `case` **expression** executes the last `of` branch
  as its fallback, side effects included — a defect at the pin, so the chapter requires `else` on every string
  `case` expression. The `elif`-in-`case` rejection also produces a third error line with an ordinal selector.

The verifier prints `SUMMARY 7/7 passed, 0 failed` (samples 02–08).

- Chapter 7, `chapters/07-loops-ranges/` — draft 2026-11-12, tech_review Momo 2026-11-12, editorial_pass
  2026-11-12. With `samples/07-loops-ranges/loops.nim`. Its review corrected two claims: `countup` takes
  `step: Positive` while `countdown` takes an unconstrained ordinal step (a negative step climbs away from `b`),
  and `n + 0` after a guard needs no new proof — `n + 1` does, because it outruns the guard's bound. Three
  findings of record live in `ERRATA.md`: the loop variable is writable and moves the counter, a stored `0..3`
  slice is not loop-iterable, and an `in 0..9` guard does not prove a `range` on a procedure parameter while two
  comparisons do.

- Chapter 8, `chapters/08-procedures/` — draft 2026-11-12, tech_review Momo 2026-11-12, editorial_pass
  2026-11-12. With `samples/08-procedures/procedures.nim`. Its review held 27 of 30 claims: one was wrong as
  written (reading an `out` parameter returns the caller's current value, not a zero value) and two were
  narrowed. Five findings of record live in `ERRATA.md`: the `[Bug]` on a default that names an earlier
  parameter, an `out` parameter readable before it is written, the rejection of a module-level `var` from a
  plain `proc`, `invalid indentation` for the two-argument command form, and named arguments that no doc
  section describes.

## Drafting

Nothing is drafting. Chapter 9 onwards: `planned`. A chapter with an open **Proof gate** line in `OUTLINE.md`
does not draft; a chapter without one may.

## License and contributions

The book text (`chapters/`, `index.*.qmd`, this folder's Markdown) is CC BY-SA 4.0 — see [`LICENSE`](LICENSE).
The samples, `task` and `tools/` are MIT — see [`LICENSE-CODE`](LICENSE-CODE). Both mirror nim-id, so the two books
share one license pair instead of inventing a third.

The gate before any change is `./task check`; what a reader can send, and what a chapter change has to satisfy, is
in [`CONTRIBUTING.md`](CONTRIBUTING.md). Security reports are private — [`SECURITY.md`](SECURITY.md).
