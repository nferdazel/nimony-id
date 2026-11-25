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
