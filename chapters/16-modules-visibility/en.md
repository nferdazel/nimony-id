---
chapter: 16
title: Modules and Visibility
job: Split a program across files, mark what leaves a module with `*`, and import selectively.
nimony_version: 0.6.3
nimony_commit: 4ba90a781b0b22d0821efaa153c129c37cef6143
toolchain: ~/.local/opt/nimony/4ba90a7
host_compiler: ~/.local/opt/nim-2.4.0
status: frozen
tech_review: Momo 2026-11-13
editorial_pass: 2026-11-13
samples: [samples/16-modules-visibility/modules.nim]
glossary_added: [module, export marker, attached routine, re-export, include]
---

# Modules and Visibility

## What this chapter is for

Every program so far has been one file. Real programs are not, and the reason is not tidiness: a file boundary is
where the language decides who may call what. That decision is the whole subject here. Nimony has no package
manifest, no module header and no namespace declaration. A file is a module, its name is its name, and a single
`*` on a declaration is what lets another file see it.

The order below follows a reader splitting one file in two: how a second file gets compiled at all, what `import`
actually brings in, what stays private and what the compiler says when you reach for it, the five import spellings
and what each one hides, and then the rule most readers have never met in another language — a call also sees the
routines attached to its argument's type, whether or not the caller imported them.

## A module is a file

The file name is the module name, minus `.nim`. `support/shapes.nim` is the module `shapes`, and that is the name
an import and a qualified call use, never the path:

```nim
import support/shapes
echo shapes.describe(square)
```

Both lines work at the pin: the import takes a path with `/`, and the qualified form takes the module name. A
subdirectory is not a namespace, so two files named `shapes.nim` in different directories are two modules both
called `shapes`. Importing both by path is fine as long as the calls are unqualified; a qualified `shapes.aval()`
then fails with `ambiguous identifier`, and the repair is an alias on one of the imports.

Module-level statements of an imported module run before the body of the file that imports it, even when the
import sits in the middle of the file:

```nim
# util.nim
echo "module init"
var ready* = 1

# main.nim
echo "main start"
import util
echo "ready ", ready
```

That prints `module init`, `main start`, `ready 1`. The import is a compile-time statement whose position in the
source does not order anything: the imported module's own statements have already run by the time `main start`
appears.

## What `import` brings

`import` brings the exported top-level names of the module into scope, unqualified:

```nim
# util.nim
proc greet*(name: string) =
  echo "hello ", name

# main.nim
import util
greet("ada")
```

There is no implicit prelude to inherit. Each module states what it uses, including `std/syncio` before it can
call `echo`, which is why every module in this book starts with that import.

Imports are not transitive. If `b` and `c` both import `d`, a file that imports `b` and `c` still cannot call
`d`'s routines; it must import `d` itself. That is deliberate and it is the property that keeps a change in `d`
from silently widening what `b`'s callers see.

## The export marker

A declaration without `*` is private to its module. A call to it from another file fails, and the message does not
use the word private:

```
main.nim(3, 1) Error: undeclared identifier: 'secret'
```

That is the same message an undeclared name gets, and it is the whole diagnostic. There is no "declared here but
not exported" line to read, so the reader checks the declaration for the `*` first.

The marker goes on each declaration you want to leave the module: a `proc`, a `type`, a `const`, a `let` or a
`var`. It goes on object fields separately, and the field is where the rule is easiest to see:

```nim
# util.nim
type Point* = object
  x: int
  y*: int

proc make*(a, b: int): Point = Point(x: a, y: b)

# main.nim
let p = make(1, 2)
echo p.y
echo p.x
```

`p.y` prints, and `p.x` is refused with `undeclared field: 'x' for type Point`. The type is exported and the field
is not, so the caller can hold a `Point` and cannot read half of it. An enum is all or nothing: exporting the type
makes its members usable by name, and there is no marker that exports one member and not its siblings.

The field rule has one soft edge worth knowing before you rely on it. A constructor call from outside the module
does not have to name the private field:

```nim
let p = Point(y: 2)
```

That compiles, and the private `x` takes its default, `0`. Nothing warns. A constructor is not a check that every
field was considered, so an object with a private field needs a constructor routine that sets it, and callers
should not build the object themselves.

## Reading what a name is not

A private type returned by an exported routine is a usable handle:

```nim
# util.nim
type Hidden = object
  v: int
proc make*(): Hidden = Hidden(v: 5)
proc show*(h: Hidden) = echo "hidden ", h.v

# main.nim
let h = make()
show(h)
```

That prints `hidden 5`. The caller cannot name `Hidden`, cannot declare a variable of that type, and cannot read
`h.v`; it can hold the value, pass it back, and let the module's routines work on it. This is the cheapest
encapsulation the language offers, and it costs one missing `*`.

## Five import spellings

The plain `import m` is the one above. The other four narrow it, and they differ in what remains visible, not in
what is loaded.

```nim
import util as u        # calls go through u., and util. is no longer a name
import util except greet
from util import greet  # only greet, unqualified
from util import nil    # nothing unqualified; util.greet still works
```

`import util as u` gives the module a second name and takes the first one away: after it, `u.greet("ada")` builds
and `util.greet("ada")` fails with `undeclared identifier: util`. What it does not do is hide the unqualified
names — `greet("ada")` still works, because the alias renames the qualifier, not the imported symbols.

`import util except greet` imports everything but `greet`, and calling `greet` then fails as an undeclared
identifier. The list is not checked against what the module exports: naming a private routine in it is accepted
silently, so a typo in an `except` list narrows nothing and reports nothing.

`from util import greet` imports that one name and nothing else; a second exported routine from the same module is
undeclared. Naming a private routine there is refused with the same `undeclared identifier` message.

`from util import nil` imports no names at all and keeps the qualified form, which is how a module can be used
entirely through `util.name` calls. It combines with the next section: the routines attached to a type still
resolve even when nothing was imported unqualified.

## Routines attached to argument types

This is the rule that makes a call compile when nothing in scope declares the routine. `doc/language.md:1280-1315`
states it: for every argument whose type is a nominal type declared in another module, the exported top-level
routines of that module with the call's name and a parameter of that type join the candidates, as if they had been
imported. The type may sit behind `var`, `sink`, `lent`, `out`, `ref` or `ptr`, and for a generic instance it is
the module that declares the generic.

So this compiles with only the type imported:

```nim
# inner.nim
type Thing* = object
  v*: int
proc show*(t: Thing) = echo "thing ", t.v
proc banner*() = echo "unrelated"

# main.nim
from inner import Thing
let t = Thing(v: 3)
show(t)
```

`show` resolves and `banner` does not, because `banner` never mentions `Thing`. The boundary is the parameter
list, not the module: a routine from the same module that takes the type is reachable, and one that does not is
not. Nor is it the argument's module in general — a routine declared in a third module that happens to take
`Thing` is not attached, and stays invisible unless imported.

Two consequences matter in practice. A module can be imported with `from m import nil` and still be used through
its types' routines, qualified or not. And a non-exported routine is never attached, so marking a routine private
is enough to keep it out of this lookup as well.

## `export` re-exports

A module that wraps another can forward it, so its own callers do not import both:

```nim
# support/report.nim
import shapes
export shapes
```

After that, a file importing `support/report` sees `Shape`, `shape` and `describe` without importing `shapes`.
The forwarding can also name one symbol, `export shapes.Shape`, and then the type crosses while the module's other
routines do not — except the ones attached to it, which arrive by the previous section's rule.

The name in an `export` statement is a module name, not a path, and it resolves like an import: relative to the
file doing the exporting. A module inside a subdirectory therefore imports its sibling as `import shapes`, not as
`import support/shapes`, and exports it the same way.

That last distinction is not cosmetic. An `export` operand that is not a plain name or `module.name` — a path is
the realistic way to hit it, but a bare `export 3` is enough — never reports anything: the front end spins at full
CPU and grows memory with no output, and it does not stop on its own. The failure is in the export statement, not
in resolving the path, so a correct `import` above it does not save the build.

## `include`

`include` is not an import. It pastes the file's text into the including module, so nothing is exported and no
visibility applies:

```nim
# part.nim
proc twice(n: int): int = n * 2

# main.nim
include part
echo twice(4)
```

That prints `8` with no `*` anywhere, because `twice` is now a declaration of `main`. Use `include` to split one
module's body across files, never to share code between modules: what the included file declares becomes the
includer's, including its private names.

## Cycles

Two modules that import each other are refused:

```
Error: import cycle: 'b.nim' imports 'a.nim' without {.cyclic.}; every import on a cycle needs it
```

The pragma on each import on the cycle makes it build. It is a deliberate opt-in, and the message names the file
and the import that are missing it, so the repair is spelled out: put `{.cyclic.}` on both.

## When two modules export the same name

Two imports that bring the same name make the call ambiguous, and the message lists both declarations with the
file and line of each:

```
main.nim(3, 5) Error: ambiguous call: 'show'
proc (n: int64) (declared in one.nim(2, 1))
proc (n: int64) (declared in two.nim(2, 1))
```

The fix is to take one side out of the plain import: `import one except show`, or a qualified `one.show(...)`, or
narrow both sides, `from one import show` together with `from two import nil`. A `from` on one side alone does not
settle it while the other side is still a plain import — both declarations stay in scope and the call stays
ambiguous.

## Mutable globals across a module boundary

An exported `var` is not the shared state a reader expects. A direct write to it from a routine body is refused,
in its own module as much as in another:

```
util.nim(5, 7) Error: unsynchronized access to global variable 'counter'; pass it to a `.sync` routine or use `{.cast(assumeSync).}`
```

Module-level statements are exempt, because module initialization is single threaded, so `counter = 9` at the top
of a file compiles and works. A routine body needs the check switched off for that access, and `{.cast(assumeSync).}:`
around the block does it:

```nim
proc bump() =
  {.cast(assumeSync).}:
    inc counter
```

The message's own suggestion is the fourth route and it is a real one: hand the global — or one of its fields or
elements — to a `var` or `ptr` parameter of a `.sync` routine, which may be one you write yourself:
`proc own(p: var int) {.sync.}` then `own(counter)` builds and increments. `.sync` is trusted, not checked. So the
routes are module-level statements, `{.cast(assumeSync).}:`, `{.feature: "assumeSync".}`, and a `.sync` routine.
All four are promises you are making, not checks the compiler has dropped.

## Two places the manual does not match the pin

The import statement is accepted inside a routine body, where `doc/language.md` says it is only allowed at the top
level, and it takes effect for the whole module: a call after the routine that contains the import builds too. The
chapter teaches the top-level form. The other is worse. An `export` operand that is not a name spins the front end
with no output instead of failing, as the `export` section says. Both are in the review note and in `ERRATA.md`;
neither changes what this chapter teaches.

## Nim 2 delta

*What Nim 2 did.* A module was a file too, `*` meant export, and `import x as y`, `except` lists and `from ... import`
existed with the same spellings. Nim 2 also injected `system` everywhere, so `echo` needed no import, and its
overload resolution did not reach a type's module for an ordinary call.

*What Nimony does.* The spellings survive; two habits do not. Every module imports `std/syncio` before it echoes,
and a call can find a routine attached to its argument's type even when the module was imported with `from m import nil`.
The exported-variable rule is also new in practice: a mutable global is refused from a routine body unless the
check is off for that access.

*What breaks if you keep the habit.* A module copied from Nim 2 fails to build on `echo` until `std/syncio` is
imported, and a renamed import used as a way to hide names does not hide them — `import util as u` still leaves
`greet` callable. Reach for `from` or `except` when narrowing is what you meant.

## Samples

`samples/16-modules-visibility/modules.nim`, with three files under `samples/16-modules-visibility/support/`,
compiled and run at the pinned commit:

```
$ nimony c -r samples/16-modules-visibility/modules.nim
square: 4 sides, 360 degrees
4 sides
square: 4 sides, 360 degrees
SQUARE
note: square
square has 4 sides
```

Six lines, in that order. The first comes through the re-exported module, the second from a routine that module
adds, the third is the same routine called through the module name, and the last three show a second module's
routine, an included file's routine, and a field read. `tools/verify-samples.sh` compiles and runs it with the
rest of the book and does not compare stdout, so these six lines are the thing to check by eye.

## Checks

1. Split a one-file program into two, exporting only the routine the other needs. Read the message you get before
   you add the `*`, then add it and confirm nothing else changed.
2. Take the `Point` from this chapter and build one from `main` without naming `x`. Print `p.y`, then add a routine
   in the module that prints `p.x` and explain why the value you see is `0`.
3. Change `import util` to `from util import nil` and make every call qualified. Then delete the qualification
   from a call whose argument is the exported type and explain why it still builds.
4. Make two modules import each other, read the cycle message, then add `{.cyclic.}` where it asks. Say what you
   had to change in the second module, not just the first.
5. Export a `var` and write it from a routine body. Read the message, then fix it with `{.cast(assumeSync).}` and
   write down what you promised the compiler.

## Chapter checklist

`draft 2026-11-13 · tech_review Momo 2026-11-13 · editorial_pass 2026-11-13 · frozen 2026-11-13`
