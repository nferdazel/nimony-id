# Chapter 2 — review record

Draft: 2026-11-12, Aksara. Pin: `4ba90a781b0b22d0821efaa153c129c37cef6143` (nimony `0.6.3`).

## Sample verification

Command run from `/tmp` (not the book folder), to prove the verifier resolves its own paths:

```
$ /Users/sachiel/.openmausbot/product/books/nimony-id/tools/verify-samples.sh
toolchain /Users/sachiel/.local/opt/nimony/4ba90a7/bin/nimony 0.6.3 pin 4ba90a7
PASS samples/02-pinned-toolchain/hello.nim exit=0
SUMMARY 1/1 passed, 0 failed
exit 0
```

Verifier author: Raka (Team Lead, Team A). Install path `/Users/sachiel/.local/opt/nimony/4ba90a7`,
host compiler `/Users/sachiel/.local/opt/nim-2.4.0`.

## Claim provenance

Every factual statement in the draft, and what it rests on.

| Claim in text | Class | Evidence |
| --- | --- | --- |
| Pin is commit `4ba90a7`, reported version `0.6.3`; newest tag is `v0.6.2` | shipped at pin | Engineering toolchain record, 2026-11-12; `nimony --version` run by Aksara 2026-11-12 |
| `build all` exit 0 in about a minute, `bin/` contents | shipped at pin | Engineering toolchain record; Raka's rebuild at the fixed path |
| Homebrew Nim fails on `nifler` with the `dist/checksums` error, and a broken `nifler` blocks all parsing | shipped at pin | Engineering toolchain record, verbatim error text |
| `nimony n` unavailable; `arkham: command not found`, `nifmake` exit 127 | shipped at pin | Re-run by Aksara 2026-11-12 in a scratch folder; output quoted in the chapter |
| `nimony c -r hello.nim` prints `hello, world` | shipped at pin | verifier PASS line above |
| Verifier exit codes, stdout not compared | shipped at pin | verifier header and Raka's stated limits |
| No release binaries exist, so the pin is a source build | shipped at pin | Engineering toolchain record |
| Verified on macOS arm64 only | limit stated | Engineering toolchain record, "What is not proven" |

`nimony n` is not a design-intent claim: it is absent, and the chapter says so once.

## Open before freeze

1. `tech_review` empty — the chapter has not had a chapter-level technical review, only its facts verified.
2. `id.md` not written.
3. `editorial_pass` not dated.
