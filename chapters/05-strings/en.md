---
chapter: 5
title: Strings
job: Treat `string` as an ordinary value with no null terminator: build, index, slice, and compare it, and know where `cstring` still appears.
nimony_version: 0.6.3
nimony_commit: 4ba90a781b0b22d0821efaa153c129c37cef6143
toolchain: /Users/sachiel/.local/opt/nimony/4ba90a7
host_compiler: /Users/sachiel/.local/opt/nim-2.4.0
status: frozen
tech_review: Momo 2026-11-12
editorial_pass: 2026-11-12
samples: ["samples/05-strings/strings.nim"]
glossary_added: ["string", "null terminator", "cstring", "slice", "escape sequence", "raw string", "concatenation"]
---

# 5. Strings

## What this chapter is for

A `string` in Nimony is an ordinary value: it has a length, it copies when you assign it, and it is a sequence
of bytes you can index. What it does **not** have is an invisible zero byte at the end, and that single change
is where most habits from other languages break.

This chapter teaches the value first — build, index, slice, compare — and then the boundary, where a `cstring`
still appears and what converting costs.

## A string is a value

Every string literal has the type `string` (`doc/language.md:280`), and the builtin `len` returns its length:

```
let title = "Nimony"
echo title.len        # 6
```

Strings are value types. Assignment copies or moves the payload — there are no reference semantics, so two
names never point at the same characters (`doc/language.md:284`):

```
var line = "abc"
var copy = line
copy.add "d"
echo line             # abc
echo copy             # abcd
```

That is not a footnote. It decides what a procedure does with a string it receives: without a `var` parameter
it works on its own copy, and the caller's string is untouched. (Chapter 8 covers parameters in full.)

## Building a string

The `&` operator concatenates (`doc/language.md:303`). `add` appends in place and needs a `var`, so it is the
cheaper form when you are growing one string in a loop:

```
var line = "strings"
line.add " and "
line.add "values"
echo line             # strings and values
```

`add` takes a `string` or a single `char`. `&` also accepts a `char` on either side
(`lib/std/system/stringimpl.nim:1062-1063`), which is the simplest way to turn one character into a string:

```
echo "" & 'z'         # z
```

There is no implicit conversion the other way. `"n=" & 42` does not compile — the compiler tries to fit the
right side into a `char` and reports `expected: char but got: int64`
(`lib/std/system/stringimpl.nim:1062`). Make the number a string first:

```
echo "n=" & $42       # n=42
```

## Length, index, slice

A string is indexed like an array, lower bound `0` (`doc/language.md:287-288`), and `s[i]` yields the i-th
`char`, a byte (`doc/language.md:299-300`).
The last character is `s[^1]`:

```
echo title[0]         # N
echo ord(title[0])    # 78
echo title[^1]        # y
```

An index is **checked**. The indexing routine carries the contract `i < len(s) and i >= 0`
(`lib/std/system/stringimpl.nim:686`), so reading one past the end is not a quiet `'\0'` — it stops the program:

```
echo "hello"[5]   # runtime: stringimpl.nim(686, 37): i < len(s) [AssertionDefect]
```

The runner then prints `FAILURE: nimcache/c/.../probe` and the process exits non-zero.

A check happens when the program runs, not while it compiles: the compiler accepts `s[5]` on a five-character
string and the assertion fires later. An index you compute is your responsibility.

Checks stay on under `-d:release`; only `-d:danger` turns them off (`nimony --help`), and then `s[5]` reads
whatever byte follows the payload and the program carries on. I confirmed both at the pin: default and
`-d:release` stop with the `AssertionDefect` above, `-d:danger` prints the stray byte.

A **slice** behaves differently. `s[a..b]` and `s[a..<b]` return a new string, and the bounds are clamped
rather than checked (`lib/std/system.nim:649-652` calls `substr`, `lib/std/system/stringimpl.nim:706-717`):
`first` is raised to `0`, `last` is lowered to `high(s)`, and an empty range gives `""`.

```
echo "clamped"[0..20]   # clamped
echo "abc"[2..1]        # (empty line)
```

Every slice is a copy. Slicing is therefore safe, but not free: a loop that slices a long string per iteration
copies per iteration.

There is no slice **assignment**. `s[0..1] = "HE"` does not compile — string has `[]` for a slice but no `[]=`
for one. A single character is the only write the index operator allows:

```
var buffer = "hello"
buffer[0] = 'H'
echo buffer             # Hello
```

## Comparing strings

Strings compare by lexicographical order, and every comparison operator is available
(`doc/language.md:286-287`):

```
echo "abc" == "abc"     # true
echo "abc" < "abd"      # true
echo "ABC" < "abc"      # true
```

The third line is worth pausing on: comparison is byte by byte, and in ASCII an uppercase letter sorts before
its lowercase form. So `"ABC" < "abc"` is `true`, and any "sort these names" code inherits that order unless it
normalizes case first.

A `case` may also match string literals directly (`doc/language.md:288`, `:290-295`), which makes command
dispatch readable:

```
let command = "start"
case command
of "start": echo "starting"
of "stop": echo "stopping"
else: echo "unknown command: " & command
```

## Escapes, raw strings, triple quotes

Inside a normal string literal a backslash starts an escape sequence:

| Sequence | Meaning |
| --- | --- |
| `\n` | newline |
| `\t` | tab |
| `\\` | a literal backslash |
| `\"` | a literal double quote |
| `\x41` | the byte with that hex value (`A`) |

An `r"..."` raw string disables escapes entirely, which is what you want for a Windows path or a regular
expression:

```
echo "a\tb"   # a, then a tab, then b
echo r"a\tb"  # a\tb
```

A triple-quoted string spans lines and keeps its own line breaks:

```
let block = """
  first
  second
  """
```

The newline that follows the opening `"""` is dropped; the rest of the indentation is kept as written.

## Characters are bytes

The guide is explicit: strings are UTF-8 **by convention**, not by enforcement, and `s[i]` is the i-th
`char` — a byte — not the i-th unicode character (`doc/language.md:297-300`).

```
let utf = "héllo"
echo utf.len          # 6
echo ord(utf[1])      # 195
```

Five letters, six bytes, and index `1` is the first byte of the two-byte `é`, not `é` itself. Nothing is wrong
with the string; the indexing contract is simply about bytes.

If you need characters rather than bytes, that is a decoding job, and it does not belong to `[]`: `std/unicode`
ships `iterator runes*(s: string): Rune` (`lib/std/unicode.nim:1467`) and `runeLen`.

## The terminator that is not there

Nim 2 stored a `'\0'` after the last character of every string. Nimony removed it
(`doc/differences.md:15-18`): the payload is the payload, and the length lives in the string's own header.

You can see the design from the source rather than from folklore. Converting a string to a C pointer is
`toCString`, and its first act is to **write** the zero:

```
func ensureTerminatingZero*(s: var string) =
  ## Appends '\0' at position s.len then shrinks back, so the null sits just
  ## past the data without changing the logical length — same as terminatingZero
  ## but in-place.
  let oldLen = s.len
  s.add '\0'
  s.shrink oldLen

func toCString*(s: var string): cstring not nil =
  ## Returns a null-terminated cstring pointer.
  ensureTerminatingZero(s)
  result = cast[cstring not nil](rawData(s))
```
(`lib/std/system/stringimpl.nim:1095-1106`)

If a string already carried a terminator, that function would have nothing to do. It also explains the
signature: `toCString` takes `var string`, because it modifies the buffer. A `let` cannot be converted:

```
let s = "hello"
let c = toCString(s)   # Error: cannot pass s to var/out T parameter
```

Appending and shrinking goes through `add`, which makes the storage unique first — so if the string's buffer is
shared, the conversion copies it. That is another reason the conversion is not free and not something to do
inside a loop.

The other half is the same rule: `cstring(s)`, the direct conversion a Nim 2 program would write, is refused
unless `s` is a literal:

```
var s = "hello"
let c = cstring(s)     # Error: Only string literals can be converted to cstring.
                       #        Use `toCString` for safe conversion.
```
(`src/nimony/sem.nim:880`)

A literal converts because the C compiler stores literals with a zero byte of its own. A runtime string has no
such byte until someone writes one.

## Where `cstring` still appears

`cstring` is the C-compatible pointer type (`doc/language.md:306-314`). In this book it appears at the C
boundary and almost nowhere else: Chapter 22 binds C functions, and that is the chapter that leans on it.

The rules you need before then:

- **Length.** `len` on a `cstring` calls C's `strlen`
  (`lib/std/system/stringimpl.nim:377`, `:369-375`), so it counts until the first zero byte. Unlike `len` on a
  `string`, its cost depends on the content.
- **To a string.** `fromCString` copies the bytes into a new `string`
  (`lib/std/system/stringimpl.nim:1108-1109`). There is also `$`, but it lives in `strutils`
  (`lib/std/strutils.nim:230`), not in `system` — without `import std/strutils`, `$c` does not compile.
- **Printing.** `echo` has no `cstring` overload. `echo c` fails even with `strutils` imported; write `echo $c`.
- **`case`.** A `cstring` works in a `case` the way a string does (`doc/language.md:341`).
- **Indexing.** The guide states no bounds checking is performed on a `cstring` index
  (`doc/language.md:312-314`). Treat `c[3]` as an unsafe read: nothing stops you from walking off the end.
- **Nil.** The type reports as `cstring not nil` in error messages. Nilability is Chapter 13's subject; for
  now, note only that a `cstring` is not nil by default.

The direction that matters most is one-way in practice: you convert at the boundary, call the C function, and
come back with a copy. Do not hold a `cstring` as your working representation of text.

## The module that does the text work

`string` gives you length, indexing, slicing, comparison and `&`. Everything else — splitting, searching,
trimming, case conversion — is `std/strutils`, and all of the following run at the pin:

```
import std/strutils

let parts = "alpha,beta,gamma".split(",")   # three strings
echo parts[1]                               # beta
echo "alpha".find("pha")                    # 2
echo "alpha".find("zzz")                    # -1
echo "alpha".toUpperAscii()                 # ALPHA
echo "  pad  ".strip()                      # pad
echo "a-b-c".replace("-", "+")              # a+b+c
```

`find` returns `-1` when the needle is absent, not an optional. `split` returns a `seq[string]`, so Chapter 10
is where its indexing and unpacking get full treatment.

Note what is **not** here: `insert` and `delete` do not exist for `string` at the pin (`insert` is an
undeclared identifier, and `delete` resolves only to the `seq` overload and fails with a type mismatch), and
`setLen` grows or shrinks the string rather than splicing it. Build the string you want with `&`, `add` and
slicing rather than reaching for an in-place editor.

## Nim 2 delta: no null terminator

> **What Nim 2 did.** Every string carried a `'\0'` just past its last character. `cstring(s)` was a cast, and
> `s[s.len]` read that zero.
>
> **What Nimony does.** The payload has no terminator (`doc/differences.md:15-18`). `toCString(var string)`
> writes one on demand and may make the buffer unique first (`lib/std/system/stringimpl.nim:1095-1106`).
> `fromCString` copies back (`:1108-1109`).
>
> **What breaks if you keep the habit.** `cstring(s)` on a variable no longer compiles — `Only string literals
> can be converted to cstring. Use `toCString` for safe conversion.` — and `toCString` refuses a `let` with
> `cannot pass s to var/out T parameter`, because terminating in place needs a mutable string. `s[s.len]` used
> as a sentinel stops the program with `i < len(s) [AssertionDefect]` instead of reading a zero (with runtime
> checks on: `-d:danger` removes the check and you read stray bytes). And code that held a `cstring` across a
> later mutation of the source string is wrong twice over: the pointer may come from a copy, and the zero is
> written only at conversion time.

## Samples

`samples/05-strings/strings.nim`, compiled and run at the pinned commit:

```
nimony c -r samples/05-strings/strings.nim
```

Expected output, in order:

```
6
N
78
y
Nim
strings and values
true
true
true
strings and values
strings and values!
a	b
a\tb
AB
z
n=42
6
195
Hello
clamped
3
beta
2
-1
7
cstring
cstring
cstring case
```

The line `a` then a tab then `b` is one line with a tab in it. The `195` is the first byte of `é`, and the `7`
is `strlen` stopping at the zero that `toCString` wrote.

## Checks

1. Print `len`, `[0]`, `[^1]` and `[0..2]` of `"Nimony"`. Expected: `6`, `N`, `y`, `Nim`.
2. Write `echo "n=" & 42`. Expected: a type mismatch naming `char` and `int64`. Change it to `$42` and expect
   `n=42`.
3. Declare `let s = "abc"` and call `s.add "d"`. Expected: `cannot pass s to var/out T parameter`. Change
   `let` to `var` and expect it to compile.
4. Declare `let s = "hello"` and print `s[5]`. Expected: it compiles, then stops at runtime with
   `i < len(s) [AssertionDefect]`.
5. Print `"abc"[0..5]` and `"abc"[2..1]`. Expected: `abc`, then an empty line. A slice clamps; an index does
   not.
6. Print `len("héllo")` and `ord("héllo"[1])`. Expected: `6` and `195`.
7. Write `echo cstring"hi"`. Expected: no overload for `cstring` in `echo`. Add `import std/strutils` and
   write `echo $cstring"hi"`. Expected: `hi`.
8. Declare `var s = "hello"`, convert with `toCString`, and print `len` of the result. Expected: `5`. Change
   `var` to `let` and expect `cannot pass s to var/out T parameter`.

## Chapter checklist

draft 2026-11-12 · tech_review Momo 2026-11-12 · editorial_pass 2026-11-12 · frozen 2026-11-12
