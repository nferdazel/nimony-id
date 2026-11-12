# Chapter 4 — review record

Draft: 2026-11-12, Aksara. Pin: `4ba90a781b0b22d0821efaa153c129c37cef6143` (nimony `0.6.3`).
Technical review: **closed 2026-11-12** — verdicts from Momo are in, applied below. Editorial pass and `id.md`
written in the same sitting; the chapter freezes at this pin.

## Sample verification

Aksara ran the verifier at the pin after writing `numbers.nim`:

```
toolchain /Users/sachiel/.local/opt/nimony/4ba90a7/bin/nimony 0.6.3 pin 4ba90a7
PASS samples/02-pinned-toolchain/hello.nim exit=0
PASS samples/03-values-names-mutability/values.nim exit=0
PASS samples/04-numbers-types-conversion/numbers.nim exit=0
SUMMARY 3/3 passed, 0 failed
```

Exit code `0`. `nimony c -r samples/04-numbers-types-conversion/numbers.nim` prints exactly the list the chapter
states, exit 0:

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

The first line is host-dependent: `sizeof(int)` is `8` on this 64-bit machine.

## Probes behind the draft

Small throwaway programs, run with `nimony c -r` at `4ba90a7`, macOS arm64. Each message quoted in the chapter
appears below exactly as the pin printed it.

| Probe | What it does | Output |
| --- | --- | --- |
| `p1.nim` | `sizeof(int)`, `sizeof(int8)`, `sizeof(float)`, `low`/`high(int8)`, `127'i8 + 1'i8`, `high(int64) + 1` | `8`, `1`, `8`, `-128`, `127`, `-128`, `-9223372036854775808` |
| `p2.nim` | division and conversion | `7 div 2 → 3`, `-7 div 2 → -3`, `7 mod 3 → 1`, `-7 mod 3 → -1`, `7 / 2 → 3.5`, `int(3.9) → 3`, `int(-3.9) → -3`, `float(3) → 3.0`, `3.0 + 1 → 4.0`, `ord('a') → 97`, `chr(97) → a`, `'a' < 'b' → true` |
| `p3.nim` | `type Digit = range[0..9]`, `var d: Digit = 5` | compiles, prints `5` and `ord(d) → 5` |
| `p3b.nim` | `var e: Digit = 10` | `p3b.nim(3, 16) Error: value out of range: 10 notin 0..9`, exit 1 |
| `p4.nim` | `var i = 3`, `var f: float = i` | `p4.nim(3, 16) Error: type mismatch: got: int64 but wanted: float64`, exit 1 |
| `p4b.nim` | `var x = 2.5`, `var n: int = x` | `p4b.nim(3, 14) Error: type mismatch: got: float64 but wanted: int64`, exit 1 |
| `p13.nim` | `var f: float = 3` (literal), then `var i: int = 3.0` | the literal converts; the float literal does not |
| `p5.nim` | `int8(200)`, `uint8(-1)`, `int(3.99)`, `float32(1.5)` | `-56`, `255`, `3`, `1.5` |
| `p6.nim`, `p14.nim` | `x.toInt`, `3.toFloat`, `3.7.toInt` | `Error: undeclared field: 'toInt' for type float64` (and the same for `toFloat`); exit 1 |
| `p7.nim` | `{.keepOverflowFlag.}` around `high(int64) + 1`, `overflowFlag()` | `-9223372036854775808`, `true` |
| `p9.nim` | `int8` of a `var` holding `200`, `6 / 2`, `sizeof(bool)`, `sizeof(char)`, `low`/`high` of a `range[0..255]` | `-56`, `3.0`, `1`, `1`, `0`, `255` |
| `p10.nim` | `Digit(step)` inside `if step >= 0 and step <= 9:` | compiles, prints `0` |
| `p11.nim` | `const X = 127'i8 + 1'i8` | `p11.nim(1, 18) Error: expression overflow at compile time: 127'i8 + 1'i8` |
| `p12.nim` | `uint8` `255 + 1`, `int8` `-128 - 1` | `0`, `127` |
| `p15.nim` | `-7 / 2` | `-3.5` |

## Claims in the draft

| # | Statement in the draft | Evidence | Verdict |
| --- | --- | --- | --- |
| 1 | `int` is as wide as a pointer; `sizeof(int)` is 8 on a 64-bit host | `doc/language.md:62`; probes `p1`; Momo's run printed `8` | PASS |
| 2 | `int8`/`int16`/`int32`/`int64` and the unsigned set are fixed-width, each with a literal suffix | `doc/language.md:63-71`; the sample's suffixed literals compile | PASS |
| 3 | Signed overflow wraps: `127'i8 + 1'i8` is `-128`, `high(int64) + 1` is `low(int64)`, nothing is raised | `doc/language.md:77-83`, `doc/differences.md:24`; probes `p1`, `p12` | PASS |
| 4 | A constant expression that overflows is a compile error: `expression overflow at compile time: 127'i8 + 1'i8` | `src/nimony/expreval.nim:466` (Momo, exact string); probe `p11` | PASS |
| 5 | `{.keepOverflowFlag.}` plus `overflowFlag()` is the way to notice a signed overflow | `doc/language.md:92-104`; probe `p7`, sample prints `true` | PASS |
| 6 | `float` is 64-bit; `float32`/`float64` widen the table; IEEE exceptions are ignored | `doc/language.md:126-142`; `sizeof(float) → 8` in `p1` | PASS |
| 7 | Integers and floats do not convert automatically in either direction, but a numeric literal adapts | `doc/language.md:139-140`, literal rule at `:1106-1108` (Convertible relation from `:1097`); probes `p4`, `p4b`, `p13` | PASS — citation corrected by Momo |
| 8 | `/` yields a float, `div` and `mod` stay integer; `div` truncates toward zero, `mod` takes the dividend's sign | probes `p2`, `p15`; Momo re-ran `-7 div 2 → -3`, `-7 mod 3 → -1`, `-7 / 2 → -3.5` | PASS |
| 9 | Conversion is `T(x)` and float→int truncates: `int(3.9)` is `3`, `int(-3.9)` is `-3` | `doc/language.md:2138-2160`; probe `p2`; sample prints `3`, `-3`, `3.0` | PASS |
| 10 | Narrowing conversion does not check: `int8(200)` prints `-56` | probes `p5`, `p9`; `semConvArg` treats every integral-to-integral conversion as unchecked (`src/nimony/sem.nim:854`); `doc/language.md:2159-2162` covers unsigned only | PASS — cite corrected; signed case added to the prose and `ERRATA.md` |
| 11 | `toInt`/`toFloat` do not exist at the pin, though the guide names them | probes `p6`, `p14`; they exist only for `Rational[T]` (`lib/std/rationals.nim:137,141`) | CORRECTED — wording applied |
| 12 | `bool` is one byte, `ord(false)` is 0 and `ord(true)` is 1, `and`/`or` short-circuit | `doc/language.md:149-172`; `sizeof(bool) → 1` in `p9` and in Momo's run | PASS |
| 13 | `char` is one byte and holds a part of a UTF-8 character; `chr` takes `range[0..255]` | `doc/language.md:175-181`; `lib/std/system.nim:249-251`; probes `p2`, `p9` | PASS — citation corrected |
| 14 | A `range` carries its bounds in the type; the compiler requires proof rather than inserting a runtime check | `doc/language.md:1467`; probes `p3`, `p3b`, `p8`, `p10` | PASS |

## Questions the wording depends on — answered 2026-11-12

**A — narrowing to a signed type.** Intended, not a missing check. `semConvArg` (`src/nimony/sem.nim:854`) treats
every integral-to-integral conversion as unchecked; only a `range` destination creates a proof obligation
(`contracts_fir.checkRangeAssign`), and the pin's own suite depends on the wrap
(`tests/nimony/errmsgs/tconvsignchange.nim:84-88`). The guide's sentence at `doc/language.md:2159-2162` is the
incomplete part, and it is now an `ERRATA.md` doc gap. The chapter keeps the broader rule: test before you narrow.

**B — `toInt` and `toFloat`.** Absent for `float`/`int`, present only for `Rational[T]` (`lib/std/rationals.nim:137,141`).
Not a compiler bug — a Nim idiom the guide still recommends and the pin did not carry over. Recorded in `ERRATA.md`
as a documentation gap, not a report to file. The chapter teaches `T(x)` and states the narrower sentence.

**C — range proof.** Safe as written. A visible guard in the same routine satisfies the prover, including an `int`
parameter; without a visible guard the call fails with `cannot prove 'x' is in range 0..9`. Momo could not
reproduce the Chapter 7 watch-list claim that a parameter guard fails, so that row is rewritten to "the guard does
not travel into another routine", and Chapter 7 must re-probe before it leans on it.

Sample stdout was confirmed independently: Momo ran `numbers.nim` at the pin and got exactly the 21 lines above,
exit 0. The verifier compares compile/run/exit only; the list in the chapter is the check.

## Momo's verdict summary

Thirteen of fourteen PASS as written or with a citation correction; one wording fix applied (#11). Verifier
at `4ba90a7`: `SUMMARY 3/3 passed, 0 failed`, exit 0. Nothing else in the chapter changed on review.

## Definition-of-done state

| Gate | State |
| --- | --- |
| One job | yes — numeric types, overflow, conversion, `bool`/`char`/`range`; no second job |
| Samples run | `numbers.nim` PASS, `SUMMARY 3/3 passed, 0 failed`, exit 0 |
| Technical review | **closed** — Momo 2026-11-12, fourteen verdicts applied |
| Editorial pass | **done 2026-11-12** |
| Both languages | **done** — `id.md` written in the same pass, same frontmatter and section shape |
| Frozen | **yes 2026-11-12** |

## Glossary

Added in this handoff: `integer type`, `floating-point type`, `narrowing conversion`, `wrapping overflow`,
`range type`.
