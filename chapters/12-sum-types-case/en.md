---
chapter: 12
title: Sum Types and Exhaustive `case`
job: Express alternatives as variants and match the discriminator with an exhaustive `case`, preferring that over sentinel fields and flags.
nimony_version: 0.6.3
nimony_commit: 4ba90a781b0b22d0821efaa153c129c37cef6143
toolchain: ~/.local/opt/nimony/4ba90a7
host_compiler: ~/.local/opt/nim-2.4.0
status: frozen
tech_review: Momo 2026-11-12
editorial_pass: 2026-11-12
samples: ["samples/12-sum-types-case/sumtypes.nim"]
glossary_added: ["sum type", "discriminator", "exhaustive case"]
---

# Sum Types and Exhaustive `case`

## What this chapter is for

A shape is a circle, a rectangle or a triangle, and each one needs different data to describe it. The
temptation is one object with every field and a `kind` flag, where half the fields are dead on any given
value. The next temptation is a boolean: `isCircle`, then `isRectangle`, then a third flag for the case
neither one covers.

A **sum type** — a variant object — says it once. The object has a **discriminator**: a field holding which
alternative this value is. Each alternative owns its fields, and the fields of the other alternatives are not
part of that value at all. A `case` over the discriminator then lists every alternative, and the compiler
refuses to build a `case` that misses one.

That refusal is the point of the chapter. It is a compile-time check, and it is the reason to prefer this
shape over flags: a new alternative breaks every `case` that forgot it, in the build, not in production.

## The shape of a variant

A `case` section inside an object declares the alternatives (`doc/language.md:592-655`):

```nim
type
  ShapeKind = enum
    Circle, Rectangle, Triangle

  Shape = object
    case kind: ShapeKind
    of Circle:
      radius: float
    of Rectangle:
      width, height: float
    of Triangle:
      a, b, c: float
```

`kind` is the discriminator, and it must be an ordinal type — an enum, an integer, a `bool`. A `string`
selector is rejected with `selector must be of an ordinal type` (`ch12-probes/c40.nim`, `src/nimony/sem.nim:3207`).
A holey enum, the kind Chapter 11 showed with explicit ordinals and gaps, is rejected for the same reason: the
test that admits a type here refuses one with holes (`src/nimony/typeprops.nim:17-33`), and the line arrives
wrapped:

```
[Error] c38.nim(8, 5) illformed AST inside object: (err . "selector must be of an ordinal type")
```

The section must cover every value, or end in `else` (`doc/language.md:627`). Omitting one is a build error. The
declaration alone reports it cleanly, with the same list a `case` statement gives:

```nim
type
  Kind = enum Circle, Rectangle, Triangle
  Shape = object
    case kind: Kind
    of Circle:
      radius: float
    of Rectangle:
      width, height: float
```

```
rv17.nim(5, 5) Error: not all cases are covered; missing: {Triangle}
```

Construct a value of the type and the constructor reports the same information through its generic error, with
the line wrapped (`rv19.nim` is the declaration above plus one construction):

```
[Error] rv19.nim(5, 5) illformed AST inside case object: (err . "not all cases are covered; missing\3A \7BTriangle\7D")
```

Read that as `not all cases are covered; missing: {Triangle}`. The information is there and the location is
the `case` line, but the compiler reports it as an error value left inside the type body: the line begins
`illformed AST inside case object:` and the message arrives escaped (`\3A` for `:`, `\7B` and `\7D` for the
braces). The constructor meets that error node while it walks the type body (`src/nimony/sem.nim:4705`), which
is why the wrapper needs a construction. The packaging is ugly, and it is recorded in `ERRATA.md` rather than
taught as normal output.

`else` is accepted in the section (`c3.nim`, `c17.nim`), and its fields belong to every value the `of`
branches did not name. For an enum, writing every member is the better habit: `else` hides the member a later
edit adds.

Two more rules, both rejected at the declaration:

- One name may not appear in two branches: `of Circle: radius: float` beside `of Rectangle: radius: float`
  gives `attempt to redeclare: radius` (`c24.nim`). The branches share storage, as the `sizeof` numbers below
  measure, so one field name cannot stand for two branches of a single value.
- In this form the discriminator is a named field, and leaving the name out is a parse error: `case bool` gives
  `':' or '=' expected, but got 'keyword of'` (`c30.nim`). The anonymous sum type — `case` with no name and no
  selector — is a separate form with nothing to name; `else` in it is refused instead, with `[Error] ... illformed
  AST inside object: (err . "sum type case objects cannot have an else branch")` (`rv14.nim`,
  `src/nimony/sem.nim:3075`).

## Constructing a variant

A construction names the discriminator and the fields of that one alternative. Fields of other alternatives
are not written, and the ones left out take their default (`doc/language.md:629-641`, `c10.nim`, `c35.nim`):

```nim
let c = Shape(kind: Circle, radius: 1.0)
let r = Shape(kind: Rectangle, width: 2.0, height: 3.0)
let t = Shape(kind: Triangle, a: 3.0, b: 4.0, c: 5.0)

echo Shape(kind: Rectangle, width: 1.0).height   # 0.0
echo Shape(kind: Rectangle).width                # 0.0
```

The discriminator is checked against the fields you name, and there are three rejections worth recognising by
their message (`src/nimony/sem.nim:4559-4578`):

| What you wrote | What the compiler says |
| --- | --- |
| `Shape(kind: Circle, width: 3.0)` | `a case selecting discriminator 'kind' with value 'Circle' appears in the object construction, but the field(s) 'width' are in conflict with this value.` (`c4.nim`) |
| `Shape(kind: Circle, radius: 1.0, width: 3.0)` | `The fields 'radius' and 'width' cannot be initialized together, because they are from conflicting branches in the case object.` (`c5.nim`) |
| `Shape(radius: 1.0)` — no discriminator | `cannot prove that it's safe to initialize 'radius' with the runtime value for the discriminator 'kind'.` (`c51.nim`) |

The first row is why the discriminator has to be a *literal* enum value when a branch field is named. This pin
recognises only a literal spelling at the constructor (`src/nimony/sem.nim:4601-4612`), so a discriminator
written as a name — a `let` or a `const` — is refused even when the value is correct, and the message claims a
conflict that does not exist:

```nim
const k = Circle
let s = Shape(kind: k, radius: 1.0)   # refused: "...with value 'k' ... field(s) 'radius' are in conflict"
let ok = Shape(kind: Circle, radius: 1.0)   # builds
let ok2 = Shape(kind: ShapeKind.Circle, radius: 1.0)   # builds, qualified name is still a literal
```

Probes `c29.nim`, `c49.nim`, `c50.nim`, `rv1.nim`, `rv2.nim`. Write the value out; a qualified
`ShapeKind.Circle` is fine. The restriction is the constructor's alone: the same `const` still works as an `of`
label in a `case` (`rv15.nim`, `rv16.nim`). With no branch field at all, a runtime discriminator is allowed —
`Shape(kind: k)` builds and the branch fields start at their defaults (`c31.nim`).

## Matching with a `case`

The `case` statement from Chapter 6 is the tool here. It takes the discriminator and lists the alternatives
(`doc/language.md:1776-1840`):

```nim
func area(s: Shape): float =
  case s.kind
  of Circle:
    result = PI * s.radius * s.radius
  of Rectangle:
    result = s.width * s.height
  of Triangle:
    let p = (s.a + s.b + s.c) / 2.0
    result = sqrt(p * (p - s.a) * (p - s.b) * (p - s.c))
```

`PI` and `sqrt` come from `std/math`, which the sample imports.

The expression form works the same way and yields a value (`doc/language.md:2086-2100`):

```nim
let label =
  case r.kind
  of Circle: "round"
  of Rectangle: "boxy"
  else: "pointy"
```

### What the compiler checks

At this pin the check is `checkExhaustiveness` (`src/nimony/sem.nim:2699-2748`), and one call serves a `case`
statement, a `case` expression and the object's own `case` section (`sem.nim:3290`); only the place it leaves
the error differs. Leave an enum member out and the build stops at the `case` head with the missing values
named:

```
c13.nim(14, 3) Error: not all cases are covered; missing: {Triangle}
```

That list is the reason to prefer this shape. Add a fourth alternative to `ShapeKind` and every `case` that
switches on it fails to build until it is handled. With a `bool` and two flags, nothing fails.

The rest of the rules a reader will hit, each a probe:

- A selector that is not an enum gets the same message without a list: an `int` `case` without `else` gives
  `not all cases are covered` (`c55.nim`, `c19.nim`). An `int` can never be covered, so the compiler does not
  pretend to name what is missing.
- A duplicated label is `value already handled`, reported at the duplicate (`c57.nim`, `c37.nim`).
- A misspelled label is `undeclared identifier: Cirlce`, followed by the missing list (`c59.nim`).
- Two enum values in one `of` are legal — `of Square, Rectangle:` — and so is a range on an ordinal selector,
  `of 0..3:` (`c16.nim`, `c62.nim`).
- An `else` is allowed even when the enum is fully covered (`c28.nim`). It is dead code; prefer the full list.
- A `bool` has two values, so `of true:` and `of false:` need no `else` (`c54.nim`).
- `case` also accepts a holey enum as a selector: the statement path never runs the test the discriminator path
  runs, so the type is admitted because nothing checks it, not because it qualifies (`c39.nim`, `c56.nim`).

### What the compiler does not check

This is the part that costs a debugging session if it is not said plainly. The branch fields share one block
of storage, and the pin emits **no runtime check** on which branch is active. Reading a field of the inactive
branch compiles and returns whatever the storage holds:

```nim
let s = Shape(kind: Circle, radius: 1.0)
echo s.width     # 1.0 — the radius occupies that slot; nothing complains
echo s.height    # 0.0 — this slot is untouched
```

Writing goes the other way, into the same storage, and leaves the discriminator alone:

```nim
var s = Shape(kind: Circle, radius: 1.0)
s.width = 99.0
echo s.width     # 99.0
echo s.kind      # Circle
```

Probes `c7.nim` and `c8.nim`. Assigning the discriminator directly is legal on a `var`, and it does not clear
or rebuild anything — the old bytes stay and are reinterpreted:

```nim
var s = Shape(kind: Circle, radius: 1.0)
s.kind = Rectangle
s.width = 3.0
echo s.radius    # 3.0 — the radius slot now holds the width
```

Probe `c9.nim`. On a `let`, the same assignment is rejected earlier with `cannot mutate expression s.kind`
(`c36.nim`). The layout below is why nothing checks it: the branches are a union with no tag read at access, and
`FieldDefect`, the Nim 2 name for a check of this kind, appears nowhere under `lib/` or `src/`. The guard is
yours to write. A `case` is how you write it; what the branch reads must be the branch that matches `kind`.

`sizeof` shows the layout the cost comes from: one byte for the discriminator, then the largest branch, rounded
to the alignment of `float`. For the three-branch `Shape` above, `sizeof(ShapeKind)` is `1` and `sizeof(Shape)`
is `32` — one byte plus the 24-byte triangle branch, padded to 8 (`rv10.nim`). A two-branch shape of the same
kind measures `24` (`c44.nim`). Branches whose fields overlap in size share that space; nothing tags each access.

One more shape to avoid, and it is a missing diagnostic rather than a rule: a `case` statement whose `of`
branch is a bare value and whose *another* branch holds a `for` loop dies inside the compiler with
``xelim.nim(118, 3) `result.typeKind != AutoT` ``. The bare value is wrong on its own — it is rejected with
``expression of type `int64` must be discarded`` (`rv12.nim`) — so this is a diagnostic the `for` hides, not
working code the compiler refuses. An `else` is not needed to trigger it: `of false` does the same (`rv8.nim`).
The minimal form is probe `r2.nim`:

```nim
proc f(b: bool): int =
  case b
  of true:
    1
  else:
    for i in 0..2:
      result = result + 1
```

Write the assignment in every branch instead — `of true: result = 1` — and it builds (`r3.nim`). Recorded in
`ERRATA.md` with the probe.

## Nested variants

A branch may hold a `seq` of the same type, which is how a tree is written
(`doc/language.md:635-655`):

```nim
type
  NodeKind = enum
    Leaf, Branch

  Node = object
    id: int
    case kind: NodeKind
    of Leaf:
      value: string
    of Branch:
      children: seq[Node]

func total(n: Node): int =
  case n.kind
  of Leaf:
    result = n.id
  of Branch:
    result = n.id
    for child in n.children:
      result = result + total(child)
```

Probe `c12.nim` builds the same tree, prints `2`, `a`, `6`. A `ref object` variant works too, with the same
construction and the same `case` (`c25.nim`).

> **Nim 2 delta — the runtime field check is gone**
>
> *What Nim 2 did* → reading a field of the inactive branch raised `FieldDefect: field 'width' is not
> accessible for type 'Shape' using 'kind = Circle'`, and assigning the discriminator raised `FieldDefect:
> assignment to discriminant changes object branch` (`nim2/n1.nim`, `nim2/n2.nim` on the host compiler).
> *What Nimony does* → neither is checked. The read returns the union's storage, and the assignment is a plain
> field write (`c7.nim`, `c9.nim`).
> *What breaks if you keep the habit* → code that leaned on the defect to catch a wrong branch now prints a
> plausible number instead, and a port that switched `kind` on an existing value keeps the old bytes. Guard
> with `case` before every branch read; do not rely on the compiler to catch the others.

## Samples

One file proves the chapter: `samples/12-sum-types-case/sumtypes.nim`.

```
~/.local/opt/nimony/4ba90a7/bin/nimony c -r samples/12-sum-types-case/sumtypes.nim
```

Through the verifier:

```
$ ./tools/verify-samples.sh
PASS samples/12-sum-types-case/sumtypes.nim exit=0
SUMMARY 11/11 passed, 0 failed
```

Its output, in order:

```
circle(1.0)
rect(2.0x3.0)
tri(3.0,4.0,5.0)
3.141592653589793
6.0
6.0
boxy
0
4
0.0
0.0
2.0
99.0
Rectangle
true
Branch
2
a
6
```

The first three lines are `$` on each variant. Then the three areas: the circle, the `2x3` rectangle, and the
`3-4-5` triangle through Heron's formula. `boxy` is the `case` expression with `else`. `0` and `4` are the two
`sides` answers. `0.0` and `0.0` are the rectangle's omitted fields: `height` when only `width` is written, then
`width` when neither is. Then `2.0` and `99.0`: the copy changed, the original did not, and `Rectangle` and
`true` are the copied discriminator and the field-by-field equality. The last four are the tree: `Branch`, two
children, the first leaf's value, and `6` — the sum of the three `id`s.

## Checks

1. Declare `Shape` from this chapter and construct a `Circle` and a `Rectangle`. Expected: both build; the
   circle has no `width` and the rectangle has no `radius`.
2. Give `ShapeKind` a fourth member and rebuild without touching `area`. Expected:
   `not all cases are covered; missing: {<the new member>}` at the `case` head.
3. Remove `of Triangle` from the `case` section of the object itself. Expected: the build stops with the
   `illformed AST inside case object` line, and `missing: {Triangle}` inside it.
4. Construct `Shape(kind: Circle, width: 3.0)`. Expected: the `...field(s) 'width' are in conflict with this
   value.` line.
5. Construct with `radius` and `width` together. Expected: `The fields 'radius' and 'width' cannot be
   initialized together...`.
6. Construct `Shape(radius: 1.0)` with no discriminator. Expected: `cannot prove that it's safe to initialize
   'radius' with the runtime value for the discriminator 'kind'.`
7. Put `Circle` in a `const` and construct `Shape(kind: k, radius: 1.0)`. Expected: it is refused, and the
   message names `k`. Write `Shape(kind: ShapeKind.Circle, ...)` instead. Expected: it builds.
8. Build a `Circle` with `radius: 1.0`, then print `s.width` and `s.height`. Expected: `1.0` and `0.0`, no
   diagnostic — the read is not checked, and the radius occupies the first slot.
9. On a `var` `Circle`, assign `s.kind = Rectangle` and `s.width = 3.0`, then print `s.radius`. Expected:
   `3.0`, from the shared storage.
10. Do the same discriminator assignment on a `let`. Expected: `cannot mutate expression s.kind`.
11. Write a `case` over `ShapeKind` that repeats `of Circle` twice. Expected: `value already handled`.
12. Write `of Cirlce`. Expected: `undeclared identifier: Cirlce` plus the missing list.
13. Print `sizeof(ShapeKind)` and `sizeof(Shape)` for the three-branch version. Expected: `1` and `32`.
14. Build the `Node` tree from this chapter and print `total`. Expected: `6`.

## Chapter checklist

draft 2026-11-12 · tech_review Momo 2026-11-12 · editorial_pass 2026-11-12 · frozen 2026-11-12
