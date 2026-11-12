---
chapter: 3
title: Values, Names, and Mutability
job: Introduce `let`, `var`, `const`, lexical scope, and the fact that names are case-sensitive.
nimony_version: 0.6.3
nimony_commit: 4ba90a781b0b22d0821efaa153c129c37cef6143
toolchain: /Users/sachiel/.local/opt/nimony/4ba90a7
host_compiler: /Users/sachiel/.local/opt/nim-2.4.0
status: frozen
tech_review: Momo 2026-11-12
editorial_pass: 2026-11-12
samples: ["samples/03-values-names-mutability/values.nim"]
glossary_added: ["let variable", "case-sensitive identifier", "scope (of a name)", "zero value"]
---

# 3. Values, Names, and Mutability

## What this chapter is for

Nimony gives you three ways to put a name on a value, and they differ in one question only: *can this name be
written again after the line that declares it goes by?* `const` says no and fixes the value before the program
starts. `let` says no and fixes it when the declaration runs. `var` says yes.

That is the whole rule, and it is worth learning precisely now because nearly every later chapter reads better
when you know which names are allowed to change. The chapter also covers the two things about names themselves
that Nimony does differently from Nim 2: spelling is exact, and a name lives only in the block that declared it.

## Three declarations, three promises

### `const`: fixed before the program runs

A `const` is bound to a constant expression. `doc/language.md` at the pin restricts those to literals, built-in
operators, previously declared constants, and calls to routines whose arguments can all be evaluated at compile
time (`doc/language.md:24-31`). The value is settled while compiling, so by the time your program starts there is
nothing left to compute.

```
const Language = "nimony"
const Banner = Language & " / names and values"
```

The concatenation happens during compilation. So does a call, when nothing in it needs the program to be running:

```
proc double(x: int): int = x * 2
const Twice = double(4)          # 8, computed while compiling
```

`doc/language.md:1711-1733` changes the subject after that: a constant's symbol can be used as a constant
expression, and the value part of each constant opens its own scope, so a name declared inside one does not leak
into the next line.

### `let`: single assignment

`let` binds a value once, at the point where the declaration runs, and refuses every write afterwards. It is the
declaration to reach for by default: most values in a well-shaped program are read many times and written once.

```
let limit = 3
```

Writing to it is a compile error, not a runtime one:

```
Error: invalid reassignment to `let` variable
```

`doc/language.md:1640-1655` adds two consequences worth knowing before they surprise you. A `let` variable is not
an l-value, so it cannot be passed to a `var` parameter and its address cannot be taken. And because the value is
immutable from the start, a `let` must have an initializer — the only exception is a declaration that takes its
value from native code through an `importc`-style pragma.

### `var`: the one that can be written again

`var` declares a mutable name. This is the declaration that changes, and in Nimony it is also the one with the
most checking attached:

```
var total = 0
for i in 1 .. limit:
  total = total + i
```

A `var` at module level starts at its type's zero value whether or not you write one: `int` reads `0`, `string`
reads `""`, an object built from them is all-zero.

Inside a routine the rule is the guide's (`doc/language.md:1591-1630`): a local must be proven written before it
is read. `var chosen: int` that no path writes stops the build with `Error: cannot prove that chosen has been
initialized`; writing in both branches satisfies the analysis, writing in only one does not.

The check is about proof, not about the type: `int` fails it too. A module-level `var` of a type with no default
value is a different case and is refused at the declaration:

```
Error: 'base' is of type 'ref int64 not nil', which has no default value (it contains a not-nil pointer): give it an initial value
```

`{.noinit.}` turns the check off and hands you the raw storage: a read before a write returns whatever was in
memory, not `0`.

## Names are case-sensitive

This is the first real difference from Nim 2, and it is a difference in spelling only.

Nimony is case-sensitive: two identifiers that differ in case are two identifiers (`doc/language.md:7`;
`doc/differences.md:22`). So this compiles, and both names stay live:

```
let step = 2
let Step = 5
echo step      # 2
echo Step      # 5
```

Nothing is "close enough". Using a spelling that does not exist is an error at the use site:

```
Error: undeclared identifier: my_value
```

where the declaration was `let myValue = 1`. The reason for the change is stated plainly in the language guide —
implementation simplicity — and it may change in the future, which is exactly why the book states it at the pin
rather than as a permanent truth.

If you are porting a module and need Nim 2's rules back, the escape hatch exists and is per module:

```
{.feature: "ignoreStyle".}
```

With that line at the top, `myValue`, `my_value` and `myvalue` resolve to the same symbol. It is a compatibility
switch, not a style the book teaches; code written fresh should spell names exactly.

## Where a name lives

An identifier is valid from the point of its declaration to the end of the block it was declared in
(`doc/language.md:4752-4765`). An inner block may declare the same spelling again, and inside that block the
inner declaration is the one you get:

```
block:
  let step = 100
  echo step     # 100

echo step       # 2 — the outer let, untouched
```

Two rules keep this from becoming a puzzle. An identifier cannot be redeclared in *the same* block, only in a
nested one — the compiler says `Error: attempt to redeclare: step`. And the special name `_` is never added to
scope at all, so `let _ = 123` is evaluated and then discarded, and you can write it again as often as you like.

## Nim 2 delta: spelling and when `const` is computed

> **What Nim 2 did.** Identifiers were style-insensitive: `myValue`, `my_value` and `myvalue` were one name, and
> mixed spellings in one file were normal. `const` values were evaluated by a restricted compile-time evaluator.
>
> **What Nimony does.** Identifiers are exact (`doc/language.md:7`), with `{.feature: "ignoreStyle".}` available
> per module for ported code. `const` is evaluated by a compile-time engine that accepts a routine call as long as
> every argument can be evaluated while compiling (`doc/language.md:24-31`), which is why `const Twice = double(4)`
> works.
>
> **What breaks if you keep the habit.** Ported code stops at `undeclared identifier` on a spelling variant that
> Nim 2 accepted — a mechanical fix, but one that arrives as a hundred errors, not one. And a `const` whose value
> depends on a `var` is still a compile error, so computing a "constant" from runtime data stays impossible; the
> fix is `let`, not a pragma.

## Samples

- `samples/03-values-names-mutability/values.nim` — one program that declares all three, computes a `const` with a
  call, keeps two case-differing names alive, shadows one in a nested block, and declares a module-level `var`
  without a value that both branches then write. Proven by `tools/verify-samples.sh`:

  ```
  PASS samples/03-values-names-mutability/values.nim exit=0
  ```

  Expected output, in order — the verifier checks compile, run and exit code, not stdout, so this list is the
  check:

  ```
  nimony / names and values
  8
  6
  2
  5
  100
  2
  1
  ```

## Checks

1. Declare `let n = 1` and then `n = 2`. Expected: a compile error reading `invalid reassignment to \`let\` variable`,
   reported at the assignment, not at the declaration.
2. Declare `let step = 2` twice in the same block. Expected: `attempt to redeclare: step`. Move the second one
   inside a `block:` and both compile.
3. Declare `let myValue = 1`, then `echo my_value`. Expected: `undeclared identifier: my_value`. Add
   `{.feature: "ignoreStyle".}` above the declaration and run it again: expected, it compiles and prints `1`.
4. Compute `const Twice = double(4)` where `double` is a one-line proc. Expected: it compiles and prints `8`.
   Then change the argument to a `var` and build again. Expected: a compile error at the `const` line — a `const`
   cannot depend on runtime data.
5. Write `var chosen: int` inside a proc, no path writing it, then read it. Expected:
   `cannot prove that chosen has been initialized`. Then make every path write first and build again: expected, it
   compiles. Note that the same block at module level does not fail — there the value is `0`.

## Chapter checklist

draft 2026-11-12 · tech_review Momo 2026-11-12 · editorial_pass 2026-11-12 · frozen 2026-11-12
