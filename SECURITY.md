# Security policy

## What this repository is

A book: Markdown chapters in two editions, Nim sample files, a POSIX shell build script, and one GitHub Actions
workflow. There is no service, no API, no database, no user data, and no credential of any kind. That shapes what
counts as a security report here.

## Supported versions

Only `main` is maintained. The book is pinned to `4ba90a781b0b22d0821efaa153c129c37cef6143` (`nimony 0.6.3`) and
issues in older commits are not patched; they are recorded in [`ERRATA.md`](ERRATA.md) and fixed forward.

## What to report here, privately

- A secret, token or private path committed by mistake.
- A sample, script or workflow step that does something other than what it says — especially anything that
  fetches and executes code beyond the pinned toolchain and the actions named in `.github/workflows/`.
- A build script or `tools/` change that could write outside the repository, or a render that could publish
  something unintended.
- A link in the manuscript that resolves to malware, phishing, or a look-alike of a project site.

Use GitHub's **Report a vulnerability** (Security tab → Advisories) so the report stays private. Please do not
open a public issue first. Include the commit, the file, what you ran, and what happened.

## What belongs somewhere else

| Report | Where |
| --- | --- |
| A compiler or language bug at the pin | [nim-lang/nimony](https://github.com/nim-lang/nimony), at commit `4ba90a7` — the compiler is not ours to patch |
| A vulnerability in Nimony, in Nim, or in Quarto | that project's own security process |
| A statement in the book that is wrong at the pin, a broken example, a typo | an ordinary issue — see [`CONTRIBUTING.md`](CONTRIBUTING.md) |
| A vulnerability in GitHub Actions or a third-party action we use | GitHub Security Lab, and tell us as well |

The book does not vendor, bundle or redistribute the compiler, so a Nimony advisory does not have a version of
ours to fix. It does have a chapter that may need an errata row, and we will add one.

## How the repository is set up against that

- Workflows are read-only by default (`permissions: contents: read`); only the Pages job takes `pages: write`
  and `id-token: write`, for the one deploy it exists to do.
- Every action is pinned by commit SHA and Dependabot proposes the bumps, so a moved `@v4` tag cannot change
  what runs here.
- The gate compiles the pinned toolchain from `nim-lang/nimony` at the pin and runs `nimony c` inside the
  repository. No step downloads and executes an artefact that is not named in the workflow.
- The site publishes from `main` only, through `.github/workflows/pages.yml`. A pull request cannot reach the
  deploy job, and the deploy writes nothing back to the repository.
- No secret is stored in the repository and none is needed by the site. A report that a real credential
  appeared in a file or a sample is the highest-priority kind of report here.

## What we do

1. Confirm the report against the named commit, in private.
2. If a secret was committed: rotate it first, then remove it from history — deleting the file is not enough.
3. If the fix changes what a frozen chapter teaches, the chapter text stays as it is and the correction goes to
   [`ERRATA.md`](ERRATA.md); only a broken sample is patched in place.
4. Say what happened and what changed, once the fix is in `main`.

There is no bounty program and no response-time guarantee beyond "as fast as one maintainer can".
