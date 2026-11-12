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

Chapters 1–7 are `frozen`. A frozen chapter is not rewritten. If the pin moved and a sample broke, the break
goes to [`ERRATA.md`](ERRATA.md) — that file exists precisely so a frozen chapter stays frozen.

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
6. Technical truth is not the author's call. A chapter reaches `frozen` only with a named technical review
   recorded in its frontmatter and in `review.md` beside it.

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

## Contribution license

By sending a contribution you agree it is licensed under the same terms as the project: book text under
CC BY-SA 4.0 ([`LICENSE`](LICENSE)), code and build scripts under MIT ([`LICENSE-CODE`](LICENSE-CODE)). Do not
send text or code whose copyright is not yours.
