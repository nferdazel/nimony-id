# Indonesian edition term list, 2026-11-13

The decision record for the Indonesian edition's vocabulary: one canonical form per contested term, the variants
it rejects, the count in the repo today, and the reason. Written to be applied mechanically, with the sentences
that a mechanical pass would get wrong named at the end.

Scope: findings 1, 2 and 3 of `reviews/2026-11-13-whole-book.md`. Nothing in `chapters/`, `samples/` or the
built book was changed by this handoff; no rebuild, no commit.

State it describes: `~/Projects/nimony-id` at `773ace5` (`VERSION` `0.1.20`). The four sweeps this list defines are
already applied, in `397b47b` ("Fix the Indonesian edition's voice, section names and
cross-references") and `63eeff8` ("Catch the two capitalised Sampel"). Counts below are therefore the counts
*after* the sweep, which is what makes them a usable acceptance test, plus the pre-sweep number where the
rejected variant is cited. Supersedes the draft in `reviews/2026-11-13-id-terminology.md`, which carried the
four commands before they were run.

## What the reader meets today

| Form | Count in `chapters/*/id.md` | Where it sits |
| --- | --- | --- |
| `kamu` | 286 | 74 in Chapters 1–8, 212 in Chapters 9–24 and Appendix A |
| `lo` / `lu` | 2 | both inside code: `curl -LO` (02:60), `` `lo <= value <= hi` `` (07:365) |
| `gue`, `kau`, `Anda`, `kalian` | 0 | — |
| `bab` (lowercase) | 127 | body prose, `bab ini`, `bab-bab` |
| `Bab` (capital) | 153 | of which 125 are `Bab N` cross-references; the rest open a sentence |
| `chapter` / `Chapter` | 53 | 23 checklist headings, 24 frontmatter `chapter:` keys, 6 in frontmatter prose (`job:`, `tech_review:`) |
| `Chapter N` | 1 | Appendix B's `tech_review:` line, not reader text |
| `Lampiran` | 3 | the two appendix headings and one "Lampiran ini" in Appendix B |
| `## Samples` | 23 | Chapters 2–24; Chapter 1 has `samples: []` and no section |
| `## Cek` | 23 | the same 23 chapters |
| `## Nim 2 delta` | 18 | 12 bare, 6 with a subtitle after the colon |
| `## Chapter checklist` / `## Checklist chapter` | 11 / 12 | source-only, stripped before rendering |
| `sample` (bare word) | 84 | 72 lowercase, 12 sentence-initial; body prose |
| `samples/…` | 126 | inside code spans, file paths the reader types |
| `samplenya` | 4 | Appendix B |
| `sampel` | 0 | was 21, all Appendix B |
| `latihan` | 0 | was 14, all section headings |

## 1. Address form

**Canonical: `kamu`.** One form, every chapter, for the whole book.

Rejected, with the count each had before the sweep and the reason:

| Variant | Was | Why it loses |
| --- | --- | --- |
| `lo` / `lu` | 208 (Chapters 9–24) | Jakarta informal; `DEVIATIONS.md` #6 fixes *kamu* for the edition. It is also the marker that split the narrator in two at Chapter 9. |
| `gue` | 3 (Chapter 5:103, Chapter 21:144 and :197) | first person in a book with no narrator; all three sentences address the reader, so all three say *kamu*. |
| `kau` | 3 (Chapter 6 heading, two Appendix A rows) | archaic literary register; the reader meets it nowhere else in the book. |
| `Anda` | 0 | formal register the book never establishes; starting it at Chapter 9 would be the same split with a different word. |
| `kalian` | 0 | the book addresses one reader; the two `kita` that remain are inclusive "we", not an address form, and stay. |

Reason in one sentence: a technical book that changes who it is talking to mid-way is the failure
`DEVIATIONS.md` #6 exists to prevent, and *kamu* is the form the edition already used for its first eight
chapters.

Tone is not the problem it looks like. The pre-sweep Chapters 9–24 used *lo* but almost no other Jakarta marker:
counting `nggak, gak, udah, banget, bikin, kayak, doang, bakal, gimana, gitu, biar, gampang, cuma, aja, bikinan,
dinalar` gives 1–6 hits per chapter on **both** sides of the old split (Chapter 2 has 1, Chapter 3 has 2, Chapter
7 has 3; Chapter 19 has 5, Chapter 23 has 6). The pronoun was the only systematic marker, so swapping it does not
create a register clash. What it does create is a short list of grammar breaks, in section 5.

## 2. chapter and bab, and the shape of a cross-reference

**Canonical: `bab` in prose, `bab ini` for the current one, `Bab N` for a numbered reference.**

| Rejected | Why |
| --- | --- |
| `chapter`, `Chapter N` | the appendices in the same edition already said *Bab* 56 times while the chapters they cite said *Chapter* 69 times; one object, two names, and the split fell on the boundary a reader crosses last. |
| `Bab N (judul)` | no chapter reference in the book carries a title, and adding one invites a second place to keep a title correct. |
| `bab ke-N` | the book writes `Bab 13`, never an ordinal; 125 references already use the bare numeral, so the ordinals would be the new minority. |

Shape, as the 125 existing references already have it:

- one chapter: `Bab 13`
- a run: `Bab 11 dan 12`
- a list: `Bab 3, 4, 5, dan 6` (comma-separated, `dan` before the last)
- the opening heading: `## Untuk apa bab ini` (23 chapters), `## Untuk apa lampiran ini` (Appendices A and B)
- an appendix: `Lampiran A`. This shape is fixed but **unexercised**: no `id.md` cites an appendix by letter
  today, only "Lampiran ini", so the first such reference should be checked against this line.

Where `chapter` legitimately survives, and must not be touched: the frontmatter key `chapter: 1`, and English
frontmatter prose in `job:` / `tech_review:` (54 files). That is the manuscript's record, not reader text, and
`tools/verify-*` reads the key.

## 3. The six section names

| Section (template) | Canonical heading | Rejected | Count now |
| --- | --- | --- | --- |
| What this chapter is for | `## Untuk apa bab ini` | `## Untuk apa chapter ini` (23) | 23 |
| Samples | `## Samples` | `## Sample` (9 chapters) | 23 |
| Checks | `## Cek` | `## Latihan` (14), `## Checks` (1) | 23 |
| Nim 2 delta | `## Nim 2 delta` | `## Delta Nim 2` (4 files), and the two subtitled `Delta Nim 2: …` headings in Chapters 6 and 7 | 18 headings: 12 bare, 6 subtitled (`## Nim 2 delta: …`, Chapters 3–7 and 9) |
| Chapter checklist | `## Chapter checklist` / `## Checklist chapter` — unchanged | normalising the pair | 23, stripped |

Why `## Samples` stays English: the directory is `samples/`, the command under the heading is
`nimony c -r samples/NN-slug/<file>.nim`, and the prose says *sample* 84 times against *sampel* 21 before the
sweep. A translated heading over an untranslated path gives the reader two names for the one thing he types.

Why `## Cek`: it is the direct rendering of the template's *Checks*, and the body already uses *cek* as the word
for a check (`lolos cek`, `ceknya`, `cek runtime` in Chapters 12 and 19). *Latihan* never appears in body prose,
and it names an exercise with an answer, which the book does not ship: the template asks for "short exercises
with a stated expected outcome".

Why `## Nim 2 delta` and not `Delta Nim 2`: it is the `en.md` heading, and the in-text callout titles were
already `**Nim 2 delta — …**` before the heading sweep, so the Indonesian heading now matches the labels inside
its own section.

Why the checklist heading keeps two spellings: it is stripped by `tools/strip-status.py` before rendering and
never reaches the reader. Renaming it means editing the strip regex in the same pass for no visible gain. Both
forms stay, and `GLOSSARY.md` says so.

## 4. sample, sampel, and the other words in a heading

**Canonical: `sample`, in prose and in headings.** Rejected: `sampel`, `sampelnya` (21 in Appendix B; 4 of those
were `sampelnya`). Reason: the reader types `samples/` 126 times in code spans and the two editions share that
path; the artifact and the directory are one name.

Words that appear in a section heading and are therefore covered by this list:

| Heading | Where | Status |
| --- | --- | --- |
| `## Samples` | 23 chapters | fixed |
| `## Menambah sample` | Appendix B | correct, singular |
| `## Bab mana di belakang sample mana` | Appendix B | correct; the title is a `bab`, the artifact a `sample` |
| `# Testing dan Verifier Sample` | Chapter 23, H1 | correct; `Verifier` is the tool's name |
| `# Catatan verifikasi sample` | Appendix B, H1 | correct |

## 5. Where the sentence, not the word, has to change

A pronoun swap is safe almost everywhere: the 208 `lo` sat in Chapters 9–24, and the substitution reads
correctly in all but the lines below. It is not safe in these, because Indonesian marks the object on the verb,
and `kamu` as a free object after `memberi` reads as a translation, not as this book. 15 lines from the sweep,
each a one-line edit, plus one pre-existing sentence the check surfaced.

**Class A — object clitic the sweep could not reach (12 lines).** `memberi kamu` → `memberimu`,
`memberi tahu kamu` → `memberitahumu`. The book already writes `memberimu` four times (Chapter 2 twice, Chapters 3 and 5 once each), so the
two forms stand in the same book today.

| File:line | Now | Rewrite |
| --- | --- | --- |
| 14:20 | `Bab 13 memberi kamu dua cara …` | `Bab 13 memberimu dua cara …` |
| 15:20 | `Bab 8 memberi kamu routine …` | `Bab 8 memberimu routine …` |
| 20:21 | `… memberi kamu tes yang menentukan …` | `… memberimu tes yang menentukan …` |
| 20:183 | `Iterasi memberi kamu pairs, keys, …` | `Iterasi memberimu pairs, keys, …` |
| 20:263 | `… yang memberi kamu JsonNode …` | `… yang memberimu JsonNode …` |
| 21:214 | `import std/os memberi kamu removeFile …` | `import std/os memberimu removeFile …` |
| 22:117 | `memberi kamu tiga jalan menyeberang …` | `memberimu tiga jalan menyeberang …` |
| 20:29 | `… memberi tahu kamu bahwa …` | `… memberitahumu bahwa …` |
| 20:30 | `memberi tahu kamu bahwa fungsi …` | `memberitahumu bahwa fungsi …` |
| 20:31 | `… yang berhasil memberi tahu kamu sedikit lebih banyak …` | `… yang berhasil memberitahumu sedikit lebih banyak …` |
| 20:32 | `Itu tidak memberi tahu kamu bahwa …` | `Itu tidak memberitahumu bahwa …` |
| 21:34 | `… compiler yang memberi tahu kamu kebenaran …` | `… compiler yang memberitahumu kebenaran …` |

**Class B — the sentence has to be rebuilt (3 lines).**

| File:line | Now | Rewrite | Why |
| --- | --- | --- | --- |
| 11:172 | `**Nim 2 delta — echo tidak lagi menerapkan $ kamu**` | `**Nim 2 delta — echo tidak lagi menerapkan $ milikmu**` | `$` is a symbol, not a possessor; `$ kamu` is not Indonesian even when the pronoun is right. |
| 11:154 | `` `echo` tidak menerapkan `$` untuk kamu. `` | `` `echo` tidak menerapkan `$` untukmu. `` | the same construction one paragraph earlier, and it is the sentence the callout restates. |
| 09:330 | `tanpa `[]=` milik kamu sendiri` | `tanpa `[]=` milikmu sendiri` | Appendix A's delta row already says `$ milikmu`; one book, one form. |

Not from the sweep, but found by the same check: 04:56 `Tidak ada yang dilempar untuk kamu selamatkan.` already
read `kamu` at `2fd2cdd` (`git show 2fd2cdd:chapters/04-numbers-types-conversion/id.md`, line 56). The elided
relative clause reads as a mistake rather than as brevity; `Tidak ada yang dilempar untuk kamu tangkap.` fixes
it if the editor wants it in the same pass.

One that needs no change, for the record: 13:81 `sedang mengutip tipe balik ke kamu` is grammatical; `kepadamu`
is smoother but not wrong, and it is not worth a frozen-chapter edit on its own.

Chapters that need this read rather than a replacement: **04, 09, 11, 14, 15, 20, 21, 22**. Everything else in the
edition takes the canonical forms without a second look.

## 6. Left as it is, on purpose

| Item | Why |
| --- | --- |
| `` `lo <= value <= hi` `` (07:365) | a range bound the sample declares, not prose; renaming it breaks the code. |
| `curl -LO` (02:60) | shell flag, inside a code block. |
| `## Checklist chapter` / `## Chapter checklist` | stripped before rendering; the strip regex matches both. |
| `chapter:` frontmatter key, `job:` / `tech_review:` prose | the manuscript's record, English by design, and the verifier reads the key. |
| Chapter 1 has no `## Samples` / `## Cek` | `samples: []`; adding empty sections would be a template change, not a term decision. |
| `kita` (2) | inclusive "we", not an address form. |
| Title Case in H1s, including `# Standard Library yang Bisa Kamu Andalkan` | house style for H1 in this book (`# Percabangan yang Mengembalikan Nilai`); `Kamu` capital is correct there. |

## 7. Acceptance

Run from the repository root; these are the numbers in section "What the reader meets today".

```
rg -oi '\bkamu\b' chapters/{01..08}-*/id.md | wc -l          # 74
rg -oi '\bkamu\b' chapters/{09..24}-*/id.md chapters/a*/id.md | wc -l   # 212
rg -oi '\b(lo|lu|gue|kau|anda|kalian)\b' chapters/*/id.md    # 2 lines, both code
rg -n '\bChapter [0-9]' chapters/*/id.md                     # 1 line: Appendix B frontmatter
rg -o '\bbab\b' chapters/*/id.md | wc -l                     # 127
rg -o '\bBab\b' chapters/*/id.md | wc -l                     # 153
rg -ni '\bsampel|\blatihan\b' chapters/*/id.md               # no output
rg --no-filename '^## ' chapters/*/id.md | sort | uniq -c    # Samples 23, Cek 23, Nim 2 delta 12 (+6 with a subtitle),
                                                             # Untuk apa bab ini 23, checklist 23
rg -n '\bmemberi (tahu )?kamu\b' chapters/*/id.md            # no output after class A
rg -n '\$ kamu|milik kamu sendiri' chapters/*/id.md          # no output after class B
./task check                                                 # verify 23/23, then both PDFs and the site
```

The last command is the editor's to run after the section 5 edits; this handoff did not build. The 15 lines in
section 5 are text changes to frozen chapters, so they need their editorial correction row in `ERRATA.md` under
"Editorial corrections", the same route the first sweep took.
