# Indonesian edition term list, 2026-11-13

Draft term list for findings 1, 2 and 3 of `reviews/2026-11-13-whole-book.md`, written for the editor to apply
in one pass. Nothing in `chapters/`, `samples/` or the built book was changed by this handoff; this file is the
artifact.

## Ground it stands on

- `reviews/2026-11-13-whole-book.md` findings 1 (address form), 2 (section names), 3 (cross-references).
- `../specs/nimony-id/2026-11-13-editorial-consistency-rulings.md` (Wira): the address form stays *kamu*; the 208
  occurrences in Chapters 9–24 are the correction, the 72 in Chapters 1–8 stand; `OUTLINE.md`'s language policy
  stands, so the heading is Indonesian and code, sample names and field names stay English.
- Counts below were run from `~/Projects/nimony-id` at `2fd2cdd` (`v0.1.18`), the source of truth. The authoring
  mirror under `.openmausbot/product/books/` is a release behind and was not used.

## What the reader sees now

| Word | Count in `chapters/*/id.md` | Where |
| --- | --- | --- |
| `kamu` | 72 | Chapters 1–8 |
| `lo` / `Lo` | 208 | Chapters 9–24 (205 lowercase, 3 sentence-initial) |
| `kau` | 3 | Chapter 6 heading, two rows of Appendix A |
| `gue` / `Gue` | 3 | Chapter 5 line 103, Chapter 21 lines 144 and 197 |
| `chapter` / `Chapter` | 250 | every chapter, 69 of them as `Chapter N` |
| `bab` / `Bab` | 88 | mostly cross-references, mostly in the appendices |
| `lampiran` | 3 | appendix headings |
| `sample` (prose) | 130 | body prose; 126 more sit inside `samples/` paths in code spans |
| `sampel` | 21 | Appendix B only |
| `latihan` | 14 | section headings only; the word never appears in body prose |
| `cek` | 6 in body prose, 8 as a heading | body prose uses *cek* for a verification step |

## The list

| English term | Indonesian edition | Fixed where |
| --- | --- | --- |
| the reader | **kamu** | every `id.md`. No second-person alternative: not *lo*, *lu*, *kau*, *Anda*, *kalian*. No first-person narrator either; the three sentences that spoke as *gue* (Chapter 5 line 103, Chapter 21 lines 144 and 197) all address the reader and so say *kamu*. |
| chapter, `Chapter N` | **bab**, **Bab N** | body prose and the opening section heading: `## Untuk apa bab ini` |
| appendix | **lampiran**, `Lampiran A` | headings and cross-references; already correct, no change |
| Samples (section) | **`## Samples`** | English kept. The prose word is *sample* 130 times against *sampel* 21, and the directory is `samples/`, so the heading matches both. |
| sample (the artifact) | **sample** | Appendix B's 21 *sampel*/*sampelnya* become *sample*/*samplenya* |
| Checks (section) | **`## Cek`** | the direct rendering of the fixed English name, and the word the body already uses for a check (6 times); *latihan* never appears in body prose |
| Nim 2 delta (section) | **`## Nim 2 delta`** | the label stays English: it is the `en.md` heading and the three in-text callout titles already say `**Nim 2 delta — …**` |
| Chapter checklist (section) | **`## Chapter checklist`** | unchanged, and not part of the sweep; it is the process record, `tools/strip-status.py` strips it, and its two spellings are what the strip regex matches |

Terms kept English in the Indonesian edition, because the reader meets the same word in a path, a command or a
file name: `sample`, `pin` (159), `build` (98), `commit` (46), `probe` (22), `driver` (17), `harness` (4),
`toolchain`.

## The sweeps

Four edits, each mechanical. Run from the repository root. Every command protects code spans, and the two
`## Chapter checklist` / `## Checklist chapter` heading forms are left alone.

**S1 — address form.** 214 replacements across 19 files (`05`, `06`, `09`–`24`, `a1`).

```
perl -pi -e 'my @s; s/(`[^`]*`)/push @s,$1; "\x00".$#s."\x00"/ge;
             s/\b(Lo|Kau|Gue)\b/Kamu/g; s/\b(lo|lu|kau|gue)\b/kamu/g;
             s/\x00(\d+)\x00/$s[$1]/ge' chapters/*/id.md
```

Two exclusions this command handles, both verified: Chapter 20's `curl -LO` is inside a code block and stays;
Chapter 7 line 365 has a range bound named `lo` inside a code span (`` `lo <= value <= hi` ``) and stays. Headings
are swept too — eight of the 214 sit in a heading, one of them an H1 (`# Standard Library yang Bisa Lo
Andalkan`) — so a rule that skips heading lines leaves them behind.

**S2 — cross-references.** 90 `Chapter` (69 numbered, 21 sentence-initial `Chapter ini` / `Chapter-chapter`) and
137 lowercase `chapter` become `Bab` / `bab`.

```
perl -pi -e 'next if /^## (Chapter checklist|Checklist chapter)$/;
             s/\bChapter\b/Bab/g; s/\bchapter\b/bab/g' chapters/*/id.md
```

Inside fenced code there is no `chapter` at all (checked: 0 lines), so no code sample is touched.

**S3 — section headings.** 9 files: `## Sample` → `## Samples`. 15 files: `## Latihan` (14) and `## Checks`
(1) → `## Cek`. 4 files (`13`, `14`, `23`, `24`): `## Delta Nim 2` → `## Nim 2 delta`. S2 has already turned
`## Untuk apa chapter ini` into `## Untuk apa bab ini` in all 23 chapters.

```
perl -pi -e 's/^## Sample$/## Samples/; s/^## (Latihan|Checks)$/## Cek/;
             s/^## Delta Nim 2$/## Nim 2 delta/' chapters/*/id.md
```

**S4 — Appendix B only.** 21 occurrences.

```
perl -pi -e 's/\bsampelnya\b/samplenya/g; s/\bsampel\b/sample/g' chapters/a2-sample-verification-record/id.md
```

## Acceptance for the pass

```
rg -n '\b(Chapter|chapter)\b' chapters/*/id.md          # 23 lines, every one a checklist heading
rg -n '\b(Lo|lo|Lu|lu|Kau|kau|Gue|gue|Anda|kalian)\b' chapters/*/id.md
                                                        # 1 line: Chapter 7's `lo <= value <= hi` code span
rg -n '^## (Sample|Latihan|Checks|Delta Nim 2)$' chapters/*/id.md   # no output
rg -n '\bsampel' chapters/*/id.md                       # no output
rg --no-filename '^## ' chapters/*/id.md | sort | uniq -c
                                                        # Samples 23, Cek 23, Nim 2 delta 12,
                                                        # Untuk apa bab ini 23, Untuk apa lampiran ini 2,
                                                        # and the 23 checklist headings left as they are
./task check                                            # verify 23/23, then both PDFs and the site
```

All four sweeps were run once against a scratch copy of `chapters/` before this handoff was written, and the
acceptance commands above printed what they promise: 23 checklist headings left, one code span left in
`07-loops-ranges/id.md:365`, `curl -LO` untouched at `02-the-pinned-toolchain/id.md:60`, no `## Sample` /
`## Latihan` / `## Checks` / `## Delta Nim 2` left, and no `sampel`. The repository itself was not touched, so
`./task check` is still the editor's to run after applying.

The three delivered defects are text changes to frozen chapters, so each sweep needs its editorial correction
row in `ERRATA.md` (the same route the heading correction took). That row is the editor's to write.

## Ready to paste

`GLOSSARY.md`, new section at the end:

```
## Indonesian edition vocabulary

The Indonesian edition (`id.md`) keeps a term in English when the reader meets the same word in a path, a
command or a file name. These are fixed for every chapter; a new term is added here in the same change that
introduces it.

| English | Indonesian edition | Fixed where |
| --- | --- | --- |
| chapter, `Chapter N` | bab, `Bab N` | body prose and `## Untuk apa bab ini` |
| appendix | lampiran, `Lampiran A` | headings and cross-references |
| Samples (section) | `## Samples` | heading; English kept |
| sample (the artifact) | sample | prose and `samples/`; never *sampel* |
| Checks (section) | `## Cek` | heading |
| Nim 2 delta (section) | `## Nim 2 delta` | heading, same as `en.md` |
| Chapter checklist (section) | `## Chapter checklist` | source-only; stripped by `tools/strip-status.py`, do not rename |
| the reader | kamu | one voice; no *lo*, *lu*, *kau*, *Anda*, *kalian*, and no first-person narrator |
```

`CHAPTER_TEMPLATE.md`, one paragraph under **Section order**:

```
The Indonesian edition uses the same six sections, in the same order, with these exact headings:
`## Untuk apa bab ini`, the body's own headings, `## Nim 2 delta`, `## Samples`, `## Cek`, `## Chapter
checklist`. They are listed in `GLOSSARY.md`; `en.md` keeps the English ones. A chapter that needs a different
name for one of the six is a template change, not a chapter decision.
```

## Left open on purpose

The checklist heading has two spellings (12 × `## Checklist chapter`, 11 × `## Chapter checklist`). It is
stripped before rendering, so it is not reader text, and both forms are what `tools/strip-status.py` accepts.
Normalising it would mean editing the strip regex in the same pass for no visible gain; it stays as it is.
