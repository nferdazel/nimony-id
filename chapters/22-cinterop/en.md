---
chapter: 22
title: The C Boundary
job: Bind a C function, map its types, and cross the cstring boundary deliberately.
nimony_version: 0.6.3
nimony_commit: 4ba90a781b0b22d0821efaa153c129c37cef6143
toolchain: ~/.local/opt/nimony/4ba90a7
host_compiler: ~/.local/opt/nim-2.4.0
status: frozen
tech_review: Momo 2026-11-13
editorial_pass: 2026-11-13
samples: [samples/22-cinterop/cinterop.nim]
glossary_added: [importc, exportc, cdecl, header, dynlib, cstring array]
---

# The C Boundary

## What this chapter is for

Every routine in this book so far was written in Nimony and checked by Nimony. A C function is different: the
compiler sees a signature you typed and no body at all, so nothing inside it is verified. This chapter is about
declaring that signature honestly, mapping the types so the C side reads what you meant, and crossing the string
boundary without pretending the two string models are the same.

The rule that organises the chapter is blunt: at an `importc` declaration the type is a promise, not a check.
Everything that goes wrong at this boundary goes wrong because the promise was wrong — a `long` declared as
`int`, a pointer declared non-null that C leaves null, a callback whose parameter list differs by one `const`.

## Declaring a C function

`{.importc.}` names the C symbol and `header` names the file the generated C must include
(`src/nimony/sempragmas.nim:346` accepts the pair). The smallest complete declaration is a libc routine:

```nim
import std / [syncio]

proc strlen(s: cstring): int {.importc, header: "<string.h>".}
echo strlen(cstring"hello")
```

That prints `5`. The name is taken from the Nimony identifier unless the pragma carries a string, and the header
does not introduce the symbol: Nimony writes a prototype from your declaration, and without a header it emits one
whose C name is attached with an assembler label, `cstrlen_0(...) __asm__("strlen")`. What `header` adds is the
real declaration. `major` is the proof — it prints `0` with `<sys/types.h>` in the pragma, and without the header
the link fails with an undefined `_major`, because `major` is a macro in that header and no such symbol exists.
Name the header whenever the C side has one.

`dynlib` loads the library instead of linking it, and the string is the platform's name, not a portable one:
`dynlib: "libm.so.6"` failed on this machine with `could not load: libm.so.6`, while `dynlib: "libm.dylib"`
resolved and `cos(0.0)` printed `1.0`. If the code has to run on more than one system, that string is a build
choice, not a constant to copy.

A variadic C routine takes `{.varargs.}`, and the arguments after the fixed ones are passed as written:

```nim
proc printf(fmt: cstring): cint {.importc, header: "<stdio.h>", varargs.}
discard printf(cstring"%s %d\n", cstring"hi", 42)
```

One detail in that line is not a trick of `printf`: the literal after `cstring` is a *generalized string
literal*, and the lexer reads it raw (`src/nifler2/nimlexer.nim:1061-1064`), so `\n` stays two characters. The
output of that call was `hi 42\n` on one line, backslash included. Nim 2.4.0 reads it the same way, so this is a
gap in the manual rather than a change at the pin.

A callable that is a macro in C can be declared as a routine, and the header is what makes it work: the C
compiler expands the name before it ever asks for a symbol, which is why `major` returns `0` when the pragma
names `<sys/types.h>`. A macro that is not a function call — `sizeof`-like expressions, `offsetof`, a constant —
is a different matter: `{.importc: "sizeof(struct stat)".}` with the header is refused by the C compiler as
`called object type 'unsigned long' is not a function`, and without the header the link fails on the symbol
`sizeof(struct stat)`.

## The types a signature needs

The C-width aliases arrive with `system`, so no import is needed: `cint` is `int32`, `cdouble` is `float64`,
`csize_t` is `uint`, `clong` follows the platform (`int` on this one). `sizeof` answers in bytes at the pin, and
the four values that matter here are `4` for `cint`, `8` for `cdouble`, `8` for a `pointer` and `8` for
`csize_t`.

Those aliases are the whole point of the chapter's first rule. `cint` is not `int`, and a value that is already
typed has to be converted: `csize_t(sizeof(cint))` is written out because `sizeof` returns an `int`, while a bare
literal such as the `3` below converts on its own.

```nim
proc memset(p: pointer, c: cint, n: csize_t): pointer {.importc, header: "<string.h>".}
var buf: array[4, char]
discard memset(addr buf[0], cint(ord('x')), 3)
```

`buf` then reads `xxx`, and `buf[3]` is still `'\0'` — an array of `char` is a C buffer, and its address is what
C wants.

A C struct is mapped as an `{.importc.}` object whose fields you list in order, and the type name is the C one:

```nim
type
  DivT {.importc: "div_t", header: "<stdlib.h>", nodecl.} = object
    quot: cint
    rem: cint

proc cdiv(a, b: cint): DivT {.importc: "div", header: "<stdlib.h>".}
let d = cdiv(7, 2)
```

`d.quot` and `d.rem` print `3` and `1`: a small struct comes back by value and is read field by field. The same
mapping works for an output parameter — POSIX `stat` filled a `Stat` object through `ptr Stat` and returned `0`,
and the generated C contains `struct stat` and the real `stat(...)` call. `out Stat` is the same pointer with the
initialisation rule from Chapter 8 attached: the declaration the manual itself shows (`doc/language.md:2778`)
emitted `stat("main.nim", (&st))` and filled the object.

`sizeof` on such a type asks C, not Nimony: an `{.importc: "struct stat".}` object with one field declared still
reports `144`, because the C emitter writes `sizeof(struct stat)`
(`src/lengc/genexprs.nim:527-533`). The field list is for reading fields, not for telling the compiler how big
the C object is.

## A string at the boundary

Nimony's `string` is length-carrying and may contain any byte; C's `char*` ends at the first zero. The pin gives
you three ways across, and they are not interchangeable.

`cstring"..."` is a literal in read-only memory, raw as described above. `toCString(s)` takes `var string` and
gives a pointer to that string's own bytes, so the view is writable and the string is not copied:

```nim
var greeting = "hello"
let asC = toCString(greeting)
echo $asC
asC[0] = 'H'
echo greeting
```

That prints `hello` and then `Hello`. A `let` cannot be passed: `toCString` on a `let` is
`cannot pass s to var/out T parameter`, and `cstring(x)` on anything other than a literal is refused with the
message `Only string literals can be converted to cstring. Use` ``toCString`` `for safe conversion.`
(`src/nimony/sem.nim:880`).

`fromCString(c)` copies the other way. `$c` also copies, but `$` for `cstring` lives in `std/strutils` at the pin,
not in `system`: without the import, `$c` fails as a type mismatch against every `$` candidate. `echo c` fails
for the reason Chapter 20 gave: the nine `write` overloads have no `cstring` in them.

The two models disagree at the first zero byte, and the disagreement is silent:

```nim
var withNul = "a\0b"
echo withNul.len, " ", strlen(toCString(withNul))
```

`3 1`. The Nimony string has three bytes; C counted one. Nothing warns, because nothing on either side is
allowed to look past the terminator.

## Null pointers have their own type

At the pin `ptr`, `pointer` and `cstring` cannot be nil unless the type says so, and a C function is exactly
where the type is most likely to be wrong. `getenv` returns a null pointer for a name that is not set, so its
return type has to be `nil cstring`:

```nim
proc getenv(name: cstring): nil cstring {.importc, header: "<stdlib.h>".}
let missing = getenv(cstring"BOOK22_NOPE")
echo isNil(missing)
```

That prints `true`, and `getenv(cstring"PATH")` gives a value whose `isNil` is `false`. Declaring the same
routine with a plain `cstring` return also compiles, and `isNil` on the answer still printed `true` — the
compiler believed the promise and inserted no check, because a C return cannot be checked. The type is the only
guard there is.

The same holds on the way in. A parameter that C is allowed to leave null takes `nil pointer` or `nil cstring`,
and a bare `nil` argument to a `pointer` parameter is `expected non-nil value`
(`src/nimony/contracts.nim:280`). With `nil pointer` in the signature, `gettimeofday(addr tv, nil)` ran and
printed `true` for a plausible timestamp.

An array of C strings needs `nil cstring` elements, since the null terminator of the array is a null pointer:

```nim
var slots: array[2, nil cstring]
slots[0] = cstring"one"
slots[1] = nil
let first: nil cstring = slots[0]
if first != nil:
  echo strlen(first)
```

Both the assignment and the check are fussier than they look, and the fuss starts at the declaration.
`var slots: array[2, cstring]` is refused before anything is assigned:
`'slots' is of type 'array[0..1, cstring not nil]', which has no default value`. With `nil cstring` elements the
array exists, but a `nil` assigned into one of the other element type is `expected non-nil value`; checking
`slots[0] != nil` in place is `cannot analyze expression is not nil: slots[0]` (`src/nimony/contracts.nim:293`),
and `isNil(slots[0])` fails the same way, so the copy into `first` is what makes the check work.
`cast[cstring](slots[0])` also gets past it, by promising what the check could not prove.

## Calling back, and the one thing C checks

`{.exportc.}` puts a C name on a Nimony routine, and `{.compile.}` adds a C file to the build, resolved relative
to the source file:

```nim
{.compile: "helper2.c".}
proc book_cb(x: cint): cint {.exportc: "book_cb", cdecl.} = cint(x + 1)
proc helper_call(x: cint): cint {.importc, header: "helper2.h".}
```

With `helper2.c` declaring `book_cb` and calling it, `helper_call(41)` printed `42`. The symbol is really there:
`nm` on the binary shows `_book_add` for the plain `exportc` probe, with the underscore the platform's C
toolchain adds. `{.cdecl.}` lands in the generated C as `N_CDECL(int, book_add)(...)`, and on this platform the
macro expands to nothing because the default convention is already C's.

The one place the C compiler does check you is a callback's prototype, and it is stricter than the Nimony side.
`qsort` wants `int (*)(const void *, const void *)`; the pin emits a `{.cdecl.}` Nimony proc with `pointer`
parameters as `int (void *, void *)` — no `const` — and clang refuses that with
`incompatible function pointer types`. Declaring the parameter as `pointer` and passing
`cast[pointer](cmp)` compiled and sorted `3 1 2` into `123`. That cast is not cosmetic: it is the C type system
being told that the two signatures are close enough, which is the same promise the whole boundary runs on.

## What the boundary does not check

Nothing about an `importc` routine is analysed. Its body is treated as external, so the effect tags are whatever
you wrote and the signature is not compared with the C header:
`src/nimony/contracts_fir.nim:6036-6041` skips body traversal for extern procs entirely. A wrong `cint` where C
has a `long` compiles on both sides and reads the wrong bytes; a `proc` that takes two parameters and is called
with three is a C error at most.

A C global is a binding, not a copy: `var errno {.importc, header: "<errno.h>".}: cint` read `7` after being
written, and after `open` on a missing file returned `-1` the same variable read `2` — the real `errno`
(`src/nimony/contracts_fir.nim:5791`). Declaring it `cint` was right here; declaring a C `long` as `cint` would
have compiled and read half a value.

That is the chapter's whole method: read the C prototype, write the Nimony type that matches it exactly, and
treat every deviation as a bug you will find at run time rather than at compile time.

## Nim 2 delta

*What Nim 2 did:* `cstring(x)` converted a `var string` directly, `$` for `cstring` was reachable from `system`,
`allocCStringArray` built an argument array, and `ptr`/`pointer`/`cstring` were nullable unless told otherwise.
*What Nimony does:* only a string literal converts to `cstring`; a `var string` goes through `toCString`, and a
`let` cannot go at all. `$` for `cstring` comes from `std/strutils`. There is no `allocCStringArray`: the array
is `alloc0` plus a `cast` to `ptr UncheckedArray[nil cstring]`, and `dealloc` at the end. Nullability is
inverted — the bare type is non-null and the nullable type is written `nil cstring`.
*What breaks if you keep the habit:* `cstring(someVar)` is the conversion error quoted above, `echo cstringValue`
is a mismatch against the nine `write` overloads, `allocCStringArray` is `undeclared identifier`, and a
`getenv` declared as returning `cstring` compiles while promising something the C function does not keep.

## Samples

`samples/22-cinterop/cinterop.nim`, run at the pinned commit:

```
nimony c -r samples/22-cinterop/cinterop.nim
```

Expected output, which the sample verifier prints in full:

```
5
hello
4 3
3 1
xxx true
4 8
true
Hello
3 1
3
true
```

Line by line: the length of `hello` through `strlen` (`5`); the same bytes as a Nimony string (`hello`); the raw
`cstring` literal and the escaped Nimony literal side by side (`4 3`); the C struct returned by value (`3 1`);
the buffer C filled (`xxx`, with the fourth byte still zero, `true`); `sizeof` of `cint` and of the importc
struct (`4 8`); a null `getenv` answer (`true`); the writable view changing the string (`Hello`); a Nimony string
with an embedded zero against C's count (`3 1`); the checked array element (`3`); and the null slot (`true`).

## Checks

1. Declare `strlen` with `header` and call it on `cstring"abcdef"`. Expected: `6`.
2. Call `strlen` on a Nimony `let` string without converting. Expected: a type mismatch naming `string` and
   `cstring`.
3. Call `toCString` on a `let`. Expected: `cannot pass … to var/out T parameter`.
4. Write `cstring"a\nb"` and `"a\nb"` and print both lengths. Expected: `4` and `3`.
5. Declare `getenv` returning a plain `cstring`, then call it with a name you know is unset and print `isNil`.
   Expected: `true`, with no compiler complaint — the lesson is that the declaration cannot make it non-null.
6. Declare `memset` and fill three bytes of an `array[4, char]` with `'x'`. Expected: `xxx` and a zero fourth
   byte.
7. Put a `{.exportc.}` proc in your program and look for its name with `nm`. Expected: the symbol is present.

## Chapter checklist

draft 2026-11-13 · tech_review 2026-11-13 · editorial_pass 2026-11-13 · frozen 2026-11-13
