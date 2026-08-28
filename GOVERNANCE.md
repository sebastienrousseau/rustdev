<!-- SPDX-License-Identifier: Apache-2.0 OR MIT -->

# Governance

This document describes how langdev is run: who decides what, how
changes land, and how the project intends to grow its maintainer base.
It is intentionally lightweight and will formalise as the community
grows.

## Current model

langdev is **maintainer-led**. As of the pre-1.0 line it has a single
lead maintainer, [Sebastien Rousseau](https://github.com/sebastienrousseau),
who is responsible for the roadmap, releases, and final decisions.

This is stated plainly rather than dressed up: a single maintainer is a
real bus-factor risk, and **broadening the maintainer team is an
explicit `1.0` goal**. Until then, the automation and the documented
processes below exist so the project does not depend on any one person's
memory.

## Repositories

The suite spans one source-of-truth repo and several per-language repos:

- **`langdev`** — the shared core and templates. Changes to hardening,
  the entrypoint, the dotfiles bootstrap, or the scaffolding land here
  first and are vendored downstream with `make sync-common`.
- **`<language>dev`** (`rustdev`, `pythondev`, `llamadev`, …) — each
  adds one language's toolchain layer on top of the vendored core.

The same governance, Code of Conduct, and security policy apply across
every repo in the suite.

## Roles

- **Users** — file issues, ask in
  [Discussions](https://github.com/sebastienrousseau/langdev/discussions),
  and open pull requests. No special status required.
- **Contributors** — anyone whose pull request has merged. Listed in the
  git history; thank you.
- **Maintainers** — hold merge rights across the suite. Currently one
  (the lead maintainer). Maintainers are bound by the same review and CI
  gates as everyone else.

### Becoming a maintainer

There is no rigid quota. A contributor who has landed several
non-trivial, high-quality changes, engaged constructively in review, and
shown good judgement on scope and the security posture may be invited to
become a maintainer by the lead maintainer. Reaching **two or more
active maintainers** is a stated goal on the road to `1.0`.

## How decisions are made

- **Day-to-day** (bug fixes, docs, digest bumps): lazy consensus —
  proposed via PR, merged once CI is green and review is satisfied.
- **Notable changes** (the security posture, the shared entrypoint or
  bootstrap contract, template shape, adding a new `<language>dev`
  image): discussed first in an issue or Discussion so the rationale and
  alternatives are on record before code is written. A change to the
  shared core ripples into every downstream repo, so it gets extra
  scrutiny.
- **Disagreements**: the lead maintainer is the tie-breaker while the
  project is single-maintainer. As the team grows this will move to
  maintainer consensus.

All changes, including a maintainer's own, go through a pull request and
the full CI suite (`hadolint`, `shellcheck`, image build, Trivy scan).
Direct pushes to `main` are not used.

## Security posture as policy

The default hardening — non-root, all capabilities dropped,
`no-new-privileges`, read-only rootfs, pinned and checksummed inputs, no
committed secrets — is a **governance invariant**, not a per-repo
preference. Weakening it in the shared core or a shipped image is a
notable change and must be justified in an issue before it is proposed.
See [`SECURITY.md`](SECURITY.md).

## Releases

- The suite is pre-1.0; interfaces may change between tags and are
  documented in [`CHANGELOG.md`](CHANGELOG.md).
- Releases are tag-driven; each shipped image publishes a CycloneDX
  SBOM. The cut process is encoded in the CI/release workflows, not in
  tribal knowledge.
- Commit signing is required across the suite; CI rejects unsigned
  pull-request commits.

## Code of conduct & security

Participation is governed by the [Code of Conduct](CODE_OF_CONDUCT.md).
Security issues follow the private disclosure process in
[`SECURITY.md`](SECURITY.md) — please do not open public issues for
vulnerabilities.

## Changing this document

Amend `GOVERNANCE.md` via pull request like any other change. While the
project is single-maintainer, the lead maintainer approves governance
changes; once there are multiple maintainers, governance changes require
maintainer consensus.
