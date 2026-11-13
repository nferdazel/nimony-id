# Contributing

This repository is the source of *Nimony: A Pinned Guide*. Every statement in it is checked against one fixed
Nimony commit — the pin, `4ba90a781b0b22d0821efaa153c129c37cef6143` (`nimony 0.6.3`). The book has no interest in
what the language does on `master`; it has a strong interest in anything at the pin that the book got wrong.

## What you can send

| Type | How |
| --- | --- |
| An example that does not build or does not print what the chapter says | open an issue with the chapter, the command you ran, and the full output |
| A sentence that is wrong at the pin | issue first, with the source file and line in the Nimony tree that decides it |
| A typo, an unclear paragraph, a term used two ways | small pull request, one file per PR |
| A proposal for a new chapter | issue first; chapters are one job each and the outline is the contract |
| A third language | issue first; a translation needs a structural decision, not just text |

All 24 chapters and Appendices A–C are `frozen`. A frozen chapter is not rewritten. If the pin moved and a
sample broke, the break goes to [`ERRATA.md`](ERRATA.md) — that file exists precisely so a frozen chapter stays
frozen.

## Before you send

```sh
quarto --version            # 1.10.19 is what CI uses
./task check                # verify every sample at the pin, then render both editions
```

`./task check` compiles and runs every file under `samples/*/*.nim` with the pinned `nimony`, then renders the
English and Indonesian books. It prints `SUMMARY n/n passed, 0 failed`; anything else is a failure, not a
warning. The verifier refuses to report a green run when no sample exists, and refuses a toolchain that is not
the pin.

Set `QUARTO` and `NIMONY_HOME` if your copies are not on `PATH` / in the default location; `./task help` lists
both. CI runs the same command, so a green local run is the whole gate.

## Writing or changing a chapter

1. Read [`OUTLINE.md`](OUTLINE.md) for the chapter's one job and [`CHAPTER_TEMPLATE.md`](CHAPTER_TEMPLATE.md)
   for the section order, frontmatter and the six gates a chapter must pass.
2. Both editions or neither. `chapters/NN-slug/en.md` and `chapters/NN-slug/id.md` carry the same frontmatter,
   the same section order and the same code blocks. `./task build` fails closed on an unpaired chapter folder.
3. Every code block in a chapter has a file under `samples/NN-slug/` that the verifier runs. A block with no
   sample behind it is prose that nobody has compiled.
4. A new term goes into [`GLOSSARY.md`](GLOSSARY.md) in the same change that introduces it.
5. Provenance is part of the sentence. A claim about behaviour cites the Nimony file and line at the pin, or it
   is marked as design intent. "The documentation says so" is not proof of pin behaviour — the documentation
   has been wrong before, and `ERRATA.md` records where.
6. Module-level mutable state is a constraint, not a term. A plain `proc` that reads or writes a module-level
   `var` is rejected at the pin (`unsynchronized access to global variable …; pass it to a .sync routine or use
   {.cast(assumeSync).}`); `ERRATA.md` records it. A chapter that shows module-level mutable state states that
   rule at first use, and no chapter teaches a global counter as if it were free.
7. Technical truth is not the author's call. A chapter reaches `frozen` only with a named technical review
   recorded in its frontmatter and in `review.md` beside it.

## Repository sanity

This repository is public and everything in it is published twice: as Markdown on GitHub, and as a site at
`nimony.qouver.com`. Three rules follow.

1. **No path from your machine.** Use `$NIMONY_HOME`, `~/.local/opt/...` or a path relative to the repository
   root. A transcript may show a real install path only where the chapter is about that install. A review
   artifact beside a chapter is a transcript too: a workspace path in it is written home-relative (`~/...`) and
   the rest of the command is left exactly as it ran.
2. **No secret, token, private URL or personal data**, in prose or in a sample. `.gitignore` already covers
   `nimcache/`, `_book/`, `.quarto/`, `.build/` and `tools/verify-samples.log`; a build artefact in a diff is
   a mistake, not a shortcut.
3. **Nothing new executes in CI unless it is visible in the diff.** Every action is pinned by commit SHA,
   Dependabot proposes the bumps, and each job sets `timeout-minutes` and a cache. `curl | sh` is not how a
   step gets installed here.

## Versions and releases

`VERSION` is the book's version; `./task version` prints it. `./task release` reads the commits since the last
`v*` tag and bumps MAJOR on `type!:` or a `BREAKING CHANGE:` footer, MINOR on `feat:`, PATCH otherwise — this
history uses plain imperative subjects, so most releases are PATCH. The script runs `./task check`, commits
`chore: release X.Y.Z`, and creates the annotated tag `vX.Y.Z`. CI then refuses a tag that is not `v` plus the
contents of `VERSION`, and attaches the rendered `_book` to the tag run.

The script pushes nothing: `git push origin main --follow-tags`.

## Commit style

Plain imperative subject, matching the existing history:

```
Add chapter 7, Loops and Ranges
Fix loops sample output on the pin
Clarify the countdown step wording
```

A commit that touches a chapter touches that chapter's `en.md`, `id.md`, `review.md` and its sample together;
a reviewer should never need two commits to see one chapter.

## Branches and pull requests

Do not push to `main` directly. Open a pull request and let CI run `./task check`. A pull request that changes
prose states which chapters it touches and whether any frontmatter `status:` line moves.

That rule is a convention, not a server-side gate. `main` carries the "Basic Branch Guardrail" ruleset, which
refuses branch deletion and force-push only — ordinary pushes are still accepted, which is what lets
`./task release` commit the version bump and tag on `main` directly. A rejected `git push --force` is the ruleset
working; it is not a sign that the branch is broken.

## Contribution license

By sending a contribution you agree it is licensed under the same terms as the project: book text under
CC BY-SA 4.0 ([`LICENSE`](LICENSE)), code and build scripts under MIT ([`LICENSE-CODE`](LICENSE-CODE)). Do not
send text or code whose copyright is not yours.
