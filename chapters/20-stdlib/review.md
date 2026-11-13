# Chapter 20 review note — The Standard Library You Can Rely On

Status: `drafting`. Reviewer: **Momo**. This note is the claim table, the open questions and the errata
candidates. Append your verdict at end of file; do not edit the table rows in place.

Pin for every run below: `4ba90a781b0b22d0821efaa153c129c37cef6143` (nimony 0.6.3), install
`~/.local/opt/nimony/4ba90a7`. Probe sources: `ch20-probes/` in the authoring workspace
(`probes/ch20/`), one directory per
probe, each run as `~/.local/opt/nimony/4ba90a7/bin/nimony c -r main.nim` from inside the probe directory.
Host comparisons (`nim2/n2`, `nim2/n3`) were compiled with `~/.local/opt/nim-2.4.0/bin/nim c -r --hints:off`.

Verifier already run by the editor, from the repository root:

```
toolchain ~/.local/opt/nimony/4ba90a7/bin/nimony 0.6.3 pin 4ba90a7
PASS samples/20-stdlib/stdlib.nim exit=0
SUMMARY 19/19 passed, 0 failed
```

Sample output, byte-identical to the block in `en.md` section Samples:

```
42
not a number: 4x
-1
2
tea
2
tea and coffee
---
4
2 2
3 9
2 2
3
2 6
2
9
false
2
missing: milk
0
2
true
true
false
2
10
```

## Claims

| # | Claim (as written in `en.md`) | Probe | Raw output | Source line |
| --- | --- | --- | --- | --- |
| 1 | A module's file existing is not permission to use it; only a run is. | policy, exercised by every probe below | — | `CHAPTER_TEMPLATE.md` "Claim provenance" |
| 2 | The two-line `deques` probe prints `1`. | `q16` | `1`, exit 0 | probe |
| 3 | `std/strformat` is refused at the import with `file not found`. | `i07-strformat` | `main.nim(2, 1) Error: file not found: …/src/lib/std/strformat.nim`, exit 1 | probe |
| 4 | `std/re` is refused the same way. | `i16-re` | `main.nim(2, 1) Error: file not found: …/src/lib/std/re.nim`, exit 1 | probe |
| 5 | `std/seqs` is refused the same way at the pin. | `i06-seqs` | `main.nim(2, 1) Error: file not found: …/src/lib/std/seqs.nim`, exit 1 | probe |
| 6 | `std/cookies` is refused the same way. | `i32` | `main.nim(1, 1) Error: file not found: …/src/lib/std/cookies.nim`, exit 1 | probe |
| 7 | Nim 2.4.0 also has no `std/seqs`: `cannot open file: std/seqs`. | `nim2/n1` | `n1.nim(1, 11) Error: cannot open file: std/seqs`, exit 1 | host compiler |
| 8 | Nim 2.4.0 does have `std/strformat` and `std/re`: `fmt"a{1 + 1}"` prints `a2`, a regex match prints `true`. | `nim2/n2` | `a2` / `true` / `5`, exit 0 | host compiler |
| 9 | `echo` is a `varargs` template that forwards each argument to `write` and then writes a newline. | doc read | `for x in unpack(): write stdout, x` then `write stdout, '\n'` | `lib/std/syncio.nim:465-469` |
| 10 | The `write` overload set is `string`, `bool`, `int64`, `int32`, `uint64`, `uint32`, `T: enum`, `char`, `float`. | doc read | nine overloads, no generic one | `lib/std/syncio.nim:293-331` |
| 11 | `echo @[1, 2]` is an error listing the whole overload set. | `e01` | `expected: string but got: seq[int64]`, `expected: bool but got: seq[int64]`, … at `syncio.nim(468, 5)` | `lib/std/syncio.nim:468` |
| 12 | `echo` of an object of your own fails the same way. | `e02` | `expected: string but got: Point`, … `Point does not match constraint T` | `lib/std/syncio.nim:468` |
| 13 | `write` writes without a newline; `writeLine(f, s)` writes the string and a newline. | doc read | `proc writeLine*(f: File; s: string)` body writes `s` then `'\n'` | `lib/std/syncio.nim:471-475` |
| 14 | `quit` does not return. | doc read | `proc quit*(value: int) {.noreturn.}` | `lib/std/syncio.nim:538` |
| 15 | `readLine(f, s: var string): bool` returns whether a line was read; `readLine(f): string` is `{.raises.}`. | doc read | two declarations | `lib/std/syncio.nim:506`, `:511` |
| 16 | `strutils` is ASCII-focused by its own description. | doc read | module header | `lib/std/strutils.nim:1-5` |
| 17 | `split` defaults to splitting on any whitespace character and takes `maxsplit`. | `q15` | `"a b c".split.len` → `3`; `split(" ")` → `3` | `lib/std/strutils.nim:405` |
| 18 | `split` has `set[char]`, `char` and `string` separator overloads. | doc read | three declarations | `lib/std/strutils.nim:405`, `:409`, `:413` |
| 19 | `strip` trims whitespace unless characters are named. | `s01` | `"  pad  ".strip` → `pad` | `lib/std/strutils.nim:1593` |
| 20 | `join` takes any `openArray[string]` and defaults to an empty separator. | `sample` | `["tea", "coffee"].join(" and ")` → `tea and coffee` | `lib/std/strutils.nim:489` |
| 21 | `parseInt` is `{.raises.}` and is refused outside `try`. | `s02`, `s03` | `main.nim(3, 17) Error: cannot call a routine marked as `.raises` outside of a `try`..`except` block` | `lib/std/strutils.nim:1733` |
| 22 | `%` is `{.raises.}` and is refused outside `try`. | `s05` (first run) | `main.nim(3, 18) Error: cannot call a routine marked as `.raises` …` | `lib/std/strutils.nim:1474` |
| 23 | `format` is `{.raises.}` too. | doc read | `func format*(formatstr: string; a: openArray[string]): string {.raises.}` | `lib/std/strutils.nim:1588` |
| 24 | Inside `try`, `parseInt("42")` returns `42` and `parseInt("abc")` is caught as `ErrorCode`. | `s04` | `42` / `bad input: abc` / `0` | `lib/std/strutils.nim:1733` |
| 25 | Inside `try`, `"$1 and $2" % [a, b]` produces `tea and tea` for two identical arguments. | `s05` | `tea and tea` / `tea and tea` | probe |
| 26 | `ErrorCode` needs no import: it is included into `system` from a fragment. | `s01`, `t01`, `h01` compile with no error-codes import | — | `lib/std/system.nim:256` |
| 27 | `KeyError` is a member of `ErrorCode`. | `t01`, `s04` catch a table read with `except ErrorCode` | `missing: coffee` / `-1` | `lib/std/errorcodes/errorcodes.nim:18` |
| 28 | There is no `std/errorcodes` module; importing it fails. | `i31` | `main.nim(1, 1) Error: file not found: …/src/lib/std/errorcodes.nim` | probe |
| 29 | `add(s, elem)` appends. | `y02` | `@[1, 2, 3]` + `add(4)` → `4` | `lib/std/system/seqimpl.nim:213` |
| 30 | `setLen` resizes and requires an element type with a default. | `y02` | `setLen(2)` → `2` | `lib/std/system/seqimpl.nim:337` |
| 31 | `delete(s, idx)` removes one element and is in `system`. | `y02` | `delete(0)` → len `1`, `xs[0]` is `2` | `lib/std/system/seqimpl.nim:370` |
| 32 | `sequtils` carries `map`, `filter`, `keepIf`, `apply`, `all`, `any`, `count`, `deduplicate`, `minIndex`, `maxIndex`, `cycle`, `zip`, `unzip`, `minmax`. | doc read + `q01`, `q02`, `y04` | `map` → `28` and `2`; `cycle(2).len` → `4`; `zip(...).len` → `2`; `deduplicate.len` → `2` | `lib/std/sequtils.nim:80`, `:89`, `:98`, `:131`, `:111`, `:121`, `:35`, `:46`, `:64`, `:72`, `:142`, `:151`, `:161`, `:174` |
| 33 | The range form `delete(s, first, last)` is in `sequtils`, not `system`. | `y03` | `delete(0, 0)` → `1 3` | `lib/std/sequtils.nim:189` |
| 34 | `insert(dest, src, pos = 0)` is in `sequtils`, and `insert` is undeclared without it. | `y03`, `y01` | `y03`: `insert(@[0], 0)` → `0 4`; `y01`: `Error: undeclared identifier: 'insert'` | `lib/std/sequtils.nim:210` |
| 35 | `&` exists for `string` and `string`/`char` combinations only; `xs & ys` is a type mismatch. | `y01` | `expected: string but got: seq[int64]` (three candidates) | `lib/std/system/stringimpl.nim:1034`, `:1062`, `:1063` |
| 36 | The sequence equivalent of `&` is `concat(a, b)`. | `y03` | `concat(@[1], @[2, 3]).len` → `3` | `lib/std/sequtils.nim:27` |
| 37 | `map` and `filter` take a routine value; `doubled[2]` is `6` and `even.len` is `2`. | `q01` | `28` / `2` (sample form: `2 6` / `2`) | `lib/std/sequtils.nim:80`, `:89` |
| 38 | `mapIt`/`it` exist as well. | `q02` | `xs.mapIt(it * 3).len` → `3` | `lib/std/sequtils.nim` template section |
| 39 | `initTable[K, V]()` creates an empty table. | `t02`, `z01` | `tea=2`, `coffee=7`, `water=1` | `lib/std/tables.nim:243` |
| 40 | `t[k] = v` stores and overwrites and is not `{.raises.}`. | `t01` | stores then sums without a `try` | `lib/std/tables.nim:158` |
| 41 | Reading `t[k]` is `{.raises.}` and raises `KeyError`; outside `try` it is a compile error. | `t01` (first run) | `main.nim(5, 17) Error: cannot call a routine marked as `.raises` outside of a `try`..`except` block` | `lib/std/tables.nim:110-114` |
| 42 | `hasKey` and `contains` answer without raising. | `t01` | `counts.hasKey("coffee")` → `false` | `lib/std/tables.nim:82`, `:78` |
| 43 | `getOrDefault(t, k, fallback)` answers with the fallback; the one-argument form needs `HasDefault`. | `t01` | `getOrDefault("milk", 0)` → `0` | `lib/std/tables.nim:93`, `:86` |
| 44 | `getOrQuit` ends the program after an `assert`. | doc read | `raiseAssert "key not found"` | `lib/std/tables.nim:101-107` |
| 45 | Iteration is `pairs`/`keys`/`values`/`mpairs`/`mvalues`. | `t02` | `tea=2`, `coffee=7`, `water=1` | `lib/std/tables.nim:189-209` |
| 46 | Iteration order is not part of the contract, and `initOrderedTable` is `initTable` inline. | doc read + `t02` | `t02` printed insertion order for three keys; the ordered variant is `{.inline.} = initTable[K, V]()` | `lib/std/tables.nim:258` |
| 47 | `Keyable` is declared `concept of Hashable`, and `Hashable` lives in `std/hashes`. | doc read | `Keyable* = concept of Hashable` | `lib/std/tables.nim:6`; `lib/std/hashes.nim:13` |
| 48 | A `seq[int]` is a legal table key. | `z01` | `t[@[1, 2]] = "pair"` → `t.len` is `1` | `lib/std/tables.nim:6` |
| 49 | `HashSet[T]` is a `Table[T, bool]`, so the same key rules apply. | doc read | `HashSet*[T: Keyable] = object ## … (implemented as Table[T, bool])` | `lib/std/sets.nim:5` |
| 50 | The set surface is `initHashSet`, `incl`, `excl`, `contains`, `len`, `clear`, `intersection`, `containsOrIncl`, `missingOrExcl`. | `h01` | `2` / `true` / `false` / `1` | `lib/std/sets.nim:8`, `:12`, `:16`, `:24`, `:46`, `:20`, `:61`, `:28`, `:34` |
| 51 | `containsOrIncl` returns true if the element was already present, inserting otherwise; `missingOrExcl` returns true if it was missing, removing otherwise. | sample + doc read | sample prints `true` for `milk` (present) and `false` for `sugar` (added) | `lib/std/sets.nim:28-39` |
| 52 | A duplicate `incl` changes nothing. | `h01` | `incl("a")` twice with `incl("b")` → len `2` | `lib/std/sets.nim:12` |
| 53 | `set[char]` is a bitset over the character range in `system`; `strutils` takes `set[char]` for `split`/`strip`. | doc read | `split(s; seps: set[char] = Whitespace; …)` | `lib/std/strutils.nim:405`, `:1593` |
| 54 | Nimony has no `Atomic[T]` wrapper; atomics are operations on an ordinary `var`. | doc read + `a01` | module header: "Atomics are operations, not type properties" | `lib/std/atomics.nim:1-4` |
| 55 | `atomicFetchAdd`/`atomicLoad`/`atomicStore`/`atomicExchange`/`atomicCompareExchange` take a `var T` and a memory order defaulting to `moSequentiallyConsistent`. | `a01` | `0`, `1`, `2`, `10`, `true`, `11` | `lib/std/atomics.nim:49-52`, `:83` |
| 56 | The six memory orders are the C ones. | doc read | `moRelaxed` … `moSequentiallyConsistent` | `lib/std/atomics.nim:6-12` |
| 57 | The constraint is `Trivial`; a `string` is refused at the call. | `z02` | `string does not match constraint T (declared in …/atomics.nim(49, 1))` | `lib/std/atomics.nim:12` |
| 58 | `AtomicFlag` exists as a distinct `bool`. | doc read | `AtomicFlag* = distinct bool` | `lib/std/atomics.nim:14` |
| 59 | Nimony has no `Atomic[int]`: the wrapper type is an undeclared identifier. | `a02` | `main.nim(3, 14) Error: undeclared identifier: Atomic`; then `undeclared identifier: 'store'` | `lib/std/atomics.nim:1-4` |
| 60 | `std/json` imports and `parseJson` accepts a string, but indexing the result does not resolve. | `j01` | `node["a"]` → `JsonTree does not match constraint T` plus candidate list | `lib/std/json.nim` |
| 61 | `std/deques`, `heapqueue`, `intsets`, `algorithm`, `math`, `hashes`, `random`, `times`, `streams` each pass an import and at least one action. | `d01`, `q11`, `q12`, `m01`, `x01`, `r01`, `i20-streams`+`q13` | `d01`: `2`/`0`/`1`; `q11`: `1`/`2`; `q12`: `2`/`true`; `m01`: `13`/`4.0`; `x01`: `true`/`true`; `r01`: `true` | probes |
| 62 | `std/strtabs` refuses `newStringTable()` with `too few arguments`, because the zero-pair constructor takes a mode. | `q14` | `[1] too few arguments (declared in …/strtabs.nim(251, 1))` | `lib/std/strtabs.nim:251` |
| 63 | `std/logging`'s `info("started")` compiles, runs and prints nothing, because `info` logs to registered handlers and import registers none. | `g01` | empty stdout, exit 0 | `lib/std/logging.nim:404-409`; `doc/stdlib.md:451-475` |
| 64 | `std/rex` imports at the pin. | `i30-rex` | `ok`, exit 0 | probe |
| 65 | The pin's own guide lists the modules it documents. | doc read | headings `system` … `crypto` | `doc/stdlib.md:11-687` |

## Questions for the reviewer

**A. The job line and citable fact.** The outline's job named `std/seqs` as one of the proven modules. There is
no such module at the pin (`i06-seqs`) and none in Nim 2.4.0 (`nim2/n1`), so I changed the job line to
"sequence helpers from `system` and `sequtils`" and split the tour accordingly (`add`/`setLen`/`delete(idx)` in
`system`, `insert`/`delete(first,last)`/`concat` in `sequtils`). Is that split complete at the pin, or does a
third place own part of it?

**B. `echo`'s redirection.** I claim the whole reason a `seq` or an object cannot be echoed is the fixed
`write` overload set (`e01`, `e02`), not a missing `$` conversion. Is there any path through `echo` at the pin
that would pick up a user-defined `$` (a `$`-based `write` overload, or `repr`) that the error message would not
show me?

**C. `ErrorCode` reachability.** The enum arrives through `include "errorcodes/errorcodes"` in `system`
(`lib/std/system.nim:256`), so `import std / errorcodes` is refused although the file exists
(`lib/std/errorcodes/errorcodes.nim`, `i31`). Is the fragment intended to be unreachable as a module, and may
the chapter point at the file path as a source while saying the import does not work?

**D. Table order.** `t02` printed `tea`, `coffee`, `water` in insertion order for three keys, and
`initOrderedTable` is defined as `initTable` inline (`lib/std/tables.nim:258`). I wrote "order is not part of the
contract" and made the sample sum instead of printing pairs. Does anything at the pin guarantee insertion order
for small tables, or was `t02` luck?

**E. `HashSet` identity.** I state `HashSet[T]` is a `Table[T, bool]` (`lib/std/sets.nim:5`) and that therefore
the `Keyable`/`Hashable` rules apply unchanged, including a `seq[int]` element. Confirm that is the pin's
implementation and not a comment that has drifted.

**F. `std/json`.** `parseJson` accepts a string and `node["a"]` is refused with a constraint error and a full
candidate list (`j01`); the module has no section in `doc/stdlib.md`. Is this a documentation defect worth an
ERRATA row, or an unfinished module the book should simply not advertise?

**G. `std/logging` silence.** `info("started")` compiles, runs and prints nothing (`g01`), and the module's
guide says entries are NIF lines written by a handler (`doc/stdlib.md:451-475`). I explained it as "no registered
handler, so the call is a no-op" (`lib/std/logging.nim:404-409`). Is that the actual mechanism at the pin, or is
there a default handler whose output I failed to find?

**H. Atomic fallback.** `a01` shows the arithmetic working in a single-threaded program. I claim only the
observable arithmetic and the `Trivial` constraint, not lock-freedom. If the reviewer wants one sentence about
what the emitted C does, I will add it only with a source line.

## ERRATA candidates

1. **`doc/stdlib.md` has no `tables` example that reads a key.** The section documents `Table` and its
   operations (`doc/stdlib.md:325-348`) without saying that `[]` is `{.raises.}`, so a reader writing the
   obvious line gets a compile error at the pin that the section does not predict. Documentation gap, candidate.
2. **`std/strtabs`' zero-pair constructor requires a mode** (`lib/std/strtabs.nim:251`) while its own
   cross-reference advertises a `newStringTable(keyValuePairs)` form (`lib/std/strtabs.nim:255-256`) and the
   Nim 2 habit is `newStringTable()` with no argument. Documentation gap, candidate.
3. **`std/json` is importable and unreadable.** `parseJson` works and the indexing operator does not resolve
   (`j01`). Either a documentation defect (the module is not in `doc/stdlib.md` at all) or an unfinished
   module. Candidate, low priority; the chapter does not teach it.
4. **The outline's own module list named `std/seqs`.** This one is the book's error, not the pin's: the name is
   not in the pin and not in Nim 2.4.0. Fixed in `OUTLINE.md` and in the chapter's job line in this handoff, no
   ERRATA row needed.

## Watch rows

- **`std/streams`' `readLine`** is `{.raises.}` like `syncio`'s, so the module passes "one action runs" only for
  the constructor (`q13`, `main.nim(4, 8)`). Whether the stream module is worth a chapter section waits on a
  use that is not a file read, which is Chapter 21's ground.
- **`std/rex`** imports (`i30-rex`) and no call was probed. It stays mentioned, not taught, until a run exists.

---

# Verdict — 2026-11-13 (Momo)

Re-run from the sources, not from the pasted rows: `./tools/verify-samples.sh` at pin `4ba90a7` gave
`SUMMARY 19/19 passed, 0 failed`, and the chapter sample's 26 output lines diff byte-identical against
the block in `en.md` section Samples. All 66 probe directories were re-run, plus nine reviewer probes
of my own (`j2`, `dollar`, `writeov`, `repr`, `raises`, `goq`, `setseq`, `tableorder`, `pct`).
`en.md`, `id.md` and `samples/` were not touched.

**59 rows stand as written; 2 stand with only a source-line fix (57, 58); 2 are narrowed (47, 49);
2 need their paragraph rewritten while the row survives (46, 60). Zero open.**

## Answers

**A.** No third place owns the sequence helpers; `system` also carries `pop`, so say "most of the rest".
`add`/`setLen`/`delete(idx)` are in `system/seqimpl.nim` and `pop` is at `:363`; `sequtils` carries the
rest; `std/seqs` exists in neither compiler (`i06-seqs`, `nim2/n1`). The three named are not the whole
`system` surface, only the three a first program needs.

**B.** No `$` path, but a user-declared `write` overload is picked up, so the set is the module default,
not a closed list. My `dollar` probe still dies at `write stdout, p` (`syncio.nim:468`) with the nine
overloads; my `writeov` probe defines `proc write(f: File; p: P)` and `echo p` prints `custom:7`.
`echo repr(x)` works when the string is passed explicitly. Rewrite "Fixed means fixed" to "nine
is the default set; no `$` is consulted, and a `write` overload you declare is found at the call site".

**C.** Yes, the fragment is not a module and the import cannot work. `errorcodes/errorcodes.nim` is
generated ("Generated by tools/gen_errorcodes.nim. DO NOT EDIT!") and included from `system.nim:256`;
`import std/errorcodes` looks for `src/lib/std/errorcodes.nim`, which does not exist (`i31`). Cite the
path as a source, say the import fails, and this is intended, not a defect.

**D.** Not luck. `Table` keeps its pairs in a `seq`, `pairs` walks it in order (`tables.nim:189-192`), and
`del` "Preserves insertion order" by shifting entries down (`:211-213`); the source comment says
"Nimony's `Table` is already insertion-ordered" (`:252`). My `tableorder` probe printed `a`, `c`, `d`
after deleting `b`. The guide does not promise the order, so the sample's sum is still the portable
habit, but "it is a name, not a guarantee" is false at the pin.

**E.** It is an object wrapping `t: Table[T, bool]` (`sets.nim:5-6`), not a type alias, with
`T: Keyable`. The rules carry over — my `HashSet[seq[int]]` probe printed `2` and `true` — but
`HashSet[int]` is not a `Table[int, bool]`. Write "wraps", not "is".

**F.** Not an unfinished module. `parseJson` returns a `JsonTree`; the read path is `tree{"a"}` →
`JsonNode` (`json.nim:551`) and `getInt`/`getStr`/`kind` on that (`:383`, `:418-424`). My `j2` probe
printed `1`. Drop "parser without a reader"; the gap is that `doc/stdlib.md` has no `json` section and
`[]` is not the accessor, so this is documentation, not a dead module.

**G.** No default handler. `handlers` is a thread-local `seq[Logger]` (`logging.nim:131`), `logLoop` only
walks it (`:375-379`), and nothing registers one at import. Your mechanism sentence is exact.

**H.** One sentence is possible with a source: each operation lowers to the GCC/Clang `__atomic_*` builtin
of the same name (`src/lengc/typenav.nim:87-100`), and the generated C contains no `_Atomic` types
(`lib/std/atomics.nim:2-3`). Keep lock-freedom out; the flag pair has no native back end (`:31-36`),
which says nothing about the C path.

## Claim verdicts

| # | Verdict | Evidence |
| --- | --- | --- |
| 1 | stands | exercised by every probe below |
| 2 | stands | `q16` prints `1` |
| 3 | stands | `i07` file not found |
| 4 | stands | `i16` file not found |
| 5 | stands | `i06` file not found |
| 6 | stands | `i32` file not found |
| 7 | stands | `nim2/n1` cannot open file: std/seqs |
| 8 | stands | `nim2/n2` prints `a2`, `true`, `5` |
| 9 | stands | `syncio.nim:465-469` |
| 10 | stands | nine overloads at `:293`, `:299`, `:303`, `:309`, `:312`, `:318`, `:321`, `:324`, `:331`; none unconstrained |
| 11 | stands | `e01` lists all nine |
| 12 | stands | `e02` lists all nine |
| 13 | stands | `syncio.nim:471-475` |
| 14 | stands | `:538` `{.noreturn.}` |
| 15 | stands | `:506`, `:511` |
| 16 | stands | `strutils.nim:1` |
| 17 | stands | `:405`; `q15` prints `3`, `3` |
| 18 | stands | `:405`, `:409`, `:413` |
| 19 | stands | `:1593`; `s01` prints `pad` |
| 20 | stands | `:489` |
| 21 | stands | `:1733`; `s02`, `s03` refused |
| 22 | stands | `:1474`; my `pct` probe refused |
| 23 | stands | `:1588` |
| 24 | stands | `s04` prints `42`, `bad input: abc`, `0` |
| 25 | stands | `s05` prints `tea and tea` twice |
| 26 | stands | `system.nim:256`; `s01`, `t01`, `h01` compile without the import |
| 27 | stands | `errorcodes.nim:18`; `t01`, `s04` catch it |
| 28 | stands | `i31` file not found |
| 29 | stands | `seqimpl.nim:213`; `y02` |
| 30 | stands | `:337` `[T: HasDefault]`; `y02` |
| 31 | stands | `:370`; `y02` |
| 32 | stands | all fourteen at `sequtils.nim:80`, `:89`, `:98`, `:131`, `:111`, `:121`, `:35`, `:46`, `:64`, `:72`, `:142`, `:151`, `:161`, `:174` |
| 33 | stands | `:189`; `y03` prints `1 3` |
| 34 | stands | `:210`; `y03` prints `0 4`; `y01` refuses `insert` |
| 35 | stands | `stringimpl.nim:1034`, `:1062`, `:1063`; `y01` names the three |
| 36 | stands | `sequtils.nim:27`; `y03` prints `3` |
| 37 | stands | `:80`, `:89`; `q01` prints `28`, `2` |
| 38 | stands | `q02` prints `3` |
| 39 | stands | `tables.nim:243`; `t02`, `z01` |
| 40 | stands | `:158`, no `{.raises.}`; `t01` sums outside try |
| 41 | stands | `:110-114`; my `raises` probe refused |
| 42 | stands | `:78`, `:82`; `t01` prints `false` |
| 43 | stands | `:86`, `:93`; `t01` prints `0` |
| 44 | stands | `:101-107`; my `goq` probe printed `1` then `[Assertion Failure] key not found` |
| 45 | stands | `:189-209`; `t02` prints three pairs |
| 46 | **rewrite** | order is insertion order at the pin: `pairs` walks `data` (`:189-192`), `del` preserves it (`:211-213`), comment at `:252`; my probe printed `a c d` after deleting `b`. Keep "the guide does not promise it", drop "it is a name, not a guarantee" |
| 47 | **narrow** | `Keyable = concept of Hashable` **plus** `func ==(a, b: Self): bool` (`tables.nim:6-7`); add the `==` half |
| 48 | stands | `z01` prints `1`; `hash(seq)` at `hashes.nim:61` plus `==` |
| 49 | **narrow** | object wrapping `t: Table[T, bool]` (`sets.nim:5-6`), not an alias; my `setseq` probe printed `2`, `true`. Say "wraps" |
| 50 | stands | `h01` prints `2`, `true`, `false`, `1`; `:8`, `:12`, `:16`, `:24`, `:46`, `:20`, `:61`, `:28`, `:34` |
| 51 | stands | `:28-39`; sample prints `true`, `false` |
| 52 | stands | `h01` len `2` |
| 53 | stands | `set` is the magic type at `system/basic_types.nim:105`, included into `system`; `strutils.nim:405`, `:1593` |
| 54 | stands | header `atomics.nim:1-3`; `a02` |
| 55 | stands | `:49`, `:53`, `:57`, `:61`, `:83`; `a01` prints `0`, `1`, `2`, `10`, `true`, `11` |
| 56 | stands | `:6-12` |
| 57 | stands, cite | `Trivial` is `:14`, not `:12`; the message names `atomics.nim(49, 1)` because that is `atomicLoad` |
| 58 | stands, cite | `AtomicFlag` is `:16`, not `:14` |
| 59 | stands | `a02` |
| 60 | **rewrite** | the row is true (`node["a"]` refused, `j01`), the paragraph is false: `t{"a"}.getInt` prints `1` (see F) |
| 61 | stands | `d01`, `q11`, `q12`, `m01`, `x01`, `r01`; streams only the constructor, as the watch row says (`q13` refuses `readLine`) |
| 62 | stands | `q14` first line `too few arguments (strtabs.nim(251, 1))`; the cell quotes only the first line of a longer dump |
| 63 | stands | `g01` empty stdout; `:131`, `:375-379`, no import-time registration |
| 64 | stands | `i30-rex` prints `ok` |
| 65 | stands | headings `:11` through `crypto` at `:687`; every named section present |

## ERRATA rulings

1. **Struck.** `doc/stdlib.md:341` already says "`[]` raises `KeyError` on missing keys". The guide
   predicts the compile error; there is no gap to record.
2. **Keep.** The `See also` block at `lib/std/strtabs.nim:253-256` advertises
   `newStringTable(keyValuePairs)`, but that proc is commented out (`:263` onward), and Nim 2.4.0 takes
   `newStringTable()` with no argument (my host run printed `1`). Documentation defect in the module.
3. **Reframe.** Not an unfinished module: `t{"a"}` then `getInt` works (`json.nim:551`, `:423`; my probe
   printed `1`). The real gap is that `doc/stdlib.md` has no `json` section at all. Keep as a
   documentation gap, low priority; the chapter must not present `[]` as the expected accessor.
4. **No row**, correct: the book's own outline error, already fixed in `OUTLINE.md` and the job line.
5. **New, low priority.** `doc/stdlib.md:345-346` says `getOrQuit` "calls `quit`, not an exception"; the
   source is `raiseAssert "key not found"` (`lib/std/tables.nim:101-107`), and my `goq` probe printed
   `[Assertion Failure] key not found` before failing. The chapter's "after an assert" matches the source.

## Watch rows

Both stay. `q13` confirms `streams.readLine` is `{.raises.}`, so streams passes only on the constructor;
`i30-rex` is import-only.

## Notes for the editor

- `samples/20-stdlib/stdlib.nim` carries the same "iteration order is not part of the contract" comment
  that the chapter must rewrite. I did not touch it.
- Claim 62's raw-output cell is a truncation, not a wrong claim; the dump continues with the `auto`
  cascade.
- Two chapter citations move: `Trivial` `:12` → `:14`, `AtomicFlag` `:14` → `:16`.
- No other chapter was opened.
