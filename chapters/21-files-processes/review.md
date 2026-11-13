# Chapter 21 review note — Files, Processes, and the Outside World

Status: `drafting`. Reviewer: **Momo**. This note is the claim table, the open questions and the errata
candidates. Append your verdict at end of file; do not edit the table rows in place.

Pin for every run below: `4ba90a781b0b22d0821efaa153c129c37cef6143` (nimony 0.6.3), install
`~/.local/opt/nimony/4ba90a7`. Probe sources: `ch21-probes/` in the authoring workspace
(`~/.openmausbot/workspaces/be336972-1e63-4f00-9916-c76cc8e33654/ch21-probes`), one directory per
probe, each run as `~/.local/opt/nimony/4ba90a7/bin/nimony c -r main.nim` from inside the probe directory.
Probes that need an exit code or an argv were run as the compiled binary `nimcache/c/<hash>/main` afterwards,
because `nimony c -r` reports only its own `FAILURE` line. Host comparison (`nim2/n1`) was compiled with
`~/.local/opt/nim-2.4.0/bin/nim c -r --hints:off`.

Verifier already run by the editor, from the authoring folder:

```
toolchain ~/.local/opt/nimony/4ba90a7/bin/nimony 0.6.3 pin 4ba90a7
PASS samples/21-files-processes/files.nim exit=0
SUMMARY 20/20 passed, 0 failed
```

Sample output, byte-identical to the block in `en.md` section Samples (16 lines, an empty line is the second
line of the `second` echo):

```
6
second

13
2
13
true false
Success
false
fallback
visible
false
0
a b|c|

4 7
```

## Claims

| # | Claim (as written in `en.md`) | Probe | Raw output | Source line |
| --- | --- | --- | --- | --- |
| 1 | Everything that reaches outside the process is marked `{.raises.}`, so a call outside a `try` is a compile error. | `f03`, `f06`, `e01` | `Error: cannot call a routine marked as `.raises` outside of a `try`..`except` block` at each call | `lib/std/syncio.nim:577`, `:590`; `lib/std/os.nim:443`; `lib/std/envvars.nim:17`, `:22` |
| 2 | `writeFile` and `readFile` are both `{.raises.}`. | doc read + `f01` | both declarations carry the pragma; `f01` runs under `try` | `lib/std/syncio.nim:590`, `:577` |
| 3 | `writeFile("note.txt", "first\n")` then `readFile` gives length `6`. | sample | `6` | `lib/std/syncio.nim:590`, `:577` |
| 4 | A missing file arrives as the `ErrorCode` member `IOError`. | `f02` | `caught: IOError`, exit 0 | `lib/std/syncio.nim:577` |
| 5 | A read aimed at a directory arrives as `IOError` too. | `z01` | `caught: IOError`, exit 0 | `lib/std/syncio.nim:577` |
| 6 | A second `writeFile` replaces the file and never appends. | `f13` | `second`, exit 0 | `lib/std/syncio.nim:590` |
| 7 | Appending needs `open(f, name, fmAppend)`, `writeLine` and `close`. | `f09` | `one`, `two`, exit 0 | `lib/std/syncio.nim:400`, `:471`, `:341` |
| 8 | `open(f, filename, mode): bool` returns whether it opened and does not raise. | `g06`, `f03` | `false` then `true`; `true` | `lib/std/syncio.nim:400-451` |
| 9 | `readLine(f, s: var string): bool` returns whether a line was read. | `f04`, sample | `line: alpha`, `line: beta`; sample counts `2` | `lib/std/syncio.nim:506` |
| 10 | `readAll(f)` returns everything left and is `{.raises.}`. | `f10` | `5`, exit 0, call wrapped because of the pragma | `lib/std/syncio.nim:561` |
| 11 | `getFileSize` is `{.raises.}` and answers `5` for `"12345"`. | `f06` | `5` | `lib/std/os.nim:443` |
| 12 | `getFileSize` on a missing file reports `NameNotFound`. | `z02` | `caught: NameNotFound` | `lib/std/os.nim:443`; `lib/std/errorcodes/errorcodes.nim:43` |
| 13 | `open(filename, mode)` prints `cannot open: missing.txt` and exits `1`. | `f11` | stdout `cannot open: missing.txt`, rc `1` | `lib/std/syncio.nim:453-461` |
| 14 | That overload's docstring says it raises `IOError`, but the raise is commented out with a `TODO`. | doc read | `# TODO: raise exception when it is supported.` / `#raise newException(IOError, …)` then `quit "cannot open: " & filename` | `lib/std/syncio.nim:456-461` |
| 15 | `Path` is built with `path("...")` and printed with `$`. | `d01`, sample | `$here` printed a directory; `$note` accepted by `writeFile` | `lib/std/paths.nim:26`, `:30` |
| 16 | `/` joins paths, `extractFilename` splits one, `absolutePath` resolves it. | `d01` | `main.nim` from `$abs.extractFilename()` | `lib/std/paths.nim:63`, `:188`, `:289` |
| 17 | `echo` of a `Path` is a type mismatch; `echo $path` is not. | `d01` (first draft) | `expected: string but got: Path`, nine overloads listed | `lib/std/syncio.nim:293-331`, `:468` |
| 18 | `std/files` mutators take a `Path`: `removeFile`, `copyFile`, `moveFile`, `tryRemoveFile`. | doc read + `f08`, `g05` | `f08` prints `data`; `g05` compiles | `lib/std/files.nim:65`, `:186`, `:261`, `:45` |
| 19 | `fileExists` and `dirExists` take a `string`. | `f12` | `true true` | `lib/std/private/oscommons.nim:111`, `:141`; re-exported at `lib/std/os.nim:11` |
| 20 | `fileExists(somePath)` is a type mismatch. | sample, first draft | `expected: string but got: Path (declared in …/oscommons.nim(111, 3))` | `lib/std/private/oscommons.nim:111` |
| 21 | `createDir` and `removeDir` take a `Path`. | `d02` | `created`, `removed` | `lib/std/dirs.nim:49`, `:305` |
| 22 | A bare `tryRemoveFile` call is refused: `expression of type ErrorCode must be discarded`. | `f07` (first draft) | `Error: expression of type `ErrorCode` must be discarded` | `lib/std/files.nim:45` |
| 23 | The success value of `tryRemoveFile` is the enum member `Success`. | `f07` | `Success` | `lib/std/files.nim:45`; `lib/std/errorcodes/errorcodes.nim:5` |
| 24 | `removeFile` is the `try` contract for the same operation. | doc read + `g05` | `proc removeFile*(file: Path) {.raises.}` | `lib/std/files.nim:65` |
| 25 | `createTempDir` returns a `Path`, `createTempFile` a `(File, Path)` tuple, `genTempPath` a name only. | `t01`, sample | `bookNin7YEa3.txt`; `sample` creates and removes a directory | `lib/std/tempfiles.nim:181`, `:156`, `:103` |
| 26 | Importing `dirs` and `paths` makes `getCurrentDir` ambiguous. | `d01` | `Error: ambiguous call: 'getCurrentDir'` with both declarations at `dirs.nim(440, 1)` and `paths.nim(255, 1)` | `lib/std/dirs.nim:440`; `lib/std/paths.nim:255` |
| 27 | `paramCount`/`paramStr` are the primitive pair and come with `std/os`. | `a01`, `g04` | `paramCount()` printed `3` with three arguments | `lib/std/cmdline.nim:211`, `:218`; `export cmdline` at `lib/std/os.nim:8` |
| 28 | `commandLineParams` returns `seq[string]`. | `a01` | `{one}`, `{two three}`, `{}` | `lib/std/cmdline.nim:262` |
| 29 | An argument containing a space arrives as one element; an empty argument arrives empty. | `a01` binary run with `one "two three" ""` | `[one]`, `[two three]`, `[]` | probe |
| 30 | `commandLineParams` cannot be printed by `echo`. | `a01` (first draft) | `expected: string but got: seq[string]`, nine overloads | `lib/std/syncio.nim:468` |
| 31 | `getAppFilename` returns the running executable, which under the pin is a `nimcache` path. | `a02` | `nimcache/c/mai3r4ykk/main` | `lib/std/os.nim:132-136` |
| 32 | `getAppDir` is that file's directory. | doc read | `result = splitFile(getAppFilename()).dir` | `lib/std/os.nim:138-139` |
| 33 | `getEnv` is total and takes a default; `existsEnv` answers a question. | `e01` | `fallback`, then `true`, then `false` | `lib/std/envvars.nim:4`, `:11` |
| 34 | `putEnv` and `delEnv` are `{.raises.}`. | `e01` (first draft) | two `cannot call a routine marked as `.raises`…` errors at the two writes | `lib/std/envvars.nim:17`, `:22` |
| 35 | `envPairs` iterates the environment. | `e02` | `true` | `lib/std/envvars.nim:26` |
| 36 | A variable set with `putEnv` is visible to a child process. | `e05` | `out[NIMONY_CHILD=visible` … `] code=0` | `lib/std/envvars.nim:17`; `lib/std/osproc.nim:898` |
| 37 | `quit(value: int)` sets the process exit status. | `x01` binary run | stdout `before`, rc `3` | `lib/std/syncio.nim:538` |
| 38 | `quit(msg)` prints to **stdout** and exits `1`. | `x02` binary run | stdout `fatal: no config`, stderr empty, rc `1` | `lib/std/syncio.nim:547` |
| 39 | `quit(msg, errorcode)` prints and exits with that code. | `x03` binary run | stdout `bad input`, rc `2` | `lib/std/syncio.nim:551` |
| 40 | The driver reports a nonzero exit as `FAILURE: <path>` without naming the code or the source. | `x01`, `x02`, `f11` | `FAILURE: nimcache/c/mai3r4ykk/main` | probe |
| 41 | `execShellCmd` returns the shell command's exit status. | `p05` | `5` | `lib/std/os.nim:373`, `:428` |
| 42 | `execProcess` defaults include `poEvalCommand`, and `args` with that option asserts. | `p01` | `[Assertion Failure] `args` has to be empty when using poEvalCommand.`, rc nonzero | `lib/std/osproc.nim:878-880` |
| 43 | `execProcess` with `options = {poUsePath}` passes each `args` element as one argv entry. | `s02` | `argv[a b|c|` … `]` for `args = ["%s|", "a b", "c"]` | `lib/std/osproc.nim:878` |
| 44 | `execProcess` output carries a trailing newline added by the reader. | sample | `a b|c|` then a blank line | `lib/std/osproc.nim:890-894` |
| 45 | `execCmdEx` folds stderr into stdout and returns `(output, exitCode)`. | `p02` | `out[out` / `err` / `]`, `code=7` | `lib/std/osproc.nim:898-916` |
| 46 | A command that does not exist returns status `127` and the shell's message as output. | `p07` | `out[/bin/sh: /no/such/binary: No such file or directory` … `] code=127` | `lib/std/osproc.nim:898` |
| 47 | `startProcess`, `inputStream`, `outputStream`, `readLines`, `waitForExit`, `peekExitCode` work as a set. | `p03`, `p04`, `p08` | `p03` → `1 0`; `p04` → `-1` then `4`; `p08` → `L:one`, `L:two`, `code=0` | `lib/std/osproc.nim:331`, `:871`, `:438`, `:483` |
| 48 | `readLines(p)` returns `(seq[string], int)` and takes the exit code from `peekExitCode`. | doc read + `p03` | `proc readLines*(p: Process): (seq[string], int)`; `result = (acc, p.peekExitCode)` | `lib/std/osproc.nim:871-876` |
| 49 | `poParentStreams` sends the child's output straight to the parent's stdout. | `p09` | `direct to stdout` then `child code=0` | `lib/std/osproc.nim:642`, `:779` |
| 50 | In Nim 2.4.0, `std/os.removeFile` takes a string and says nothing when the file is missing. | `nim2/n1` | `compiled and ran`, exit 0, on a nonexistent path | host compiler |
| 51 | At the pin, `import std/os` alone has no `removeFile`. | `g04` | `Error: undeclared identifier: 'removeFile'` | pin module list; `lib/std/files.nim:65` |
| 52 | With `std/files` imported, `removeFile("x.txt")` is a type mismatch: `expected: Path but got: string`. | `g07` | `[1] expected: Path but got: string (declared in …/files.nim(65, 1))` | `lib/std/files.nim:65` |

## Questions for the reviewer

**A. `open(filename, mode)` quits instead of raising.** The docstring at `lib/std/syncio.nim:453-459` says it
raises `IOError`, the raise is commented out with `TODO: raise exception when it is supported`, and the body
calls `quit "cannot open: " & filename`, which prints to stdout and exits `1` (`f11`). Is this a documentation
defect to file, or an intended interim shape that the chapter should describe as "the quitting overload, not
to be used"? The chapter currently says the second.

**B. `execProcess` cannot take both an argument list and its own defaults.** The default option set is
`{poStdErrToStdOut, poUsePath, poEvalCommand}` (`lib/std/osproc.nim:878-880`), and `startProcess` asserts
```
`args` has to be empty when using poEvalCommand.
```
(`p01`), so the natural call `execProcess("/bin/echo", args = ["hi"])` dies at run time. Is that combination
intended (the argument-taking form is meant to be used with explicit options), and is the assert instead of a
compile-time rule worth an ERRATA row?

**C. `getAppFilename` is a nimcache path under the pin.** `a02` printed `nimcache/c/mai3r4ykk/main`. On Linux
the implementation reads `/proc/self/exe` (`lib/std/os.nim:132-135`), so it reports the built binary, not the
source. Is that stable enough to state as a rule ("do not use `getAppDir` to find your source files"), and does
the driver intend to keep the binary in nimcache?

**D. The `Path`/`string` split between `std/files` and `std/os`.** Mutators take `Path`, predicates take
`string`, both are re-exported by different modules (`lib/std/files.nim:65` against
`lib/std/private/oscommons.nim:111`). Is that a deliberate boundary (path-valued mutation, string-valued
query), or drift to be filed? The chapter teaches it as the shape you have to live with.

**E. `tryRemoveFile` returning `ErrorCode`.** A bare call is `expression of type ErrorCode must be discarded`,
and success is the enum member `Success`. Is `discard tryRemoveFile(...)` the intended idiom, or should there be
a `check`-style helper the chapter would prefer to teach? Same question for `tryWriteFile`, which returns
`bool`.

**F. `quit(msg)` writes to stdout.** `x02` shows the message on stdout, stderr empty, rc `1`
(`lib/std/syncio.nim:547`). Intended, or an oversight worth an ERRATA row? A wrapper that captures stderr for
diagnostics will miss it.

**G. `createTempFile` returns a tuple of two different kinds.** `t01` shows `(File, Path)`: an unclosed handle
and a path. Is the handle meant to be used, or is the tuple a convenience whose `File` is usually dropped? The
chapter drops it and uses `genTempPath` when a name is enough.

**H. Reproducibility of a file-writing sample.** The verifier runs samples from the repository root
(`tools/verify-samples.sh`, `cd "$ROOT"`), so this chapter's sample creates and removes a directory under the
system temp dir instead of writing beside the repository. Is that the house rule for any sample that touches
the disk, or would you rather the sample write under `nimcache/`?

## ERRATA candidates

1. **`lib/std/syncio.nim:453-461` — docstring against body.** `open(filename, mode)` is documented as raising
   `IOError`; at the pin it prints `cannot open: …` and exits `1`. Documentation defect, with `f11` as the
   repro. The chapter describes the behaviour, not the docstring.
2. **`lib/std/osproc.nim:878-880` — default options make `args` unusable.** `execProcess` defaults include
   `poEvalCommand`, and `startProcess` asserts when `args` is non-empty (`p01`). Either the default set or the
   failure mode is wrong; a compile-time refusal would be honest. Message gap at minimum.
3. **`lib/std/files.nim:45` and `:616` — `try*` results must be discarded.** Both return a value the caller
   normally ignores (`ErrorCode`, `bool`), and the language refuses a bare call. Documentation gap rather than
   a defect: `doc/stdlib.md` does not show the discard.

## Watch rows

- `readLines(p)` reads the exit code with `peekExitCode` immediately after the loop (`lib/std/osproc.nim:871-876`).
  Whether a child that has already exited but not been waited on always reports its real code there was not
  measured; `p03` returned `0` and `p04` returned `-1` before `waitForExit`.
- `getFileSize` and `fileExists` disagree about what a path is. Whether `fileExists` will gain a `Path` overload
  is not readable from one commit; the chapter keeps `$` at the call.

---

# Verdict — 2026-11-13 (Momo)

Re-run from the sources, not from the pasted rows: `./tools/verify-samples.sh` at pin `4ba90a7` gave
`SUMMARY 20/20 passed, 0 failed`, exit 0. The chapter sample's 16 output lines diff byte-identical against
the block in `en.md` section Samples, including the blank line after `second` and after `a b|c|`. All 46
probe directories were re-run with `nimony c -r main.nim`; the argv and exit-code probes were then run as
`nimcache/c/<hash>/main` (`a01`, `x01`, `x02`, `x03`, `f11`), and `nim2/n1` was compiled with host Nim
2.4.0. I added eight probes of my own for the shapes the table records from a first draft (`e_path`, `e_seq`,
`e_exists`, `e_trf`, `e_trf2`, `e_osparam`, `e_amb`, `e_envnote`) plus a host-Nim `quit` probe. `en.md`,
`id.md` and `samples/` were not touched.

**43 rows stand as written; 6 stand with only a source-line fix (33, 34, 35, 36, 42, 49); 3 are narrowed
(1, 24, 25). Zero open.**

## Answers

**A.** Documentation defect, not a deliberate surface: the `TODO` at `syncio.nim:460-461` says the raise is
the intended behaviour and the quit is interim, while the docstring at `:456-457` promises `IOError`. Keep
ERRATA 1 and the chapter's "quitting overload" wording. `f11` as a binary: stdout `cannot open: missing.txt`,
stderr empty, rc `1`.

**B.** Inherited, not a Nimony defect. Nim 2.4.0 has the same default set
`{poStdErrToStdOut, poUsePath, poEvalCommand}` and the same assert with the identical message
(`~/.local/opt/nim-2.4.0/lib/pure/osproc.nim:76-80`, `:983`). Withdraw ERRATA 2 as a defect; at most a doc
note that `args` needs explicit options without `poEvalCommand`. The chapter's fix is right, and a
compile-time refusal is a wish, not a gap.

**C.** Yes, state it as a pin rule, not a language promise. `getAppFilename` is `/proc/self/exe` on Linux/AIX
and `paramStr(0)` elsewhere (`os.nim:132-135`); both name the built binary, which the driver puts at
`nimcache/c/<hash>/main` (`a02`). `getAppDir` is that directory (`:138-139`). A program must not use it to
find source-adjacent files; whether the driver keeps that layout is a toolchain decision, not part of the
language.

**D.** A migration seam, not drift worth an ERRATA. The Path API owns mutation (`files.nim:45`, `:65`, `:186`,
`:261`; `dirs.nim:49`, `:305`) and the legacy string predicates stayed in `oscommons.nim:111`, `:141`,
re-exported by `os.nim:11`; `$` and `path()` are the bridge. Teach it as the shape. One addition to the module
map: `dirs` re-exports `removeFile` and `tryRemoveFile` (`dirs.nim:11`, `:15`), so `import std/dirs` alone is
enough for those two; `copyFile` and `moveFile` still need `std/files`.

**E.** `discard` is the idiom at the pin; there is no `check`-style helper in `std`. `tryWriteFile` is
`syncio.nim:616` and returns `bool`, not `files.nim:616`. ERRATA 3 stays as a documentation gap with those
citations; `doc/stdlib.md` has no `files` section and shows no discard.

**F.** Stdout at the pin: `syncio.nim:547` is `echo msg; quit QuitFailure`, and `x02` as a binary writes
`fatal: no config` to stdout, stderr empty, rc `1`. But Nim 2.4.0 writes the same message to stderr (my host
run) and `doc/stdlib.md:232` says stderr. Keep the chapter's sentence, add the Nim 2 delta, and file ERRATA 4
against the guide; whether the change from Nim 2 is intended needs the compiler owner, so the chapter states
the pin, not a promise.

**G.** The handle is meant to be used. `createTempFile` creates the file exclusively with mode `0o600` and
returns it open; the docstring says the caller closes `cfile` and removes `path` (`tempfiles.nim:156-180`).
Dropping it leaks a descriptor until exit and leaves the file. When a name is enough, `genTempPath` is the
right call; add the close clause to the chapter's mention.

**H.** Yes. `tools/verify-samples.sh` runs every sample with `cd "$ROOT"`, so writing beside the repository
leaves litter and can collide; `nimcache` is build output, not a runtime scratch area. System temp dir plus
cleanup is the house rule for a disk-touching sample, and this sample does exactly that.

## Claim verdicts

| # | Verdict | Evidence |
| --- | --- | --- |
| 1 | **narrow** | en.md says "nearly every", not everything: `execShellCmd` (`os.nim:373`), `getEnv` (`envvars.nim:140`), `existsEnv` (`:177`), `fileExists` (`oscommons.nim:111`), `paramCount`/`paramStr` (`cmdline.nim`), `open(f,...)` (`syncio.nim:400`) and `readLine(f,s)` (`:506`) do not raise. Keep "nearly"; name `execShellCmd` as the reach-outside exception (it returns `-1` on launch failure) |
| 2 | stands | `f01` runs under `try`; `syncio.nim:577`, `:590` |
| 3 | stands | sample prints `6` |
| 4 | stands | `f02` prints `caught: IOError` |
| 5 | stands | `z01` prints `caught: IOError` for `readFile(".")` |
| 6 | stands | `f13` prints `second` |
| 7 | stands | `f09` prints `one`, `two` |
| 8 | stands | `g06` prints `false`, `true`; `syncio.nim:400-451`, no `{.raises.}` |
| 9 | stands | `f04` prints both lines; sample counts `2`; `syncio.nim:506` |
| 10 | stands | `f10` prints `5` under `try`; `syncio.nim:561` |
| 11 | stands | `f06` prints `5`; `os.nim:443` |
| 12 | stands | `z02` prints `caught: NameNotFound`; `errorcodes.nim:43` |
| 13 | stands | `f11` binary: stdout `cannot open: missing.txt`, stderr empty, rc `1`; `syncio.nim:453-461` |
| 14 | stands | docstring `:454-457` says `IOError`; `:460-461` has the `TODO` and the commented `raise` |
| 15 | stands | `d01` prints the directory and `main.nim`; `paths.nim:26`, `:30` |
| 16 | stands | `d01` prints `main.nim` from `$abs.extractFilename()`; `paths.nim:63`, `:188`, `:289` |
| 17 | stands | `e_path` refuses `echo path("x")` with nine overloads; `syncio.nim:293-331`, `:468` |
| 18 | stands | `f08` reads `data` after `copyFile`; `g05` compiles; `files.nim:65`, `:186`, `:261`, `:45` |
| 19 | stands | `f12` prints `true true`; `oscommons.nim:111`, `:141`, `os.nim:11` |
| 20 | stands | `e_exists` refuses `fileExists(path("x"))` at `oscommons.nim:111` |
| 21 | stands | `d02` prints `created`, `removed`; `dirs.nim:49`, `:305` |
| 22 | stands | `e_trf` prints `expression of type ErrorCode must be discarded` |
| 23 | stands | `f07` prints `Success`; `files.nim:45`, `errorcodes.nim:5` |
| 24 | **narrow** | `removeFile` swallows `NameNotFound` (`files.nim:68-70`) and raises the other codes; `g05` removes a missing file silently. The delta's "ignoring the result becomes a compile error" is true of `tryRemoveFile`, not `removeFile`; do not contrast the missing-file behaviour with Nim 2 |
| 25 | **narrow** | types are right (`t01`); add that `createTempFile` returns the file open and the caller must close it and remove the path (`tempfiles.nim:156-180`); `genTempPath` is the name-only path |
| 26 | stands | `e_amb` prints `ambiguous call: 'getCurrentDir'` with `dirs.nim:440` and `paths.nim:255` |
| 27 | stands | `e_osparam` with only `std/os` prints `0` and `0`; `os.nim:8` exports `cmdline`; `a01` with `one "two three" ""` prints `3`, `[one]`, `[two three]`, `[]` |
| 28 | stands | `a01` binary with `one "two three" ""` prints `{one}`, `{two three}`, `{}`; `cmdline.nim:262` |
| 29 | stands | same run: `[one]`, `[two three]`, `[]` |
| 30 | stands | `e_seq` refuses `echo commandLineParams()` with nine overloads; `syncio.nim:468` |
| 31 | stands | `a02` prints `nimcache/c/mai3r4ykk/main`; `os.nim:132-135` (`/proc/self/exe` on Linux/AIX, `paramStr(0)` elsewhere) |
| 32 | stands | `os.nim:138-139` `splitFile(getAppFilename()).dir` |
| 33 | stands, cite | `e01` prints `fallback`; native declarations are `envvars.nim:140`, `:177`, not `:4`, `:11` (those are the `when defined(nodejs)` branch) |
| 34 | stands, cite | `e01` first draft refused both writes; native `putEnv`/`delEnv` are `:204`, `:244`, not `:17`, `:22` |
| 35 | stands, cite | `e02` prints `true`; native `envPairs` is `:271`, not `:26` |
| 36 | stands, cite | `e05` prints `NIMONY_CHILD=visible`, code `0`; native `putEnv` is `envvars.nim:204`, not `:17` (the `:17` line is the nodejs branch) |
| 37 | stands | `x01` binary rc `3`, stdout `before`; `syncio.nim:538` |
| 38 | stands | `x02` binary: stdout `fatal: no config`, stderr empty, rc `1`; `syncio.nim:547`. New ERRATA 4: `doc/stdlib.md:232` says stderr and Nim 2.4 writes stderr |
| 39 | stands | `x03` binary rc `2`, stdout `bad input`; `syncio.nim:551` |
| 40 | stands | `x01`, `x02`, `f11` all print `FAILURE: nimcache/c/mai3r4ykk/main` with no code |
| 41 | stands | `p05` prints `5`; `os.nim:373`, `:428` |
| 42 | stands, cite | `p01` asserts; the default set is `osproc.nim:881-882`, not `:878-880`; Nim 2.4 has the same set and message |
| 43 | stands | `s02` prints `argv[a b\|c\|]`; `osproc.nim:878` |
| 44 | stands | sample prints `a b\|c\|` then a blank line; `osproc.nim:891-894` adds `'\n'` after every line read |
| 45 | stands | `p02` prints both `out` and `err` in `out[...]`, `code=7`; `osproc.nim:898-920` adds `poEvalCommand` and `poStdErrToStdOut` |
| 46 | stands | `p07` prints the shell message and `code=127` |
| 47 | stands | `p03` `1 0`; `p04` `-1` then `4`; `p08` `L:one`, `L:two`, `code=0`; `osproc.nim:331`, `:871`, `:438`, `:483` |
| 48 | stands | `osproc.nim:871-876`; `readLines` iterates `p.lines`, which waits, then calls `peekExitCode` |
| 49 | stands, cite | `p09` prints `direct to stdout`; on POSIX the handling is `startProcess :331-395` (`poParentStreams` at `:363`, `:376`), not `:642`/`:779` (Windows branch) |
| 50 | stands | host Nim 2.4.0 prints `compiled and ran`, rc `0`, on a nonexistent path |
| 51 | stands | `g04` `undeclared identifier: 'removeFile'` with only `std/os` |
| 52 | stands | `g07` `expected: Path but got: string` at `files.nim:65` |

## ERRATA rulings

1. **Keep.** `lib/std/syncio.nim:453-461` — the docstring promises `IOError`, the body prints `cannot open: …`
   and quits. The `TODO` makes the quit interim; the docstring is still wrong. Documentation defect, with
   `f11` as the repro. The chapter describes the behaviour, not the docstring.
2. **Withdrawn.** The defaults and the assert are inherited from Nim 2.4.0 unchanged
   (`~/.local/opt/nim-2.4.0/lib/pure/osproc.nim:76-80`, `:983`); this is not a Nimony defect and not a
   message gap worth an ERRATA row. The chapter's "pass options explicitly" is the correct teaching.
3. **Keep as a documentation gap, with corrected citations.** `files.nim:45` (`tryRemoveFile`) and
   `syncio.nim:616` (`tryWriteFile`, returns `bool`), not `files.nim:616`. `doc/stdlib.md` has no `files`
   section and shows no `discard`.
4. **New, documentation defect.** `doc/stdlib.md:232` says `quit(msg)` writes to stderr; at the pin
   `syncio.nim:547` uses `echo`, so it writes to stdout (`x02`). Nim 2.4.0 writes stderr (my host run).
   File the guide line; the chapter's stdout sentence is correct at the pin, and the stdout/stderr change
   from Nim 2 should be confirmed as intended.

## Watch rows

Both stay. `readLines` is safe because `p.lines` calls `waitForExit` before `readLines` calls
`peekExitCode` (`osproc.nim:866-876`); a bare `peekExitCode` can still return `-1` while the child runs
(`p04`). `fileExists` has only string overloads (`oscommons.nim:111`, `:204`); no `Path` overload at the pin.

## Notes for the editor

- `:25-27` (claim 1): keep "nearly every"; add `execShellCmd` as the reach-outside exception, since it
  reports a launch failure as `-1` instead of raising (`os.nim:373`, `:425-428`).
- `:96-99` and `:200-212` (claims 24, 50): `removeFile` still ignores a missing file at the pin
  (`files.nim:68-70`); only `tryRemoveFile` forces the discard. Remove the implication that the
  missing-file behaviour changed from Nim 2, and keep the real breaks: module move and `string` → `Path`.
- `:101-105` (claim 25): add that the `File` from `createTempFile` is open and must be closed, and the path
  removed; `genTempPath` is the name-only alternative.
- `:147-149` (claim 38): add the Nim 2 delta for `quit(msg)` — stderr in Nim 2.4.0, stdout at the pin — and
  point the ERRATA at `doc/stdlib.md:232`.
- `:133-141` (claims 33-36): use the native `envvars.nim` lines `:140`, `:177`, `:204`, `:244`, `:271`;
  the current `:4`, `:11`, `:17`, `:22`, `:26` are the `when defined(nodejs)` branch.
- `:163-167` (claim 42): cite `osproc.nim:878-882`; the default set is on `:881-882`.
- `:193-194` (claim 49): cite `osproc.nim:363`, `:376` (POSIX `startProcess`), not `:642`/`:779`.
- `:126-129` (claim 31): cite `os.nim:132-135`.
- Question D: `dirs` itself re-exports `removeFile` and `tryRemoveFile` (`dirs.nim:11`, `:15`); the module
  split in the chapter is still right for `copyFile`/`moveFile`.
- Sample verified: 16 lines, byte-identical; verifier `20/20`. No sample change.
- No other chapter was opened.
