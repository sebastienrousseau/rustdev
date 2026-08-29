<!-- SPDX-License-Identifier: Apache-2.0 OR MIT -->

# Changelog

All notable changes to this project are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

`rustdev` — a hardened, disposable Rust development container built on
the [`langdev`](https://github.com/sebastienrousseau/langdev) core. It
adds a pinned, checksum-verified Rust toolchain and a single Neovim LSP
drop-in on top of the shared, hardened base; the developer environment
is the user's own chezmoi-managed dotfiles (shell, aliases, tmux, and
Neovim), cloned and applied at build time.

### Added

- **Rust toolchain, pinned and checksum-verified.** A separate
  `toolchain` build stage installs `rustup` (`rustup-init` sha256-
  verified for musl amd64 + arm64) and the pinned stable toolchain with
  the `rust-analyzer`, `rust-src`, and `clippy` components, plus
  `cargo-audit` and `cargo-watch` (`cargo install --locked --version`).
  Only the relocatable prefix (`/opt/langdev/toolchain`) is copied into
  the runtime image — no build tools leak in.
- **Dotfiles + tmux as the environment.** The image clones and
  `chezmoi apply`s the user's dotfiles at build time (latest by default;
  pin with `DOTFILES_REF`). tmux is loaded by default — the entrypoint
  attaches to (or creates) a persistent `langdev` session
  (`LANGDEV_NO_TMUX=1` opts out).
- **Neovim LSP wiring via `rustaceanvim`.** A single
  `nvim/plugins.local/lang.lua` spec wires `mrcjkb/rustaceanvim` (the
  maintained successor to `rust-tools.nvim`) to the build-time
  `rust-analyzer` on `PATH` — no Mason, no network on first launch.
  Treesitter grammars `rust` and `ron` are added on top of the user's
  set; the full plugin set is baked headless at build time.
- **Rust login-shell environment.** `dotfiles.d/rust.sh`, installed to
  `/etc/profile.d/rust.sh` (root-owned, `0644`), exports `CARGO_HOME` /
  `RUSTUP_HOME`, prepends `$CARGO_HOME/bin` to `PATH` (duplicate-guarded,
  safe to re-source), and adds cargo aliases — kept out of the user's
  pristine dotfiles.
- **Hardened, disposable runtime.** Non-root `dev` (UID/GID 1000),
  `cap_drop: [ALL]`, `no-new-privileges`, read-only root filesystem with
  `tmpfs` for writable state, `pids_limit` / `mem_limit` / `cpus`; the
  only bind mount is the project at `/work`. Base image pinned by digest.
- **`make` lifecycle and CI.** `build`, `buildx` (multi-arch:
  `linux/amd64`, `linux/arm64`), `up`/`shell`, `run`, `lint`, `scan`,
  `sbom`, `trash`, and `sync-common`; CI gates every change with
  `hadolint`, `shellcheck`, a Docker build, a Trivy scan (fail on
  HIGH/CRITICAL), and a CycloneDX SBOM artifact.

### Licensing

- Dual-licensed **`Apache-2.0 OR MIT`**. Added `LICENSE-APACHE` and
  `LICENSE-MIT`, removed the single `LICENSE` file, and applied
  `SPDX-License-Identifier: Apache-2.0 OR MIT` headers across the repo.

[Unreleased]: https://github.com/sebastienrousseau/rustdev/commits/main
