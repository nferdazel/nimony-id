# Changelog

All notable changes to *Nimony: A Pinned Guide* are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres
to [Semantic Versioning](https://semver.org/spec/v2.0.0.html). `VERSION` is the single source of the
version, and `./task release` bumps it and tags `vX.Y.Z`; CI refuses a tag that does not match it. Both
editions ship in one version.

This file starts here. The release history before it is on the releases page, one entry per tag with
the two PDFs attached, and the README carries the narrative for the early versions. It is not copied
back into this file.

## [Unreleased]

### Fixed

- Chapter 10 (both editions): one sentence after the runtime index example names the three shapes where
  `4ba90a7` drops the bounds check — a read in an `except` handler after the body rewrote the index, a store
  that runs a side-effecting hook, and a call passing a value to a `sink` parameter — so the paragraph no longer
  implies the check always holds. Chapter 15 is unchanged: it makes no bounds claim, and `IndexError` appears
  there only in the `ErrorCode` member list.

### Changed

- `ERRATA.md`: the Chapters 10 and 15 watch row becomes an open erratum dated 2026-11-25 on `0.6.3` / `4ba90a7`.
  The ruling records that the `try` body is checked and the `except` handler is not; the earlier plan to narrow
  Chapter 10 to "checked outside a `try` body" is withdrawn as wrong.
- Appendix C (both editions): the errata index lists two open rows.

### Added

- `reviews/2026-11-25-3001-index-check.md`: the probe set behind the ruling — the two checked controls and the
  three escaping shapes, run by Engineering at the pin and partly re-run by the editor.

## [0.1.27] - 2026-11-25

### Fixed

- `ERRATA.md`: the Chapter 11 (objects) watch row lost a cell because the source signature
  `[T: tuple|object]` carried an unescaped pipe; it renders as one four-column row again.
- `README.md`: the status paragraph no longer hardcodes a version number, so it cannot fall a release
  behind `VERSION`.

### Added

- `ERRATA.md`: a watch row for `nim-lang/nimony#3001` (index checks dropped across `try` handlers,
  hook-running assignments and `sink` parameters), until now recorded only in
  `reviews/2026-11-16-corpus-at-head.md`. Chapter 10's runtime index claim is unchanged and the ruling
  sits with the Head of Engineering.

### Changed

- CI: `jiro4989/setup-nim-action` bumped to 2.5.1 (`08957181`), pinned by full commit SHA as before.

## [0.1.26] - 2026-11-20

### Changed

- CI/CD v2.0: one local gate (`./task gate`, `./task gate-full`), one release mechanism
  (`./task release`, no push without `--push`), the golden contract job renamed to `preflight`
  and required by every expensive job.

## [0.1.25] - 2026-11-14

Current edition: 24 chapters and Appendices A-D at pin `4ba90a7`, both editions frozen.
