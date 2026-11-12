---
chapter: 9
title: Overloading and UFCS
job: Resolve overload sets by argument type, call either form with method-call syntax, and know what is no longer overloadable (`var T` for `[]`).
nimony_version: 0.6.3
nimony_commit: 4ba90a781b0b22d0821efaa153c129c37cef6143
toolchain: /Users/sachiel/.local/opt/nimony/4ba90a7
host_compiler: /Users/sachiel/.local/opt/nim-2.4.0
status: frozen
tech_review: Momo 2026-11-12
editorial_pass: 2026-11-12
samples: ["samples/09-overloading/overloading.nim"]
glossary_added: ["overload set", "overload resolution", "receiver", "method call syntax", "index setter", "module-of-origin"]
---

# Overloading and UFCS

## What this chapter is for

Chapter 8 gave one routine one name. Here one name carries several routines, and the compiler picks the one a
call means. That is the mechanism behind most of what looks like built-in behaviour in this book: `$` on a
number and `$` on a tuple are two declarations with one name (`lib/std/system/formatint.nim:104`,
`lib/std/system/dollars.nim:41`). Not everything that looks overloaded is: `echo` is one declaration,
`template echo*() {.varargs.}` (`lib/std/syncio.nim:465`), which takes any number of arguments.

The chapter has two halves. First, how a name with several candidates is resolved, including the cases where
resolution fails and says so. Second, the call syntax that puts the first argument in front of the name —
`x.f(y)` for `f(x, y)` — which is not a second language feature but the same call written differently.

The last section is the delta: `var T` is no longer a dimension of overloading. That removes a shape from
Nim 2 code that you cannot simply port. Two separate checks carry the removal, and confusing them is the
usual mistake: overload resolution has no `var`-ness dimension, so a `var T` / `T` pair is one ambiguity;
and the borrow pass (`validBorrowsFrom`) decides where a `var` result may point. Both appear below.

## One name, several routines

Two routines may share a name as long as their parameter lists differ. Nothing is declared as an "overload" —
the second `proc` with the same name is one more candidate in the set:

```
func render(x: int): string = "int " & $x
func render(x: string): string = "text " & x

echo render(3)
echo render("a")
```

```
int 3
text a
```

Arity counts as well, because it is part of the parameter list:

```
func twice(x: int): int = x * 2
func twice(x: int, y: int): int = x * 2 + y

echo twice(4)
echo twice(4, 1)
```

```
8
9
```

The return type is not part of the parameter list, and it does not distinguish two candidates. Writing the
same parameter list twice with different results is accepted at the declaration and rejected at the call:

```
proc g(x: int): int = 1
proc g(x: int): string = "s"
echo g(1)
```

```
q4.nim(4, 7) Error: ambiguous call: 'g'
proc (x: int64): int64 (declared in q4.nim(2, 1))
proc (x: int64): string (declared in q4.nim(3, 1))
```

Read the two lines the error prints: they are the candidates it could not choose between. This is the shape
of every ambiguity message in the chapter, so it is worth recognising before you meet one in a larger program.
The message is built in `src/nimony/semcall.nim:1397`. The pin prints `int` as `int64` in these listings; that
is not a bug in your code, it is how the argument types are rendered.

## How the compiler chooses

`doc/language.md:1318` describes the call as a *symbol choice*: the name may refer to more than one candidate,
and overload resolution turns it into one symbol. The work is done in ordered trials, and the first trial that
separates two candidates decides between them. The first trial is category matching
(`doc/language.md:1328-1347`), which ranks each argument against each formal parameter in this order:

1. **Exact match** — same type.
2. **Literal match** — an integer or float literal whose value fits the parameter type.
3. **Generic match** — the parameter is a generic type.
4. **Subrange or subtype match.**
5. **Integral conversion match.**
6. **Conversion match**, possibly through a `converter`.

A candidate that matches more arguments at a higher category wins. If two candidates still tie after every
trial, the ambiguity is reported — the guide says so at `doc/language.md:1325-1326`, and the message in the
previous section is what that looks like.

The ranking shows up immediately with literals. Given a candidate on `int` and one on `int32`, the call goes to
`int`:

```
proc pick(x: int): string = "int"
proc pick(x: int32): string = "int32"
echo pick(5)
```

```
int
```

`int32` would accept `5` as a literal match, but `int` takes it as an exact match and wins at the higher
category — probed at the pin, not a sentence in the guide. Replace the second parameter with `float` and
`pick(5)` still prints `int`, while `pick(5.0)` prints `float` — the argument's own form picks the side.

That only holds while one side is `int`. The guide's list gives integer literals integer targets and float
literals float targets, so it predicts no tie between `int32` and `float`. The pin ties them anyway, and that
is a probe finding rather than a category the guide names:

```
proc amb(x: int32): string = "int32"
proc amb(x: float): string = "float"
echo amb(5)
```

```
v4.nim(4, 9) Error: ambiguous call: 'amb'
proc (x: int32): string (declared in v4.nim(2, 1))
proc (x: float64): string (declared in v4.nim(3, 1))
```

So the literal rule only gets you so far. Past `int`, say which type you mean with a conversion or a typed
variable at the call site; do not expect the literal to widen on its own.

One trap at this pin deserves its own paragraph. `int` is `int64` here, not a distinct width:

```
func show(x: int64): string = "int64"
var a: int = 5
echo show(a)
echo sizeof(int)
echo sizeof(int64)
```

```
int64
8
8
```

So on a 64-bit target `int` and `int64` are the same type written two ways: `src/nimony/builtintypes.nim:160-163`
builds `int` as `(i configBits)`, `:197-199` builds `int64` as `(i 64)`, and `src/nimony/semmain.nim:652`
passes the target bits. On a 32-bit target the pair would be distinct; every target this book builds for is
64-bit. A set with one `int` candidate and one `int64` candidate is therefore a set with two identical
candidates: it compiles, and every call to it is ambiguous. If you port Nim 2 code that overloaded on both
widths, collapse the pair into one routine.

Where two candidates come from different modules, the one declared in the calling module is preferred. The
guide encodes this as an extra implicit parameter and calls it module-of-origin (`doc/language.md:1375-1400`);
you do not write anything for it, but it explains why a local wrapper can quietly shadow an imported routine
that matches equally well. Probed 2026-11-12 with two modules: with a local `pick` beside the imported one the
local wins, and with the local removed the imported one is used, both builds exit 0.

## Method call syntax

`f(x, y)` has a second spelling: `x.f(y)`. The guide introduces it for object-oriented code and then says
plainly that it is not restricted to objects — any first argument can be the receiver
(`doc/language.md:2836-2842`). The parentheses are dropped when there are no remaining arguments, so `5.twice`
and `5.twice()` are the same call:

```
func twice(x: int): int = x * 2
func twice(x: int, y: int): int = x * 2 + y

echo 5.twice
echo 5.twice(1)
```

```
10
11
```

`5.twice(1)` shows the whole rule at once: the receiver becomes the first argument, the rest follow in order,
and the overload set is the same one the plain call would use.

It is also the way out of the one-argument limit on the command form described in Chapter 8. In expression
position that form takes exactly one argument and the parser stops at the comma; in statement position it does
take two and parses as one call, but the result has nowhere to go, so `add 1, 2` fails with
`expression of type int64 must be discarded`. `1.add(2)` is one call in either position.

The receiver has to be the first parameter, and the compiler says so in the type's terms:

```
func wrap(s: string, n: int): string = s & $n
echo 1.wrap("a")
```

```
r4.nim(3, 12) Error: Type mismatch at [position]
1.(wrap, "a")
[1] expected: string but got: int64 (declared in r4.nim(2, 1))
```

The rewritten call in the message is the point: `1.wrap("a")` became `1.(wrap, "a")`, with `1` in the first
position. The receiver is not matched against some receiver type; it is matched against the first parameter
like any other argument.

Explicit generic instantiation does not survive the rewrite. The guide warns that `p[T](x)` cannot be written
`x.p[T]`, because that parses as `(x.p)[T]` (`doc/language.md:2855-2866`). Both halves of that warning are
visible at the pin:

```
func count[T](a: T, b: T): int = 2
echo 3.count[int](4)
```

```
u3.nim(3, 7) Error: undeclared field: 'count' for type int64
```

The parser read it as a field access on `3`, exactly as documented; the message comes from
`src/nimony/sem.nim:5162`. The documented cure is the `[: ]` form,
and it works in the receiver position:

```
echo 3.count[:int](4)
```

```
2
```

`[: ]` has no syntax tree of its own: the parser rewrites it to `count[int](3, 4)` before anything else sees
it (`doc/language.md:2862-2866`). Probed, not quoted: the bare call form `count[:int](3, 4)` does not parse at
this pin — it fails with `invalid indentation` at the bracket — so the `[: ]` escape is only usable on the
receiver side. Write `count[int](3, 4)` when you are not using a receiver.

## Nim 2 delta: `var T` is no longer an overload dimension

`doc/differences.md:31` records the change: overloading based on `var T` is gone, and accessors become
polymorphic instead — mutability is tracked at the location being written, not chosen by a second overload.
The file then shows the Nim 2 pair that used to exist and the single Nimony routine that replaces it
(`doc/differences.md:31-43`):

```
# Nim 2
func `[]`(x: var Container): var Element
func `[]`(x: Container): lent Element

# Nimony
func `[]`(x: Container): var Element
```

Three separate things follow from that at the pin, and they are easy to confuse because only one of them is
about `[]` specifically.

**A `var` and a non-`var` overload are not two candidates; they are one ambiguity.** Resolution no longer
distinguishes them, so a pair that Nim 2 would separate by mutability is a pair the pin cannot separate at all:

```
func get(b: var Box, i: int): var int = b.v
func get(b: Box, i: int): int = b.v
var b = Box(v: 7)
echo get(b, 0)
```

```
r5.nim(7, 9) Error: ambiguous call: 'get'
func (b: var Box, i: int64): var int64 (declared in r5.nim(4, 1))
func (b: Box, i: int64): int64 (declared in r5.nim(5, 1))
```

**A `var` result needs a path it can borrow.** The simplified accessor in the delta exists, but the borrow pass
has to see somewhere for the result to point. An inline field of a by-value parameter gives it nothing: the
field sits inside the caller's copy, so there is no path back. Writing the guide's own line with a plain
parameter is rejected at the definition, not at the call:

```
func `[]`(b: Box, i: int): var int = b.v
```

```
r2.nim(4, 39) Error: cannot borrow from b.v
```

The check is `trReturn` at `src/nimony/derefs.nim:466-468`, which calls `validBorrowsFrom`
(`src/nimony/derefs.nim:258-314`).

This is the borrow pass, not the resolution rule. The removed overload decided which routine a call selects;
`validBorrowsFrom` constrains where a `var` result may point. With `b: var Box` the accessor builds and a read
through it works. A `lent` parameter is accepted too, and so is indirection — a `seq` field read through a
plain parameter compiles, because the path goes through heap storage instead of an inline field:

```
type Container = object
  data: seq[int]

func `[]`(x: Container, i: int): var int = x.data[i]
```

This is the shape the chapter sample runs at the end: `1` read through the accessor, then `5` after the element
is written directly. Swap the `seq` field for an inline `v: int` and you get the rejection above.

**Writing through an index needs an explicit `[]=`.** A `var`-returning accessor is not enough for assignment.
With only `func `[]`(b: var Box, i: int): var int` declared, `b[0] = 9` fails at the assignment. The message
does name your type once, in its first line, and then lists the built-in `[]=` candidates. What it never says
in words is that no `[]=` for `Box` exists:

```
s1.nim(6, 1) Error: Type mismatch at [position]
b[0] = 9
[1] Box does not match constraint T (declared in /.../lib/std/system.nim(32, 1))
[1] expected: array[I, T] but got: Box (declared in /.../lib/std/system.nim(34, 1))
... 10 more candidate lines
```

The assignment asks for `[]=`, and with no `[]=` of your own it can only try the built-in ones; the
`Type mismatch at [position]` header comes from `src/nimony/semcall.nim:1436`, and the first built-in candidate
is `lib/std/system.nim:32`. Declare the setter and the same line compiles:

```
func `[]`(b: Box, i: int): int = b.v
func `[]=`(b: var Box, i: int, val: int) = b.v = val

var b = Box(v: 7)
b[0] = 9
echo b[0]
```

```
9
```

What Nim 2 did → what Nimony does → what breaks if you keep the habit:

- **Nim 2:** two `[]` overloads, one on `var Container` returning `var Element`, one on `Container` returning
  `lent Element`; assignment went through the `var` overload automatically.
- **Nimony:** one `[]` accessor, which may return `var` when it has a path to borrow from — a `var`, `out` or
  `lent` parameter, or indirection such as a `seq` field; writes go through a separate `[]=` you declare.
- **What breaks:** a ported container that overloaded on `var T` compiles as two identical-looking candidates
  and every call to it is ambiguous; a ported accessor that returned `var` from an inline field of a by-value
  parameter stops compiling with `cannot borrow from b.v`; and a ported type that relied on implicit
  write-through starts failing at the assignment with a built-in candidate list.

This is a chapter where the delta is not a footnote. Read `doc/differences.md:31-43` before porting any
container type.

## Samples

`samples/09-overloading/overloading.nim` — the overload set, both call forms, and the index setter, at the
pinned commit:

```
$ nimony c -r samples/09-overloading/overloading.nim
int 3
text a
8
9
10
11
a1
9
1
5
```

`10` and `11` are `5.twice` and `5.twice(1)`: same receiver, different candidate, chosen by the arguments that
follow it. The `9` is a write through the sample's `[]=` and a read back through `[]`. The last two lines are
the `seq`-backed container from the borrow section: `1` read through the accessor, then `5` after the element is
written directly — which is what shows the `var` result really points into the container's own storage.

## Checks

1. Write `func render(x: int)` and `func render(x: string)` returning `int 3` and `text a`. Expected: the same
   two lines as the sample.
2. Write `twice(x: int)` and `twice(x: int, y: int)`. Expected: `twice(4)` is `8`, `twice(4, 1)` is `9`.
3. Write `proc g(x: int): int` and `proc g(x: int): string`, then call `g(1)`. Expected: `ambiguous call: 'g'`
   followed by the two candidate lines. Remove one declaration. Expected: it builds.
4. Write `pick(x: int)` and `pick(x: int32)`, then call `pick(5)`. Expected: the `int` line.
5. Write `once(x: int)` and `once(x: int64)`, then call `once(5)`. Expected: `ambiguous call` with two
   identical-looking `(x: int64)` candidates. Replace the second parameter type with `int32`. Expected: it
   builds and prints the `int` line.
6. Write `func show(x: int64)` and pass a value declared `var a: int`. Expected: it builds. Replace the
   parameter with `int32`. Expected: `Type mismatch`, with the detail line `[1] expected: 32 but got: 64`.
7. Write `wrap(s: string, n: int)` and call `"a".wrap(1)`. Expected: `a1`. Call `1.wrap("a")`. Expected:
   `Type mismatch`, and the message rewrites the call to `1.(wrap, "a")`.
8. Write `5.twice` and `5.twice()`. Expected: the same value from both, and the same value as `twice(5)`.
9. Write `echo 3.count[int](4)` for `count[T]`. Expected: `undeclared field: 'count' for type int64`. Write
   `echo 3.count[:int](4)`. Expected: `2`. Write `echo count[:int](3, 4)`. Expected: `invalid indentation`.
10. Write the `get` pair from the delta section, one on `var Box` and one on `Box`. Expected: `ambiguous call`
    listing both. Delete either declaration. Expected: it builds.
11. Write `func `[]`(b: Box, i: int): var int = b.v`. Expected: `cannot borrow from b.v`. Change the
    parameter to `b: var Box`. Expected: it builds, and reading `b[0]` works.
12. Write the `[]` accessor with `b: var Box` and then assign `b[0] = 9`. Expected: `Type mismatch at
    [position]` with a list of built-in candidates. Add `func `[]=`(b: var Box, i: int, val: int)`. Expected:
    it builds and prints the written value.

## Chapter checklist

draft 2026-11-12 · tech_review Momo 2026-11-12 · editorial_pass 2026-11-12 · frozen 2026-11-12
