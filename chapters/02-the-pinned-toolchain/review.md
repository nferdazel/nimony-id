# Chapter 2 — review record

Draft: 2026-11-12, Aksara. Pin: `4ba90a781b0b22d0821efaa153c129c37cef6143` (nimony `0.6.3`).
Technical review: Momo, 2026-11-12. Nine claims; six PASS, three CORRECT-with-wording, none unproven.

## Sample verification

Run by Momo during the review, from the pinned install path:

```
toolchain ~/.local/opt/nimony/4ba90a7/bin/nimony 0.6.3 pin 4ba90a7
PASS samples/02-pinned-toolchain/hello.nim exit=0
SUMMARY 1/1 passed, 0 failed
```

Exit code `0`. Earlier the same three lines were reproduced by Aksara from `/tmp`, to prove the verifier
resolves its own paths. Verifier author: Raka (Team Lead, Team A). Install path
`~/.local/opt/nimony/4ba90a7`, host compiler `~/.local/opt/nim-2.4.0`.

## Claim verdicts

| # | Statement in the draft | Verdict | Evidence | What changed |
| --- | --- | --- | --- | --- |
| 1 | Newest tag is behind master: pin reports `0.6.3`, newest tag `v0.6.2` | PASS | Tags endpoint returns only `v0.6.2` and `v0.2.0`; `v0.6.2...4ba90a7` = ahead 360, behind 0; releases endpoint returns `[]` | none |
| 2 | Version `0.6.3 [macosx; arm64]`; version comes from the source tree, so a nearby branch can report `0.6.3` and behave differently | PASS | `src/lib/nimversion.nim:29` slurps `doc/version.md`, `:43` takes the first field; `doc/version.md` at the pin and on master today are the same string | none |
| 3 | Host build needs official Nim 2.4.0, sha256 `93a1e638…c7df` | PASS | sha256 file fetched from nim-lang.org on review day, exact match; tarball ships `dist/checksums` and `dist/nimony` | none |
| 4 | `build all` takes about a minute on an Apple silicon laptop; exit 0 fills `bin/` with seven named tools | CORRECT — wording | All seven names present (plus `nifler2`, `dagon`, `pnak`, `shoggoth`, `validator`); build record has 1m02s, not re-measured on review day | timing narrowed to the measured machine; "and the rest" already covered the extra names |
| 5 | Homebrew Nim fails on `nifler` with the `../dist/checksums/src/checksums/sha1` error, caused by packaging | PASS (cause re-checked statically on review day, failure not re-run) | `/opt/homebrew/Cellar/nim/2.4.0/nim` holds `bin compiler config doc lib nim.nimble`, no `dist/checksums`; official tarball has both trees | none |
| 6 | "Without `nifler` the compiler cannot parse a file at all" | CORRECT — wording | `build all` quits on the first failing tool (`src/hastur/builders.nim:255-283`) and `nifler2` is built last; but `parserTool()` prefers `nifler2` when present (`src/lib/tooldirs.nim:29-37`) | replaced with the build-ordering reason plus the `nifler2` fallback |
| 7 | `../nativenif not found` build message; `arkham: command not found`, `nifmake` exit 127; `arkham` is the missing native backend | CORRECT — wording | Build log line 1 carries a `[build] ` prefix; `doc/design.md:44` says native code comes from `arkham` + `nifasm`, shipped in `nim-lang/nativenif` | prefix restored and the message made one verbatim line; attribution corrected to "native code generator, ships in the separate repository" |
| 8 | `std/syncio` imported explicitly; Nimony does not put `echo` in scope for free | PASS | `echo` is `template echo*() {.varargs.}` at `lib/std/syncio.nim:465`; `lib/std/system.nim` defines no `echo` | none |
| 9 | Verifier exit codes 0/1/2, does not compare stdout | PASS | script exits 2 for toolchain/pin problems, 1 from the summary check; compares exit codes only | none |

## Applied changes

1. "`build all` takes about a minute on an Apple silicon laptop." → "`build all` took 1m02s on the macOS arm64
   machine this book was pinned on."
2. "without `nifler` the compiler cannot parse a file at all" → "`build all` stops at the first failing tool,
   and the fallback parser `nifler2` is built last, so a build that dies at `nifler` has no parser at all."
3. Build message quoted with its `[build] ` prefix as one verbatim line; "`arkham` is the missing native
   backend." → "`arkham` is the native code generator, and it ships in the separate `nim-lang/nativenif`
   repository." The sentence before it was retightened to avoid saying "separate repository" twice.

`tech_review: Momo 2026-11-12` filled in frontmatter and in the chapter checklist.

## Claim provenance

Every factual statement in the draft, and what it rests on.

| Claim in text | Class | Evidence |
| --- | --- | --- |
| Pin is commit `4ba90a7`, reported version `0.6.3`; newest tag is `v0.6.2`, no release binaries | shipped at pin | Momo's tag/release check 2026-11-12; `nimony --version` |
| `build all` took 1m02s; `bin/` contents | shipped at pin | Engineering build record 2026-11-12 (timing not re-measured) |
| Homebrew Nim fails on `nifler` with the `dist/checksums` error; the build dies before `nifler2` exists | shipped at pin | Build record 2026-11-12; packaging re-checked statically on review day |
| `nimony n` unavailable; `arkham: command not found`, `nifmake` exit 127 | shipped at pin | Re-run by Aksara 2026-11-12; quoted output in the chapter |
| `arkham`/`nifasm` ship in `nim-lang/nativenif` | shipped at pin | `doc/design.md:44`, build message |
| `nimony c -r hello.nim` prints `hello, world` | shipped at pin | verifier PASS line above |
| `echo` is not in implicit scope | shipped at pin | `lib/std/syncio.nim:465`, `lib/std/system.nim` |
| Verifier exit codes, stdout not compared | shipped at pin | verifier script; run above |
| Verified on macOS arm64 only | limit stated | chapter table row "verified on" |

`nimony n` is not a design-intent claim: it is absent, and the chapter says so once.

## Closed before freeze — 2026-11-12

1. `id.md` written 2026-11-12, same frontmatter — including `tech_review`, `editorial_pass`, `toolchain`,
   `host_compiler` and the sample list — and a full mirror of `en.md`, all nine corrected claims included.
2. `editorial_pass` dated 2026-11-12: "pinned toolchain" is in `GLOSSARY.md`; `OUTLINE.md` marks this chapter
   `Nim 2 delta: no` and the chapter carries no delta box; no reference to nim-id; the Indonesian text uses the
   address form recorded in `DEVIATIONS.md` #6.
3. The verifier was re-run from `/tmp` on 2026-11-12 after the edits: `PASS`, `SUMMARY 1/1 passed, 0 failed`,
   exit `0`.
4. Timing and the Homebrew failure still rest on the 2026-11-12 build record rather than a same-day re-run.
   Both are labelled that way in the text and here; the wording was narrowed so neither needs a new number.

Chapter frozen 2026-11-12. A break found on a newer pin goes to `ERRATA.md`; the text is not rewritten.
