---
chapter: 21
title: Files, Processes, and the Outside World
job: Read and write files, read arguments and environment, return exit codes, and run a subprocess.
nimony_version: 0.6.3
nimony_commit: 4ba90a781b0b22d0821efaa153c129c37cef6143
toolchain: ~/.local/opt/nimony/4ba90a7
host_compiler: ~/.local/opt/nim-2.4.0
status: frozen
tech_review: Momo 2026-11-13
editorial_pass: 2026-11-13
samples: [samples/21-files-processes/files.nim]
glossary_added: [Path, process exit code, poEvalCommand, poUsePath, environment variable, temp directory]
---

# Files, Processes, and the Outside World

## What this chapter is for

Every program so far has been a closed box: it reads its own literals, computes, and prints. That is a
demonstration, not a tool. This chapter is where the program starts to touch things that outlive it — a file on
disk, the arguments it was started with, the environment it inherited, the exit code it hands back to whatever
ran it, and another program it starts itself.

Two rules organise the whole chapter. Anything that reaches outside the process can fail, and the compiler makes
you say so: nearly every routine here is marked `{.raises.}`, so a call without a `try` is a compile error, not
a runtime surprise. `execShellCmd` is the exception the chapter meets later, and it reports a launch failure as
`-1` instead. And a path is its own type at the pin, not a string with slashes in it, which is where a Nim 2
program written against `os` stops compiling.

## A file, read and written whole

The smallest useful pair is `writeFile` and `readFile` (`lib/std/syncio.nim:590`, `:577`). Both are
`{.raises.}`, which is the compiler telling you the truth about a disk:

```nim
import std / [syncio]

try:
  writeFile("note.txt", "first\n")
  echo readFile("note.txt").len
except ErrorCode as e:
  echo "failed: ", e
```

That prints `6`: five characters and the newline. The failure is a value from the same enum Chapter 15 taught,
not an exception object; a missing file arrives as `IOError`, and so does a read aimed at a directory instead of
a file. `readFile` has no "does it exist" check built in, and it does not need one.

A second `writeFile` to the same name replaces the file. It never appends, and it never merges: after
`writeFile("t.txt", "first version\n")` and then `writeFile("t.txt", "second\n")`, `readFile` returns `second`.
That is worth knowing before you use `writeFile` in a loop and wonder where the earlier lines went.

Appending needs an explicit file handle and an open mode (`lib/std/syncio.nim:400`):

```nim
var f: File
discard open(f, "note.txt", fmAppend)
f.writeLine("third")
close(f)
```

`open` in that form returns a `bool` and does not raise. The reading side of the same type has two shapes:
`readLine(f, s: var string): bool` returns whether a line was read (`lib/std/syncio.nim:506`), which is how you
count lines without knowing the file size; `readAll(f)` returns everything left (`lib/std/syncio.nim:561`), and
it is `{.raises.}` while the `readLine` pair is not. `getFileSize` (`lib/std/os.nim:443`) and `fileExists` are
the two taps on the side of the file that do not open it.

One overload of `open` is a trap. `open(filename, mode)` — the form that returns a `File` instead of filling a
`var` — does not raise on a missing file: it prints `cannot open: missing.txt` and ends the program with exit
code `1` (`lib/std/syncio.nim:453-461`). The docstring above it still says it raises an `IOError`, and the line
that would have done so is commented out with a `TODO` beside it. Read the body, not the docstring: the form
that quits is not the form you want inside a `try`.

## A path is not a string

At the pin a path has a type, `Path`, built with `path("...")` and turned back into a string with `$`
(`lib/std/paths.nim:26`, `:30`). Join two with `/`, take one apart with `extractFilename` or `splitFile`, and
resolve a relative one against the working directory with `absolutePath` (`lib/std/paths.nim:63`, `:188`,
`:289`). The type is not cosmetic. `echo somePath` is refused, because the nine `write` overloads of Chapter 20
have no `Path` in them, while `echo $somePath` prints; the conversion is explicit on purpose, since a path is
data about the filesystem, not text a reader wants.

The API is split across two modules, and the split is not symmetric:

- the mutators are in `std/files` and take a `Path`: `removeFile`, `copyFile`, `moveFile`, `tryRemoveFile`
  (`lib/std/files.nim:65`, `:186`, `:261`, `:45`); `std/dirs` re-exports the two removers
  (`lib/std/dirs.nim:11`, `:15`), so a module that already imports `dirs` reaches them without a second import;
- the predicates are in `std/os` and take a `string`: `fileExists`, `dirExists`
  (`lib/std/private/oscommons.nim:111`, `:141`), re-exported by `lib/std/os.nim:11`;
- the directory operations are in `std/dirs` and take a `Path`: `createDir`, `removeDir`
  (`lib/std/dirs.nim:49`, `:305`).

So `fileExists(somePath)` is a type mismatch and `fileExists($somePath)` is not, while `removeDir(somePath)`
wants the `Path` and refuses the string. Two modules, two conventions, and the compiler will not let you guess
wrong silently — it just makes you look.

`tryRemoveFile` deserves its own paragraph. It returns an `ErrorCode`, so a bare call is
`expression of type ErrorCode must be discarded`, and the success value is the enum member `Success`
(`lib/std/files.nim:45-62`). Discard it when you only want the attempt, or compare it when the reason matters.
`removeFile` is the same operation with a `try` contract instead, and it treats a missing file as nothing to do
(`lib/std/files.nim:65-70`): a cleanup step needs neither an existence check nor a caught `NameNotFound`.

Temporary work belongs in a temporary directory. `createTempDir(prefix, suffix)` returns a `Path` under the
system temp directory; `createTempFile` returns a `(File, Path)` tuple whose handle is already open and whose
documented contract is that you close the handle and remove the path (`lib/std/tempfiles.nim:181`, `:156-171`);
`genTempPath` gives the name without creating anything (`:103`). A sample that writes beside the repository
leaves litter behind; a sample that writes into a temporary directory removes it at the end and is safe to run
twice.

One ambiguity is worth knowing before you meet it: importing `dirs` and `paths` together gives two
`getCurrentDir`, one in each module (`lib/std/dirs.nim:440`, `lib/std/paths.nim:255`), and a call is then
`ambiguous call: 'getCurrentDir'`. Name the module, or import only the one you use. The two return the same
type; the compiler simply will not pick for you.

## Arguments arrive as a list

`paramCount` and `paramStr` are the primitive pair (`lib/std/cmdline.nim:211`, `:218`), and
`commandLineParams` returns them as a `seq[string]` (`lib/std/cmdline.nim:262`). All three come with `std/os`,
which re-exports the module (`lib/std/os.nim:8`).

The list is the argument vector, not a string to be split: an argument containing a space arrives as one
element, and an empty argument arrives as an empty string. Running a probe with `one "two three" ""` prints
`[one]`, `[two three]`, `[]` from `paramStr`, and the same three from `commandLineParams`. There is no quoting
to get right and no shell involved, because the shell already did its work before your program started.

`commandLineParams` is a `seq`, which means it is unprintable by `echo` for the reason Chapter 20 gave: print
its elements in a loop, not the sequence.

The other name in the module is not what a reader expects. `getAppFilename` returns the running executable
(`lib/std/os.nim:132-135`), and under the pin that is a file inside `nimcache` — `nimcache/c/<hash>/main` in a
probe — not the name of the source you compiled. Use it to find out what the process is, never to find files
that sit beside your source. `getAppDir` is the same directory by another name (`lib/std/os.nim:138`).

## The environment you inherit

`getEnv` is total and takes a default, `existsEnv` answers a question, and `putEnv`/`delEnv` are the writes
(`lib/std/envvars.nim:140`, `:177`, `:204`, `:244`). The reads never raise; the two writes do, so they belong in
a `try` like everything else that changes state outside the process. `envPairs` iterates the whole environment
(`lib/std/envvars.nim:271`), which is the honest way to answer "what did I inherit" instead of guessing at
variable names.

A variable you set is visible to a child process you start, because the environment is inherited, not copied
into the child by hand. A probe that sets `NIMONY_CHILD` and then runs `/usr/bin/env` through a shell sees the
value. That is the whole mechanism behind configuration by environment: no API, a process-level table.

## Exit codes are part of the interface

A program says two things when it ends: what it printed, and what it returned. `quit(value: int)` sets the
second (`lib/std/syncio.nim:538`); a program ending in `quit(3)` exits with status `3`. The string forms are
the trap: `quit(msg)` prints the message to **stdout** and exits `1` (`lib/std/syncio.nim:547`), and
`quit(msg, errorcode)` prints and exits with your code (`:551`). A wrapper script that separates stdout from
stderr will not find that message where it looked, and it is the one habit here that a Nim 2 reader has to
unlearn: Nim 2.4.0 and `doc/stdlib.md:232` both send the message to stderr, the pin sends it to stdout.

Behind the driver, a nonzero exit is reported as a failed build step: `nimony c -r` prints
`FAILURE: nimcache/c/<hash>/main` and reports failure, without naming your code. That line is the driver's, not
yours, and it is the reason a deliberately failing probe looks like a broken build until you read the output
above it.

From the other side, `execShellCmd` returns the exit status of the shell command it ran
(`lib/std/os.nim:373`, `:428`), so `execShellCmd("exit 5")` is `5`. It inherits your streams, so the child's
output appears without being captured, and that is the right call when the child is the point — a formatter, a
test runner — rather than data you want to inspect. It is also the one routine in the chapter that does not
raise when the launch itself fails: there is no shell to run, and the answer is `-1` (`lib/std/os.nim:425-428`).

## Running another program

`std/osproc` is the module for a child you want to talk to, and its defaults are the first thing to understand.
`execProcess(command, args = [...])` looks like the direct call, but its default options include
`poEvalCommand` (`lib/std/osproc.nim:878-882`; the set is on `:881-882`), and a command line that is evaluated
by a shell cannot also take an argument list. The combination that looks natural therefore asserts at run
time, with the message `args` has to be empty when using poEvalCommand. The fix is to pass options explicitly,
and the two useful shapes are:

```nim
let printed = execProcess("/usr/bin/printf", args = ["%s|", "a b", "c"],
                          options = {poUsePath})
echo printed

let (noise, code) = execCmdEx("/bin/sh -c 'echo err 1>&2; exit 7'")
echo noise.len, " ", code
```

The first passes an argument vector: each element is one `argv` entry, so `a b` stays one argument. The second
evaluates a shell line, folds stderr into stdout — hence the `poStdErrToStdOut` in the default set — and returns
the exit code beside the output. Its output ends with a newline, so `echo noise` prints a blank line after it;
print a length, a comparison, or the first line instead.

A command that does not exist is not an error code from your program: the shell reports it, `execCmdEx` returns
status `127` and the message as output. A child that fails for its own reasons returns its own code, and the
distinction between "I could not start it" and "it started and failed" is the exit status and nothing else.

When the output is large or arrives slowly, take the process apart:
`startProcess` (`lib/std/osproc.nim:331`), `inputStream` and `outputStream`, then `readLine` while it runs and
`waitForExit` at the end (`lib/std/osproc.nim:438`). `peekExitCode` answers `-1` while the child is still
running (`:483`), which is how the loop that reads output and the loop that cannot block stay separate.
`readLines(p)` is the convenience that does both and returns `(seq[string], int)` (`lib/std/osproc.nim:866-876`).
With `poParentStreams` instead of the capture options, the child writes straight to your terminal and there is
nothing to read (`lib/std/osproc.nim:363`, `:376`).

Everything in this section is `{.raises.}`, and the tags on the declarations say why: starting a process is an
effect, and a failing `fork`, a missing executable, or a dead pipe all arrive as `ErrorCode`. Wrap the call, not
the loop.

## Nim 2 delta

*What Nim 2 did:* `import std/os` gave you `removeFile(file: string)`, which said nothing when the file was not
there — it ran to completion on a nonexistent path. Path-taking `std/files` existed, but the string form was
always within reach.
*What Nimony does:* `std/os` no longer carries `removeFile`; it is `std/files.removeFile(file: Path)` and it is
`{.raises.}` (`lib/std/files.nim:65`), with `tryRemoveFile` returning the reason as an `ErrorCode`. It is still
tolerant of a missing file (`lib/std/files.nim:68-70`), so the change is the module and the type, not the
tolerance. The predicates stayed in `std/os` and still take a `string`, so half of a Nim 2 file program compiles
and half does not. The exit-code habits break too: `quit(msg)` writes to stdout at the pin and to stderr in
Nim 2.4.0.
*What breaks if you keep the habit:* `removeFile("x.txt")` is `undeclared identifier: 'removeFile'` with only
`std/os` imported, and after the import is fixed, the string is a type mismatch until it becomes
`path("x.txt")`. The habit of ignoring the result becomes a compile error too, since an `ErrorCode` cannot be
discarded silently.

## Samples

`samples/21-files-processes/files.nim`, run at the pinned commit:

```
nimony c -r samples/21-files-processes/files.nim
```

Expected output, which the sample verifier prints in full:

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

Line by line: the length of `first\n` (`6`); the whole file after the second `writeFile`, which replaced it
(`second`, then the blank line `echo` adds after a string that already ends in one); the length after appending
`third\n` (`13`); the line count from the `readLine` loop (`2`); `getFileSize` (`13`); existence before and
after a removal (`true false` then `Success`, `false`); the fallback from an unset variable (`fallback`), a
value that was set (`visible`), and the answer after deleting it (`false`); no arguments under the verifier
(`0`); an argument vector preserved by the child (`a b|c|`, with the newline `execProcess` adds after it); and
the merged stderr plus exit code from a shell child (`4 7`).

## Checks

1. Write `"alpha\n"` to a file, read it back, and print `true` when the length is `6`. Expected: `true`.
2. Call `readFile` on a name you know is missing, without a `try`. Expected: a compile error naming `.raises`,
   before anything runs.
3. Now call it inside a `try`. Expected: the caught `ErrorCode` prints as `IOError`.
4. Run your binary with `one "two three"` from a shell and print each `paramStr(i)` inside brackets. Expected:
   `[one]` and `[two three]`, two lines.
5. Set `BOOK21_VALUE`, start `/usr/bin/env` through `execCmdEx`, and search the output for the value. Expected:
   the value appears in the child's output.
6. Run `quit(7)` at the end of a program. Expected: the driver reports `FAILURE` and the binary's own exit
   status is `7` when you run it directly.

## Chapter checklist

draft 2026-11-13 · tech_review 2026-11-13 · editorial_pass 2026-11-13 · frozen 2026-11-13
