<!-- SPDX-License-Identifier: Apache-2.0 OR MIT -->

# Changelog

All notable changes to this project are documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
This project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.0.2] - 2026-08-29

### Added

- **Remote & Mobile Web Access.**
  - `make web` and `make web-auth` targets using `ttyd` for browser-based access on iPads and mobile devices over WebSocket/SSL.
  - `make mosh` for UDP-based roaming mobile shell sessions that survive connection drops.
- **Diagnostic CLI (`make doctor`).**
  - Added `common/doctor.sh` to probe host engines, architecture, cgroups, kernel security, and clipboard readiness.
- **Universal Clipboard (OSC 52).**
  - Added `set -s set-clipboard on` in `common/tmux.conf` for seamless copy-paste to host/mobile clipboards.
- **TUI Popups.**
  - Added floating TMUX popups for Lazygit (`Prefix + g`) and Lazydocker (`Prefix + d`).
- **VS Code IDE Grid & Parallel Task Worktrees.**
  - Added `common/tmux-ide.sh` (`Prefix + i`) and `common/muxtree.sh` (`Prefix + m`).

## [0.0.1] - 2026-08-29

`rustdev` is a member of the [`langdev`](https://github.com/sebastienrousseau/langdev)
suite: a complete, batteries-included Rust toolchain inside a
portable, disposable container that builds with **both** Docker and
Podman and boots the developer's own chezmoi-managed dotfiles.

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
