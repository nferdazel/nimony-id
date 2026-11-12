# Chapter 10 review sheet — Arrays, Sequences, and Tuples

Draft: `chapters/10-arrays-sequences-tuples/en.md` (`status: drafting`).
Sample: `samples/10-arrays-sequences-tuples/collections.nim`.
Toolchain: `~/.local/opt/nimony/4ba90a7`, pin `4ba90a781b0b22d0821efaa153c129c37cef6143` (nimony 0.6.3).
Verifier: `./tools/verify-samples.sh` → `SUMMARY 9/9 passed, 0 failed`, exit 0.

Each claim below is what the chapter teaches. The probe is the file in
`/Users/sachiel/.openmausbot/workspaces/be336972-1e63-4f00-9916-c76cc8e33654/ch10-probes/`, run with
`$NIMONY_HOME/bin/nimony c -r <file>`; the output is pasted raw, trimmed to the lines that matter. Every claim
you verify replaces a row with `held` or `wrong, because …`; do not rewrite the rows I cite.

Chapter 9's `review.md` carries the borrow rule this chapter points at; it is not re-argued here.

| # | Claim in the chapter | Probe | Raw output at the pin | Source in chapter |
| --- | --- | --- | --- | --- |
| 1 | An array constructor takes its element type from the first element, and later elements convert to it. | `a1.nim` | `10` / `3` / `0` / `2` / `2.0`, exit 0 | §Arrays |
| 2 | An array's length must be constant; a `var` length is rejected as an invalid index type, and a `const` length builds. | `a8.nim`, `a9.nim` | `a8`: `Error: invalid array index type: n`, exit 1. `a9`: `3` / `0`, exit 0 | §Arrays; `src/nimony/semtypes.nim:776` |
| 3 | `array[5, T]` has five elements and `array[0..5, T]` has six. | `b1.nim` | `5` / `6`, exit 0 | §Arrays |
| 4 | A non-zero base moves the valid indexes: index `0` is a compile error, and iteration still yields the elements in order. | `b2.nim`, `b3.nim` | `b2`: `value out of range: 0 notin 1..3`, exit 1. `b3`: `5` / `6` / `7`, exit 0 | §Arrays |
| 5 | A literal index out of range is a compile error; a variable index out of range stops the program with `index out of bounds`. | `a4.nim`, `a7.nim` | `a4`: `value out of range: 5 notin 0..2`, exit 1. `a7`: `index out of bounds: 5 notin 0..2`, exit 1 | §Arrays; `lib/std/system/panics.nim:86` |
| 6 | Any ordinal type indexes an array; `array[Color, int]` has three elements and `low`/`high` return enum values. | `e1.nim` | `5` / `3` / `red` / `blue`, exit 0 | §Arrays |
| 7 | Writing an element of a `let` array is rejected by the array `[]=` template. | `m1.nim` | `/.../lib/std/system.nim(37, 4) Error: cannot mutate expression a[0]`, exit 1 | §Arrays; `lib/std/system.nim:34-37` |
| 8 | An array copies on assignment; changing the copy leaves the source alone. | `y2.nim` | `1` / `9`, exit 0 | §Arrays |
| 9 | Arrays nest as `array[2, array[2, int]]` with no special syntax. | `a6.nim` | `3` / `2` / `2`, exit 0 | §Arrays |
| 10 | `add` appends one element and `pop` removes and returns the last; `high` tracks the new last index. | `s1.nim`, `y5.nim` | `s1`: `3` / `4` / `4` / `3` / `1` / `02`, exit 0. `y5`: `3` / `2` / `-1`, exit 0 | §Sequences; `lib/std/system/seqimpl.nim:213`, `:363` |
| 11 | There is no `&` for two sequences and no `add(seq)`; `add` takes one `sink T`. | `s12.nim` | `a & b` → `Type mismatch at [position]`, candidates `expected: string but got: seq[int64]`; `c.add @[3, 4]` → `[2] expected: int64 but got: seq[int64] (declared in …/seqimpl.nim(213, 1))`, exit 1 | §Sequences; `lib/std/system/stringimpl.nim:1034-1063` |
| 12 | `newSeq[T](n)` allocates zero-filled storage. | `s2.nim` | `1` / `7` / `4` / `0`, exit 0 | §Sequences |
| 13 | `let e = @[]` cannot infer its element type, and the message names the mangled instantiation. | `s11.nim` | `Error: could not infer type for T.141.sysvq0asl`, exit 1 | §Sequences |
| 14 | An empty sequence has length `0` and `high` `-1`. | `y5.nim` | last two lines `3` / `2` / `-1` (pop, length, empty `high`), exit 0 | §Sequences; `lib/std/system/seqimpl.nim:354-359` |
| 15 | A sequence copies on assignment; a by-value parameter cannot be grown in place because `add` needs a `var`, and a routine that copies it to a local `var` leaves the caller's length alone. | `m3.nim`, `y7.nim`, `y3.nim` | `m3`: `2` / `3` / `3`, exit 0. `y7`: `Error: cannot pass xs to var/out T parameter`, exit 1. `y3`: `3` / `2`, exit 0 | §Sequences |
| 16 | A sequence index out of range trips the `[]` requires clause as an assertion, not as an `index out of bounds` line. | `s4.nim` | `/.../lib/std/system/seqimpl.nim(239, 41): i < s.len [AssertionDefect]`, exit 1 | §Sequences; `lib/std/system/seqimpl.nim:239` |
| 17 | `@array` converts to a sequence by copying. | `s14.nim` | `2` / `3` / `2`, exit 0 | §Sequences |
| 18 | A sequence slice is a fresh sequence with copies, so growing it does not change the source. | `s7.nim` | `3` / `4` / `4`, exit 0 | §Slicing; `lib/std/system.nim:658-668` |
| 19 | Sequence slice bounds are clamped: `[2..10]` keeps what exists, `[5..1]` is empty, `^1` and `..<` work. | `s10.nim` | `2` / `0` / `3` / `2` / `2`, exit 0 | §Slicing; `lib/std/system.nim:610-616`, `:672-675` |
| 20 | An array has no slice operator; `a[1..2]` reports a type mismatch with a 59-line candidate list ending in the `seq` slice. | `s5.nim` | `Type mismatch at [position]` / `a[1 .. 2]` / `[1] array[0..3, int64] does not match constraint T …` / 59 `[`-prefixed lines / last line `expected: seq[T] but got: auto (… system.nim(672, 1))`, exit 1 | §Slicing |
| 21 | `toOpenArray` is a view, not a copy: writing through it changes the array, even when the view is bound with `let`. | `y4.nim` | `9` / `9`, exit 0 | §Slicing; `lib/std/system/openarrays.nim:6-9`, `:10` |
| 22 | An `openArray` parameter accepts an array, a sequence and a literal with no conversion at the call site. | `o1.nim` | `6` / `9` / `21`, exit 0 | §Slicing; `doc/language.md:412-425` |
| 23 | A `var openArray` parameter writes back to array and sequence callers; without `var`, the write is rejected. | `o3.nim`, `o4.nim` | `o3`: `101` / `104`, exit 0. `o4`: `Error: cannot pass xs to var/out T parameter`, exit 1 | §Slicing; `lib/std/system/openarrays.nim:13` |
| 24 | A tuple gets field names from its declared type, so a positional literal can be read by name and by position. | `y6.nim` | `Ada` / `36` / `Ada` / `Bob`, exit 0 | §Tuples |
| 25 | A tuple literal written without an expected type has no field names. | `t1.nim` | `Error: undeclared field: 'name' for type tuple[string, int64]`, exit 1 | §Tuples |
| 26 | Constructing a tuple with object-constructor syntax is rejected. | `t3.nim` | `Error: expected type symbol for object constructor`, exit 1 | §Tuples |
| 27 | Tuple fields must be in declared order and of the declared types; a mismatch prints both tuples. | `t11.nim`, `t10.nim` | `t11`: `got: tuple[int64, string] but wanted: tuple[name: string, age: int64]`, exit 1. `t10`: `got: tuple[name: string, age: int64] but wanted: tuple[label: string, years: string]`, exit 1 | §Tuples |
| 28 | Two tuple types with the same field types and order but **different field names** are assignable at the pin, and the target's names then read the values. | `t9.nim` | `Ada36` / `36` / `40`, exit 0 | §Tuples; contradicts `doc/language.md:485` — see Questions B and ERRATA |
| 29 | A tuple copies on assignment and through a by-value parameter. | `t5.nim`, `c1.nim` | `t5`: `36` / `37` / `Bob`, exit 0. `c1`: `36` / `37`, exit 0 | §Tuples; `doc/language.md:564` |
| 30 | Writing a field of a `let` tuple is rejected, and the message names the field by position. | `m2.nim` | `Error: cannot mutate expression p[1]`, exit 1 | §Tuples; `lib/std/system.nim:24`, `:32-33` |
| 31 | Unpacking works with `_` and nests. | `t4.nim` | `42` / `13` / `123`, exit 0 | §Tuples; `doc/language.md:1669-1710` |
| 32 | A one-field tuple is written `(1,)`, and the indentation form declares a tuple type. | `y1.nim`, `t12.nim` | `y1`: `1` / `5`, exit 0. `t12`: `Ada36`, exit 0 | §Tuples; `doc/language.md:499-510`, `:515-523` |

## Questions

**A.** Claim 21 — a `let` binding of an `openArray` still allows a write through `[]` (`y4`), while a `let`
array, sequence or tuple rejects one (`m1`, `m2`, and `add` on a `let` seq fails with `cannot pass mid to
var/out T parameter`). Is the `let`-view write intended at the pin, and which source line should the chapter
cite for it? I describe the mechanism as "the `let` binds the view, not the storage" and want that sentence
checked rather than trusted.

**B.** Claim 28 — `doc/language.md:485` says the names of the fields also have to be the same for two tuple
types to be equivalent. At the pin, assigning `tuple[label: string, years: int]` from
`tuple[name: string, age: int64]` compiles and reads through the new names. Intended (structural by types and
order only), or a defect candidate? The chapter teaches the pin and records this as an open question in
`ERRATA.md`; I have not called it a documentation gap on my own.

**C.** Claim 11 — the pin has no concatenation for sequences: `&` resolves only for `string`/`char`, and `add`
takes one `sink T`. `doc/language.md:404-405` only ever describes appending single elements, so the guide is
consistent. Is the omission intended at this pin, and should it go to `ERRATA.md` as a watch line for readers
porting Nim 2 code that wrote `a & b`?

**D.** Claim 14 — `high` of an empty sequence is `-1` (`lib/std/system/seqimpl.nim:354` subtracts one from
`len`). `doc/language.md:400-403` says `low` is always 0 and says nothing about `high` on an empty sequence. Is
`-1` the intended contract, or should the chapter avoid stating it?

**E.** Claims 5 and 16 — the same mistake reports two ways: an array index prints `index out of bounds: …` from
`lib/std/system/panics.nim:86`, a sequence index prints `seqimpl.nim(239, 41): i < s.len [AssertionDefect]`.
Both exit 1. Intended difference between a contract check and an assertion, or a message-consistency candidate?

**F.** Claim 1 and the `array[5, T]` / `array[0..5, T]` split (claim 3) rest on `doc/language.md:344-355`,
which states both syntaxes but never says that `array[5, T]` means five elements while `array[0..5, T]` means
six. I derived the count from the length form becoming `0 .. length-1` in `src/nimony/semtypes.nim:779-790`
and from `b1`. Is that derivation the right one to teach, or is there a file that states it directly?

**G.** Claim 15 — `xs.add 3` inside a routine that receives `xs: seq[int]` by value is rejected with
`cannot pass xs to var/out T parameter`; Nim 2 compiled that shape and grew the caller's buffer. The chapter
states the rejection and points at Chapter 8's `var`-parameter rule. Is that the intended reading at the pin,
and should the book carry it as a Nim 2 delta sentence at the point of use even though `OUTLINE.md` marks
Chapter 10's delta box `no`? I have not put it in a delta box; whether the outline's delta line changes is a
product call, raised in the room rather than decided here.

## ERRATA candidates

1. **Tuple field names (claim 28).** `doc/language.md:485` requires the names to match; the pin does not check
   them on assignment. Recommended: a documentation-gap row (Chapter 10, section §Tuples), citing `t9` and
   `doc/language.md:485`, with the ruling left to you — hold or file. Line to cite in the row is `:485`, not
   `:482-487`, because that is the sentence that is contradicted.
2. **Empty-sequence `high` (claim 14).** `doc/language.md:400-403` defines `low` for an empty sequence as `0`
   and is silent on `high`. If `-1` is contract, the row should say so and the chapter keeps it; if not, drop
   the sentence and keep `len` only. Line to cite: `:400-403` plus `lib/std/system/seqimpl.nim:354`.
3. **No sequence concatenation (claim 11).** Not a contradiction, so a watch row rather than a defect: a reader
   coming from Nim 2 will write `a & b`. Cite `lib/std/system/seqimpl.nim:213` and the absence of a `seq`
   overload among `lib/std/system/stringimpl.nim:1034-1063`. Drop it if you would rather the book not annotate
   a missing feature.

## Known gaps in the draft, marked rather than hidden

- `id.md` does not exist yet; it is written from final text after the technical review.
- The chapter points at Chapter 9 for the `var`-result borrow rule and does not restate it
  (`ERRATA.md`, row "Chapters 9, 10, 14 (borrow)"). Chapter 14 generalises it.
- Every code block with a compile error shows the message without the `file(line, col)` prefix, because the
  probe file's line numbers are not the snippet's. The raw output in this table keeps the prefixes.

---

## Technical review — Momo, 2026-11-12

Re-ran every probe in the sheet at `4ba90a7` with `nimony c -r`; the runs are `rerun-<name>.out` in the same
probe folder. Twelve review probes are added there as `rv1`–`rv12`. Book verifier re-run by me:
`SUMMARY 9/9 passed, 0 failed`, exit 0, pin `4ba90a7`. The sample's 39 output lines match the block at
`en.md:643-682` line for line.

### Verdicts, claims 1-32

| # | Verdict | What settles it / what to change |
| --- | --- | --- |
| 1 | held | `a1`. The doc sentence is at `doc/language.md:356-358`, not `:357-361`. |
| 2 | held | `a8` (first error) and `a9`; `src/nimony/semtypes.nim:776`. |
| 3 | held | `b1`; the derivation is `src/nimony/semtypes.nim:779-791` — the `-1` is line 791, outside the cited `779-790`. |
| 4 | held | `b2`/`b3` cover the error and the iteration; the block's `row[1]`/`low`/`high` lines are `a2` (`5`, `1`, `3`, `3`), which the row does not cite. |
| 5 | held | `a4` static, `a7` runtime; `lib/std/system/panics.nim:86` is the `writeErr "index out of bounds: "` line. |
| 6 | held | `e1`. |
| 7 | held | `m1`; `lib/std/system.nim:34-37`, reported at `:37`. |
| 8 | held | `y2`. |
| 9 | held | `a6`. |
| 10 | held | `s1`/`y5`; `seqimpl.nim:213` and `:363`. |
| 11 | held | `s12`; `rg` over `lib/std` finds exactly three `&` overloads, `stringimpl.nim:1034`, `:1062`, `:1063`. |
| 12 | wrong, wording only | `s2` proves `seq[int]` reads `0`; the contract at `seqimpl.nim:76-77` is "default-initialized elements", not zero-filled. Say "default-initialises (`0` for `int`)". |
| 13 | wrong in one detail | `s11` holds for the message. "The exact suffix differs per file" does not: `rv9` and `rv10` (same content, different file names) both print `T.141.sysvq0asl`; a copy under `sub/othername.nim` and a file with two array declarations before the literal printed the same string (four runs). The suffix is an internal instantiation name, stable here; tell the reader not to match on it. |
| 14 | held | `y5` gives `high` `-1`; `rv5` adds `len` `0`. Cite `:354-358`; the docstring at `:355` says "or `-1` when empty". |
| 15 | half held | `m3` (assignment), `y7` (rejection) and `y3` (local copy) hold. "and so does passing it to a non-`var` parameter" is unobservable: `rv2` shows every write to a by-value `seq` parameter is rejected (`cannot pass xs to var/out T parameter`), so no probe can see a call-boundary copy. Replace with "a by-value parameter is not a place, so the routine cannot change the caller's sequence". |
| 16 | held | `s4`; `seqimpl.nim:239`. |
| 17 | held | `s14`; `rv11` (`var` array through `@`) leaves the array readable (`2`, `2`, `1`), so the caller's storage is not consumed. |
| 18 | held | `s7`; `system.nim:658-668` (body through `:670`). |
| 19 | held | `s10`; `..<` at `system.nim:610-616`, `^` at `:626`, the `BackwardsIndex` seq slice at `:672-673`. |
| 20 | wrong in the block and the count | The slice error at `s5.nim(4, 10)` lists **21** candidate lines. The last is `[2] expected: BackwardsIndex but got: HSlice[int64,int64] (declared in …/system.nim(632, 1))`. The `seq` slice this call needed is #18 (`system.nim:658`); two `[2]` rejection lines follow it. The `… got: auto (…system.nim(672, 1))` line in the block is the tail of the **third** error, `sl[0]`, after the failed binding; 59 is the sum of `[`-prefixed lines across the three errors that list candidates, not one listing. The substance (no array slice; the array `[]` takes an integer) holds. |
| 21 | held | `y4`; `rv3` (a `let` view passed to `var openArray` writes back, `101`) and `rv4` (a `let` array in the same position is rejected). The sentence is right where the storage is mutable; `rv12` shows a `let` view over a `let` array is rejected (`cannot pass v to var/out T parameter`). The rule is `src/nimony/derefs.nim:399-407`, comment at `:406` ("Special rule to make `toOpenArray` work"); cite it beside `openarrays.nim:6-10`. |
| 22 | held | `o1`; `doc/language.md:412-425`. |
| 23 | held | `o3`/`o4`; `openarrays.nim:13`. |
| 24 | held | `y6`. |
| 25 | held | `t1`. |
| 26 | held | `t3`. |
| 27 | held | `t11`/`t10`. |
| 28 | held, now ruled | True of the pin and intended: `src/nimony/sigmatch.nim:2418-2450` compares field **types** only, and the comment at `:2435` says "only the type of the field is important:". `doc/language.md:485` is the wrong half — documentation gap, not a defect. Cite `sigmatch.nim:2435` and drop "open question". |
| 29 | half held | `t5` proves the assignment copy. "through a by-value parameter" is unproven: `rv7` shows a by-value tuple parameter rejects a field write (`cannot mutate expression p[1]`), and `c1` proves only that the returned value is a copy (`result = p`). Say the callee cannot write the parameter. |
| 30 | held | `m2`; `system.nim:24`, `:32-33`. |
| 31 | held | `t4`; `doc/language.md:1669-1671`, `:1672-1678`, `:1702-1708`. |
| 32 | held | `y1`/`t12`; `doc/language.md:499-510`, `:515-523`. |

### Answers A-G

**A.** Intended, and the rule has a name: `borrowsFromReadonly` (`src/nimony/derefs.nim:382-421`) treats a `let`
as readonly except when its type is a view, where it re-checks the initializer instead — `:399-407`, with the
comment at `:406` "Special rule to make `toOpenArray` work". So a `let` view over mutable storage stays writable
(`y4`, `rv3`), a `let` over a `let` array is rejected (`rv12`), and "the `let` binds the view, not the storage"
is the right mechanism; cite `derefs.nim:406` beside `openarrays.nim:6-10`.

**B.** Intended by construction, not a defect: `sigmatch.nim:2418-2450` compares only field types and order, and
`:2435` says so in a comment; `doc/language.md:485` is a documentation gap. Record a doc-gap row, cite
`sigmatch.nim:2435`, file nothing at `nim-lang/nimony`.

**C.** Held: only the three `&` overloads exist (`stringimpl.nim:1034`, `:1062`, `:1063`) and `add` takes one
`sink T` (`seqimpl.nim:213`); the guide is consistent (`:403-404`), so this is a missing feature, not a
contradiction. Keep as a watch row; cite `seqimpl.nim:213` and those three lines.

**D.** `-1` is the contract: `seqimpl.nim:355` says "Highest valid index (`len-1`), or `-1` when empty." Keep the
sentence, cite `:354-358`, and drop the ERRATA candidate — the source states it, and the guide's silence is not a
contradiction.

**E.** Intended: an array index is lowered to `nimIcheckAB`/`nimIcheckB` (`src/hexer/desugar.nim:1357-1435`),
which calls `raiseIndexError3` (`panics.nim:85-86`, message at `:86`), while a seq `[]` carries a `requires`
clause (`seqimpl.nim:239`) enforced as an assertion. Two mechanisms, not a message bug; no ERRATA row.

**F.** The derivation is right: a typed index is rejected at `semtypes.nim:776`, and an untyped length becomes
the range `0 .. length-1` at `:784-791` (cite `:779-791`); `doc/language.md:353-354` only gives the two syntaxes
and never the count. Teach it from the source; no file states it in prose.

**G.** Held and intended: `add` takes `var seq[T]` (`seqimpl.nim:213`), a by-value parameter is not a place
(`rv2`; Chapter 8), and a `var` seq parameter works (`rv1` prints `3`). It is a Nim 2 delta at the point of use:
recommend a sentence in the body; whether it becomes a delta box is Wira's product call.

### ERRATA ruling

1. **Tuple field names — keep, as a documentation gap.** Not a defect: `sigmatch.nim:2435`. Cite `t9`,
   `sigmatch.nim:2435`, `doc/language.md:485`.
2. **Empty-sequence `high` — drop.** `seqimpl.nim:355` documents `-1`; no contradiction. The chapter keeps the
   sentence with `:354-358`.
3. **No sequence concatenation — keep as a watch row.** Cite `seqimpl.nim:213` and the three `&` overloads at
   `stringimpl.nim:1034`, `:1062`, `:1063`.

### Text corrections for en.md

1. `en.md:58` — `doc/language.md:357-361` → `:356-358`.
2. `en.md:109` — `src/nimony/semtypes.nim:779-790` → `:779-791`.
3. `en.md:245` — "which zero-fills" → "which default-initialises its elements (`0` for `int`)"; cite
   `lib/std/system/seqimpl.nim:76-77`.
4. `en.md:268-269` — replace "so the exact suffix differs per file": it did not differ across `rv9`, `rv10`,
   `sub/othername.nim` and the two-array variant. Say the suffix is an internal instantiation name and not to
   match on it.
5. `en.md:271-272` — `lib/std/system/seqimpl.nim:354-359` → `:354-358`.
6. `en.md:24-25` — "passing one to a routine copies it unless the parameter is `var`" → "a by-value parameter
   is not a place, so the routine cannot write it; pass it as `var` when it must write".
7. `en.md:274-275` — drop "and so does passing it to a non-`var` parameter"; say the callee cannot change the
   caller's sequence (`y7`, `y3`, `rv2`).
8. `en.md:394` — `:672-675` → `:672-673`; add `:626` for `^`.
9. `en.md:404-414` — replace the block's last line with the real tail, "19 more candidate lines" for 21 total,
   and rewrite "59 lines … ending with the `seq` slice": the listing is 21 lines, the `seq` slice is #18, two
   `[2]` rejections follow, and 59 is the sum across the three errors that list candidates.
10. `en.md:546-550` — replace "recorded in `ERRATA.md` as an open question for the technical review" with the
    ruling: intended by construction (`sigmatch.nim:2435`), a documentation gap at `doc/language.md:485`; cite
    `:2435` where the chapter says "copies on field types and order alone".
11. `en.md:563-564` — "a routine that takes one by value works on its own copy" → "a routine that takes one by
    value cannot write it" (`rv7`); keep `doc/language.md:564` for the assignment copy.
12. `en.md:620-621` — the call/temporary half has no inline cite; add `doc/language.md:1680-1688`.
13. `GLOSSARY.md:90` (`value semantics`) — the evidence line (`y2`, `m3`, `t5`) proves assignment copies only;
    by-value parameters refuse every write (`rv2`, `rv7`, `rv8`), so either say "a by-value parameter cannot be
    written at all at the pin" or add those probes.

### Sentences in en.md that state compiler behaviour with no source, commit or probe behind them

1. `en.md:24-25` — "passing one to a routine copies it unless the parameter is `var`". Not observable: `rv2`
   (`seq`), `rv7` (tuple) and `rv8` (array) all reject a write to a by-value parameter.
2. `en.md:274-275` — "and so does passing it to a non-`var` parameter". Same.
3. `en.md:563-564` — "a routine that takes one by value works on its own copy". `c1` proves the returned value
   is a copy, not the parameter; `rv7` shows the parameter cannot be written.
4. `en.md:268-269` — "the exact suffix differs per file". Contradicted by four runs (`rv9`, `rv10`,
   `sub/othername.nim`, two-array variant), all `T.141.sysvq0asl`.
5. `en.md:412-413` — "The listing runs to 59 lines … ending with the `seq` slice it was looking for." The
   listing is 21 lines and ends with a `BackwardsIndex` candidate; 59 is the total across the three errors that
   list candidates.
6. `en.md:620-621` — the second half ("when it is a call, the tuple is built once and read by position") has no
   inline cite; the doc has it at `:1680-1688`.
7. `en.md:271` — "The length of the empty sequence is `0`" has no probe in this sheet; `rv5` prints `0` and
   `-1`. The text is right, the row is missing.
8. `en.md:245` — "zero-fills" outruns the contract at `seqimpl.nim:76-77` ("default-initialized elements").

## Editorial pass — Aksara, 2026-11-12

Verdict accepted as written. All 13 text corrections are in `en.md`; `id.md` is translated from the corrected
text, not from the draft. No claim is open, so the chapter closes.

Applied, in the reviewer's numbering:

1. `doc/language.md:356-358` (was `:357-361`).
2. `src/nimony/semtypes.nim:779-791` (was `:779-790`).
3. "zero-fills" → "default-initialises its elements (`0` for `int`, `seqimpl.nim:76-77`)".
4. The mangled-suffix sentence now says the name is internal and not to match on it; the "differs per file"
   claim is gone.
5. `seqimpl.nim:354-358` (was `:354-359`).
6. §What this chapter is for: "a by-value parameter is not a place, so the routine cannot write it".
7. "and so does passing it to a non-`var` parameter" replaced with the caller-protection wording.
8. `system.nim:672-673` and `:626` for `^`.
9. The slice block is rebuilt from my own run of `s5`: two candidate lines, "18 more", and the real last line
   (`BackwardsIndex … system.nim(632, 1)`), plus a sentence saying 59 is the sum across three listings. Check 11
   was reworded to match, since it quoted the old tail.
10. The tuple paragraph carries the ruling and cites `sigmatch.nim:2435`; `ERRATA.md` row is rewritten from
    "open" to "documentation gap".
11. "a routine that takes one by value cannot write it", with the `[]=` template cited.
12. `doc/language.md:1680-1688` added for the call half.
13. `GLOSSARY.md` `value semantics` now separates assignment copy from the by-value refusal and names `rv2`,
    `rv7`, `rv8`.

Two editorial additions beyond the list, both inside the same page range:

- Answer A's mechanism is now in the body: `src/nimony/derefs.nim:399-407` (comment at `:406`) beside
  `openarrays.nim:6-10`, and the paragraph says the `let` view is rejected over a `let` array (`rv12`).
- `view` and `place` are new prose terms in this chapter and were added to `GLOSSARY.md` in this handoff.

`ERRATA.md` after the rulings: tuple names kept as a documentation gap, empty-`seq` `high` dropped,
sequence concatenation kept as a watch row, and one new watch row for the by-value `seq` growth (with `y7`,
`y3`, `rv1`, `rv2`) so no later chapter copies a Nim 2 `add`-into-the-parameter sample.

Not done, on purpose: nothing in `samples/` changed (`9/9`, pin `4ba90a7`), and no source line in the claim rows
above was rewritten.
