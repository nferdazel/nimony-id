---
appendix: B
title: The sample verification record
job: Record the exact command, pin and output format behind every code sample in this book, so a reader can reproduce a chapter's evidence instead of trusting the page.
nimony_version: 0.6.3
nimony_commit: 4ba90a781b0b22d0821efaa153c129c37cef6143
toolchain: ~/.local/opt/nimony/4ba90a7
host_compiler: ~/.local/opt/nim-2.4.0
status: frozen
tech_review: Momo 2026-11-12 to 2026-11-13, chapter by chapter; this appendix restates the verifier behaviour Chapter 23 teaches
editorial_pass: 2026-11-13
samples: []
glossary_added: []
---

# The sample verification record

## What this appendix is for

A programming book is a claim about a compiler. This book makes that claim in one form only: every sample under
`samples/` is compiled and run by one script against one toolchain, and a chapter does not freeze until that run
is green. This appendix is the record of what "green" means, what the command was, and what the output looked
like at the pin — the same information a reader needs to check the book rather than believe it.

## The pin

| Item | Value |
| --- | --- |
| Compiler | `nimony` 0.6.3 |
| Commit | `4ba90a781b0b22d0821efaa153c129c37cef6143` (2026-11-12) |
| Toolchain path | `~/.local/opt/nimony/4ba90a7`, fixed; `$NIMONY_HOME` overrides it and is checked against the same pin |
| Host compiler | Nim 2.4.0, official tarball, sha256 `93a1e638289077b972b684e6e71cb11b2029602ccac4f8fd8dfa70f193fac7df` |
| Backend used | `nimony c` only; `nimony n` does not exist at this pin and is out of scope |

The path is fixed on purpose. A toolchain under a temporary directory, a Homebrew Nim, or a second checkout of the
same commit is not the pin: the script refuses a compiler whose version or commit does not match, and it refuses it
before it compiles anything.

## The command

From the root of the book's repository:

```
./task verify            # or: bash tools/verify-samples.sh
```

`./task check` runs the same verifier and then renders both editions, which is the gate before a commit. Both
commands resolve the toolchain through `$NIMONY_HOME` and fall back to `~/.local/opt/nimony/4ba90a7`.

## What the output means

The verifier reads every `samples/*/*.nim`, compiles each one with `nimony c -r`, and prints one line per sample
followed by a summary:

```
toolchain ~/.local/opt/nimony/4ba90a7/bin/nimony 0.6.3 pin 4ba90a7
PASS samples/02-pinned-toolchain/hello.nim exit=0
...
SUMMARY 23/23 passed, 0 failed
```

Three exit codes, and they are not interchangeable:

- **0** — every sample compiled and ran.
- **1** — at least one sample failed; the failing line names the sample and its exit code.
- **2** — the toolchain is missing or is not the pin. This is not a verdict on the samples, and a green-looking
  summary is impossible: the script stops before compiling.

A sample's **exit code is the whole verdict**. A chapter's expected output is checked against the block printed in
that chapter, byte for byte, by the editor and independently by the reviewer; the verifier itself judges exit
status only, because a printed value that is merely plausible is exactly what a book must not accept.

One consequence of `nimony c -r` matters when reading any exit code in this book: the driver turns a non-zero exit
of the child into `1` and prints `FAILURE: <binary path>`, while the compiled binary keeps the real code. Where a
chapter teaches a specific exit status, it says the status came from the binary under `nimcache/c/<hash>/main`, not
from the driver. Chapter 23 carries that finding.

## The run at the pin

Full output of `./task verify`, 2026-11-13, macOS arm64, paths as printed:

```
toolchain /Users/sachiel/.local/opt/nimony/4ba90a7/bin/nimony 0.6.3 pin 4ba90a7
PASS samples/02-pinned-toolchain/hello.nim exit=0
PASS samples/03-values-names-mutability/values.nim exit=0
PASS samples/04-numbers-types-conversion/numbers.nim exit=0
PASS samples/05-strings/strings.nim exit=0
PASS samples/06-branching/branching.nim exit=0
PASS samples/07-loops-ranges/loops.nim exit=0
PASS samples/08-procedures/procedures.nim exit=0
PASS samples/09-overloading/overloading.nim exit=0
PASS samples/10-arrays-sequences-tuples/collections.nim exit=0
PASS samples/11-objects-enums-distinct/objects.nim exit=0
PASS samples/12-sum-types-case/sumtypes.nim exit=0
PASS samples/13-references-pointers-nil/refs.nim exit=0
PASS samples/14-ownership-borrow/ownership.nim exit=0
PASS samples/15-errors-as-values/errors.nim exit=0
PASS samples/16-modules-visibility/modules.nim exit=0
PASS samples/17-generics-concepts/generics.nim exit=0
PASS samples/18-templates-compiletime/templates.nim exit=0
PASS samples/19-plugins-nif/plugins.nim exit=0
PASS samples/20-stdlib/stdlib.nim exit=0
PASS samples/21-files-processes/files.nim exit=0
PASS samples/22-cinterop/cinterop.nim exit=0
PASS samples/23-testing/testing.nim exit=0
PASS samples/24-passive-procs/passive.nim exit=0
SUMMARY 23/23 passed, 0 failed
```

Twenty-three samples for twenty-four chapters, and the count is not an error: Chapter 1 has none. It is the
chapter that says what Nimony is, and a sample there would have to run before the reader has a toolchain.

## Which chapter is behind which sample

| Chapter | Sample | Notes |
| --- | --- | --- |
| 2 | `samples/02-pinned-toolchain/hello.nim` | Proves the build and the run, nothing about the language. |
| 3 | `samples/03-values-names-mutability/values.nim` | |
| 4 | `samples/04-numbers-types-conversion/numbers.nim` | Wrapping is the teaching point, so the sample runs the wrap. |
| 5 | `samples/05-strings/strings.nim` | |
| 6 | `samples/06-branching/branching.nim` | |
| 7 | `samples/07-loops-ranges/loops.nim` | |
| 8 | `samples/08-procedures/procedures.nim` | |
| 9 | `samples/09-overloading/overloading.nim` | |
| 10 | `samples/10-arrays-sequences-tuples/collections.nim` | |
| 11 | `samples/11-objects-enums-distinct/objects.nim` | |
| 12 | `samples/12-sum-types-case/sumtypes.nim` | |
| 13 | `samples/13-references-pointers-nil/refs.nim` | |
| 14 | `samples/14-ownership-borrow/ownership.nim` | |
| 15 | `samples/15-errors-as-values/errors.nim` | |
| 16 | `samples/16-modules-visibility/modules.nim` | The only sample that is more than one file: the support modules sit in `support/`. |
| 17 | `samples/17-generics-concepts/generics.nim` | |
| 18 | `samples/18-templates-compiletime/templates.nim` | |
| 19 | `samples/19-plugins-nif/plugins.nim` | Its plugin lives in `deps/shape` and is built during the run. |
| 20 | `samples/20-stdlib/stdlib.nim` | |
| 21 | `samples/21-files-processes/files.nim` | Creates a temporary directory, reads and writes files, and runs a subprocess. |
| 22 | `samples/22-cinterop/cinterop.nim` | Deliberately single-file, no `{.compile.}` and no callback: the callback form is prose in Chapter 22 because it was measured on clang only. |
| 23 | `samples/23-testing/testing.nim` | |
| 24 | `samples/24-passive-procs/passive.nim` | Single file, one thread, no I/O; the thread pool is prose. |

Each chapter's `review.md` next to its text holds the claim-by-claim probe table that sits behind these samples:
what was run, the raw output, and the Nimony source line for anything the raw output alone cannot explain.

## Adding a sample

A new sample is one file, `samples/NN-slug/name.nim`, with its expected output printed in that chapter's
**Samples** section and repeated in the review note. It is proven by the same command, and its line joins the
output block above. No sample is exempt, and no chapter freezes on a sample that was run by hand.
