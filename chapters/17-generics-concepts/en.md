---
chapter: 17
title: Generics and Concepts
job: Parameterize routines, types and constraints that are checked structurally, using concepts instead of implicit type-class generics.
nimony_version: 0.6.3
nimony_commit: 4ba90a781b0b22d0821efaa153c129c37cef6143
toolchain: ~/.local/opt/nimony/4ba90a7
host_compiler: ~/.local/opt/nim-2.4.0
status: frozen
tech_review: Momo 2026-11-13
editorial_pass: 2026-11-13
samples: [samples/17-generics-concepts/generics.nim]
glossary_added: [type parameter, static parameter, concept inheritance, Self, deferred body check]
---

# Generics and Concepts

## What this chapter is for

A generic routine is one piece of source that becomes several routines, one per type it is used with. A concept
is the constraint that says which types may be used at all. Nimony checks both at the definition, not by pasting
text and hoping: a generic body is type-checked once, against what its parameters promise, and a concept is
checked as a set of calls against the type at the instantiation. That is why the errors in this chapter arrive
before the program runs and why the messages name a constraint rather than a template expansion.

## A type parameter on a proc

Brackets after the routine name introduce the type parameters:

```nim
proc id[T](x: T): T = x

echo id(3)        # 3
echo id("s")      # s
```

The type is inferred from the argument, and the routine is instantiated once per type. The instantiation can also
be written out when inference is not what you want:

```nim
echo id[int](3)   # 3
```

Two names compete when both fit. A concrete routine beats a generic one: with `pick(x: int)` and `pick[T](x: T)`
in scope, `pick(3)` calls the concrete one and `pick("s")` falls to the generic. Generic candidates are considered
after the ordinary ones, so a generic routine is a fallback unless there is no concrete candidate at all.

## Generic types

A `type` takes the same bracket, and the parameter is usable in its fields and in the constructor:

```nim
type Box[T] = object
  v: T

let b = Box[int](v: 3)
echo b.v          # 3
```

The explicit form names the instance, `Box[int](v: 3)`. The bare `Box(v: 3)` builds too, because the field's
type is `T` and the argument settles it; write the instance when you want the call to say which `T` it produced. A
constraint may sit on the type parameter too, and then every instance must satisfy it:

```nim
type Box[T: Addable] = object
  v: T
```

## Several parameters, and what comes back

Parameters are separated by commas inside one bracket pair, and they are independent: `proc pair[A, B](a: A, b: B):
(A, B)` returns a tuple whose halves keep their own types, so `pair(1, "x")[1]` is a `string`. A generic routine
may also build and return a container of its parameter type:

```nim
proc pairUp[T](a: T): seq[T] = @[a, a]
echo pairUp(7).len   # 2
```

Nothing about the return type needs to be spelled at the call site; the instantiation follows from the argument.

## A static parameter

`static int` is a value parameter known at compile time, not a type:

```nim
proc fill[N: static int](x: int): seq[int] =
  var s = @[0]
  s.setLen(0)
  for i in 0..<N: s.add x
  s

echo fill[3](7).len   # 3
```

The two lines starting `s` are not ceremony. `var s: seq[int]` followed by `s.add x` is refused with `cannot
prove that s has been initialized`, which is Chapter 3's definite-assignment rule rather than anything to do with
the static parameter; an empty `seq` built from a literal gives the body a value it can prove was written.

The bracket form is how the value is supplied, because there is no argument to infer it from. The body may use
`N` wherever a constant is allowed.

## Checked, not pasted

A generic body is checked at the point of definition against what its parameters promise. Writing a field the
parameter does not have fails there, not at the call:

```
main.nim(2, 28) Error: undeclared field: 'nonexistent' for type T
```

The consequence is that a generic routine compiles for every conforming type or for none, and the compiler does
not wait for an instantiation to tell you the body is nonsense.

A `when` whose condition depends on the type parameter is the exception that looks like a hole. It is checked as
an `if` with a constant condition: every branch is checked against the constraint, and each branch is its own
scope. A name declared inside such a branch is therefore not visible after it, and the error arrives when the
routine is instantiated:

```nim
proc f[T](x: T) =
  when T is int:
    var y = 1
  else:
    var y = "a"
  echo y          # Error: undeclared identifier: y
```

Declare the name before the `when` when both branches need it. `{.untyped.}` removes this restriction and moves
the check to the instantiation entirely, where `when` is an ordinary conditional and branches share the scope:

```nim
proc show[T](x: T): string {.untyped.} =
  when T is string:
    "str: " & x
  elif T is int:
    "int: " & $x
  else:
    "other"

echo show("a")    # str: a
echo show(2)      # int: 2
```

Prefer the checked form. `{.untyped.}` is a promise that every instantiation compiles, made before you have seen
one.

## Concepts: a constraint is a list of calls

A concept describes what a type must be able to do, as a list of routine signatures:

```nim
type Addable = concept
  proc `+`(a, b: Self): Self
```

`Self` stands for the type being checked (`doc/language.md:4319`). A type satisfies the concept when every
requirement, read as a call with `Self` replaced by that type, resolves by ordinary overload resolution and
returns something assignable to the declared result (`doc/language.md:4317-4339`). So this accepts `int` because
`+` on two `int`s exists and returns an `int`:

```nim
proc twice[T: Addable](x: T): T = x + x
echo twice(3)     # 6
```

A concept with a type parameter is a container concept, and the parameter is bound from the requirements. The
manual's `Findable[T]` is the worked example: an `iterator items(x: Self): T` plus `==` on `T` gives the generic
both the element type and the comparison it needs, so a custom collection works without a single declaration
referring to it:

```nim
type Findable[T] = concept
  iterator items(x: Self): T
  proc `==`(a, b: T): bool

proc find[T; C: Findable[T]](x: C; elem: T): int = ...
```

With `MyCollection` providing `items`, `find(myCollection, 3)` prints `2` (`doc/language.md:4429-4441`). The
`C: Findable[T]` parameter is not decoration either; the last section shows what the `x: Findable[T]` spelling
does instead.

## When a type does not satisfy it

The concept is checked at the call, and the message names the type, the constraint and where the constraint was
declared:

```
main.nim(8, 1) Trace: instantiation from here
main.nim(8, 11) Error: Type mismatch at [position]
twice(n)
[1] NoAdd does not match constraint Addable (declared in main.nim(6, 1))
```

Three things in that message are worth reading rather than skimming. The trace line is the instantiation, not the
declaration. The `[N]` is the argument position where the match failed, and the lines printed under it are the
candidates tried at that position, so a two-argument call that fails on its second argument reports `[2]`. And the
failure is reported against the constraint, not against a missing routine: a routine call prints no
`missing: proc ...` line, so do not expect the message to list which requirement the type lacks. The sentence to
read is the last one.

One shape does print that second line, and it is a type rather than a call: `Box[NoAdd]` gives `NoAdd does not
match constraint Addable` followed by `missing: proc +(a: Self, b: Self)`. A failed generic type argument names
the requirement; a failed routine call only names the constraint.

## Concept inheritance

`concept of` adds a parent's requirements to the child's, and both are checked the same way:

```nim
type
  Named = concept
    proc name(x: Self): string
  Aged = concept of Named
    proc age(x: Self): int

proc describe[T: Aged](x: T): string = name(x) & " " & $age(x)
```

A `Person` with both routines satisfies `Aged`, and `describe` prints `ada 3`. A type that has `age` but not
`name` fails on the inherited requirement, and the message names the child: `P2 does not match constraint Aged`.
The parent's requirement is what failed, but the message does not say which of the two it came from, so read the
constraint you wrote rather than the one you inherited from.

## `Self` and `var Self`

`Self` in a requirement stands for the type being checked, and the qualifier says what the routine may do to its
argument. A `var Self` requirement is the one written for a routine that mutates, and a routine whose generic
parameter is a `var T` can pass the value along:

```nim
type Bumpable = concept
  proc bump(x: var Self)

proc bump(x: var C) = x.v += 1
proc run[T: Bumpable](x: var T) = bump(x)

var c = C(v: 1)
run(c)            # c.v becomes 2
```

The qualifier is not enforced when the concept is satisfied. A `var Self` requirement accepts a value-taking
candidate, and the mutation the requirement implies never happens; a plain `Self` requirement accepts a `var`
candidate, and the mutation does happen. What is enforced is the body's own call: `run[T](x: var T)` can pass `x`
on, and `run[T](x: T)` cannot — `cannot pass x to var/out T parameter`. Write the qualifier you mean, then let the
body's call be the check rather than the requirement.

## Two manual rules the pin does not keep

Both are in `doc/language.md`, and both are wrong at this commit. They are worth knowing because a reader who
follows them writes code that works but believes it should not.

The first is the inference restriction. `doc/language.md:4477-4499` says `var T` cannot be inferred, and its
example is refused. At the pin the same program compiles, runs, and mutates the caller's variable through the
`var` parameter — `g(v, i)` leaves `i` at `100` — and the explicit form `g[var int](v, i)` builds too. Treat `var
T` inference as supported, while keeping the signature explicit when the inference would be doing real work: the
compiler is the less reliable half of that pair.

The second is the sentence at `doc/language.md:4427`: a concept "can only be used as a constraint of a type
parameter". The pin accepts a concept in a plain parameter position, `proc f(x: Addable)`, and a single
instantiation runs:

```nim
proc f(x: Addable) = echo "took it"
f(3)              # took it
```

Call it with a second conforming type and the build dies in the backend with `Symbol not found in NIF module:
Addable.0` and an `AssertionDefect`. So the declaration is accepted, the first instantiation works, and the
program is not usable. That is a defect, not a feature to learn; the chapter writes the constraint on a type
parameter, `[T: Addable]`, every time.

The manual's related example, `proc find[T](x: Findable[T]; elem: T)`, fails one step earlier and for the same
reason: it is refused at its definition, on `items(x)` and on `a == elem`, before any call exists. Calling it
repeats the refusal at the call site — `expected: Findable[T] but got: MyCollection` — but that message is not
what fixes it; the signature is. Write the container as its own parameter, `proc find[T; C: Findable[T]](x: C;
elem: T)`, which is the form the section above uses.

The same shape appears when the concept's own name is used where `Self` belongs. The requirement inside the
concept, ``proc `<`(a, b: Comparable): bool``, is accepted with no diagnostic at all; the proc that then takes
`Comparable` as a parameter type is refused at its own definition, and the call repeats it as `expected:
Comparable but got: int64`. Inside a concept the name to write is `Self`; outside one, a concept is not a
parameter type.

## Nim 2 delta

*What Nim 2 did.* A type class in a parameter position made an implicit generic: `proc f(x: Addable)` was a
shorthand for a routine instantiated per conforming type, and Nim 2 substituted the argument's type into the body
without checking it first. Templates, concepts and generics all shared that paste-and-try feel, and a body could
contain a field access that only failed for the types that lacked it.

*What Nimony does.* The bracket form `[T]` is the generic, the concept is written as `[T: Addable]` where it
belongs, and the body is checked at the definition. A concept in a plain parameter position is accepted by the
front end but crashes the backend on a second instantiation, so it is not a route at all. `{.untyped.}` is the
explicit opt-out for the paste-and-try habit.

*What breaks if you keep the habit.* `proc f(x: Addable)` moves the generic into a runtime crash instead of a
compile error, and a body written for one type fails at the definition even if every call site would have been
fine. Write the bracket, keep the concept on the type parameter, and reach for `{.untyped.}` only when the body
genuinely needs to see the type.

## Samples

`samples/17-generics-concepts/generics.nim`, compiled and run at the pinned commit:

```
$ nimony c -r samples/17-generics-concepts/generics.nim
42
6
12
```

The three lines are `twice(21)`, `sumAll` over `@[1, 2, 3]`, and `sumAll` over two `Money` values, so one concept
constrains three instantiations of two routines, and the second call reaches the `+` declared in the same file.

## Checks

1. Write `proc id[T](x: T): T` and call it with an `int` and a `string`. Then replace the body with a field
   access the parameter does not have, and read where the error lands.
2. Add a `Box[T]` type, then a constrained `Box[T: Addable]`, and try to instantiate the second with a type that
   has no `+`.
3. Move a name declaration inside a `when T is int` branch and call the routine. Read the error, then declare the
   name before the `when` and confirm it builds.
4. Write a concept with two requirements and `concept of` a third. Delete one of the parent's routines from the
   type and say which constraint the message names.
5. Write `proc f(x: Addable)`, call it once with an `int`, then with a second conforming type. Record what
   happens at each step and which form you should have written.

## Chapter checklist

`draft 2026-11-13 · tech_review Momo 2026-11-13 · editorial_pass 2026-11-13 · frozen 2026-11-13`
