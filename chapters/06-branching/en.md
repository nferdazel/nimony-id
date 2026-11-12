---
chapter: 6
title: Branching That Returns a Value
job: Use `if`, `case` and `when` as expressions, rely on exhaustive `case`, and label `break` because unlabelled `break` only leaves the innermost loop.
nimony_version: 0.6.3
nimony_commit: 4ba90a781b0b22d0821efaa153c129c37cef6143
toolchain: /Users/sachiel/.local/opt/nimony/4ba90a7
host_compiler: /Users/sachiel/.local/opt/nim-2.4.0
status: frozen
tech_review: Momo 2026-11-12
editorial_pass: 2026-11-12
samples: ["samples/06-branching/branching.nim"]
glossary_added: ["if expression", "case expression", "when", "exhaustive case", "labelled break", "block expression"]
---

# 6. Branching That Returns a Value

## What this chapter is for

In many languages a branch is a statement: it runs code and then it is done. In Nimony the same keywords also
produce a **value**, so `if` and `case` can sit on the right of a `let`. That removes a whole class of
"declare first, assign in each branch" code.

Two rules go with the feature, and both are enforced by the compiler rather than by convention: an
`if` expression must have an `else`, and a `case` over an ordinal type must cover every value it can hold.

This chapter also covers the two ways to leave a loop early, because the default changed from Nim 2: an
unlabelled `break` leaves only the innermost loop, so leaving two nested loops needs a labelled `block`.

## `if` as a statement

The statement form is what you already expect (`doc/language.md:1737-1775`):

```
let score = 72
if score >= 90:
  echo "A"
elif score >= 70:
  echo "B"
else:
  echo "C"
```

Conditions are evaluated in order and the first true one wins. The `else` is optional here: with no branch
taken, execution simply continues after the `if`. Each branch opens its own scope, so a name declared inside
one branch is not visible in another.

## `if` as an expression

Put the same construct where a value is expected and it returns the value of the branch that ran
(`doc/language.md:2069-2081`):

```
let score = 72
let label = if score >= 50: "pass" else: "fail"
echo label        # pass
```

The `else` is not optional in this form. An expression has to produce a value on every path, and the compiler
enforces that through definite assignment rather than through syntax — the error comes from the checker that
tracks whether a variable has been written before it is read (`src/nimony/contracts_fir.nim:4165`).

The diagnostic is worth seeing once, because it does not mention `else` at all:

```
let y = if false: 9
```

```
Error: cannot prove that `x has been initialized
```

The name `x` in that message is not yours; the source above declares no `x`. It prints `x` whatever you called
the binding: `let z = if false: 9` gives the same line, and so does the same code inside a proc. `x` is the
temporary the expression reads. What the message means is that the value of `y` is unproven on the path where
the condition is false. Add the `else` and it compiles:

```
let y = if false: 9 else: 0
echo y            # 0
```

One shape slips past the check: when the condition is the literal `true`, the false path is dead code and is
elided, so `let y = if true: 9` compiles. Do not rely on it — write the `else`.

`elif` chains work in the expression form too, and the last expression inside a branch is its value:

```
proc sign(n: int): string =
  result = if n < 0: "neg" elif n == 0: "zero" else: "pos"

echo sign(-2), " ", sign(0), " ", sign(7)   # neg zero pos
```

## `case` as a statement

`case` selects by value instead of by condition (`doc/language.md:1776-1804`):

```
let n = 3
case n
of 0: echo "zero"
of 1, 2: echo "small"
else: echo "large"
```

An `of` branch takes a comma-separated list of values, and a ranged entry covers a span: `of 1..4`. The values
in an `of` branch must be constant expressions — the compiler checks exhaustiveness, and that check needs to
know the set in advance.

The `else` branch is the fallback. For an ordinal selector it is optional **only** when the branches already
cover every value the type can hold (`doc/language.md:1800-1804`).

## Exhaustiveness

Cover every value and `else` is not needed:

```
type Color = enum red, green, blue
let c = green
let name = case c
  of red: "r"
  of green: "g"
  of blue: "b"
echo name         # g
```

Leave one out and the compiler refuses, naming what is missing (`src/nimony/sem.nim:2746`):

```
of red: "r"
of green: "g"
```

```
Error: not all cases are covered; missing: {blue}
```

That message is a gift: add the value it names and the chapter of accidental falls-through never happens.
When the selector is not an enum — an `int`, a `char` — the compiler cannot list what is absent, so the
message is bare (`src/nimony/sem.nim:2748`):

```
Error: not all cases are covered
```

For those types the fix is an `else`, and the domain is then as wide as the type. `of 0..59` plus `else` is
exhaustive. `of 'a'..'z'` and `of 'A'..'Z'` are **not** exhaustive for `char`, because all 256 values are in
range; that shape needs an `else` too.

## `case` as an expression

The same construct produces a value, with the branch's last expression as the result
(`doc/language.md:2086-2103`):

```
let grade = case score
  of 0..59: "F"
  else:
    if score >= 90: "A" else: "B"
echo grade        # B
```

A branch may contain several statements; only the last one is the value. The interesting consequence is that
a `case` expression can carry side effects, which is usually a sign the branch is doing too much:

```
let label = case n
  of 1:
    echo "checking one"
    "one"
  of 2:
    echo "checking two"
    "two"
  else: "many"
```

That prints `checking two` and binds `label` to `"two"`. Prefer the pure form; use a statement `case` when the
branches exist to run code.

## No `elif` inside a `case`

Nim 2 allows `elif` after the `of` branches of a `case`. Nimony does not, and this is worth knowing before you
copy an example from the older documentation:

```
let r = case n
  of 0: "zero"
  elif n > 10: "medium"
  else: "small"
```

```
Error: not all cases are covered
Error: `elif` branch in a `case` is not supported; use `else:` with a nested `if`
Error: this branch in a `case` is not supported; use `else:` with a nested `if`
```

The first line is collateral: a rejected `elif` does not count as coverage, so the same `case` also looks
non-exhaustive. The second and third lines are the same rule firing twice, on the `elif` and on the `else` that
follows it. A string selector produces only those two. The fix is the one the message gives — ordinary nested
`if` inside `else`, which clears all three:

```
let r = case n
  of 0: "zero"
  else:
    if n > 10: "medium" else: "small"
```

The rejection is deliberate and recent: an earlier build dropped the whole tail after an `elif` without a
diagnostic, which silently deleted a default branch in the compiler's own source
(`src/nimony/sem.nim:3292-3307`). Erroring is the safer trade, so a `case` at this pin is `of`…`else`, and
anything more conditional goes inside the `else`.

## A string selector: no `else` required, so always write one

`string` is the exception in the rules above: a `case` on a string does not require an `else` or an `elif`
(`doc/language.md:1811-1812`), and the exhaustiveness check is skipped for it entirely
(`src/nimony/sem.nim:3287-3290`).

Skipping the check is not the same as handling the miss. In a **statement** `case`, an unmatched string simply
does nothing, which is harmless:

```
var r = -1
case "zzz"
of "go": r = 111
of "stop": r = 222
echo r            # -1
```

In an **expression** `case`, the miss does not stop at the value: at this pin the last `of` branch is executed
as the fallback, side effects and all, and the expression takes its value.

```
var s = "zzz"
let r = case s
  of "go":
    echo "go branch"
    111
  of "stop":
    echo "stop branch"
    222
echo r
```

```
stop branch
222
```

Reorder the branches and both the line printed and the number follow. Nothing warns you. That is why the rule
for this book is: **every `case` expression on a `string` gets an `else`**, whether or not the language asks
for one. The skipped exhaustiveness check is documented; the fallthrough into the last branch is not. Ruled
2026-11-12: the check skip is intended, the fallthrough is an unfixed defect at this pin.

## `when`: branching at compile time

`when` looks like `if` and is resolved before the program exists (`doc/language.md:1872-1901`). Each condition
must be a constant expression of type `bool`, and only the taken branch is compiled:

```
when sizeof(int) == 8:
  echo "64-bit int"
else:
  echo "not 64-bit"
```

The branch that is not taken is not semantically checked at all, so it may mention names and types that do not
exist:

```
when false:
  let q: int = "not an int"
echo "compiled"    # compiled
```

That is how a program carries platform-specific code for a platform it is not being built for. The conditions
themselves are always checked; a non-constant condition is rejected rather than deferred:

```
let x = 5
when x > 0:
  echo "positive"
```

```
Error: cannot evaluate expression at compile time:
undeclared identifier: x
```

`when` does not open a new scope, unlike `if`. A definition inside the taken branch stays visible after it:

```
proc f(): int =
  when true:
    let k = 41
  result = k + 1
echo f()          # 42
```

Do not build on that. The definition is only visible when the branch was taken, so a name defined inside a
`when` is as conditionally present as the branch itself.

The expression form exists too, and it is the honest way to pick a constant:

```
let width = when sizeof(int) == 8: 64 else: 32
echo width        # 64
```

## `block`: an expression with a name you can leave

A `block` groups statements, and a named one can be left early (`doc/language.md:1946-1974`):

```
var found = false
block myblock:
  for i in 0..3:
    for j in 0..3:
      if i * j == 4:
        found = true
        break myblock
echo found        # true
```

`break myblock` leaves the block and everything inside it, which is how a doubly nested search exits in one
step without a flag.

A `block` can also be an expression, and its value is the last expression inside it
(`doc/language.md:2105-2119`):

```
let total = block:
  var sum = 0
  for i in 1..4:
    sum = sum + i
  sum
echo total        # 10
```

That shape keeps a scratch variable out of the surrounding scope: `sum` exists only inside the block.

## Labels: `break` leaves one loop by default

This is the part that bites Nim 2 code. An unlabelled `break` leaves the innermost loop only
(`doc/language.md:1975-1990`), and it never leaves a `block` (`doc/language.md:1963`; `doc/differences.md:23`):

```
var pairs = 0
for i in 0..2:
  for j in 0..2:
    if j == 1:
      break
    pairs = pairs + 1
echo pairs        # 3
```

Three rows, each stopping at `j == 1`: the outer loop keeps going. To leave both loops you name the block
around them and break to that name, as in the previous section.

Two rules keep this straight:

- `break <name>` leaves the named block, wherever the `break` sits inside it.
- `break` with no name leaves the innermost loop, and is an error outside a loop:
  ``Error: `break` only possible within a loop or a `block` statement``.

A named block is not a substitute for a procedure. If the exit is carrying a value out of a computation that
deserves a name, write the proc.

## Nim 2 delta: labelled `break`, and no `elif` in `case`

Two habits from Nim 2 stop working here.

**Leaving nested loops.** In Nim 2 an unlabelled `break` inside a `block` inside a loop could leave the block;
at this pin an unlabelled `break` always means the innermost loop. The replacement is a named `block` and
`break <name>` (`doc/differences.md:23`). `{.feature: "anonBlockBreaks".}` restores the old reading per module,
but the book does not use it: the named form says what it leaves, and that is the whole point.

**`elif` in a `case`.** The pin rejects it and tells you to nest an `if` in the `else`
(`src/nimony/sem.nim:3305`). Older examples and older habits will reach for the `elif` chain; rewrite it.

One more delta, in the other direction: the `if`/`case`/`when` **expression** forms are the normal way to
produce a value, not a trick. Nim 2 code that declares a variable and assigns it in every branch can usually
collapse into one `let`.

## Samples

`samples/06-branching/branching.nim` — every construct in this chapter, in order:

```
B
pass
large
g
B
a
64-bit int
64
10
1
3
```

The `B` twice is not a duplicate: the first is the `if` statement, the fifth line is the grade computed by the
`case` with a nested `if`. `10` is the block expression summing `1..4`; `1` is the labelled break finding
`i * j == 4` once; `3` is the unlabelled break counting one pair per row.

## Checks

1. Write `let y = if false: 9`. Expected: ``Error: cannot prove that `x has been initialized``. Add
   `else: 0` and expect `0`.
2. Write `case` over `enum red, green, blue` with only `red` and `green` handled. Expected:
   `not all cases are covered; missing: {blue}`. Add the `blue` branch and expect it to compile.
3. Write `case` over an `int` with `of 0` and `of 1` and no `else`. Expected: `not all cases are covered`,
   with no value named.
4. Write `case` over a `char` with `of 'a'..'z'` and `of 'A'..'Z'`. Expected: the same bare
   `not all cases are covered`. Add `else: discard` and expect it to compile.
5. Write the `elif`-in-`case` shape from this chapter. Expected: three errors — `not all cases are covered`,
   then `` `elif` branch in a `case` is not supported; use `else:` with a nested `if` ``, then the same for the
   following `else`. Rewrite it as `else:` plus an `if` and expect it to compile.
6. Write `let r = case "zzz"` with `of "go": 111` and `of "stop": 222`, no `else`, and an `echo` in each branch.
   Expected: the first run prints the last branch's line and `222`. Swap the two branches and expect the other
   line and `111`. Then add `else: 999` and expect `999` with no branch line.
7. Write `when x > 0` with `var x = 5` above it. Expected: `cannot evaluate expression at compile time` and
   `undeclared identifier: x`.
8. Write `when false:` with `let q: int = "not an int"` inside. Expected: it compiles. Remove the `when` and
   expect a type mismatch.
9. Write a doubly nested `for` with an unlabelled `break` in the inner loop. Expected: the outer loop
   continues. Wrap both in `block outer:` and use `break outer`. Expected: both loops end.

## Chapter checklist

draft 2026-11-12 · tech_review Momo 2026-11-12 · editorial_pass 2026-11-12 · frozen 2026-11-12
