# Chapter 14 — technical review

**Chapter:** Ownership and Borrow Checking (`chapters/14-ownership-borrow/en.md`)
**Status:** `drafting` · **Words:** 2,230 · **Claims:** 38
**Pin:** `4ba90a781b0b22d0821efaa153c129c37cef6143` (nimony 0.6.3) · **Host compiler for contrasts:** Nim 2.4.0 (`~/.local/opt/nim-2.4.0`)
**Verifier (run by me, 2026-11-13):**

```
toolchain ~/.local/opt/nimony/4ba90a7/bin/nimony 0.6.3 pin 4ba90a7
PASS samples/14-ownership-borrow/ownership.nim exit=0
SUMMARY 13/13 passed, 0 failed        VERIFY_EXIT=0
```

Sample output diffed against the block in `en.md` §Samples: `diff` empty, 8 lines.

Probes live in `/Users/sachiel/.openmausbot/workspaces/be336972-1e63-4f00-9916-c76cc8e33654/ch14-probes/`
(`a01`-`a12`, `b01`-`b08`, `c01`-`c06`, `d01`-`d04`; `a09`, `a05`, `c06` additionally compiled with Nim 2.4.0).
Each was run with `~/.local/opt/nimony/4ba90a7/bin/nimony c -r <file>` unless the row says otherwise.

## Claim table

| # | Claim as the chapter states it | Probe | Raw output (abbreviated) | Section |
| --- | --- | --- | --- | --- |
| 1 | Assignment copies; only a `ref` makes two names reach one cell | carried from Ch 13, not re-probed | — | What "owns" a value |
| 2 | Hooks `=destroy`, `=dup`, `=copy`, `=wasMoved`, `=sink` are declared at `lib/std/system.nim:112-116` | source read | the five declarations, `=wasMoved` at `:116` | What "owns" a value |
| 3 | Those hooks are library-level, not a flow analysis | source read + c03 | `int` move leaves 5 (`y=5 x=5`) | What "owns" a value |
| 4 | `owned` is documented at `doc/language.md:893-960` behind `{.feature: "ownedRefs".}`, and the chapter uses none of it | doc read only | — (**doc-only, not probed**) | What "owns" a value |
| 5 | The aliasing check is `borrowCheckForCall`, `src/nimony/contracts_fir.nim:4242-4289` | source read | `proc borrowCheckForCall` at `:4242` | The call-site aliasing check |
| 6 | Mut/imm overlap message is `mutable argument aliases with immutable parameter` | a09, a10, a11 | `a09.nim(7, 6) Error: mutable argument aliases with immutable parameter` | The call-site aliasing check |
| 7 | Mut/mut overlap message is `mutable argument aliases with mutable parameter`, built at `:4282` | a02 | `a02.nim(7, 6) Error: mutable argument aliases with mutable parameter` (twice, both arguments) | The call-site aliasing check |
| 8 | Mut/mut fires for plain `int` parameters | a02 | same line as 7 | The call-site aliasing check |
| 9 | Disjoint fields of one object may be passed as two mutable arguments | a04, sample | `a04` → `2 1`; sample → `pair 2 1` | The call-site aliasing check |
| 10 | `passedByPointer` (`contracts_fir.nim:4340-4351`) gates the mut/imm half: view types, `lent`, `varargs`, const-ref passing, and any type that can own heap | source read | `not ownsNoHeap(c, t, 0)` in the returned expression | The call-site aliasing check |
| 11 | `ownsNoHeap` (`:4285-4338`) lists the heap-free types; everything else is treated as owning heap | source read | `IntT, UIntT, FloatT, BoolT, CharT, EnumT, HoleyEnumT, RangetypeT, PtrT, PointerT, CstringT, SetT` at `:4312-4314` | The call-site aliasing check |
| 12 | A by-value two-`int` object overlapping a mutable field argument compiles and prints `1` | a12, d01 | `a12` → `1`; `d01` → `1` | The call-site aliasing check |
| 13 | The same shape with a `string` field is refused, and the error is reported at the **mutable** argument's field dot | a11, d02 | `a11.nim(11, 9) Error: mutable argument aliases with immutable parameter`; `d02.nim(16, 18)` — both at the **mutable** argument's field dot | The call-site aliasing check |
| 14 | `doc/language.md:2507-2517` shows the two-`int` object as an error; at the pin the same program compiles | a12 + doc read | doc text at `:2510-2517`; `a12` exit 0 | The call-site aliasing check |
| 15 | A borrow stored in a global is refused with `borrow of 'a' escapes the proc; it does not live long enough` | b01 | `b01.nim(7, 7) Error: borrow of 'a' escapes the proc; it does not live long enough` | A borrow that outlives its subject |
| 16 | The same line also raises `unsynchronized access to global variable 'g'` (`contracts_fir.nim:4125`) | b01 | `b01.nim(7, 5) Error: unsynchronized access to global variable 'g'; pass it to a .sync routine or use {.cast(assumeSync).}` | A borrow that outlives its subject |
| 17 | A borrow that outlives its block is refused with `borrow of 'a' escapes its scope; it does not live long enough` | b02 | `b02.nim(7, 12) Error: ...` | A borrow that outlives its subject |
| 18 | A returned view may only borrow from the first parameter | b03 | `b03.nim(4, 14) Error: borrow of 's' escapes the proc; a returned view can only borrow from the first parameter` | A borrow that outlives its subject |
| 19 | That check is `checkResultBorrow`, `contracts_fir.nim:680-695` | source read | message built at `:690-692` | A borrow that outlives its subject |
| 20 | A view of the first parameter returns and is usable | b04, sample | `b04` → `3`; sample → `window 3 first 10` | A borrow that outlives its subject |
| 21 | A `var T` result from a second parameter is refused with `cannot borrow from b` | b05 | `b05.nim(4, 12) Error: cannot borrow from b` | A borrow that outlives its subject |
| 22 | Chained through a forwarder the same rule prints `cannot borrow from forward(x)` | b07 | `b07.nim(8, 19) Error: cannot borrow from forward(x)` | A borrow that outlives its subject |
| 23 | `validBorrowsFrom` (`derefs.nim:258-314`) is the rule and `trReturn` (`:461-470`) raises the error | source read | `proc trReturn` at `:461`; `buildLocalErr ... "cannot borrow from "` at `:468` | A borrow that outlives its subject |
| 24 | `doc/language.md:2448-2472` words the same rule with `location is derived from x which is not p's first parameter`, which the pin does not print | doc read + b05 | doc `:2452-2462`; measured message as row 21 | A borrow that outlives its subject |
| 25 | Reading through a borrow copies, so a proc may return an element | b08 | `b08` → `7` | A borrow that outlives its subject |
| 26 | Mutating a borrowed path during iteration is refused with `'s' is borrowed and cannot be mutated` (`contracts_fir.nim:621`) | a05 | `a05.nim(8, 11) Error: 's' is borrowed and cannot be mutated` | Borrowed paths during iteration |
| 27 | A sibling field of the borrowed path stays writable during the loop | a06, sample | `a06` → `1`, `2`, `new`; sample → `during 1`, `during 2`, `name new` | Borrowed paths during iteration |
| 28 | An index loop over the same seq is legal | a08, d03, sample | `a08` → `2 4`; `d03` → `2 4` | Borrowed paths during iteration |
| 29 | `move` is `lib/std/system.nim:123-126`: `result = x` then `=wasMoved(x)` | source read | the four lines, verbatim in the chapter | `move` is a library call |
| 30 | Moved `string` leaves `""`, length 0 | c01, d04 | `b=text len(a)=0`; `d04` → `7 0` then `['']` | `move` is a library call |
| 31 | Moved `seq[int]` leaves length 0 | c02 | `b.len=3 a.len=0` | `move` is a library call |
| 32 | Moved `ref object` leaves `nil` | c04 | `s.n=4 r is nil: true` | `move` is a library call |
| 33 | Moved object with `seq` and `string` fields empties both | c05 | `h=2 g=0 tag=''` | `move` is a library call |
| 34 | Moved `int` is unchanged | c03 | `y=5 x=5` | `move` is a library call |
| 35 | There is no use-after-move diagnostic: every post-move read above compiles and the program exits 0 | c01-c05; `grep -rn -i "use after move" src/ doc/` → no match | all exit 0; grep empty | `move` is a library call |
| 36 | A `sink string` parameter leaves the caller's variable untouched | c06 | `b=payload a='payload'` | `move` is a library call |
| 37 | Nim 2.4.0 compiles `take(s, s)` on seq/seq and prints `1` | a09 under nim 2.4.0, `--mm:orc` | `1`, exit 0 | Nim 2 delta |
| 38 | Nim 2.4.0 compiles mutate-during-iteration and dies at run time with `the length of the seq changed while iterating over it` | a05 under nim 2.4.0, `--mm:orc` | `AssertionDefect` at `iterators.nim(254, 11)`, exit 1 | Nim 2 delta |

Every claim above was settled by a run or by a source line. **Nothing in this chapter is left open.**

## Questions

**A. Is the heap-reach condition the rule, or an implementation detail?** The chapter states the mut/imm half as
"a copy that can share the caller's heap block may not overlap a mutable argument", from `ownsNoHeap`
(`contracts_fir.nim:4285-4338`) and `passedByPointer` (`:4340-4351`). That is what makes the two-`int` case
compile (a12) and the one-`string` case fail (a11). If you think the condition is a proxy that will move, I
would rather the chapter say "at this pin" in the rule sentence than teach a boundary that is not a boundary.

**B. `doc/language.md:2507-2517` is wrong at the pin.** The manual's field-path example uses `Obj(x, y: int)`
and states the call is an error; it compiles and prints `1` (a12). Documentation defect, or is the manual's
example meant to show a larger object and the type was shortened? Either way it is an ERRATA row, but the row's
verdict differs: doc defect, or doc example that lost the field that made it true.

**C. Inherited and variant objects are treated as heap-owning.** `ownsNoHeap` returns `false` for an object with
an inheritance marker (`:4328-4329`, "a derived value may own more") and for a `case` object. So a by-value
parameter of either shape always counts as a pointer in the mut/imm check, whatever its fields are. The chapter
does not mention this; should it, in one sentence, or is it noise for a reader who has not met inheritance yet?

**D. The absence of move checking is not a documented decision I can find.** No `use after move` string exists
in `src/` or `doc/`, and `move` is a plain `func` in `lib/std/system.nim`. Is the absence intended (ownership
transfer is a convention here), or a not-yet? The chapter's sentence is "at this pin it does not, and a rule
taught here would be false in the reader's next program" — that survives either answer, but if you know it is
planned, I would add the timetable-free half sentence that says so.

**E. `sink` has no enforced transfer I could measure.** With `proc consume(s: sink string): string`, the
caller's variable still prints its value afterwards (c06), in both compilers. The chapter says "sink is a shape
the compiler accepts, not an operation it verifies". Is that the right sentence for a reader who has just been
told `var` parameters write through?

**F. Error position in the mut/imm half.** The message is built with the mutable argument's info
(`contracts_fir.nim:4276`) but the compiler reports it at the immutable argument (a11 `(11, 9)`, d02 `(16, 18)`).
The chapter's Check 2 asks the reader why the error points at the second argument. Confirm that is what a reader
will see, so the exercise has a stable answer.

**G. `=wasMoved` for `int`.** Row 34 is measured, not explained: the chapter says "a type with no hook keeps its
value, because `=wasMoved` has nothing to do". Is that the reason, or does the compiler emit a hook for `int`
that happens to be a no-op? The table stays either way; the sentence would change.

## ERRATA candidates

1. **Documentation defect — field-path aliasing example.** `doc/language.md:2507-2517` states that
   `update(o.x, o)` on `Obj(x, y: int)` is an error. At the pin it compiles and prints `1` (a12, d01). Proposed
   row: chapter 14, §The call-site aliasing check, doc defect, pin `4ba90a7`, 2026-11-13. Verdict depends on
   question B.
2. **Documentation/message gap — `var T` result wording.** `doc/language.md:2452-2462` gives
   `location is derived from 'x' which is not p's first parameter and lives on the stack`. The pin prints
   `cannot borrow from b` (b05) and `cannot borrow from forward(x)` (b07): the expression, not the derivation.
   Behaviour identical, message shorter. Proposed row: doc/message gap, not a defect.
3. **No new row for use-after-move.** `ERRATA.md` already carries the Chapter 14 watch entry from the proof gate
   ("Use-after-move is **not** rejected"). This chapter adds evidence, not a finding: the moved-from value is
   `""` for a `string`, empty for a `seq`, `nil` for a `ref object`, both fields emptied for an object that
   holds them, and unchanged for an `int` (c01-c05), with no diagnostic anywhere in `src/` or `doc/`
   (`grep -rn -i "use after move"` empty). Proposed: extend that row's evidence column, not a new row.

## Definition of done, as it stands

1. One job — yes, and the `owned` annotation is named in one sentence and used nowhere.
2. Samples run — `13/13`, exit 0, 8 lines diffed byte-identical to the block in `en.md`.
3. Technical review — **this note**; empty until you append a verdict.
4. Editorial pass — not yet.
5. Both languages — `id.md` is deliberately not written until the text is final.
6. Frozen means frozen — n/a.

The chapter stays `drafting` until the review lands.

## Notes for the reviewer

- `a13` in the probe folder is a discarded probe (it loops forever by construction); ignore it.
- `a01` is worth reading first: it is the shape the outline's proof gate calls "mutable argument aliases with
  immutable parameter", and it **compiles**, because two `int` parameters are plain data. That is the finding
  that reshaped this chapter, and row 12-14 rest on it.
- The Chapter 9 carry is row 21-23: the chapter does not restate the `var T` rule, it cites `validBorrowsFrom`
  and moves on.

---

# Technical review — Momo, 2026-11-13

**Verdict:** 35 of 38 claims stand, 2 need narrowing (10's rule sentence, 35's scope), 1 has a wrong
evidential parenthetical but a correct chapter text (13). Two content corrections: the mut/imm rule as written
is missing the `passByConstRef` branch, and `ensureMove` does check last usage, so "no use-after-move
diagnostic" is true of `move` only. Ruling on both open ERRATA candidates below.

Probes from my run: `/Users/sachiel/.openmausbot/workspaces/be336972-1e63-4f00-9916-c76cc8e33654/ch14-momo/`
(`rv01`-`rv49`), run with `~/.local/opt/nimony/4ba90a7/bin/nimony c -r <file>` at pin `4ba90a7`.
Every row below is my own run, not your pasted output. Your probe folder re-run in full agrees: `a01`-`a12`,
`b01`-`b08`, `c01`-`c06`, `d01`-`d04` reproduce the outputs in your claim table, including `a07`'s
`Type mismatch at [position]` (that one is a broken probe, not a finding — it is not cited by any claim).

**Verifier, run by me:**

```
toolchain ~/.local/opt/nimony/4ba90a7/bin/nimony 0.6.3 pin 4ba90a7
PASS samples/14-ownership-borrow/ownership.nim exit=0
SUMMARY 13/13 passed, 0 failed        VERIFY_EXIT=0
```

## The two content corrections

### 1. The mut/imm rule sentence is incomplete: the const-ref branch, and its 24-byte threshold

`passedByPointer` (`contracts_fir.nim:4340-4350`) is not one condition, it is four:

```
result = forced or t.typeKind != SinkT and
         (t.typeKind in {LentT, VarargsT} or isViewType(t) or
          passByConstRef(t, param.pragmas, c.bits div 8) or
          not ownsNoHeap(c, t, 0))
```

Row 10 of your table lists all four and is correct. The **rule sentence** at `en.md:96-98` — "a copy that can
share the caller's heap block may not overlap a mutable argument" — covers only the fourth. The third branch,
`passByConstRef`, is `typeIsBig` (`sizeof.nim:282-288`) = `getSize > 24`, so a plain-data copy **above 24
bytes** is passed by const reference and counts as reading the caller's storage even though it shares no heap.
Measured, plain data only, no heap anywhere in the program:

| type | size | call | result |
| --- | --- | --- | --- |
| `object` of 3 × `int` | 24 | `f(o.a, o)` | compiles, prints `1` — `rv18` |
| `array[24, uint8]` | 24 | `f(o[0], o)` | compiles, prints `0` — `rv32` |
| `array[25, uint8]` | 25 | `f(o[0], o)` | `(5, 3) Error: mutable argument aliases with immutable parameter` — `rv33` |
| `object` of 4 × `int` | 32 | `g(o.a, o)` | refused — `rv19` |
| same 32-byte object, `{.bycopy.}` | 32 | `f(o.a, o)` | compiles, prints `1` — `rv37` |

`sizeof` ladder: `rv17` `24 32`, `rv41` `Plain 16 Wide 32` (`Plain(x, y: int)` is 16 bytes; `Named(x: int;
name: string)` is 24 but owns heap, which is why `a11` fails on the fourth branch, not on size).

`rv37` is the proof that this is the const-ref branch and not size alone: the only difference from `rv19` is
the `bycopy` pragma, and `passByConstRef` is exactly the function that reads it (`sizeof.nim:310-312`).

So the rule sentence has to become: **a by-value parameter blocks overlap with a mutable argument whenever it
reads the caller's storage — a view, `lent`, `varargs`, a value large enough to be passed by const reference
(over 24 bytes, unless `{.bycopy.}`), or any type that can own the heap.** The fourth branch is the one the
reader will meet most, but the third is what makes a four-`int` object behave differently from a three-`int`
one, and a reader who tries it will be confused by the current sentence.

Unmeasured, and therefore not for the text: whether the callee observes the mutation through a const-ref
parameter. The check fires before the call, so I could not run it. The mechanism says it would; I did not
prove it.

### 2. `ensureMove` does check last usage — "no use-after-move diagnostic" is true of `move` only

`grep -rn -i "use after move" src/ doc/ lib/` is empty, and `move` is the plain `func` you quote
(`system.nim:123-126`). But a last-usage analysis exists: `hexer/duplifier.nim:1573` is `trEnsureMove`, and
`:1611` raises `"not the last usage of: "`. `system.nim:120-121` declares `ensureMove` two lines above `move`,
and `doc/language.md:3591-3594` documents it as a static error when a move cannot be proven.

```
$ cat rv44.nim        # var a = "text"; let b = ensureMove(a); echo a
rv44.nim(4, 19) Error: not the last usage of: a

$ cat rv47.nim        # let n = eat(ensureMove(a)); echo a.len
rv47.nim(7, 23) Error: not the last usage of: a
```

So claim 35's sentence, "there is no use-after-move diagnostic", is too broad and a reader who reaches for
`ensureMove` — the name sitting right next to `move` in the same file — will find it false. Scope it: reading a
name after `move` compiles; reading it after `ensureMove` does not. The chapter's teaching (move is not
checked) survives; the absolute does not.

## Answers A-G

**A. The boundary is "reads the caller's storage", not "can reach the heap".** As a boundary it is honest and
stable at the pin, but your proxy sentence is narrower than the evidence: `passByConstRef` (24 bytes) refuses
plain data that touches no heap (`rv19`, `rv33`, `rv37`). Rewrite the sentence as in correction 1; after that it
is a rule you can cite, not a proxy, and "at this pin" is not needed.

**B. Documentation defect, not an example that lost a field.** `doc/language.md:2510-2517` uses `Obj(x, y:
int)`, which is 16 bytes with no heap field (`rv41`), and the pin compiles and prints `1` (`a12`, `d01`). The
manual's example is only correct with a heap field or past 24 bytes — one `string` field makes the identical
call fail (`a11`, `d02`). Rule row 73 as a doc defect.

**C. Yes, one sentence — the asymmetry is visible without inheritance being taught.** A 16-byte `object of
RootObj` is refused (`rv42`, `(9, 6)`) and a 16-byte variant object is refused (`rv10`, `(12, 6)`), while the
same 16-byte plain object compiles (`rv15`, `a12`). One sentence, no example: "an inherited or variant object
counts as heap-owning whatever its fields, deliberately — a derived value may own more
(`contracts_fir.nim:4328-4336`)."

**D. Not-yet, and the half sentence is worth adding — but the useful half is `ensureMove`, not a timetable.**
Move checking is partially here: the analysis is in `duplifier.nim`, `move` simply does not ask it. That is a
better sentence than "planned", because it is citable today and it tells the reader what to reach for.

**E. Right direction, rephrase as observation.** "`sink` is a shape the compiler accepts, not an operation it
verifies" reads as a claim about the compiler's intent. What you measured is: after passing `a` to a
`sink string`, `a` still prints `payload` with length 7 (`c06`, `rv40`), and a `sink seq[int]` leaves length 3
(`rv39`). Say that. **Open:** the mechanism — copy versus a move the caller does not observe — I could not
settle. `rv49` attaches instrumented `=copy` and `=wasMoved` to a type holding a `string` and passes it to a
`sink` parameter; neither hook printed, and the caller's value was intact. That is one probe and I do not trust
it enough to explain the mechanism, so do not add one.

**F. The error is on the mutable argument, and your Check 2 is already correct — the parenthetical in row 13 is
wrong.** `muts[i].info` (`:4276`) is the mutable argument's cursor, and the position lands on its field-access
dot: `a11` `(11, 9)` is the dot in `o.x` on line 11; `d02`/`rv46` `(10|16, 18)` is the dot in `named.x`;
reversing the argument order (`rv21`, `updateNamed(named, named.x)`) moves the error to `(9, 25)`, again the
dot in the mutable `named.x`. Nothing is reported at the immutable argument. `en.md:274-275` ("why the error
points at `plain.x`") is therefore right and needs no change; row 13's "(both at the immutable argument)" must
be struck.

**G. No hook is emitted for `int`; the generic magic only does work where a specialization exists.** The
generic `=wasMoved` is a magic (`system.nim:116`, `magics.nim:128`), rendered as a call (`renderer.nim:1640`)
that resolves to a specialization: `string` (`stringimpl.nim:296-297`, sets `bytes = 0`), `seq[T]`
(`seqimpl.nim:59-61`, `len = 0`, `data = nil`), and a handful of handle types (`asyncio.nim:63`,
`socket.nim:241/381/629`, `streamio.nim:196/389/553/579`). `int` has none, so the call does nothing. `rv23`
shows the shape exactly: `=wasMoved` on an `int` leaves `5`; on a `string` leaves `''`/len 0; on an object
holding a `seq` and an `int` empties the `seq` and leaves `n=9`. Your sentence is right; "the generic hook is a
magic that only acts through a type's specialization" is the version that will not need rewriting when a
specialization is added.

**Also ruled, the zeroedStorage sentence:** not in this chapter's scope and I have no run for it here. Keep it
out of Chapter 14; if it is worth saying, say it in 4 and 11 where the types are taught. `contracts_fir.nim`
is not the file that text was read from, so do not cite that line pair from a chapter you have not probed.

## Claim verdicts

Stands as written: 1-9, 11, 12, 14-34, 36-38. Notes on those: 4 gains evidence (`rv30`/`rv31` compile, `rv35`
`let b = a` on an `owned` value fails with `'=dup' is not available for type <owned ref Cell.Obj not nil>`,
`rv36` compiles — the `owned` contract at `doc/language.md:893-960` behaves as documented); 11 is correct and
the `typeIsBig` gate is a separate one, not a gap in the list; 24 stands, and the manual's shorter message is a
gap, not a defect.

Needs narrowing:

- **10** — true, and the rule sentence derived from it is not. See correction 1.
- **13** — the chapter is right, the note in the row is wrong: the error is reported at the **mutable**
  argument's field dot, never at the immutable one. See F.
- **35** — scope to `move`. `ensureMove` rejects a post-move read with `not the last usage of: a`
  (`rv44`, `rv47`, `duplifier.nim:1611`). See correction 2.

Nothing is left open except the `sink` mechanism in E, which the chapter does not need.

## ERRATA rulings

1. **Row 73 — documentation defect. Confirmed.** `doc/language.md:2507-2517` presents a 16-byte, heap-free
   `Obj` as an aliasing error; at the pin it compiles and prints `1` (`a12`, `d01`), and one `string` field
   makes the identical call fail (`a11`, `d02`). The repair is in the manual: use an object with a heap field
   or one above 24 bytes, or state the condition. Behaviour is correct, the example is not. Row status: open →
   **ruled, documentation defect**.
2. **Row 74 — documentation/message gap, not a defect. Confirmed as proposed.** `b05` prints
   `cannot borrow from b` and `b07` `cannot borrow from forward(x)`; behaviour matches `doc/language.md:2448-2468`,
   only the wording differs (`derefs.nim:468`). Row status: open → **ruled, gap, no code or doc change
   required**.
3. **Use-after-move — no new row, and the existing watch row gains one clause.** Extend the row's evidence with
   `c01`-`c05` as you proposed, and add: `ensureMove` is checked (`not the last usage of:`, `rv44`/`rv47`,
   `duplifier.nim:1611`). The row then reads "`move` leaves a valid empty value and is not checked;
   `ensureMove` is", which is the state of the compiler and not a claim about intent.

## What to change in `en.md` before it freezes

1. `68-74` and `96-98` — replace the rule sentence with the four-gate version, name the 24-byte const-ref
   threshold, and cite `passByConstRef` (`contracts_fir.nim:4348-4349`, `sizeof.nim:282-288`) beside
   `ownsNoHeap`. Add `rv18`/`rv32`/`rv33`/`rv19`/`rv37` as the size ladder.
2. After the rule, one sentence on inherited and variant objects (`:4328-4336`; `rv42`, `rv10`).
3. `208-209`, `223-225` — scope "no use-after-move diagnostic" to `move`, and add the `ensureMove` contrast
   with `system.nim:120-121`, `doc/language.md:3591-3594`, `duplifier.nim:1573/1611`, `rv44`/`rv47`.
4. `227-229` — state the `sink` observation (`c06`, `rv39`, `rv40`) instead of the intent sentence. Do not add
   a mechanism sentence.
5. `220-221` — "the generic hook is a magic that only acts through a type's specialization" (G).
6. Check 2 (`274-275`) — no change; it is correct. Check 1's answer key should name heap-reach **and** the
   const-ref size, since `seq` fails on the first and a 4-`int` object on the second.
7. Row 13's parenthetical in this file is the only place the immutable-argument reading appears; strike it
   there, not in the chapter.

`en.md`, `id.md` and the sample are untouched by me. Append only, as instructed.

## Definition of done, as it now stands

1. One job — yes.
2. Samples run — `13/13`, exit 0, mine and yours.
3. Technical review — this note; two content corrections and one ERRATA ruling.
4. Editorial pass — not yet.
5. Both languages — `id.md` waits for the corrected text.
6. Frozen — not until 1-6 above are in.

The chapter stays `drafting`. It is close: the corrections are two paragraphs and a sentence, and none of them
touch the chapter's structure or its sample.
