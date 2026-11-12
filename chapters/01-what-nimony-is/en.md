---
chapter: 1
title: What Nimony Is
job: Give the reader a working mental model — Nimony is the Nim 3 line, built on a NIF pipeline, with plugins instead of macros — so later rules read as design choices rather than surprises.
nimony_version: 0.6.3
nimony_commit: 4ba90a781b0b22d0821efaa153c129c37cef6143
status: frozen
tech_review: Momo 2026-11-12 (10 claims at 4ba90a7: 8 PASS, 2 corrected in text)
editorial_pass: 2026-11-12
samples: []
glossary_added: [NIF, plugin, passive proc, polymorphic accessor, ErrorCode]
---

# 1. What Nimony Is

Nimony is a new implementation of Nim, written to explore what Nim 3 should be. It is not Nim 2 with
patches, and it is not finished. Both facts shape how you read everything that follows: the language you are
about to learn is deliberately different from the Nim you may find in books, blog posts and Stack Overflow
answers, and it is still moving.

This chapter has no code. It gives you the model the rest of the book assumes, and it tells you what to do
when the rest of the world disagrees with us.

## One language line, two names

The project's own differences document is split down the middle. Its first half is titled "The Future: Nim 3
(the good)", and it opens by naming the relationship: *Nimony* is the work-in-progress implementation for
**Nim 3** (`doc/differences.md`, commit `4ba90a7`).

That sentence does a lot of work, so read it twice. Nimony is an **implementation**, not a dialect: it is a
compiler you run, with its own standard library, its own build model and its own bugs. And its target is
**Nim 3**, which does not exist yet as a released language. The Nim 2 you can install today is a different
language line, and the website's FAQ is blunt about the gap: Nim 3 is Nimony plus compatibility work that has
not happened. Nothing in this book assumes that work lands on a schedule.

The second half of the same document is titled "The present: Nimony (the bad)", and it lists what the
compiler cannot do yet. We will get to that list shortly. The split is worth noticing because it is honest in
a way most language documentation is not: the design and the deficit are printed side by side, by the people
who own both.

## What the compiler is built to do well

The README states the highlights without much ceremony (`README.md`, commit `4ba90a7`):

- incremental recompilations
- fully parallel builds
- no forward declarations for procs and types
- type-checked generics
- one concurrency model for the event loop and for threads
- editor support

Those are not marketing adjectives; each one removes work you may be used to doing. In Nim 2 you order
declarations so the compiler meets a definition before its use. Here you do not. In Nim 2 a rebuild of a large
project is mostly a rebuild. Here the pipeline is arranged so that most of it is not.

Underneath sits **NIF**, the interchange format that every stage of the pipeline reads and writes;
`doc/design.md` calls it the format used to communicate between compiler phases, and passes work on streams of
NIF tokens. The design philosophy page argues the payoff: with NIF, many transformations become simpler and can
be written without recursion, and plugins run incrementally and in parallel like the rest of the pipeline
(nim-lang.org/araq/nimony.html, read 2026-11-12). Read that as the design's argument rather than as a measured
property of this pin — the page dates from 2025-05-10 and is written in the future tense. Chapter 19 goes into
what it means when you write a plugin. For now the consequence is smaller and more useful: the compiler's stages
are separable, which is why the build behaves the way the README says.

## The language you will actually write

Seven differences decide most of what this book teaches. Each has a chapter; none is a footnote. Most are
argued in the design half of the differences document rather than in its list of what ships today, so a chapter
teaches one only after it has been re-proven at the pin — that is what its `tech_review` line is for.

**Nil-ability lives in the type.** A reference that may be nil is written `nil ref T`, and a reference that
cannot be nil is a different type. Dereferencing without checking is a compile-time problem, not a runtime
crash (Chapter 13).

**Alternatives are data.** The `case` inside an `object` gets new syntax, and that is what enables built-in
pattern matching. You model "one of these shapes" as a type instead of as a flag plus a comment (Chapter 12).

**Generics are checked, and concepts are how you constrain them.** You write `proc f[T: Concept](x: T)`, and
the constraint is checked at compile time rather than discovered at instantiation (Chapter 17).

**Concurrency lost its colour.** Where Nim 2 wrote `async`, Nimony writes `passive`; where Nim 2 wrote
`await`, you write nothing. The event loop and multi-threading share one model (Chapter 24).

**Side effects are declared, not inferred.** `func`, `iterator` and `converter` are side-effect free by
default; `proc` is not; there is no inference (Chapters 8 and 15).

**Accessors are polymorphic.** Nim 2 needed one accessor for a mutable container and another for an immutable
one. Nimony declares one, ``func `[]`(x: Container): var Element``, and lets the type system track whether a
write is allowed (Chapter 9).

**The small rules changed too**, and these are the ones that quietly break code you copy from the internet:
`string` lost its terminating zero and no longer converts to `cstring` without a copy; identifiers are
case-sensitive by default; an unlabelled `break` leaves a loop and never a block; signed integer overflow
wraps instead of raising `OverflowDefect`.

Two of those have a per-module restore switch: `{.feature: "ignoreStyle".}` and `{.feature: "anonBlockBreaks".}`
bring back the Nim 2 behaviour for the module that uses them. The `string` change has none, and
`{.keepOverflowFlag.}` is not a compatibility mode — it is a block that makes `overflowFlag()` report the last
signed `+`, `-` or `*` that wrapped, so that you can detect the wrap you just had. Detection is not restoration.
The book teaches the default in all four cases (Chapters 3, 4, 5 and 6).

> **Nim 2 delta — this is not a drop-in replacement**
>
> *What Nim 2 did* → one toolchain, `nim c`, and a set of habits that carry across versions.
> *What Nimony does* → a separate implementation at one pinned commit, where `string`, integer overflow, the
> effect system and the macro system all behave differently from the Nim 2 you may know.
> *What breaks if you keep the habit* → pasting Nim 2 snippets and expecting them to compile unchanged, building
> with a package manager's Nim, or reading today's documentation as if it described this pin.

## What is missing at this pin, and why that is a boundary

At the commit this book is written against, Nimony lacks (`doc/differences.md`):

- an exception system compatible with Nim's — it uses its own, based on an `ErrorCode` enum
- a working effect system — `tags` and `gcsafe` are ignored, and `raises: []` is both the default and ignored,
  while a `raises` list is mapped to `{.raises.}`
- closure iterators
- implicit generics, where a routine omits `[T]` and becomes generic through a type class such as `SomeInt`

And two Nim 2 features are on their way out rather than gone at this pin. The design replaces macros with
plugins and points to single dispatch, but `macro` and `method` still compile and run for Nim 2 compatibility;
the book teaches plugins and procs, and treats a working `macro` as compatibility surface, not as evidence that
the design did not change. Plugins declared with `typed` parameters run after type checking and receive
semantically checked NIF; `untyped` parameters pass code through first.

Read that as the edge of the map, not as a to-do list for you. If a technique you know depends on one of those
features, the answer in this book is the replacement, not a workaround that pretends the feature exists. The
one place where the replacement is genuinely a different skill rather than a renaming is Chapter 19: a plugin
is not a macro with a new name, and the sooner you stop reaching for `macro` the less painful that chapter is.

## Why every claim here carries a commit

The newest release tag is `v0.6.2`. The `master` branch at the commit this book uses reports `0.6.3`. That is
the whole argument for pinning a commit instead of a tag: the tag is already behind the compiler people are
building against.

So this book pins one commit — `4ba90a781b0b22d0821efaa153c129c37cef6143`, 12 November 2026 — built from the
official Nim 2.4.0 tarball, not the Homebrew package, which cannot build `nifler` and therefore cannot parse
anything (Chapter 2 walks through the install and the trap). Every sample compiles and runs through
`nimony c`. The native backend `nimony n` does not exist at this pin and is out of scope, not "coming soon".

Two rules follow from that, and you should expect both while reading:

1. A claim about the language is only as good as its source at the pin: a file in the Nimony repository, a
   compiled and run sample, or a review from Engineering that names one. Where this book could not settle a
   question, the chapter stays open and says so.
2. When the pin moves and a frozen chapter breaks, the break is recorded in the errata, not quietly patched.
   You can check the errata against the chapter you are reading and know exactly which one is older.

## How to read the rest of the book

The chapters run in one order, because each leans on the one before. Three conventions are worth knowing now.

**The delta box.** Where a Nim 2 habit actively misleads, the chapter contains a box named "Nim 2 delta":
*what Nim 2 did → what Nimony does → what breaks if you keep the habit*. It appears only where it earns its
place, and it is never the main path. If you have never written Nim, skip it; the chapter teaches Nimony
without it. If you have, read it first, then go back and read the chapter as if you had not.

**Samples are evidence.** Every code block that claims to run was compiled and run at the pin. Where a sample
is illustrative rather than verified, the text says so.

**Terms are fixed.** A word with a special meaning is in the book's glossary, and a chapter that needs a new
one adds it in the same breath. If a term feels slippery, that is a bug, not a style choice.

Chapter 2 installs the toolchain and gets a program to run. Everything after it assumes you have that working,
because a book about a compiler that cannot compile is a very long opinion.

---

`draft 2026-11-12 · tech_review Momo 2026-11-12 · editorial_pass 2026-11-12 · frozen 2026-11-12`
