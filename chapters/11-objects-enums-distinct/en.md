---
chapter: 11
title: Objects, Enums, and Distinct Types
job: Model data with nominal `object` types, ordinal `enum` types and representation-sharing `distinct` types, and explain value copy at assignment.
nimony_version: 0.6.3
nimony_commit: 4ba90a781b0b22d0821efaa153c129c37cef6143
toolchain: ~/.local/opt/nimony/4ba90a7
host_compiler: ~/.local/opt/nim-2.4.0
status: frozen
tech_review: Momo 2026-11-12
editorial_pass: 2026-11-12
samples: ["samples/11-objects-enums-distinct/objects.nim"]
glossary_added: ["nominal type", "enum type", "borrow"]
---

# Objects, Enums, and Distinct Types

## What this chapter is for

Chapter 10 chose a container by what the data has to do. This chapter names the data itself. An `object`
gives a shape of related fields one name, so a routine can take a `Point` instead of two integers in a fixed
order. An `enum` names a fixed set of values and orders them, so `Color` is not a stand-in for `int`. A
`distinct` type keeps one representation and refuses to mix with its base, so a distance in metres cannot be
added to a duration in seconds by accident.

All three are ordinary value types, and the rule from Chapter 10 holds: assignment copies. What changes is
what the compiler is willing to let you mix. An object is nominal, so two objects with identical fields are
still two types. An enum's values are ordered and can be walked. A distinct type shares bytes with its base
and shares nothing else.

## Objects

An object is a named set of fields, each with its own type (`doc/language.md:476`). Declaring one names a new
type; there is no relation between two objects that happen to look alike.

```nim
type Point = object
  x: int
  y: int
```

A field that is never written still has a value. Construction fills the fields you name and leaves the rest
alone — the manual says so at `doc/language.md:568-583`. That an omitted field takes its type's default (`0` for
`int`, `false` for `bool`, an empty string for `string`) is measured at the pin, not quoted
(`ch11-probes/o1.nim`, `o3.nim`).

```nim
var empty = Point()
echo empty.x      # 0
echo empty.y      # 0
echo Point(x: 1).y   # 0 — y is not required in the constructor
```

A field may also declare its own default, and that default applies to `Point()` and to any field the
constructor leaves out (`doc/language.md:652`):

```nim
type Badge = object
  label: string = "new"
  level: int = 1

echo Badge().label      # new
echo Badge(level: 4).level   # 4, label stays "new"
```

Two mistakes are worth knowing by their message. Naming a field the type does not have is rejected at the
constructor: `P(z: 1)` gives `undeclared field: 'z' for type P`. Leaving a field out is not a mistake at
all — it is a default.

A field is reachable from another module only if it is marked with `*` (`doc/language.md:546-549`). From
outside the module, an unmarked field reads as `undeclared field: 'hidden' for type Widget` — the compiler
does not distinguish "hidden" from "not there", and that is the point.

### Copy at assignment

Objects are values. `var b = a` copies every field (`doc/language.md:564`), and the copy is independent
afterwards:

```nim
var a = Point(x: 1, y: 2)
var b = a
b.x = 99
echo a.x    # 1
echo b.x    # 99
```

The copy reaches inside a field. An object holding a `seq` copies the sequence's elements, not a shared
buffer, so writing through the copy leaves the original alone:

```nim
type Bag = object
  items: seq[int]

var a = Bag(items: @[1, 2])
var b = a
b.items[0] = 99
echo a.items[0]    # 1
echo b.items[0]    # 99
```

That is measured at the pin (`ch11-probes/o12.nim`), and it matches the rule the language reference states for
tuples and objects: the assignment operator copies each component (`doc/language.md:564`). It also explains
the parameter rule from Chapter 10. A by-value object parameter is not a place, so a routine cannot write the
caller's object; `var` is what makes it writable.

### Objects are nominal

This is the part a reader with a C background has to unlearn. A tuple is structural: two tuples with the same
field types in the same order are the same type. An object is nominal: two objects with identical fields are
different types, and the compiler says so (`doc/language.md:548-549`).

```nim
type A = object
  x: int
type B = object
  x: int

var a = A(x: 1)
var b = B(x: 2)
a = b    # Error: type mismatch: got: B but wanted: A
```

The same rule governs comparison. `==` works between two values of the *same* object type and compares field
by field, sequences included (`ch11-probes/o17.nim`, `o18.nim`):

```nim
echo Point(x: 1, y: 2) == Point(x: 1, y: 2)    # true
echo Point(x: 1, y: 2) == Point(x: 1, y: 3)    # false
echo A(x: 1) == B(x: 1)                       # Error: A does not match constraint Enum ...
```

That equality is not compiler magic, and it is no longer an open question: it is the library generic
`func ==*[T: tuple|object](x, y: T): bool` at `lib/std/system.nim:463`, which walks `fields(x, y)` and returns
false on the first unequal field, so a `seq` field compares through the seq `==`
(`lib/std/system.nim:470-480`). The error above names it too, in its second candidate:
`[2] expected: A but got: B (system.nim(463, 1))` (`ch11-probes/o16.nim`). `doc/language.md` has no paragraph on
object equality — a documentation gap, recorded in `ERRATA.md`, not a defect in the language.

What a reader needs is the consequence: a different type is a different type, so a name for the data buys you a
check, not a comment.

### Printing an object costs a `$`

`echo` writes built-in types. A user-defined object is not one of them, so `echo p` is a type error listing
the `write` overloads the compiler tried, trimmed here to the first two of nine (`ch11-probes/o6.nim`):

```
write stdout, P(x: 1)
[2] expected: string but got: P
[2] expected: int64 but got: P
...
```

`echo` does not apply `$` for you. Write one and apply it yourself:

```nim
func `$`(v: Point): string =
  "(" & $v.x & ", " & $v.y & ")"

echo $p     # (11, 9)
```

The same holds for a distinct type with a defined `$`: `echo $m` prints, `echo m` does not. That is documented,
not a bug. Nimony's `echo` template loops `unpack()` and writes each argument, with no `$` converter
(`doc/language.md:466-471`, `lib/std/syncio.nim:465-468`), and `doc/porting.md:346-347` says objects
deliberately have no generic `$` — define one for the object type.

> **Nim 2 delta — `echo` no longer applies your `$`**
>
> *What Nim 2 did* → `echo p` found the `$` overload and printed `P1`, with the same source
> (`~/.local/opt/nim-2.4.0`, probe `nim2check.nim`).
> *What Nimony does* → the `echo` template above writes the value itself; a user-defined `$` is a routine you
> call, so write `echo $p`.
> *What breaks if you keep the habit* → `echo` of an object fails with `write stdout, P(x: 1)` and a candidate
> list, and the fix is not to define `$` but to apply it.

## Enums

An enum names a fixed set of values and gives them an order (`doc/language.md:182`). The order is the order of
declaration, and `ord` returns the position:

```nim
type Color = enum
  red, green, blue

echo ord(red)      # 0
echo ord(blue)     # 2
echo red < blue    # true
echo Color.green   # green — a value may be qualified with its type
```

Comparison works because an enum is an ordinal type, which is what lets it index an array and lets `for` walk
it (`doc/language.md:223-224`, `ch11-probes/e5.nim`):

```nim
var counts: array[Color, int]
counts[green] = 5
echo counts.len     # 3

for c in Color:
  echo c            # red, green, blue
```

The built-in `$` prints the value's name (`doc/language.md:228`), and that printed name is the same text the
value was declared with — unless the value carries an attached string, which the next section covers.

### Explicit ordinals, holes, and names

A value may be given an explicit ordinal. The manual says the values must ascend, while a value without one gets
the previous plus one and gaps are allowed (`doc/language.md:213-224`):

```nim
type Token = enum
  word = (2, "word")
  number = 4
  symbol = 89

echo ord(word)      # 2
echo ord(symbol)    # 89
echo word           # word
```

The manual requires the ordinals to ascend (`doc/language.md:213-215`), and this pin does not enforce it:
`a = 5, b = 3, c` compiles (`ch11-probes/rv11.nim`), `c` still takes previous plus one so `ord` gives `5` / `3` /
`4`, and comparison follows the values, so `a < b` is `false`. The enum is holey, with the consequences below.
Write ascending lists; a descending one is accepted rather than rejected, so the compiler will not catch it for
you.

The pair form attaches a string to the value, and that string is what `$` prints (`doc/language.md:228-240`).
A hole is the price of explicit ordinals: the enum is then **not ordinal**, so it cannot index an array and
`inc`, `dec`, `succ` and `pred` are unavailable (`doc/language.md:223-225`). On a hole-free enum they are
available, and nothing stops them leaving the set:

```nim
var c = red
inc c
echo c            # green
echo succ(blue)   # ordinal 3 — not a member, prints an empty line
```

Two rough edges, both measured at the pin. First, `low` and `high` are built-in procs over a `typedesc`
(`lib/std/system/basic_types.nim:113-116`), and in argument position the unqualified name resolves to the proc,
not to the enum member: an enum with a member named `low` makes `ord(low)` fail with `auto does not match
constraint T (system.nim(207, 1))`, a message that never names your enum (`ch11-probes/e10.nim`). The member
itself is intact — `ord(Level.low)` is `0` (`rv9.nim`). So qualify the value as `Level.low`, or avoid the two
names.

Second, an enum has no upper bound check on `inc` or on conversion. `inc` on `blue` succeeds and leaves a value
of ordinal `3`, which is not a member; it prints as an empty line and compares unequal to `red`
(`ch11-probes/e13.nim`). `Color(7)` on a three-value enum compiles the same way and prints empty (`e14.nim`), and
so does `Color(-1)` built from a variable (`rv17.nim`). The reason is mechanical: the checks key on `range`
types (`src/nimony/contracts_fir.nim:2551-2569`, `:2492-2500`), and an enum is not a range type. Nim 2 refuses a
literal `Color(7)` at compile time, raises `RangeDefect` for a computed one, and `OverflowDefect` on `inc blue`.
This is recorded in `ERRATA.md` as a watch row, not taught as correct behaviour: do not walk an enum past its last
value, and validate a converted integer before you trust it.

## Distinct types

A distinct type is a new type derived from a base type, incompatible with it, with an explicit conversion
allowed each way (`doc/language.md:1058-1065`). It shares the base's representation and nothing else.

```nim
type Meters = distinct int

let m = Meters(4)
echo int(m)          # 4
echo sizeof(Meters)  # 8
echo sizeof(int)     # 8
```

The conversions must be written. Neither direction is implicit:

```nim
var m: Meters = 5    # Error: type mismatch: got: int64 but wanted: Meters
var i: int = Meters(4)   # Error: type mismatch: got: Meters but wanted: int64
```

The `int64` in those messages is not a typo — at this pin `int` and `int64` are the same type, which Chapter 9
established and `ch11-probes/d1.nim` and `d12.nim` show again. Which name a message uses follows the expression,
not the distinct's base: an `int` literal names `int64` even for `distinct int32` (`rv7.nim`), while a value
already held in `int32` names `int32` (`rv8.nim`). Read the message you get; do not assume it says `int64`.

Operators are not inherited either. `Meters(2) + Meters(3)` is a type error, and so is
`Meters(2) == Meters(2)`, until you write them (`ch11-probes/d3.nim`, `d4.nim`). Write the body first — it
states the operation:

```nim
func `+`(lhs, rhs: Meters): Meters = Meters(int(lhs) + int(rhs))
func `$`(v: Meters): string = $int(v) & "m"

echo int(Meters(2) + Meters(3))   # 5
echo $Meters(4)                   # 4m
```

When the operation is exactly the base's, `{.borrow.}` is the shortcut:

```nim
func `+`(lhs, rhs: Meters): Meters {.borrow.}
```

`borrow` does not copy a body. The compiler generates one that converts each distinct operand to the base, calls
the base operation, and converts the result back (`src/nimony/semborrow.nim:17-60`). It does not carry
`noSideEffect` with it, so an operator that should be pure is a `func`, which is the shape
`doc/porting.md:51-62` shows. A hand-written body is the same thing spelled out, and it is what you need when
the operation is not the base's.

The base need not be numeric. A distinct type over an object keeps the field access of the base through the
conversion, and adds a name that the field alone does not carry:

```nim
type Reading = object
  value: int
type Sample = distinct Reading

var s = Sample(Reading(value: 7))
echo s.Reading.value    # 7
```

What a distinct type buys, in one sentence: the field layout is the base's, the arithmetic is none of it, and
a routine that asks for `Meters` cannot be handed an `int` or a `Seconds` by mistake.

## Samples

One file proves the chapter: `samples/11-objects-enums-distinct/objects.nim`.

```
~/.local/opt/nimony/4ba90a7/bin/nimony c -r samples/11-objects-enums-distinct/objects.nim
```

Through the verifier:

```
$ ./tools/verify-samples.sh
PASS samples/11-objects-enums-distinct/objects.nim exit=0
SUMMARY 10/10 passed, 0 failed
```

Its output, in order:

```
1
2
9
0
0
new
4
a
1
b
99
10
11
(11, 9)
0
2
true
green
1
5
3
red
green
blue
2
89
word
number
symbol
4
4
8
8
5
4m
7
```

The first five are the point: `x`, `y`, `y` after assignment, then the two defaults of `Point()`. `new` and
`4` are the declared field default and the constructor's override. Then `a`, `1`, `b`, `99`: the copy's name
and element changed while the original kept its own. `10` and `11` are the by-value sum and `x` after
`moveRight`; `(11, 9)` is `$p`. The enum block runs `0`, `2`, `true`, `green`, `1` for the ordinal, the order,
the qualification and `ord` through method syntax, then `5`, `3`, and the three values `for` walked. `2` and
`89` are the explicit ordinals; `word`, `number`, `symbol` are what `$` prints. Then `4`, `4`, `8`, `8` —
both conversions and both sizes — and `5`, `4m` for the borrowed `+` and the distinct `$`. The last `7` is the
field read through the distinct conversion.

## Checks

1. Declare `type Point = object` with `x, y: int`, then `echo Point(x: 1).y`. Expected: `0`.
2. Give a field a default (`label: string = "new"`), print `Badge().label` and `Badge(label: "x").label`.
   Expected: `new` and `x`.
3. Construct with a field the type does not have. Expected: `undeclared field: 'z' for type P`.
4. Copy an object and change a field on the copy. Expected: the original is unchanged.
5. Copy an object whose field is a `seq`, then write `b.items[0] = 99`. Expected: `a.items[0]` is still `1`.
6. Declare two objects with the same single field and assign one to the other. Expected: `type mismatch:
   got: B but wanted: A`.
7. `echo` an object with no `$`. Expected: `write stdout, P(x: 1)` and a candidate list. Define a `$` for it,
   then print `echo $p`. Expected: it prints.
8. Print `ord(blue)`, `red < blue` and `Color.green` for a three-value enum. Expected: `2`, `true`, `green`.
9. Index an `array[Color, int]` with `green` and print `.len`. Expected: the value you stored, then `3`.
10. Declare an enum with `a = 2, b = 4, c = 89` and call `inc` on one value. Expected: it does not build —
    the enum is no longer ordinal.
11. Name an enum value `low` or `high` and call `ord` on it. Expected: a type error, not a wrong number.
12. `inc` an enum value at its last member. Expected: it builds and the value prints as an empty line —
    do not rely on that; do not `inc` a value that is already `high`, compare first.
13. Build `Meters(4)`, print `int(m)`, `sizeof(Meters)` and `sizeof(int)`. Expected: `4`, `8`, `8`.
14. Write `var m: Meters = 5`. Expected: `got: int64 but wanted: Meters`.
15. Write `Meters(2) + Meters(3)` with no operator defined. Expected: a type error. Add
    `{.borrow.}` to a `+` and print `int(...)`. Expected: `5`.

## Chapter checklist

draft 2026-11-12 · tech_review Momo 2026-11-12 · editorial_pass 2026-11-12 · frozen 2026-11-12
