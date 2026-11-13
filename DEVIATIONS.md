# Deviations from the nim-id baseline

The book inherits nim-id's `docs/writing-guide.md`, `docs/publishing-standards.md` and `docs/glossary.md`.
Every place it departs from them is recorded here with a reason and the date it was decided.

| # | Deviation | Reason | Decided |
| --- | --- | --- | --- |
| 1 | Retired Nimony terms are kept in `GLOSSARY.md` under "Retired in Nimony" with what replaced them, instead of being deleted or folded into the banned-variant list. | Readers arriving from Nim 2 search for `macro`, `exception`, `closure iterator` first. Deleting the row hides the thing they are looking for. | 2026-11-12 (editor, on Wulan's finding) |
| 2 | Chapter frontmatter carries `nimony_commit` next to `nimony_version`. | The newest tag (`v0.6.2`) trails `master`, which reports `0.6.3`; a version string alone does not identify the compiler. | 2026-11-12 (editor) |
| 3 | Sample verification is a script (`tools/verify-samples.sh`, Engineering) rather than an ad-hoc run pasted into the chapter. | A pin that moves must fail loudly in one place, not in a reviewer's memory. | 2026-11-12 (editor, on Raka's proposal) |
| 4 | Chapter files live at `chapters/NN-slug/en.md` and `.../id.md`, not in the nim-id `books/id`, `books/en` split. | The skeleton needs one folder per chapter for a per-chapter checklist; the id/en pair is a policy here, not a site build. | 2026-11-12 (editor) |
| 5 | Each chapter carries a "Nim 2 delta" box. | Nim 2 material is the default on the internet and is actively wrong for Nimony; the delta is named once, in a fixed place, instead of scattered warnings. | 2026-11-12 (editor) |
| 6 | The Indonesian text addresses the reader as "kamu" and keeps code, sample names and field names in English. The heading rule is not repeated here: it is the language policy in [`OUTLINE.md`](OUTLINE.md), so the `id.md` heading is the Indonesian title of that chapter and only the `title:` frontmatter stays English in both editions. | The nim-id guide does not fix an address form, and Indonesian technical prose drifts between "Anda", "kalian" and "kita"; mixing them is the visible failure. Code stays English because identifiers and error text must match what the reader types and sees. | 2026-11-12 (editor) |
