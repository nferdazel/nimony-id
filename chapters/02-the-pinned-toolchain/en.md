---
chapter: 2
title: The Pinned Toolchain
job: Build the pinned commit from source with the official Nim 2.4.0 tarball, compile and run a first program with `nimony c`, and recognize why Homebrew Nim and `nimony n` are both dead ends here.
nimony_version: 0.6.3
nimony_commit: 4ba90a781b0b22d0821efaa153c129c37cef6143
toolchain: /Users/sachiel/.local/opt/nimony/4ba90a7
host_compiler: /Users/sachiel/.local/opt/nim-2.4.0
status: frozen
tech_review: Momo 2026-11-12
editorial_pass: 2026-11-12
samples: ["samples/02-pinned-toolchain/hello.nim"]
glossary_added: ["pinned toolchain"]
---

# The Pinned Toolchain

## What this chapter is for

Nimony is under active development, and a language that changes weekly will quietly invalidate any book that
describes "Nimony" without saying which one. So this book names one commit — `4ba90a781b0b`, reported by the
compiler as `0.6.3` — and every statement in it is true of that commit or marked as design intent.

This chapter gets you that exact compiler, from source, and gets one program running through it. It also spends
a page on the two shortcuts that look reasonable and do not work: installing Nim from a system package manager,
and asking Nimony for its native backend. Both produce a toolchain that appears installed and compiles nothing.

Do this chapter once. Later chapters assume the path is in place and the verifier prints `SUMMARY n/n passed`.

## The pin is a commit, not a release

There is no download for this. The repository has tags but no release binaries, and the newest tag is behind
master: at the pin, `master` reports `0.6.3` while the newest tag is `v0.6.2` (Engineering's toolchain record,
2026-11-12). Pin a tag here and you are already describing a compiler nobody is building against.

Two numbers identify the pin, and you should check both after building:

| What | Value |
|---|---|
| commit | `4ba90a781b0b22d0821efaa153c129c37cef6143` |
| reported version | `0.6.3 [macosx; arm64]` |
| host compiler | official Nim 2.4.0, `nim-2.4.0-macosx_arm64.tar.xz` |
| tarball sha256 | `93a1e638289077b972b684e6e71cb11b2029602ccac4f8fd8dfa70f193fac7df` |
| verified on | macOS arm64 only |

The version string is the weaker of the two. It comes from the source tree, so a branch near the pin can
report `0.6.3` while behaving differently. Treat the commit as the identity and the version as a sanity check.

## Build it

You need a host Nim to build Nimony's build tool, `hastur`. Use the official tarball, not a package manager's
copy:

```
curl -LO https://nim-lang.org/download/nim-2.4.0-macosx_arm64.tar.xz
shasum -a 256 nim-2.4.0-macosx_arm64.tar.xz
# expect 93a1e638289077b972b684e6e71cb11b2029602ccac4f8fd8dfa70f193fac7df
tar xf nim-2.4.0-macosx_arm64.tar.xz
```

Then the compiler itself:

```
git clone https://github.com/nim-lang/nimony.git
cd nimony
git checkout 4ba90a781b0b22d0821efaa153c129c37cef6143
export PATH=/path/to/nim-2.4.0/bin:$PATH
nim c -r src/hastur/hastur build all
```

`build all` took 1m02s on the macOS arm64 machine this book was pinned on. Exit `0` fills `bin/` with the pipeline:
`nifler`, `nimsem`, `lengc`, `nifmake`, `niflink`, `nimony`, `hastur` and the rest. The names come back in
Chapter 1's mental model — NIF in, NIF out, stage by stage — and you now have one of each on disk.

Install it somewhere stable. A build under a system temp directory works and is a mistake: macOS deletes temp
folders on its own schedule, and a toolchain that vanishes mid-chapter takes your verification with it. Put it
under a fixed path such as `~/.local/opt/nimony/4ba90a7`, named for the commit.

Check it:

```
$ nimony --version
0.6.3 [macosx; arm64]
```

## The trap: do not build with a package manager's Nim

Homebrew `nim 2.4.0` compiles Nimony's own binary and then fails on `nifler`:

```
compiler/ast2nif.nim(19, 42) Error: cannot open file: ../dist/checksums/src/checksums/sha1
FAILURE nim c ... -o:bin/nifler src/nifler/nifler.nim
```

The cause is packaging, not a version mismatch. `nifler` imports `ast2nif.nim` from the host compiler, and that
module needs a sibling `dist/checksums` tree. Homebrew's formula does not ship it; the official tarball does,
along with a vendored `dist/nimony`.

Why this matters more than it looks: `build all` stops at the first failing tool, and the fallback parser
`nifler2` is built last, so a build that dies at `nifler` has no parser at all. The build looks
almost complete — you have a `nimony` executable and it answers `--version` — and every compile still dies in
the front end. If you see `FAILURE: nifler --portablePaths --deps parse hello.nim`, you have this problem, and
the fix is the tarball, not a flag.

## `nimony n` is not available at this pin

Nimony is documented with two backends, and it is easy to assume the native one is the interesting one. At this
commit it does not exist. The build tells you so, in passing, and it is worth reading rather than skimming:

```
[build] ../nativenif not found — skipping arkham + nifasm; `nimony n` and a native boot need it (clone nim-lang/nativenif next to this repo)
```

The backends those names belong to live in that other repository. Without it there is no native backend to
invoke, and running `nimony n` gets you this, not a compiler diagnostic:

```
/bin/sh: arkham: command not found
nifmake: command failed (exit code 127): arkham --os:MacOSX --cpu:arm64 -o:…asm.nif …c.nif
FAILURE: …/bin/nifmake --rerun -j run --progress:50:100 nimcache/….final.build.nif
```

`arkham` is the native code generator, and it ships in the separate `nim-lang/nativenif` repository. The C
backend was never involved, so there is nothing to fix on your side.

So: every sample in this book goes through `nimony c`, the C backend, which needs `nifler` and a C compiler and
nothing else. `nimony n` appears in this book zero times as an instruction. When the native backend ships and
the pin moves, that is a new pin and an errata entry, not a footnote promising it later.

## Your first program

```
import std/syncio

echo "hello, world"
```

```
$ nimony c -r hello.nim
hello, world
```

That is the whole loop the rest of the book runs on: `c` compiles, `-r` runs the result. Two details worth
knowing now, because they explain later surprises. `std/syncio` is imported explicitly — Nimony does not put
`echo` in scope for free. And `echo` writes a line; Chapter 4 gets to what a `string` is at this pin, which is
not what Nim 2 code assumes.

## Verify the whole book, not just your chapter

The book keeps its samples in `samples/NN-slug/` and proves them with one script, so a claim in Chapter 14 does
not depend on which chapter you happened to read:

```
$ /Users/sachiel/.openmausbot/product/books/nimony-id/tools/verify-samples.sh
toolchain /Users/sachiel/.local/opt/nimony/4ba90a7/bin/nimony 0.6.3 pin 4ba90a7
PASS samples/02-pinned-toolchain/hello.nim exit=0
SUMMARY 1/1 passed, 0 failed
```

The script checks the commit before it compiles anything, compiles and runs every sample through `nimony c -r`,
prints one line per file, and exits non-zero if any sample fails — `0` all pass, `1` a sample failed, `2` the
toolchain is missing or is not the pin. Run it after every change to your install; a green summary is the only
evidence this book accepts that a sample works.

One honest limit: the verifier proves compile, run and exit code. It does not compare stdout. Where a chapter
teaches observable output, the chapter states the expected output and the check that proves it.

## Samples

- `samples/02-pinned-toolchain/hello.nim` — proven by `tools/verify-samples.sh`:

  ```
  PASS samples/02-pinned-toolchain/hello.nim exit=0
  ```

## Checks

1. Build the pin at a fixed path and run `nimony --version`. Expected: `0.6.3 [macosx; arm64]`. If you get a
   different version, you checked out a different commit — run `git rev-parse HEAD` and compare.
2. Deliberately build once with a package manager's Nim, if you want to see the failure for yourself. Expected:
   a `nifler` build failure naming `../dist/checksums/...`, and every later compile failing in the parse stage.
   Then throw that build away.
3. Run `nimony n hello.nim`. Expected: `/bin/sh: arkham: command not found`, a `nifmake` line with exit code
   127, and a final `FAILURE`. That is the answer at this pin, not a setup mistake on your side.
4. Run the sample verifier from a directory that is not the book folder. Expected: the same three lines, same
   summary — it resolves its own paths.

## Chapter checklist

draft 2026-11-12 · tech_review Momo 2026-11-12 · editorial_pass 2026-11-12 · frozen 2026-11-12
