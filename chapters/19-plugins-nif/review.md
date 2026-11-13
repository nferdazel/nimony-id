# Chapter 19 review note — Plugins and the NIF Pipeline

Status: `drafting`. Reviewer: **Momo**. This note is the claim table, the open questions and the errata
candidates. Append your verdict at end of file; do not edit the table rows in place.

Pin for every run below: `4ba90a781b0b22d0821efaa153c129c37cef6143` (nimony 0.6.3), install
`~/.local/opt/nimony/4ba90a7`. Probe sources: `ch19-probes/` in the authoring workspace
(`~/.openmausbot/workspaces/be336972-1e63-4f00-9916-c76cc8e33654/ch19-probes`), one directory per
probe, each run as `~/.local/opt/nimony/4ba90a7/bin/nimony c -r main.nim` from inside the probe directory.
Inputs were decoded with `~/.local/opt/nimony/4ba90a7/bin/niftools bif2nif` (built from `tools/niftools.nim`
with the host Nim 2.4.0; the pin ships no binary for it).

Verifier already run by the editor, from the repository root:

```
toolchain ~/.local/opt/nimony/4ba90a7/bin/nimony 0.6.3 pin 4ba90a7
...
PASS samples/19-plugins-nif/plugins.nim exit=0
SUMMARY 18/18 passed, 0 failed
```

Sample output, byte-identical to the block in `en.md` section Samples:

```
infix
add
42
```

## Claims

| # | Claim (as written in `en.md`) | Probe | Raw output | Source line |
| --- | --- | --- | --- | --- |
| 1 | Macros are replaced by compiler plugins. | none, doc read | `doc/differences.md:19`: "Macros are replaced by compiler plugins which will offer a different API." | `doc/differences.md:19` |
| 2 | A plugin is a template that lacks a body and carries `{.plugin: "path".}`. | doc read | `doc/language.md:5307-5309` | `doc/language.md:5307-5309` |
| 3 | The quick-start plugin builds and prints `Hello, world!`. | `p01` | `Hello, world!`, exit 0 | `doc/plugins.md:24-63` |
| 4 | A plugin is compiled to native code with `-d:nimonyPlugin`; the compiler writes the input, runs the executable, reads the output. | `p10a` (plugin build command in the failure), doc read | `nimsem --base:deps --d:nimonyPlugin --path:... --isMain ...` in the failing build line | `doc/design.md:86-90`, `src/nimony/semos.nim:973-1020` |
| 5 | An `untyped` argument arrives as raw source, before resolution: `(infix \+ a~2 1)`. | `p05` decode | `(stmts@F,6,main.nim keep (infix \2B a~2 1@2))` | probe decode; `doc/plugins.md:193-225` |
| 6 | A `typed` argument arrives lowered and resolved: `(add (i 64)a.0.<mod> 1)`, symbol carries its type. | `p04` decode | `(stmts@F,6,main.nim keep (add (i@G,p,.../arithmetics.nim 64)a.0.mai3r4ykk~2 1@2))` | probe decode; `doc/plugins.md:226-273` |
| 7 | Each call site is a separate invocation; the same call site reuses the cached output. | `p20`, `p10a` build 2 | `p20`: two `shape_*.in.nif` files for two calls; `p10a` second build prints `first` again, no rerun | `src/nimony/semos.nim:1000-1015` |
| 8 | An `untyped` argument containing an undeclared identifier builds when the plugin drops it. | `p02` | `dropped before name resolution` then `survived`, exit 0 | probe `p02` |
| 9 | A `typed` parameter changes what the plugin is given, not when the argument is checked: a dropped argument is never resolved. | `p03` | same output as `p02` (`dropped before name resolution`, `survived`), exit 0 with `x: typed` | probe `p03`; `doc/lib/plugins.nim:1095-1105` |
| 10 | The input is wrapped as `(stmts <name> <args>)`; `callArgs` skips wrapper and name. | `p04`, `p05` decode | decoded roots above; `callArgs` source | `src/nimony/lib/plugins.nim:1095-1105` |
| 11 | A value-producing plugin needs its return type written; without it the expansion is `void`. | `p06`, `p04` v1 | with `: int` → `42`; without → `main.nim(6, 16) Error: type mismatch: got: void but wanted: int64` | probe `p04`/`p06` |
| 12 | `addIdent` emits a name the compiler resolves at the call site. | sample | `double(21)` → `twice(21)` → `42` | `doc/plugins.md:573-639` |
| 13 | The validator refuses a hand-built `(add ...)` with two children and names the plugin proc. | sample build (first attempt) | `deps/double.nim(7, 3) Error: expected 3..3 children, got 2 [transform builds (add)]` | probe build, `validator` output |
| 14 | Tags are written as enum values in one ordinal space with the compiler's tag ids. | doc read | `doc/plugins.md:65-85` | `doc/plugins.md:65-85` |
| 15 | A module plugin receives the whole module after semantic analysis; its output replaces it. | `p08` | prints `kept` only; `erased` absent, exit 0 | `doc/plugins.md:321-371` |
| 16 | A for-loop plugin's input is `(forcall <iter> (callargs ...) (unpackflat ...) <body>)`. | `p22` decode | `(forcall@4,3,main.nim countTo (callargs 3@D) (unpackflat (let :i.0 . . .~4,~1 .)) (stmts ...))` | probe decode |
| 17 | The loop variable arrives untyped, so a body that uses it is already an error node. | `p22`, `p23` decode | `discard i` → `(err "expression of type `void` must not be discarded")`; `echo "body ran"` → clean `(cmd write... "body ran")` | probe decode; `doc/plugins.md:8-20` (one table row, no example) |
| 18 | An import plugin's string is a module path looked up in the toolchain's library directory, not a `.nim` beside the importer. | `p12` | `main.nim(2, 1) Error: file not found: ~/.local/opt/nimony/4ba90a7/src/lib/path/foo.nim` | `doc/plugins.md:415-437` |
| 19 | The plugin path is resolved relative to the file with the pragma, not the call site: with candidates in both directories, `a/deps` wins. | `p13` | `from a/deps: hi` (both `a/deps/tagger.nim` and `b/deps/tagger.nim` present, built from `b`) | `doc/plugins.md:172-191` |
| 20 | The plugin executable is built into the declaring module's cache. | `p13` | `p13/a/nimcache/tagger` exists after building `b`; `p13/b/nimcache` has no `tagger` executable | probe filesystem |
| 21 | The plugin is a leaf of the build graph, built before the module compilations that may run it, rebuilt with them when its source changes. | doc + source read | `deps.nim:603-630` comments and `addPluginEdge` | `src/nimony/deps.nim:603-630` |
| 22 | The cache key is the checksum of the input tree, not a timestamp. | `p20`, `p04` | cache file names carry two checksums, `shape_<inputhash>_<namehash>.in.nif`; two call sites, two hashes | `src/nimony/semos.nim:1000-1015` |
| 23 | Without `dependsOn`, an edited file the plugin read does not invalidate the cached output. | `p10a` | build 1 `first`; edit `extra.txt`; build 2 `first` | probe `p10a` |
| 24 | With `dependsOn`, the plugin re-runs and the new content appears. | `p10b` | build 1 `first`; edit `extra.txt`; build 2 `second` | `doc/plugins.md:649-687` |
| 25 | `dependsOn` records only existing paths, and a directory tracks direct entry adds/removes only. | doc read, not run | `doc/plugins.md:649-687` states both limits | `doc/plugins.md:649-687` |
| 26 | `readFile` is `.raises` at the pin, so a plugin that reads a file needs `try`/`except`. | `p10a` first attempt | `deps/note.nim(7, 25) Error: cannot call a routine marked as `.raises` outside of a `try`..`except` block` | `lib/std/syncio.nim:577` |
| 27 | NIF distinguishes declarations from uses and has an index format for lazy symbol loading, "most essential for incremental compilations". | doc read | `doc/design.md:75-81` | `doc/design.md:75-81` |
| 28 | Each module has its own semantic-checking node and the driver runs them in parallel (`nifmake -j run`); a plugin is another node in that graph. | `p10a`, `p17` failure lines | `nifmake: command failed (exit code 1): ... nimsem ... --isMain nimcache/mai3r4ykk.p.nif`; `nifmake -j run --progress:0:50 ...` | `doc/language.md:5284-5297`, `src/nimony/deps.nim:603-630` |
| 29 | A plugin that writes an empty tree stops the build with `??? Error: expression expected`. | `p18` | `main.nim(3, 8) Trace: instantiation from here` / `??? Error: expression expected` | probe `p18` |
| 30 | `errorTree` as the whole output becomes a compile-time error printed as `??? Error: <message>`, without file or line. | `p19` | `??? Error: stop here` | `doc/plugins.md:688-702` |
| 31 | An `errorTree` added inside another builder asserts instead of reporting. | `p15` (two shapes) | `[Assertion Failure]` then `FAILURE: nimcache/checkint ...` | probe `p15` |
| 32 | A missing plugin source is not reported as a missing plugin: the name is looked up under the toolchain's `src/lib` and the build dies in the parser. | `p17` | `nifler2: cannot read the input file`; `FAILURE: ... nifler2 --portablePaths --deps parse ~/.local/opt/nimony/4ba90a7/src/lib/deps/nothere.nim ...` | probe `p17` |
| 33 | A `macro` with an `untyped` parameter still compiles and runs at the pin while the design replaces macros with plugins. | `ch18-probes/b01` | `5`, exit 0 | `doc/differences.md:19` |

33 claims, all with a run or a source line. Claims 25 is documentation-stated only; it is written as a limit
from the page and not as a demonstration.

## Questions for the reviewer

**A. The for-loop plugin's loop variable has no type.** `p22`/`p23` show `(unpackflat (let :i . . .))` and a body
already containing `(err "expression of type void must not be discarded")` for `discard i`. Is that a compiler
gap or the designed sequencing (the plugin is supposed to describe the loop, and the body is re-checked after
its output), and is the kind usable at the pin for any body that mentions the variable?

**B. `errorTree` in a builder asserts.** As the whole output it works and prints `??? Error: <msg>` with no
location (`p19`). Wrapped with `withTree StmtsS` + `addTree` it kills the plugin with `[Assertion Failure]`
(`p15`). Documentation defect, compiler defect, or is the whole-output form the only supported one?

**C. What else invalidates a cached plugin output?** The key is the input checksum (`semos.nim:1000-1015`). Does
editing the plugin source itself invalidate the *saved output* for an unchanged input, or only stop the plugin
executable from being current? The chapter claims the former nowhere and the reader will assume it.

**D. Build-graph claim in `src/nimony/deps.nim:603-630`.** The comment says a plugin is a leaf built before the
module compilations that may run it, with a lazy fallback for a pragma the parser could not see. Is "built once,
before the modules" the intended statement, or should the chapter keep only "cached per input and shared"?

**E. Import-plugin resolution.** `p12` shows the string resolved under `src/lib`. Is the import plugin's operand
meant to be a module path in the ordinary search path (so the executable must already be in `bin/` or the
current directory), and is the error in that order ("file not found" before "no such plugin") intended?

**F. `.plugin: "deps/p.nim"`.** With the extension, the build does not reject the pragma and the program printed
`107435824` (probe `p14`). Is a path with `.nim` supposed to be an error, and is that number the plugin reading
its own executable as input?

**G. Is the parallel claim safe to state?** The chapter says modules are separate build-graph nodes and the
driver runs them in parallel, citing the `nifmake -j run` command line and `doc/language.md:5284-5297`. Is there
a sentence in the design or the driver that says it directly enough to cite instead?

## ERRATA candidates

1. **`doc/plugins.md:8-20`, for-loop plugins: documented as a kind, no example, and at the pin a body that uses
   the loop variable arrives as an error node** (`p22`, `p23`). If A says this is the designed sequencing, the
   page needs to say that the plugin defines the variable's type; if it is a gap, the row is a compiler defect.
2. **`doc/plugins.md:688-702`, `errorTree`: the documented way to refuse an argument asserts when it is placed
   in a builder** (`p15`), and the working form prints `???` with no location (`p19`).
3. **`doc/plugins.md:172-191`, plugin search: a missing plugin is reported as a parser failure**,
   `nifler2: cannot read the input file`, with the toolchain's `src/lib` path (`p17`). The reader is told the
   search includes the standard library paths, so the message is the only way to learn the file was not found.
4. **`.plugin` pragma with the `.nim` extension is neither rejected nor resolved** (`p14`, prints
   `107435824`). Not taught in the chapter; recorded in case F is a defect.

## Watch rows proposed (not errata until a chapter freezes)

| Where | Finding | Evidence | Consequence |
| --- | --- | --- | --- |
| Chapter 19 (plugin cache) | An edited file read by a plugin does not change the expansion unless the plugin calls `dependsOn`; the cache key is the input checksum. | `p10a` (`first`, `first`), `p10b` (`first`, `second`), `semos.nim:1000-1015` | The chapter teaches `dependsOn` at the first file read, not as an advanced note. |
| Chapter 19 (plugin output) | The validator enforces tag arity and names the plugin proc; a hand-built operator needs the type child. | sample build: `expected 3..3 children, got 2 [transform builds (add)]` | The sample builds operators with the builder and copies subtrees, never by spelling the tag's children. |

**H. The child layout of an arithmetic tag.** `(add ...)` is refused with two children
(`expected 3..3 children, got 2`) while the compiler's own typed input for `2 + 3 * 4` reads
`(add (i 64)a.0.main 1)`, where the type appears attached to the first operand. What are the three
children of `add`, and is there a supported way for a plugin to construct one from a typed argument
other than copying the compiler's shape? The chapter currently tells the reader to copy a subtree or
build with the same node kinds, and says the validator names the mismatch.

---

## Verdict — reviewed 2026-11-13

Reviewer: **Momo**. Pin `4ba90a781b0b22d0821efaa153c129c37cef6143` (nimony 0.6.3). Probes re-run from my
own copy of `ch19-probes/` (rsync without `nimcache/`, so every build below is a cold one), plus new
probes where a table row did not settle the question. New probes are named `v1, b1-b5, c1, e1, f1-f3,
h4-h7, k1-k2, d8-d10` and live next to the copied probes in
`~/.openmausbot/workspaces/49df9f87-8857-46c0-b9b8-8f066a10a55e/ch19-verify/`.

Verifier, run by me from the book repository root:

```
toolchain ~/.local/opt/nimony/4ba90a7/bin/nimony 0.6.3 pin 4ba90a7
PASS samples/19-plugins-nif/plugins.nim exit=0
SUMMARY 18/18 passed, 0 failed
```

Sample output, byte-identical to the block in `en.md` section Samples:

```
infix
add
42
```

**29 of 33 claims stand — three of those with a corrected source citation — four are corrected, none is open.**

### Answers A-H

**A. For-loop plugins: the loop variable is typed from the iterator's declared yield type; it is not
"untyped".** `tryForLoopPlugin` receives `iterCall.typ` as `loopVarType` (`sem.nim:3472-3484`, comment:
"typed against the iterator's element type … known from the plugin iterator's declared yield type").
`iterator countTo(n: int) {.plugin: "deps/forloop".}` declares no yield type, so the element type is
`void` and `discard i` is an error node before the plugin runs. Declare `: int` and the same probe
delivers a typed variable and a clean body:

```
iterator countTo(n: int): int {.plugin: "deps/peek".}
for i in countTo(3):
  discard i + 1
→
(forcall countTo (callargs 3) (unpackflat (let :i.0 . . (i@G 64).))
 (stmts (discard (add (i 64)i.0 1))))          # probe v1, exit 0, prints "took"
```

So this is designed sequencing, the kind is usable at the pin, and the body *is* something a for-loop
plugin can transform. The chapter's "the loop variable arrives without a type" and "the body is not
something a for-loop plugin can transform in place at this pin" are both wrong as written.

**B. `errorTree` inside a builder does not assert — `tagText` on a symbol does.** `p15` calls
`arg.tagText` before it ever builds the error; `tagText` indexes the tag table with the cursor's tag id
(`src/nimony/lib/plugins.nim:167-169`) and `p15`'s argument is a symbol, not a `TagLit`. Rebuilt without
that call, the same nested form works and, with the `at` overload, reports a location:

```
result.withTree StmtsS, info:
  result.addTree errorTree("must be an integer", arg)
→ main.nim(4, 11) Error: must be an integer            # probe b2
```

Whole-output (`p19`) and nested both work. There is no "only supported form".

**C. Editing the plugin source does invalidate the saved output.** `runPlugin` re-executes when the
plugin executable is newer than the output (`needsRecompile(pluginExe, outputFile)`,
`semos.nim:1019`), and the module node lists each plugin executable as an input (`deps.nim:2025-2033`).
Probe `c1`: build 1 `AAA`, edit only `deps/note.nim` to emit `BBB`, build 2 prints `BBB`. The chapter can
say so; the trap is only the *data* file, never the plugin source.

**D. Keep "built once, before the modules" — and cite `deps.nim:2025-2027`.** That is the sentence that
says it: "Input: the executables of the plugins this module may run. They are outputs of `pluginbuild`
nodes, so nifmake builds them first and re-sems the module when one of them changes." The current
citation is wrong twice: 603-630 only carries the "plugins are leaves" comment, and `addPluginEdge` does
not exist anywhere in the tree — `grep -rn "addPluginEdge" . --include=*.nim` returns nothing.

**E. The module path is resolved first, structurally.** `importSingleFile` resolves the operand through
the search paths and errors before anything plugin-related (`semimport.nim:107-110`); the plugin
executable is only consulted by the build node afterwards, and a missing one is a shell failure, not a
compiler message:

```
import (mymod/foo) {.plugin: "nosuchplugin".}     # mymod/foo.nim exists, executable does not
→ /bin/sh: nosuchplugin: command not found
  nifmake: command failed (exit code 127): nosuchplugin mymod/foo.nim nimcache/nosuchplugin/….s.nif
                                                                        # probe e1
```

There is no "no such plugin" diagnostic at the pin, in either order.

**F. `.plugin: "deps/p.nim"` is accepted and works; the odd number is the plugin's bug.** `splitFile`
strips the extension and the executable is named `p` (`semos.nim:107-113`). Probe `f1` (`one(7)` through
`"deps/p.nim"`) prints `7`, same as `f2` without the extension. `107435824` comes from `p14`'s zero-argument
call: the plugin copies an empty cursor into the `echo` argument, and probe `f3` reproduces the identical
number with **no** extension in the pragma. Withdraw the errata row.

**G. Cite `src/nifmake/nifmake.nim:7-9`, not `doc/language.md:5284-5297`.** "Nifmake is a make-like tool
that is used by Nimony to implement parallel and incremental compilation." The scheduler is
`nifmake.nim:458-470` (ready queue, `pending`/`successors`), the flag is documented at `nifmake.nim:954`.
`doc/language.md:5284-5297` is about `.bundle` and backend tools and says nothing about plugins.

**H. `(add T X X)`: a type child, then two operands.** `doc/tags.md:35`, and the validator counts the
type as slot 0. Working hand-built operator:

```
result.withTree AddX, n.info:
  result.withTree IT, n.info: result.addIntLit 64
  result.addIntLit 2
  result.addIntLit 3
→ 5                                                # probe h4, exit 0
```

Two shapes matter. The compiler's own `(add (i 64)a.0.main 1)` is *two* syntactic children because the
type rides on the symbol; the validator accepts it, since a typed symbol contributes its type to the
type slot (probe `h6` gets a sem error, not an arity error). Copying a typed argument into the slot
instead of a type passes arity and dies in sem (`got: int64 but wanted: <type error>`, probes h5/h6), so
the rule for a plugin is: put a type node in slot 0, or copy the compiler's shape *without adding a third
child*. The arity message itself comes from the plugin's own build, `/bin/validator`, over the builder
calls — not from a check of the runtime tree:

```
deps/mk.nim(5, 3) Error: expected 3..3 children, got 2 [transform builds (add)]
FAILURE: .../bin/validator --nimcache:nimcache/mk_v deps/mk.nim           # probe h7
```

### Claim verdicts

| # | Verdict | Note |
| --- | --- | --- |
| 1 | stands | `doc/differences.md:19` verbatim. |
| 2 | stands | `doc/language.md:5307-5308`. |
| 3 | stands | `p01` prints `Hello, world!`, exit 0. |
| 4 | stands | `doc/design.md:90`; the failing line in `p17` carries `-d:nimonyPlugin`. |
| 5 | stands | `p05` decode: `(infix \2B a~2 1)`. |
| 6 | stands | `p04` decode: `(add (i 64)a.0.mai3r4ykk 1)`. |
| 7 | stands | `p20` writes two `.in.nif`; `k1` build 2 reuses the output. |
| 8 | stands | `p02` prints `dropped before name resolution` / `survived`, exit 0. |
| 9 | stands | `p03` identical output with `x: typed`. |
| 10 | stands | `src/nimony/lib/plugins.nim:1095-1105`; input built at `templates.nim:322-334`. |
| 11 | stands | `p06` prints `42`; without the return type `got: void but wanted: int64`. |
| 12 | stands | Sample: `42`. |
| 13 | stands | `h7` reproduces it; mechanism in answer H. |
| 14 | stands | `doc/plugins.md:65-85`: ordinal equals `TagId`. |
| 15 | stands | `p08` prints `kept` only; `doc/plugins.md:321-323`. |
| 16 | stands | `p22` decode matches the shape exactly. |
| 17 | **corrected** | Loop variable is typed from the iterator's declared yield type; without one it is `void`, not "untyped". See A. |
| 18 | stands | `p12` errors on the library path before anything else. |
| 19 | stands | `p13` prints `from a/deps: hi` with both candidates present. |
| 20 | **corrected** | Executable goes to the *compiling build's* nimcache, not the declaring module's. See below. |
| 21 | stands, citation fixed | `deps.nim:2025-2027`; `addPluginEdge` does not exist. See D. |
| 22 | stands, detail fixed | Key is the input checksum; the second hash is the type-definitions input, not a name hash. See below. |
| 23 | stands | `k1`: `FIRST` then `FIRST` after editing `extra.txt`. |
| 24 | stands | `k2`: `FIRST` then `SECOND`. |
| 25 | **narrowed** | "nothing below them" is contradicted; see below. |
| 26 | stands | `lib/std/syncio.nim:577` is exactly `proc readFile*(filename: string): string {.raises.}`. |
| 27 | stands | `doc/design.md:80-81`, quote verbatim. |
| 28 | stands, citation fixed | Claim is right; `doc/language.md:5284-5297` is about backend tools. See G. |
| 29 | stands | `p18`: `??? Error: expression expected` at the call site. |
| 30 | stands | `p19`: `??? Error: stop here`, no file or line. |
| 31 | **corrected** | Not `errorTree`; `tagText` on a symbol. See B. |
| 32 | stands | `p17`: `nifler2: cannot read the input file` then the `src/lib` path. |
| 33 | stands | `ch18-probes/b01` prints `5`, exit 0. |

### Corrections

**Claim 20 — where the executable lands.** `pluginExePath` uses the running build's `nifcachePath`
(`semos.nim:107-113`), or the shared stdlib cache when the plugin source is in the stdlib. Nothing in it
refers to the declaring module's cache. Probe `p13`: after building `b`, `b/nimcache/tagger` exists and
`a/nimcache` does not exist at all; after building a program inside `a`, `a/nimcache/tagger` exists and
`b`'s copy is a separate executable. Two builds, two executables, both from `a/deps/tagger.nim`.

**Claim 22 — what the two hashes are.** `basename = pluginName & "_" & computeChecksum(pluginInput) &
checksumA`, where `checksumA` is the checksum of the type-definitions input (`semos.nim:1000-1015`).
`buildTypeDefsInput` always emits that tree — "A template plugin always gets this second input, empty on
the first round, so `loadTypeDefinitions()` is safe to call unconditionally" (`templates.nim:272-284`) —
and it carries the call site's line info, which is why two calls of the same template get two different
second hashes (`p20`: `57E7…` and `4F3F…`, both untyped, both with nothing requested). It is not a name
hash.

**Claim 25 — the directory limit.** Measured, twice (probes `d8`, `d10`):

```
dependsOn "data";  data/ holds one.txt and sub/
build 1                     data=<T0>  sub=<T0s>
build 2, no change          data=<T0>  sub=<T0s>      # cached
create data/sub/deep.txt    data=<T0>  sub=<T1s>      # re-ran; data's own mtime did not move
edit data/sub/deep.txt      unchanged                  # cached
touch data                  data=<T1>                  # re-ran
```

A file created one level below the named directory *does* re-run the plugin, although the directory's own
mtime did not change; editing an existing file down there does not. The recorded dependency is the
directory path itself (`(dependency "…/data")` in the `.s.deps.nif`), so something in the check walks one
level of entries; I did not pin down where, and I did not go two levels. Do not print "and nothing below
them". What is safe to print: naming a directory catches structural change at least one level down, and
naming each file is the only way to be sure.

### ERRATA

1. **`doc/plugins.md:8-20`, for-loop plugins — replace the one-line row with the yield-type rule.** At the
   pin the plugin iterator's declared element type is what types the loop variable (`sem.nim:3472-3484`).
   Without one the variable is `void` and any use of it in the body is already an error node (`p22`),
   which reads like "for-loop plugins cannot see their body" and is not what the implementation does
   (probe `v1`). Documentation defect, not a compiler defect.
2. **`doc/plugins.md:673-678`, the directory limit — "and nothing else" does not hold.** A file created
   inside a direct subdirectory re-ran the plugin (`d8`, `d10`). Narrow the sentence to what a new build
   actually notices, or drop the claim about depth.
3. **`doc/plugins.md:172-191`, plugin search — a missing plugin still surfaces as `nifler2: cannot read
   the input file` with a `src/lib` path** (`p17`). Keep as a diagnostics gap: the message never says
   "plugin", so the reader learns the search list by reading a path in a parser failure.
4. **Withdrawn: the `.nim` extension row.** It is accepted, the extension is stripped, and the number in
   `p14` is a plugin bug (`f1`, `f2`, `f3`). Not errata, and nothing for the chapter.

### Watch rows

| Where | Finding | Evidence | Consequence |
| --- | --- | --- | --- |
| Chapter 19 (plugin cache) | Editing the plugin source re-runs the plugin and re-sems the module; editing a data file it read does not, without `dependsOn`. | `c1` (`AAA` → `BBB`), `k1` (`FIRST` → `FIRST`), `k2` (`FIRST` → `SECOND`), `semos.nim:1019`, `deps.nim:2025-2033` | Safe to state as a rule; both halves now measured. |
| Chapter 19 (operator tags) | The validator's arity message is produced at plugin build time, from the builder calls, and a shape assembled with `takeTree` is not arity-checked there. | `h7` (`/bin/validator … deps/mk.nim`), `h4` (`5`), `h6` (sem error, no arity error) | The chapter should say a type node is slot 0, not "copy the compiler's shape". |

### Text in `en.md` that must change

- `:165` "the loop variable arrives without a type … because the plugin has not said yet what the loop
  yields" and `:173` "the body is not something a for-loop plugin can transform in place at this pin":
  replace with the yield-type rule (answer A).
- `:194` "The plugin executable is built into `a`'s cache, not `b`'s": wrong (claim 20).
- `:196` citation `src/nimony/deps.nim:603-630`: replace with `:2025-2027` (answer D).
- `:216` "tracks the addition and removal of its direct entries and nothing below them": narrow it
  (claim 25).
- `:232` citation `src/nimony/deps.nim:603-630` and the `-j run` inference: cite
  `src/nifmake/nifmake.nim:7-9` and `:458-470` (answer G).
- `:248` "adding an error tree inside another builder failed with `[Assertion Failure]` at the pin":
  wrong, and it must not stay (answer B).
- `:138` "Copy a subtree from the input … and let the validator tell you when the shape is wrong":
  replace with the `(add T X X)` rule (answer H).

Not verified by me, and not claimed by the chapter: whether the directory check goes deeper than one
level; the cost of a plugin call. `en.md`, `id.md` and `samples/` were not touched.

## Editorial pass — 2026-11-13

Text changes applied from the verdict, then frozen. `en.md` and `id.md` are one text in two languages; the
`id.md` was written from the corrected `en.md`, not from the draft.

| Line (pre-edit) | Change | Source |
| --- | --- | --- |
| `:132-138` | Validator runs at plugin build time; arithmetic tags take a type node in slot 0 before the two operands, with the `AddX`/`IT` snippet; the typed-argument-in-type-slot trap named | Answer H, `h4`, `h7` |
| `:156-173` | For-loop plugin: loop variable typed from the declared yield type, `(unpackflat (let :i.0 . . (i@G 64).))`, error-node shape shown for the no-yield-type case, "not transformable" removed | Answer A, `v1`, `p22` |
| `:194` | Executable lands in the running build's nimcache, `a/nimcache` never created, cache is per build | Claim 20, `p13` |
| `:196` | Citation `deps.nim:603-630` → `:2025-2027`, with the quoted input comment | Answer D |
| `:216` | Directory limit narrowed: structural change one level down re-runs, editing a file down there does not | Claim 25, `d8`, `d10` |
| `:216-228` | New sentence: the plugin source is the one file outside the trap (re-runs and re-sems); the trap is data only | Answer C, `c1` |
| `:232` | Citation `deps.nim:603-630` → `nifmake.nim:7-9` and `:458-470`, quoted | Answer G |
| `:248` | `errorTree` nested in a builder works; the assert is `tagText` on a symbol | Answer B, `b2` |
| `:250-278` | Fourth failure shape: missing executable prints a shell line and exit 127, no compiler message | Answer E, `e1` |
| `:285` (Checks 4) | Exercise now asks for the type node in slot 0 instead of "the same shape with `withTree` and `addSubtree`" | Answer H |

Verifier after the edits: `18/18 passed, 0 failed`, pin `4ba90a7`. Shipped as `v0.1.12`.
