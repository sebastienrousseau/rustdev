<!-- SPDX-License-Identifier: Apache-2.0 OR MIT -->

<p align="center">
  <img src="assets/logo.svg" alt="rustdev logo" width="140" />
</p>

<h1 align="center">rustdev</h1>

<p align="center">
  Portable, hardened Rust 1.85+ toolchain development container with TMUX IDE,
  Model Context Protocol (MCP) AI agent tooling, rust-analyzer, clippy, cargo-audit, mobile WebTTY, and dotfiles bootstrap.
</p>

<p align="center">
  <a href="https://github.com/sebastienrousseau/rustdev/actions/workflows/ci.yml"><img src="https://img.shields.io/github/actions/workflow/status/sebastienrousseau/rustdev/ci.yml?style=for-the-badge&logo=github" alt="Build" /></a>
  <a href="#license"><img src="https://img.shields.io/badge/license-Apache--2.0%20OR%20MIT-blue?style=for-the-badge" alt="License: Apache-2.0 OR MIT" /></a>
  <a href="https://scorecard.dev/viewer/?uri=github.com/sebastienrousseau/rustdev"><img src="https://img.shields.io/ossf-scorecard/github.com/sebastienrousseau/rustdev?style=for-the-badge&label=OpenSSF%20Scorecard&logo=openssf" alt="OpenSSF Scorecard" /></a>
  <a href="#portability"><img src="https://img.shields.io/badge/engines-docker%20%7C%20podman-1d63ed?style=for-the-badge&logo=docker" alt="Engines: Docker or Podman" /></a>
  <a href="#portability"><img src="https://img.shields.io/badge/arch-amd64%20%C2%B7%20arm64-555?style=for-the-badge" alt="Architectures: amd64, arm64" /></a>
</p>

---

## Contents

- [Quick start](#quick-start)
- [The suite](#the-suite)
- [2026 Developer & AI Capabilities](#2026-developer--ai-capabilities)
- [Architecture & Design](#architecture--design)
- [Security Model](#security-model)
- [Portability](#portability)
- [Development & Lifecycle](#development--lifecycle)
- [Documentation](#documentation)
- [License](#license)

---

## Quick start

Clone this repository and spin up a complete, hardened Rust terminal IDE in seconds:

```sh
git clone https://github.com/sebastienrousseau/rustdev.git
cd rustdev
make up          # builds the image and launches the 4-pane TMUX IDE
```

### Remote & Mobile Web Access

Access your development environment from any iPad, tablet, or web browser:

```sh
make web         # starts dark-themed WebTTY at http://localhost:7681
make web-auth    # starts WebTTY with password authentication
make mosh        # starts roaming UDP shell that survives cellular IP handovers
make doctor      # runs system diagnostics (container engine, tools, linters, clipboard)
```

When you are done:

```sh
make trash       # removes container image and build cache cleanly
```

---

## The suite

`rustdev` is the Rust member of the [`langdev`](https://github.com/sebastienrousseau/langdev) suite:

| Repository | Language Stack | Built-In Tooling | Status |
|---|---|---|:---:|
| [**`langdev`**](https://github.com/sebastienrousseau/langdev) | Core Foundation | Hardened runtime, TMUX IDE, MCP server, `ai-pack`, WebTTY | `v0.0.4` |
| [**`pythondev`**](https://github.com/sebastienrousseau/pythondev) | Python 3.12+ | `uv`, `ruff`, `mypy`, `pytest`, `debugpy`, Pyright | `v0.0.4` |
| [**`rustdev`**](https://github.com/sebastienrousseau/rustdev) | Rust 1.85+ | `rustup`, `rust-analyzer`, `clippy`, `cargo-audit`, `sccache` | `v0.0.4` |
| [**`godev`**](https://github.com/sebastienrousseau/godev) | Go 1.24+ | `gopls`, `golangci-lint`, `delve`, Go toolchain | `v0.0.4` |
| [**`javadev`**](https://github.com/sebastienrousseau/javadev) | Java 21+ | OpenJDK 21, Maven, Gradle, JDTLS | `v0.0.4` |
| [**`kotlindev`**](https://github.com/sebastienrousseau/kotlindev) | Kotlin 2.1+ | `kotlinc`, OpenJDK 21, Gradle, Maven, KLS | `v0.0.1` |
| [**`swiftdev`**](https://github.com/sebastienrousseau/swiftdev) | Swift 6.0+ | Swift toolchain, SourceKit-LSP, `swift-format` | `v0.0.4` |

---

## 2026 Developer & AI Capabilities

Every container in the suite includes native, pre-configured tooling for modern AI-assisted engineering:

### 1. 4-Pane TMUX IDE (`Prefix + i`)
- **Left Panel (20% W)**: Intelligent project explorer (`langdev-explorer`, `yazi`) with visual Git branch status.
- **Center-Top (56% W, 70% H)**: Editor pane loaded with Neovim and `rust-analyzer`.
- **Center-Bottom (56% W, 30% H)**: Integrated bash terminal with Cargo toolchain on PATH.
- **Right Panel (24% W)**: Dedicated AI Agent terminal (Claude Code, Agy, Aider, Ollama).

### 2. Parallel AI Task Worktrees (`muxtree` / `Prefix + m`)
- Automates Git worktrees paired with dedicated TMUX sessions (`muxtree new <branch>`, `muxtree list`, `muxtree switch`).
- Allows human developers and autonomous AI agents to work on separate features concurrently in isolated branches without workspace collisions.

### 3. Model Context Protocol (MCP) Server (`/usr/local/bin/mcp-server`)
- Standard JSON-RPC 2.0 stdio MCP server exposing container workspace tools (`list_files`, `read_file`, `git_status`, `git_diff`, `run_tests`, `run_command`).
- Pre-configured `common/mcp.json` configuration template for Claude Code, Cursor, and Aider.

### 4. AI Context Packing (`ai-pack`)
- High-speed repository context bundler formatting source code into token-efficient XML or Markdown for LLM prompt injection (`ai-pack --format markdown -o context.md`).

### 5. Universal Clipboard (OSC 52)
- Seamless copy-paste synchronization across container, host macOS/Linux/Windows, SSH sessions, and mobile Safari.

### 6. Floating TUI Modals
- **`Prefix + g`**: Instant floating Lazygit modal popup.
- **`Prefix + d`**: Instant floating Lazydocker process monitor popup.

---

## Architecture & Design

1. **The Developer Environment IS Your Dotfiles**:
   At build time, each image clones your chezmoi-managed dotfiles repository and applies your personalized shell, prompt, and editor configurations. No synthetic configurations.
2. **Vendored Core (`common/`)**:
   Shared runtime logic is vendored into each repository under `common/` and synchronized using `bin/langdev-sync`. Every repository is 100% standalone and buildable.

---

## Security Model

Every container adheres to strict security defaults documented in [`SECURITY.md`](SECURITY.md):
- **Unprivileged Execution**: Runs as non-root `dev` user (UID/GID 1000).
- **Capability Dropping**: `cap_drop: [ALL]` with `no-new-privileges:true`.
- **Read-Only Root Filesystem**: Immutability enforced; temporary writes isolated to explicit `tmpfs` mounts.
- **Supply-Chain Integrity**: Base images pinned by cryptographic digest, inputs checksum-verified, no unpinned `curl | sh`.

---

## Portability

- **Single OCI `Containerfile`**: Builds identically under Docker, Podman, Buildah, and nerdctl.
- **Engine Autodetection**: `Makefile` auto-detects Docker or Podman and configures flags (SELinux `:Z`, user namespaces) automatically.
- **Multi-Architecture**: Multi-arch builds for `linux/amd64` and `linux/arm64`.

---

## Development & Lifecycle

```sh
make up          # build + interactive dev shell (alias: make shell)
make web         # launch WebTTY browser IDE on port 7681
make mosh        # launch UDP roaming mosh session
make doctor      # run container & system diagnostic healthcheck
make test        # run hermetic Bats unit test suite
make coverage    # run unit tests with kcov coverage gate (>=95%)
make lint        # run shellcheck on scripts + hadolint on Containerfiles
make scan        # run Trivy vulnerability scanner
make sbom        # generate CycloneDX software bill of materials
make trash       # purge local image and cache
```

---

## Documentation

| Document | Description |
|---|---|
| [`STYLE.md`](STYLE.md) | House style, standards, and conventions across repositories. |
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | Contribution guidelines, testing standards, signed commits. |
| [`SECURITY.md`](SECURITY.md) | Vulnerability disclosure policy and threat model. |
| [`GOVERNANCE.md`](GOVERNANCE.md) | Maintainer governance and decision-making model. |
| [`SUPPORT.md`](SUPPORT.md) | Getting help, opening issues, and discussions. |
| [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md) | Contributor covenant code of conduct. |
| [`CHANGELOG.md`](CHANGELOG.md) | Version releases and change history. |

---

## License

Licensed under either of:
- Apache License, Version 2.0 ([`LICENSE-APACHE`](LICENSE-APACHE))
- MIT license ([`LICENSE-MIT`](LICENSE-MIT))

at your option. Dual-licensed `Apache-2.0 OR MIT`.
