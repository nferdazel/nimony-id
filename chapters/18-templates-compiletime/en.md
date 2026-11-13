---
chapter: 18
title: Templates and Compile-Time Evaluation
job: Remove repetition with hygienic templates and evaluate work at compile time with `const`.
nimony_version: 0.6.3
nimony_commit: 4ba90a781b0b22d0821efaa153c129c37cef6143
toolchain: ~/.local/opt/nimony/4ba90a7
host_compiler: ~/.local/opt/nim-2.4.0
status: frozen
tech_review: Momo 2026-11-13
editorial_pass: 2026-11-13
samples: [samples/18-templates-compiletime/templates.nim]
glossary_added: [template, hygienic template, injection, constant expression, compile-time evaluation]
---

# Templates and Compile-Time Evaluation

## What this chapter is for

Two ways to write something once, and they are not the same tool. A template removes repetition in the source: the
compiler substitutes its body at each call site, with the names inside it bound to where they were written. A
`const` removes repetition in the values: the compiler works the value out before the program starts, and the
program carries the result. A template can change which code exists; a `const` can only produce a value. That split
decides which one to reach for: a template when the shape repeats, a `const` when a number or a string repeats.

## A template is substituted, not called

The manual states the mechanism plainly at `doc/language.md:4504-4510`: a template is "a simple substitution
mechanism that operates on Nim's abstract syntax trees", processed in the semantic pass, and invoked with call
syntax. The body is not a routine body.

```nim
template twice(x: untyped): untyped = x + x

echo twice(3)      # 6
```

There is no call here in the compiled program, no parameter slot, no frame. `twice(3)` becomes `3 + 3`. That is why
the parameter type is not a type: `x` is `untyped`, so the argument arrives as source and is substituted where the
parameter is written.

Each expansion is checked on its own. Give the template a type it cannot satisfy and the error arrives inside the
body, with a trace to the call site:

```
main.nim(5, 1) Trace: instantiation from here
main.nim(4, 41) Error: Type mismatch at [position]
Plain(n: 1) + Plain(n: 1)
```

The second line of that message is the substituted source, not a call, and the trace names the line you have to fix.
A template is therefore checked where it is used, against the argument it is used with, not once at its definition.

## The names it declares are not your names

```nim
template bump(): untyped =
  var tmp = 99
  tmp

var tmp = 1
echo bump()      # 99
echo tmp         # 1
```

Two different `tmp`. The template's declaration is renamed to a template-private symbol when the template is
compiled, so a module-level name of the same spelling cannot collide with it and the template cannot take over the
caller's variable. The renaming is the default for every local a template declares, and `{.inject.}` is the way to
opt out of it for one declaration (`src/nimony/semuntyped.nim:214-232`; the mechanism is `makeTemplateSym` and the
gensym set that records it).

`declared` shows the same fact without needing a collision to demonstrate it:

```nim
template twice(x: untyped): untyped =
  var acc = x
  acc + acc

echo twice(21)          # 42
echo declared(acc)      # false
```

## Where a template's names come from

Hygiene has a second half: a name the body uses is resolved in the scope the template was written in, not in the
scope it is expanded in.

```nim
proc helper() = echo "module helper"

template callHelper() =
  helper()

proc scope() =
  proc helper() = echo "local helper"
  callHelper()          # module helper

scope()
```

The local `helper` has the same name, the same arity and the nearer scope, and it still does not win: the body's
`helper` was written at module level, so that is where it is looked up. Deferral is real, though: a routine declared
below the template but above the call resolves normally, so the rule is deferred in time and fixed in place.

That matters most in a library. A template cannot be hijacked by a caller that happens to declare a name of the same
spelling, which is the whole point of writing it hygienic; the price is that the template cannot borrow anything
from the caller either.

## What you pass in cannot see what the template declares

The passed block is not text pasted after the template's declarations. It was written at the call site and is
checked there.

```nim
template withValue(v: int, body: untyped) =
  block:
    let local = v
    body

withValue(5):
  echo local      # Error: undeclared identifier: local
```

The message comes with two Trace lines, one for the `withValue(5)` call and one for the block, and then
`undeclared identifier: local`. The template's `local` never existed in the block's scope.

The manual's own example of this section (`doc/language.md:4566-4583`) says the block works when the parameter is
`untyped` and fails when it is `typed`. At the pinned commit the `untyped` version fails too, with
`undeclared identifier: 'p'`, because the `proc p` the block calls is declared inside the template and is therefore
hygienic like every other local. The `typed` version fails earlier and differently, with
`expression of type ``typed`` must be discarded`. Neither shape is a route to the name; injection is.

## Injection: taking one name out on purpose

```nim
template setup() =
  proc report() {.inject.} = echo "report ready"
  let limit {.inject.} = 3

setup()
report()          # report ready
echo limit        # 3
```

`{.inject.}` on a declaration inside a template keeps the name instead of renaming it, so the caller's scope sees
`report` and `limit` after the expansion. `{.gensym.}` says the opposite explicitly, and is useful where you want the
default to be visible in the source. Both pragmas are read by `symBinding` (`src/nimony/semuntyped.nim:183-191`) and
applied in `addDecl` (`:214-232`). Object *fields* are the standing exception: a field name is injected rather than
renamed, because a field is not a local.

`{.dirty.}` is a different switch, and one that does nothing on its own. `doc/porting.md:262-282` describes it as the
pragma for a template body that must reference identifiers belonging to the *caller's* scope, and says such a
template needs `{.feature: "untyped".}` at module level. Both halves are needed: without the feature the pragma is
inert and the template's local stays invisible to the caller, and with it the local is injected into the caller and
the caller's own names resolve in the body. That cuts both ways, so it is an escape hatch for porting old code and
not an incoming-only switch: a dirty template does publish its names. Treat it as a last resort rather than the way
to get a name out of a template.

## Which parameter type to write

`untyped` is the working choice for a block or for any expression you intend to substitute, and it is what the
sample uses. The alternatives each have one job:

- **A real type** when the argument must be checked before substitution. `template addOne(x: int): int = x + 1`
  accepts `addOne(41)` and refuses `addOne("s")` with `[1] expected: int64 but got: string (declared in main.nim(2,
  1))`, naming the template's own parameter list as the place the mismatch came from. Prefer this when the argument
  is an expression of known type: the error arrives at the argument instead of inside the body.
- **`var`** when the template must write back through the parameter: `template bump(x: var int) = x = x + 2` leaves
  the caller's variable at `7`.
- **Arity** distinguishes templates that share a name, exactly as it does for routines: a one-argument `tag` and a
  two-argument `tag` coexist and each call picks its own.

Two shapes look available and are not:

- **`varargs[untyped]`** accepts the call and leaves the parameter unreadable. Anything that inspects the values
  fails at the pin: `args.len`, `echo args` and `for a in args`, the last one with `expected: openArray[T] but got:
  int64`. The parameter expands to the first argument rather than to the argument list, so `args.len` becomes
  `len(1)` and `for a in args` becomes `items(1)`. Only uses that never look at the values build: `discard args`,
  `let x = args`, or forwarding the parameter to another `varargs[untyped]` slot. Do not write it.
- **`typed`** is accepted and unusable. `template typedSlot(x: typed) = echo x` refuses `typedSlot(41)` with
  `expected: string but got: typed` for every `echo` overload, and `template passThrough(x: typed): int = x` refuses
  with `got: typed but wanted: int64`. The argument is not even resolved at the call: `typedSlot(notDeclared)` builds
  with no diagnostic, so the parameter is a placeholder, not a checked argument. Nim 2.4.0 runs both templates and
  prints `41` and `42`, so this is a difference from Nim 2 and not a mistake in the template: at this pin a `typed`
  parameter passes the meta-type through to the body instead of the argument's type. Write `untyped`, or a real type.

## Statement or expression, and the parentheses

A template whose body produces no value is a statement, and using it where a value is expected is an error at the
use, not in the template: `let v = note("hi")` gives `expression 'note("hi")' has no type (or is ambiguous)`, then a
second error from the `echo` of `v` because `v` is `void`. A template that ends in an expression is a value and can
initialize a `const` (`const Six = twice(3)` is `6`).

A call always takes parentheses. The bare name is not a call and not a proc value either: `greet` with no `()` is
`undeclared identifier: greet`, whichever way the template was declared. `doc/porting.md:255-262` documents a
different message for this mistake, `expression of type proc() must be discarded`, which the pin does not print.

## A constant is a value the compiler works out

`doc/language.md:26-31` defines the class: a constant is bound to a constant expression, and a constant expression
may depend only on literals, built-in operators, previously declared constants, and a routine call whose arguments
can be evaluated at compile time. The list is short and the consequences are concrete.

```nim
const Start = 10
const Step = Start * 2 + 1       # 21

const Greeting = "hello" & ", " & "world"
const Width = Greeting.len        # 12

const Primes = [2, 3, 5, 7]
const Count = Primes.len          # 4
```

Constants feed constants, string and array operations fold, and `len` folds for an array. `Primes[2]` is `5`, and a
string index folds to a `char`: `const First = Word[0]` on `const Word = "nimony"` is `n`. Object and enum literals work the same way, so
`const Origin = Point(x: 0, y: 0)` is a constant object and `Origin.x` is `0`.

Two ordering rules catch the reader who thinks of `const` as an immutable variable:

- A `const` cannot be initialized from a runtime value, and a `let` written above it does not help. The error is
  `undeclared identifier: runtime`, not "not a constant": only the earlier constants exist at the point the
  constant is evaluated.
- The same is true among constants. `const A = B` before `const B = 2` reports `undeclared identifier: B`, and then
  a second error where `A` is used, because `A` collapsed to `auto`.

A constant is not a variable afterwards: `Floor = 2` on a `const Floor = 1` is `cannot mutate expression Floor`. A
`const` inside a routine body is legal and is folded once, so a factor declared that way costs nothing per call.

## What the evaluator will actually compute

`doc/language.md:33` says the compile-time engine exists and that "the restrictions for this mechanism are currently
undocumented". A book cannot cite an undocumented boundary, so this section claims only what the pin demonstrates.

A call to a routine you wrote is folded, and the body may contain the ordinary control flow: `const Nine =
square(3)` is `9`; a `for` with an `if` inside is `30`; a `while` accumulating is `6`; recursion is `120` for
`fact(5)`. Containers and strings are built during evaluation as well: a `seq` grown with `add` gives `4` and `9` for
its length and last element, and a string grown with `&` gives `xxxx` and length `4`.

The boundary is not uniform, and one asymmetry is worth knowing before it wastes an afternoon. Reading `.len` of a
`const` array folds, and so does reading `.len` of a seq literal or of an array reached directly. A seq reached
through a named `const` does not:

```
main.nim(3, 20) Error: cannot evaluate expression at compile time: len(Table)

main.nim(2, 15) Error: undeclared field: 'len' for type seq[int64]
```

`(@[4, 5]).len` is `2` and `len(@[1, 2, 3])` is `3`, so the failing shape is the named-const indirection, not seq
versus array. The seq itself is a perfectly good constant: `Table.len` and `Table[1]` work at runtime on the same
value. Only the fold is missing.

When the evaluator cannot produce a value, the message names the expression it gave up on
(`src/nimony/expreval.nim:147-155`). An index outside a constant array is one case: `const Bad = [10, 20, 30][5]`
reports `cannot evaluate expression at compile time: [10, 20, 30][5]`, with no bounds message: the evaluator has no
bounds check, so it declines to fold instead of failing the way a runtime index would. Arithmetic that overflows its
type is another, and that one is a definite error at the pin: `const Overflow = 127'i8 + 1'i8` gives
`expression overflow at compile time: 127'i8 + 1'i8` (`src/nimony/expreval.nim:466-472`).

A call the in-process folder cannot handle is handed to a sub-compilation (`src/nimony/expreval.nim:283-320`,
`forwardToExecute`), which is how a routine call works at all. A routine that prints while being evaluated prints
nothing and only the value comes back, because the sub-compilation captures stdout to get the value. That is not a
promise that the rest of the body is inert: a `writeFile` inside a routine being folded writes the file during the
compilation. The constant is `40`, the terminal stays empty.

Where the language requires a constant rather than an expression, the folded value is accepted: an array length
written as `array[Width, int]` for `const Width = 4` builds, and so does `array[Slots, int]` where `Slots` came from
a routine call.

## Nim 2 delta

*What Nim 2 did.* The template syntax was the same, and a `typed` parameter worked: Nim 2.4.0 prints `41` and `42`
for the two templates that the pin refuses. A `macro` was the ordinary way to generate code, and `{.dirty.}`
templates were the escape hatch for a body that needed the caller's names.

*What Nimony does.* Templates are the supported repetition tool, checked per call site, with the body's names bound
where they were written. A `typed` parameter is accepted and not usable, so `untyped` or a real type is the route.
A `macro` with an `untyped` parameter still compiles and runs at the pin, while `doc/differences.md` lists macros as
replaced by plugins: compatibility surface, not the technique this book teaches (Chapter 19). `const` is computed by
an evaluator whose limits the manual leaves undocumented, so keep constant expressions to the shapes shown above.

*What breaks if you keep the habit.* A ported `typed`-parameter template fails at its first use with a type error
about `typed` that says nothing about the template, and the fix is to change the parameter type rather than the
body. A ported `macro` keeps compiling while the design moves away from it. And a `let` used to initialize a
`const` fails as `undeclared identifier`, which reads like a typo rather than a rule.

## Samples

`samples/18-templates-compiletime/templates.nim`, compiled and run at the pinned commit:

```
$ nimony c -r samples/18-templates-compiletime/templates.nim
6
100
report ready
3
3
9
6
```

Seven lines: `twice(3)`, then the module's own `acc` still at `100` although the same template declares a local
spelled `acc`; the injected `report` and `limit` from `setup()`; the folded `Folded.len`; `Table[3]` where `Table`
was built by a routine at compile time; and `Folded[2]`.

## Checks

1. Write `template twice(x: untyped): untyped = x + x`, call it with an `int` and with a `string`, then call it with
   a `seq[int]`. Record which call fails and where the message points.
2. Declare `var total = 1` at module level and a template that declares `var total = 99` and returns it. Confirm the
   module-level `total` still reads `1` after the call, then remove the pragma-free local and use `{.inject.}`
   instead, and say what changed for the caller.
3. Write a template that declares `let local = 1` and takes a `body: untyped` block, expand it, and have the block
   print `local`. Read the two traces, then make the block compile by adding `{.inject.}` to the declaration.
4. Write a `const` whose value comes from a routine with a `for` loop, then try to initialize another `const` from a
   `let` declared just above it. Record both messages.
5. Take a `const` seq, read its `.len` in a second `const`, then read the same `.len` at runtime. Report which of the
   two builds and why the difference matters for where you put the constant.

## Chapter checklist

`draft 2026-11-13 · tech_review Momo 2026-11-13 · editorial_pass 2026-11-13 · frozen 2026-11-13`
