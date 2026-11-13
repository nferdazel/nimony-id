# Whole-book review, 2026-11-13

Editorial review of the complete book at `v0.1.18` (24 chapters, Appendices A–C, pin `4ba90a7`). Scope: the
book as a reader meets it, in both editions. Technical truth is not re-litigated here; where a finding needs a
compiler ruling it says so and names the owner.

Commands behind the evidence, all run from the repository root on 2026-11-13:

```
./task verify                                   # SUMMARY 23/23 passed, 0 failed
grep -ohiE "\bkamu\b" chapters/{01..08}-*/id.md | wc -l          # 72
grep -ohiE "\b(lo|lu)\b" chapters/{09..24}-*/id.md | wc -l       # 208
grep -oh  "Chapter [0-9]\+" chapters/*/id.md | wc -l             # 69
grep -ohiE "\bchapters?\b" chapters/*/id.md | wc -l              # 251
```

## What holds

- All 54 chapter files (`27` folders × `en`/`id`) carry `status: frozen` and a non-empty `tech_review`,
  `editorial_pass`, `samples:` and `glossary_added:`.
- Every term named in a chapter's `glossary_added:` exists as a row in `GLOSSARY.md`. No gaps.
- `./task verify` is green today: `SUMMARY 23/23 passed, 0 failed`, pin `0.6.3` / `4ba90a7`.
- `en.md`/`id.md` pairs match in heading count, code-block count and table count for all 27 folders. The
  build's fail-closed pairing rule has never had to fire.
- Appendix B's run block is the verifier's own output, home directory abbreviated and labelled.

## Findings

Severity is about the reader, not the effort. Each finding names the owner of the fix.

### 1. The Indonesian edition changes who it is talking to at Chapter 9 — high

Chapters 1–8 address the reader as *kamu* (72 occurrences). Chapters 9–24 address the same reader as *lo*
(208 occurrences). Two stray *gue* in Chapter 21.

`DEVIATIONS.md` #6 is explicit: the book addresses the reader as *kamu*, and the reason given is that
Indonesian technical prose "drifts between *Anda*, *kalian* and *kita*; mixing them is the visible failure."
The edition ships exactly that failure, split cleanly at the chapter where the drafting hands changed.

A reader who reads straight through meets a different narrator on page ~120 and no sentence explains it. Fix is
mechanical (208 replacements) but it is a text change to 16 frozen chapters, so it is an editorial correction
row in `ERRATA.md`, the same route the heading correction took. Owner: Aksara, wording checked by Wulan.

### 2. Indonesian section names drift three ways — high

The template fixes six section names. The Indonesian edition uses:

| Section | Variants | Chapters |
| --- | --- | --- |
| Samples | `## Sample` / `## Samples` | 02–10 / 11–24 |
| Checks | `## Latihan` / `## Cek` / `## Checks` | 02–10, 23, 24 / 15–22 / 14 |
| Nim 2 delta | `## Nim 2 delta` / `## Delta Nim 2` | 8 chapters / 4 chapters |

Same section, same function, three names. The cause is structural: `GLOSSARY.md` is English-only and
`CHAPTER_TEMPLATE.md` fixes only the English headings, so the Indonesian edition has no term list to obey and
each batch of chapters coined its own. Owner: Wulan drafts the term list, Aksara applies it.

### 3. Indonesian cross-references are still English — high

`id.md` carries `Chapter N` 69 times and the bare word *chapter* 251 times, including the first heading of 23
chapters, `## Untuk apa chapter ini`. Appendices A–C in the same edition say *Bab* (56 times). So the same
edition names the same object two ways, and the split falls on the chapter/appendix boundary a reader crosses
last.

The language policy in `OUTLINE.md` covers headings only; nothing covers the vocabulary of cross-references.
That hole is why *chapter* survives 24 chapters of otherwise Indonesian prose. Owner: Aksara, term decided with
Wulan (`bab`, `Bab N`, `Lampiran X`).

### 4. Three documents disagree about Indonesian chapter titles — medium, needs a decision

- `OUTLINE.md`, language policy: the `id.md` heading is the Indonesian title of that chapter.
- `DEVIATIONS.md` #6: the Indonesian text "keeps code, chapter titles and field names in English".
- `ERRATA.md`, editorial corrections: "`id.md` headings are Indonesian … Chapter, sample and file names stay
  English."

Practice follows `OUTLINE.md` and `ERRATA.md`: headings are Indonesian, frontmatter `title:` is English.
`DEVIATIONS.md` #6 is stale and, read as written, forbids the edition that shipped. Owner: Wira decides which
sentence stands; Aksara rewrites the other two to match.

### 5. `CONTRIBUTING.md` says only Chapters 1–7 are frozen — medium

All 24 chapters and Appendices A–C are frozen. A contributor reads the public page and concludes they may
propose a rewrite of Chapter 8. The frozen rule is the book's whole editorial premise, so the page that states
it must state the right range. Owner: Aksara.

### 6. `README.md` publishes two stale states — medium

- Release section: "The current release is `v0.1.6` … it carries chapters 1 to 13". `VERSION` is `0.1.18`,
  the release is `v0.1.18`, and the book carries 24 chapters plus the appendices.
- Status section: "Chapters 1 to 18 are in the book".

The README is the first page of a public repository; both lines are wrong by 6 releases and 6 chapters. Owner:
Aksara.

### 7. The `ERRATA.md` watch table is broken into four pieces — medium

Three stray blank lines inside the watch list (after the Chapter 20 rows, after Chapter 21, after Chapter 22)
end the table. Under GitHub's markdown, a row that follows a blank line with no header above it is a paragraph,
so every row for Chapters 21–24 prints as a line of pipes on the page that exists to be read when something
breaks. Owner: Aksara.

### 8. Review artifacts leak machine paths into a public repository — low

Fourteen `chapters/*/review.md` files carry `/Users/sachiel/...` paths, including probe directories under
`.openmausbot/workspaces/` and one path belonging to another bot's workspace. `CONTRIBUTING.md` rule 1 forbids
a path from the machine in the repository, and the repository is public. These are evidence files, not prose,
but the rule as written does not carve them out. Two options, for Wira: sanitize the paths, or narrow rule 1 to
say what a review artifact may contain. Owner: Aksara proposes, Wira picks.

### 9. The authoring mirror is a release behind — low, ops

`~/.openmausbot/product/books/nimony-id` is at `0.1.17` and still carries the pre-`v0.1.18` Chapter 2 text with
the absolute authoring path. The repository at `~/Projects/nimony-id` is `0.1.18` and is the source of truth.
Anyone editing the mirror would resurrect a defect that was fixed. Owner: Aksara notes it; the folder's fate is
Fredi's call.

## What this review does not cover

Compiler-level truth for the 24 chapters' claims, and whether every quoted output block matches a fresh run —
the verifier checks exit codes only, by design. That is a technical audit, handed to Momo with this file as the
brief. Code-block-to-sample coverage is handed to Raka; the Indonesian term list to Wulan; findings 4 and 8 to
Wira.
