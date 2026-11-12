---
chapter: 10
title: Arrays, Sequences, and Tuples
job: Choose between fixed-size `array`, growable `seq` and heterogeneous `tuple`, with their slicing and unpacking rules.
nimony_version: 0.6.3
nimony_commit: 4ba90a781b0b22d0821efaa153c129c37cef6143
toolchain: ~/.local/opt/nimony/4ba90a7
host_compiler: ~/.local/opt/nim-2.4.0
status: frozen
tech_review: Momo 2026-11-12
editorial_pass: 2026-11-12
samples: ["samples/10-arrays-sequences-tuples/collections.nim"]
glossary_added: ["openArray", "view", "place", "tuple unpacking", "value semantics"]
---

# Arrays, Sequences, and Tuples

## What this chapter is for

Chapter 9 chose a routine by argument type. This chapter chooses a container by what the data has to do.
Three shapes cover most of it: an `array` when the length is known before the program runs, a `seq` when it
grows while the program runs, and a `tuple` when the parts are a fixed set of fields of different types.

All three are values. Assigning one copies it. A by-value parameter is not a place, so the routine cannot write
it; pass it as `var` when it must write. That is why writing one element of an array does not change the array it
was copied from, and why a sequence parameter cannot be grown in place: `add` needs a `var`, so a routine that
wants more elements copies the parameter into a local first. The choice between them is about shape and
permission, not speed: which one can grow, what may index it, and what a slice hands back.

## Three shapes, one decision

| Shape | Length | Element types | Access |
| --- | --- | --- | --- |
| `array[N, T]` | fixed before the program runs | one, all `T` | position, by any ordinal type |
| `seq[T]` | grows while the program runs | one, all `T` | position from 0, plus `add` and `pop` |
| `tuple` | fixed, one slot per field | one per field, and they may differ | field name or position |

`doc/language.md:344-355` defines the array, `:376-408` the sequence, and `:476-495` the tuple. The line that
separates the first two from the third is homogeneity: an `array` and a `seq` hold one element type, while a
tuple is heterogeneous storage. A tuple may mix the types:

```
let mixed = (1, "a", true)
echo mixed[0]
echo mixed[1]
echo mixed[2]
```

```
1
a
true
```

## Arrays: the length is part of the type

An array constructor is a pair of brackets. The element type comes from the first element, and every other
element has to convert to it (`doc/language.md:356-358`):

```
let a = [10, 20, 30]
echo a.len
echo a.low
echo a.high
let f = [1.0, 2, 3]
echo f[1]
```

```
3
0
2
2.0
```

`2` became `2.0` because the first element fixed the element type as `float`. The type is not `array[10, 20,
30]`: the bracket syntax is a constructor, and `array[N, T]` is the type. Those are two different roles for
the same brackets, and the declaration `var xs: array[3, int] = [1, 2, 3]` uses both in one line.

The length must be known before the program runs. Writing it from a variable is rejected, and the message
names the variable rather than saying "not constant":

```
var n = 3
var a: array[n, int]
```

```
Error: invalid array index type: n
```

The check is in `src/nimony/semtypes.nim:776`; a constant length works (`const N = 3; var a: array[N, int]`,
probed). The syntax has two forms, and they do not mean the same thing (`doc/language.md:353-355`):

```
var five: array[5, int]
var six: array[0..5, int]
echo five.len
echo six.len
```

```
5
6
```

`array[5, T]` is a length: five elements, indexed `0..4`. `array[0..5, T]` is a range: its lower bound is 0
and its upper bound is 5, so it holds six. The length form is turned into an index range `0 .. length-1` in
`src/nimony/semtypes.nim:779-791`. If you want a count, write the count; if you want explicit bounds, write
the bounds and expect one more element than the difference.

A range with a different lower bound moves the valid indexes and keeps the length:

```
type Row = array[1..3, int]
var row: Row = [5, 6, 7]
echo row[1]
echo row.low
echo row.high
for x in row:
  echo x
```

```
5
1
3
5
6
7
```

The constructor still fills from the array's first position, not from index 1, and the `for` loop still visits
the elements in order. Indexing by 0 is a compile error, because the compiler knows the value is out of range:

```
type Row = array[1..3, int]
var row: Row = [5, 6, 7]
echo row[0]
```

```
value out of range: 0 notin 1..3
```

That message is a static check on the literal index. With a variable index the same mistake is caught at
runtime instead, and the program exits with a message from `lib/std/system/panics.nim:86`:

```
let a = [10, 20, 30]
var i = 5
echo a[i]
```

```
index out of bounds: 5 notin 0..2
```

Exit code 1, no value printed.

Any ordinal type can index an array (`doc/language.md:351`), an enum included:

```
type Color = enum red, green, blue
var counts: array[Color, int]
counts[green] = 5
echo counts[green]
echo counts.len
echo counts.low
echo counts.high
```

```
5
3
red
blue
```

The array is three elements long because `Color` has three values, and `low` and `high` return values of the
index type — printed through their `$`, which is why they read as names, not numbers. An element nobody wrote
reads its zero value, the same defaulting a module-level `var` gets (Chapter 3); the sample's `five[4]` prints
`0` for exactly that reason.

An array is writable at an index only when the array itself is writable. The built-in `[]` returns `var T`
(`lib/std/system.nim:25`), so a `var` array can be written through it; a `let` array cannot:

```
let a = [1, 2, 3]
a[0] = 9
```

```
/.../lib/std/system.nim(37, 4) Error: cannot mutate expression a[0]
```

The rejection comes from one of the array `[]=` templates at `lib/std/system.nim:34-37` — the message points
at the second of the two, `:37` — so the write never reaches storage. And an array copies on assignment, so the
copy is independent:

```
var a = [1, 2]
var b = a
b[0] = 9
echo a[0]
echo b[0]
```

```
1
9
```

Arrays nest without a special syntax: `array[2, array[2, int]]` is a two-by-two table, and `grid[1][0]` walks
it in two indexing steps.

## Sequences: storage that grows

A sequence is written with the same array constructor plus `@` (`doc/language.md:376-380`):

```
var xs = @[1, 2, 3]
xs.add 4
echo xs.len
echo xs.pop
echo xs.len
echo xs[0]
echo xs.high
```

```
4
4
3
1
2
```

`add` appends one element (`lib/std/system/seqimpl.nim:213`), `pop` removes and returns the last one and
requires the sequence to be non-empty (`lib/std/system/seqimpl.nim:363`). There is no concatenation operator
at this pin: `xs & ys` has no candidate for `seq`, and `xs.add ys` fails because `add` takes a single `sink T`,
not a sequence. The only `&` overloads are the string and char ones (`lib/std/system/stringimpl.nim:1034-1063`).
To grow by another sequence, add its elements in a loop.

The other way to get storage is `newSeq`, which default-initialises its elements (`0` for `int`,
`lib/std/system/seqimpl.nim:76-77`):

```
var ys = newSeq[int](4)
echo ys.len
echo ys[3]
```

```
4
0
```

An empty literal has no element type to infer, so it needs the annotation on the left:

```
let e = @[]
```

```
Error: could not infer type for T.141.sysvq0asl
```

The digits and letters after `T.` are a mangled name for that instantiation. It is an internal name that is not
stable across releases, so do not match on the suffix; the part to read is `could not infer type`.

`let e: seq[int] = @[]` builds. The length of the empty sequence is `0` and its `high` is `-1`
(`lib/std/system/seqimpl.nim:354-358`); unlike an array, an empty sequence is a normal value you can grow.

A sequence copies like every other value: assignment copies the elements, and a routine that takes the
sequence by value cannot change the caller's sequence at all. Growing the copy leaves the original alone:

```
var a = @[1, 2]
var b = a
b.add 3
echo a.len
echo b.len
```

```
2
3
```

Across a call the rule is stricter than "the copy is independent": a sequence parameter is a value, and `add`
wants a `var`, so growing the parameter itself is rejected.

```
proc grow(xs: seq[int]): int =
  xs.add 3
  result = xs.len
```

```
Error: cannot pass xs to var/out T parameter
```

Copy it into a local `var` first. Then the routine returns the longer length and the caller's sequence is
unchanged:

```
proc grow(xs: seq[int]): int =
  var copy = xs
  copy.add 3
  result = copy.len

var s = @[1, 2]
echo grow(s)
echo s.len
```

```
3
2
```

This is the same `var`-parameter rule Chapter 8 states, seen from the container side: the argument to `add`
must be a place, and a by-value parameter is not one.

Indexing a sequence is checked differently from an array. The `[]` for `seq` carries a `requires` clause,
`i < s.len and i >= 0` (`lib/std/system/seqimpl.nim:239`), and a bad index trips that as an assertion rather
than printing an "index out of bounds" line:

```
var xs = @[1, 2, 3, 4]
var i = 9
echo xs[i]
```

```
/.../lib/std/system/seqimpl.nim(239, 41): i < s.len [AssertionDefect]
```

Exit code 1. The two containers reject the same mistake in two different ways; neither returns a value.

`@` also converts an array into a sequence, and the conversion copies:

```
let fixed = [7, 8]
var grown = @fixed
grown.add 9
echo grown.len
echo fixed.len
```

```
3
2
```

## Slicing: a copy for a seq, a view for an array

A slice is written with `..` or `..<` inside the brackets. For a sequence the result is a fresh sequence with
copies of the elements (`lib/std/system.nim:658-668`), so growing it does not touch the source:

```
var xs = @[1, 2, 3, 4]
var mid = xs[1..2]
mid.add 99
echo mid.len
echo xs.len
```

```
3
4
```

The bounds are clamped rather than checked: `xs[2..10]` keeps whatever the source has from index 2, and a
lower bound above the upper one yields an empty sequence, not an error. The implementation clamps with
`max(x.a, 0)` and `min(x.b, s.len - 1)` and computes the length only when `b >= a`.

```
let xs = @[1, 2, 3, 4]
echo xs[2..10].len
echo xs[5..1].len
echo xs[1..^1].len
echo xs[0..<2].len
```

```
2
0
3
2
```

`^1` is the last index, so `xs[1..^1]` drops the first element; `..<` excludes its upper bound
(`lib/std/system.nim:610-616`, `:626`, `:672-673`).

An array has no slice operator. `a[1..2]` fails, because the slice overloads are declared for `string` and
`seq` only (`lib/std/system.nim:649`, `:658`, `:672`) and an array has no candidate:

```
let a = [1, 2, 3, 4]
let sl = a[1..2]
```

```
Type mismatch at [position]
a[1 .. 2]
[1] array[0..3, int64] does not match constraint T (declared in .../lib/std/system.nim(24, 1))
[2] expected: int64 but got: HSlice[int64,int64] (declared in .../lib/std/system.nim(25, 1))
... 18 more candidate lines
[2] expected: BackwardsIndex but got: HSlice[int64,int64] (declared in .../lib/std/system.nim(632, 1))
```

That listing is 21 candidate lines, every `[]` and slice overload the compiler could try. The `seq` slice this
call actually needed is in the middle of it (`lib/std/system.nim:658`); the last two lines are the compiler
trying the `^` form, `BackwardsIndex`, which the argument is not. The point is the first line — the array's own
`[]` takes an integer index, and no overload takes an array plus a range.

Expect follow-on noise: the failed binding leaves `sl` with no type, so `sl.len` and `sl[0]` each produce their
own error with their own candidate lists. That is where 59 lines comes from if you count them all — three
listings, not one.

The array route is `toOpenArray`, a converter that builds an `openArray` (`lib/std/system/openarrays.nim:25`).
That is not a copy; it is a view over the array's storage, declared `{.view.}` at
`lib/std/system/openarrays.nim:6-9`:

```
var letters = [10, 20, 30, 40]
let view = letters.toOpenArray(1, 2)
view[0] = 99
echo view.len
echo letters[1]
```

```
2
99
```

Writing through the view changed the array. The `let` binds the view, not the storage: the view is a pointer
plus a length (`lib/std/system/openarrays.nim:6-9`), and its `[]` returns `var T`
(`lib/std/system/openarrays.nim:10`). Read-only checking agrees, by a dedicated rule: a `let` is readonly
unless its type is a view, where the compiler re-checks what the view was built from
(`src/nimony/derefs.nim:399-407`, comment at `:406`). So this works over `var` storage and is rejected over a
`let` array. This is the one place in the chapter where a `let` name still leads to a write, and it is the point
of a view.

The same type is what a routine uses to accept either container without a conversion
(`doc/language.md:412-425`):

```
func total(v: openArray[int]): int =
  result = 0
  for x in v:
    result = result + x

let arr = [1, 2, 3]
let sq = @[4, 5]
echo total(arr)
echo total(sq)
echo total([6, 7, 8])
```

```
6
9
21
```

A `var openArray` parameter writes back to the caller, whether the caller passed an array or a sequence:

```
proc bump(v: var openArray[int]) =
  v[0] = v[0] + 100

var a = [1, 2, 3]
bump(a)
echo a[0]
```

```
101
```

Without the `var`, the write is rejected: `v[0] = 0` becomes a call to `[]=`, whose first parameter is
`var openArray[T]` (`lib/std/system/openarrays.nim:13`), and the error is `cannot pass v to var/out T
parameter`. Pass the view as `var` when the routine is meant to change it.

One rule from Chapter 9 applies here, and this chapter does not restate it: the built-in `[]` for an array
and for a sequence returns `var T` (`lib/std/system.nim:25`, `lib/std/system/seqimpl.nim:239`), which is why
these two containers are writable without declaring a `[]=`. A container you write yourself follows the rule
in Chapter 9, not a copy of it here.

## Tuples: fields, order, and a copy

A tuple is an ordered product: a fixed sequence of fields, each with its own type. Two tuple types are the
same type when they specify the same fields in the same order, and the guide adds that the names have to match
too (`doc/language.md:482-487`). Construct one with parentheses, in field order (`doc/language.md:478-482`):

```
type Person = tuple[name: string, age: int]
var p: Person = (name: "Ada", age: 36)
var q: Person = ("Bob", 20)
echo p.name
echo p.age
echo p[0]
echo q.name
```

```
Ada
36
Ada
Bob
```

Positional and named construction are the same tuple: the declared type supplies the names, so `q.name` works
even though the literal has none. Order is not optional — `(36, "Ada")` for `Person` is rejected with a type
mismatch that prints both tuples, `got: tuple[int64, string] but wanted: tuple[name: string, age: int64]`.

What does not work is object-constructor syntax. `Person(name: "Ada", age: 36)` is refused:

```
Error: expected type symbol for object constructor
```

A tuple gets the parentheses form; the named-field call syntax belongs to `object`, which Chapter 11 covers.

Names live in the type, not in the literal. A tuple written without an expected type has positional fields
only, so asking for a name fails:

```
let q = ("Bob", 20)
echo q.name
```

```
Error: undeclared field: 'name' for type tuple[string, int64]
```

The reverse also holds at this pin, and the guide disagrees with it. Two tuple types with the same field types
in the same order but different field names are assignable:

```
type P = tuple[name: string, age: int]
type Q = tuple[label: string, years: int]
var p: P = ("Ada", 36)
var q: Q = p
echo q.label, q.years
```

```
Ada36
```

`doc/language.md:485` says the names also have to be the same; the pin compares field types and order only,
which the source states outright — "only the type of the field is important" (`src/nimony/sigmatch.nim:2435`).
That is intended by construction, not a defect, so the book teaches the pin and records `doc/language.md:485` as
a documentation gap in `ERRATA.md`. Do not use it as a rename — nothing promises the two names stay
interchangeable — and do not assume the compiler will reject it either.

Types still have to agree. Changing one field's type fails, and the message shows both sides:

```
type R = tuple[label: string, years: string]
var r: R = p
```

```
Error: type mismatch: got: tuple[name: string, age: int64] but wanted: tuple[label: string, years: string]
```

A tuple copies field by field on assignment (`doc/language.md:564`). A routine that takes one by value cannot
write it: a field write on the parameter is rejected by the read-only `[]=` template
(`lib/std/system.nim:24`, `:32-33`).

```
type Person = tuple[name: string, age: int]
var person: Person = ("Ada", 36)
var other = person
other.age = 37
echo person.age
echo other.age
```

```
36
37
```

A `let` tuple is not writable, and the message names the field by position rather than by name, because field
access lowers to `[]` (`lib/std/system.nim:24`) and the write goes through the `[]=` template:

```
let p: Person = ("Ada", 36)
p.age = 37
```

```
Error: cannot mutate expression p[1]
```

Unpacking is the reason a tuple is often the return type for several values. It works in `var`, `let` and
`const` statements (`doc/language.md:1669-1671`), `_` skips a field (`:1672-1678`), and the pattern nests
(`:1702-1708`):

```
proc pair(): (int, int) = (4, 2)
let (a, b) = pair()
echo a
echo b
let (x, _, z) = (1, 2, 3)
echo x
echo z
let (m, (n, o)) = (1, (2, 3))
echo m
echo n
echo o
```

```
4
2
1
3
1
2
3
```

When the value is a tuple literal, each name is assigned directly with no temporary (`doc/language.md:1689-1699`);
when it is a call, the tuple is built once and read by position (`doc/language.md:1680-1688`), which matters
if the call has effects.

Two small shapes complete the type. A one-field tuple is written with a trailing comma, `(1,)`, and the comma
is allowed in any tuple construction (`doc/language.md:499-510`); the type can also be written in the
`type` section with indentation instead of a field list (`:515-523`).

## Choosing

- Length known when you write the program, one element type, no growth: `array`. Prefer the count form
  `array[N, T]`; use a range only when the index itself carries meaning.
- Length decided while the program runs, one element type: `seq`. Grow it with `add`, read it with `[]`.
- A fixed set of differently typed fields, usually returned from a routine or stored as one row: `tuple`.
- A routine that should accept both containers: take `openArray[T]`. Add `var` only when it must write back.
- A slice of a `seq` is a copy; a slice of an `array` is spelled `toOpenArray` and is a view. Decide which
  one you need before writing the brackets.

## Samples

`samples/10-arrays-sequences-tuples/collections.nim` — the three shapes, slicing both ways, and unpacking, at
the pinned commit:

```
$ nimony c -r samples/10-arrays-sequences-tuples/collections.nim
2
3
5
6
0
5
1
3
5
red
4
4
3
1
2
3
3
1
0
2
2
4
3
6
6
2
99
Ada
36
36
37
4
2
1
3
1
2
3
```

The first four numbers are the two-by-two array: its length `2`, then `grid[1][0]`, then `5` and `6` for the
count form against the range form. `0` is `five[4]`, an unwritten element reading its zero value. `5`, `1`,
`3` are the non-zero-based row: element, `low`, `high`; `5` and `red` are the enum-indexed array's value and
its `low`. The sequence section runs `4`, `4`, `3`, `1`, `2`: length after `add`, the popped element, the new
length, the first element, `high`. `3` and `3` are the slice's length after its own `add` and the source's
unchanged length; `1`, `0`, `2` are the clamped, inverted and `^1` slices. Then `2`, `4`, `3` compare the
array-to-sequence copy against the two assigned sequences, and `6`, `6` are the two `openArray` calls. `2` and
`99` are the view's length and the array element it changed. The rest is the tuple: `Ada`, `36`, `36`, `37`
for the named field, positional access and the copy, then the three unpackings.

## Checks

1. Write `let a = [10, 20, 30]` and print `a.len`, `a.low`, `a.high`. Expected: `3`, `0`, `2`.
2. Write `let f = [1.0, 2, 3]` and print `f[1]`. Expected: `2.0`.
3. Write `var n = 3; var a: array[n, int]`. Expected: `invalid array index type: n`. Replace `n` with
   `const N = 3`. Expected: it builds.
4. Declare `array[5, int]` and `array[0..5, int]`. Expected lengths `5` and `6`.
5. Declare `array[1..3, int] = [5, 6, 7]`, print `[1]`, `low`, `high`, then index `[0]`. Expected: `5`, `1`,
   `3`, then `value out of range: 0 notin 1..3`.
6. Index a three-element array with a variable holding `5`. Expected: `index out of bounds: 5 notin 0..2`,
   exit code 1.
7. Write `var xs = @[1, 2, 3]; xs.add 4; echo xs.pop`. Expected: `4`, and `xs.len` is `3` afterwards.
8. Write `let e = @[]`. Expected: `could not infer type`. Add `: seq[int]`. Expected: it builds and `high` is
   `-1`.
9. Write `var a = @[1, 2]; var b = a; b.add 3`. Expected: `a.len` is `2`, `b.len` is `3`.
10. Slice `@[1, 2, 3, 4]` with `[2..10]`, `[5..1]` and `[1..^1]`. Expected lengths `2`, `0`, `3`.
11. Slice `[1, 2, 3, 4]` with `[1..2]`. Expected: a 21-line candidate list; the `seq` slice it needed is in
    the middle of it. Replace it with `toOpenArray(1, 2)` and write `view[0] = 99`. Expected:
    the array's element 1 becomes `99`.
12. Write `func total(v: openArray[int])` and call it with an array, a sequence and a literal. Expected: the
    same values the sample prints, from all three.
13. Declare `type P = tuple[name: string, age: int]` and two values `("Ada", 36)` and `(name: "Bob", age: 20)`.
    Print `p.name` and `p[0]`. Expected: `Ada` and `Ada`.
14. Write `Person(name: "Ada", age: 36)` for a tuple type. Expected: `expected type symbol for object
    constructor`.
15. Unpack `(1, (2, 3))` as `let (m, (n, o)) = ...` and print the three. Expected: `1`, `2`, `3`. Replace `n`
    with `_`. Expected: it still builds.

## Chapter checklist

draft 2026-11-12 · tech_review Momo 2026-11-12 · editorial_pass 2026-11-12 · frozen 2026-11-12
