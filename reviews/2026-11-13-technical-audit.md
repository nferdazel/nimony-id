# Technical audit, 2026-11-13

Second pass: the previously *open* blocks, the inline comment claims, and the citations. Audited at repository HEAD
`2afa1dc`, `VERSION` `0.1.23`, pin `4ba90a781b0b22d0821efaa153c129c37cef6143` (`nimony 0.6.3`,
`~/.local/opt/nimony/4ba90a7`). The first pass (`b645f97` / `0.1.21`) verified the full expected-output blocks and
rebuilt every diagnostic it could; it left 65 output blocks, Chapter 4's inline comments and the citation reading
marked *open*. This pass runs all of them.

Verdict: **the previously open set is closed except two failing blocks in Chapter 19.** 67 fenced blocks were
carried as open in the snippet table; two of them turn out not to be output blocks, leaving the 65 the first pass
counted. Of those: 61 now have a fresh run or a verified shell session behind them, 2 are historical verifier
records covered by `ERRATA.md:125`, and **2 fail**: the two NIF listings in Chapter 19 show the input
tree for `a + 1`, not for the `2 + 3 * 4` printed above them. Four further quoted-text defects are low severity
(`chapters/23-testing`, `chapters/24-passive-procs`, `chapters/10-arrays-sequences-tuples`,
`chapters/11-objects-enums-distinct`). No other quoted
diagnostic was found false, and Chapter 4's fourteen inline `#` comments all reproduce.

## What was re-run

```
$ bash tools/verify-samples.sh
SUMMARY 23/23 passed, 0 failed
```

- **The 67 carried blocks.** Each block's described shape was rebuilt at the pin and run: single files for the
  diagnostics, two-module trees for Chapter 16, temp projects with plugins for Chapter 19, the tarball and the
  compiler driver for Chapter 2. 61 pass, 2 fail (Chapter 19), 2 are records, 2 are not output blocks.
- **Chapter 4's inline `#` comments.** All fourteen were executed as assertions: overflow wrap and flag
  (`-9223372036854775808 true`), `div`/`mod`/`/` (`3`, `1`, `3.0`), conversions (`3`, `-3`, `3.0`), `ord`/`chr`/
  comparison (`97`, `a`, `true`), `ord(five)` (`5`), `-7 div 2`/`-7 mod 3` (`-3`/`-1`), `int8(200)` (`-56`), and
  the quoted errors `type mismatch: got: int64 but wanted: float64`, `undeclared field: 'toInt' for type float64`,
  `cannot prove 'step' is in range 0..9`, `expression overflow at compile time: 127'i8 + 1'i8`. All match.
- **Citations.** 472 toolchain citations with line references re-resolved against the pin: 0 missing files, 0
  ranges past end of file. 418 share at least one content word with the sentence that cites them; the 54 that
  share none were read by hand against their ranges and all 54 support their sentence. No citation points at
  unrelated text. This upgrades the first pass's "existence only" to "existence plus a support check"; it is not a
  sentence-by-sentence reading of all 472.
- **The three Appendix B blocks.** `./task verify`, its summary lines and the full run at the pin all reproduce.

### Chapter 19 plugin battery

Every mechanism the chapter names was built and run from a temporary project: untyped and typed inputs decoded from
`.in.nif` with `tools/niftools bif2nif`; the arity validator (exact `deps/double.nim(7, 3) Error: expected 3..3
children, got 2 [transform builds (add)]` and its `FAILURE: .../validator` line); a module plugin that drops a
top-level `block` (prints `kept` only); a for-loop plugin (input shape matches the listing at `en.md:169`); an import plugin
without its executable (`/bin/sh: nosuchplugin: command not found` + `exit code 127`); the `dependsOn` table
(`first/first` without, `first/second` with); `readFile` without a `try` (exact `deps/note.nim(7, 25)`); a missing
plugin source (`nifler2: cannot read the input file`); `errorTree` (`??? Error: stop here`); and the resolution
rule (a plugin in `a/deps` runs while a decoy in `b/deps` is never compiled, `a/nimcache` is never created).

## Table A — quoted output, per chapter

Every fenced output/transcript block in the chapter. `Verified` = a fresh run, a rebuilt diagnostic or a shell
session executed at the pin. `Record` = a historical verifier summary kept by `ERRATA.md:125`. `N/A` = the block is
not program output (a code fragment the classifier caught, or a directory listing).

| Ch | Blocks | Verified | Record | Fail | N/A | Note |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 0 | 0 | 0 | 0 | 0 | Prose only, empty by design. |
| 2 | 7 | 7 | 0 | 0 | 0 | Tarball sha256 `93a1e638…fac7df` re-downloaded and hashed; `nimony --version`; the `nativenif` line is in the recorded build log; `nimony n` reproduced; verifier block reproduced. The 1m02s build time is a measurement on the authoring machine, not re-timed. |
| 3 | 4 | 4 | 0 | 0 | 0 | `ref int64 not nil` refusal and the `ignoreStyle` pragma both run. |
| 4 | 0 | 0 | 0 | 0 | 0 | No fenced output block; the fourteen inline comments are verified above. |
| 5 | 3 | 3 | 0 | 0 | 0 | Full block matches; transcript runs. |
| 6 | 7 | 7 | 0 | 0 | 0 | Enum and non-enum `not all cases` messages both rebuilt. |
| 7 | 15 | 15 | 0 | 0 | 0 | `0..high(int)` contract violation, and the `0..len(word)` defect fixed in `0.1.21` re-run: assertion line, then `a`, `b`, `c`. |
| 8 | 7 | 7 | 0 | 0 | 0 | Includes the `.noSideEffect` refusal; it points into `syncio`, as the prose says. |
| 9 | 12 | 12 | 0 | 0 | 0 | UFCS mismatch, `cannot borrow from b.v` (column 39 exact) and the ambiguity pairs all rebuilt. |
| 10 | 34 | 33 | 0 | 0 | 1 | `L295` is a code fragment, not output. `L406`'s message is correct but its `... 18 more candidate lines` line is invented, see Finding 4. |
| 11 | 3 | 2 | 1 | 0 | 0 | `echo` of an object: first line and two candidates exact, the rest elided (Finding 5). `10/10` record covered by `ERRATA.md:125`. |
| 12 | 6 | 5 | 1 | 0 | 0 | Constructor's `illformed AST` message and the `case` expression error reproduce. `11/11` record covered by `ERRATA.md:125`. |
| 13 | 2 | 2 | 0 | 0 | 0 | — |
| 14 | 4 | 4 | 0 | 0 | 0 | Both aliasing halves rebuilt, including the 32-byte const-ref case. |
| 15 | 4 | 4 | 0 | 0 | 0 | `except IOError`, uninitialised `result`, and the ErrorCode/ref-exception refusal all exact. |
| 16 | 4 | 4 | 0 | 0 | 0 | Private name, import cycle and unsynchronized global rebuilt as two-file trees. |
| 17 | 3 | 3 | 0 | 0 | 0 | Instantiation trace and constraint message exact (`8,1` / `8,11` / `6,1`). |
| 18 | 3 | 3 | 0 | 0 | 0 | — |
| 19 | 13 | 10 | 0 | 2 | 1 | Two NIF listings fail (Finding 1); `L198` is a directory listing, not output. The other ten mechanisms verified, including the `dependsOn` table. |
| 20 | 2 | 2 | 0 | 0 | 0 | Transcript and full block match. |
| 21 | 2 | 2 | 0 | 0 | 0 | Full 16-line block matches byte-for-byte. |
| 22 | 2 | 2 | 0 | 0 | 0 | — |
| 23 | 7 | 7 | 0 | 0 | 0 | `assert` without the import, the unsynchronized global (Finding 3) and the verifier transcript. |
| 24 | 12 | 12 | 0 | 0 | 0 | `delay()` assert, the driver chain, the two-worker sketch, the generated C struct (`workerX60Qcoro_0_<hash>`, `workerX60Qs0`/`s1`) and the three refusals all reproduce. The assert quote needs backticks (Finding 3). |
| A2 | 3 | 3 | 0 | 0 | 0 | Command, summary and full run reproduced. |

Totals: **159 blocks, 153 verified, 2 records, 2 failing, 2 not output.**

## Findings

1. **Chapter 19's two NIF listings do not match the source printed above them — medium.** `en.md:68-69`,
   `id.md:85-86` print `shape(2 + 3 * 4)` and `typedShape(2 + 3 * 4)`. The blocks at `en.md:75` and `en.md:81`
   (`id.md:95`, `id.md:101`) show `(stmts shape (infix \+ a~2 1))` and
   `(stmts typedShape (add (i 64)a.0.main~2 1))`, which is the input for `a + 1`, not for `2 + 3 * 4`. Decoded from
   the pin's own `.in.nif`, the printed source produces

   ```
   (stmts shape (infix \2B 2 (infix * 3 4)))
   (stmts typedShape (add (i 64)2 (mul (i 64)3 4)))
   ```

   and the `a + 1` source produces

   ```
   (stmts shape (infix \2B a 1))
   (add (i 64)a.0.<build id> 1)
   ```

   Three smaller mismatches ride along: the operator escape prints `\2B`, not `\+`; the symbol's module suffix is
   the build's cache id (`a.0.mai3r4ykk` in this run), never the literal `main`; and the sentence "the tree says
   `2` where the source said a literal operand" describes an index (`~2`), not a literal. `en.md:95` and
   `id.md:121` repeat the `\+` form for `ignore(notDeclared + 1)`; the pin prints
   `(stmts ignore (infix \2B notDeclared 1))`, and `review.md:38` carries the same `\+` in its claim column
   while its own evidence column already shows `\2B`.

   The smallest honest repair keeps the prose's teaching point (a symbol gains a name and a type) by changing the
   source block and the listing together:

   ```nim
   import std / syncio

   let a = 1

   template shape(x: untyped) {.plugin: "deps/shape".}
   template typedShape(x: typed) {.plugin: "deps/shape".}

   shape(a + 1)
   typedShape(a + 1)
   ```

   ```
   (stmts shape (infix \2B a 1))
   ```

   ```
   (stmts typedShape (add (i 64)a.0.<build id> 1))
   ```

   Then the "Four things changed" paragraph says: operator sugar is gone (`infix` → `add`), `a` became a symbol
   in the module's namespace (the suffix is the build's module id, shown here as `<build id>`), the symbol carries
   its type `(i 64)`, and positions/indices (`~2`, `@2`) are omitted. The alternative — keep `2 + 3 * 4` and print
   the two nested trees above — needs the same paragraph rewritten and loses the symbol lesson.

2. **Chapter 23 quotes the `.sync` message with straight quotes — low.** `en.md:101-102` and `id.md:101-102` print
   `pass it to a '.sync' routine or use` / `'{.cast(assumeSync).}'`. The compiler prints backticks:
   `pass it to a `.sync` routine or use `{.cast(assumeSync).}``. Only the quote characters are wrong; the words,
   the wrapping and the variable name are right.

3. **Chapter 24 quotes the assert with straight quotes and drops its location — low.** `en.md:144` and
   `id.md:145` print `'state != -1' delay() no-arg must precede suspension point`. The pin prints
   `cps.nim(269, 5) `state != -1` delay() no-arg must precede suspension point [AssertionDefect]` (with the
   backtick pair). `id.md:394` repeats the single-quoted form in prose. Either print the full line or keep the
   message and say the location is elided; the quotes must be backticks either way.

4. **Chapter 10 prints an elision as compiler output — low.** `en.md:410` and `id.md:414` contain
   `... 18 more candidate lines`. The compiler prints all 21 candidate lines and never produces that sentence. The
   count is right (18 lines are omitted between the third and the last), so the fix is to replace the line with the
   book's `…` and say in prose that 18 candidates are elided, or print them.

5. **Chapter 11 says "every" while showing two — low.** `en.md:144-145` introduces the block as "a type error listing
   every `write` overload the compiler tried"; the block shows two candidates and `...` of nine. Change "every" to
   "the" or say the listing is trimmed.

6. **Chapters 11 and 12 print `10/10` and `11/11` from an earlier freeze — record, not defect.** `en.md:335` and
   `en.md:322` show `./tools/verify-samples.sh` with those summaries; at HEAD the same command prints `23/23`.
   `ERRATA.md:125` rules that the counts are the chapters' own freeze and that the new sentence in Chapter 2 covers
   them. Recorded here so a reader of this audit does not mistake them for a fresh run.

### Applied in `0.1.24`

The findings above describe the files as audited; each bullet records what replaced them. Findings 1 to 5 were
fixed in both editions, with no pin change:

- **Finding 1 (Chapter 19).** The source is now `var a = 2` / `shape(a + 1)` / `typedShape(a + 1)`, in
  `chapters/19-plugins-nif/{en,id}.md` and in `samples/19-plugins-nif/plugins.nim`. The two blocks print
  `(stmts shape (infix \2B a 1))` and `(stmts typedShape (add (i 64)a.0.<build id> 1))`, decoded from that
  sample's own `.in.nif` files at the pin with `tools/niftools bif2nif` (the decoded text also carries `@`-infos,
  `~`-positions and the absolute `arithmetics.nim` path; the blocks elide them as the sentence above them says).
  The paragraph now counts three changes rather than four, and the arity sentence says the compiler's `add` has
  the same three slots the validator demands. `tools/verify-samples.sh` still prints `SUMMARY 23/23 passed`.
  Two follow-up corrections in `e0cce38` cover text the first pass missed: the inline example in both editions
  now names the wrapper, `(stmts ignore (infix \2B notDeclared 1))`, and `review.md:38`'s claim column reads
  `(infix \2B a 1)`, matching its own evidence column instead of the `\+` form this finding records.
- **Finding 2 (Chapter 23).** Quick-quoted `` `.sync` `` and `` `{.cast(assumeSync).}` `` in both editions.
- **Finding 3 (Chapter 24).** Backticked assert in both editions, plus one clause saying the compiler prints the
  position `cps.nim(269, 5)` before the message and `[AssertionDefect]` after it, both elided.
- **Finding 4 (Chapter 10).** The invented line is now `...`, and the prose says the marker stands for the 18
  candidate lines between the third and the last, so the compiler's 21 are accounted for.
- **Finding 5 (Chapter 11).** "every `write` overload" is now the listing trimmed to two of nine.

Every row is in `ERRATA.md` under editorial corrections.

### Fixed in `0.1.21`, re-verified at `0.1.23`

**`chapters/07-loops-ranges/en.md:145-148`** — fresh run of `for i in 0..len(word): echo word[i]`:

```
…/lib/std/system/stringimpl.nim(686, 37): i < len(s) [AssertionDefect]
a
b
c
FAILURE: nimcache/c/<hash>/main
```

The block keeps `a`, `b`, `c` after the assertion; the absolute prefix and the driver's `FAILURE:` line are the
book's usual elisions.

**`chapters/24-passive-procs/en.md:228-250`** — with the chapter's `{.feature: "assumeSync".}` rule, the chain
prints exactly `outer 1`, `inner 1`, `outer parked`, `inner 2`, `outer 2`.

## Not proven by this audit

- **418 of the 472 citations were checked mechanically, not read.** Each shares a content word with its cited
  range; a range can share a word and still be the wrong evidence. The 54 with no shared word were read and pass.
- **The Nim 2.4.0 column of the delta table was not re-measured.** It records the host compiler's documented
  behaviour; this audit ran the pin only.
- **The per-chapter `review.md` claim tables are records, not runnable artifacts.** The probe files they name
  (`chNN-probes/*.nim`) are not in the repository, so their verdicts were not re-executed here.
- **The 1m02s `build all` time** is a measurement on the authoring machine, not a property of the commit.

## Artifacts

Scripts and outputs outside the repository, under
`~/.openmausbot/workspaces/49df9f87-8857-46c0-b9b8-8f066a10a55e/`:
`audit-blocks.py` / `audit-blocks-head.json` (block classification), `audit-snippets2.py` / `audit-snippets2.json`
(snippet rebuilds), `audit-citations2.py` / `cite_sem.json` (citation resolution and support check),
`cite_review.md` (the 54 read citations with their ranges), `blk/` (every rebuilt shape, one directory per case,
with the exact program and observed output).
