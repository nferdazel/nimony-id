---
chapter: 14
title: Ownership and Borrow Checking
job: Show who owns a value, which aliasing and escaping-borrow shapes the compiler rejects, and why `move` is not a checked operation at this pin.
nimony_version: 0.6.3
nimony_commit: 4ba90a781b0b22d0821efaa153c129c37cef6143
toolchain: ~/.local/opt/nimony/4ba90a7
host_compiler: ~/.local/opt/nim-2.4.0
status: frozen
tech_review: Momo 2026-11-13
editorial_pass: 2026-11-13
samples: [samples/14-ownership-borrow/ownership.nim]
glossary_added: [ownership, borrow, alias, moved-from state, ensureMove]
---

# Ownership and Borrow Checking

## What this chapter is for

Chapter 13 gave you two ways to reach another name's storage: a managed `ref` and a raw `ptr`. This chapter is
about the rules that come with reaching it. Who is responsible for a value, when two names may point at
overlapping storage, and what the compiler refuses before your program ever runs.

At this pin the compiler enforces three rules, and only three. A call may not pass the same location once as a
mutable argument and once as an argument that reads the caller's storage. A borrow may not outlive the storage
it borrows from. A borrowed path may not be mutated while the borrow lasts. Most of what Nim 2 programmers
group under "ownership" is not enforced here, move checking above all, so the second half of this chapter says
what the pin does instead of teaching a rule the compiler does not have.

## What "owns" a value

Start with what assignment already does. `var b = a` copies, and the two names reach separate storage, unless
the type is a `ref`, in which case both names reach one cell (Chapter 13). So the owner of a value is simply
the name whose copy is destroyed at the end of its scope. Nothing in the type marks it, and nothing tracks it
at run time.

The compiler has hooks to run at those moments — `=destroy`, `=dup`, `=copy`, `=wasMoved`, `=sink` — declared
in `lib/std/system.nim:112-116`. They are ordinary routines the runtime calls; they are not a flow analysis,
and a type is free to define them or not. A `string` and a `seq` use them to release their buffer. An `int`
does not need one at all, which is why moving an `int` later in this chapter changes nothing.

`doc/language.md:893-960` documents an opt-in `owned` annotation for `ref` and closures behind
`{.feature: "ownedRefs".}`. This chapter does not use it, and no rule below depends on it.

## The call-site aliasing check

Every call is checked for overlapping arguments. The check is `borrowCheckForCall`, in
`src/nimony/contracts_fir.nim:4242-4289`, and it has two halves.

A mutable argument must not overlap an immutable one, when the immutable one reads the caller's storage. When
it does, the call is refused:

```
Error: mutable argument aliases with immutable parameter
```

Two mutable arguments must not overlap either, and that half fires whenever the paths overlap at all:

```
Error: mutable argument aliases with mutable parameter
```

Whether the second half fires is easy to see. `swap(x, x)` on two `int` parameters is refused
(`src/nimony/contracts_fir.nim:4282`), because two writes through one location make the result depend on
the order the callee writes, and no type property can rescue that. Disjoint fields of one object are fine, and
`swap(p.x, p.y)` runs — it is the first block of this chapter's sample.

The first half depends on the type, and that is the part worth learning. `passedByPointer`
(`src/nimony/contracts_fir.nim:4340-4351`) answers one question — can the callee's copy be changed by a
mutation through another argument? — and it says yes on four conditions:

- the parameter is a `lent`, or a `varargs`;
- the type is a view, such as an `openArray`;
- the value is large enough to be passed by const reference: over 24 bytes, unless the type or the parameter
  carries `{.bycopy.}` (`passByConstRef`, `src/nimony/sizeof.nim:306-318`; the threshold is `getSize > 24` at
  `:282-288`);
- the type can own the heap.

`ownsNoHeap` (`src/nimony/contracts_fir.nim:4285-4338`) is the list for the fourth: integers, floats, `bool`,
`char`, enums, ranges, `ptr`, `pointer`, `cstring`, sets, arrays and tuples of those, and objects with no
destroy hook whose fields are all in the list. Everything it does not understand is treated as owning heap,
deliberately conservative.

The third condition surprises readers, because it has nothing to do with the heap. A plain object of three
`int`s is 24 bytes and still copied, so the call compiles; one more `int` makes it 32, the compiler passes it
by const reference, and the same call is refused:

```nim
type Obj24 = object
  a, b, c: int

type Obj32 = object
  a, b, c, d: int

proc f(x: var int, y: Obj24) = x = y.a
proc g(x: var int, y: Obj32) = x = y.a

var t = Obj24(a: 1)
var u = Obj32(a: 1)

f(t.a, t)     # compiles, prints 1: 24 bytes, copied
g(u.a, u)     # Error: mutable argument aliases with immutable parameter: 32 bytes, const ref
```

Adding `{.bycopy.}` to `Obj32` makes `g(u.a, u)` compile again, with no change to the fields — that pragma is
exactly what `passByConstRef` reads (`src/nimony/sizeof.nim:310-312`), so the size alone is not the rule.

The fourth condition has one deliberate blind spot. **An inherited or variant object always counts as
heap-owning**, whatever its fields: `ownsNoHeap` returns false for an object with an inheritance marker — the
comment says "a derived value may own more" (`src/nimony/contracts_fir.nim:4328-4329`) — and for a `case`
object, so a by-value parameter of either shape is a pointer for this check even when it is 16 bytes of plain
data. Inheritance is not this book's subject yet; the sentence is here so the reader is not surprised by a
refusal they cannot explain from the fields.

The heap branch is the one a reader meets first, and one field flips it:

```nim
type Plain = object
  x, y: int

type Named = object
  x: int
  name: string

proc update(a: var int, b: Plain) = a = b.x
proc updateNamed(a: var int, b: Named) = a = b.x

var plain = Plain(x: 1, y: 2)
var named = Named(x: 1, name: "n")

update(plain.x, plain)        # compiles, prints 1
updateNamed(named.x, named)   # Error: mutable argument aliases with immutable parameter
```

The rule these calls demonstrate is not "an argument may not overlap its parent". It is: **a by-value
parameter blocks overlap with a mutable argument whenever it reads the caller's storage** — a view, `lent`,
`varargs`, a value large enough to be passed by const reference (over 24 bytes, unless `{.bycopy.}`), or a type
that can own the heap. Only when all four are false, as for a short plain-data copy, does the call compile.

`doc/language.md:2507-2517` shows this check with a two-`int` object and states that the call is an error. At
this pin the same program compiles and prints `1`. The manual's example is only correct for an object with a
heap field or one past 24 bytes; the book teaches the rule above, not that example, and the mismatch is
recorded in `ERRATA.md`.

## A borrow that outlives its subject

The second rule is about views: `openArray`, `lent`, and anything a `var T` result hands back. Such a value
keeps a borrow of the storage it points into, and the borrow has to end before that storage does.

Storing one somewhere that outlives the owner is refused. Writing it into a global is the blunt case:

```nim
var g: openArray[int]

proc escape =
  var a = [1, 2, 3]
  g = toOpenArray(a)
```

```
Error: borrow of 'a' escapes the proc; it does not live long enough
Error: unsynchronized access to global variable 'g'; pass it to a `.sync` routine or use `{.cast(assumeSync).}`
```

Two errors, and the second one is not about borrowing at all: the global-access rule from Chapter 13 fires on
the same line (`src/nimony/contracts_fir.nim:4125`). A reader who only reads the first line will not know why a
plain assignment to a global is a problem; expect both.

The same rule applies inside one proc, between scopes:

```nim
proc outlivesSource =
  var view: openArray[int]
  block:
    var a = [1, 2, 3]
    view = toOpenArray(a)   # Error: borrow of 'a' escapes its scope; it does not live long enough
```

A returned view is the third shape, and it has its own sentence because the fix is different: it may borrow
from the first parameter and from nothing else.

```nim
proc head(i: int; s: string): openArray[char] =
  result = s.toOpenArray(0, 1)   # Error: borrow of 's' escapes the proc;
                                 # a returned view can only borrow from the first parameter
```

The reason is the calling convention. The first parameter of a routine that returns a view is passed by
reference, so the view points into the caller's storage. Every later parameter may be the callee's own copy —
a short string keeps its characters inline — and a view of a copy would dangle. The check is
`checkResultBorrow` (`src/nimony/contracts_fir.nim:680-695`); the first-parameter half is why
`proc window(s: seq[int]): openArray[int]` in the sample is legal.

A `var T` result follows the same rule, which is where Chapter 9's statement came from. `validBorrowsFrom`
(`src/nimony/derefs.nim:258-314`) answers one question — is this expression derived from the routine's first
parameter, or from a pointer? — and `trReturn` (`src/nimony/derefs.nim:461-470`) refuses the rest:

```nim
proc p(a: int; b: var int): var int =
  result = b            # Error: cannot borrow from b
```

The message names the expression, not the rule. `cannot borrow from b` is all you get; the reason is that `b`
is the second parameter. Chaining through a forwarding proc reads the same way:
`result = forward(x)` fails with `cannot borrow from forward(x)`.

`doc/language.md:2448-2472` states this rule with the message `location is derived from x which is not p's
first parameter and lives on the stack`. That wording is not what the compiler prints at this pin; the
behaviour is the same and the error is shorter.

Reading a value through a borrow copies it, so it leaves freely. A proc that walks a seq and returns the first
element is not returning a view:

```nim
proc first(s: seq[int]): int =
  for x in s: return x
  return -1
```

## Borrowed paths during iteration

Iteration borrows the path it walks. While the loop runs, that path may not be mutated, and the rule is prefix
exclusion: if `a.b.c` is borrowed, neither `a`, `a.b`, nor `a.b.c` may be written through, while siblings at
the same level stay writable (`doc/language.md:2540-2567`).

```nim
proc addItem(s: var seq[int]; val: int) = s.add val

var s = @[1, 2, 3]
for x in s:
  addItem(s, x)     # Error: 's' is borrowed and cannot be mutated
```

The error is raised in `src/nimony/contracts_fir.nim:621`, and it names the borrowed path, not the callee. The
sample's second block is the legal half: iterating `c.elements` and writing `c.name` compiles and runs, because
`name` is a sibling of the borrowed path. Walking the same seq by index is legal too — `for i in 0 ..< s.len:
s[i] += 1` never takes the borrow that the `for x in` form takes.

## `move` is a library call; `ensureMove` is the checked one

`move` is not a language construct. It is this, in `lib/std/system.nim:123-126`:

```nim
func move*[T](x: var T): T {.nodestroy, inline, noSideEffect.} =
  result = x
  `=wasMoved`(x)
```

A copy, then a hook. The type system has no moved state and the flow analysis keeps no moved flag, so reading a
name after `move` is never an error. What is left behind is a *valid empty value*, because that is what
`=wasMoved` does for the types that define it:

| moved value | what the old name holds afterwards | probe |
| --- | --- | --- |
| `string` | `""`, `len` 0 | `c01` |
| `seq[int]` | empty, `len` 0 | `c02` |
| `ref object` | `nil` | `c04` |
| object with `seq` and `string` fields | both fields emptied | `c05` |
| `int` | unchanged, still 5 | `c03` |

The last row is the one to internalise: `=wasMoved` is a magic (`lib/std/system.nim:116`, `src/nimony/magics.nim:128`)
that only does work where a type has a specialization — `string` (`lib/std/system/stringimpl.nim:296-297`),
`seq[T]` (`lib/std/system/seqimpl.nim:59-61`), and a handful of handle types. `int` has none, so the call does
nothing and the move is a copy with extra steps. The compiler will not tell you that you reused it.

Reading the old name after a `move` compiles and runs in every row above; there is no error to catch. This is why
the chapter does not teach "the compiler stops use after move". At this pin it does not, and a rule taught here
would be false in the reader's next program.

**`ensureMove` is the checked one.** It sits two lines above `move` in the same file
(`lib/std/system.nim:120-121`, a magic rather than a routine) and it asks the last-usage analysis before it
acts. Inside a proc, using the name after `ensureMove` stops the build:

```nim
proc handover =
  var a = "text"
  let b = ensureMove(a)
  echo b
  echo a          # Error: not the last usage of: a
```

Drop that last line and the same proc compiles and prints `text`, so the difference the reader sees is exactly
the second read. The analysis is `trEnsureMove` (`src/hexer/duplifier.nim:1573`), the error is built at `:1611`,
and `doc/language.md:3591-3594` documents it as a static error when a move cannot be proven safe. So the honest
sentence is scoped: reading a name after `move` compiles, reading it after `ensureMove` does not. Reach for
`ensureMove` when you want the compiler to check the handover.

One more caveat worth knowing before you reach for it: the analysis only runs on a name it can track — a `var`,
`let` or `sink` parameter in a local scope. A module-level variable is refused whatever follows, because
`isLastRead` treats globals as unanalysable on purpose (`src/hexer/duplifier.nim:124-129`). Keep the handover
inside a proc.

The same applies to `sink`. A `sink` parameter accepts the argument and the callee owns its copy; the caller's
variable is untouched afterwards. Passing a `string` to a `sink string` parameter leaves the caller's value and
its length intact (`c06`, `rv40`), and a `sink seq[int]` leaves its length (`rv39`). What the compiler does
behind that is not this chapter's subject; the observable shape is what it teaches.

## Nim 2 delta

Nim 2 compiles the calls Nimony refuses, and the difference is when you find out.

*What Nim 2 did.* `take(s, s)` with `(var seq[int], seq[int])` compiled and printed `1` under Nim 2.4.0; so did
a loop that appends to the seq it is iterating, which then died at run time with
`the length of the seq changed while iterating over it`.

*What Nimony does.* Both are refused before anything runs, on the offending line:
`mutable argument aliases with immutable parameter` and `'s' is borrowed and cannot be mutated`.

*What breaks if you keep the habit.* Code that hands a container and an element of it to the same call — the
`gotcha(myseq, myseq[0])` shape — stops compiling, and the fix is to copy the element out first or to split the
call. Code that mutates a collection mid-iteration stops compiling too, and the fix is an index loop. Both
failures are cheap; the Nim 2 failures were a wrong answer and a runtime assertion.

`move` and `sink` behave the same in both compilers, including the empty value left behind, so a Nim 2 program
that moved a string keeps working. What does not carry over is the assumption that the compiler tracks the move
without being asked; `ensureMove` exists in both, but Nim 2.4.0 words its refusal differently
(`cannot move 'a', which introduces an implicit copy`) than the pin's `not the last usage of: a`.

## Samples

`samples/14-ownership-borrow/ownership.nim`, compiled and run at the pinned commit:

```
$ nimony c -r samples/14-ownership-borrow/ownership.nim
pair 2 1
during 1
during 2
name new
window 3 first 10
taken payload left 0
cell 7 gone true
kept shared payload shared
```

Eight lines, in that order. `tools/verify-samples.sh` compiles and runs it with every other sample in the book
and exits 0 only when all of them do; it does not compare stdout, so the eight lines above are the expected
output and the thing to check by eye.

## Checks

1. Write `take(a: var int, b: int)` and call it as `take(x, x)`. It compiles. Change `b` to `seq[int]` and call
   it as `take(s, s)`. It does not. Now make `b` an `array[25, uint8]` and call `take(v[0], v)`, which fails
   too. State which property of the second parameter decides in each case, in one sentence each.
2. Take the `Plain`/`Named` pair from this chapter and add one `string` field to `Plain`. Compile both calls
   again and say which one now fails and why the error points at `plain.x`, the mutable argument.
3. Rewrite the `addItem(s, x)` loop as an index loop. Both versions do the same work; say what the index version
   does not take.
4. Move a `string` into a `let`, print the length of the old name, then print the old name itself. Write down
   what you expect before running it, and check the moved-from value matches the second column of the table.
   Then replace `move` with `ensureMove`: note what changes, and why the failure arrives before the program runs.

## Chapter checklist

`draft 2026-11-13 · tech_review Momo 2026-11-13 · editorial_pass 2026-11-13 · frozen 2026-11-13`
