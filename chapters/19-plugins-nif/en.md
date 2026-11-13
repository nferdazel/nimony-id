---
chapter: 19
title: Plugins and the NIF Pipeline
job: Replace the macro habit with plugins that operate on NIF, and explain what NIF buys in incremental and parallel builds.
nimony_version: 0.6.3
nimony_commit: 4ba90a781b0b22d0821efaa153c129c37cef6143
toolchain: ~/.local/opt/nimony/4ba90a7
host_compiler: ~/.local/opt/nim-2.4.0
status: frozen
tech_review: Momo 2026-11-13
editorial_pass: 2026-11-13
samples: [samples/19-plugins-nif/plugins.nim]
glossary_added: [plugin, NIF, template plugin, module plugin, for-loop plugin, plugin cache]
---

# Plugins and the NIF Pipeline

## What this chapter is for

A macro was a routine that ran inside the compiler and returned code. Nimony has no such routine: `doc/differences.md:19` says macros are replaced by compiler plugins. A plugin is a separate Nim program that the compiler compiles, runs as a subprocess, and feeds a tree, and that answers with a tree. Everything the plugin can see and everything it can produce is NIF, the same representation the compiler's own phases pass to each other. That is the point of the design, and it is also what makes a plugin faster to reason about than a macro: its input and output are files you can open.

## A plugin is a template without a body

The declaration looks like a template. The body is a pragma naming another file:

```nim
# main.nim
import std / syncio

template generateEcho(s: string) {.plugin: "deps/mplugin1".}

generateEcho("Hello, world!")
```

```nim
# deps/mplugin1.nim
import plugins

proc transform(n: NifCursor): NifBuilder =
  result = createTree()
  let info = n.info
  var arg = callArgs(n)
  result.withTree StmtsS, info:
    result.withTree CallS, info:
      result.addIdent "echo"
      result.takeTree arg

var inp = loadPluginInput()
saveTree transform(inp)
```

Compiled and run, that prints `Hello, world!`. `doc/language.md:5307-5309` states the rule behind it: a plugin is a template that lacks a body and carries a `{.plugin.}` pragma listing the Nim program that implements it.

Read the second file as an ordinary program, because that is what it is. It imports one module, `plugins`, whose API is NIF cursors for reading and a builder for writing. `loadPluginInput()` opens the file the compiler passed as the first argument. `saveTree` writes the result to the file named by the second argument. Nothing else connects the two processes. The compiler writes input, runs the executable, reads output, and splices the result into the module it is checking (`doc/design.md:86-90`, `src/nimony/semos.nim:973-1020`).

Two consequences follow from "ordinary program". The plugin is compiled to native code by Nimony itself, with `-d:nimonyPlugin`, so a plugin that does not build fails before any code that uses it is checked. And the plugin runs in its own address space: it cannot reach into the compiler's symbol tables, which is why the interesting part of the API is about asking for what it is missing rather than walking structures it cannot see.

## What arrives depends on the parameter

The same call argument reaches a plugin in two different shapes. Declare the parameter `untyped` and it arrives as source, before name resolution. Declare it `typed` and it arrives after semantic analysis, lowered and resolved.

```nim
import std / syncio

template shape(x: untyped) {.plugin: "deps/shape".}
template typedShape(x: typed) {.plugin: "deps/shape".}

shape(2 + 3 * 4)
typedShape(2 + 3 * 4)
```

A plugin that prints the first argument's tag reports `infix` for the first call and `add` for the second. The difference is in the cached input files, and the compiler keeps them: each invocation writes its input to a `.in.nif` file under `nimcache`, in NIF's binary form behind the usual extension. `tools/niftools bif2nif` decodes one in place. The `untyped` input for the call above reads, with paths and indices left out:

```
(stmts shape (infix \+ a~2 1))
```

The `typed` input for the same source reads:

```
(stmts typedShape (add (i 64)a.0.main~2 1))
```

Four things changed. The operator's sugar is gone: `2 + 3 * 4` was an `infix` node with an operator token, and it is an `add` node now. The identifier `a` became `a.0.main`, a symbol that names its declaration and its module. The symbol carries its type, `(i 64)`, so an argument's type is readable without asking the compiler for a declaration. And the tree says `2` where the source said a literal operand of an infix expression. That is what "semantically checked, lowered NIF" means in practice.

Raw input is not checked, and that is not a detail. A plugin that drops its argument can be called with a name that does not exist:

```nim
template ignore(x: untyped) {.plugin: "deps/drop".}

ignore(notDeclared + 1)
echo "survived"
```

That builds and prints `survived`, because the argument is never resolved: the plugin was handed `(infix \+ notDeclared 1)` and answered with something else. Change the parameter to `typed` and the same call still builds if the plugin still drops it, which is the useful lesson: the parameter kind decides what the plugin is given, not when the argument is checked. An argument the plugin passes through is checked when the plugin's output is checked.

The wrapper is worth memorising because every plugin writes against it. The input is a `(stmts <template name> <argument>...)` node, and `callArgs` exists to skip both the wrapper and the name (`src/nimony/lib/plugins.nim:1095-1105`). A plugin given two arguments calls `callArgs` once and iterates from there.

The parameter kind is also the one place a plugin template differs from a template in a way that bites. A plugin that produces a value needs the return type written on the declaration:

```nim
proc twice(n: int): int = n + n

template double(x: typed): int {.plugin: "deps/double".}

echo double(21)      # 42
```

Omit the `: int` and the expansion has no type: `let b = double(21)` fails with `type mismatch: got: void but wanted: int64`. A plain template infers a value from its body; a plugin template has no body to infer from, so the declaration has to say.

## Writing the tree back

The builder is small, and the sample uses most of it. `withTree` opens a node, runs a block, and closes it. `addIdent` writes a name that the compiler will resolve in the caller's scope. `addStrLit` writes a string literal. `takeTree` copies the current subtree from the input and advances the cursor. `addSubtree` copies without advancing, which is how one argument becomes two:

```nim
proc transform(n: NifCursor): NifBuilder =
  result = createTree()
  let info = n.info
  var arg = callArgs(n)
  result.withTree CallX, info:
    result.addIdent "twice"
    result.addSubtree arg

var inp = loadPluginInput()
saveTree transform(inp)
```

That plugin replaces `double(21)` with a call to `twice(21)`, and `twice` is resolved afterwards, in the module that made the call. A plugin therefore emits names, not bound symbols, unless it deliberately copies a symbol out of its input.

Tags are written as enum values (`StmtsS`, `CallS`, `CallX`, `AddX`) rather than as strings. All five classes, statements, expressions, types, pragmas and the substructures that are none of those, share one ordinal space with the compiler's tag ids (`doc/plugins.md:65-85`). The payoff is a compile error in the plugin for a misspelled tag name instead of a malformed tree at run time.

The compiler validates what comes back, and it does that while building the plugin, not when the tree is spliced. A builder that produces `(add ...)` with two children is refused with the plugin source named in the message:

```
deps/double.nim(7, 3) Error: expected 3..3 children, got 2 [transform builds (add)]
FAILURE: .../bin/validator --nimcache:nimcache/double_v deps/double.nim
```

Three children, because the arithmetic tags carry more than the two operands the source shows: a type in slot 0, then the left and the right operand. The compiler's own input for `2 + 3 * 4` writes `(add (i 64)a.0.main 1)`, which reads as two children only because the type rides on the symbol. A hand-built operator supplies the type itself:

```nim
result.withTree AddX, info:
  result.withTree IT, info: result.addIntLit 64
  result.addIntLit 2
  result.addIntLit 3
```

That node evaluates to `5`. Copying a typed argument into the type slot instead passes the arity check and dies later in semantic analysis, so the rule is a type node first, or the compiler's two-children shape with nothing added.

## Four scopes, one mechanism

A template plugin runs at each call site. The other kinds run at different scopes, and `doc/plugins.md:8-20` lists them: a for-loop plugin declared on an `iterator`, a module plugin declared as a statement, a type plugin attached to a type, and an import plugin attached to an `import`.

A module plugin receives the entire module after semantic analysis and must return the entire module. That is how a whole-module transformation stays a tree edit instead of a set of call-site hooks:

```nim
{.plugin: "deps/erase".}

echo "kept"
block:
  echo "erased"
```

With a plugin that skips top-level `block` statements, the program prints `kept` and nothing else. The erased block is gone before code generation, not skipped at run time.

A for-loop plugin is declared on an iterator with no body, and it is invoked for a `for` loop that calls it. Its input is the whole loop, not a call site. The loop variable is typed from the element type the iterator declares, so an iterator that names one hands the plugin a typed variable and a clean body:

```
(forcall countTo
 (callargs 3)
 (unpackflat (let :i.0 . . (i@G 64).))
 (stmts (discard (add (i 64)i.0 1))))
```

That is `iterator countTo(n: int): int {.plugin: "deps/peek".}` with a body reading `discard i + 1`, and the declared `: int` is where `(i@G 64)` comes from. Leave the return type off and the element type is `void`, so the variable arrives untyped and a body that mentions `i` is already an error node by the time the plugin sees it:

```
(stmts
 (discard i.0
  (err "expression of type `void` must not be discarded")))
```

So the kind is usable for a body transformation as long as the iterator says what it yields, and the body a plugin receives is fully checked, which is what makes type-aware rewrites possible. The documentation lists the kind in one table row (`doc/plugins.md:8-20`) and states neither the rule nor an example, so this chapter states the scope and the condition together rather than teaching the kind.

An import plugin is the odd one out and worth separating in the reader's mind. `import (path/foo) {.plugin: "v2".}` names a module path and an already-built executable, not a `.nim` file resolved against the importing module (`doc/plugins.md:415-437`). At the pin, writing it without the executable present stops at the module path:

```
main.nim(2, 1) Error: file not found: .../src/lib/path/foo.nim
```

The path was looked up in the toolchain's library directory, so the import plugin's string is a module name in the ordinary search path, and its executable has to exist before the build reaches it. The in-tree example is `src/v2`, which shells out to a Nim 2 compiler and fills the cache with semchecked NIF for a whole module.

## Where the plugin lives

The path in the pragma is resolved relative to the file that contains the string, not relative to the call site. That distinction has a visible consequence when a template is exported:

```
a/lib.nim            declares template tagged*(s: string) {.plugin: "deps/tagger".}
a/deps/tagger.nim    the plugin that lib.nim names
b/main.nim           imports ../a/lib and calls tagged("hi")
b/deps/tagger.nim    a decoy with the same plugin name
```

Compiled from `b`, with a plugin of the same name sitting next to `b`, the program prints what `a/deps/tagger.nim` produced, and `b/deps/tagger.nim` is never compiled. The executable lands in the cache of the build that is running, not in the cache of the module that declares the pragma: this build writes `b/nimcache/tagger`, and `a/nimcache` is never created. A second program inside `a` compiles the same source again into its own cache, which is why the cache is per build and not per plugin. `doc/plugins.md:172-191` states the resolution rule; the probe is the check that the rule holds when both candidates exist.

The build graph treats the plugin as a leaf: the module node lists the executables of the plugins it may run as inputs, and those executables are outputs of `pluginbuild` nodes, so the driver builds them first and re-checks the module when one of them changes (`src/nimony/deps.nim:2025-2027`). That is why a plugin edit is not a full rebuild and why a plugin that is never invoked by a changed module is not rebuilt either.

## The cache, and the one call that keeps it honest

A plugin invocation is cached by the checksum of its input tree, not by the clock. `runPlugin` computes that checksum, names the input and output files after it, and reuses the output when the files are current (`src/nimony/semos.nim:1000-1015`). Two call sites produce two inputs and two runs; the same call site on the next build produces one file and no run.

That is correct for a plugin whose answer depends only on its input, and wrong for a plugin that reads anything else. A plugin that reads a schema file, a table of constants or a template would be memoised forever: the file changes, the input does not, and the build keeps the old expansion. The fix is one call:

```nim
dependsOn "extra.txt"
```

`dependsOn` reports the read, and the compiler re-runs the plugin when the named file is newer than the cached output (`doc/plugins.md:649-687`). The difference is easy to see with a plugin that echoes the contents of a file:

```
             first build     after editing extra.txt
no dependsOn    first                  first
dependsOn       first                  second
```

Two limits matter when the file is not a single path. Only a path that exists is recorded, so creating a file the plugin looked for and did not find invalidates nothing. Naming a directory is not naming its contents: a file created inside a direct subdirectory re-runs the plugin even though the directory's own timestamp does not move, while editing an existing file down there changes nothing at all. Track each file when the contents of a tree matter.

The plugin's own source is the one file that never falls into that trap. It is an input to the module node, so editing it re-runs the plugin and re-checks the module, while a data file the plugin read stays invisible until `dependsOn` names it.

There is one more thing to know before writing a plugin that reads a file: at the pin `readFile` is declared `.raises` (`lib/std/syncio.nim:577`), so a plugin that calls it must catch it:

```
deps/note.nim(7, 25) Error: cannot call a routine marked as `.raises` outside of a `try`..`except` block
```

## What NIF buys in a build

The chapter's second job is the reason this design exists, and the honest version is smaller than "NIF makes builds fast". Three properties do the work, and they are properties of the format, not of the plugin system.

Declarations and uses are separate token kinds (`doc/design.md:75-81`). The compiler can answer "where is this declared" and "who uses this" from the representation, with no name matching over text, and a plugin gets the same information for free: `symText` and the symbol in the tree are the identity, not a spelling to be resolved again.

Symbols load lazily. NIF has a companion index format that lets the compiler pull a symbol on demand instead of reading a whole module, which `doc/design.md:81` names as "most essential for incremental compilations". A module's header can be read without reading its bodies, so a change in one module does not force the compiler to re-read the interface of every module above it.

Modules are separate nodes in one graph. Each module has its own semantic-checking node, and the driver runs a graph rather than a list: nifmake is "a make-like tool that is used by Nimony to implement parallel and incremental compilation" (`src/nifmake/nifmake.nim:7-9`), scheduling from a ready queue (`:458-470`), and the command line in a failed build reads `nifmake -j run`. A plugin is another node in that graph. It therefore does not serialise the build it participates in: it is built once, cached by input, and shared by every module that invokes it. The parallel part belongs to the build graph, not to the plugin. Nothing in this chapter makes a plugin concurrent, and a plugin that writes a shared file from two modules at once is a bug you wrote.

What NIF costs is equally concrete. A plugin author works with the tags of a compiler IR, not with an AST designed for humans, and the input is a frozen snapshot: the plugin cannot ask the compiler a question except by asking for a type declaration it needs. That is the subject of `needTypes`, which makes the compiler append the declarations the plugin names to a second input and run the plugin again (`doc/plugins.md:226-273`). A plugin that never inspects types pays nothing, and one that does asks for a whole level at a time rather than a symbol at a time.

## When a plugin goes wrong

Four failures are worth recognising, because their messages do not say "plugin".

A plugin that writes an empty tree stops the build with `??? Error: expression expected`, pointing at the call site. The `???` is the plugin output's missing source position, not a broken diagnostic: the output had no location because the builder wrote none.

A plugin that wants to report a problem returns `errorTree`, and the compiler prints it as a compile-time error:

```
??? Error: stop here
```

That is the documented way to refuse an argument (`doc/plugins.md:688-702`), and the message arrives without a file and line unless the plugin supplies one. Both shapes work. Return it as the whole output, or add it inside another builder (`result.addTree errorTree("must be an integer", arg)`), where the overload taking a cursor reports the argument's position as `main.nim(4, 11) Error: must be an integer`. What does assert inside a builder is `tagText` called on a symbol: it indexes the tag table with the cursor's tag id (`src/nimony/lib/plugins.nim:167-169`), and a symbol has none.

A plugin source that does not exist is not reported as a missing plugin. The name is resolved in the toolchain's library directory, and the build dies in the parser:

```
nifler2: cannot read the input file
FAILURE: .../nifler2 --portablePaths --deps parse .../src/lib/deps/nothere.nim ...
```

Read the path in that line: it tells you where the compiler looked. A path that begins with your project's directory is the one you meant; a path under the toolchain's `src/lib` means the pragma's string was resolved as a library module, and the plugin file is missing from the declared path.

The fourth shape has no compiler message at all. A plugin that resolves but whose executable is missing is run as a command, and the shell is what complains:

```
/bin/sh: nosuchplugin: command not found
nifmake: command failed (exit code 127): nosuchplugin mymod/foo.nim nimcache/...
```

So a build that stops with exit code 127 and a shell line is not a broken toolchain: the pragma's path resolved to something that is not there.

## Nim 2 delta

*What Nim 2 did.* A macro was a routine with two halves: Nim code that ran in the compiler and a `NimNode` tree it returned. `std/macros` was the API, and a macro was called like a template.

*What Nimony does.* A plugin is a separate program compiled to native code, invoked as a subprocess, reading NIF and writing NIF. There is no in-process tree API, no `NimNode`, and no way to hand the compiler a callback.

*What breaks if you keep the habit.* A ported macro that builds its result by calling helper procs in the same module is now a program that has to load its input, transform it, and save it, and its helpers have to be in the plugin, not in the module that uses it. A ported macro that returns a `NimNode` will not compile at all. At the pin a `macro` with an `untyped` parameter still compiles and runs, which makes the old habit look supported: `doc/differences.md:19` says macros are replaced, so treat a surviving macro as compatibility surface and write new transformations as plugins.

## Samples

`samples/19-plugins-nif/plugins.nim`, compiled and run at the pinned commit:

```
$ nimony c -r samples/19-plugins-nif/plugins.nim
infix
add
42
```

Three lines. The first two come from one plugin used twice, once through an `untyped` parameter and once through a `typed` one: the plugin reports the tag it was handed, and the tags differ because the second argument was resolved and lowered. The third is a plugin replacing `double(21)` with `twice(21)`, which the compiler then resolves and runs. The `block` that the module plugin erases prints nothing, which is the fourth thing the sample checks.

## Checks

1. Write a template plugin that takes one `untyped` argument and returns it unchanged, then call it with an expression whose value you print. Explain why the program's output is the expression and not the plugin's input.
2. Change the parameter to `typed` and decode both cached inputs with `tools/niftools bif2nif`. List three differences between them, one of which must be a symbol.
3. Write a plugin that reads a text file and emits its contents as a string literal. Build twice with the file edited in between, note that the output does not change, then add `dependsOn` and build again.
4. Make the plugin emit `(add ...)` by hand with two children and record the validator's message. Then put a type node in the first slot and two int literals after it, and record what the program prints. Try passing a typed argument where the type belongs as well.
5. Move the plugin source to a second directory and leave a decoy with the same name in the calling module's directory. Record which one runs, and where the executable is written.

## Chapter checklist

`draft 2026-11-13 · tech_review Momo 2026-11-13 · editorial_pass 2026-11-13 · frozen 2026-11-13`
