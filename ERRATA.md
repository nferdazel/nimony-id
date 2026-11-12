# Errata

Rule: errata applies to **frozen** chapters. A chapter frozen under an older pin is never rewritten to the
newer one; the break is recorded here and the chapter text stays as it shipped.

Format — one row per break:

| Chapter | Section | What broke | Broke on (version / commit) | Date | Status |
| --- | --- | --- | --- | --- | --- |

## Open errata

_None. No chapter is frozen yet._

## Watch list (known at the pin — not errata yet)

Issues found while establishing the pin. They are not errata because no chapter has shipped; each one is a
constraint on how the chapter may be written, and each must be re-checked at the pin before that chapter
freezes.

| Where | Finding | Evidence | Consequence for the book |
| --- | --- | --- | --- |
| Chapter 7 (ranges) | `doc/differences.md` implies a preceding guard proves a value in `range[0..10]`. It holds for a guarded **local** and fails for a **proc parameter**. | `probe.nim(13, 27) Error: cannot prove 'n' is in range 0..10` at `4ba90a7` | Teach the local form only; never promise a parameter guard works. |
| Chapter 2 (toolchain) | The native backend `nimony n` does not exist at this pin (`../nativenif not found`, `arkham: command not found`). | `hastur build all` output; Raka's run at `4ba90a7` | Every sample uses `nimony c`. `nimony n` is out of scope, not "coming later". |
| Chapter 2 (toolchain) | A build that dies at `nifler` has no parser — but "without `nifler`" is not the general condition. `parserTool()` prefers `nifler2` when present (`src/lib/tooldirs.nim:29-37`), and `build all` stops at the first failing tool (`src/hastur/builders.nim:255-283`). | Momo's source read at `4ba90a7` (2026-11-12) | The chapter gives the build-ordering reason; never generalize to "`nifler` is the parser". |
| Chapter 23 (testing) | `unittest` behaviour at this pin is unproven. | no sample yet | Chapter teaches an assert-based runner until a sample proves otherwise. |
| Chapters 4, 5 | `string` is not null-terminated and integer overflow wraps instead of raising. | `doc/differences.md` at the pin | Statements are design rules, not footnotes; both chapters carry a delta box. |
| Chapter 1, Chapter 19 | `doc/differences.md` files "macros replaced by plugins" and "methods → single dispatch" under *The Future: Nim 3*, not under *The present*. At the pin both still work: `doc/language.md:4862` says macros "exist for Nim 2 backwards compatibility reasons", and `m(A2(), B2())` resolved to `A2B2`. | Momo's compile+run at `4ba90a7` (2026-11-12) | Teach plugins and procs. A working `macro` or `method` is compatibility surface, never evidence the design did not change. Re-check before Chapters 18 and 19 freeze. |
| Chapter 1, Chapter 19 | Six of the seven teaching claims in Chapter 1 (nilability, new `case` syntax, `passive`, side-effect defaults, polymorphic accessor, `string`) come from the *Future* section of `doc/differences.md`, while the design page's recursion and parallel-plugin claims are written in the future tense (page dated 2025-05-10). | `doc/differences.md` section split at `4ba90a7`; `passive` confirmed present in `src/hexer/coro_transform.nim` | Design intent is labelled as such in the text; each claim that becomes a chapter must be re-proven at the pin before that chapter freezes. |
| Chapters 12, 13, 14, 15, 17, 19, 24 | The core feature each chapter teaches was documented at the pin but no run had demonstrated it. **Closed 2026-11-12:** gates 13, 15, 17, 19, 24 proved (24 with a scheduling limit); gates 12 and 14 proved only in part. | `PROOF_GATES_2026-11-12.md` + `RUN_2026-11-12.log`, Momo, `4ba90a7` — all probes through `nimony c` | Each verdict is now written into its `OUTLINE.md` **Proof gate** line. Chapters 13, 15, 17, 19, 24 may draft; 12 and 14 draft to the narrower job recorded below. |
| Chapter 12 | There is no `match` construct at this pin. No `Match` tag in `src/models/nimony_tags.nim`; exhaustive checking exists only as `case`, which rejects with `not all cases are covered; missing: {Triangle}`. | Momo's run at `4ba90a7` (2026-11-12); `g1_variants_missing.nim` | Chapter teaches `case` and the chapter title dropped "Pattern Matching". A `match` chapter waits on the syntax; it is never promised as "later". |
| Chapter 14 | Use-after-move is **not** rejected: `let b = move(a)` compiles, `a` reads as an empty string at runtime with no diagnostic. `move` is documented as leaving "a moved-from state", not as a checked operation. What does get rejected: `mutable argument aliases with immutable parameter`, and `borrow of 'a' escapes the proc; it does not live long enough`. | `g3_use_after_move.nim`, `g3_alias_bad.nim`, `g3_borrow_escape_bad.nim` at `4ba90a7` (2026-11-12) | The chapter teaches the two rules that exist and never a "the compiler catches use-after-move" rule. Checked move semantics stays open. |
| Chapter 24 | Passive procs suspend, resume and run to their end, but the default `trivialTick` scheduler does not interleave chains: `complete` runs one chain to completion before the next starts. | `g7_passive.nim` at `4ba90a7` → `A:start A:end B:start B:end driver:done` (2026-11-12) | Teach suspension and resume; never imply concurrency. Interleaving waits on a `std/threadpool` `submit(delay(...))` sample. |
| Chapter 13 | A module-level `var base: ref int` is rejected — "which has no default value (it contains a not-nil pointer)". The same declaration inside a proc is legal once a write reaches it first. | `g2_nil_ok.nim` probe at `4ba90a7` (2026-11-12) | State the rule with the module-level/proc split, not as a blanket "a `ref` needs no initialiser". |
