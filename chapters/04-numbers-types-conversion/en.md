---
chapter: 4
title: Numbers, Types, and Conversion
job: Cover integers, floats, booleans, characters, ranges, and explicit conversion, including the fact that integer overflow wraps instead of raising.
nimony_version: 0.6.3
nimony_commit: 4ba90a781b0b22d0821efaa153c129c37cef6143
toolchain: /Users/sachiel/.local/opt/nimony/4ba90a7
host_compiler: /Users/sachiel/.local/opt/nim-2.4.0
status: frozen
tech_review: Momo 2026-11-12
editorial_pass: 2026-11-12
samples: ["samples/04-numbers-types-conversion/numbers.nim"]
glossary_added: ["integer type", "floating-point type", "narrowing conversion", "wrapping overflow", "range type"]
---

# 4. Numbers, Types, and Conversion

## What this chapter is for

Every value in a Nimony program has exactly one type, and the compiler infers it before you name it. For numbers
that inference decides three things you can feel immediately: how much room the value has, what happens when a
computation needs more room than that, and whether two values of different types may meet in one expression.

This chapter covers the numeric types, the two non-numeric types you will hold in a variable all day — `bool` and
`char` — and the one place where a type is not just a label but a proof: `range`. Conversion gets its own section
because Nimony does comparatively little of it for you.

## The integer types

`int` is the integer you reach for. It is as wide as a pointer on the machine you compile for
(`doc/language.md:59-66`), which on a 64-bit host means `sizeof(int)` is `8` and the range runs from
`low(int)` to `high(int)`. When you need a width the platform cannot change, name it: `int8`, `int16`, `int32`,
`int64`, and the unsigned set `uint`, `uint8`, `uint16`, `uint32`, `uint64` (`doc/language.md:63-71`). The same
table gives each type a literal suffix, so the literal itself can carry the width:

```
let small = 127'i8
let big = 9223372036854775807'i64
let byte = 255'u8
```

One habit from C should be dropped here: `int` is not "32 bits, probably". It is the type whose width matches the
target, and code that needs an exact width says so. The unsigned types exist mostly for the C boundary, which is
Chapter 22; for arithmetic in your own program, `int` is the default.

## What happens when an integer overflows

Signed arithmetic wraps. `doc/language.md:76-90` states the rule at the pin: when the mathematical result of `+`,
`-`, `*` or unary `-` on a signed type `T` does not fit `T`, the result is that value modulo `2^bits` in two's
complement. So `127'i8 + 1'i8` is `-128'i8`, `high(int64) + 1` is `low(int64)`, and there is no error — neither at
compile time nor at runtime.

That is the whole difference from Nim 2, and it is not a configuration: `doc/differences.md:24` records that
signed overflow wraps **instead of** raising `OverflowDefect`, and that the C backend compiles with `-fwrapv` so
the C compiler cannot assume otherwise. Nothing is thrown for you to rescue.

The consequence is simple to state and easy to forget: a number that looks impossible is a defect in your
arithmetic, not a signal from the language. If a value matters, check the bound before the operation, or ask for
the flag. `{.keepOverflowFlag.}` keeps the CPU flag alive around a block and `overflowFlag()` reports whether the
last signed `+`, `-` or `*` inside it overflowed (`doc/language.md:92-104`):

```
var top = 9223372036854775807'i64
var wrapped: int64
var overflowed = false
{.keepOverflowFlag.}:
  wrapped = top + 1'i64
  overflowed = overflowFlag()
# wrapped is -9223372036854775808, overflowed is true
```

Constant expressions are the exception, and it is a compile error rather than a wrap. `const X = 127'i8 + 1'i8`
stops the build with `Error: expression overflow at compile time: 127'i8 + 1'i8` (`doc/language.md:98-104`, string
at `src/nimony/expreval.nim:466`), because a constant that cannot hold its own value is a mistake in the source,
not a runtime condition.

## Two number families that do not mix

`float` is the generic floating-point type and it is 64 bits wide; `float32` and `float64` are spelled out when the
width matters (`doc/language.md:126-140`). Both follow IEEE 754, and the IEEE exceptions — invalid, division by
zero, overflow, underflow, inexact — are ignored during execution (`doc/language.md:142`).

Integers and floats do not convert into each other on their own. `doc/language.md:139-140` says it plainly:
"Integer types are not converted to floating-point types automatically and vice versa." What the compiler will do
is admit a literal, because a numeric literal has no type until the context gives it one (`doc/language.md:1106-1108`;
the Convertible relation it bypasses starts at `:1097`):

```
var good: float = 3        # fine: the literal becomes 3.0
var i = 3
var bad: float = i         # Error: type mismatch: got: int64 but wanted: float64
```

The same asymmetry runs the other way: `var n: int = 3.0` is rejected with `type mismatch: got: float64 but
wanted: int64`. A literal adapts to the type you asked for; a value does not.

Division follows the two families. `/` always produces a float, even when both operands are integers, while `div`
and `mod` stay in the integer type:

```
echo 7 div 2      # 3
echo 7 mod 2      # 1
echo 6 / 2        # 3.0
```

`div` truncates toward zero, so `-7 div 2` is `-3`, not `-4`. `mod` takes the sign of the dividend:
`-7 mod 3` is `-1`. Neither operator is interchangeable with `/`, and writing `7 / 2` where you meant `3` is the
quiet way to end up teaching the next chapter with floats.

## Explicit conversion

A conversion is spelled as a call on the type name (`doc/language.md:2138-2160`):

```
echo int(3.9)      # 3
echo int(-3.9)     # -3
echo float(3)      # 3.0
```

Float to integer truncates toward zero — `int(-3.9)` is `-3`, not `-4` — so rounding is your decision, not the
conversion's. Conversion is also how you narrow, and narrowing does not check anything: `int8(200)` compiles and
prints `-56`. `doc/language.md:2159-2162` explains the policy for unsigned targets, where conversions are unchecked
by design for C interoperability; at the pin the same silence applies to signed narrowing, and the pin's test suite
relies on it — `int8(wb)` is `-56` (`tests/nimony/errmsgs/tconvsignchange.nim:84-88`). If the value might not fit,
test it before you convert it.

Do not reach for `toInt` or `toFloat` here. `doc/language.md:2144-2148` mentions them as the Nim idiom, but at
`4ba90a7` they exist only for `Rational[T]` (`lib/std/rationals.nim:137,141`), not for `float` or `int` —
`3.7.toInt` fails with `undeclared field: 'toInt' for type float64`. The conversion form is the one that exists.

## Booleans and characters

`bool` holds `true` and `false` and is one byte (`doc/language.md:149-172`). Its ordinal values are fixed:
`ord(false)` is `0` and `ord(true)` is `1`, and the usual operators `not`, `and`, `or`, `xor` and the comparisons
are defined on it. `and` and `or` short-circuit, which is why `p != nil and p.next != nil` is safe to write.

`char` is one byte as well, and that byte is a *part* of a UTF-8 character, not a character
(`doc/language.md:175-181`). Anything outside ASCII will not fit one `char`. The two functions you need are
`ord`, which turns a `char` into its numeric value, and `chr`, which turns a number in `0..255` back into a
`char` (`lib/std/system.nim:249-251`):

```
echo ord('a')     # 97
echo chr(97)      # a
echo 'a' < 'b'    # true
```

Comparison works because `char` is ordinal: `'a' < 'b'` is true for the same reason `97 < 98` is.

## Ranges

A range is a type whose bounds are part of the type: `range[0..9]` is not an `int` that happens to be small, it is
a type whose values are the ten integers from `0` to `9`. You declare one with a name and use it like any other
type:

```
type Digit = range[0..9]
var five: Digit = 5
echo ord(five)     # 5
```

The compiler enforces the bound, and it does so by proof rather than by a runtime check. A literal outside the
range is rejected at the declaration with `Error: value out of range: 10 notin 0..9`. A value of another type
needs to be proven inside the bound before the conversion is accepted:

```
var step = 10
var d: Digit = Digit(step)
# Error: cannot prove 'step' is in range 0..9
```

Wrap the conversion in a guard and it compiles — the prover accepts a check it can see:

```
if step >= 0 and step <= 9:
  d = Digit(step)
```

Chapter 7 uses ranges in loops; here the point is only that a range moves a fact you would otherwise test at
runtime into the type, and the compiler will not let you skip the proof.

## Nim 2 delta: overflow wraps

> **What Nim 2 did.** Signed overflow raised `OverflowDefect` when overflow checks were on, which in practice meant
> that a debug build crashed where a release build wrapped — the same source behaving two ways. The standard rescue
> was to catch the defect or to push `overflowChecks: off`.
>
> **What Nimony does.** Signed overflow wraps, always, and the C backend is compiled with `-fwrapv` so nothing
> downstream may assume otherwise (`doc/differences.md:24`, `doc/language.md:76-90`). The explicit way to notice an
> overflow is `{.keepOverflowFlag.}` with `overflowFlag()`; a constant expression that overflows is a compile error
> instead.
>
> **What breaks if you keep the habit.** A `try`/`except OverflowDefect` around arithmetic is dead code that still
> compiles, so a wrapped number travels on and fails somewhere else — as a wrong index, a negative length, a
> silently wrong total. And arithmetic written to depend on a debug build raising is now simply arithmetic that
> wraps.

## Samples

- `samples/04-numbers-types-conversion/numbers.nim` — one program that prints the width of `int`, wraps a signed and
  an unsigned value at their bounds, reads the overflow flag, divides with `div`, `mod` and `/`, converts in both
  directions including a narrowing that wraps, exercises `bool` and `char`, and uses a `range` type. Proven by
  `tools/verify-samples.sh`:

  ```
  PASS samples/04-numbers-types-conversion/numbers.nim exit=0
  ```

  Expected output, in order — the verifier checks compile, run and exit code, not stdout, so this list is the
  check:

  ```
  8
  -128
  127
  -128
  0
  -9223372036854775808
  true
  3
  1
  3.5
  3
  -3
  3.0
  -56
  1
  1
  97
  a
  true
  5
  5
  ```

  `8` for `sizeof(int)` is this 64-bit host; on a 32-bit target the same line prints `4`.

## Checks

1. Print `sizeof(int)`, `low(int8)` and `high(int8)`. Expected: `8`, `-128`, `127` on this host; the first number
   changes with the target, the other two never do.
2. Set `var edge: int8 = 127` and add `1'i8`. Expected: it compiles and prints `-128`. Then write the same sum as a
   `const`. Expected: `expression overflow at compile time: 127'i8 + 1'i8`.
3. Print `7 div 2`, `7 mod 2` and `7 / 2`. Expected: `3`, `1`, `3.5`. Change the first number to `-7`. Expected:
   `-3`, `-1`, `-3.5`.
4. Declare `var i = 3` and then `var f: float = i`. Expected: `type mismatch: got: int64 but wanted: float64`.
   Replace `i` with the literal `3`. Expected: it compiles and prints `3.0`.
5. Declare `type Digit = range[0..9]` and assign the literal `10`. Expected: `value out of range: 10 notin 0..9`.
   Pass a `var` holding `10` through `Digit(...)`. Expected: `cannot prove 'step' is in range 0..9`. Guard the
   conversion with `if step >= 0 and step <= 9:` and build again — expected, it compiles.
6. Convert `200` to `int8` and print it. Expected: `-56`. Convert `-3.9` to `int`. Expected: `-3`, because the
   conversion truncates toward zero rather than rounding.

## Chapter checklist

draft 2026-11-12 · tech_review Momo 2026-11-12 · editorial_pass 2026-11-12 · frozen 2026-11-12
