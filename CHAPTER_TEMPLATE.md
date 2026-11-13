# Chapter template

Copy this file to `chapters/NN-slug/en.md` and `chapters/NN-slug/id.md`. The English file is the manuscript of
record; the Indonesian file mirrors it. Neither is written from the other at freeze time — both are edited.

```
---
chapter: NN
title: <chapter title, same as OUTLINE.md>
job: <the one-sentence job from OUTLINE.md, verbatim>
nimony_version: 0.6.3
nimony_commit: 4ba90a781b0b22d0821efaa153c129c37cef6143
toolchain: ~/.local/opt/nimony/4ba90a7    # $NIMONY_HOME; fixed install path, never a temp directory
host_compiler: ~/.local/opt/nim-2.4.0     # official tarball, never Homebrew
status: planned            # planned | drafting | frozen
tech_review:               # reviewer name + date, or empty
editorial_pass:            # date, or empty
samples: []                # paths under samples/NN-slug/, each one compiled and run by tools/verify-samples.sh
glossary_added: []         # terms this chapter adds in the same handoff
---
```

## The heading

The heading is the title only: `# Overloading and UFCS`, never `# 9. Overloading and UFCS`. The PDF draws the
chapter number from the counter, so a typed prefix prints twice and pushes every section number one higher.
`en.md` uses the outline title verbatim; `id.md` uses the Indonesian title of the same chapter
(`# Overloading dan UFCS`), while the `title:` frontmatter stays the outline title in both files so the two
editions pair by one name. The preface (`index.<lang>.qmd`) is `# Nimony {.unnumbered}`, so the chapters start
at 1.

## Section order

1. **What this chapter is for** — the job in the reader's terms, two or three sentences. No history.
2. **Body** — the teaching sequence. Every claim about compiler behaviour names the Nimony source file or
   commit it rests on, inline or in a footnote.
3. **Nim 2 delta** — present only where the outline says `yes`. One box, fixed shape:
   *what Nim 2 did → what Nimony does → what breaks if you keep the habit*. Never the main path.
4. **Samples** — the files listed in frontmatter, with the exact command that proves them:
   `nimony c -r samples/NN-slug/<file>.nim` at the pinned commit.
5. **Checks** — short exercises with a stated expected outcome, no open-ended prompts.
6. **Chapter checklist** — the dated line described below. It stays in the source as the process's record;
   the build strips it, so it is never printed as book content.

The Indonesian edition uses the same six sections, in the same order, with these exact headings:
`## Untuk apa bab ini`, the body's own headings, `## Nim 2 delta`, `## Samples`, `## Cek`, `## Chapter
checklist`. They are listed in `GLOSSARY.md`; `en.md` keeps the English ones. A chapter that needs a different
name for one of the six is a template change, not a chapter decision.

## Claim provenance

Every claim the chapter teaches belongs to one of two classes, and the text says which:

- **Shipped at the pin** — the behaviour was demonstrated at `nimony_commit`, by a run or by an explicit
  statement in `doc/` at that commit. This is the only class the body may teach as fact.
- **Design intent** — the claim comes from `doc/design.md`, the "Future: Nim 3" section of
  `doc/differences.md`, or the website. It is written in the future tense, attributed to the design page, and
  never used to justify a rule the reader must follow.

A chapter whose core job rests on design intent does not draft: the outline's **Proof gate** line names what
must be demonstrated first. "It is in the docs" is not proof of pin behaviour — the `range` guard was
documented and still failed on a proc parameter.

## Definition of done (all six, or the chapter stays open)

1. **One job.** The chapter does the job in the outline and nothing else. A second job means a split.
2. **Samples run.** Every sample compiles and runs at `nimony_commit` through `nimony c`, proven by
   `tools/verify-samples.sh` output pasted into the review note. A sample that runs on another compiler
   version does not count.

   The verifier is the only accepted proof, and it runs against the fixed install path — never a toolchain
   under a system temp directory:

   ```
   ./tools/verify-samples.sh          # from the repository root; $NIMONY_HOME overrides the default install
   ```

   Exit `0` all samples pass, `1` a sample failed, `2` toolchain missing or wrong version/commit. Shape of the
   output at the pin (paths abbreviated to `~`, per-sample lines elided); the count is the number of samples
   that exist when you run it, so paste the real number, never this placeholder:

   ```
   toolchain ~/.local/opt/nimony/4ba90a7/bin/nimony 0.6.3 pin 4ba90a7
   PASS samples/NN-slug/name.nim exit=0
   ...
   SUMMARY n/n passed, 0 failed
   ```

   The verifier checks compile, run and exit code only. It does not compare stdout, so a chapter that teaches
   observable output still states the expected output and the test that checks it.
3. **Technical review.** `tech_review` names the reviewer and date; every compiler or language claim cites a
   Nimony source file or commit, and a claim that was documented but never demonstrated is recorded as design
   intent rather than fact (see Claim provenance). An empty `tech_review` blocks freeze, no exceptions.
4. **Editorial pass.** `editorial_pass` is dated. Terminology matches `GLOSSARY.md`; new terms were added in
   the same handoff; the delta box is present exactly where the outline marks it; nothing refers to nim-id; the
   frontmatter records the toolchain as `~/.local/opt/nimony/4ba90a7`, never with a build machine's home
   directory in it, because the repository is public.
5. **Both languages.** `en.md` and `id.md` both exist and both carry the same frontmatter and sample list.
   One side missing means the chapter cannot freeze.
6. **Frozen means frozen.** After freeze, a break found on a newer pin goes to `ERRATA.md` with chapter,
   section, what broke, the version it broke on, and the date. The chapter text is not rewritten.

## Chapter checklist line

The last line of the chapter, dated, filled in order:

```
draft 2026-11-12 · tech_review <name> 2026-11-12 · editorial_pass 2026-11-12 · frozen 2026-11-12
```

Leave a step's date empty while it is unfinished. A chapter with an empty step is open, and stays open.

The line, with its `## Checklist chapter` / `## Chapter checklist` heading or chapter 1's bare backticked
form after the closing rule, is source-only. The build removes it from the staged copy before rendering, so it
never becomes a PDF heading, a site table-of-contents entry, or a nearly empty page. Keep it in the source; do
not expect it to print.
