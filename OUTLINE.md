title: Nimony: A Pinned Guide
subtitle: Learning the language against one fixed commit
title decided: 2026-11-12 by the editor, on the owner's delegation; carried in `_quarto.yml` only, the preface heading stays "Nimony" in both editions
pin: nimony 0.6.3 @ commit 4ba90a781b0b22d0821efaa153c129c37cef6143 (2026-11-12)
pin decided: 2026-11-12 by Engineering (Momo, verified; Raka re-verified); book scope gated by Wira
pin source build: official Nim 2.4.0 tarball, sha256 93a1e638289077b972b684e6e71cb11b2029602ccac4f8fd8dfa70f193fac7df — never Homebrew Nim
samples run through: nimony c  (nimony n is NOT available at this pin and is out of scope)
language policy: id/en pair per chapter, en is the manuscript of record, id is the mirror; a chapter cannot freeze with one side missing. Heading rule (set 2026-11-12 by the owner's call): the `id.md` heading is the Indonesian title of that chapter, terms that read worse translated stay English; the `title:` frontmatter stays this file's English title in both files, so the two editions pair by one name; headings carry no hand-typed chapter number, the PDF takes it from the counter
reader: an experienced programmer who has never used Nimony — not a learn-to-program book, and not a sequel to nim-id

# Nimony Book Outline

This outline is the chapter sequence for a **standalone** book. Nothing in it assumes the reader has read
nim-id, and no chapter may refer to nim-id as a prerequisite. The reader arrives able to program in some
other language; the book teaches Nimony on its own terms.

Ordering rule: a chapter may only use concepts introduced in chapters listed as its prerequisites. Every
chapter carries the "Nim 2 delta" box where a Nim 2 habit actively misleads — never as the main path.

## What this book is not

- Not a Nim 2 book with a new cover: exceptions, closure iterators and `var T` indexing are gone or
  unimplemented, and macros survive only as compatibility surface. The book teaches the replacements, not the
  old forms.
- Not a compiler-internals book. NIF and the plugin model appear as *why the language behaves this way*,
  not as a tour of the passes.
- Not a second copy of `doc/language.md`. The book owns sequence and teaching order; the manual stays the
  reference.

## Part I — Orientation

### Chapter 1: What Nimony Is
- **Job:** Give the reader a working mental model — Nimony is the Nim 3 line, built on a NIF pipeline, with plugins instead of macros — so later rules read as design choices rather than surprises.
- **Prerequisites:** none
- **Nim 2 delta:** yes — Nimony is not a drop-in replacement.
- **Status:** frozen — draft 2026-11-12, tech_review Momo 2026-11-12, editorial_pass 2026-11-12

### Chapter 2: The Pinned Toolchain
- **Job:** Build the pinned commit from source with the official Nim 2.4.0 tarball, compile and run a first program with `nimony c`, and recognize why Homebrew Nim and `nimony n` are both dead ends here.
- **Prerequisites:** 1
- **Nim 2 delta:** no
- **Status:** frozen — draft 2026-11-12, tech_review Momo 2026-11-12, editorial_pass 2026-11-12;
  `id.md` written and dated in the same pass

## Part II — The Core Language

### Chapter 3: Values, Names, and Mutability
- **Job:** Introduce `let`, `var`, `const`, lexical scope, and the fact that names are case-sensitive.
- **Prerequisites:** 2
- **Nim 2 delta:** yes — case sensitivity and what `const` evaluates at.
- **Status:** frozen — draft 2026-11-12 (Aksara), tech_review Momo 2026-11-12 (11 claims: 6 PASS, 2 PASS as
  documented, 2 corrected, 1 rewritten for scope), editorial_pass 2026-11-12; `id.md` written in the same pass

### Chapter 4: Numbers, Types, and Conversion
- **Job:** Cover integers, floats, booleans, characters, ranges, and explicit conversion, including the fact that integer overflow wraps instead of raising.
- **Prerequisites:** 3
- **Nim 2 delta:** yes — overflow wraps; no `OverflowDefect` rescue.
- **Status:** frozen — draft 2026-11-12 (Aksara), tech_review Momo 2026-11-12 (14 claims: 13 PASS, three of
  them with citation fixes; 1 corrected — `toInt`/`toFloat` exist only for `Rational[T]`), editorial_pass
  2026-11-12; `id.md` written in the same pass; `samples/04-numbers-types-conversion/numbers.nim` passes

### Chapter 5: Strings
- **Job:** Treat `string` as an ordinary value with no null terminator: build, index, slice, and compare it, and know where `cstring` still appears.
- **Prerequisites:** 4
- **Nim 2 delta:** yes — no null terminator, so C-string habits break.
- **Status:** frozen — draft 2026-11-12 (Aksara); tech_review Momo 2026-11-12 (18/18 hold);
  editorial_pass 2026-11-12; `samples/05-strings/strings.nim` passes at the pin. Its review added the rune
  iterator (`std/unicode`, `runes`, `runeLen`) after the draft had assumed none existed.

### Chapter 6: Branching That Returns a Value
- **Job:** Use `if`, `case` and `when` as expressions, rely on exhaustive `case`, and label `break` because unlabelled `break` only leaves the innermost loop.
- **Prerequisites:** 4
- **Nim 2 delta:** yes — labelled `break` is required to leave an outer loop, and an `elif` after the `of` branches of a `case` is rejected (nest an `if` in `else`).
- **Status:** frozen 2026-11-12 — tech review by Momo 2026-11-12 (24 verdicts, 6 fixes applied), both editions
  written. `samples/06-branching/branching.nim` passes at the pin (`5/5`). One finding of record: a string
  `case` expression with no match **executes** the last `of` branch as its fallback — an unfixed defect, not a
  rule, and the reason the chapter requires `else` on every string `case` expression.

### Chapter 7: Loops and Ranges
- **Job:** Iterate ordinals with `for`, control repetition with `while` and `continue`, and prove a `range` only in the local form the compiler accepts.
- **Prerequisites:** 6
- **Nim 2 delta:** yes — a `range` proof must be visible where the value is used, written as two comparisons on
  a parameter; it does not travel into another routine (see ERRATA watch list).
- **Status:** frozen 2026-11-12; `en.md` and `id.md` written, 28 claims probed at the pin,
  `samples/07-loops-ranges/loops.nim` passes (`6/6` in the book verifier); tech review Momo 2026-11-12,
  editorial pass 2026-11-12. Review corrections: `countup`'s step is `Positive` while `countdown`'s is an
  unconstrained ordinal, and `n + 0` needs no new range proof — the offset has to clear the guard's bound.
  Four findings of record: the loop variable is writable and moves the counter (observation only), a stored
  `0..3` slice is not loop-iterable, an `in 0..9` guard does not prove a `range` on a parameter while two
  comparisons do, and a negative `countdown` step climbs instead of descending.

## Part III — Procedures and Data

### Chapter 8: Procedures, Parameters, and Results
- **Job:** Define `proc` and `func`, return through `result`, pass by `var` and `sink`, and use default and named arguments.
- **Prerequisites:** 7
- **Nim 2 delta:** no
- **Status:** frozen — draft 2026-11-12 (Aksara), tech review Momo 2026-11-12 (27 of 30 claims held, one corrected,
  two narrowed), editorial pass 2026-11-12. `samples/08-procedures/procedures.nim` passes (`7/7`). Five findings
  of record in `ERRATA.md`: a default that names an earlier parameter dies in the backend with `[Bug] could not
  find symbol: x.0` (defect candidate, to file), an `out` parameter may be read before it is written (the guide
  says it may not), a `proc` that touches a module-level `var` is rejected as unsynchronized access, the
  two-argument command form reports `invalid indentation` where the guide predicts `too many arguments`, and
  named arguments are undocumented.

### Chapter 9: Overloading and UFCS
- **Job:** Resolve overload sets by argument type, call either form with method-call syntax, and know what is no longer overloadable (`var T` for `[]`).
- **Prerequisites:** 8
- **Nim 2 delta:** yes — `var T` indexing overloads are removed. The removal is carried by two checks, not one: resolution has no `var`-ness dimension, so a `var T`/`T` pair is one ambiguity, and `validBorrowsFrom` decides where a `var` result may point.
- **Status:** frozen 2026-11-12 — draft 2026-11-12 (Aksara), tech review Momo 2026-11-12 (23 claims, 21 held, 1 wrong as generalised, 1 right in substance with a wrong detail; no claim left open), editorial pass 2026-11-12, 8/8 samples pass. `en.md` + `id.md`.

### Chapter 10: Arrays, Sequences, and Tuples
- **Job:** Choose between fixed-size `array`, growable `seq` and heterogeneous `tuple`, with their slicing and unpacking rules.
- **Prerequisites:** 8
- **Nim 2 delta:** no
- **Carries from 9:** the rule for a `var` accessor result — it needs a path it can borrow (`var`/`out`/`lent` parameter, or indirection such as a `seq` field), and an inline field of a by-value object is not one. Chapter 9 owns the rule; Chapter 10 points at it rather than restating it.
- **Status:** frozen 2026-11-12 — draft 2026-11-12 (Aksara); tech review Momo 2026-11-12 (32 claims: 27 held, 2
  half held — the observable half only, 3 wrong: `newSeq` wording, the mangled-suffix claim, the 21-line
  candidate count; no claim left open), 13 text corrections applied, editorial pass 2026-11-12, `9/9` samples
  pass. `en.md` + `id.md`. Rulings of record in `ERRATA.md`: different tuple field names are a documentation gap
  (`sigmatch.nim:2435`), `high` of an empty `seq` is `-1` by contract so that candidate was dropped, no sequence
  concatenation is a watch row, and a by-value `seq` parameter cannot be grown — a Nim 2 delta stated in the
  body, not as a delta box (Wira's call).

### Chapter 11: Objects, Enums, and Distinct Types
- **Job:** Model data with nominal `object` types, ordinal `enum` types and representation-sharing `distinct` types, and explain value copy at assignment.
- **Prerequisites:** 10
- **Nim 2 delta:** no — one inline box for `echo` and `$`; the outline flag stays "no"
- **Status:** **FROZEN 2026-11-12.** `en.md` final after 13 corrections from the tech review, `id.md` written from that final text, both `frozen`. Verifier 10/10 at pin `4ba90a7`; sample `samples/11-objects-enums-distinct/objects.nim`. Rulings of record in `ERRATA.md`: `echo` does not apply a user-defined `$` is documented (`doc/language.md:466-471`) and becomes the chapter's one delta box, enum values are not bounds-checked is a watch row (`contracts_fir.nim:2551-2569`), object `==` is `lib/std/system.nim:463` (documentation gap), explicit ordinals need not ascend at the pin (`rv11`, documentation gap). Further changes go to `ERRATA.md`, not to the chapter. Chapter 12 opens next; the borrow rule it shares with 9, 10 and 14 is already in `ERRATA.md`.

### Chapter 12: Sum Types and Exhaustive `case`
- **Job:** Express alternatives as variants and match the discriminator with an exhaustive `case`, preferring that over sentinel fields and flags.
- **Prerequisites:** 11
- **Nim 2 delta:** yes — this is the shape Nim 2 readers reach for `case` objects and inheritance to fake.
- **Proof gate:** **CLOSED 2026-11-12** (Momo, pin `4ba90a7`). A variant object with payload-carrying alternatives compiles and runs; omitting a variant from `case` is rejected with `not all cases are covered; missing: {Triangle}`. One correction to the gate as first written: there is no `match` construct at the pin (no `Match` tag in `src/models/nimony_tags.nim`), so the chapter says `case`, and the chapter title changed with it. A `match` chapter waits on the syntax — it is not promised as "later".
- **Status:** **FROZEN 2026-11-12.** `en.md` final after the tech review (34 of 36 claims held; the two wrong numbers were the inactive-branch read printing `1.0` and `sizeof(Shape)` being `32`), `id.md` written from that final text, both `frozen`. Verifier 11/11 at pin `4ba90a7`; sample `samples/12-sum-types-case/sumtypes.nim`. Rulings of record in `ERRATA.md`: no runtime branch check is intended by the union layout and stays a watch row; a name-spelled discriminator is constructor-only narrowness with a defective message (`doc/language.md:629-641` is the documentation gap); the `xelim` assertion is a missing diagnostic, filed as a low-priority defect candidate with repro `rv8`; the wrapped `illformed AST` line is message quality only and is not filed. Further changes go to `ERRATA.md`, not to the chapter.

## Part IV — Ownership and Failure

### Chapter 13: References, Pointers, and Explicit Nilability
- **Job:** Separate managed `ref` from raw `ptr`, write the nil-ability into the type (`nil ref T`), and dereference only after proving non-nil.
- **Prerequisites:** 12
- **Nim 2 delta:** yes — nilability is in the type, not a runtime surprise.
- **Proof gate:** **CLOSED 2026-11-12** (Momo, pin `4ba90a7`). `nil ref T` accepts `nil` and a not-nil `ref T`; a dereference under `if x != nil` runs; an unguarded one is rejected with `cannot prove expression is not nil: x`. Companion rule the probe hit and the chapter must teach: a module-level `var base: ref int` is rejected with "no default value (it contains a not-nil pointer)", while the same declaration inside a proc is legal once a write reaches it first.
- **Status:** **FROZEN 2026-11-13.** `en.md` final after the tech review (38 of 40 claims held; 27 was the one wrong claim and 28 needed scoping), `id.md` written from that final text, both `frozen`. Verifier 12/12 at pin `4ba90a7` (`samples/13-references-pointers-nil/refs.nim`). The chapter's Allocation section was rewritten: `new` takes `out T` for any `T: ref`, so a not-nil local is a legal destination (`rv26`, `rv34`); nullable-plus-guard is the sample's variant, not a requirement. Rulings of record in `ERRATA.md`: the `new` row is withdrawn as written (the chapter was wrong, not the compiler); field narrowing and unanalysed globals are current limitations, stated as such; the manual's `doc/lenientnils.md:92-98` example is a documentation defect (module-level, fails as `rv27`, while the same shape in a proc prints `42`). Reference equality is taught in one sentence with `src/nimony/magics.nim:64`. Further changes go to `ERRATA.md`, not to the chapter.

### Chapter 14: Ownership and Borrow Checking
- **Job:** Show who owns a value, which aliasing and escaping-borrow shapes the compiler rejects, and why `move` is not a checked operation at this pin.
- **Prerequisites:** 13
- **Nim 2 delta:** yes — the compiler rejects code Nim 2 accepted.
- **Carries from 9:** `validBorrowsFrom` (`src/nimony/derefs.nim:258-314`) is where the `var`-result rule lives; Chapter 9 states it, this chapter generalises it and cites the source.
- **Proof gate:** **PARTLY CLOSED 2026-11-12** (Momo, pin `4ba90a7`). Two rejections are proven verbatim: `mutable argument aliases with immutable parameter`, and `borrow of 'a' escapes the proc; it does not live long enough`. The gate's first half failed as written: a use-after-move is **not** rejected — `let b = move(a)` compiles and `a` reads as an empty string at runtime. The chapter teaches the two rules that exist; a "the compiler catches use-after-move" rule is never taught. Move-as-checked-operation stays open and is not promised.
- **Status:** **FROZEN 2026-11-13.** `en.md` final after the tech review (35 of 38 claims stood; 10 and 35 narrowed, 13 had a wrong note with a correct chapter text), `id.md` written from that final text, both `frozen`. Verifier 13/13 at pin `4ba90a7` (`samples/14-ownership-borrow/ownership.nim`). Two content corrections landed: the aliasing rule is the four conditions of `passedByPointer` (`src/nimony/contracts_fir.nim:4340-4351`) including the 24-byte `passByConstRef` branch (`src/nimony/sizeof.nim:282-288`, `:306-318`), and the move half is scoped — `move` is never diagnosed, `ensureMove` is (`not the last usage of:`, `src/hexer/duplifier.nim:1611`). Rulings of record in `ERRATA.md`: the manual's `doc/language.md:2507-2517` example is a documentation defect, `:2452-2462` is a message gap, and two watch rows (the inherited/variant blind spot at `:4328-4329`, and `ensureMove` refusing module-level names at `duplifier.nim:124-129`). The `sink` mechanism is not explained, only observed (`c06`, `rv39`, `rv40`). Further changes go to `ERRATA.md`, not to the chapter.

### Chapter 15: Errors as Values
- **Job:** Report failure with `ErrorCode`, `{.raises.}` and `except ErrorCode`, and explain why there is no exception object to catch.
- **Prerequisites:** 8, 13
- **Nim 2 delta:** yes — no `raise`/`try`/`except` exception hierarchy.
- **Proof gate:** **CLOSED 2026-11-12** (Momo, pin `4ba90a7`). An `ErrorCode`-returning proc, a `{.raises.}` proc, `except ErrorCode as e` and the no-raise path compile and run; calling a `{.raises.}` proc outside `try` is rejected with `cannot call a routine marked as `.raises` outside of a `try`..`except` block`.
- **Status:** frozen 2026-11-13 — draft 2026-11-13 (Aksara), tech_review Momo 2026-11-13 (42/42 claims stand,
  no open claim; two sentence-level corrections: the `porting.md` construction row is the Nim 2 column and only
  row `:106` is wrong, and the `ref`-arm escape has a cause in `emitDispatcher`), editorial_pass 2026-11-13;
  `id.md` written in the same pass; sample `samples/15-errors-as-values/errors.nim` passes 14/14 at `4ba90a7`.
  Three ERRATA rows added: catch shape (documentation defect, one row), two bound `except ErrorCode as` arms
  (compiler defect, repro `mc2`), `canraise` (defect candidate plus documentation gap)

## Part V — Scale

### Chapter 16: Modules and Visibility
- **Job:** Split a program across files, mark what leaves a module with `*`, and import selectively.
- **Prerequisites:** 8
- **Nim 2 delta:** no
- **Status:** frozen 2026-11-13 — draft 2026-11-13 (Aksara), tech_review Momo 2026-11-13 (48 of 50 claims
  stand; #37 and #42 corrected, none open), editorial_pass 2026-11-13; `id.md` written from that final text;
  sample `samples/16-modules-visibility/modules.nim` (four files under `support/`) passes 15/15 at `4ba90a7`.
  Two content corrections landed: an `export` operand that is not a name spins the front end with no diagnostic
  (minimal repro `export 3`, not the path as such), and the shared-global check is syntactic — "refused" holds for
  a direct write, and a `let` pointer to the global escapes it. Two prose corrections: `.sync` is a real fourth
  route through a `var` parameter (including your own proc), and a one-sided `from` does not settle an ambiguity
  while the other side is a plain import. ERRATA: import-in-a-proc is a documentation defect, the `export`
  operand is a compiler defect, the missing-module message is a gap, and the alias escape is a watch row.

### Chapter 17: Generics and Concepts
- **Job:** Parameterize routines, types and constraints that are checked structurally, using concepts instead of implicit type-class generics.
- **Prerequisites:** 12, 16
- **Nim 2 delta:** yes — implicit generics through type classes are not available.
- **Proof gate:** **CLOSED 2026-11-12** (Momo, pin `4ba90a7`). A concept constrains a generic proc and the conforming call runs; a non-conforming type is rejected naming the type, the constraint and where it was declared (`NoAdd does not match constraint Addable (declared in …)`). Do not promise the `missing: proc …` detail for every failure — this shape does not print it.
- **Status:** **FROZEN 2026-11-13.** `en.md` final after the tech review (24 of 30 claims stood; 4, 15, 18 and 19
  corrected, 17 and 24 narrowed, and the `[N]` sentence rewritten), `id.md` written from that final text, both
  `frozen`. Verifier 17/17 at pin `4ba90a7` (`samples/17-generics-concepts/generics.nim`; 17 because Chapter 18's
  sample is already in the folder). Two content corrections landed: `Box(v: 3)` builds, so the field does tell `T`,
  and the manual's `proc find[T](x: Findable[T]; elem: T)` is refused at its definition, not at the call. Rulings of
  record in `ERRATA.md`: `doc/language.md:4477-4499` (the `var T` restriction) and `:4472` (`process` is never
  declared) are documentation defects, a concept in a plain parameter position is a compiler defect
  (`src/nimony/sigmatch.nim:1825-1827` matches it on purpose, `g24` asserts in the backend), and `:4324`
  (`var Self`) is a watch row because the qualifier is not enforced at satisfaction. Further changes go to
  `ERRATA.md`, not to the chapter.

### Chapter 18: Templates and Compile-Time Evaluation
- **Job:** Remove repetition with hygienic templates and evaluate work at compile time with `const`.
- **Prerequisites:** 17
- **Nim 2 delta:** yes — templates are the supported repetition tool; `macro` still compiles at this pin but
  is compatibility surface, not a technique the book teaches.
- **Proof gate:** **CLOSED 2026-11-13** (Momo, pin `4ba90a7`). `const Nine = square(3)` folds to `9`, a `for` with
  an `if` folds to `30`, recursion folds to `120`, and `const Overflow = 127'i8 + 1'i8` is refused with
  `expression overflow at compile time`. The evaluator does not fold `.len` of a seq reached through a named `const`;
  do not promise a bounds error for an out-of-range constant index, it reports cannot-evaluate.
- **Status:** **FROZEN 2026-11-13.** `en.md` final after the tech review (42 of 45 claims stood; 14 and 19
  corrected, 41 narrowed), `id.md` written from that final text, both `frozen`. Verifier 17/17 at pin `4ba90a7`
  (`samples/18-templates-compiletime/templates.nim`). Three prose passages changed with the verdict: `{.dirty.}` is
  inert without `{.feature: "untyped".}` and then injects in both directions (`semdecls.nim:1183`), `varargs[untyped]`
  is accepted and unreadable rather than refusing every use, and a routine that is folded does run its effects, so a
  `writeFile` writes during compilation. Rulings of record in `ERRATA.md`: `doc/language.md:4566-4583` (the `untyped`
  block example) and `doc/porting.md:255-262` (the quoted bare-call message) are documentation defects, a `typed`
  template parameter is a compiler defect (`typedSlot(notDeclared)` builds; `m21` is the repro), and `{.dirty.}` is a
  watch row. Further changes go to `ERRATA.md`, not to the chapter.

### Chapter 19: Plugins and the NIF Pipeline
- **Job:** Replace the macro habit with plugins that operate on NIF, and explain what NIF buys in incremental and parallel builds.
- **Prerequisites:** 18
- **Nim 2 delta:** yes — the design replaces macros with plugins; a `macro` that still compiles at this pin is
  compatibility surface, not the sanctioned route.
- **Proof gate:** **CLOSED 2026-11-12** (Momo, pin `4ba90a7`), both halves. A `typed` parameter receives semantically checked, lowered NIF — `a + 1` arrives as `(add (i 64)a.0.… 1)` with the operand already resolved to a symbol carrying its type — and the plugin's output replaces the call in the compiled program. An `untyped` parameter receives raw syntax before name resolution: a node containing an undeclared identifier compiles.
- **Status:** **FROZEN 2026-11-13.** `en.md` final after the tech review (29 of 33 claims stood, three of those with a
  corrected citation; four corrected), `id.md` written from that final text, both `frozen`. Verifier 18/18 at pin
  `4ba90a7` (`samples/19-plugins-nif/plugins.nim`). Four passages changed with the verdict: a for-loop plugin's
  variable is typed from the iterator's declared yield type and the body is transformable when one is declared, the
  plugin executable lands in the running build's nimcache rather than the declaring module's, `errorTree` works
  nested inside a builder (the assert was `tagText` on a symbol), and the arithmetic tags take a type node as slot 0
  before the two operands. Rulings of record in `ERRATA.md`: `doc/plugins.md:8-20` (the for-loop row) and
  `doc/plugins.md:673-678` ("and nothing else") are documentation defects, the missing-plugin message is a gap row,
  and the `.nim`-extension candidate is withdrawn (`splitFile` strips it). Further changes go to `ERRATA.md`, not to
  the chapter.

## Part VI — Programs

### Chapter 20: The Standard Library You Can Rely On
- **Job:** Tour only the modules proven at the pin (`syncio`, `strutils`, sequence helpers from `system` and `sequtils`, `tables`, `sets`, `atomics`) and state the rule for using any other.
- **Prerequisites:** 16
- **Nim 2 delta:** yes — `std/strformat` and `std/re` are absent at the pin, `&` is string-only, and an atomic is
  an operation on a plain `var`, not a wrapper type. Changed from "no" 2026-11-13 by the editor: the chapter's job
  is to say what a Nim 2 reader may rely on, and these three are exactly the habits that mislead.
- **Status:** frozen 2026-11-13 — draft 2026-11-13 (Aksara), 65 claims probed at the pin, tech review by Momo the
  same day (59 stood, 2 stood with a source-line fix, 2 narrowed, 2 paragraphs rewritten, zero open). Momo re-ran
  the verifier himself: `19/19 passed` at `4ba90a7`, sample output 26 lines byte-identical. Corrections in the
  text: iteration order at the pin is insertion order (with the guide still silent on it), `Keyable` also requires
  `==`, `HashSet` wraps rather than is a `Table[T, bool]`, `std/json` reads through `tree{"a"}` not `[]`, the
  `echo` overload set is the module default because a declared `write` overload is found, and atomics lower to
  `__atomic_*` builtins. `id.md` written from the final text. ERRATA rows: `strtabs` `See also`, the missing
  `json` section, and `getOrQuit`.

### Chapter 21: Files, Processes, and the Outside World
- **Job:** Read and write files, read arguments and environment, return exit codes, and run a subprocess.
- **Prerequisites:** 20
- **Nim 2 delta:** yes — at the pin `removeFile` is not in `std/os` any more but in `std/files` and takes a
  `Path`, while `fileExists` still takes a `string`; `quit(msg)` writes to stdout where Nim 2.4.0 writes
  stderr; a Nim 2 file program compiles in half its lines.
- **Status:** frozen 2026-11-13 — draft 2026-11-13 (Aksara), 52 claims probed at the pin, tech review by Momo
  the same day (44 stood as written, 5 stood with a source-line fix, 3 narrowed, zero open). Momo re-ran the
  verifier himself: `20/20 passed` at `4ba90a7`, sample output 16 lines byte-identical. Corrections in the
  text: `removeFile` still ignores a missing file, so the delta is the module and the type, not the tolerance;
  `quit(msg)` writes to stdout at the pin while `doc/stdlib.md:232` and Nim 2.4.0 say stderr;
  `createTempFile` returns an open handle the caller must close and a path the caller must remove;
  `execShellCmd` is the one routine that reports a launch failure as `-1`; and the `execProcess` defaults are
  the Nim 2 defaults, so the cancelled ERRATA row was withdrawn rather than filed. `id.md` written from the
  final text. ERRATA rows: the `open`-returns-`File` docstring, the missing `files` section in the guide, and
  `quit(msg)`'s stream.

### Chapter 22: The C Boundary
- **Job:** Bind a C function, map its types, and cross the `cstring` boundary deliberately.
- **Prerequisites:** 13, 20
- **Nim 2 delta:** yes — only a string literal converts to `cstring` (`toCString` for a `var`), `$` for `cstring`
  comes from `std/strutils`, there is no `allocCStringArray`, and `ptr`/`pointer`/`cstring` are non-null unless
  the type is written `nil cstring`.
- **Status:** frozen 2026-11-13 — draft 2026-11-13 (Aksara), 48 claims probed at the pin, tech review by Momo
  the same day (42 stood as written, 3 cited the wrong line, 3 corrected, zero open). Momo re-ran the verifier
  himself: `21/21 passed` at `4ba90a7`, sample output 11 lines byte-identical. Corrections in the text: `header`
  is not what puts a prototype in front of C, Nimony writes one itself and the header supplies the real
  declaration (proof: `major` prints `0` with `<sys/types.h>`, and fails to link with an undefined `_major`
  without it); the `sizeof(struct stat)` failure is the C compiler's, with a header, and a link error without
  one; declaring `array[2, cstring]` is refused before any assignment, and `isNil(slots[0])` fails the way
  `!= nil` does. `id.md` written from the final text. ERRATA rows: the raw `cstring` literal gap, the
  conversion example at `doc/language.md:332-341` the pin refuses, and a watch row for the callback `const`
  split (Nim 2 fails identically). The two findings that shape the chapter: `cstring"…"` is a generalized
  literal and therefore raw (`cstring"a\nb"` is four bytes, `"a\nb"` is three, `p17`), and a callback's `void*`
  parameters are emitted without C's `const`, so `qsort` is refused by clang until the proc is cast through
  `pointer` (`p05`, `p11`).

### Chapter 23: Testing and the Sample Verifier
- **Job:** Write checks that run under the pin and use the book's sample verifier so a chapter's claims stay reproducible.
- **Prerequisites:** 20
- **Nim 2 delta:** yes — `assert` is in `std/assertions` not `system`, `doAssert` and `static:` are absent,
  `std/unittest` does not exist, and a mutable global touched inside a routine needs a `var`/`ptr` parameter, an
  `{.cast(assumeSync).}:` block, or a `{.feature: "assumeSync".}` module; declaring the routine `{.sync.}` is not
  enough.
- **Status:** **frozen 2026-11-13** (Momo's verdict in `chapters/23-testing/review.md`; 24 claims stand, four
  citations fixed, two text changes, none open; verifier `23/23`, four output lines byte-identical). Draft
  2026-11-13 (Aksara), 30 claims probed at the pin. The findings that shape the chapter: `assert` needs
  `import std / [assertions]` because it is not in `system` (a01), a routine may not touch a mutable module-level
  variable by name, and `{.sync.}` on the routine does not lift that — a `var`/`ptr` parameter or an
  `{.cast(assumeSync).}:` block does (b10, s1, s2), and `nimony c -r` flattens a non-zero child exit to `1` while
  the binary keeps the real code (e01). `{.assert: cond.}` works as a statement in a body, but only when the prover
  can discharge the claim — a third correction, 2026-11-13, after Momo's whole-book audit found
  `{.assert: x mod 2 == 0.}` failing `cannot prove assertion` in a body — and crashes the compiler only in the
  routine-pragma position (v2, v4) — a compiler defect to file, not a documentation erratum. `id.md` written from
  the final text.

### Chapter 24: Passive Procs and Concurrency
- **Job:** Suspend and resume work with passive procs, the single mechanism standing in for both async and threaded procedures, and state the scheduling limit instead of implying parallelism.
- **Prerequisites:** 14, 20
- **Nim 2 delta:** yes — no separate `async`/`thread` split.
- **Proof gate:** **CLOSED 2026-11-12 with a limit** (Momo, pin `4ba90a7`). Two `.passive` procs each start, `suspend()` and run past it to their end, driven by a third passive proc using `delay`/`complete`, with no `async` or `await` in the source. **Not proven: interleaving.** `complete` runs a chain to completion on the default `trivialTick` scheduler, so A finishes before B starts. The chapter teaches suspension and resume and never promises concurrency; an interleaving claim waits on a `std/threadpool` `submit(delay(...))` sample.
- **Status:** **frozen 2026-11-13** (Momo's verdict in `chapters/24-passive-procs/review.md`; 43 claims stand,
  26 narrowed to "does not guarantee overlap", none open; verifier `23/23`, ten output lines byte-identical).
  Draft 2026-11-13 (Aksara), 43 claims probed at the pin. The findings that shape the chapter: `complete` on a
  coroutine that parks never returns (`p05`), a `delay()` with no following `suspend()` kills the compiler with a
  `cps.nim:269` assertion while a bare `suspend()` is silently a synchronous transition (`p09`, `p10`), and
  `delay` refuses both a `var` parameter and a callee that returns a value (`p14`, `p12`). Interleaving is the
  driver's decision; two tasks that block do overlap, so the chapter says "no guarantee" rather than "never"
  (`e1`, `p20`). `id.md` written from the final text.

## Back matter

- **Appendix A — Nim 2 to Nimony delta table:** one consolidated table of everything removed or changed at the pin, each row citing `doc/differences.md` or a Nimony source file. **FROZEN 2026-11-13** — `chapters/a1-nim2-delta-table/{en,id}.md`; assembled only from Chapters 3-24, so it adds no claim and needs no new technical review; the rows it deliberately omits are named in its last section.
- **Appendix B — Sample verification record:** the exact command, pin, and output format every chapter must reproduce. **FROZEN 2026-11-13** — `chapters/a2-sample-verification-record/{en,id}.md`; carries the `23/23 passed` run of 2026-11-13 verbatim and the chapter-to-sample map.
- **Appendix C — Errata index:** pointer to `ERRATA.md`. **FROZEN 2026-11-13** — `chapters/a3-errata-index/{en,id}.md`; restates the errata rule, the three parts of `ERRATA.md`, and the one filed upstream defect (`nim-lang/nimony#2985`, fix in `#2988`).

The three appendices live under `chapters/aN-slug/` so the bilingual staging in `tools/build-site.sh` treats them like a chapter pair; they are listed under `book.appendices` in `_quarto.yml`, so the PDF letters them A, B, C and never numbers them as chapters 25-27.

## Rules the outline enforces

1. One job per chapter; a chapter that needs a second job gets split, not stretched.
2. No chapter text refers to nim-id, and no chapter requires it.
3. Every compiler or language claim cites a Nimony source file or commit, and passes `tech_review`.
4. Every code sample compiles and runs at the pinned commit through `nimony c`; `nimony n` never appears as an instruction.
5. A term used with a special meaning is in `GLOSSARY.md` in the same handoff that introduces it. Retired Nim 2 terms stay listed and marked.
6. A frozen chapter is never rewritten for a newer pin; the break goes to `ERRATA.md`.
7. Design intent is not pin behaviour. A chapter whose core job rests on a feature never demonstrated at
   `nimony_commit` stays `planned` and carries a **Proof gate** line; the gate closes only when Engineering
   records the run that proves it, with the verdict and date written into that line.
8. A gate that fails as written is rewritten to what the pin actually does, and the chapter's **Job** changes
   with it — a failed half is never dropped silently and never softened to "coming later". The failed half goes
   to `ERRATA.md` by name. Two gates failed in part on 2026-11-12 (`match`, use-after-move); both are rewritten
   above.
9. Every sample is proven by `tools/verify-samples.sh` at the fixed install path
   (`$NIMONY_HOME`, default `~/.local/opt/nimony/4ba90a7`), never by a toolchain under a temp directory.

## Open questions

1. **Coverage of compiler internals:** whether NIF gets a chapter of its own later (currently folded into Chapter 19 as motivation, not internals). Owner: Wira / Damar.
2. **`unittest` at the pin:** **closed 2026-11-13.** `lib/std/` carries no `unittest.nim` and `import std / [unittest]` fails in the parser (probe `a09`, `b06`); Chapter 23 teaches an assert-and-exit-code harness.
3. **Stdlib surface:** the module list can only grow with a verified sample at the pin, never from Nim 2 documentation.
4. **id/en pair:** the policy above follows nim-id's baseline; if the owner later wants English-only, that is a dated decision in this file, not a silent drift.
