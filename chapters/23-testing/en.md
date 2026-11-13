---
chapter: 23
title: Testing and the Sample Verifier
job: Write checks that run under the pin and use the book's sample verifier so a chapter's claims stay reproducible.
nimony_version: 0.6.3
nimony_commit: 4ba90a781b0b22d0821efaa153c129c37cef6143
toolchain: ~/.local/opt/nimony/4ba90a7
host_compiler: ~/.local/opt/nim-2.4.0
status: frozen
tech_review: Momo 2026-11-13
editorial_pass: 2026-11-13
samples: [samples/23-testing/testing.nim]
glossary_added: [assert, assertionsEnabled, assumeSync, sample verifier]
---

# Testing and the Sample Verifier

## What this chapter is for

A claim about a compiler is worth what its reproducer is worth. Every chapter in this book was checked by
running something, and this chapter is where that habit becomes a file you can run again: a test that fails
loudly when the behaviour changes, and the little verifier that compiles and runs every sample in the
repository against one pinned commit.

The pin makes this simpler and stranger than Nim 2. Simpler, because there is one toolchain and one command.
Stranger, because the testing furniture Nim 2 programmers reach for is not all here: `std/unittest` does not
exist, `doAssert` is not declared, `static:` is not a statement the compiler accepts, and `assert` itself is not
in `system`. What is here is a small, readable assertion module and a process exit code, and that is enough to
write checks that mean something.

## `assert` is not in `system`

The first surprise is the import. In Nim 2, `assert` is there before you write anything. At the pin it is a
template in `std/assertions` (`lib/std/assertions.nim:23`), so a program that imports only `syncio` gets:

```
main.nim(2, 1) Error: undeclared identifier: 'assert'
```

Add the module and the same line compiles. The module is small enough to read in one sitting, and reading it
answers most of the questions this chapter would otherwise have to test:

```nim
import std / [assertions, syncio]

assert 1 + 1 == 2
assert true, "never printed"
echo "survived"
```

That prints `survived` and nothing else: a passing assertion is silent. Three definitions in the module do the
work. `assertionsEnabled` is a compile-time constant, `not defined(danger) and not defined(noAssertions)`
(`:3`). `assert` is a template that expands to a call on `failedAssertImpl` only when that constant is true
(`:23-31`). `raiseAssert` prints `[Assertion Failure] ` plus the message with `echo` and quits with status `1`
(`:11-13`).

That last detail is worth stopping on, because Chapter 21 already showed you the same shape: `quit(msg)` writes
to stdout at the pin. A failed assertion follows the same rule. The message goes to stdout, not stderr, and the
process exits `1`:

```
[Assertion Failure] got 2
```

The message is whatever you passed; with no message the line is `[Assertion Failure] ` with a trailing space and
nothing after it. A test runner that scrapes stderr for failures will see nothing.

`assert` is also allowed inside a `func`, which matters if your checks live in read-only helpers. `failedAssertImpl`
is declared `{.noinline, noSideEffect, noreturn.}` and casts away the effect inside its body
(`lib/std/assertions.nim:15-22`), so the call does not make its caller impure:

```nim
import std / [assertions, syncio]

func clampPositive(x: int): int =
  assert x >= 0, "negative"
  x
echo clampPositive(7)
```

That prints `7`.

## The harness you write yourself

There is no `std/unittest` at the pin. `import std / [unittest]` fails in the parser with
`file not found: …/src/lib/std/unittest.nim`, which is the same shape as the missing modules in Chapter 20: the
error names the path the compiler looked at, not a missing feature. `doAssert` is not declared either, so the
Nim 2 habit of a second, unremovable assertion has no equivalent here.

What you write instead is a procedure with a name, a condition, and two counters. The first version of it that
most people write does not compile, and the error is a good lesson:

```nim
var checks = 0

proc bump() =
  inc checks
```

```
Error: unsynchronized access to global variable 'checks'; pass it to a '.sync' routine or use
'{.cast(assumeSync).}'
```

At the pin a mutable module-level variable may not be touched by name from inside a routine
(`src/nimony/contracts_fir.nim:4120-4127`). The check is about shared state, and it fires even in a
single-threaded program with no threads in it. The message offers two ways past it, and the `.sync` half means
less than it looks: declaring the routine `{.sync.}` does not make the direct access legal, because that clause is
about a global handed to a routine as a `var` or a `ptr` parameter. Passing the counters that way is the first
shape, and it keeps the routine honest about what it changes:

```nim
proc check(name: string; cond: bool; checks, failures: var int) =
  inc checks
  if cond:
    echo "ok - ", name
  else:
    inc failures
    echo "not ok - ", name
```

Or wrap the mutation in the pragma block the message names. The message says "use `{.cast(assumeSync).}`", and
putting that pragma on the variable declaration is refused as `too many arguments for pragma`; the form that
works is the block:

```nim
proc bump() =
  {.cast(assumeSync).}:
    inc checks
```

The `.sync` half of that message is not a licence to declare the harness routine `{.sync.}`. It describes the
var-parameter route above; the block is how you say the same promise about a line that names a global directly.

`{.feature: "assumeSync".}` at module level is the third form: it marks every global in the module as
single-threaded, which is what the compiler's own sources do for their internal state
(`src/nimony/programs.nim:9`). It is a promise, and the compiler takes it.

The counters as parameters are the shape this chapter teaches, because they keep the promise local to the
routine that makes it. `check` never names a global, so it needs no `{.sync.}` of its own; the driver is plain
statements in the module body, where mutable globals are allowed:

```nim
var checks = 0
var failures = 0

check("addition", 1 + 1 == 2, checks, failures)
check("length of hello", "hello".len == 5, checks, failures)
echo checks, " checks, ", failures, " failed"
quit(if failures == 0: 0 else: 1)
```

`quit` is what makes the harness a test rather than a report. The exit code is the only thing a shell, a CI job
or the book's verifier reads.

## Checks that run at compile time

Some claims are cheaper to check while compiling, and the pin has one reliable way to do it, one pragma that works
in exactly one position, and one statement shape that is refused.

`static:` is not a statement the compiler accepts. `static: assert 1 + 1 == 3` stops in sem with
`unsupported statement: staticstmt` (`src/nimony/sem.nim:5873`), for any body, not just assertions.

What works is `when` plus the `{.error.}` pragma, which is judged while the module is analysed and prints your
message with a source position:

```nim
when 1 + 1 != 3:
  {.error: "arithmetic broke".}
```

```
main.nim(3, 5) Error: arithmetic broke
```

`{.assert.}` is the third shape, and two things decide whether it works: where it sits, and whether the prover can
discharge the claim. As a statement inside a body it is accepted, but the claim has to be proven there from what
the code already establishes, which is why every assertion in `tests/nimony/contracts/tassertpragma.nim` sits
behind a guard. `{.assert: x mod 2 == 0.}` at the top of a proc body called with `4` stops the build with
`half.nim(4, 5) Error: cannot prove assertion: x mod 2 == 0 [pass --verbose for the Final IR]`. Put in the
routine-pragma position it crashes the compiler: `proc half(x: int): int {.assert: x mod 2 == 0.}` stops with
`Error: unhandled exception: nifcore.nim(1875, 3) 'b.openTags.len > 0' closeTag with no matching openTag`. That is
a compiler defect to file, not a feature to avoid: the assertion module's own comment points at the pragma — "a
claim the contract prover may rely on is `{.assert: cond.}`" (`lib/std/assertions.nim:33-35`) — so the statement
form is the one to use, and the routine position is the one that is broken.

A type error inside an assertion is reported through the template, which is why the diagnostic names
`assertions.nim` instead of your line. `assert 1` gives `Type mismatch at [position]`, the source line, then
`[1] expected: bool but got: int64 (declared in …/lib/std/assertions.nim(23, 1))`. Read `[1]` as "the first
argument of the template".

## Flags that erase assertions

`assertionsEnabled` is a compile-time constant, so the flags that change it are visible in the binary. At the
pin `-d:danger` and `-d:noAssertions` compile every assertion out, and `-d:release` keeps them. A program whose
only check is `assert 1 == 2` behaves like this:

| Flags | Output | Exit |
| --- | --- | --- |
| none | `[Assertion Failure] ` | `1` |
| `-d:release` | `[Assertion Failure] ` | `1` |
| `-d:danger` | `not reached`, the program continues | `0` |
| `-d:noAssertions` | `not reached`, the program continues | `0` |

The constant itself is the cheapest proof, and the only one that does not depend on a failing program:

```nim
import std / [assertions, syncio]
echo assertionsEnabled
```

`true` with no flags, `true` under `-d:release`, `false` under `-d:danger`, `false` under `-d:noAssertions`.

Two consequences follow. A gate that runs with `-d:danger` proves nothing about assertions, so the book's
verifier runs without flags. And the checks you write by hand are not affected: `check`, `quit` and the counters
are ordinary code, so a harness compiled with `-d:danger` still prints `ok - …` and still returns `1` on a
failure. Only `assert` disappears.

## Running a program and reading its exit code

`nimony c -r` compiles, runs the binary, and prints a `FAILURE:` line when the program exits non-zero. It does
not forward the code. A program ending in `quit 3` produces:

```
before
FAILURE: nimcache/c/<hash>/main
```

and `nimony c -r` itself exits `1`. The binary it names, run directly, exits `3`. That difference matters when a
test distinguishes kinds of failure: the driver flattens them, the binary does not.

The pin's cache layout is why the path is findable. The binary lands under the source directory's
`nimcache/c/<hash>/main`, and the hash is derived from the module's path as the compiler saw it — relative to the
working directory or to a search path — so it changes with how you invoked the build. A script that needs the
real exit code globs `nimcache/c/*/main` after a plain compile rather than hardcoding a hash, and runs it.
Chapter 21 already used that trick for probes about exit codes; here it is the difference between "something
failed" and "this failed".

## The book's verifier

`tools/verify-samples.sh` is the gate every chapter's sample passes through. It is a bash script of about
ninety lines, and its shape is the shape of the contract:

- It refuses to run against the wrong toolchain. `nimony --version` must begin with `0.6.3`
  (`tools/verify-samples.sh:33-40`), and the toolchain directory must be a git checkout whose `HEAD` is
  `4ba90a781b0b22d0821efaa153c129c37cef6143` (`:42-52`). Both failures exit `2`, which is the script's code for
  "toolchain problem, not a sample problem".
- It globs `samples/*/*.nim` (`:55`), so a sample is a file one directory below `samples/`, and a directory of
  supporting files beside it is an input rather than a sample, as Chapter 19's plugins are.
- It compiles and runs each file from the repository root with `nimony c -r` (`:67`), which is why a sample that
  reads a relative path is reading it from the root, not from its own directory.
- It writes every transcript into `tools/verify-samples.log`, one block per file with the exit code in the
  header (`:70-74`), and prints `PASS`/`FAIL` and a `SUMMARY` line (`:76-87`). The script's own exit status is
  the last test (`:88`).

That is the whole contract: one file per chapter under `samples/`, no arguments, no flags, exit `0` on success,
and output that the chapter prints verbatim. CI runs the same script through `./task check`
(`.github/workflows/ci.yml:73`) with a fifteen-minute job limit, so a sample that hangs is a failed build rather
than a stuck one.

The rule that follows is boring and easy to break: a sample must not depend on anything the repository does not
carry. Writing a file is fine if it goes into a temp directory the sample removes; Chapter 21's sample does
exactly that. Reading a path relative to the sample's own directory is not fine, because the verifier's working
directory is the root.

## Nim 2 delta

*What Nim 2 did:* `assert` and `doAssert` were in `system`, `static:` blocks ran at compile time, `std/unittest`
provided `suite`/`test`/`check`, and a module-level `var` was mutable from any routine.

*What Nimony does:* `assert` is a template in `std/assertions` and must be imported; `doAssert` does not exist;
`static:` is refused as an unsupported statement; there is no `unittest`, so the harness is a proc and an exit
code; and a mutable global touched from a routine needs a `var` or `ptr` parameter, an `{.cast(assumeSync).}:`
block, or a `{.feature: "assumeSync".}` module — declaring the routine `{.sync.}` is not enough.

*What breaks if you keep the habit:* `assert` without the import is `undeclared identifier`, `static: assert`
is `unsupported statement`, `import std / [unittest]` is a missing file, and the first `inc` on a global inside
a helper is an `unsynchronized access` error that has nothing to do with threads.

## Samples

`samples/23-testing/testing.nim`, run at the pinned commit:

```
nimony c -r samples/23-testing/testing.nim
```

Expected output, which the sample verifier prints in full:

```
ok - double of 4
ok - length of hello
ok - empty string
3 checks, 0 failed
```

Line by line: the first check calls a `func` that asserts its argument is positive and doubles it; the second
checks a string length; the third checks the length of the empty string, which is the case a test suite forgets;
and the last line is the tally the driver prints before `quit`. The program exits `0`, which is what the
verifier reads.

## Checks

1. Import only `std/syncio` and write `assert 1 == 1`. Expected: `undeclared identifier: 'assert'`.
2. Add `std/assertions` and make the assertion fail. Expected: `[Assertion Failure] ` on stdout, exit `1`.
3. Run the same failing program with `-d:danger`. Expected: no output from the assertion, exit `0`.
4. Print `assertionsEnabled` with no flags and with `-d:noAssertions`. Expected: `true`, then `false`.
5. Put `inc counter` for a module-level `var` inside a proc. Expected: the `unsynchronized access` error.
6. Wrap the same line in `{.cast(assumeSync).}:`. Expected: it compiles.
7. Write `static: assert 1 == 1`. Expected: `unsupported statement: staticstmt`.
8. Write `when 1 + 1 != 3: {.error: "broke".}`. Expected: the build stops with your message and a line number.

## Chapter checklist

draft 2026-11-13 · tech_review 2026-11-13 · editorial_pass 2026-11-13 · frozen 2026-11-13
