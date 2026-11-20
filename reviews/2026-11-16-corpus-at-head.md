# Corpus run at Nimony HEAD, 2026-11-16

The book's 23 samples were compiled and run against current `nim-lang/nimony` HEAD, not only against the pin.
Purpose: decide whether the book has anything worth contributing upstream. Technical truth here is a
compiler observation only; any claim that needs a ruling goes to Momo, any code that would go upstream goes
through Raka.

## What was run

```
git clone --depth 1 https://github.com/nim-lang/nimony            # HEAD fd5cf2fb0c2d 2026-11-15
PATH=$HOME/.local/opt/nim-2.4.0/bin:$PATH nim c -r src/hastur/hastur build all   # exit 0
```

Each of `samples/*/*.nim` (23 files, the same glob `tools/verify-samples.sh` uses) was then compiled and run
twice, once with the pin `4ba90a7` (`0.6.3`) and once with HEAD, with `--nimcache` outside the repository so
neither tree was written to. Samples were run from a copy, so the book repository is untouched.

## Result

- Pin `4ba90a7`: 23/23 pass.
- HEAD `fd5cf2f`: 23/23 pass.
- Stdout and stderr are identical between the two runs for all 23 samples. No diagnostic changed, no exit code
  changed, no output line changed.

Four further files under `samples/16-modules-visibility/support/` and `samples/19-plugins-nif/deps/` are
modules without a main and are outside the verifier's glob; they fail identically on both toolchains and are
not part of this count.

## Contract feature, spot check

`{.invariant: cond.}` landed on 15 Nov (`9ae3596`) and is documented at `doc/language.md:3292-3327`. Four
probes, all in line with that section:

| Probe | Result |
|---|---|
| `while` loop with `{.invariant: i >= 0.}` | compiles, prints `5` |
| invariant plus `break` out of the loop | compiles, prints `30` |
| invariant naming the `for` loop variable | rejected: `cannot prove loop invariant on entry: 0 <= i` |
| invariant that is false on entry | rejected: `loop invariant violated on entry: 100 < i` |

No defect found. The two rejections are the documented behaviour, and both name the claim rather than the
location only.

## What this means for a contribution

The samples are a green external corpus at HEAD two days after the pin, which is worth one paragraph and no
pull request on its own. What makes the corpus contribution-shaped is history: the same corpus produced the
`delay()` probe that became #2985 and #2988. A CI job in `nim-lang/nimony` that checks out this repository at
a tag and runs `tools/verify-samples.sh` against the freshly built compiler would catch that class of
regression in idiomatic code, which the unit tests do not cover. Cost on our side is a tag per release, which
`./task release` already makes.

Open soundness issue `#3001` (index checks dropped across `try` handlers, hook-running assignments and sink
parameters) is the other place the book has a stake: chapters 10 and 15 tell the reader the compiler keeps
array bounds. A probe set there is dual-purpose, since a contracts chapter would need the same programs.

Neither is started. Scope belongs to Wira, the upstream wording to Momo, the code to Raka.
