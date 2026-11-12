---
chapter: 13
title: References, Pointers, and Explicit Nilability
job: Separate managed `ref` from raw `ptr`, write the nil-ability into the type (`nil ref T`), and dereference only after proving non-nil.
nimony_version: 0.6.3
nimony_commit: 4ba90a781b0b22d0821efaa153c129c37cef6143
toolchain: ~/.local/opt/nimony/4ba90a7
host_compiler: ~/.local/opt/nim-2.4.0
status: frozen
tech_review: Momo 2026-11-13
editorial_pass: 2026-11-13
samples: [samples/13-references-pointers-nil/refs.nim]
glossary_added: [ref (sourced), ptr (sourced), explicit nilability (extended), nil narrowing]
---

# References, Pointers, and Explicit Nilability

## What this chapter is for

Every value you have built so far is copied when you assign it, and a parameter is a copy of what the
caller passed. That model breaks down the moment two parts of a program have to look at the same cell, or a
part of the program wants to touch storage that belongs to someone else. Nimony answers with two different
tools — a managed `ref` and a raw `ptr` — and, on top of both, one deliberate restriction: **a pointer-like
value is not nil unless the type says it is**.

This chapter has three jobs, in order: choose between `ref` and `ptr`, write nil-ability into the type when
you need it, and get past the compiler's proof requirement at the point where you dereference.

## Two ways to refer to a thing

A `ref T` is a managed reference: the cell lives on the managed heap, the runtime keeps it alive as long as
any reference to it exists, and several names can point at that one cell. A `ptr T` is the untraced form —
a raw address you obtained yourself, with no lifetime behind it. `doc/language.md:774-783` draws the line
between traced and untraced references this way.

The practical consequence is aliasing, and it changes how a parameter behaves. In Chapter 11 the rule was
that a by-value object parameter is not a place, so writing to it is pointless and rejected. A `ref`
parameter is the opposite: the copy is a copy of the *reference*, and writing through it reaches the cell.

```nim
type Counter = ref object
  n: int

proc bump(c: Counter) =
  c.n += 1
```

No `var` on the parameter, and the caller sees both increments. `c.n` is shorthand: `.` on a reference
dereferences automatically, and `[]` does the same for indexed access (`doc/language.md:794-807`). Writing
`c[].n` is legal and, as the documentation says, discouraged — it gives the same result.

Two references compare by identity, not by contents: `a == b` is `true` when both names reach the same cell,
and `false` for two distinct cells with equal fields, because reference equality is the `EqRef` magic
(`src/nimony/magics.nim:64`). This is not the object equality Chapter 11 taught. That operator walks fields,
and it applies to the object value — `a[] == b[]` — not to two references to it.

Writing through the parameter and rebinding it are different rights. `c.n += 1` is fine; `c = Counter(n: 9)`
is refused with `cannot mutate expression c`, because the parameter is a copy of the reference and a
parameter is not assignable. You may change the cell; you may not change which cell the parameter names.

A raw pointer starts with `addr`. If `v` has type `T`, then `addr v` has type `ptr T`, and `p[]` reads or
writes the same storage `v` names:

```nim
var local = 10
let p: ptr int = addr local
p[] = 20
echo local          # 20
```

`addr` works on a whole variable or on an element, so `addr arr[1]` gives a `ptr int` that writes into the
array. This is the unsafe half of the language: nothing checks that the storage still exists when you write
through the pointer. The rest of this chapter is about the one thing the compiler *will* check for you,
which is whether the pointer is nil.

## A pointer type that cannot be nil

`ref`, `ptr`, `pointer`, `cstring` and procedural types cannot hold `nil` unless their type says so
(`doc/language.md:839`, and the fuller treatment at `doc/lenientnils.md:7-19`). The compiler prints such a
type with the fact spelled out — `ref Node.Obj not nil` — so a message that looks odd at first is quoting
the type back at you.

Three different errors guard the three different ways you can get this wrong, and it is worth learning to
tell them apart, because each one has a different fix.

**You handed it nil.** `var r: Node = nil` against a not-nil `Node` is refused with `expected non-nil value`
(`src/nimony/contracts.nim:280`, reached from `checkNilMatch`). Nothing was analysed: nil is simply not a
value of that type.

**There is nothing to analyse.** `cannot analyze expression is not nil: g` means the expression's root is not
a place the compiler will reason about. At this pin that is one case: a module-level variable. `analysableRoot`
(`src/nimony/contracts.nim:249-275`) walks dots, subscripts and dereferences down to a base symbol, then
refuses the symbol when it is a global, because a global is assumed to be shared between threads, so
`if glob != nil: use glob[]` cannot be proven correct. A dereference is not excluded: `if q != nil: echo q[].data`
analyses fine when `q` is a local. The comment on that branch ends with "Maybe this needs a better solution", so
treat this as the pin's behaviour rather than a permanent rule.

**It is a local and there is no fact.** `cannot prove expression is not nil: x` means you dereferenced a
nilable local that no guard has covered. The fix is a guard, and the next section is about where the
compiler accepts one.

The first of these has a second face. A type that cannot be nil has **no default value**, because zeroed
storage reads as nil and that is exactly what the type rules out. So a module-level declaration with no
initial value is refused:

```
Error: 'base' is of type 'ref Node.Obj not nil', which has no default value
(it contains a not-nil pointer): give it an initial value
```

`src/nimony/contracts_fir.nim:5798-5821` builds that message. The same rule catches an array of them
(`array[0..2, ref Node.Obj not nil]`), an object with such a field (`'p' is of type 'Pair'`), and a
procedural type (`'cb' is of type 'proc (x: int64)'`). Two other `zeroedStorage` reasons use the identical
message — a range that excludes zero, and an enum without a member of ordinal 0 — and those belong to
Chapters 4 and 11.

A **local** is treated differently, and the source states why: the local owes nothing at its declaration,
because the flow analysis allows `var r: ref int` to stand as long as a write reaches it before any read,
which is more permissive and equally safe (`src/nimony/contracts_fir.nim:5805-5811`). Read it too early and
the error changes to a different one — `cannot prove that r has been initialized`
(`src/nimony/contracts.nim:357`).

```nim
proc ok =
  var r: ref int
  r = make()          # a write first
  echo r[]

proc notOk =
  var r: ref int
  echo r[]            # Error: cannot prove that r has been initialized
```

## Writing nilability into the type

Prefix the type with `nil` and it may hold nil: `nil ref int`, `nil ptr int`, `nil cstring`,
`nil pointer`, `nil proc (x: int)`, `nil Node` (`doc/language.md:841-853`, `doc/lenientnils.md:65-75`). A
linked list says it at every link:

```nim
type Node = ref object
  data: int
  next: nil Node
```

The cost of writing it is an obligation: every dereference of a `nil` value has to be guarded by a check the
compiler can see. The benefit is that `nil` stops being a runtime surprise and becomes an argument the type
checker can carry.

A nil literal is a fine argument where a `nil` parameter is expected, so `total(nil)` is a normal call for a
`proc total(list: nil Node)`. Passing a not-proven-nil value where a **not-nil** parameter is expected is the
first error again: `cannot prove expression is not nil: m`.

### What the compiler accepts as proof

The check is a fact attached to a **place**, and the facts are tracked per local (`src/nimony/inferle.nim:137-142`
is where the `is not nil` and `is nil` facts are built). Four shapes work:

- `if x != nil:` narrows `x` inside the branch.
- `if x == nil: return` narrows `x` after the branch, because that branch does not continue.
- `x != nil and x.field > 0` narrows the right operand.
- `while it != nil:` narrows the loop body, which is what makes a list walk legal.

The walk needs one careful detail. The loop condition must test a **local**, so the sample copies the
parameter into `var it = list` and advances `it`. Testing the parameter directly fails for an unrelated
Chapter 8 reason — a parameter is not mutable, and `list = list.next` is refused with
`cannot mutate expression list`.

The fact is bound to the place, not to the cell, so anything that writes the place drops it:

```nim
if x != nil:
  x = nil
  echo x[]        # Error: cannot prove expression is not nil: x
```

Two traps follow from the same design, and both cost an afternoon if you meet them unprepared.

**Assigning a value that is certainly not nil does not refine the variable.** The nilability is in the type,
so it survives the assignment:

```nim
let m: nil Node = Node(data: 3)
echo m.data        # Error: cannot prove expression is not nil: m
```

The type of `m` is `nil Node`; the fact set has nothing to say about it, because a fact is what a comparison
established, not what the initialiser was. Add the guard, and it compiles.

**Narrowing does not reach through a field.** `if p.n != nil: echo p.n.data` is rejected with
`cannot prove expression is not nil: p.n`. `analysableRoot` walks the dot expression down to its base symbol,
so `p.n` and `p.m` are both the place `p` in the fact set: a fact recorded by `if p.n != nil` is a fact about
`p`, which says nothing about `p.n`. This is a limitation of the analysis as it stands, not a rule of the type
system, and the source marks it as provisional. Copy the field into a local, test the local, and use the local.
That is exactly why the list walk in the sample works through `it` rather than through `list.next`.

## Allocation, and the place you hand to `new`

`new` is how you get a managed cell for a type that is not an object construction:

```nim
func new*[T: ref](x: out T) {.inline.} = x = newConstr(T)
```

(`lib/std/system.nim:200`.) The parameter is `out T` for any `T` that is itself a ref, and `T` may be the
not-nil form. A not-nil local is therefore a legal destination, and the type is the proof you need:

```nim
proc boxedNotNil(v: int): ref int =
  var tmp: ref int        # not-nil, no default value, no complaint at the declaration
  new(tmp)
  tmp[] = v
  tmp
```

Nothing has to be guarded here. `tmp` is a `ref int` before the call and a filled `ref int` after it, so the
return accepts it without a check. What you cannot do is change your mind afterwards: `tmp = nil` is refused
with `expected non-nil value`, and `tmp == nil` compiles to `false`.

A module-level not-nil declaration is a different failure, and it is not about `new`: `var x: ref int` at
module level has no default value, so the declaration is refused before `new` sees it.

The sample's `boxed` takes the nullable variant instead, for a value that has to be checked while the program
runs:

```nim
proc boxed(v: int): ref int =
  var tmp: nil ref int = nil
  new(tmp)
  if tmp == nil: quit "out of memory"
  tmp[] = v
  tmp
```

With a nullable destination, `new` establishes nothing on its own: the fact engine learns from comparisons,
not from calls, so `result = tmp` straight after `new(tmp)` is rejected with `cannot prove expression is not
nil: tmp`, at every use of `tmp`. The guard is load-bearing, not decoration; `quit` on the nil branch satisfies
both analyses at once, because the branch does not continue and `result` is assigned on the one path that does.

An object construction is the easy case, and it is worth knowing that the two are not equivalent:
`Node(data: 9)` has the not-nil type `Node` and can be assigned to a `var r: Node` directly, while `new` hands
you the destination's type — a not-nil local is already a `ref T`, and a nullable one still asks you to dispose
of the nil case in writing.

## Raw pointers, `unchecked`, and the porting switch

A `nil ptr int` follows the same rules as a `nil ref int`: it holds nil, it dereferences under a guard, and
it is refused unguarded. A `ptr T` assigns to a `pointer` without a cast, and `pointer` is itself a
pointer-like type that cannot be nil, so `var p: pointer = nil` is `expected non-nil value`.

When the nil case is genuinely outside the type system's reach — an FFI handle, an invariant like "the
status field says success implies the pointer is set" — you opt out with `unchecked`, which is accepted on
`ref`, `ptr`, `pointer`, `cstring` and procedural types and disables nil tracking for that type
(`doc/language.md:867-877`, `doc/lenientnils.md:102-115`):

```nim
type Handle = object
  h: unchecked ref int

var x: Handle      # fine: an unchecked pointer has a default value
```

Use it where you can prove non-nil some other way, and nowhere else. It is the one spelling in this chapter
that gives up the guarantee instead of satisfying it.

## Nim 2 delta

> **What Nim 2 did.** Every `ref`, `ptr`, `pointer` and `cstring` could hold nil, and every declaration got
> zeroed storage, so `var x: ref int` at module level was legal and silently nil. Reading through it was a
> runtime fault: the same program compiled and died with `SIGSEGV: Illegal storage access. (Attempt to read
> from nil?)`.
>
> **What Nimony does.** Nil-ability is part of the type. A plain `ref T` cannot be nil, a declaration with a
> not-nil pointer has no default value, and an unguarded dereference does not compile. The nullable form is
> spelled `nil T`.
>
> **What breaks if you keep the habit.** Module-level buffers, object fields and procedural variables that
> relied on being zeroed now need an initial value. Helpers that accept nil to mean "absent" need `nil T` in
> their signature. And the escape hatch is honest about its price: under `{.feature: "lenientnils".}`
> (`doc/lenientnils.md:141-155`) the old code compiles again, with no compile-time diagnostic at all, and the
> nil dereference becomes a runtime fault: the process dies where it dereferences. On the toolchain and platform
> used for this book that is exit 139, which is a measurement and not a promise; what the switch restores is
> Nim 2's semantics, a pointer checked at run time instead of at compile time.

## Samples

`samples/13-references-pointers-nil/refs.nim` is the file behind the fragments above: a shared counter, a
list walked under `while it != nil`, a cell allocated through `new` and guarded, and a raw pointer writing a
local. Run at the pin:

```
$ nimony c -r samples/13-references-pointers-nil/refs.nim
2
6
0
42
20
```

The five lines are the counter after two `bump` calls, the list total, the total of an empty list passed as
`nil`, the boxed value plus one, and the local written through `p[]`.

## Checks

1. Declare `var g: nil Node = nil` at module level and read `g.data` inside a proc under `if g != nil:`. The
   expected outcome: it does **not** compile, and the message is `cannot analyze expression is not nil: g`.
   Copying `g` into a local inside the proc does not help — that copy is an unsynchronised read of a global,
   refused with `unsynchronized access to global variable 'g'`. Pass `g` as a parameter, or take the copy at
   module level, and it compiles.
2. Write `let m: nil Node = Node(data: 3)` and read `m.data`. Expected: `cannot prove expression is not nil:
   m`. Add `if m != nil:` and confirm it passes.
3. Write `type Holder = object` with a field `n: nil Node`, fill a `Holder` with a real node, then
   `if h.n != nil: echo h.n.data`. Expected: rejected on `h.n` with `cannot prove expression is not nil: h.n`,
   and that is the only error; leave `h` uninitialised and the first complaint is `cannot prove that h has been
   initialized` instead. Copy the field into a local and confirm it passes.
4. Change `total` to take `Node` instead of `nil Node` and call it with `nil`. Expected: the argument is
   rejected before the body is checked.

## Chapter checklist

`draft 2026-11-13 · tech_review Momo 2026-11-13 · editorial_pass 2026-11-13 · frozen 2026-11-13`
