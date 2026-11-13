---
appendix: A
title: Nim 2 to Nimony: the delta table
job: One consolidated table of everything at the pin that a Nim 2 habit gets wrong, each row traceable to the chapter that proved it.
nimony_version: 0.6.3
nimony_commit: 4ba90a781b0b22d0821efaa153c129c37cef6143
toolchain: ~/.local/opt/nimony/4ba90a7
host_compiler: ~/.local/opt/nim-2.4.0
status: frozen
tech_review: assembled from Chapters 3-24, each tech-reviewed by Momo 2026-11-12 to 2026-11-13; introduces no new claim
editorial_pass: 2026-11-13
samples: []
glossary_added: []
---

# Nim 2 to Nimony: the delta table

## What this appendix is for

Every chapter that changes a Nim 2 habit ends with a *Nim 2 delta* box. Read one at a time they are the right
teaching order and the wrong lookup order: a reader porting a file wants one page that says what moved. This is
that page.

Nothing here is new. Each row is the chapter delta box compressed to two contrast clauses, and the last column
names the chapter whose technical review settled it plus the source line that review cited where it cited one.
The chapter is the authority for the wording; the source file is the authority for the behaviour. Where a row's
source column carries a chapter and no line, the behaviour was demonstrated by a run at the pin and the chapter's
`review.md` holds the probe.

## How to read a row

*Nim 2.4.0* is what the same source does on the official Nim 2.4.0 tarball. *Nimony at `4ba90a7`* is what it does
on the pinned toolchain, `nimony 0.6.3`. Neither column is a recommendation; the third column of the book is the
route, and it is the chapter, not this table.

Two kinds of row sit in this table, and they read the same way but fail differently. A **removed** row means the
Nim 2 lines no longer compile. A **changed** row means they still compile and now do something else, which is the
expensive kind.

## Spelling and constants

| Area | Nim 2.4.0 | Nimony at `4ba90a7` | Established by |
| --- | --- | --- | --- |
| Identifier spelling (changed) | Style-insensitive: `myValue`, `my_value` and `myvalue` are one name. | Exact spelling; `{.feature: "ignoreStyle".}` restores the old reading per module. | Ch 3; `doc/language.md:7` |
| What `const` may contain (changed) | Evaluated by a restricted compile-time evaluator. | A routine call is accepted while every argument can be evaluated at compile time, so `const Twice = double(4)` builds. | Ch 3; `doc/language.md:24-31` |
| A `const` that names a `var` (removed) | Compile error, reported at the `const`. | Still an error, now reported as `undeclared identifier` against the `var`. | Ch 3; ERRATA watch list |

## Numbers

| Area | Nim 2.4.0 | Nimony at `4ba90a7` | Established by |
| --- | --- | --- | --- |
| Signed overflow (changed) | Raised `OverflowDefect` with checks on, which a debug build did and a release build did not. | Wraps always; the C backend is built with `-fwrapv`. | Ch 4; `doc/differences.md:24`, `doc/language.md:76-90` |
| Noticing an overflow (removed) | `try`/`except OverflowDefect`, or `overflowChecks: off`. | The `try` is dead code that still compiles; `{.keepOverflowFlag.}` plus `overflowFlag()` is the explicit route. | Ch 4; `doc/language.md:76-90` |
| An overflowing constant (changed) | Not measured for this book. | `expression overflow at compile time`. | Ch 4, Ch 18 |

## Strings and C strings

| Area | Nim 2.4.0 | Nimony at `4ba90a7` | Established by |
| --- | --- | --- | --- |
| Terminator (removed) | A `'\0'` past the last character; `s[s.len]` reads it. | No terminator; `s[s.len]` stops the program with an `AssertionDefect`. | Ch 5; `doc/differences.md:15-18` |
| `cstring(s)` on a `var string` (removed) | A cast. | Refused: only a string literal converts; `toCString(s)` writes the zero on demand and refuses a `let`. | Ch 5, Ch 22; `lib/std/system/stringimpl.nim:1095-1109` |
| Writing the terminator back (changed) | Implicit in the conversion. | `toCString(var string)` may make the buffer unique first; `fromCString` copies back. | Ch 5; `lib/std/system/stringimpl.nim:1095-1109` |

## Control flow

| Area | Nim 2.4.0 | Nimony at `4ba90a7` | Established by |
| --- | --- | --- | --- |
| Unlabelled `break` (changed) | Could leave a `block` that sat inside a loop. | Always the innermost loop; a named `block` plus `break <name>` says what it leaves, and `{.feature: "anonBlockBreaks".}` restores the old reading per module. | Ch 6; `doc/differences.md:23` |
| `elif` after a `case` `of` branch (removed) |Accepted. | Rejected with a hint to nest an `if` in the `else`. | Ch 6; `src/nimony/sem.nim:3305` |
| A `range` value (changed) | Defended at run time, so a correct value was accepted however far it travelled. | Proven by the contracts engine at compile time; an unprovable value is an error even when it is in range. | Ch 7; `doc/differences.md:58-62` |
| How the proof is written (changed) | Any guard that ran first. | Visible where the value is used, and on a parameter as two comparisons: `n in 0..9` does not count. | Ch 7; ERRATA watch list |

## Procedures and types

| Area | Nim 2.4.0 | Nimony at `4ba90a7` | Established by |
| --- | --- | --- | --- |
| `var T` overloading (removed) | Two `[]` accessors, one on `var Container` returning `var Element`, one on `Container` returning `lent Element`. | One accessor, polymorphic on the location; a `var`/non-`var` pair is a single ambiguity. | Ch 9; `doc/differences.md:31-43` |
| A `var` result (changed) | Returned from an inline field of a by-value parameter. | Rejected with `cannot borrow from b.v` unless the result has a path to borrow — a `var`, `out` or `lent` parameter, or indirection such as a `seq` field. | Ch 9; `src/nimony/derefs.nim:466-468`, `:258-314` |
| Write-through indexing (removed) | Went through the `var` overload automatically. | Needs a `[]=` you declare; without one the assignment fails with a built-in candidate list. | Ch 9; `src/nimony/semcall.nim:1436` |
| `echo` of a custom type (changed) | Found and applied the user's `$`, printing `P1`. | Writes the value itself; the user's `$` is a routine you call, so write `echo $p`. | Ch 11; `doc/language.md:466-471` |
| Reading a variant field (changed) | `FieldDefect: field 'width' is not accessible …` when the branch is not active. | Unchecked: the read returns the union's storage. | Ch 12; watch row |
| Assigning the discriminator (changed) | `FieldDefect: assignment to discriminant changes object branch`. | A plain field write; the old bytes stay. | Ch 12; watch row |

## Pointers, ownership and errors

| Area | Nim 2.4.0 | Nimony at `4ba90a7` | Established by |
| --- | --- | --- | --- |
| Nil-ability (removed) | Every `ref`, `ptr`, `pointer` and `cstring` may be nil, and declarations are zeroed, so a module-level `var x: ref int` is legal and silently nil. | In the type: a plain `ref T` cannot be nil, a not-nil pointer has no default value, and an unguarded dereference does not compile. `nil T` is the nullable form. | Ch 13; `doc/lenientnils.md:141-155` |
| Nil as "absent" (changed) | A nil argument. | The parameter must be written `nil T`. | Ch 13 |
| Aliasing in one call (removed) | `take(s, s)` compiled and printed `1`. | `mutable argument aliases with immutable parameter`. | Ch 14; `src/nimony/contracts_fir.nim:4340-4351` |
| Mutating while iterating (changed) | Compiled, then died with `the length of the seq changed while iterating over it`. | `'s' is borrowed and cannot be mutated`, at the line. | Ch 14 |
| `move` and `sink` (changed) | Same behaviour, including the empty value left behind. | Same; `ensureMove`'s refusal is worded differently (`not the last usage of: a`). | Ch 14; `src/hexer/duplifier.nim:1611`, `lib/std/system.nim:123-126` |
| Exceptions (removed) | `raise newException(IOError, "msg")`, `.msg`, a stack trace, `except IOError as e`. | `ErrorCode` values: `raise IOError`, no allocation, no message, no trace; `.msg` is a compile error. | Ch 15; `doc/porting.md:106` (ERRATA) |
| Declaring what raises (changed) | Optional `{.raises: [].}`. | The default is non-raising; a raising routine says `{.raises.}` and its callers sit in `try`/`except`. | Ch 15 |

## Modules, globals and visibility

| Area | Nim 2.4.0 | Nimony at `4ba90a7` | Established by |
| --- | --- | --- | --- |
| `echo` without an import (removed) | `system` was injected everywhere. | Import `std/syncio` before the first `echo`. | Ch 16 |
| A mutable global touched from a routine (removed) | Allowed. | Refused: pass it as a `var` or `ptr` parameter, use an `{.cast(assumeSync).}:` block, or a `{.feature: "assumeSync".}` module. Declaring the routine `{.sync.}` is not enough. | Ch 16, Ch 23 |
| An import inside a routine (changed) | Refused: imports sit at the top level. | Accepted, and it takes effect for the whole module, so a call in another routine resolves the name even when the proc holding the import never runs. | Ch 16; `doc/language.md:4646` (ERRATA), `src/nimony/sem.nim:5947-5953` |

## Generics, templates and macros

| Area | Nim 2.4.0 | Nimony at `4ba90a7` | Established by |
| --- | --- | --- | --- |
| A type class in a parameter position (changed) | An implicit generic, substituted per call. | Accepted by the front end and then crashes the backend on a second instantiation; write `[T: Addable]`. | Ch 17; `src/nimony/sigmatch.nim:1825-1827` |
| A `typed` template parameter (changed) | Worked; Nim 2.4.0 prints `41` and `42` for the two templates the pin refuses. | Accepted and unusable; write `untyped` or a real type. | Ch 18 |
| Code generation (changed) | A `macro` returning a `NimNode` from `std/macros`. | A plugin: a separate program, NIF in and NIF out, no in-process tree. A `macro` with an `untyped` parameter still compiles at the pin — compatibility surface, not the route. | Ch 18, Ch 19; `doc/differences.md:19` |
| `{.dirty.}` (changed) | The escape hatch for a body that needs the caller's names. | Inert without `{.feature: "untyped".}`, and then it injects in both directions. | Ch 18; `src/nimony/semdecls.nim:1183` |

## Standard library, files and processes

| Area | Nim 2.4.0 | Nimony at `4ba90a7` | Established by |
| --- | --- | --- | --- |
| `std/strformat` and `std/re` (removed) | Ordinary imports. | Absent at the pin; `%` from `std/strutils` covers the first, and there is no `re` replacement. | Ch 20 |
| Sequence concatenation (removed) | `xs & ys`. | `&` is string-only; `concat` from `std/sequtils`. | Ch 20 |
| Atomics (changed) | A wrapper type, `Atomic[int]`, with `load()` and `store()` members. | An operation on a plain `var`; lowers to `__atomic_*` builtins. | Ch 20 |
| `removeFile` (changed) | `std/os.removeFile(file: string)`, silent on a missing file. | `std/files.removeFile(file: Path)`, `{.raises.}`, `tryRemoveFile` for the reason — and still silent on a missing file, so the delta is the module and the type, not the tolerance. | Ch 21; `lib/std/files.nim:65`, `:68-70` |
| `quit(msg)` (changed) | Writes the message to stderr. | Writes it to stdout. | Ch 21; `doc/stdlib.md:232` (ERRATA) |

## The C boundary

| Area | Nim 2.4.0 | Nimony at `4ba90a7` | Established by |
| --- | --- | --- | --- |
| `cstring(var string)` (removed) | A direct conversion. | Only a string literal converts; `toCString` for a `var`, and nothing for a `let`. | Ch 22 |
| Nullability of C types (changed) | `ptr`, `pointer` and `cstring` are nullable unless told otherwise. | The bare type is non-null; the nullable type is written `nil cstring`. | Ch 22 |
| `$` for `cstring` (removed) | Reachable from `system`. | Comes from `std/strutils`. | Ch 22 |
| An argument array (removed) | `allocCStringArray`. | `alloc0` plus a `cast` to `ptr UncheckedArray[nil cstring]`, and `dealloc` at the end. | Ch 22 |

## Testing and concurrency

| Area | Nim 2.4.0 | Nimony at `4ba90a7` | Established by |
| --- | --- | --- | --- |
| `assert` and `doAssert` (changed) | Templates in `system`. | `assert` is in `std/assertions` and must be imported; `doAssert` does not exist. | Ch 23; `lib/std/assertions.nim:3` |
| `static:` blocks (removed) | Ran at compile time. | `unsupported statement: staticstmt`; use `when` with `{.error.}`. | Ch 23 |
| `std/unittest` (removed) | `suite`, `test`, `check`. | Absent: `lib/std/` carries no `unittest.nim`. The harness is a proc and an exit code. | Ch 23; ERRATA watch list |
| `async` and `await` (removed) | `std/asyncdispatch`, futures, `await`. | `.passive` procs, `Continuation`, `delay` and `complete`; `await` is an undeclared identifier. | Ch 24; `doc/differences.md:8-9` |
| `thread` and `spawn` (changed) | Thread procedures for parallel work. | The same `.passive` mechanism, and one continuation can be handed to a pool. `complete` runs a chain to its end, so a call from regular code waits. | Ch 24 |

## What is deliberately not in this table

Four classes of thing are left out, and the omission is the point.

**Design intent.** The design pages describe a language further along than the pin. `doc/differences.md` files
"macros replaced by plugins" under the future, so a surviving `macro` is compatibility surface; a row about what
the design will remove would be a promise the pin cannot keep. Every row above is behaviour observed or stated at
`4ba90a7`.

**Missing diagnostics.** A check that does not exist is a defect candidate in `ERRATA.md`, not a delta: the Nim 2
source compiles on both compilers, and the reader's fix is the same on both. `delay()` with no suspension point is
the live example — an assertion out of the code generator instead of a diagnostic, filed upstream as
`nim-lang/nimony#2985` with the fix in `nim-lang/nimony#2988`.

**Behaviour that is identical in both compilers.** `cstring"a\nb"` is four bytes on Nim 2.4.0 as well, so the raw
`cstring` literal is a documentation gap inherited by the pin, not a delta. It is in `ERRATA.md` and in Chapter
22's text, and it has no row here.

**Platform behaviour.** A few rows are measured on macOS arm64 only — the C callback's `const` split, the
`dynlib` library name, the value of `errno` after a failed call. Where the chapter measured them it says so; this
table does not generalise them.
