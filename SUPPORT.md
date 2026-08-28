<!-- SPDX-License-Identifier: Apache-2.0 OR MIT -->

# Support

Thanks for using langdev. Here is where to go for each kind of help.

## Questions & how-to

- **[Discussions](https://github.com/sebastienrousseau/langdev/discussions)**
  — usage questions, "how do I…", design ideas, and show-and-tell. This
  is the best first stop and keeps answers searchable for others.
- **Docs** — [`README.md`](README.md) for the overview and quick start,
  [`STYLE.md`](STYLE.md) for the house style, [`SECURITY.md`](SECURITY.md)
  for the threat model, and [`CONTRIBUTING.md`](CONTRIBUTING.md) for the
  build/lint/scan workflow.

## Bugs

Open an issue with the **Bug report** form on the affected repository. A
minimal, self-contained reproduction is the single most useful thing you
can include — the exact `make` target or `docker`/`podman` command, the
engine and version, and the host OS/arch. It usually determines how fast
a fix lands.

## Feature requests

Use the **Feature request** form. For anything touching the shared core
(`common/`, `templates/`), please float it in Discussions or the issue
first so the rationale and alternatives are captured before code is
written — a change here ripples into every `<language>dev` repo.

## Security vulnerabilities

**Do not** open a public issue. Follow the private disclosure process in
[`SECURITY.md`](SECURITY.md) (GitHub private advisory or email). You'll
get a prompt, confidential response.

## Which repo?

- **Shared behaviour** — the entrypoint, the dotfiles bootstrap, the
  hardening flags, the templates: file against **`langdev`**.
- **One language's toolchain** — the compiler/interpreter, its LSP,
  formatter, or test tools: file against that **`<language>dev`** repo.

If you are not sure, file against `langdev` and it can be moved.

## Versions & compatibility

- The suite is pre-1.0; interfaces may change between tags. Read
  [`CHANGELOG.md`](CHANGELOG.md) before upgrading, and re-run
  `make sync-common` in your `<language>dev` repos after pulling shared
  changes.
- Requires an OCI engine — **Docker** or **Podman** — on Linux, macOS,
  or Windows/WSL2.

## Response expectations

langdev is maintained by a small team (currently one person) on a
best-effort basis — there is no paid support tier or response-time SLA
today. Clear, reproducible reports get triaged fastest. Please be
patient and kind; see the [Code of Conduct](CODE_OF_CONDUCT.md).
