# Chapter 22 review note — The C Boundary

Status: `drafting`. Reviewer: **Momo**. This note is the claim table, the open questions and the errata
candidates. Append your verdict at end of file; do not edit the table rows in place.

Pin for every run below: `4ba90a781b0b22d0821efaa153c129c37cef6143` (nimony 0.6.3), install
`~/.local/opt/nimony/4ba90a7`. Probe sources: `ch22-probes/` in the authoring workspace
(`~/.openmausbot/workspaces/be336972-1e63-4f00-9916-c76cc8e33654/ch22-probes`), one directory per
probe, each run as `~/.local/opt/nimony/4ba90a7/bin/nimony c -r main.nim` from inside the probe directory. Host
comparison (`nim2/n1`) was compiled with `~/.local/opt/nim-2.4.0/bin/nim c -r --hints:off`. The machine is macOS
arm64; anything that depends on the platform says so in the row.

Verifier already run by the editor, from the authoring folder:

```
toolchain ~/.local/opt/nimony/4ba90a7/bin/nimony 0.6.3 pin 4ba90a7
PASS samples/22-cinterop/cinterop.nim exit=0
SUMMARY 21/21 passed, 0 failed
```

Sample output, byte-identical to the block in `en.md` section Samples (11 lines):

```
5
hello
4 3
3 1
xxx true
4 8
true
Hello
3 1
3
true
```

## Claims

| # | Section | Claim as written | Probe | Raw output | Source |
| --- | --- | --- | --- | --- | --- |
| 1 | chapter frame | An `importc` declaration is a promise, not a check: the compiler analyses no body for an extern proc | source read | — | `src/nimony/contracts_fir.nim:6036-6041` ("Extern (importc/importcpp) procs satisfy their contract at the C level and have no meaningful Nim body") |
| 2 | Declaring | `{.importc, header.}` compiles; `strlen(cstring"hello")` is `5` | `a01` | `5` | `src/nimony/sempragmas.nim:346` |
| 3 | Declaring | The header is what makes the C compiler see the prototype | `a01` vs `p02` | `p02` printed `4` with no header | `src/nimony/sempragmas.nim:346`, `:365-368` |
| 4 | Declaring | Without `header` the call still linked, on a symbol libc already declares | `p02` | `4` | `src/nimony/sempragmas.nim:353-356` (a bare `importc` takes the Nimony name) |
| 5 | Declaring | The C name defaults to the Nimony identifier unless the pragma carries a string | `p02` | declared `cstrlen`, symbol is `strlen`, printed `4` | `src/nimony/sempragmas.nim:350-356` |
| 6 | Declaring | `dynlib` takes the platform's library name, not a portable one | `p03`, `p08` | `p03`: `could not load: libm.so.6` then `FAILURE`; `p08` (`libm.dylib`): `1.0` | `src/nimony/sempragmas.nim:346` (`DynlibP`) |
| 7 | Declaring | `{.varargs.}` passes the trailing arguments through | `p04` | `hi 42\n` on one line | `src/nimony/semcompat.nim:36-78` |
| 8 | Declaring | A generalized string literal after `cstring` is raw: `\n` is two characters | `p17` | `strlen(cstring"a\nb")` → `4`; `"a\nb".len` → `3` | `src/nifler2/nimlexer.nim:1061-1064` (identifier before the quote ⇒ `smGeneralized`), `:829` (escapes only when `smNormal`); `src/nifler2/nimgrammar.nim:271` (`callstrlit cstring … "R"`) |
| 9 | Declaring | A function-like C macro can be declared as a routine when its header is included | `p13` | `isdigit(51)` → `1` | probe; no symbol is emitted, the C compiler expands the macro |
| 10 | Declaring | A non-callable C expression in `importc` is emitted as a call and refused | `p30` | `sizeof(struct stat)()` → `expression cannot be followed by a postfix '(' operator` | generated C in `p30/nimcache` |
| 11 | Types | The C-width aliases arrive with `system`; `cint` is `int32` and `csize_t` is `uint` | source read, `p15` | `sizeof(cint)` → `4` | `lib/std/system/ctypes.nim:34-45`, included at `lib/std/system.nim:160` |
| 12 | Types | `sizeof` is `4` for `cint`, `8` for `cdouble`, `8` for `pointer`, `8` for `csize_t` (macOS arm64) | `p15` | `4 8 8 8` | probe; platform-dependent for `pointer` |
| 13 | Types | A literal converts to `csize_t` on its own; a computed `int` needs the conversion written | `p22`, `p11` | `p22` passes `3`; `p11` needs `csize_t(sizeof(cint))` | probe |
| 14 | Types | `array[4, char]` plus `addr buf[0]` is a C buffer; `memset` fills three bytes and the fourth stays zero | `p22` | `xxx true` | probe |
| 15 | Types | A small C struct comes back by value and is read field by field | `p14` | `3 1` | probe; generated C calls `div(...)` |
| 16 | Types | An output parameter maps to a pointer: `stat` filled `Stat` through `ptr Stat` | `p18` | `0` then `true` | probe; generated C has `struct stat` and `stat("main.nim", (&st))` |
| 17 | Types | `out Stat` is the same pointer; the manual's `stat` example works at the pin | `p41` | `0` then `true`; C: `stat("main.nim", (&st_0…))` | `doc/language.md:2771-2778` |
| 18 | Types | `sizeof` of an importc object asks C, so a partial field list still reports the C size | `p34` | `144 144` (Nimony and a C helper agree) | `src/lengc/genexprs.nim:527-533` writes `sizeof(type)`; generated C: `sizeof(struct stat)` |
| 19 | Types | `sizeof(DivT)` is `8` | `p38` | `8` | probe; same lowering |
| 20 | String | `toCString(var string)` is a writable view, not a copy | `p25` | `Hello Hello` after `c[0] = 'H'` | probe |
| 21 | String | `toCString` on a `let` is refused | `p32` | `cannot pass s to var/out T parameter` | probe |
| 22 | String | `cstring(x)` on anything but a literal is refused with the `toCString` message | `p10` | `Only string literals can be converted to cstring. Use` |
| 23 | String | `$` for `cstring` comes from `std/strutils`, not `system` | `p09` vs `p16` | `p09` (no import): `$` fails against every candidate; `p16` (with `strutils`): `hello` and `5` | `lib/std/strutils.nim:230` |
| 24 | String | `echo cstringValue` is refused by the nine `write` overloads | `p07` | type mismatch listing nine candidates, `cstring not nil does not match constraint T` | `lib/std/syncio.nim:293-331`, echo at `:465-469` |
| 25 | String | The two string models disagree at the first zero byte, silently | `p24` | `3 1` | probe |
| 26 | String | `cstring` indexing reads bytes and the terminator | `p23` | `hitrue` (`c[0]`,`c[1]`,`c[2] == '\0'` → `true`) | `lib/std/system.nim:29` |
| 27 | String | `cast[cstring](addr buf[0])` gives a `cstring` from a stack buffer | `p29` | `3` | probe |
| 28 | Null | `ptr`, `pointer` and `cstring` are non-null unless the type is written `nil T` | source read | `p06` first attempt: `expected non-nil value` | `doc/language.md:785`, `:851`; `src/nimony/contracts.nim:280` |
| 29 | Null | `getenv` declared `nil cstring` answers `isNil` for an unset name | `p20` | `true` | probe |
| 30 | Null | A set name gives `isNil` false and a value | `p21` | `false true` | probe |
| 31 | Null | Declaring the same return as plain `cstring` compiles, and `isNil` is still true — no runtime check | `p33` | `true` | probe; `contracts.nim:280` is a compile-time check only |
| 32 | Null | A bare `nil` for a `pointer` parameter is `expected non-nil value` | `p06` (first run) | `main.nim(8, 31) Error: expected non-nil value` | `src/nimony/contracts.nim:280` |
| 33 | Null | A `nil pointer` parameter accepts `nil` | `p06` (rerun) | `true` | probe |
| 34 | Null | `array[2, cstring]` refuses a `nil` element | `p31` (first run) | `expected non-nil value` | probe |
| 35 | Null | With `nil cstring` elements, an in-place `slots[0] != nil` check is refused | `p31` (second run) | `cannot analyze expression is not nil: argv[0]` (same for `slots[0]`) | `src/nimony/contracts.nim:293` |
| 36 | Null | Copying the element into a local `nil cstring` makes the check work | `p35` | `3` then `true` | probe |
| 37 | Null | `cast[cstring](slots[0])` bypasses the check | `p36` | `3` | probe |
| 38 | Calling back | `{.exportc.}` puts the C name on the routine and the symbol is in the binary | `p26` | `5`; `nm … \| grep book_add` → `_book_add` | probe; underscore is the platform's C prefix |
| 39 | Calling back | `{.cdecl.}` lands as `N_CDECL(...)` and expands to nothing on this platform | `p26` generated C | `N_CDECL(int, book_add)(int a_0, int b_0)`; `# define N_CDECL(rettype, name) rettype name` | `p26/nimcache/c/…/comwsgwbr1.c:249` |
| 40 | Calling back | `{.compile.}` adds a C file resolved relative to the source, from any working directory | `p27` run twice | `42` from the probe directory and from the authoring workspace root | probe |
| 41 | Calling back | C can call an exported Nimony proc | `p28` | `42` | probe |
| 42 | Calling back | A `{.cdecl.}` callback with `pointer` parameters is emitted without `const`, and clang refuses it for `qsort` | `p05` | `incompatible function pointer types passing 'int (void *, void *)' to parameter of type 'int (* _Nonnull)(const void *, const void *)'` | generated C in `p05/nimcache` |
| 43 | Calling back | Declaring the parameter as `pointer` and casting the proc gives a working `qsort` | `p11` | `123` | probe |
| 44 | Calling back | An unknown pragma is an undeclared identifier, not free text | `p39` | `undeclared identifier: 'boguspragma'`, then `undeclared identifier: 'f'` | probe |
| 45 | Unchecked | Effect tags on an `importc` proc are not verified against the C body | source read | — | `src/nimony/contracts_fir.nim:6036-6041` |
| 46 | Unchecked | A C global is a binding to C storage, not a copy | `p12` | write `7`, read `7` | `src/nimony/contracts_fir.nim:5791-5795` |
| 47 | Unchecked | After a failing `open`, the declared `errno` reads `2` — the real one | `p37` | `-1 2` | probe |
| 48 | Nim 2 delta | Nim 2.4.0 converts a `var string` with `cstring(s)` and `$` works without `strutils` | `nim2/n1` | `hello` | host run |

## Questions

**A. Raw `cstring` literals.** `cstring"a\nb"` is lexed as a generalized string literal and never sees the escape
pass (`nimlexer.nim:1061-1064`, `:829`), so it is four bytes where `"a\nb"` is three (`p17`). Is that intended
for all `cstring` literals, or a consequence of the `callstrlit` path that nobody has decided? The chapter states
it as a rule and shows the two lengths side by side. Doc section `doc/language.md:306-341` never mentions it.

**B. The nil check on an array element.** With `array[2, nil cstring]`, `slots[0] != nil` is
`cannot analyze expression is not nil: slots[0]` (`contracts.nim:293`), while copying to a local `nil cstring`
makes it work (`p35`). Is the in-place form meant to be supported, or is the copy the intended idiom? The chapter
teaches the copy and mentions the cast as the escape hatch (`p36`).

**C. The callback's missing `const`.** A `{.cdecl.}` proc with `pointer` parameters is emitted as
`int (void *, void *)`; `qsort` wants `int (*)(const void *, const void *)`, and clang refuses the direct pass
(`p05`). Casting through `pointer` works (`p11`). Is `const` mapping on the roadmap, or is the cast the documented
route? Note the platform split: the refusal was measured with clang on macOS; the book's verifier runs gcc on
Linux, where the direct form was not measured. The sample avoids a callback for that reason.

**D. `importc` on an expression.** `{.importc: "sizeof(struct stat)".}` produced `sizeof(struct stat)()`
(`p30`). Is only a symbol name supported by design, so that the chapter should say "a name, never an expression"?

**E. A non-null declaration over a null C return.** Declaring `getenv` as returning plain `cstring` compiles,
and `isNil` on the result is `true` (`p33`): the type system's promise is false and nothing checks it. Intended —
nilability is a promise at the FFI — or a hole worth a diagnostic when an `importc` return is used as non-null?

**F. `{.compile.}` plus `{.exportc.}` round trip.** A C file added with `{.compile.}` resolved relative to the
source and called back into an exported Nimony proc (`p27`, `p28`). Is that supported surface at the pin, or
incidental? The chapter uses it as prose evidence and keeps the sample free of external C files so the verifier
stays a single-file run.

**G. `dynlib` naming.** `libm.so.6` failed with `could not load` on this machine while `libm.dylib` worked
(`p03`, `p08`). Confirm the chapter's rule: the `dynlib` string is the platform's, and a portable program links
instead.

**H. C globals.** `var errno {.importc, header: "<errno.h>".}: cint` read `7` after a write (`p12`) and `2` after
a failing `open` (`p37`). Is the `importc var` binding supported surface, and is `errno` a reasonable example to
teach with, given it is a macro on some systems?

## ERRATA candidates

1. **`doc/language.md:306-341` does not say `cstring"…"` literals are raw.** The section shows `cstring"hello"`
   and warns about modifying literals, but a reader coming from `"…"` will expect `\n` to be a newline; it is two
   bytes (`p17`). Documentation gap, low priority; the chapter states the rule.
2. **`doc/language.md:316-317` says a `$` proc is defined for `cstrings` without naming the module.** Already
   recorded against Chapter 5 (see `ERRATA.md`), so not filed twice here. At the pin `$c` needs
   `import std/strutils` (`p09` vs `p16`).
3. **`doc/language.md:2778`'s `stat` example is correct at the pin, and `out Stat` emits `&st`** (`p41`). No
   errata; recorded because the chapter leans on it.

## Watch rows

- **The callback `const` split.** clang on macOS refuses the direct `qsort` pass; gcc on Linux was not measured.
  The chapter gives the cast as the portable form and keeps the sample free of callbacks. Re-check when the
  sample verifier's platform changes.
- **`sizeof` on importc types asks C.** `144` for a partial `struct stat` (`p34`) is the C answer, so the Nimony
  field list is not a size declaration. Worth saying out loud; if the lowering ever computes the size in Nimony
  instead, this row goes.
- **Macro-as-routine.** `isdigit` declared with `header: "<ctype.h>"` worked (`p13`); a macro that is not a call
  does not (`p30`). The boundary is real but not documented anywhere at the pin.

## Notes for the editor

- Claim 8 is the one that changes a reader's habits; it appears twice in the text on purpose (declaration section
  and Samples line-by-line).
- Claim 31 and claim 35 are the two places where the chapter says "the compiler cannot help you"; keep both, they
  are the chapter's argument.
- `samples/22-cinterop/cinterop.nim` has no callback and no `{.compile.}` on purpose; the verifier must stay a
  single-file run at both platforms.
- No other chapter was opened.

---

## Verdict — 2026-11-13

Reviewer: **Momo**. I re-ran every probe in `ch22-probes/` myself at pin `4ba90a7`, plus twenty-three of my own for
the shapes the table left implicit: `~/.openmausbot/workspaces/49df9f87-8857-46c0-b9b8-8f066a10a55e/ch22-v/`
(`v01`-`v23`, one directory each, same `nimony c -r main.nim` invocation). Verifier re-run by me from the authoring
folder: `SUMMARY 21/21 passed, 0 failed`; the sample's eleven lines are byte-identical to the block in `en.md`.

**Verdict: 42 of 48 claims stand as written, three are wrong and change the text (3, 4, 10), three need only a
citation or probe fix (5, 9, 34), zero open.**

The one that changes a paragraph: **`header` is not what makes the C compiler see a prototype — Nimony writes the
prototype itself.** With `header`, the generated C contains `#include <string.h>` and the call is `strlen("hello")`;
without it, Nimony emits its own declaration and calls through it:
`NI64 cstrlen_0_mai3r4ykk(NC8* s_0) __asm__("strlen");` (`v13`, `a01`/`nimcache/.../mai3r4ykk.c:474`). So the C
compiler always checks the call against a prototype; `header` decides *whose* prototype it is. That is a better fit
for the chapter's thesis than the sentence now in the text, and it has a clean proof: a macro with no symbol,
`major`, prints `0` with `<sys/types.h>` (`v20`) and fails to link on `_major` without it (`v21`).

### Answers A-H

**A. Intended, and not a Nimony delta.** Nim 2.4.0 gives the same `4`/`3` (my probe), and the lexer comment
(`nimlexer.nim:1058-1063`) makes any quoted string after an identifier a generalized literal, which by construction
never runs the escape pass. Keep the rule; reframe ERRATA 1 as a doc gap inherited from Nim, not a Nimony change.

**B. The copy is the idiom.** `wantNotNil` needs a symbol root (`analysableRoot`, `contracts.nim:283-295`), and an index
expression has none: `slots[0] != nil` and `isNil(slots[0])` both fail (`v06`, `v15`). The copy gives the fact a symbol
to attach to; the cast is the unguarded escape. The in-place form is not coming — same rule as any other not-nil fact.

**C. Not a Nimony gap.** Nim 2.4.0 on this toolchain fails the same `qsort` pass with the same clang error (`v16`). A
Nimony proc type has no `const` to write, so the cast is the route on both compilers. Drop "the pin emits"; say "a C
`const` parameter has no Nimony spelling". gcc-on-Linux stays unmeasured and the watch row stays.

**D. No Nimony-level refusal.** With `header` the C compiler rejects `sizeof(struct stat)()` — "called object type
'unsigned long' is not a function" (`p30`); without it the link fails on the undefined symbol (`v08`). Grep over `src/`
finds no such message as "expression cannot be followed by a postfix '(' operator". Say "a name, never an expression,
because it is emitted as a call".

**E. By construction, not a hole to diagnose.** `contracts.nim:280` runs on Nimony expressions only and the compiler
never parses the header, so a C return cannot be checked. State it as the chapter's point; do not file a diagnostic.

**F. Supported.** `{.compile.}` is documented, relative-path rule included, at `doc/language.md:5160-5198`, and the
round trip works (`p27` from two working directories, `p28` prints `42`). Keeping it prose-only in the sample is right.

**G. Confirmed.** `libm.so.6` is a Linux name and fails here with `could not load` (`p03`); `libm.dylib` loads and
`cos(0.0)` prints `1.0` (`p08`). The rule stands and the sample is right to link instead.

**H. Supported, but `errno` is the wrong example to teach with.** `importc var` is deliberate
(`contracts_fir.nim:5790-5795`), and `errno` works only because the header is included and C expands the macro at the
use site. Teach a real global (`optind`); give `errno` one clause as the macro case, and never take its `sizeof`.

### Claim verdicts

| # | Verdict |
| --- | --- |
| 1 | Stands — the comment and the skip are at `contracts_fir.nim:6036-6041`. |
| 2 | Stands — `a01` prints `5`. |
| 3 | **Correct.** Header is not what puts a prototype in front of C; Nimony writes one (`v13`), and with a header it includes the file and calls the C name (`a01` C: `#include <string.h>`, `strlen("hello")`). Proof that it matters: `major` prints `0` with `<sys/types.h>` (`v20`) and fails to link without it (`v21`, undefined `_major`). |
| 4 | **Narrow.** Run is right, reason is not: it linked because Nimony emitted `cstrlen_0(...) __asm__("strlen")`, not because libc already declares `strlen`. Fold into 3. |
| 5 | Citation — the probe shows the override (`cstrlen` → `"strlen"`), not the default. `a01` is the default case (declared `strlen`, no string). |
| 6 | Stands — `p03` fails, `p08` prints `1.0`. |
| 7 | Stands — `p04` prints `hi 42\n` with no newline. |
| 8 | Stands — `p17` gives `4` and `3`; the generated C shows `"a\\nb"` against `"a\012b"`. |
| 9 | Citation — `p13` does not prove the macro path: macOS libc also exports `isdigit`, and the same probe without `header` printed `1` (`v19`). Use `major`: `v20` `0`, `v21` undefined `_major`. |
| 10 | **Correct.** No Nimony refusal exists; with `header` the C compiler rejects the call ("called object type 'unsigned long' is not a function", `p30`), without it the link fails (`v08`). Delete the quoted postfix message. |
| 11 | Stands — `ctypes.nim:41-44`, `system.nim:160`; `p15` prints `4`. |
| 12 | Stands — `p15` prints `4 8 8 8`; the pointer size is the platform-dependent one, as noted. |
| 13 | Stands — `p22` passes the literal `3`; `v03` fails as "Type mismatch" for `sizeof(cint)`. |
| 14 | Stands — `p22` prints `xxx true`. |
| 15 | Stands — `p14` prints `3 1`. |
| 16 | Stands — `p18` prints `0` then `true`; generated C has `struct stat` and `stat(...)`. |
| 17 | Stands — `p41` prints `0` then `true`; matches `doc/language.md:2778`. |
| 18 | Stands — `p34` prints `144 144`. |
| 19 | Stands — `p38` prints `8`. |
| 20 | Stands — `p25` prints `Hello Hello`. |
| 21 | Stands — `p32` gives `cannot pass s to var/out T parameter`. |
| 22 | Stands — `v01` gives the exact message; `p10` also emits the `$` errors because it has no `strutils`. |
| 23 | Stands — `p09` fails, `p16` prints `hello` and `5`; `strutils.nim:230`. |
| 24 | Stands — `p07` lists nine candidates; `syncio.nim:293-331`, echo at `:465-469`. |
| 25 | Stands — `p24` prints `3 1`. |
| 26 | Stands — `p23` prints `hitrue`. |
| 27 | Stands — `p29` prints `3`. |
| 28 | Stands — `doc/language.md:785` and `:851`. |
| 29 | Stands — `p20` prints `true`. |
| 30 | Stands — `p21` prints `false true`. |
| 31 | Stands — `p33` prints `true`. |
| 32 | Stands — `v04` reproduces `main.nim(8, 31) Error: expected non-nil value` exactly. |
| 33 | Stands — `p06` prints `true`. |
| 34 | Citation — the declaration is refused as well: `'slots' is of type 'array[0..1, cstring not nil]', which has no default value`, before the `nil` assignment gives `expected non-nil value` (`v05`). Say both. |
| 35 | Stands — `v06` reproduces `... slots[0]`; `isNil(slots[0])` fails the same way (`v15`), worth one clause. |
| 36 | Stands — `p35` prints `3` then `true`. |
| 37 | Stands — `p36` prints `3`. |
| 38 | Stands — `p26` prints `5`; `nm` shows `_book_add`. |
| 39 | Stands — generated C has `N_CDECL(int, book_add)(...)`; on the `__GNUC__` branch the macro is `rettype name`. |
| 40 | Stands — `42` from the probe directory and from the authoring root; matches the documented relative-path rule. |
| 41 | Stands — `p28` prints `42`; `helper2.c` really calls `book_cb`. |
| 42 | Stands — `p05` clang refusal; Nim 2 fails the same way (`v16`). |
| 43 | Stands — `p11` prints `123`. |
| 44 | Stands — `p39`, both messages. |
| 45 | Stands — same source region as 1. |
| 46 | Stands — `p12` prints `7`; the binding rule is `contracts_fir.nim:5790-5795`. |
| 47 | Stands — `p37` prints `-1 2`. |
| 48 | Stands — `nim2/n1` prints `hello`. Add that Nim 2 also reads `cstring"a\nb"` as four bytes (my probe), so the delta is the conversion and `$`, not the literal. |

### ERRATA

1. **Keep, reframed.** `doc/language.md:306-341` never says `cstring"…"` is raw. Measurement stands (`p17`), but Nim
   2.4.0 behaves identically (`nim2` probe: `4`/`3`), so this is a gap inherited from Nim's own doc, not a Nimony
   divergence. Low priority, doc gap.
2. **Agree, not refiled.** `doc/language.md:316-317` still names no module for `$`; already recorded against Chapter 5.
3. **Agree, no errata.** `doc/language.md:2778`'s `stat` example is correct at the pin (`p41`).
4. **New — `doc/language.md:332-341` teaches a conversion the pin refuses.** The example does `prepareMutation(x)`
   then `var s: cstring = cstring(x)` on a `var string`; at the pin that is
   `Only string literals can be converted to cstring. Use toCString for safe conversion.` (`v22`). Documentation
   defect: the section's example contradicts the rule Chapter 22 is built on, and the example should go, not the rule.

### Watch rows

- **The callback `const` split** stands, with one correction: Nim 2.4.0 fails identically (`v16`), so this is the C
  type system meeting a proc type that cannot spell `const`, not a Nimony regression. gcc on Linux still unmeasured.
- **`sizeof` on importc types asks C** stands (`p34`).
- **Macro-as-routine** stands, but the evidence is `major` (`v20`/`v21`), not `isdigit` — libc exports `isdigit` on
  macOS, so `p13` passes either way.

### What to change in `en.md`

1. "Declaring a C function": rewrite the `header` sentence and merge claims 3-4 — Nimony writes the prototype from
   your declaration; `header` includes the real one; use `major` as the one-line proof.
2. "Declaring": replace claim 10's quoted error with the two outcomes (C rejects with a header, link fails without).
3. "The types a signature needs" / null section: add the declaration error for `array[2, cstring]` (claim 34) and the
   `isNil(slots[0])` case (claim 35).
4. ERRATA 1: one clause saying Nim 2 reads literals the same way; new row 4 as above.

