<!-- SPDX-License-Identifier: MIT -->

# rustdev — portable, disposable Rust development environment

`rustdev` is a member of the [`langdev`](../../dockerfile/langdev) suite:
a complete, batteries-included Rust toolchain inside a container you can
**spin up and throw away in seconds** — on any machine with Docker or
Podman (Linux, macOS, Windows/WSL2).

It ships a pinned rustup toolchain (rustc, cargo, clippy, rust-analyzer,
rust-src) plus `cargo-audit` and `cargo-watch`. The developer environment
— shell, aliases, tmux, and Neovim — is **your own
[chezmoi-managed dotfiles](https://github.com/sebastienrousseau/dotfiles)**,
cloned and applied at build time (latest by default; pin with the
`DOTFILES_REF` build arg). rustdev adds just one thing to that editor: a
`nvim/plugins.local/lang.lua` spec that wires the LSP to the build-time
`rust-analyzer`. No network is needed on first launch.

**tmux is loaded by default** — an interactive shell attaches to (or
creates) a persistent `langdev` tmux session so panes survive detach. Opt
out with `LANGDEV_NO_TMUX=1`.

## Quick start

```sh
make up            # build (if needed) + drop into an interactive dev shell
make run CMD="cargo test"   # one-shot command in a fresh container
make trash         # remove the image + dangling build cache
```

Your code is the **only** bind mount, at `/work`. Everything else is
ephemeral (read-only rootfs + tmpfs), so a container is truly disposable.

## What's inside (pinned)

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

The toolchain is built in a separate `toolchain` stage and only its
relocatable prefix (`/opt/langdev/toolchain`) is copied into the final
image — build tools (`build-base`, `curl`) never reach the runtime layer.

> **Reproducible dotfiles:** by default the build clones the latest
> dotfiles (`DOTFILES_REF=main`). For a byte-reproducible image, pass a
> tag or commit: `--build-arg DOTFILES_REF=<sha>`. The exact commit
> bundled is recorded in the image at `~/.dotfiles.commit`.

## Make targets

| Target | Description |
|---|---|
| `make up` / `make shell` | Build then start an interactive dev shell |
| `make run CMD="…"` | Run a one-shot command in a fresh container |
| `make build` | Build the image for the host arch |
| `make buildx` | Build a multi-arch image (`linux/amd64,linux/arm64`) |
| `make trash` | Remove the image and dangling build cache |
| `make lint` | `hadolint` the Containerfile + `shellcheck` the scripts |
| `make scan` | Trivy vulnerability scan (HIGH/CRITICAL) of the built image |
| `make sbom` | Generate a CycloneDX SBOM (`sbom.cdx.json`) via syft |
| `make sync-common` | Refresh `common/` from the langdev source |

The `Makefile` auto-detects `docker` or `podman` (adding `:Z` SELinux
mount flags for Podman) so the same commands work with either engine.

## Aliases

General shell aliases come from **your own dotfiles** (whatever your
`bashrc`/`aliases` define). The Rust-specific aliases below are added by
`dotfiles.d/rust.sh`, installed to `/etc/profile.d/rust.sh` (root-owned,
`0644`) so it is sourced by every login shell without touching your
pristine dotfiles.

### Rust (`/etc/profile.d/rust.sh`)

| Alias | Expands to |
|---|---|
| `cb` | `cargo build` |
| `cr` | `cargo run` |
| `ct` | `cargo test` |
| `cc` | `cargo check` |
| `ccl` | `cargo clippy --all-targets --all-features` |
| `cw` | `cargo watch -x check` |
| `caudit` | `cargo audit` |

`/etc/profile.d/rust.sh` also exports `CARGO_HOME`, `RUSTUP_HOME` and
prepends `$CARGO_HOME/bin` to `PATH` (guarding against duplicate entries so
it's safe to re-source). It does **not** propagate any host `PATH`.

## Neovim

The Neovim config is **your own dotfiles' nvim** — applied by chezmoi at
build time and authoritative. rustdev makes exactly one addition:

- **LSP wiring via `plugins.local`.** `nvim/plugins.local/lang.lua` is
  dropped into your config at `~/.config/nvim/lua/plugins.local/` (the
  dotfiles' auto-imported local-override convention). It's an ordinary
  lazy.nvim spec, so it composes with the rest of your setup untouched.
- Rust is configured via `mrcjkb/rustaceanvim` (the maintained successor
  to the archived `rust-tools.nvim`), pointed at the pre-installed
  `rust-analyzer` on `PATH` — no Mason, no network on first launch.
- Treesitter grammars `rust` and `ron` are added on top of your set.
- The full plugin set (yours + this spec) is baked headless at build time
  from your dotfiles' `nvim/lazy-lock.json`, so the container is
  reproducible and offline-ready on first launch.

## Security posture

Enforced by `compose.yaml` (and mirrored in `make run`/`make shell`):

- Runs as non-root `dev` (UID/GID `1000`); no `sudo`, no setuid binaries
  (setuid/setgid bits stripped at build; `/tmp` is `1777`, sticky — not `777`).
- `read_only: true` root filesystem, with tmpfs for `/tmp`,
  `/home/dev/.cache`, `/home/dev/.local/state`.
- `cap_drop: [ALL]`, `security_opt: [no-new-privileges:true]`, `init: true`.
- Resource limits: `pids_limit: 512`, `mem_limit: 2g`, `cpus: 2.0`.
- The **only** bind mount is your project directory at `/work`.
- Base image pinned by digest; `rustup-init` checksum-verified; cargo
  tools `--locked` and version-pinned.
- No `.env` is committed or `COPY`'d into an image — secrets are
  runtime-only via compose `env_file`. `.env` is gitignored **and**
  dockerignored. `rustdev` needs no secrets to build or run.

## Portability

One OCI `Containerfile` builds with `docker build`, `podman build`,
`buildah`, or `nerdctl`, for `linux/amd64` and `linux/arm64`. No host-path
assumptions beyond the `/work` bind mount.

## CI

`.github/workflows/ci.yml` gates every change with `hadolint`,
`shellcheck`, a Docker build, a Trivy scan (fails on HIGH/CRITICAL), and
uploads a CycloneDX SBOM artifact.

## License

MIT — see [`LICENSE`](LICENSE).
