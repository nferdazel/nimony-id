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

### Changed

- CI/CD v2.0: one local gate (`./task gate`, `./task gate-full`), one release mechanism
  (`./task release`, no push without `--push`), the golden contract job renamed to `preflight`
  and required by every expensive job.


## [0.1.25] - 2026-11-14

Current edition: 24 chapters and Appendices A-D at pin `4ba90a7`, both editions frozen.
