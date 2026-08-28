<!-- SPDX-License-Identifier: Apache-2.0 OR MIT -->

# Contributing to langdev

Contributions are welcome. This guide covers the essentials for the
container suite: how to build and verify a change locally, how commits
are formatted and signed, and what CI expects.

`langdev` is the single source of truth. Language-agnostic changes land
here and are vendored into each `<language>dev` repo via
`make sync-common`. A change to shared behaviour belongs in this repo;
a change to one language's toolchain belongs in that language's repo.

## Prerequisites

- **Docker** or **Podman** — the suite builds with either. The
  `Makefile` auto-detects which you have.
- **hadolint** and **shellcheck** for local linting (CI runs them too).
  Optional but recommended: **trivy** (image scan) and **syft** (SBOM).
- **Git with commit signing configured** — see
  [Signed commits](#signed-commits) below. Unsigned commits are not
  merged.

## Getting started

```sh
git clone https://github.com/sebastienrousseau/langdev.git
cd langdev
```

The templates in `templates/` and the shared core in `common/` are what
you edit here. To exercise them end to end, sync them into a
`<language>dev` repo and build there:

```sh
cd ../rustdev
make sync-common LANGDEV=../langdev   # vendor your changes in
make build                            # build the image
make up                               # interactive smoke test
```

## The container workflow

Every `<language>dev` repo exposes the same lifecycle through `make`.
Run these before opening a pull request:

```sh
make build        # build the image for the host arch
make lint         # hadolint the Containerfile + shellcheck the scripts
make scan         # Trivy scan — must pass with no HIGH/CRITICAL findings
make sbom         # generate a CycloneDX SBOM (release artifact)
```

- **`make lint`** must be clean. `hadolint` gates the `Containerfile`;
  `shellcheck` gates every `*.sh`. Fix findings rather than suppressing
  them; if a suppression is genuinely warranted, add an inline
  `# hadolint ignore=…` / `# shellcheck disable=…` with a one-line
  reason in the same commit.
- **`make scan`** must report no HIGH or CRITICAL vulnerabilities. If a
  finding is unfixable upstream, document it in the PR and pin around it
  where possible — do not silence the scanner globally.
- **`make build` must not introduce an un-pinned input.** New base
  images are pinned by digest; new downloaded binaries are
  checksum-verified; new language deps come from a hash-locked lockfile.
  A `curl | sh` will not be merged.

## Branch naming

Use Conventional Commits-flavoured prefixes so a reviewer knows the
shape of the change before opening the diff:

| Prefix | Use when… | Example |
|---|---|---|
| `feat/` | adding user-visible behaviour or a new image | `feat/pythondev-uv-cache` |
| `fix/` | fixing a bug whose behaviour change is observable | `fix/entrypoint-signal-forwarding` |
| `refactor/` | restructuring without behaviour change | `refactor/split-toolchain-stage` |
| `docs/` | docs-only changes | `docs/security-threat-model` |
| `ci/` | CI / build / packaging changes | `ci/pin-trivy-action` |
| `chore/` | housekeeping, digest bumps, and similar | `chore/bump-alpine-digest` |

Open PRs against `main`.

## Making changes

1. Fork the repository and create a branch using the prefixes above.
2. Make the change. Match the local style of the file you are touching —
   read a couple of neighbours before introducing a new pattern.
3. Keep the SPDX header intact:
   `# SPDX-License-Identifier: Apache-2.0 OR MIT` in scripts, YAML,
   Makefiles, and Dockerfiles; `<!-- SPDX-License-Identifier:
   Apache-2.0 OR MIT -->` in Markdown. New files must carry it too.
4. Run `make lint` and, where a built image is affected, `make build`
   and `make scan`.
5. Commit with `git commit -S` (signed).

If you change anything under `common/` or `templates/`, note in the PR
which `<language>dev` repos need a `make sync-common` follow-up.

## Commit messages

[Conventional Commits](https://www.conventionalcommits.org/) format. The
scope is the subsystem touched:

```
<type>(<scope>): <imperative summary>

<optional body explaining the why>

<optional footer with breaking-change notes, issue refs>
```

Types: `feat`, `fix`, `refactor`, `docs`, `ci`, `chore`, `build`,
`revert`.

Scopes: subsystem or template (`entrypoint`, `bootstrap`, `compose`,
`containerfile`, `makefile`, `ci`, `sync`) or a language image name
(`rustdev`, `pythondev`, `llamadev`) when the change targets one.

Examples:

```
feat(compose): drop all capabilities and set no-new-privileges
fix(entrypoint): forward SIGTERM to the tmux session leader
chore(containerfile): pin alpine base by digest
docs(security): document the pinned + checksummed input contract
ci(workflow): fail the build on HIGH/CRITICAL Trivy findings
```

## Signed commits

Every commit must be signed. CI rejects unsigned pull-request commits.
Configure SSH or GPG signing per the
[GitHub guide](https://docs.github.com/en/authentication/managing-commit-signature-verification/signing-commits),
then commit with `git commit -S`. To sign by default:

```sh
git config commit.gpgsign true
```

By signing, you also make the Developer Certificate of Origin
attestation below verifiable — the commit is provably yours.

## Developer Certificate of Origin

By contributing, you certify the [Developer Certificate of Origin
1.1](https://developercertificate.org/): that you wrote the change or
have the right to submit it under the project's license. The signature
on your commit is the record of that attestation; no separate
`Signed-off-by` trailer is required.

## Pull requests

- Open against `main`.
- Title follows the same Conventional Commits format as commits.
- Body includes:
  - **What changed** in 1–3 bullets
  - **Why** in plain English
  - **How you verified it** — the `make` targets you ran and their
    result (lint clean, image builds, scan clean)
- Keep PRs focused. One logical change per PR.
- CI must be green: `hadolint`, `shellcheck`, image build, and the Trivy
  scan. See [`templates/github-workflows/ci.yml`](templates/github-workflows/ci.yml).
- One approval is required to merge.

## Reporting issues

Open an issue on GitHub with the **Bug report** form. Include:

- The engine and version (`docker --version` or `podman --version`) and
  host OS/arch.
- The exact `make` target or command you ran.
- Expected behaviour vs. actual behaviour, with the full output.

For security issues, **do not file a public issue.** See
[`SECURITY.md`](SECURITY.md) for the private disclosure process.

## License

By contributing, you agree that your contributions are dual-licensed
under [Apache-2.0](LICENSE-APACHE) **or** [MIT](LICENSE-MIT), at the
user's option, matching the suite's `SPDX-License-Identifier:
Apache-2.0 OR MIT`.
