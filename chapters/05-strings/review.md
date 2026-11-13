# Chapter 5 — review record

Draft: 2026-11-12, Aksara. Pin: `4ba90a781b0b22d0821efaa153c129c37cef6143` (nimony `0.6.3`).
Technical review: **complete** — Momo, 2026-11-12. All 18 claims hold at the pin; four needed a citation or
quote fix, one needed a clause added because the pin ships a rune iterator, and none was wrong about behaviour.
Corrections applied in the same handoff that wrote `id.md`: citations on #5, #9, #10, #11; the source excerpt
on #12 restored verbatim; the rune sentence added to "Characters are bytes"; one `ERRATA.md` row for the `$` on
`cstring` documentation gap. The draft header's "thirteen claims probed, four documented only" was Momo's catch
and is fixed by removing that count: seventeen claims were probed by the editor and one (#17) is documented only.

## Sample verification

Aksara ran the verifier at the pin after writing `strings.nim`:

```
toolchain ~/.local/opt/nimony/4ba90a7/bin/nimony 0.6.3 pin 4ba90a7
PASS samples/02-pinned-toolchain/hello.nim exit=0
PASS samples/03-values-names-mutability/values.nim exit=0
PASS samples/04-numbers-types-conversion/numbers.nim exit=0
PASS samples/05-strings/strings.nim exit=0
SUMMARY 4/4 passed, 0 failed
```

Exit code `0`. `nimony c -r samples/05-strings/strings.nim` prints exactly the 28 lines the chapter states, exit
`0`:

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

Line 12 is `a`, a tab, `b`. Line 25 (`7`) is `strlen` stopping at the zero `toCString` wrote; line 18 (`195`)
is the first byte of `é` in a six-byte string. The verifier does not compare stdout, so these are worth
confirming independently.

## Probes behind the draft

Small throwaway programs, run with `nimony c -r` at `4ba90a7`, macOS arm64. Each message quoted in the chapter
appears below exactly as the pin printed it.

| Probe | What it does | Output |
| --- | --- | --- |
| `p1.nim` | `len`, `[0]`, `ord([0])`, `[^1]`, `[0..2]`, `[0..<3]`, `[1..^2]` on `"hello"` | `5`, `h`, `104`, `o`, `hel`, `hel`, `ell` |
| `p2.nim` | `let s = "hello"`, `echo s[5]` (constant index) | compiles, then `lib/std/system/stringimpl.nim(686, 37): i < len(s) [AssertionDefect]`, exit 1 |
| `p2b.nim` | same with `var i = 5; echo s[i]` | same AssertionDefect, exit 1 |
| `p3.nim` | `&`, `add`, `==`, `<`, `>`, string `case` | `leftright`, `xy`, `true`, `true`, `false`, `matched left` |
| `p4.nim` | `$cstring"hello"` **without** `strutils` | type mismatch listing every `$` overload; not applicable to `cstring not nil`, exit 1 |
| `p4b.nim` | `var s = "hello"; var c: cstring = cstring(s)` | `Error: Only string literals can be converted to cstring. Use `toCString` for safe conversion.` |
| `p4c.nim` | `toCString(s)`, `c[0]`, `c[4]`, `len(c)` | `h`, `o`, `5` |
| `p6.nim` | `toCString`, `ord(c[s.len])`, `fromCString`, `len(cstring"world")` | `5`, `0`, `hello`, `5`, `world` |
| `p5.nim` | escapes `\t \n \\ \"`, `\x41\x42`, raw `r"a\tb"`, triple-quoted | `a<TAB>b` newline `c\d"e`; `AB`; `a\tb`; the triple-quoted block, first newline dropped |
| `p7.nim` | `"a"` copied then `add`; `m[0] = 'H'`; `$'z'` **without** `strutils` | copy does not touch the original; `Hello`; `$('z')` type mismatch, exit 1 |
| `p9.nim` | `"" & 'q'`, `len("héllo")`, `hi[1]`, `ord(hi[1])`, `$` on a string | `q`, `6`, a broken byte, `195`, `hello`, `z!` |
| `p10.nim` | `split`, `find` (hit and miss), `startsWith`, `endsWith`, `toUpperAscii`, `toLowerAscii`, `strip`, `replace`, `repeat`, `contains` | `3`, `alpha`, `gamma`, `6`, `-1`, `true`, `true`, `ALPHA,BETA,GAMMA`, `alpha,beta,gamma`, `pad`, `a+b+c`, `ababab`, `true` |
| `p11.nim` | `t[0..1] = "HE"`, `t.insert(...)`, `t.delete(0,1)` | `t[0 .. 1] = "HE"` → type mismatch (`string` against array/seq/ptr candidates); `insert` → `undeclared identifier: 'insert'`; `delete` → only the `seq` overload, type mismatch |
| `q1.nim` | `for ch in s`, `s.len`, `len(s)`, `setLen(3)` | `a`, `b`, `c`, `5`, `5`, `hel`, `3` |
| `q2.nim` | `case cstring"hi"` | `yes` |
| `q3/q6.nim` | `$cstring"hello"` **with** `strutils` | `hello`, `5`, `hello` (`fromCString`) |
| `q4.nim` | `echo cstring"hello"` **with** `strutils` | no matching overload in `syncio.nim`, exit 1 |
| `q5.nim` | string passed by value and by `var`; `const greeting`; `<=`, `>=` | `nimon!` then unchanged `nimon`; `hey?` mutated; `hi there`, `8`, `true`, `true` |
| `q7.nim` | `"abc"[0..^1]`, `"abc"[2..1]`, `"abc"[0..<0]` | `abc`, empty, empty |
| `q8.nim` | `"n=" & 42` | `expected: char but got: int64` (`stringimpl.nim:1062`), exit 1 |
| `q9.nim` | `join`, `add 'c'`, `add "de"`, `let` then `add` | `a-b-c`, `abcde`, then `cannot pass frozen to var/out T parameter` |
| `q10.nim` | `"abc"[0..5]` | `abc` (clamped) |
| `q11.nim` | `var i = 5; s[0..i]` | `abc` (clamped) |
| `q12.nim` | `join`, `add`, `w[0] = 'H'`, module-level `var zero: string`, `"abc"[3..5]`, `"abc"[1..1]` | `a-b-c`, `abcde`, `Hello`, `0`, `true`, empty, `b` |
| `q13/q14.nim` | `cstring(varString)` and `toCString(letString)` | `Only string literals…`; `cannot pass s to var/out T parameter` |
| `q15/q16.nim` | `$42`, `"ABC" < "abc"`, `$'z'` with `strutils` | `42`, `true`, `z` |
| `q17.nim` | `"clamped"[0..20]` on a literal | `clamped` |
| `q20.nim` | `setLen(6)` on a 3-char string; `let parts: seq[string] = …split` | `6`, `0`, `2` |
| `q21.nim` | `let s = "hello"; echo s[5]` under default, `-d:release`, `-d:danger` | default and `-d:release`: `i < len(s) [AssertionDefect]`, exit 1; `-d:danger`: a stray byte, then `survived`, exit 0 |

## Claims in the draft

| # | Statement in the draft | Evidence | Verdict |
| --- | --- | --- | --- |
| 1 | Every string literal is a `string`, and `len` is builtin | `doc/language.md:280-283`; probes `p1`, `q1` | PASS |
| 2 | Strings are value types; assignment copies the payload | `doc/language.md:284`; probes `p7`, `q5` (a copy grows, the original does not) | PASS |
| 3 | `&` concatenates; `add` appends in place and needs a `var` | `doc/language.md:303`; probes `p3`, `q9` (`let` → `cannot pass frozen to var/out T parameter`) | PASS |
| 4 | `&` takes a `char` on either side, so `"" & c` makes a one-character string; there is no implicit string conversion | `lib/std/system/stringimpl.nim:1062-1063`; probes `p9`, `q8`, `q15` | PASS |
| 5 | Lower bound is 0, `s[i]` yields a `char`, `s[^1]` is the last character | `doc/language.md:292-296`; probe `p1` | CORRECT — cite: use `doc/language.md:287-288` (indexing, lower bound 0) and `:299-300` (`s[i]` is the i-th char); `:292-296` is the `case` example |
| 6 | Indexing is checked by the contract `i < len(s) and i >= 0`, so `s[len]` is a **runtime** `AssertionDefect` (`stringimpl.nim(686, 37)`), never a compile error and never a read of a zero. The check survives `-d:release` and is removed by `-d:danger` | `lib/std/system/stringimpl.nim:686`; probes `p2`, `p2b`, `q21` (three flag sets); `nimony --help` on `-d:danger` | PASS |
| 7 | A slice returns a **new** string, clamps both bounds, and yields `""` for an empty range | `lib/std/system.nim:649-652` → `substr`; `lib/std/system/stringimpl.nim:706-717`; probes `p1`, `q7`, `q10`, `q11`, `q17` | PASS |
| 8 | There is no slice assignment; a single character may be written through `[]=` on a `var` | probe `p11` (slice assignment fails against every candidate), `q12` (`w[0] = 'H'` → `Hello`) | PASS |
| 9 | Comparison is lexicographic over bytes and every comparison operator is available; `"ABC" < "abc"` is `true` | `doc/language.md:286-288`; probes `p3`, `q15` | PASS — cite tightened to `doc/language.md:286-287` |
| 10 | A `case` may match string literals directly | `doc/language.md:289-296`; probe `p3` | CORRECT — cite: the block is `doc/language.md:288` (intro) plus `:290-295` |
| 11 | Strings are UTF-8 by convention, not enforcement; `s[i]` is a byte, so `len("héllo")` is 6 and `ord(s[1])` is 195 | `doc/language.md:297-301`; probe `p9` (and the sample's `6`, `195`) | CORRECT — cite: `doc/language.md:297-300` (301 is blank) |
| 12 | A `string` carries no null terminator; `toCString` writes one via `ensureTerminatingZero`, which is why it takes `var string` and why a `let` is refused | `doc/differences.md:15-18`; `lib/std/system/stringimpl.nim:1095-1106`; probes `q13`, `q14` | CORRECT — quote: behaviour confirmed (`doc/differences.md:15`, `stringimpl.nim:1095-1106`), but the excerpt dropped the comment's last two lines and `toCString`'s own doc comment; both restored verbatim |
| 13 | `cstring(s)` converts only from a literal, with the exact message naming `toCString` | `src/nimony/sem.nim:880`; probe `p4b` | PASS |
| 14 | `fromCString` copies back; `$` for `cstring` lives in `strutils` (`:230`), and `echo` has no `cstring` overload, so printing needs `echo $c` | `lib/std/system/stringimpl.nim:1108-1109`; `lib/std/strutils.nim:230`; probes `p4` (fails without the import), `q3`/`q6` (works with it), `q4` (`echo c` still fails) | PASS |
| 15 | `len` on a `cstring` calls `strlen`, so its cost depends on content; a `cstring` works in a `case` | `lib/std/system/stringimpl.nim:377`, `:369-375`; `doc/language.md:341`; probes `p4c`, `q2` | PASS |
| 16 | `string` has no `insert`, no `delete` and no slice assignment at the pin; `setLen` grows with zero bytes rather than splicing | probes `p11`, `q20` | PASS |
| 17 | No bounds checking is performed on a `cstring` index (**documented only, not probed**) | `doc/language.md:312-314` | PASS as documented — the guide's statement, no probe |
| 18 | `$` for `char` also lives in `strutils` (`:240`), so `$c` fails without the import | `lib/std/strutils.nim:240`; probes `p7` (fails), `q16` (works with the import) | PASS |

## Questions the wording depends on

**A. Is the "no terminator" claim true of the conversion path, or only of the literal path?** My evidence is
`toCString` calling `ensureTerminatingZero` before casting `rawData`
(`lib/std/system/stringimpl.nim:1103-1106`), plus `cstring(s)` being refused for anything but a literal
(`src/nimony/sem.nim:880`). I read that as: the buffer past `len` is not guaranteed to hold a zero, and the zero
exists only after someone writes it. Confirm from source, or tell me the sentence to cut.

> **Ruled 2026-11-12 (Momo):** confirmed on both paths, nothing cut. `doc/differences.md:15` states it, and the
> literal case has a different reason than a hidden zero in `string`: `cstring"hi"` compiles to the C literal
> `((NC8*)"hi")`, which the C compiler terminates. The sentence stands.

**B. Index checks under release flags — answered by my own run, not by a verdict.** I probed `s[5]` three ways
at the pin: default and `-d:release` both stop with `i < len(s) [AssertionDefect]`; `-d:danger` prints a stray
byte and continues, which matches `nimony --help` ("`-d:danger` … turns every runtime check off"). The chapter
now says exactly that. If Engineering reads the flag semantics differently, the sentence changes.

> **Ruled 2026-11-12 (Momo):** re-run and identical — default and `-d:release` exit 1 with
> `i < len(s) [AssertionDefect]`, `-d:danger` prints a stray byte and exits 0. No change.

**C. `doc/language.md:316-317` says "A `$` proc is defined for cstrings that returns a string".** At the pin that
`$` is in `lib/std/strutils.nim:230`, not in `system`, so it is real but import-dependent. Is that a doc gap worth
an `ERRATA.md` row (Chapter 5), or is "defined somewhere in the stdlib" a fair reading of the sentence?

> **Ruled 2026-11-12 (Momo):** real and import-dependent — a genuine documentation gap. `ERRATA.md` row added
> for Chapter 5; the chapter names `std/strutils` explicitly, including for `$` on `char` (`:240`).

**D. Byte indexing is not enforced anywhere.** I teach "indexing is bytes, not characters" from
`doc/language.md:297-301` plus a probe. Is there any rune/unicode iterator at the pin that a reader would be
expected to use instead? I found none and teach none.

> **Ruled 2026-11-12 (Momo):** wrong about absence — the pin ships them. `lib/std/unicode.nim:1467`
> `iterator runes*(s: string): Rune`, plus `utf8*` at `:1472`; over `"héllo"` the iterator prints
> `104, 233, 108, 108, 111` and `runeLen` returns `5`. The chapter now names `std/unicode`, `runes` and
> `runeLen` at `:1467` instead of leaving decoding unnamed.

**E. `setLen` growth.** `setLen(6)` on `"hel"` gives length 6 with a zero byte at index 5 (probe `q20`). I read
that as raw storage, not a terminator, and teach it only as "grow or shrink, not splice". Confirm that reading.

> **Ruled 2026-11-12 (Momo):** confirmed — growth zeroes the new tail with `zeroMem`
> (`lib/std/system/stringimpl.nim:661-662`), `len` reports the length, and nothing guarantees a zero past the
> payload. "Grow or shrink, not splice" is the correct teaching.

Also confirm the sample's 28-line stdout above; the verifier checks exit code only.

> **Confirmed 2026-11-12 (Momo):** the pin prints the 28 lines in order, `diff` against the chapter block empty,
> exit 0.

## Definition-of-done state

| Gate | State |
| --- | --- |
| 1. One job | done — the chapter does the outline's job and hands `seq[string]` detail to Chapter 10, nilability to Chapter 13, C binding to Chapter 22 |
| 2. Samples run | done — `SUMMARY 4/4 passed, 0 failed`, exit 0 |
| 3. Technical review | **done** — Momo, 2026-11-12: 18/18 hold, four citation/quote fixes applied, one rune clause added, no behaviour change |
| 4. Editorial pass | **done** — glossary updated in this handoff (`string`, `null terminator`, `cstring`, `slice`, `escape sequence`, `raw string`, `concatenation`); delta box present |
| 5. Both languages | **done** — `id.md` written in the same pass as the corrections, same frontmatter, same section order |
| 6. Frozen means frozen | **frozen 2026-11-12** — later breaks go to `ERRATA.md` |

## Glossary

Added in this handoff: `string`, `null terminator`, `cstring`, `slice`, `escape sequence`, `raw string`,
`concatenation` — all seven carry a pin-level source in `GLOSSARY.md`.
