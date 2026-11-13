---
chapter: 20
title: The Standard Library You Can Rely On
job: Tour only the modules proven at the pin (`syncio`, `strutils`, sequence helpers from `system` and `sequtils`, `tables`, `sets`, `atomics`) and state the rule for using any other.
nimony_version: 0.6.3
nimony_commit: 4ba90a781b0b22d0821efaa153c129c37cef6143
toolchain: ~/.local/opt/nimony/4ba90a7
host_compiler: ~/.local/opt/nim-2.4.0
status: frozen
tech_review: Momo 2026-11-13
editorial_pass: 2026-11-13
samples: [samples/20-stdlib/stdlib.nim]
glossary_added: [proven module, Table, Keyable, HashSet, sequtils, atomic operation, MemoryOrder]
---

# The Standard Library You Can Rely On

## What this chapter is for

A language is only as useful as the code you do not have to write yourself. This chapter tours the part of the
standard library that is proven to work at the pinned commit, and it gives you the test that decides whether a
module outside the tour belongs in your program. The list is short on purpose. A module is worth relying on
when a program runs, not when a file exists and not when Nim 2 documentation remembers it.

## The rule: presence, not reputation

Three facts look like permission and are not.

A file named `lib/std/<name>.nim` in the pin's checkout tells you the module is meant to exist. It does not
tell you that the function you want is exported from it, and it does not tell you the module compiles. A
successful `import std / <name>` tells you slightly more: the file was found and its top level parsed. It does
not tell you that the part you need works. Only a run does.

The test is two lines and one command:

```nim
import std / [syncio, deques]

var q = initDeque[int]()
q.addLast(1)
echo q.len
```

That prints `1` at the pin, so `std/deques` is usable, and you may move on. Swap the module and the calls for
the ones you need. If the import is refused, the module is not there. If the actions fail, the module is there
and not usable for your purpose.

The failure modes are worth recognising by their messages. A missing module is refused at the import with
`file not found`, naming the path the compiler tried: `std/strformat`, `std/re`, `std/seqs` and `std/cookies`
all fail this way at the pin. The first two are ordinary Nim 2 modules — the host compiler prints `a2` for
`fmt"a{1 + 1}"` and `true` for a regex match, so the documentation you remember was true of Nim 2 — and the
last two are names that were never modules at all: Nim 2.4.0 refuses `std/seqs` as well, with
`cannot open file: std/seqs`. A module that exists but does not export what you wanted fails later, at the
call. Both messages are answers.

The chapter's own tour is not a substitute for that test. It is a record that the test was run, at this commit,
for five modules and for the collection helpers that go with them.

The pin also ships a standard-library guide of its own, `doc/stdlib.md`, with sections for `system`, `syncio`,
`strutils`, `unicode`, `hashes`, `tables`, `sets`, `paths`, `dirs`, `envvars`, `appdirs`, `memfiles`,
`encodings`, `wordwrap`, `logging`, `rawthreads`, `stacktraces`, `streamio`, `channels`, `tls` and the HTTP
modules (`doc/stdlib.md:11-687`). Read it for signatures and for the design behind a module. Do not read it as
proof that a call works: it is a reference, and this chapter's list is what the reference has been checked
against.

## `std/syncio`: `echo` and its overloads

Every example in this book begins with `import std / syncio`, and `echo` is why. At the pin `echo` is a
`varargs` template (`lib/std/syncio.nim:465-469`) that forwards each argument to a `write` overload, and the
overload set is fixed (`lib/std/syncio.nim:293-331`): `string`, `bool`, `int64`, `int32`, `uint64`, `uint32`,
any enum type, `char`, and `float`.

Nine is the default set, not a closed list. A `seq` is not in it, and neither is an object of your own, so
`echo @[1, 2]` and `echo p` are both errors, and the message is the whole overload set printed back at you
with your type after `expected:` (`lib/std/syncio.nim:468`). No `$` conversion is consulted; Chapter 11
already told you that a user-defined `$` does not help. What this chapter adds is the other half: a `write`
overload you declare yourself is found at the call site, so `proc write(f: File; p: P)` makes `echo p` print
your text, and the nine you get back in an error message are the module's defaults rather than the only
possibility. Print a collection element by element, or build a string and print that.

The rest of the module is equally literal. `write` writes without a newline, `writeLine` writes a string and a
newline, and `quit` stops the program and does not return (`lib/std/syncio.nim:538`). Reading has two shapes:
`readLine(f, s: var string): bool` returns whether a line was read (`lib/std/syncio.nim:506`), while
`readLine(f): string` is marked `{.raises.}` (`lib/std/syncio.nim:511`) because the stream can fail. The file
side of the module, including `readFile` and `writeFile`, is Chapter 21's subject.

## `std/strutils`: helpers, and the ones that can fail

`std/strutils` is ASCII-focused by its own description, and most of it is total: given a string, it returns a
string, a number, or a truth value, and it cannot fail. `split`, `strip`, `join`, `repeat`, `startsWith`,
`endsWith`, `contains`, `replace`, `find`, `toUpperAscii` and `toLowerAscii` all have this shape. The
signatures reward reading once:

- `split(s, seps: set[char] = Whitespace, maxsplit = -1)` splits on any of a set of characters by default, so
  `"a b".split` and `"a,b".split(",")` are the same function with different separators
  (`lib/std/strutils.nim:405`, `:409`, `:413`).
- `strip(s, leading = true, trailing = true, chars: set[char] = Whitespace)` trims whitespace unless you name
  the characters (`lib/std/strutils.nim:1593`).
- `join(a: openArray[string], sep = "")` takes any sequence of strings, not only a sequence literal
  (`lib/std/strutils.nim:489`).

Three names are not total, and the compiler says so before you run anything. `parseInt(s): int` is marked
`{.raises.}` (`lib/std/strutils.nim:1733`), as is the `%` format operator
(`lib/std/strutils.nim:1474`) and `format` (`lib/std/strutils.nim:1588`). Calling any of them outside a `try`
block is refused at compile time with `cannot call a routine marked as `.raises` outside of a `try`..`except`
block`, which is the same rule Chapter 15 taught for your own routines. Catch `ErrorCode`, because that is the
only thing that gets raised:

```nim
proc number(s: string): int =
  try:
    result = parseInt(s)
  except ErrorCode as e:
    echo "not a number: ", s
    result = -1
```

`number("42")` prints `42` from the caller's `echo`, and `number("4x")` prints `not a number: 4x` and returns
`-1`. The `%` operator behaves the same way: `"$1 and $2" % [a, b]` is a compile error outside `try`, and
inside it produces `tea and tea` for two identical arguments.

`ErrorCode` needs no import. It is an enum included into `system` from a fragment
(`lib/std/system.nim:256`), and `KeyError` is one of its members (`lib/std/errorcodes/errorcodes.nim:18`).
There is no `std/errorcodes` module to import: `import std / errorcodes` fails with `file not found`, and that
failure is not a sign that the enum is unavailable.

## Sequences without a `seqs` module

Nim 2 programmers reach for a `seqs` module. There is no such module at the pin, and there is none in Nim 2.4.0
either: the sequence helpers are split across two places instead.

The basics are in `system`, which you never import. `add(s, elem)` appends (`lib/std/system/seqimpl.nim:213`),
`setLen(s, newLen)` resizes and requires an element type with a default value
(`lib/std/system/seqimpl.nim:337`), and `delete(s, idx)` removes one element
(`lib/std/system/seqimpl.nim:370`). `pop(s)` is there too (`lib/std/system/seqimpl.nim:363`). Those three
are the names a first program needs, not the whole `system` surface, and they are why such a program can be
written without any library import at all.

Most of the rest is `std/sequtils`: `map`, `filter`, `keepIf`, `apply`, `all`, `any`, `count`, `deduplicate`, `minIndex`,
`maxIndex`, `cycle`, `zip`, `unzip`, `minmax`, and the two that surprise people because they are not in
`system` — `delete(s, first, last)` for a range (`lib/std/sequtils.nim:189`) and `insert(dest, src, pos = 0)`
for a sequence (`lib/std/sequtils.nim:210`).

One operator is narrower than Nim 2 suggests. `&` is defined for `string` and combinations of `string` and
`char` (`lib/std/system/stringimpl.nim:1034`, `:1062`, `:1063`) and for nothing else, so `xs & ys` on two
sequences is a type mismatch whose candidate list is every string overload. The sequence equivalent is
`concat(a, b)` from `sequtils` (`lib/std/sequtils.nim:27`), and it is an ordinary call rather than an operator.

`map` and `filter` take a routine value, not a syntax argument, so the element and result types are written in
the signature of the routine you pass:

```nim
let doubled = @[1, 2, 3].map(proc (n: int): int = n * 2)
let even = @[1, 2, 3, 4].filter(proc (n: int): bool = n mod 2 == 0)
```

Both run: `doubled[2]` is `6`, and `even.len` is `2`. `mapIt` and `it` exist as well and are shorter, and the
choice between them is style, not capability.

## `std/tables`: keys, lookups, and absence

A `Table[K, V]` is a hash map with one rule that shapes every line you write: reading a key that is not there
raises, and writing one never does.

- `initTable[K, V]()` creates an empty table (`lib/std/tables.nim:243`).
- `t[k] = v` stores and overwrites (`lib/std/tables.nim:158`), with no `{.raises.}`.
- `t[k]` reads and is marked `{.raises.}`; when the key is absent it raises `KeyError`
  (`lib/std/tables.nim:110-114`).
- `hasKey(t, k)` and `contains(t, k)` answer without raising (`lib/std/tables.nim:78`, `:82`).
- `getOrDefault(t, k, fallback)` answers with your fallback instead (`lib/std/tables.nim:93`); the
  one-argument form needs a value type with a default (`lib/std/tables.nim:86`).
- `getOrQuit(t, k)` ends the program if the key is missing, after an `assert`
  (`lib/std/tables.nim:101-107`). It is the right function for a key your program cannot continue without, and
  the wrong one everywhere else.

Because a read can raise, a table read inside a routine that does not catch is a compile error, not a runtime
surprise. That is the same rule as `parseInt`, and the fix has the same shape: catch `ErrorCode`, or ask
`hasKey` first, or use `getOrDefault`. The chapter's sample uses all three, which is a fair picture of ordinary
table code at the pin.

Iteration gives you `pairs`, `keys`, `values`, `mpairs` and `mvalues` (`lib/std/tables.nim:189-209`). At the
pin the order those walk is insertion order: the table keeps its pairs in a sequence, `pairs` walks that
sequence (`lib/std/tables.nim:189-192`), and `del` preserves the order by shifting the entries down
(`:211-213`). The source says as much in a comment on the ordered table (`:252`), and `initOrderedTable`
(`:258`) is defined as `initTable` with an inline body because the ordinary table is already ordered. The
guide does not promise that order, though, and a sum or a sort does not depend on it, so accumulate a sum,
sort the keys yourself, or print one key you looked up rather than diffing a printed table.

Keys must satisfy `Keyable`, which the same file declares as `concept of Hashable` plus a `==` over two
`Self` (`lib/std/tables.nim:6-7`), with `Hashable` declared in `std/hashes` (`lib/std/hashes.nim:13`). `string`, `int`
and a tuple are obvious keys. `seq[int]` is also a legal key at the pin — `t[@[1, 2]] = "pair"` stores and the
table reports length `1` — because a sequence has both `hash` and `==`. That is worth knowing before you
serialise a composite key into a string.

## `std/sets`: values, not bitsets

A `HashSet[T]` wraps a `Table[T, bool]` (`lib/std/sets.nim:5-6`), so everything the previous section said about
keys applies unchanged: `Hashable` is the requirement (`lib/std/sets.nim:5-8`), a sequence is a legal
element, and a `HashSet[int]` is still not a `Table[int, bool]`.

The surface is small. `initHashSet[T]()` (`lib/std/sets.nim:8`), `incl` and `excl` (`:12`, `:16`), `contains`
(`:24`), `len` (`:46`), `clear` (`:20`), `intersection` (`:61`), and two that answer a question while they
work: `containsOrIncl` returns true if the element was already there and inserts it otherwise
(`lib/std/sets.nim:28`), and `missingOrExcl` returns true if it was missing and removes it otherwise
(`lib/std/sets.nim:34`). In the sample, `containsOrIncl("milk")` prints `true` and `containsOrIncl("sugar")`
prints `false` and adds the element. Inserting a duplicate changes nothing, so `incl("hot")` twice leaves
length `1`.

Do not confuse this with `set[char]`, which is a bitset over the character range and belongs to `system`. Use
`set[char]` where the domain is a character class — that is what `strutils` takes for `split` and `strip` — and
`HashSet` where the elements are values of any hashable type.

## `std/atomics`: operations, not types

This is the one module in the tour where a Nim 2 habit has to be unlearned rather than adjusted. Nimony has no
`Atomic[T]` wrapper. The module's header states the design in one line, "Atomics are operations, not type
properties" (`lib/std/atomics.nim:1-4`), and the code matches: you declare an ordinary `var` and call
`atomicLoad`, `atomicStore`, `atomicFetchAdd`, `atomicExchange`, `atomicCompareExchange` and their relatives on
it.

```nim
var hits = 0
discard atomicFetchAdd(hits, 1)
discard atomicFetchAdd(hits, 1)
echo atomicLoad(hits)      # 2
atomicStore(hits, 10)
echo atomicLoad(hits)      # 10
```

Each operation takes a memory order and defaults to `moSequentiallyConsistent`
(`lib/std/atomics.nim:49-52`), the strictest one, so the default is the safe default and the orders are an
optimisation you add when you can name what you are ordering. The six orders are the usual C ones
(`lib/std/atomics.nim:6-12`).

The indivisibility is not a property of the variable. Each operation lowers to the C compiler's `__atomic_*`
builtin of the same name (`src/lengc/typenav.nim:87-100`), and the generated C declares no `_Atomic` types
(`lib/std/atomics.nim:2-3`): the guarantee comes from the builtin at the call, which is why an ordinary `var`
is enough.

The constraint is `Trivial`: integers, `bool`, enums, `ptr`, `pointer` (`lib/std/atomics.nim:14`). A `string`
is refused at the call with `string does not match constraint T`, naming the module the constraint came from —
one more place where the message tells you the rule. `AtomicFlag` exists as a distinct `bool`
(`lib/std/atomics.nim:16`) for the flag-shaped case.

What this chapter does not teach is a second thread. Atomics are about the operations being indivisible, and a
single-threaded program can call them and see the arithmetic. Chapter 24 is where the other side of the
question lives.

## Any other module

For a module outside the tour, run the two-line test and record what you saw. The result has three possible
shapes and each one decides something different.

The module is not there. `std/strformat` and `std/re` fail this way at the pin, and so does `std/seqs`. If you
were reaching for `fmt"..."`, use `%` or `&` from `strutils`; if you were reaching for a regex, `std/rex`
imports and is the pin's own regex module, unproven here.

The module is there and the call is not. `std/json` imports and `parseJson` accepts a string, but
`node["a"]` is refused with `JsonTree does not match constraint T` and a full candidate list, because `[]`
is not the accessor for a parsed tree. The read path is `node{"a"}`, which hands you a `JsonNode`, and
`getInt`, `getStr` or `kind` on that (`lib/std/json.nim:551`, `:383`, `:418-424`). The pin's guide has no
`json` section at all (`doc/stdlib.md:11-687`), so a reader looking it up finds nothing, and the shape has to
be learned from a run.

The module is there and the call runs. `std/deques`, `std/heapqueue`, `std/intsets`, `std/algorithm`,
`std/math`, `std/hashes`, `std/random`, `std/times` and `std/streams` each pass an import and at least one
action at the pin. Passing the test is permission for the calls you actually ran, not for the module's whole
documentation, and the same round has two warnings. `std/strtabs` imports and then refuses `newStringTable()`
with `too few arguments`, because the only zero-pair constructor takes a mode (`lib/std/strtabs.nim:251`). And
`std/logging`, which the pin's guide documents in full (`doc/stdlib.md:451-475`), compiles, runs
`info("started")` and prints nothing at all: `info` is a template that logs to registered handlers
(`lib/std/logging.nim:404-409`), and importing the module registers none, so the call is silent until you add
one.

The book's rule follows from that. A module enters the tour when a chapter carries a run at the pin, and the
outline's open question about the stdlib surface stays open: the list grows only with a verified sample, never
from Nim 2 documentation and never from a file's existence.

## Nim 2 delta

*What Nim 2 did:* `std/strformat` and `std/re` were ordinary imports, sequences had a `&` operator, and atomics
were a wrapper type, `var counter: Atomic[int]`, with `load()` and `store()` members.
*What Nimony does:* `strformat` and `re` are absent at the pin, the sequence helpers live in `system` and
`std/sequtils`, `&` is string-only, and an atomic is an ordinary variable with free functions operating on it.
*What breaks if you keep the habit:* `import std / strformat` stops the build at the import, `xs & ys` resolves
to the string overloads and fails with a mismatch, and `Atomic[int]` is refused as an undeclared identifier. The
replacement is one call away in each case: `%` from `strutils`, `concat` from `sequtils`, and `atomicLoad` on a
plain `var`.

## Samples

`samples/20-stdlib/stdlib.nim`, run at the pinned commit:

```
nimony c -r samples/20-stdlib/stdlib.nim
```

Expected output, which the sample verifier prints in full:

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

Line by line: `parseInt` behind `try` (`42`, then the caught failure and `-1`); `split` and `strip` on a padded
record (`2`, `tea`, `2`); `join` and `repeat` (`tea and coffee`, `---`); `add`, `setLen` and `delete` from
`system` (`4`, then `2 2`); `insert`, the range `delete` and `concat` from `sequtils` (`3 9`, `2 2`, `3`); `map`
and `filter` (`2 6`, `2`); a table sum with a `hasKey` answer (`9`, `false`); a raising read caught and a
missing key reported (`2`, `missing: milk`, `0`); set membership (`2`, `true`, `true`, `false`); and the atomic
operations (`2`, `10`).

## Checks

1. Write the two-line probe for `std/heapqueue`: push three integers, echo the popped minimum. Expected
   output: the smallest value you pushed.
2. `echo @[1, 2]` is an error. Change one thing so it prints something informative, without writing a loop.
   Expected: a single line containing both numbers.
3. Call `parseInt` without `try`. Expected: a compile error naming `.raises`, before the program runs.
4. Read `counts["milk"]` from the sample's table with no guard and no `try`. Expected: a compile error, not a
   runtime crash.
5. Replace `counts.getOrDefault("tea", 0) + 1` with `counts["tea"] + 1` and wrap the line in `try`. Expected:
   the same output as the sample.
6. Ask whether `std/cookies` exists at the pin, and answer from a command's output rather than from memory.

## Chapter checklist

draft 2026-11-13 · tech_review 2026-11-13 · editorial_pass 2026-11-13 · frozen 2026-11-13
