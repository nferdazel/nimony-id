# Glossary

Terms that will otherwise be ambiguous across chapters. Each term has a one-line definition and an explicit source field naming where the definition came from (`nim-id glossary`, or `not yet verified`).

| Term | One-line definition | Source |
| --- | --- | --- |
| compiler | A program that translates source code into a binary. | nim-id glossary |
| compile time | While compilation runs; before the program starts. | nim-id glossary |
| runtime | While the program is running. | nim-id glossary |
| value | The content stored in a variable. | nim-id glossary |
| variable | A name for a value. | nim-id glossary |
| constant | A value that does not change. | nim-id glossary |
| data type | The kind of a value; it decides which operations are valid and how much memory it uses. | nim-id glossary |
| type | Short for data type; used in prose and code. | nim-id glossary |
| declaration | A statement that introduces a new name. | nim-id glossary |
| initialization | Filling in the first value. | nim-id glossary |
| identifier | A name for a variable, type, procedure, or module. | nim-id glossary |
| error message | Compiler output that explains a problem. | nim-id glossary |
| procedure | A routine that may have side effects (`proc`). | nim-id glossary |
| function | A routine with no side effects (`func`). | nim-id glossary |
| loop | A construct that repeats a block of code. | nim-id glossary |
| branching | Choosing which path to execute (`if`, `case`, `when`). | nim-id glossary |
| array | A fixed-size collection of elements of the same type. | nim-id glossary |
| seq | A dynamically sized collection of elements of the same type (`seq`). | nim-id glossary |
| object | A composite type with named fields. | nim-id glossary |
| variant object | An object whose fields depend on a single tag. | nim-id glossary |
| distinct | A new type with the same representation that does not interchange. | nim-id glossary |
| type alias | Another name for an existing type, with no new type. | nim-id glossary |
| range | The bounds from start to end (`a..b`, `a..<b`). | nim-id glossary |
| index | The position of an element in a collection, starting at 0. | nim-id glossary |
| element | A single value inside a collection. | nim-id glossary |
| literal | A value written directly in code (`42`, `"text"`, `@[1, 2]`). | nim-id glossary |
| expression | A piece of code that produces a value. | nim-id glossary |
| statement | A unit of code that does something, not always producing a value. | nim-id glossary |
| parameter | The name of a value a procedure receives. | nim-id glossary |
| default value | The value used when an argument is not given. | nim-id glossary |
| inclusive | The end bound counts (`0..5` includes 5). | nim-id glossary |
| exclusive | The end bound does not count (`0..<5` stops at 4). | nim-id glossary |
| ordinal type | A type whose values can be ordered and counted (`int`, `char`, `enum`). | nim-id glossary |
| stack trace | The list of calls shown when the program stops on a defect. | nim-id glossary |
| binary | The compiled file a machine can run. | nim-id glossary |
| import | Using the contents of another module. | nim-id glossary |
| export | Marking a module symbol that may be used from outside. | nim-id glossary |
| effect | A procedure trait the compiler can check (`raises`). | nim-id glossary |
| macro | A compile-time procedure that takes and produces an AST. | nim-id glossary |
| abstract syntax tree | A tree structure that represents source code. | nim-id glossary |
| untyped | A macro parameter received before type checking. | nim-id glossary |
| concept | A requirement on the shape of a type, checked during overloading. | nim-id glossary |
| thread | A path of execution inside one process. | nim-id glossary |
| suite | A group of tests in `unittest`. | nim-id glossary |
| test case | One check inside a suite. | nim-id glossary |
| FFI | A way to call code from another language, here C. | nim-id glossary |
| exit code | The number a process returns to its caller. | nim-id glossary |
| entry point | The first file or procedure that runs. | nim-id glossary |
| package | A distributable unit of code that can be installed. | nim-id glossary |
| output | Data a program sends out. | nim-id glossary |
| input | Data that goes into a program. | nim-id glossary |
| result | A value produced by an operation or procedure. | nim-id glossary |
| assignment | Writing a value into a variable or field. | nim-id glossary |
| comparison | An operation that compares two values and yields a `bool`. | nim-id glossary |
| flag | A boolean value that marks a state. | nim-id glossary |
| integer | A whole-number type. | nim-id glossary |
| float | A fractional-number type. | nim-id glossary |
| warning | A compiler message about code worth checking. | nim-id glossary |
| test | An automated check of code behavior. | nim-id glossary |
| Nimony | A redesign and reimplementation of the Nim compiler and toolchain. | not yet verified |
| ref | A managed reference to a heap-allocated value subject to compiler memory management. | not yet verified |
| ptr | An unmanaged raw memory address without runtime safety or tracking. | not yet verified |
| tuple | An ordered heterogeneous product type with value semantics. | not yet verified |
| closure | A procedure bundled with its captured lexical environment. | not yet verified |
| generic | A routine or type parameterized by types rather than concrete values. | not yet verified |
| template | A compile-time substitution construct expanding directly into code. | not yet verified |
| pragma | A compiler directive annotating symbols to modify behavior or code generation. | not yet verified |
| UFCS | Uniform Function Call Syntax allowing `f(x)` to be written and called as `x.f()`. | not yet verified |
| ARC | Automatic Reference Counting memory management without a cycle collector. | not yet verified |
| ORC | Automatic Reference Counting memory management with cyclic reference handling. | not yet verified |
| sink | A parameter annotation specifying ownership transfer of the passed value. | not yet verified |
| destructor | A special procedure invoked automatically when a value leaves scope to reclaim resources. | not yet verified |
| move semantics | Transferring resources from one variable to another without copying. | not yet verified |
| bootstrap | Compiling a compiler using an earlier or minimal build of itself. | not yet verified |
| backend | The compiler stage that generates target machine code or C code from the AST. | not yet verified |

## Terms Nimony adds

| Term | One-line definition | Source |
| --- | --- | --- |
| NIF | The interchange format every stage of the Nimony pipeline reads and writes. | nimony README, checked 2026-11-12 |
| plugin | A compiler extension that operates on NIF nodes, replacing the Nim 2 macro. | `doc/differences.md` at `4ba90a7` |
| borrow checking | Compile-time analysis that rejects aliasing at a call site and a borrow that outlives its owner; it does **not** reject use-after-move at this pin. | `doc/language.md` at `4ba90a7`; gate 3 run, 2026-11-12 |
| explicit nilability | Nil-ability is written in the type (`nil ref T`), so a possibly-nil reference is a different type from one that cannot be nil. | probe compiled and run at `4ba90a7` (2026-11-12) |
| ErrorCode | The enum of failure categories; the only error channel, because there is no exception object. | probe compiled and run at `4ba90a7` (2026-11-12) |
| passive proc | A proc declared `passive`: calling it needs no `await`, and the same model covers the event loop and `spawn`. | `doc/differences.md` and README at `4ba90a7`; no sample yet |
| verified sample | A code file that compiles and runs at the pinned commit via `nimony c`, proven by `tools/verify-samples.sh`. | book rule, `OUTLINE.md` |
| pinned toolchain | The Nimony build from one commit, installed at a fixed path outside any temp directory, whose version is checked before any sample runs. | `tools/verify-samples.sh`; install at `/Users/sachiel/.local/opt/nimony/4ba90a7` |
| polymorphic accessor | An accessor declared once over a non-`var` container that still yields a mutable location, replacing Nim 2's separate `var`/non-`var` overload pair. | `doc/differences.md` at `4ba90a7` |
| let variable | A name bound to one value when the declaration runs and never written again; not an l-value, so it cannot be passed to a `var` parameter or have its address taken. | `doc/language.md:1640-1655` at `4ba90a7` |
| case-sensitive identifier | An identifier that matches only the exact spelling used at its declaration; `step` and `Step` are two names. | `doc/language.md:7` and `doc/differences.md:22` at `4ba90a7`; probe compiled and run 2026-11-12 |
| scope (of a name) | The stretch of source from a declaration to the end of its block, in which that name refers to it; a nested block may declare the same spelling again. | `doc/language.md:4752-4765` at `4ba90a7`; probe compiled and run 2026-11-12 |
| zero value | The value a module-level `var` starts at before any write (`0`, `""`, an all-zero `object`); inside a routine a local must instead be proven written before it is read, whatever its type. | Momo's runs at `4ba90a7` (2026-11-12): module-level `var chosen: int` reads `0`; the same lines inside a proc are rejected with "cannot prove that x has been initialized"; `{.noinit.}` returns raw storage |
| integer type | A whole-number type; `int` is pointer-sized and the general choice, while `int8`…`int64` and the `uint` family carry a fixed width. | `doc/language.md:59-71` at `4ba90a7`; probe compiled and run 2026-11-12 (`sizeof(int)` is 8 on this host) |
| floating-point type | A fractional-number type following IEEE 754; `float` is 64 bits, and integers never convert to it implicitly. | `doc/language.md:126-146` at `4ba90a7`; probe rejected `var i = 3; var f: float = i` with `type mismatch: got: int64 but wanted: float64` |
| narrowing conversion | A conversion from a wider type to a narrower one, written `T(x)`; it is unchecked, so `int8(200)` yields `-56` instead of an error. | `doc/language.md:2159-2162` states the unchecked policy for unsigned targets; `semConvArg` (`src/nimony/sem.nim:854`) and the pin's suite (`tests/nimony/errmsgs/tconvsignchange.nim:84-88`) show signed narrowing wraps too |
| wrapping overflow | Signed arithmetic that exceeds its type continues modulo `2^bits` in two's complement instead of raising; `{.keepOverflowFlag.}` plus `overflowFlag()` is how you detect it. | `doc/language.md:76-104` and `doc/differences.md:24` at `4ba90a7`; probe: `127'i8 + 1'i8` prints `-128`, flag reads `true` |
| range type | A type whose bounds are part of the type (`range[0..9]`); the compiler requires proof that a value fits rather than inserting a runtime check. | `doc/language.md:1467`; probes at `4ba90a7`: `value out of range: 10 notin 0..9`, `cannot prove 'step' is in range 0..9`, a visible guard compiles |

## Retired in Nimony

Terms a Nim 2 reader will look for. They stay listed: deleting them would hide the word the reader arrives
with. "Replacement" is what the book uses instead, not a like-for-like swap.

| Term | State in Nimony | Replacement | Source |
| --- | --- | --- | --- |
| macro | removed from the design; still compiles at the pin as Nim 2 compatibility surface | plugin | `doc/differences.md` future section; Momo compiled and ran a macro at `4ba90a7` (2026-11-12) |
| exception (`raise` / `try` / `except`) | removed; no exception objects | `ErrorCode` with `{.raises.}` | probe at `4ba90a7`; `doc/differences.md` |
| effect tracking (`tags`, `gcsafe`) | declared but not enforced | none — do not promise enforcement | `doc/differences.md` at `4ba90a7` |
| closure iterator | not implemented | inline `iterator`, or an explicit state machine | `doc/differences.md` at `4ba90a7` |
| implicit generic via type class | not implemented | explicit generic parameter with a concept | `doc/differences.md` at `4ba90a7` |
| `var T` overload of `[]` | removed permanently | polymorphic accessor: ``func `[]`(x: Container): var Element`` | `doc/differences.md` at `4ba90a7` |
| null-terminated `string` | removed permanently | `string` is a plain value; `cstring` costs a copy at the C boundary | `doc/differences.md` at `4ba90a7` |
| multi-methods | removed from the design; `method` still compiles and dispatches at the pin for Nim 2 compatibility | single dispatch plus an explicit `case` | `doc/language.md` at `4ba90a7`; Momo's two-parameter dispatch test (2026-11-12) |
| case-insensitive identifiers (default) | removed; Nimony is case-sensitive | spell identifiers exactly; `{.feature: "ignoreStyle".}` restores Nim 2 style rules per module | `doc/differences.md` at `4ba90a7` |
| raising integer overflow | removed; signed overflow wraps | `{.keepOverflowFlag.}` plus `overflowFlag()` where it matters | `doc/differences.md` at `4ba90a7` |
