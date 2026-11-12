---
chapter: 7
title: Loops and Ranges
job: Iterate ordinals with `for`, control repetition with `while` and `continue`, and prove a `range` only in the local form the compiler accepts.
nimony_version: 0.6.3
nimony_commit: 4ba90a781b0b22d0821efaa153c129c37cef6143
toolchain: /Users/sachiel/.local/opt/nimony/4ba90a7
host_compiler: /Users/sachiel/.local/opt/nim-2.4.0
status: frozen
tech_review: Momo 2026-11-12
editorial_pass: 2026-11-12
samples: ["samples/07-loops-ranges/loops.nim"]
glossary_added: ["for loop", "loop variable", "iterator", "countup", "countdown", "range proof"]
---

# Loops and Ranges

## What this chapter is for

Repetition has two forms here. `for` runs a body once for each value an iterator produces, which is the ordinary
way to walk a span of numbers or characters. `while` runs a body while a condition holds, which is what you want
when the number of rounds is not known in advance.

The second half of the chapter is about `range`, the type Chapter 4 introduced. A loop is where a range usually
appears: an index bound, a loop bound, a small number passed to a routine that only accepts digits. At this pin
the compiler defends a range by proof rather than by a runtime check, and that proof has a scope — it must be
visible where the value is used, and it does not follow the value into another routine.

## `for` over a range

```
for i in 0..3:
  echo i
```

```
0
1
2
3
```

`0..3` is an iterator, not a container (`lib/std/system/iterators.nim:14-44`). It counts up and includes both
ends. The loop declares its own variable, its type is the type the iterator yields (`int` here), and its scope
ends with the body (`doc/language.md:4041-4056`). Trying to use `i` after the loop is an error: `undeclared
identifier: i`.

The bounds do not have to be literals:

```
let n = 3
for i in 0..n:
  echo i
```

A descending pair is empty rather than reversed, because `..` only counts up (`iterators.nim:14-44`):

```
var seen = 0
for i in 3..0:
  seen = seen + 1
echo seen
```

```
0
```

The body never ran. Descending needs the iterators in the next section but one.

One upper bound is refused at compile time. `for i in 0..high(int)` does not build:

```
Error: contract violated: b < 9223372036854775807'i64 or sizeof(int64) == 1 and …
```

The ellipsis is not hiding a second rule: the full line repeats the same bound for the other `sizeof` cases and
ends with `[pass --verbose for the Final IR]`.

The reason is in the iterator's own comment (`iterators.nim:15-32`): the loop ends by incrementing past `b`, and
at `high(T)` there is no such value — `inc` wraps, and the loop would never end. So the inclusive iterator
requires a bound below `high(T)`, or a type with bits to spare.

A range stored in a variable is not a loop bound:

```
let r = 0..3
for i in r:
  echo i
```

```
Error: Type mismatch at [position]
items(r)
[1] expected: typedesc[T] but got: HSlice[int64,int64] …
```

In a `for` statement `a..b` resolves to the iterator. `let r = 0..3` builds the slice value instead
(`lib/std/system.nim:610-616`), and no `items` overload accepts it. Write the bounds at the loop.

## The half-open form: `..<`

```
for i in 0..<3:
  echo i
```

```
0
1
2
```

`a..<b` is the same span with the upper bound excluded; as a value it is `a..pred(b)` (`system.nim:610-616`), and
as a loop it counts up and stops before `b` (`iterators.nim:1-12`). Equal bounds give nothing: `for i in 3..<3`
never runs.

The form earns its place with a length:

```
let word = "abc"
for i in 0..<len(word):
  echo i, " ", word[i]
```

```
0 a
1 b
2 c
```

The compiler accepts `word[i]` because the iterator declares `ensures: (a <= result and result < b)`
(`iterators.nim:1-12`). That clause is what makes the range of the loop variable provable at the index, and the
comment above the iterator says so in as many words: an inline iterator is not inlined until long after contract
analysis, so the range has to be stated rather than derived.

The inclusive version builds and then dies:

```
for i in 0..len(word):
  echo word[i]
```

```
…/stringimpl.nim(686, 37): i < len(s) [AssertionDefect]
```

The loop's range promises `i <= len(word)`, which is one value more than the index allows, so the assertion in
`[]` (`lib/std/system/stringimpl.nim:686`) stops the program at `i == len(word)`. Half-open is not a style
preference in this pattern; it is the difference between provable and crashing.

## Counting down, and stepping

Three ways to descend at the pin:

```
for i in countdown(3, 1):
  echo i          # 3 2 1
```

```
for i in 3 >.. 0:
  echo i          # 3 2 1
```

`countdown` counts from `a` down to `b`, inclusive (`iterators.nim:59-74`). The `>..` iterator is the descending
sibling of `..`, written with the larger value on the left (`iterators.nim:46-53`).

`countup` takes a step, and so does `countdown`:

```
for i in countup(0, 6, 2):
  echo i          # 0 2 4 6

for i in countdown(5, 1, 2):
  echo i          # 5 3 1
```

`countup` takes `step: Positive` (`iterators.nim:76`), so a negative step does not compile: `countup(0, 6, -2)`
fails with `value out of range: -2 notin 1..9223372036854775807`. `countdown` takes an ordinary ordinal step
(`V: Ordinal`, `:59`); only its comment says the step may be positive (`:64`), and a negative one compiles and
climbs away from `b` instead of descending — `countdown(5, 1, -1)` prints `5 6 7 8 …` and never stops. `countup`
also carries the `b < high(T)` requirement `..` has (`:77-82`); `countdown` has no such `requires`, only the note
that it fails when `a >= b and b + step > high(T)` (`:66-67`).

## `char` is an ordinal too

`char` has an order, so the same iterators apply:

```
for c in 'a'..'c':
  echo c
```

```
a
b
c
```

`ord(c)` on the same loop prints `97`, `98`, `99`, because a `char` is a small integer with a printable face.
Descending needs the same help as `int`: `countdown('c', 'a')` and `'c' >.. 'a'` both print `c`, `b`, `a`, while
`'c'..'a'` is empty.

## The loop variable is a variable

Its scope ends with the body, but at this pin it is not read-only. Writing it moves the loop:

```
for i in 0..5:
  if i == 1:
    i = 3
  echo i
```

```
0
3
4
5
```

The write set the counter to `3`, and the next round continued from `4`. Writing past the bound ends the loop
instead: `for i in 0..2: i = 5; echo i` prints `5` once and stops.

The book's rule is to read the loop variable and not write it. Nothing in the samples here writes it, and no
later chapter relies on it — the behaviour is recorded in `ERRATA.md` as a pin observation, not taught as a
technique.

## `continue`

`continue` jumps to the next iteration of the surrounding loop (`doc/language.md:2010-2015`):

```
for i in 0..5:
  if i mod 2 == 0:
    continue
  echo i
```

```
1
3
5
```

It targets the loop even from inside a bare `block`:

```
for i in 0..2:
  block:
    let x = i
    if x == 1:
      continue
    echo x
```

```
0
2
```

That is the same rule as `break` in Chapter 6: the innermost loop, not the block. The two keywords differ in
where they send you — `continue` to the next round, `break` out of the loop — not in what they consider the
surrounding construct.

## `while`

`while` tests first, so the body may never run:

```
while false:
  echo "never"
echo "after"
```

```
after
```

Endless loops are no error at the pin (`doc/language.md:1992-2006`). The way out is `break`, which works because
a `while` opens an implicit block. `continue` re-tests the condition rather than skipping it:

```
var i = 0
while i < 5:
  i = i + 1
  if i == 3:
    continue
  echo i
```

```
1
2
4
5
```

The increment sits before `continue`; move it after and the loop stops moving. That is the one `while` mistake
worth naming, because the compiler will not name it for you.

## A `range` parameter: the proof is local

Chapter 4 showed the type and the conversion. In practice a range is usually met at a boundary — a routine that
accepts only digits:

```
proc clamped(x: range[0..9]) =
  echo "digit ", x

proc showDigit(n: int) =
  if n >= 0 and n <= 9:
    clamped(n)
  else:
    echo "not a digit"
```

That compiles and prints `digit 7` for `showDigit(7)`. Remove the `if` and the call is rejected:

```
Error: cannot prove 'n' is in range 0..9
```

(`src/nimony/contracts_fir.nim:2386-2387`.) No runtime check is emitted, in either direction
(`doc/differences.md:58-62`): a value that reaches a `range` parameter is either proven before the call or the
program does not build.

Four details decide whether the proof is accepted.

1. **It must be visible where the value is used.** A caller that guards `n`, then calls a routine that calls
   `clamped` without guarding again, fails at the inner call. The proof does not travel.
2. **Two comparisons work everywhere**, including on a parameter: `n >= 0 and n <= 9`, or `0 <= n and n <= 9`.
3. **`n in 0..9` is not the same proof.** It is accepted for a local or a module-level `var`, but not for a
   procedure parameter, where the same call still fails with `cannot prove 'n' is in range 0..9`. The guide's
   example is written with `in` (`doc/differences.md:64-65`); on a parameter, write the comparisons.
4. **A computed value needs a proof that covers the computation.** The engine follows a constant offset: with
   `n >= 0 and n <= 9` guarded, `clamped(n + 0)` passes, and `clamped(n + 1)` fails with `cannot prove 'n'
   stays in range 0..9` because the guard promised `n <= 9`, not `n <= 8`. Narrow the guard to `n <= 8` and
   `n + 1` passes. The verb changes from "is" to "stays"; the obligation does not.

Assignment to a range variable is a conversion, so the same rule applies from the other side. A literal outside
the bounds is rejected at the declaration (`value out of range: 7 notin 0..4`, `doc/differences.md:63-64`), and a
value of another type is rejected with the proof message:

```
var r: range[0..4] = 3
var n = 7
r = n
# Error: cannot prove 'n' is in range 0..4
```

So the rule for this book: put the guard in the routine that needs the range, write it as two comparisons, and
re-prove a computed value against the bound the guard actually promised.

## Nim 2 delta: the range proof is local

> **What Nim 2 did.** A `range` was defended at runtime when the value reached the type, so a value that was
> correct at the moment of use was accepted however far it had travelled to get there. Checked on the host
> compiler, Nim 2.4.0: assigning `7` to a `var r: range[0..4]` stops with `RangeDefect`, and so does `70` passed
> to a `range[0..9]` parameter.
>
> **What Nimony does.** The obligation `lo <= value <= hi` goes to the contracts engine at compile time and no
> runtime check is emitted (`doc/differences.md:58-62`). Whatever the engine cannot prove is a compile error,
> even when the value is in range when the program runs.
>
> **What breaks if you keep the habit.** The "validate once, pass it on" shape stops compiling: the guard has to
> be visible in the routine where the range type is required. A guard written as `x in a..b` on a parameter does
> not count, so the same lines that read as a check now fail to build. And a computation built from a guarded
> value can outrun the guard: with `n <= 9` guarded, `n + 1` needs `n <= 8`, so the proof has to cover the
> result, not just the value.

## Samples

`samples/07-loops-ranges/loops.nim` — every construct in this chapter, in order, at the pinned commit:

```
$ nimony c -r samples/07-loops-ranges/loops.nim
incl 0
incl 1
incl 2
incl 3
half 0
half 1
half 2
descending count 0
down 3
down 2
down 1
step 0
step 2
step 4
step 6
char a
char b
char c
index 0 a
index 1 b
index 2 c
odd 1
odd 3
odd 5
while 0
while 1
while 2
total 10
digit 7
not a digit
```

`descending count 0` is the point of `3..0`: the loop ran zero times. `total 10` is `1 + 2 + 3 + 4` accumulated
by a `var` outside the loop. The last two lines are the range parameter accepting `7` through the comparison
guard and refusing `70` in the `else`.

## Checks

1. Write `for i in 0..3: echo i`. Expected: `0 1 2 3`, four lines. Change it to `0..<3`. Expected: three lines.
2. Count the rounds of `for i in 3..0`. Expected: `0`. Replace the header with `countdown(3, 1)`. Expected:
   `3 2 1`. Try `3 >.. 0`. Expected: the same.
3. Write `for i in countup(0, 6, 2)`. Expected: `0 2 4 6`. Try `countdown(5, 1, 2)`. Expected: `5 3 1`. Try
   `countup(0, 6, -2)`. Expected: `value out of range: -2 notin 1..9223372036854775807`.
4. Write `for c in 'a'..'c': echo c`. Expected: `a b c`. Change the header to `'c'..'a'`. Expected: nothing.
5. Write `for i in 0..len("abc"): echo "abc"[i]`. Expected: it builds, prints `a`, `b`, `c`, then stops with
   `i < len(s) [AssertionDefect]`, exit 1. Change the header to `0..<len("abc")`. Expected: three lines, exit 0.
6. Write `for i in 0..high(int): echo i`. Expected: `contract violated:` with the `b < …` requirement. Change the
   bound to `high(int) - 1`. Expected: it builds and runs (do not run it to the end).
7. Write the loop-variable example from this chapter. Expected: `0 3 4 5`. Move the write past the bound
   (`for i in 0..2: i = 5; echo i`). Expected: `5` once.
8. Write the `continue` example. Expected: `1 3 5`. Put it inside a bare `block`. Expected: `0 2`.
9. Write the `while` + `continue` example. Expected: `1 2 4 5`. Move the increment after `continue`. Expected: the
   loop stops moving.
10. Write the two-proc range example. Expected: `digit 7` and `not a digit`. Remove the guard. Expected:
    `cannot prove 'n' is in range 0..9`. Replace `n >= 0 and n <= 9` with `n in 0..9`. Expected: the same error.
    Change the call to `clamped(n + 1)`. Expected: `cannot prove 'n' stays in range 0..9`. Change it to
    `clamped(n + 0)`. Expected: it compiles — a zero offset is no computation.

## Chapter checklist

draft 2026-11-12 · tech_review Momo 2026-11-12 · editorial_pass 2026-11-12 · frozen 2026-11-12
