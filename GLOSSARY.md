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
| nominal type | A type identified by its declaration, not its shape: two objects with identical fields are different types. | `doc/language.md:548-549` at `4ba90a7`; probe `n1` (2026-11-12) |
| enum type | A named set of ordered values (`type Color = enum red, green, blue`), each usable where an ordinal is expected. | `doc/language.md:182-192` at `4ba90a7`; probes `e1`, `e5` (2026-11-12) |
| variant object | An object whose fields depend on a single tag. | nim-id glossary |
| sum type | A type whose value is exactly one of a fixed set of alternatives, written in Nimony as an object with a `case` section. | `doc/language.md:592-655` at `4ba90a7`; probe `c1` (2026-11-12) |
| discriminator | The field of a variant object that says which alternative the value is; it must be an ordinal type. | `doc/language.md:600-627` at `4ba90a7`; probes `c1`, `c38`, `c40` (2026-11-12) |
| exhaustive case | A `case` whose `of` labels cover every value of the selector's type, so leaving one out is a compile error. | `doc/language.md:1794-1816` at `4ba90a7`; `src/nimony/sem.nim:2699-2748`; probes `c13`, `c19` (2026-11-12) |
| distinct | A new type with the same representation that does not interchange. | nim-id glossary |
| `borrow` | A pragma that generates an operator body for a distinct type by converting each operand to the base, calling the base operation and converting the result back; it does not carry `noSideEffect`, so pure operators are `func`. | `src/nimony/semborrow.nim:17-60`, `doc/porting.md:51-62` at `4ba90a7`; probe `d10` (2026-11-12) |
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
| ref | A managed reference to a heap-allocated cell that several names can share; a `ref` parameter writes through to the caller without `var`, and cannot be nil unless the type says `nil ref T`. | `doc/language.md:774-783` at `4ba90a7`; probes: two `bump(a)` calls print `2`; rebinding the parameter is `cannot mutate expression c` |
| ptr | A raw pointer: an address obtained with `addr`, with no lifetime behind it, no runtime safety and no tracking of the storage it names. | `doc/language.md:774-783`, `:788-791` at `4ba90a7`; probes: `p[] = 20` changes the local, `addr arr[1]` changes the element |
| tuple | An ordered heterogeneous product type with value semantics: fields are read by name or position, and the declared type supplies the names. | `doc/language.md:476-495` at `4ba90a7`; probes 2026-11-12: `y6` (named and positional reads), `t5` (copy on assignment) |
| closure | A procedure bundled with its captured lexical environment. | not yet verified |
| generic | A routine or type parameterized by types rather than concrete values. | not yet verified |
| template | A compile-time substitution construct expanding directly into code. | not yet verified |
| pragma | A compiler directive annotating symbols to modify behavior or code generation. | not yet verified |
| UFCS | Uniform Function Call Syntax allowing `f(x)` to be written and called as `x.f()`. | `doc/language.md:2836-2842` at `4ba90a7`; probed 2026-11-12 (both `5.twice` and `5.twice()`) |
| ARC | Automatic Reference Counting memory management without a cycle collector. | not yet verified |
| ORC | Automatic Reference Counting memory management with cyclic reference handling. | not yet verified |
| sink | A parameter annotation saying the callee takes ownership of the value. At this pin the observation is that the caller's variable is untouched afterwards — a `sink string` and a `sink seq[int]` leave the caller's value and length intact — so the chapter teaches the observable shape, not a transfer mechanism. | `a07`-`a12` at `4ba90a7`; probes: `c06` → `b=payload a='payload'`, `rv40` → length 7 kept, `rv39` → length 3 kept |
| destructor | A special procedure invoked automatically when a value leaves scope to reclaim resources. | not yet verified |
| move semantics | Handing a value from one name to another. `move(x)` copies and then calls `=wasMoved`, leaving a valid empty value behind with no diagnostic; `ensureMove` is the form the compiler checks for last usage. | `lib/std/system.nim:116-126`, `src/hexer/duplifier.nim:1573,1611` at `4ba90a7`; probes `c01`-`c05`, `rv44`, `rv47` |
| bootstrap | Compiling a compiler using an earlier or minimal build of itself. | not yet verified |
| backend | The compiler stage that generates target machine code or C code from the AST. | not yet verified |
| overload set | The candidates one name refers to when several routines share it. | `doc/language.md:1318` at `4ba90a7` |
| overload resolution | Choosing one candidate from an overload set by matching the arguments against the parameter types, in ranked categories. | `doc/language.md:1318-1347` at `4ba90a7`; probed 2026-11-12 |
| method call syntax | Writing the first argument before the name: `x.f(y)` for `f(x, y)`, with the parentheses dropped when no further arguments follow. | `doc/language.md:2836-2842` at `4ba90a7`; probed 2026-11-12 |
| receiver | The value written before the dot in a method call; it becomes the first argument. | `doc/language.md:2836-2842` at `4ba90a7`; probed 2026-11-12 |
| index setter | The `[]=` routine an assignment to an index resolves to; `[]` alone does not make a type writable. | probed at `4ba90a7` (2026-11-12), Chapter 9 probes `s1`/`s3` |
| module-of-origin | The implicit tie-breaker that prefers a candidate declared in the calling module over an equally good imported one. | `doc/language.md:1375-1400` at `4ba90a7`; probed 2026-11-12 with two modules |
| openArray | A slice passed as a parameter or built with `toOpenArray`: a pointer plus a length over another container's storage, indexed from 0, owning nothing. | `doc/language.md:410-425` and `lib/std/system/openarrays.nim:6-21` at `4ba90a7`; probes 2026-11-12: `o1` (array and seq both accepted), `y4` (a write through the view changes the array) |
| view | A value that points at another container's storage instead of copying it; `toOpenArray` builds one, and a `let` view still writes through to storage that may be written. | `lib/std/system/openarrays.nim:6-10` and `src/nimony/derefs.nim:399-407` (comment at `:406`) at `4ba90a7`; probes 2026-11-12: `y4` and `rv3` (a write through a `let` view reaches the array), `rv4` and `rv12` (rejected over a `let` array) |
| place | A location that can be assigned to: a `var`, a field, an index. A by-value parameter is not one, so a routine cannot write it. | `doc/language.md:2350-2372` at `4ba90a7` (Chapter 8); probes 2026-11-12: `rv2`, `rv7`, `rv8` (a write to a by-value `seq`, `tuple` or `array` parameter is rejected) |
| tuple unpacking | Binding each field of a tuple to its own name in one `let`, `var` or `const` statement, with `_` to skip a field and nesting allowed. | `doc/language.md:1669-1710` at `4ba90a7`; probe `t4` prints `42`, `13`, `123` |
| value semantics | Assignment copies the whole value, so changing the copy leaves the source unchanged; a by-value parameter is not a place, so a routine cannot write it at all. `array`, `seq` and `tuple` all behave this way at the pin. | probes 2026-11-12: `y2` (`1`/`9`), `m3` (`2`/`3`), `t5` (`36`/`37`) for assignment; `rv2`, `rv7`, `rv8` (a write to a by-value `seq`, `tuple` or `array` parameter rejected) |

## Terms Nimony adds

| Term | One-line definition | Source |
| --- | --- | --- |
| NIF | The interchange format every stage of the Nimony pipeline reads and writes. | nimony README, checked 2026-11-12 |
| plugin | A compiler extension that operates on NIF nodes, replacing the Nim 2 macro. | `doc/differences.md` at `4ba90a7` |
| borrow checking | Compile-time analysis that rejects aliasing at a call site and a borrow that outlives its owner; it does **not** reject use-after-move at this pin. | `doc/language.md` at `4ba90a7`; gate 3 run, 2026-11-12 |
| explicit nilability | Nil-ability is written in the type (`nil ref T`, `nil ptr T`, `nil cstring`, `nil pointer`, `nil proc`), so a possibly-nil reference is a different type from one that cannot be nil; the cost is that every dereference needs a visible guard. | `doc/language.md:786-788`, `:839-865`, `doc/lenientnils.md:7-19` at `4ba90a7`; probes: `var base: Node` at module level → `which has no default value (it contains a not-nil pointer)`; `if x != nil` compiles, unguarded `x[]` → `cannot prove expression is not nil: x` |
| ErrorCode | The enum of failure categories; the only error channel, because there is no exception object. | probe compiled and run at `4ba90a7` (2026-11-12) |
| passive proc | A proc declared `passive`: calling it needs no `await`, and the same model covers the event loop and `spawn`. | `doc/differences.md` and README at `4ba90a7`; no sample yet |
| verified sample | A code file that compiles and runs at the pinned commit via `nimony c`, proven by `tools/verify-samples.sh`. | book rule, `OUTLINE.md` |
| pinned toolchain | The Nimony build from one commit, installed at a fixed path outside any temp directory, whose version is checked before any sample runs. | `tools/verify-samples.sh`; install at `$NIMONY_HOME`, default `~/.local/opt/nimony/4ba90a7` |
| polymorphic accessor | An accessor declared once over a non-`var` container that yields a mutable location when it has a path to borrow — a `var`, `out` or `lent` parameter, or indirection such as a `seq` field; an inline field of a by-value object has none. Replaces Nim 2's separate `var`/non-`var` overload pair. | `doc/differences.md` at `4ba90a7`; `src/nimony/derefs.nim:466-468` and `:258-314`; probes 2026-11-12 (`r2`, `y7`) |
| let variable | A name bound to one value when the declaration runs and never written again; not an l-value, so it cannot be passed to a `var` parameter or have its address taken. | `doc/language.md:1640-1655` at `4ba90a7` |
| case-sensitive identifier | An identifier that matches only the exact spelling used at its declaration; `step` and `Step` are two names. | `doc/language.md:7` and `doc/differences.md:22` at `4ba90a7`; probe compiled and run 2026-11-12 |
| scope (of a name) | The stretch of source from a declaration to the end of its block, in which that name refers to it; a nested block may declare the same spelling again. | `doc/language.md:4752-4765` at `4ba90a7`; probe compiled and run 2026-11-12 |
| zero value | The value a module-level `var` starts at before any write (`0`, `""`, an all-zero `object`); inside a routine a local must instead be proven written before it is read, whatever its type. | Momo's runs at `4ba90a7` (2026-11-12): module-level `var chosen: int` reads `0`; the same lines inside a proc are rejected with "cannot prove that x has been initialized"; `{.noinit.}` returns raw storage |
| integer type | A whole-number type; `int` is pointer-sized and the general choice, while `int8`…`int64` and the `uint` family carry a fixed width. | `doc/language.md:59-71` at `4ba90a7`; probe compiled and run 2026-11-12 (`sizeof(int)` is 8 on this host) |
| floating-point type | A fractional-number type following IEEE 754; `float` is 64 bits, and integers never convert to it implicitly. | `doc/language.md:126-146` at `4ba90a7`; probe rejected `var i = 3; var f: float = i` with `type mismatch: got: int64 but wanted: float64` |
| narrowing conversion | A conversion from a wider type to a narrower one, written `T(x)`; it is unchecked, so `int8(200)` yields `-56` instead of an error. | `doc/language.md:2159-2162` states the unchecked policy for unsigned targets; `semConvArg` (`src/nimony/sem.nim:854`) and the pin's suite (`tests/nimony/errmsgs/tconvsignchange.nim:84-88`) show signed narrowing wraps too |
| wrapping overflow | Signed arithmetic that exceeds its type continues modulo `2^bits` in two's complement instead of raising; `{.keepOverflowFlag.}` plus `overflowFlag()` is how you detect it. | `doc/language.md:76-104` and `doc/differences.md:24` at `4ba90a7`; probe: `127'i8 + 1'i8` prints `-128`, flag reads `true` |
| range type | A type whose bounds are part of the type (`range[0..9]`); the compiler requires proof that a value fits rather than inserting a runtime check. | `doc/language.md:1467`; probes at `4ba90a7`: `value out of range: 10 notin 0..9`, `cannot prove 'step' is in range 0..9`, a visible guard compiles |
| string | A sequence of bytes indexed from 0, stored as a value (assignment copies it), UTF-8 by convention rather than by enforcement, and carrying no null terminator. | `doc/language.md:280-303` at `4ba90a7`; probes compiled and run 2026-11-12: `"héllo"` has length 6 and `ord` of index 1 is 195; a copy grows without touching the original |
| null terminator | The `'\0'` byte C uses to mark the end of a string; a Nimony `string` does not store one, so `toCString` writes it on demand and may have to copy first. | `doc/differences.md:15-18`; `lib/std/system/stringimpl.nim:1095-1106` at `4ba90a7` |
| cstring | The C-compatible pointer to a zero-terminated char array, used at the C boundary; `len` on it calls `strlen`, and `cstring(s)` converts only from a literal. | `doc/language.md:306-341` and `lib/std/system/stringimpl.nim:377` at `4ba90a7`; `src/nimony/sem.nim:880` refuses a non-literal |
| slice | A range of a string or `seq` written `s[a..b]` or `s[a..<b]`; the result is a new value with copied elements, and out-of-range bounds are clamped instead of checked. An `array` has no slice operator — it gets a view through `toOpenArray`. | `lib/std/system.nim:649-652`, `:658-668` and `lib/std/system/stringimpl.nim:706-717` at `4ba90a7`; probes: `"clamped"[0..20]` prints `clamped`; `xs[5..1]` is empty and `xs[2..10]` clamps |
| escape sequence | A backslash pair inside a string literal that stands for another byte (`\n`, `\t`, `\\`, `\"`, `\x41`); a raw string disables it. | probe compiled and run at `4ba90a7` (2026-11-12): `"a\tb"` contains a tab, `"\x41"` is `A` |
| raw string | A string literal written `r"..."` in which a backslash is literal and no escape is processed. | probe compiled and run at `4ba90a7` (2026-11-12): `r"a\tb"` prints `a\tb` |
| concatenation | Joining two strings into a new one with `&`, as opposed to appending in place with `add` on a `var`. | `doc/language.md:303`; `lib/std/system/stringimpl.nim:1062-1063` at `4ba90a7` |
| if expression | The `if` form used where a value is expected (`let x = if c: a else: b`); the `else` is required because every path must produce a value. | `doc/language.md:2069-2081` at `4ba90a7`; probe: omitting `else` fails with ``cannot prove that `x has been initialized`` (`src/nimony/contracts_fir.nim:4165`) |
| case expression | The `case` form used where a value is expected; the branch's last expression is the result, and branch statements before it are side effects. | `doc/language.md:2086-2103` at `4ba90a7`; probe: a two-statement branch prints its statement then yields its last expression |
| when | Compile-time branching: each condition must be a constant `bool`, only the taken branch is compiled, and both statement and expression forms exist. | `doc/language.md:1872-1901`, `:2082-2084` at `4ba90a7`; probes: `when false:` with a type error inside compiles; `when x > 0` over a `var` fails with `cannot evaluate expression at compile time` |
| exhaustive case | A `case` whose branches cover every value the selector's type can hold, so no `else` is needed; the compiler checks it and names what is missing for enums. | `doc/language.md:1800-1804`; `src/nimony/sem.nim:2746` and `:2748` at `4ba90a7`; probes: `missing: {blue}` for an enum, bare `not all cases are covered` for `int` and `char` |
| labelled break | `break <blockname>`, which leaves the named `block` and everything inside it; plain `break` leaves only the innermost loop and never a `block`. | `doc/language.md:1946-1990`, `doc/differences.md:23` at `4ba90a7`; probes: labelled break exits two nested loops, unlabelled break lets the outer loop continue |
| block expression | A `block` used as a value, where the last expression inside is the result — a way to keep a scratch variable out of the surrounding scope. | `doc/language.md:2105-2119` at `4ba90a7`; probe: a block summing `1..4` evaluates to `10` |
| for loop | A loop that runs its body once for each value an iterator yields (`for i in 0..3`); the bounds are written at the loop, and a stored `0..3` slice is not iterable. | `doc/language.md:4041-4056` and `lib/std/system/iterators.nim:14-44` at `4ba90a7`; probe: `let r = 0..3; for i in r` → `Type mismatch … items(r)` |
| loop variable | The variable a `for` loop declares for its body; its type comes from the iterator, and its scope ends with the body. | `doc/language.md:4041-4056` at `4ba90a7`; probe: using `i` after the loop → `undeclared identifier: i` |
| iterator | A routine that yields values to a `for` loop instead of returning once; `..`, `..<`, `countup` and `countdown` are the ones this chapter uses. | `doc/language.md:4041-4056` and `lib/std/system/iterators.nim:1-93` at `4ba90a7` |
| countup | The counting-up iterator with a positive step (`countup(0, 6, 2)` yields `0 2 4 6`); its upper bound must lie below `high(T)`. | `lib/std/system/iterators.nim:76-93` at `4ba90a7`; probe printed `0 2 4 6` |
| countdown | The counting-down iterator (`countdown(5, 1, 2)` yields `5 3 1`), inclusive at both ends. Its step is an unconstrained ordinal (`V: Ordinal`), so a negative step compiles and climbs away from the target instead of descending. | `lib/std/system/iterators.nim:59-74` at `4ba90a7`; probes printed `3 2 1` and `5 3 1`; Momo's run at the same pin printed `5 6 7 8 …` for `countdown(5, 1, -1)` |
| proc | A routine that may have side effects, declared with `proc`; its body is a statement block whose last expression, or `result`, is the return value. | `doc/language.md:2211-2262` at `4ba90a7`; probe: a block body ending in `5` returns `5` |
| func | A `proc` treated as `noSideEffect` by default — no global state, no side-effecting calls, no mutation through `ref`/`ptr`; `{.sideEffect.}` overrides the default. | `doc/language.md:3115-3121` at `4ba90a7`; probes: `echo` inside a `func` → `cannot call a routine with side effects from a .noSideEffect context`; `{.sideEffect.}` builds |
| result | The implicitly declared variable holding a routine's return value; assigning it and reaching the end of the body returns it, and a path that never assigns it fails to build. | `doc/language.md:2243-2245` at `4ba90a7`; probe: `cannot prove that result has been initialized` |
| var parameter | A parameter written `var T` that aliases the caller's variable, so writes are visible outside; the argument must be a place, not a value. | `doc/language.md:2350-2372` at `4ba90a7`; probe: `bump(7)` → `cannot pass 7 to var/out T parameter` |
| out parameter | A parameter written `out T` that the routine must set on every path; the compiler checks the routine, not the call, and only the every-path check is enforced. | `doc/language.md:2765-2790` at `4ba90a7`; probes: a missing branch → `cannot prove that y has been initialized`; reading it before writing reads the caller's current value (`var v = 9` → `before 9`), which contradicts `:2765` — see `ERRATA.md` |
| sink parameter | A parameter written `sink T` that lets the routine take over the argument's storage; for a `string` at this pin the caller's variable still reads its value after the call. | `doc/language.md:3626-3636` at `4ba90a7`; probe: `take(text)` leaves `text` as `abc` |
| default argument | The value a parameter takes when the call omits it; it is re-evaluated at every call, and at this pin it may not name an earlier parameter. | `doc/language.md:2234-2241` at `4ba90a7`; probes: `twice()` → `94`; `int = x` dies with `[Bug] could not find symbol: x.0` — see `ERRATA.md` |
| named argument | An argument given as `name = value`, which may appear out of order; an unknown name is rejected. Probed, not quoted: the guide never describes the form. | probe at `4ba90a7`: `pair(b = 7, a = 3)` → `37`, `pair(c = 1)` → `named argument not found`; only doc trace is `doc/tags.md:33`, tag at `src/models/nimony_tags.nim:277` |
| range proof | The compile-time obligation `lo <= value <= hi` that a value must satisfy before it becomes a `range` type; no runtime check is emitted, and the proof must be visible where the value is used. | `doc/differences.md:58-65` and `src/nimony/contracts_fir.nim:2386-2387` at `4ba90a7`; probes: a comparison guard compiles on a parameter, an `in` guard does not, and a guard in a caller does not travel |

| nil narrowing | The compiler treating a nilable place as non-nil (not to be confused with a narrowing conversion) inside a guarded branch, because a comparison established the fact. It holds for locals and parameters; it does not reach through a field or a module-level variable, which are current limits of the analysis, not rules of the type system. | `src/nimony/inferle.nim:137-142`, `src/nimony/contracts.nim:249-275` at `4ba90a7`; probes: `if x != nil` compiles, `if p.n != nil: p.n.data` → `cannot prove expression is not nil: p.n` (`rv11`), local copy prints `5` (`vx4`), module-level guard → `cannot analyze expression is not nil: g` (`d04`) |

| ownership | The name responsible for a value: assignment copies, so each copy is owned by the name that holds it, and the copy is destroyed when that name leaves scope. Types define `=destroy`/`=copy`/`=sink`/`=wasMoved` hooks (`lib/std/system.nim:112-116`); the compiler has no tracked owner token, and an opt-in `owned` annotation exists behind `{.feature: "ownedRefs".}` without being used in this book. | `lib/std/system.nim:112-116`, `doc/language.md:893-960` at `4ba90a7`; probes: `move` of a `string`/`seq`/`ref` empties the old name, `move` of an `int` does not (`c01`-`c05`) |
| borrow | A temporary right to read storage owned by something else, held by a view (`openArray`, `lent`, a `var T` result or parameter) and tracked along an access path. A borrow may borrow only from the routine's first parameter when the routine returns one, may not outlive its subject, and blocks mutation of the borrowed path and its prefixes. | `doc/language.md:2485-2696`, `src/nimony/derefs.nim:258-314`, `src/nimony/contracts_fir.nim:669-695` at `4ba90a7`; probes: `b01`-`b08`, `a05`, `a06` |
| alias | Two paths that reach overlapping storage in one call. A mutable argument may not overlap another argument when that one is mutable, or when it reads the caller's storage: it is a view, `lent`, `varargs`, a value passed by const reference (over 24 bytes unless `{.bycopy.}`), or a type that can own the heap. The compiler reports `mutable argument aliases with mutable/immutable parameter`. A short plain-data copy (two `int`s) is not treated as an alias. | `src/nimony/contracts_fir.nim:4242-4289`, `:4285-4338`, `:4340-4351`, `src/nimony/sizeof.nim:282-288`, `:306-318` at `4ba90a7`; probes: `a02` (refused); `a11`/`a09`/`a10` (refused); `a12`/`d01`/`rv15` 16-byte object accepted; `rv18` 24-byte accepted, `rv19` 32-byte refused, `rv33` 25-byte refused, `rv37` 32-byte with `{.bycopy.}` accepted; `rv42`/`rv10` inherited and variant objects refused |
| moved-from state | What `move(x)` leaves in `x`: a valid empty value, because `move` is a library routine that copies and then calls `=wasMoved` (`lib/std/system.nim:123-126`). Empty for `string` and `seq`, `nil` for a `ref`, unchanged for a type with no `=wasMoved` specialization such as `int`, because the generic hook is a magic that only acts through a specialization (`src/nimony/magics.nim:128`). Reading it again is not diagnosed; `ensureMove` is the checked form. | `lib/std/system.nim:116,123-126`, `src/hexer/duplifier.nim:1573`, `:1611` at `4ba90a7`; probes `c01`-`c05`: `""`/`0`, empty, `nil`, both fields emptied, `5` |
| `ensureMove` | The checked form of a move: a magic rather than a routine (`lib/std/system.nim:120-121`), it asks the last-usage analysis before it acts and is a static error when the moved-from name is read afterwards — `not the last usage of: a`. The analysis runs only on a name it can track (`var`, `let`, `sink` parameter in a local scope); a module-level variable is refused whatever follows. Contrast with `move`, which is never diagnosed. | `src/hexer/duplifier.nim:100-129,1573,1611`, `doc/language.md:3591-3594` at `4ba90a7`; probes `rv44`, `rv47`, `zz13`/`zz16` |

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
