---
chapter: 8
title: Procedures, Parameters, and Results
job: Define `proc` and `func`, return through `result`, pass by `var` and `sink`, and use default and named arguments.
nimony_version: 0.6.3
nimony_commit: 4ba90a781b0b22d0821efaa153c129c37cef6143
toolchain: /Users/sachiel/.local/opt/nimony/4ba90a7
host_compiler: /Users/sachiel/.local/opt/nim-2.4.0
status: frozen
tech_review: Momo 2026-11-12
editorial_pass: 2026-11-12
samples: ["samples/08-procedures/procedures.nim"]
glossary_added: ["proc", "func", "result", "var parameter", "out parameter", "sink parameter", "default argument", "named argument"]
---

# Procedures, Parameters, and Results

## What this chapter is for

Every chapter so far has been a program made of statements. A routine gives a run of statements a name and a
signature, so the rest of the book can call it instead of repeating it. Nimony has two declarations for that:
`proc`, which may do anything, and `func`, which may not touch anything outside its own arguments and result.

The job here is the whole boundary of a call — how arguments arrive, how the result leaves, and which parameter
form to reach for. Overloading and method dispatch are Chapter 9; this chapter assumes one routine per name.

## A proc is a statement block with a name

```
proc greet(name: string) =
  echo "hi ", name

greet("nimony")
```

```
hi nimony
```

The `=` starts the body, and the body is a block of statements at one deeper indent
(`doc/language.md:2211-2218`). No return type after `)` means the routine produces nothing: you call it for
what it does.

Parameters go in the parentheses as `name: type`. The type applies to every name before it, across commas, and
stops at a semicolon (`doc/language.md:2218-2224`). So this is legal and `c` has its own type:

```
proc add(a, b: int; c: float): float =
  float(a + b) + c
```

`add(1, 2, 0.5)` prints `3.5`. The guide's warning is real at the pin: drop the type from the first group and
the declaration is rejected — `proc bad(a; b: int)` fails with `type or init value expected`, reported at the
parameter name.

A return type comes after the closing parenthesis. The body can then be written in two shapes. The block form
is what `greet` used. The single-expression form writes the value on the same line:

```
proc triple(x: int): int = x * 3
```

`triple(5)` is `15`. This is not a second declaration form to choose by taste — it is the same routine with a
one-expression body, and both forms appear in the standard library: `lib/std/colors.nim:21` writes one this way,
`lib/std/syncio.nim:293` uses the block.

## The body's last expression is the result

A block body is a statement list expression, and a statement list expression evaluates to its last expression
(`doc/language.md:1552-1560` defines the parenthesised `(stmt1; stmt2; …; ex)` form; applying it to a proc body is
probe p33). So this compiles and returns `5`:

```
proc f(): int =
  echo "body"
  5
```

The `echo` is a statement that runs first; the `5` is the value the body produces. Nothing marks the last line
as special, which is why a stray trailing expression in a routine that already assigns `result` is a mistake
worth watching: it becomes the result even after `result` was set. `proc f(): int = result = 1` followed by `5`
returns `5`, not `1`. Write `discard` if that is not what you mean.

## `result` is a variable

A routine with a return type has an implicitly declared variable named `result` that holds the return value
(`doc/language.md:2243-2245`). Assign to it anywhere in the body; when the body ends, `result` is what the
caller gets:

```
proc f(a, b: int): int =
  result = a + b

echo f(2, 3)
```

That prints `5` with no `return` anywhere. Because `result` is an ordinary variable, the assignment can be
split across branches, and Chapter 3's rule applies to it: every path that reaches the end must have written
it. A routine that never does fails to build:

```
proc counter(): int =
  discard

echo counter()
```

```
Error: cannot prove that result has been initialized
```

That is the same definite-assignment check that catches an `if` expression without `else`; the name in the
message is `result` because that is genuinely the variable this time (`src/nimony/contracts_fir.nim:6065`, which
builds this wording for `result` and for a parameter alike).

## `return`

`return expr` is sugar, and the guide says so in as many words: it means `result = expr` followed by `return`
(`doc/language.md:1915-1921`). `return` without an expression is short for `return result`
(`doc/language.md:1924-1926`), which is only useful after something has already set `result`:

```
proc sign(n: int): int =
  if n > 0:
    result = 1
    return
  result = 0
```

`sign(4)` is `1`, `sign(-4)` is `0`. The bare `return` leaves at that line with whatever `result` holds.

With a value it leaves earlier, skipping the rest of the body:

```
proc grade(n: int): string =
  if n >= 50:
    return "pass"
  echo "checked ", n
  "fail"
```

`grade(70)` is `pass` and prints nothing else; `grade(10)` prints `checked 10` and then returns `fail` through
the body's last expression. The early exit is a control-flow tool, not a style — reach for `result` plus the
last expression when the routine reads top to bottom.

## Default values

A parameter may carry a default (`doc/language.md:2234-2241`):

```
proc pad(n: int; width: int = 3): int = n * width

echo pad(7)
echo pad(7, 2)
```

`21` and `14`. The guide adds a detail that is easy to skim past: the default is **re-evaluated every time the
routine is called**, not once at declaration (`doc/language.md:2234-2241`). The illustration needs a module-level
counter, and this pin rejects that from a plain `proc` with `unsynchronized access to global variable`; the
demonstration is therefore registered in `ERRATA.md` rather than shown here, and the rule for the book is
`CONTRIBUTING.md`'s: a chapter that shows module-level mutable state states the `.sync` rule at first use.

One shape must not be written at this pin: a default written in terms of an earlier parameter.

```
proc scaled(x: int; factor: int = x): int = x * factor
```

That is not a diagnostic. The front end accepts it and the build dies in the C backend with
`[Bug] could not find symbol: x.0`, exit 1. It is recorded in `ERRATA.md`; the book's rule is that a default is
a literal or an expression that names no parameter of the same routine.

## Named arguments

An argument may be given by name instead of by position. The guide does not describe the form — the only trace
of it in `doc/` is the NIF tag for "explicitly named arguments in function calls" (`doc/tags.md:33`) — so
everything in this section is probed at the pin, not quoted:

```
proc pad(n: int; width: int = 3): int = n * width

echo pad(width = 2, n = 7)
```

`14`. Names may appear out of order, and parameters you skip still take their defaults: `pad(n = 7)` is `21`.
The name is checked — `pad(count = 1)` fails with `named argument not found` — and the count is too:
`pad(1, 2, 3)` fails with `too many arguments`. Both are reported at the call site with the declaration named
underneath, which is the useful half when a default lured you into passing one argument too many.

Use names when a call has two arguments of the same type and the order is not obvious from the function name.
`pad(2, 7)` is `14` and `pad(7, 2)` is `21`; the named form `pad(width = 2, n = 7)` is `14` as well, but it says
which number is which, and a reader who mistook the order cannot misread it.

## `var` parameters

Prefix the type with `var` and the parameter becomes a handle on the caller's variable
(`doc/language.md:2350-2372`):

```
proc bump(x: var int) =
  x = x + 1

var n = 5
bump(n)
echo n
```

`6`. The write inside the routine is visible outside it, because a `var` parameter is a hidden pointer to the
argument (`doc/language.md:2370-2372`).

The argument has to be a place, not a value. `bump(7)` is rejected:

```
Error: cannot pass 7 to var/out T parameter
```

The rule is the same one Chapter 3 used for assignment: the thing on the left has to be a variable with
storage. A `let` will not do either.

## `out` parameters

`out T` is the writing-only sibling (`doc/language.md:2765-2790`). It exists for the case where a routine must
produce more than one result and a return value is not enough:

```
proc split(a, b: int; q, r: out int) =
  q = a div b
  r = a mod b

var q, r: int
split(8, 5, q, r)
echo q, " ", r
```

`1 3`. The compiler checks the routine rather than each call: every path before the return has to set every
`out` parameter (`doc/language.md:2782-2790`). Take away the assignment inside the `if` and the routine stops
building with `cannot prove that y has been initialized` — the same wording as a local that a branch may leave
unwritten.

One difference from the guide's description is worth stating plainly. `doc/language.md:2765` says an `out`
parameter "must be written to before it can be used"; at the pin the routine builds if you read it first. What the
read returns is the caller's current value, not a fresh one: `var v = 9` passed to a routine that echoes the
parameter before writing it prints `before 9`. A variable the caller just declared happens to read `0`, which is
why the shape looks harmless in a first test. The enforcement is the every-path check on the routine, not a read
barrier. Do not write a routine that reads an `out` parameter before assigning it — it builds, and what it reads
is whatever the caller's storage held.

## More than one result, two ways

`var` and `out` parameters are one way to return several values. A tuple is the other, and it keeps the result
in the return type where the caller can see it (`doc/language.md:2386-2394`):

```
proc divmod(a, b: int): (int, int) = (a div b, a mod b)

let t = divmod(8, 5)
echo t[0], " ", t[1]
```

`1 3`. The tuple is constructed in the expression body and indexed at the call site. Chapter 10 covers tuple
access properly; what matters here is the choice: parameters when the routine also has side effects to report,
a tuple when the value is the whole answer.

## `sink` parameters

`sink T` marks a parameter the routine may take over (`doc/language.md:3626-3636`):

```
proc take(s: sink string) =
  echo "sink got ", s

var text = "abc"
take(text)
echo "sink after ", text
```

```
sink got abc
sink after abc
```

The caller's variable still holds `abc` after the call, so at this pin `sink` on a `string` is a permission,
not an observable move: it tells the compiler the callee may keep the argument's storage instead of copying it,
and nothing at the call site changes. Write it when a routine stores what it is given — the container code in
the standard library does — and do not expect it to empty your variable or to make a call cheaper in a way you
can measure.

## `func` is a proc with no side effects

`func` declares a routine that is treated as `noSideEffect` by default, where `proc` is treated as having side
effects (`doc/language.md:3115-3119`). Side-effect free means, in the guide's words, no access to global or
thread-local variables, no call to a routine that has side effects, and no mutation through a `ref` or `ptr`.

The practical rule is short: if the routine only reads its arguments and computes, write `func`. If it echoes,
writes a file, or changes something the caller can observe, write `proc`.

Trying to cheat is caught. A `func` that echoes fails to build:

```
Error: cannot call a routine with side effects from a `.noSideEffect` context
```

The error points into `syncio`, because `echo` is the side-effecting routine being called. When the effect is
deliberate, the declaration can say so — `{.sideEffect.}` on a `func` restores `proc` behaviour and the call
compile-and-runs.

One nuance the guide spells out and the compiler enforces: a `func` may write its own `var` parameter — the
variable the caller named — but not anything behind a `ref` or `ptr` (`doc/language.md:3121`). A `func` that adds
into a `var seq[int]` passes and the caller's sequence grows; a `func` that writes `n.x` through a `ref` object
is rejected with `cannot mutate n.x through a ref/ptr in a .noSideEffect context`. Summing into `result` over that
sequence is a different matter: the body has to set `result = 0` before the loop, or the routine fails to build
with the same `cannot prove that result has been initialized` as any other path that leaves it unset.

There is no `noSideEffect` inference (`doc/language.md:3156`): a `proc` is not quietly treated as pure because its
body looks pure. The defaults are the declaration's, and the annotations override them.

## A value is not a statement

A statement position does not accept a value. Calling a routine that returns something and ignoring the result
is a static error (`doc/language.md:1577-1578`):

```
proc add(a, b: int): int = a + b

add(1, 2)
```

```
Error: expression of type `int64` must be discarded
```

Write `discard add(1, 2)` when the value really is unwanted (`doc/language.md:1562-1578`). The same rule makes
a void routine unusable as a value: `let x = greet("a")` does not build, because there is nothing to bind.

## Calling forms

Three forms, all the same call (`doc/language.md:2261-2272`).

**Positional**, with parentheses: `add(1, 2)`, `5.add(6)`.

**Dot form**, where the receiver becomes the first argument (`doc/language.md:2836-2866`): `5.add(6)` is
`add(5, 6)` and prints `11`. It composes with defaults: `1.optarg optarg 8` calls `optarg(1, optarg(8))` and
prints `9`, exactly as the guide's example says.

**Command form**, no parentheses, only where the call is a statement (`doc/language.md:2868-2875`):

```
proc note(msg: string) =
  echo "note ", msg

note "no parens"
```

In an expression position the command form takes exactly one argument: `let single = singlearg 2` builds. Two
arguments in that position is a syntax error at the pin — `let r = add 1, 2` reports `invalid indentation`,
where the guide's own example predicts `too many arguments`. Write the parentheses in an expression.

And a call with no arguments always needs its parentheses: the bare name is the routine itself, a value of the
routine's type. `echo f` where `f` takes no arguments is a type mismatch; the message lists eight candidate
`echo` overloads and one line in that list is `expected: int64 but got: proc (): int64`
(`doc/language.md:2891-2893`).

## Recursion and declaration order

A routine may call itself (`doc/language.md:2274`):

```
proc fact(n: int): int =
  if n <= 1:
    1
  else:
    n * fact(n - 1)
```

`fact(5)` is `120`. The recursion is ordinary calls, not a special form; the base case is the `if` that returns
without recursing.

Declaration order does not matter at module level. A call may appear above the declaration it resolves to — this
is probed at the pin, not quoted, because the guide has no sentence on it:

```
echo later(4)

proc later(x: int): int = x + 1
```

That prints `5`. The whole module is in scope for name resolution, so a `proc` does not need a forward
declaration the way a C prototype does. A name that exists nowhere is a different error, reported as
`undeclared identifier` — the module-wide lookup is what makes the call above the declaration work.

## Samples

`samples/08-procedures/procedures.nim` — every construct in this chapter, in order, at the pinned commit:

```
$ nimony c -r samples/08-procedures/procedures.nim
block 42
single 15
result hi!!
early pass
late checked 10
fail
bare 1 0
default 21
named 14
var 6
out 1 3
tuple 1 3
sink got abc
sink after abc
func 49
override ran
override 1
dot 11
note no parens
fact 120
later 5
```

Three lines carry their own lesson. `late checked 10` and the `fail` after it are one routine: the `echo` ran,
then the body's last expression became the result, so the label and the value land on separate lines.
`override ran` before `override 1` is the `{.sideEffect.}` func printing before its value is used. `sink after
abc` is the `sink` parameter leaving the caller's variable alone.

## Checks

1. Write `proc double(x: int): int` with a block body `x * 2`, then the single-expression form of the same
   routine. Expected: the same value from both.
2. Write a block body that echoes `body` and then has `5` as its last line. Expected: `body`, then `5`.
3. Write `proc counter(): int` with a body of `discard`. Expected: `cannot prove that result has been
   initialized`.
4. Run the `sign` example. Expected: `1` for `4` and `0` for `-4`. Replace the bare `return` with a `return
   result`. Expected: unchanged.
5. Run the `grade` example with `70` and with `10`. Expected: `pass` alone, then `checked 10` followed by
   `fail`.
6. Write `pad(n: int; width: int = 3)`. Expected: `pad(7)` is `21`, `pad(7, 2)` is `14`, `pad(width = 2, n =
   7)` is `14`. Try `pad(count = 1)`. Expected: `named argument not found`. Try `pad(1, 2, 3)`. Expected: `too
   many arguments`.
7. Write `proc scaled(x: int; factor: int = x): int`. Expected: the build dies with `[Bug] could not find
   symbol: x.0`. Replace the default with `3`. Expected: it builds.
8. Run the `bump` example. Expected: `6`. Change the call to `bump(7)`. Expected: `cannot pass 7 to var/out T
   parameter`.
9. Run the `split` example. Expected: `1 3`. Move `r = a mod b` inside `if false:` and rebuild. Expected:
   `cannot prove that r has been initialized`.
10. Run the `divmod` example. Expected: `1 3`.
11. Run the `take` example. Expected: `sink got abc` then `sink after abc`.
12. Write `func square(x: int): int = x * x`. Expected: `49`. Add `echo "side"` to the body. Expected:
    `cannot call a routine with side effects from a .noSideEffect context`. Add `{.sideEffect.}` to the
    declaration. Expected: it builds and prints.
13. Call a routine that returns `int` as a statement. Expected: `expression of type int64 must be discarded`.
    Wrap it in `discard`. Expected: it builds.
14. Write the `note` example with `note "no parens"`. Expected: `note no parens`. Try `let r = add 1, 2` with a
    two-argument `add`. Expected: `invalid indentation`. Add the parentheses. Expected: it builds.
15. Write `echo f` where `f` is a no-argument `int` routine. Expected: a type mismatch ending `proc (): int64`.
    Write `echo f()`. Expected: the value.
16. Run the `fact` example. Expected: `120`. Write `echo later(4)` above `proc later(x: int): int = x + 1`.
    Expected: `5`.

## Chapter checklist

draft 2026-11-12 · tech_review Momo 2026-11-12 · editorial_pass 2026-11-12 · frozen 2026-11-12
