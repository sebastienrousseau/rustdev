<!-- SPDX-License-Identifier: Apache-2.0 OR MIT -->

<p align="center">
  <img src="https://cloudcdn.pro/rustdev/v1/logos/rustdev.svg" alt="rustdev logo" width="128" />
</p>

<h1 align="center">rustdev</h1>

<p align="center">
  A portable, disposable Rust development container — a pinned rustup
  toolchain on the hardened <a href="https://github.com/sebastienrousseau/langdev">langdev</a>
  core that builds with <b>both</b> Docker and Podman and boots the
  developer's own dotfiles.
</p>

<p align="center">
  <a href="https://github.com/sebastienrousseau/rustdev/actions"><img src="https://img.shields.io/github/actions/workflow/status/sebastienrousseau/rustdev/ci.yml?style=for-the-badge&logo=github" alt="Build" /></a>
  <a href="#license"><img src="https://img.shields.io/badge/license-Apache--2.0%20OR%20MIT-blue?style=for-the-badge" alt="License: Apache-2.0 OR MIT" /></a>
  <a href="https://scorecard.dev/viewer/?uri=github.com/sebastienrousseau/rustdev"><img src="https://img.shields.io/ossf-scorecard/github.com/sebastienrousseau/rustdev?style=for-the-badge&label=OpenSSF%20Scorecard&logo=openssf" alt="OpenSSF Scorecard" /></a>
  <a href="#portability"><img src="https://img.shields.io/badge/engines-docker%20%7C%20podman-1d63ed?style=for-the-badge&logo=docker" alt="Engines: Docker or Podman" /></a>
  <a href="#portability"><img src="https://img.shields.io/badge/arch-amd64%20%C2%B7%20arm64-555?style=for-the-badge" alt="Architectures: amd64, arm64" /></a>
</p>

---

## Contents

**Getting started**

- [Quick start](#quick-start) — `make up`, and you are in a dev shell
- [Why this approach?](#why-this-approach) — the four choices that shape the image

**What you get**

- [What's inside](#whats-inside) — the pinned Rust toolchain, exactly
- [The developer environment IS your dotfiles](#the-developer-environment-is-your-dotfiles) — no synthetic config, tmux loaded by default

**Operational**

- [Security model](#security-model) — the container threat model and controls
- [Portability](#portability) — engines, architectures, host assumptions
- [When not to use rustdev](#when-not-to-use-rustdev) — limitations, stated plainly
- [Development](#development) — `make` targets, lint, scan, SBOM, CI
- [Documentation](#documentation) — community docs and the house style
- [License](#license)

---

## Quick start

`rustdev` is standalone. Clone it, and one command gets you an
interactive, hardened Rust shell in a fresh container:

```sh
git clone https://github.com/sebastienrousseau/rustdev.git
cd rustdev
make up                       # build (if needed) + interactive dev shell
```

Other everyday commands:

```sh
make run CMD="cargo test"     # one-shot command in a fresh container
make trash                    # remove the image + dangling build cache
```

Your code is the **only** bind mount, at `/work`. Everything else is
ephemeral (read-only rootfs + tmpfs), so a container is truly
disposable. No registry pull and no network are needed on first launch —
the image is built entirely from the repo you cloned, and the Neovim
plugin set is baked headless at build time.

---

## Why this approach?

Most "Rust dev container" setups make one of two trades: a heavyweight,
root-running image with the kitchen sink, or a bare `rust:alpine` that
leaves you to reassemble your editor, shell, and tools every time.
rustdev refuses both. Four choices, in priority order, shape the image:

1. **Secure by default, not by opt-in.** The container runs as a
   non-root `dev` user (UID/GID 1000) with **all Linux capabilities
   dropped**, `no-new-privileges`, and a **read-only root filesystem**;
   writable state is confined to explicit `tmpfs` mounts. This is the
   default `make up` posture, not a hardened variant you must remember
   to select. The threat model is [documented](SECURITY.md), not
   implied.

2. **Ultra-small but complete.** A multi-stage build installs the Rust
   toolchain into a relocatable prefix and copies **only** that prefix
   into the runtime image — `build-base` and `curl` never reach the
   final layer. "Complete" is measured against a real Rust workflow:
   you can edit, build, test, lint, and audit without reaching outside
   the container.

3. **Portable and disposable.** One OCI `Containerfile` builds with
   Docker, Podman, Buildah, and nerdctl. The `Makefile` auto-detects the
   engine and adjusts flags (SELinux `:Z` mounts) accordingly. Images
   are multi-arch (`linux/amd64`, `linux/arm64`). The only bind mount is
   your project at `/work`, and `make trash` leaves nothing behind.

4. **Reliable and reproducible.** Everything is pinned: the Alpine base
   **by digest**, the Rust toolchain and cargo tools by version, and
   Neovim plugins via the dotfiles' `lazy-lock.json`. `rustup-init` is
   **checksum-verified** (musl amd64 + arm64) — there is no `curl | sh`
   anywhere in the build. Pin `DOTFILES_REF` to a tag or commit and the
   image is reproducible; the exact dotfiles commit bundled is recorded
   at `~/.dotfiles.commit`.

---

## What's inside

Everything is pinned. Bump the toolchain inputs together (see the build
args at the top of the `Containerfile`).

| Component | Version | How it's pinned |
|---|---|---|
| Alpine base | `3.22` | by digest `sha256:14358309…695dce` |
| Rust (stable) | `1.98.0` | `RUST_VERSION` build arg |
| rustup | `1.29.0` | `RUSTUP_VERSION`; `rustup-init` sha256-verified (musl amd64 + arm64) |
| `cargo-audit` | `0.22.2` | `cargo install --locked --version` |
| `cargo-watch` | `8.5.3` | `cargo install --locked --version` |
| rust-analyzer / clippy / rust-src | (with `1.98.0`) | rustup components |
| Dotfiles (shell/tmux/nvim) | latest | `DOTFILES_REF` build arg (pin a tag/commit) |
| Neovim plugins | — | your dotfiles' `nvim/lazy-lock.json` (baked headless at build) |

The toolchain is built in a separate `toolchain` stage; only its
relocatable prefix (`/opt/langdev/toolchain`) is copied into the final
image, so `build-base` and `curl` never reach the runtime layer.
`rust-analyzer`, `cargo`, `clippy`, `cargo-audit`, and `cargo-watch` are
all on `PATH`.

Rust-specific login-shell setup lives in `dotfiles.d/rust.sh`, installed
to `/etc/profile.d/rust.sh` (root-owned, `0644`) so every login shell
sources it without touching your pristine dotfiles. It exports
`CARGO_HOME` and `RUSTUP_HOME`, prepends `$CARGO_HOME/bin` to `PATH`
(guarding against duplicates so it is safe to re-source), and adds these
aliases — **only** for tools actually present in the image:

| Alias | Expands to |
|---|---|
| `cb` | `cargo build` |
| `cr` | `cargo run` |
| `ct` | `cargo test` |
| `cc` | `cargo check` |
| `ccl` | `cargo clippy --all-targets --all-features` |
| `cw` | `cargo watch -x check` |
| `caudit` | `cargo audit` |

It does **not** propagate any host `PATH`.

---

## The developer environment IS your dotfiles

rustdev does **not** ship a synthetic shell or editor config. At build
time the image clones the user's chezmoi-managed
[dotfiles repo](https://github.com/sebastienrousseau/dotfiles) and runs
`chezmoi apply`, so the container has the *real* bashrc, aliases, tmux
config, and Neovim setup — **always the latest** by default. Pin
`DOTFILES_REF` to a tag or commit for a reproducible build; the exact
commit bundled is recorded at `~/.dotfiles.commit`.

- **tmux is installed and loaded by default.** An interactive shell
  attaches to (or creates) a persistent `langdev` tmux session, so panes
  and windows survive detach. Opt out with `LANGDEV_NO_TMUX=1`.
- **The dotfiles' Neovim config is authoritative.** rustdev makes
  exactly one addition: `nvim/plugins.local/lang.lua` is dropped into
  the config at `~/.config/nvim/lua/plugins.local/` (the dotfiles'
  auto-imported local-override convention). It is an ordinary lazy.nvim
  spec, so it composes with the rest of your setup untouched.
- **LSP via `rustaceanvim`.** Rust is wired through
  `mrcjkb/rustaceanvim` (the maintained successor to the archived
  `rust-tools.nvim`), pointed at the build-time `rust-analyzer` on
  `PATH` — no Mason, no network on first launch. Treesitter grammars
  `rust` and `ron` are added on top of your set.
- **Baked, offline-ready.** The full plugin set (yours plus this spec)
  is baked headless at build time from your dotfiles'
  `nvim/lazy-lock.json`, so the container is reproducible and needs no
  network on first launch.

---

## Security model

The full threat model and the private disclosure process are in
[`SECURITY.md`](SECURITY.md). Enforced by `compose.yaml` and mirrored in
`make run` / `make shell`:

- **Non-root.** Runs as `dev` (UID/GID 1000); no `sudo`, no setuid
  binaries in the image (setuid/setgid bits stripped at build; `/tmp` is
  `1777`, sticky — not `777`).
- **Least privilege at runtime.** `cap_drop: [ALL]`,
  `security_opt: [no-new-privileges:true]`, `read_only: true` (with
  `tmpfs` for `/tmp`, `/home/dev/.cache`, and `/home/dev/.local/state`),
  and `init: true` (tini as PID 1 for clean signal handling).
- **Resource limits.** `pids_limit: 512`, `mem_limit: 2g`, `cpus: 2.0`.
- **Pinned, checksummed inputs.** Base image pinned **by digest**;
  `rustup-init` checksum-verified; cargo tools installed `--locked` and
  version-pinned — never `curl | sh`.
- **One bind mount.** The only bind mount is your project directory at
  `/work`.
- **No committed secrets.** No `.env` is committed or `COPY`'d into an
  image — secrets are runtime-only via compose `env_file`. `.env` is
  gitignored **and** dockerignored. rustdev needs no secrets to build or
  run.
- **CI gates every change.** `hadolint`, `shellcheck`, a Docker build,
  and a Trivy image scan (fail on HIGH/CRITICAL) run on every push and
  pull request; a CycloneDX SBOM is uploaded as an artifact.

Report a vulnerability privately — see [`SECURITY.md`](SECURITY.md). Do
not open a public issue.

---

## Portability

- **One `Containerfile` (OCI).** `docker build`, `podman build`,
  `buildah`, and `nerdctl` all work from the same file.
- **Engine autodetection.** The `Makefile` detects `docker` or `podman`
  and adjusts flags (SELinux `:Z` mounts) accordingly.
- **Multi-arch.** Images build for `linux/amd64` and `linux/arm64` via
  `docker buildx` / `podman --platform`.
- **No host assumptions.** The only bind mount is your project directory
  at `/work`; there are no host-path assumptions beyond it.

---

## When not to use rustdev

Stated plainly, so you can rule it out fast:

- **You need a production runtime image.** rustdev builds a *development*
  environment — editor, LSP, test and audit tooling, a shell. It is
  deliberately not a minimal production artifact; ship a separate,
  slimmer image (or a `FROM scratch` static binary) for that.
- **You do not use chezmoi-managed dotfiles.** The environment *is* the
  user's dotfiles. Without a chezmoi dotfiles repo you lose the main
  point, though the hardening and Rust toolchain layers still stand on
  their own.
- **You need a nightly toolchain or extra targets by default.** rustdev
  ships one pinned stable toolchain with a minimal component set. Extra
  targets, components, or a nightly channel are deliberate additions,
  not the default.
- **You need GPU passthrough or host-device access.** The default
  posture drops all capabilities and forbids privilege escalation.
  Workloads that need device access require deliberate, documented
  relaxations that run against the grain of the design.
- **You are on a platform without Docker or Podman.** There is no
  VM-less fallback; rustdev targets an OCI engine on Linux, macOS, or
  Windows/WSL2.

---

## Development

The `Makefile` exposes the full lifecycle and auto-detects `docker` or
`podman` (adding `:Z` SELinux mount flags for Podman), so the same
commands work with either engine:

```sh
make up          # build + interactive dev shell (alias: make shell)
make run CMD=…   # one-shot command in a fresh container
make build       # build the image for the host arch
make buildx      # multi-arch build (linux/amd64, linux/arm64)
make lint        # hadolint the Containerfile + shellcheck the scripts
make scan        # Trivy vulnerability scan (fail on HIGH/CRITICAL)
make sbom        # CycloneDX SBOM via syft
make trash       # remove the image and dangling build cache
make sync-common # refresh common/ from the langdev source
```

CI (`.github/workflows/ci.yml`) runs the lint and build/scan jobs on
every push and pull request, uploading a CycloneDX SBOM artifact.
Contributions require signed commits and Conventional Commit messages —
see [`CONTRIBUTING.md`](CONTRIBUTING.md).

---

## Documentation

| Document | What it covers |
|---|---|
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | The container workflow: build/lint/scan/sbom, signed commits, Conventional Commits. |
| [`SECURITY.md`](SECURITY.md) | The container threat model and the private disclosure process. |
| [`GOVERNANCE.md`](GOVERNANCE.md) | Who decides what, and how the maintainer base is meant to grow. |
| [`SUPPORT.md`](SUPPORT.md) | Where to go for questions, bugs, and feature requests. |
| [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md) | Community standards and enforcement. |
| [`CHANGELOG.md`](CHANGELOG.md) | Notable changes, Keep a Changelog format. |

rustdev follows the langdev suite's house style — see
[`STYLE.md`](https://github.com/sebastienrousseau/langdev/blob/main/STYLE.md)
in the `langdev` repo.

---

## License

Licensed under either of

- Apache License, Version 2.0 ([`LICENSE-APACHE`](LICENSE-APACHE))
- MIT license ([`LICENSE-MIT`](LICENSE-MIT))

at your option. The suite is dual-licensed `Apache-2.0 OR MIT`; every
file carries an `SPDX-License-Identifier: Apache-2.0 OR MIT` header.

Unless you explicitly state otherwise, any contribution intentionally
submitted for inclusion in the work by you, as defined in the Apache-2.0
license, shall be dual licensed as above, without any additional terms
or conditions.
