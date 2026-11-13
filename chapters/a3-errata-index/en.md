---
appendix: C
title: The errata index
job: Say what an erratum is in this book, where the list lives, and how a reader reports one, so a frozen page is corrected in public rather than quietly rewritten.
nimony_version: 0.6.3
nimony_commit: 4ba90a781b0b22d0821efaa153c129c37cef6143
toolchain: ~/.local/opt/nimony/4ba90a7
host_compiler: ~/.local/opt/nim-2.4.0
status: frozen
tech_review: restates the ERRATA.md rule; no technical claim
editorial_pass: 2026-11-13
samples: []
glossary_added: []
---

# The errata index

## The rule

A frozen chapter is not rewritten. Chapters 1 to 24 are frozen at `4ba90a7`, and the pin does not move under them:
when a later compiler build changes a behaviour this book teaches, the chapter keeps teaching what was true when it
shipped, and the change is recorded as an erratum. A reader who checks a claim against a newer `nimony` finds the
explanation at the page they were reading, not a silent difference.

That is a deliberate cost. A book that edits itself to follow the compiler has no verifiable editions, and the whole
wording of this one rests on a single commit.

## Where the list lives

`ERRATA.md` in the book's repository. It has three parts:

- **Open errata** — breaks found after a chapter froze. Empty as of this edition: no chapter has been falsified at
  the pin since it shipped.
- **Watch list** — issues known at the pin before any chapter shipped. These are constraints on how a chapter may
  be written, not corrections: a documented behaviour the pin does not have, a message that names the wrong reason,
  a check that does not exist. Each row names the evidence, the sentence the book is therefore allowed to print,
  and the chapter it binds.
- **Editorial corrections** — changes made to a frozen chapter without touching the pin, where the chapter was right
  about the compiler and wrong about the edition.

## How a row is written

One row per break, with the chapter and section, what broke, the version or commit it broke on, the date, and the
status. A row carries a source line whenever the behaviour can be read in the compiler's own code, and a raw run
whenever it has to be observed. A break with neither does not go in: "it stopped working" is not an erratum until
someone names what changed.

Defects found while writing the book are separated from errata. A documentation gap is a row that says the manual
is wrong and the book's sentence stands. A compiler defect is a row that says the compiler is wrong and the chapter
teaches around it — and, where it is worth filing, an upstream issue. One such defect is filed at the time of this
edition: `delay()` with no following suspension point stops code generation on an assertion instead of a diagnostic,
`nim-lang/nimony#2985`, with the fix in `nim-lang/nimony#2988`. The chapter still quotes the assertion, because the
pin still produces it.

## Reporting one

Open an issue on the book's repository with the chapter, the sentence, the toolchain version and commit, and the
command whose output contradicts the page. A claim about the compiler needs the source file or the commit behind it;
a claim about the prose needs the page. The editor decides whether it is an erratum, a defect, or an editorial
correction, and writes the row with the next edition.
