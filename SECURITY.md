<!-- SPDX-License-Identifier: Apache-2.0 OR MIT -->

# Security Policy

## Supported versions

The suite is pre-1.0. Security fixes land on `main` and are vendored
into each `<language>dev` repo via `make sync-common`.

| Series | Supported |
|:-------|:---------:|
| `main` (latest) | Yes |
| older tags | Best effort — upgrade to latest |

## Reporting a vulnerability

Report security vulnerabilities privately by opening a
[GitHub Security Advisory](https://github.com/sebastienrousseau/langdev/security/advisories/new)
on the affected repository, or by emailing
**sebastian.rousseau@gmail.com**.

**Do not open a public issue for a security report.**

Include:

- A description of the vulnerability and its impact.
- The affected component — the `Containerfile`, `compose.yaml`, the
  entrypoint or bootstrap scripts, or a specific `<language>dev` image.
- Steps to reproduce, ideally with the exact `make` target or
  `docker`/`podman` command.
- Affected versions or commit SHAs.
- Any suggested fix (optional).

Expect an initial response within 48 hours. A fix or mitigation plan
will follow within 7 days of confirmation.

## Threat model

langdev builds *disposable development environments*. The primary
assets are the developer's host, the project source mounted at `/work`,
and any runtime secrets passed via `env_file`. The design assumes a
container may run code that is untrusted, buggy, or compromised, and
constrains what such code can reach.

### In scope

- Container breakout or host privilege escalation from inside an image.
- A build that pulls an unpinned or unverified input (base image,
  binary, or dependency) and so admits a supply-chain substitution.
- A secret committed to git or baked into an image layer.
- An entrypoint or bootstrap script that mishandles signals, untrusted
  environment variables, or filesystem permissions.

### Out of scope

- Vulnerabilities in the user's own dotfiles repo (the environment *is*
  the user's dotfiles — the user owns that content).
- Vulnerabilities in language toolchains or third-party tools shipped by
  a `<language>dev` image, beyond keeping them pinned and scanned.
- Deliberate, documented relaxations a user applies on their own host
  (for example re-adding a capability for GPU access).

## Security controls

Every image in the suite ships these by default. They are the container
threat model made concrete.

### Runtime least privilege

- **Non-root.** The container runs as `dev` (UID/GID 1000). There is no
  `sudo` and no setuid binary in the image.
- **All capabilities dropped.** Compose sets `cap_drop: [ALL]`; `make
  up` passes `--cap-drop ALL` on the CLI. No capability is added back.
- **No privilege escalation.** `security_opt: [no-new-privileges:true]`
  / `--security-opt no-new-privileges` prevents a setuid or file-cap
  binary from raising privileges.
- **Read-only root filesystem.** `read_only: true` / `--read-only`.
  Writable state is confined to explicit `tmpfs` mounts (`/tmp`,
  `/home/dev/.cache`, `/home/dev/.local/state`), which are wiped when
  the container exits.
- **Resource caps.** `pids_limit` and `mem_limit` (`--pids-limit`,
  `--memory`) bound fork-bomb and memory-exhaustion blast radius.
- **Minimal mounts.** The only bind mount is the project directory at
  `/work`. There is no Docker socket mount and no host-path assumption.

### Pinned and checksummed inputs

- **Base image pinned by digest** — not by a floating tag — so a rebuild
  resolves to the same bytes.
- **OS packages pinned** to explicit versions.
- **Downloaded binaries are checksum-verified.** There is no `curl | sh`
  anywhere in the build; every fetched artifact is validated against a
  known hash before use.
- **Language dependencies install from hash-pinned lockfiles** (for
  example `Cargo.lock`, `uv.lock`), so the dependency closure is
  reproducible.
- **Neovim plugins pinned** via `lazy-lock.json` and baked headless at
  build time — the container needs no network on first launch.
- Pin `DOTFILES_REF` to a tag or commit for a byte-reproducible build.

### No committed or baked-in secrets

- No `.env` is committed to git or `COPY`'d into an image. Secrets are
  runtime-only, supplied via compose `env_file` / `--env-file`.
- `.dockerignore` keeps `.env` out of the build context; `.gitignore`
  keeps it out of history. `env.example` carries placeholders only.

### Supply-chain integrity

- **CI gates every change.** `hadolint` lints the `Containerfile`,
  `shellcheck` lints the scripts, and a **Trivy** image scan fails the
  build on HIGH/CRITICAL findings — on every push and pull request.
- **SBOM on release.** A CycloneDX SBOM (`syft`) is generated so
  downstream consumers can reproduce and audit the image's contents.
- **GitHub Actions pinned.** Workflow actions are pinned so the CI
  supply chain is itself reproducible.
- **Signed commits.** All commits on `main` are signed; CI rejects
  unsigned pull-request commits.

## Verifying an image

```sh
# Confirm the container is non-root and read-only:
docker run --rm langdev:local id            # uid=1000(dev) gid=1000(dev)

# Re-run the vulnerability scan locally:
make scan                                    # fails on HIGH/CRITICAL

# Generate and inspect the SBOM:
make sbom && jq '.components | length' sbom.cdx.json
```
