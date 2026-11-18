# Nimony: A Pinned Guide

Editorial home of the Nimony book. This folder is the book's plan and manuscript; it is never inside a
project repository, and no chapter work happens outside it.

**Title:** *Nimony: A Pinned Guide* (*Learning the language against one fixed commit*). Decided
2026-11-12 by the editor on the owner's delegation. The title stays English in both editions (it is a
label, not prose); it lives in `_quarto.yml` as `book.title` and `book.subtitle`.

## What this is

The book teaches the Nimony language against one fixed commit (`4ba90a7`, `nimony 0.6.3`, `nimony c`
only), so every claim can be checked against a single snapshot instead of drifting with the compiler.
It ships two editions, Indonesian and English, kept in step by a parity gate.

What it is not: it is not a general Nim book (that is [`nim-id`](https://github.com/nferdazel/nim-id)),
and it does not cover the C or JavaScript backends beyond what the pin does. Nothing outside the pin is
documented here on purpose: a newer compiler is a different book.

## Status

Version `VERSION` at the root, currently 0.1.25, tagged `vX.Y.Z`. Chapters 1 to 24 and Appendices A to
D are in the book at pin `4ba90a7`, each with `en.md` and `id.md` and each `frozen`. Nothing is
drafting and nothing is planned.

The verifier prints `SUMMARY 23/23 passed, 0 failed` (samples 02-24; Chapter 1 has none).

The review notes in this README cover Chapters 1 to 8; every later chapter carries the same record in
its own `review.md`, and `ERRATA.md` holds the pin-level findings that outlived the chapter.

- Chapter 1, `chapters/01-what-nimony-is/`: draft 2026-11-12, tech_review Momo 2026-11-12,
  editorial_pass 2026-11-12. No code samples; the compile gate does not apply.
- Chapter 2, `chapters/02-the-pinned-toolchain/`: same dates, with `samples/02-pinned-toolchain/hello.nim`
  proven by `tools/verify-samples.sh`.
- Chapter 3, `chapters/03-values-names-mutability/`: same dates, with
  `samples/03-values-names-mutability/values.nim`. Its review corrected the initialization rule: a
  module-level `var` is zeroed, a local must be proven written.
- Chapter 4, `chapters/04-numbers-types-conversion/`: same dates, with
  `samples/04-numbers-types-conversion/numbers.nim`. Its review corrected the `toInt`/`toFloat` claim
  (they exist only for `Rational[T]` at the pin) and recorded signed narrowing as intended, documented
  as a guide gap.
- Chapter 5, `chapters/05-strings/`: same dates, with `samples/05-strings/strings.nim`. Its review
  corrected the rune claim (the pin does ship `std/unicode`'s `runes` and `runeLen`), tightened four
  citations, restored the `ensureTerminatingZero` excerpt verbatim, and recorded the
  `$c`-needs-`strutils` gap as a guide gap.
- Chapter 6, `chapters/06-branching/`: same dates, with `samples/06-branching/branching.nim`. Its
  review kept all 24 claims and corrected one mechanism: an unmatched string `case` expression executes
  the last `of` branch as its fallback, side effects included, which is a defect at the pin, so the
  chapter requires `else` on every string `case` expression. The `elif`-in-`case` rejection also
  produces a third error line with an ordinal selector.
- Chapter 7, `chapters/07-loops-ranges/`: draft 2026-11-12, tech_review Momo 2026-11-12,
  editorial_pass 2026-11-12. With `samples/07-loops-ranges/loops.nim`. Its review corrected two
  claims: `countup` takes `step: Positive` while `countdown` takes an unconstrained ordinal step (a
  negative step climbs away from `b`), and `n + 0` after a guard needs no new proof while `n + 1` does,
  because it outruns the guard's bound. Three findings of record live in `ERRATA.md`: the loop variable
  is writable and moves the counter, a stored `0..3` slice is not loop-iterable, and an `in 0..9` guard
  does not prove a `range` on a procedure parameter while two comparisons do.
- Chapter 8, `chapters/08-procedures/`: draft 2026-11-12, tech_review Momo 2026-11-12,
  editorial_pass 2026-11-12. With `samples/08-procedures/procedures.nim`. Its review held 27 of 30
  claims: one was wrong as written (reading an `out` parameter returns the caller's current value, not
  a zero value) and two were narrowed. Five findings of record live in `ERRATA.md`: the `[Bug]` on a
  default that names an earlier parameter, an `out` parameter readable before it is written, the
  rejection of a module-level `var` from a plain `proc`, `invalid indentation` for the two-argument
  command form, and named arguments that no doc section describes.

## Architecture

One Quarto project, two editions, one pin.

| Part | Contents |
|---|---|
| `chapters/NN-slug/` | one folder per chapter, `en.md` and `id.md` |
| `chapters/aN-slug/` | the back matter, listed under `book.appendices` so the PDF letters them A-D |
| `samples/` | one sample per code block, run by the verifier at the pin |
| `tools/` | build, verification and release scripts |
| `ops/` | Caddy block and the static deploy script |
| `public/` | render output: the Indonesian edition at the root, the English one under `public/en/`, one PDF in each. Not tracked |

The build strips the dated chapter checklist line before rendering, and fails closed on an unpaired
chapter. `tools/check-parity.py` reads the chapter list out of the two PDFs and out of the latest
release's assets, so a content merge cannot leave the release a chapter behind.

## Repository layout

| File or folder | What it is |
|---|---|
| `OUTLINE.md` | The contract for this book: reader, pin, language policy, 24 chapters with one job each, prerequisites, status |
| `CHAPTER_TEMPLATE.md` | Frontmatter, section order, and the six gates a chapter must pass before `frozen` |
| `GLOSSARY.md` | Every term used with a special meaning, plus the terms Nimony retired |
| `ERRATA.md` | Breaks found after a chapter froze, plus the watch list of known pin-level constraints |
| `DEVIATIONS.md` | Every place this book departs from the nim-id writing baseline |
| `DESIGN.md` | The design direction: the palette and type hierarchy the series shares, and the cover device that is this book's own |
| `chapters/` | One folder per chapter: `NN-slug/en.md` and `NN-slug/id.md`, plus the `aN-slug/` back matter |
| `index.en.qmd`, `index.id.qmd` | The book's preface, one file per edition, same shape and the same pin statement |
| `CONTRIBUTING.md` | What a reader can send, the gate before sending it, and how a chapter change reaches `frozen` |
| `SECURITY.md` | What counts as a security report in a book repository, and what to send to Nimony instead |
| `LICENSE`, `LICENSE-CODE` | Book text is CC BY-SA 4.0; samples, `task` and `tools/` are MIT |
| `VERSION` | The book's version. `./task release` bumps it and tags the commit; CI refuses a tag that does not match it |
| `public/` | Render output, generated by `./task build`. Not tracked |
| `.github/` | The CI workflow, Dependabot for the action pins, a pull-request checklist, and two issue forms: errata and chapter proposal |

## Local development

### Prerequisites

Quarto (the version CI pins), Nim at the pin `4ba90a7`'s toolchain (`nimony 0.6.3`), Python 3, and
`poppler-utils` for the PDF parity check. CI clones Nimony itself into `$HOME/.local/opt/nimony/4ba90a7`
before the sample gate runs.

### Quickstart

```sh
./task build      # render both editions into public/
./task verify     # run the sample verifier
./task check      # every gate in CI order
./task version    # print VERSION
./task release    # bump VERSION and tag
```

## Configuration

`./task release` and the CI tag check both read `VERSION`; a tag that does not match it fails the job.
The deploy script reads its host-side values from the environment on the VPS. No secret is committed
and no `.env` file belongs in this repository.

## Quality gates

`./task check` is the gate before any change. CI runs the same scripts plus a gitleaks job and the
shared golden CI/CD contract check over `ops/`.

| Gate | Guards |
|---|---|
| sample verifier (`tools/verify-samples.sh`) | every sample compiles at the pin and matches `verify-samples.log` |
| chapter shape | both editions carry the same chapter set, order and section shape |
| `VERSION` versus tag | a `v*` tag must equal `VERSION`, checked in the workflow |
| PDF parity | the site and the latest release list the same chapters |
| gitleaks | no secret is committed, and the check fails on its own |

## Deployment

Both editions are served from Cloudflare at <https://nimony.qouver.com>. The origin is the VPS, not
GitHub Pages: a webhook on push to `main` calls `ops/scripts/deploy-static.sh`, which renders both
editions and publishes them to `/srv/qouver/apps/nimony-id/releases/<sha>` with a `web` symlink that
Caddy reads. The site root serves the Indonesian edition, `/en/` the English one, and the two PDFs are
assembled in `public/` and `public/en/`. A pull request cannot reach the deploy script.

Anything published there is a render of `main`, and the deploy fails closed on an unpaired chapter. The
DNS A record already points at the VPS; the Caddy block is mirrored in
`ops/caddy/Caddyfile.nimony-id.example`, so nothing in this repository touches DNS.

## Documentation

- [`OUTLINE.md`](OUTLINE.md): the editorial contract, chapter by chapter.
- [`CHAPTER_TEMPLATE.md`](CHAPTER_TEMPLATE.md): what a chapter must satisfy before `frozen`.
- [`GLOSSARY.md`](GLOSSARY.md), [`ERRATA.md`](ERRATA.md), [`DEVIATIONS.md`](DEVIATIONS.md): the term
  list, the post-freeze findings, and where this book departs from nim-id.
- [`DESIGN.md`](DESIGN.md): palette, type hierarchy and the cover device.
- [`CONTRIBUTING.md`](CONTRIBUTING.md): what a reader can send and how a change reaches `frozen`.

## Security

There is no server application in this repository; the surface is the workflows, the deploy script and
the tooling. A leaked credential, or a workflow that could be made to run foreign code, is a security
report. A wrong statement about the language is an errata issue. See [`SECURITY.md`](SECURITY.md).

## Contributing

The gate before any change is `./task check`; what a reader can send, and what a chapter change has to
satisfy, is in [`CONTRIBUTING.md`](CONTRIBUTING.md). A correction to a `frozen` chapter goes to
`ERRATA.md` instead of rewriting the chapter, and new terms go to `GLOSSARY.md` in the same change.

## License

The book text (`chapters/`, `index.*.qmd`, this repository's Markdown) is CC BY-SA 4.0, see
[`LICENSE`](LICENSE). The samples, `task` and `tools/` are MIT, see [`LICENSE-CODE`](LICENSE-CODE).
Both mirror nim-id, so the two books share one license pair instead of inventing a third.
