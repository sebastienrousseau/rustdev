# syntax=docker/dockerfile:1.9
# rustdev Containerfile — OCI, builds with Docker AND Podman.
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
# Multi-stage, hardened, ultra-small Rust dev image built on the langdev
# foundation. The developer environment (shell, editor, tmux) is the USER'S
# OWN chezmoi-managed dotfiles, cloned + applied at build time (latest by
# default; pin with DOTFILES_REF). langdev provides only the hardened base +
# the Rust toolchain + a single nvim/plugins.local/lang.lua LSP drop-in.
#
# Pin the base by DIGEST. Update via `make bump-base` (looks up the current
# digest for the tag and rewrites the two lines below).
ARG ALPINE_VERSION=3.22
# renovate: datasource=docker depName=alpine
ARG ALPINE_DIGEST=sha256:14358309a308569c32bdc37e2e0e9694be33a9d99e68afb0f5ff33cc1f695dce

ARG USERNAME=dev
ARG USER_UID=1000
ARG USER_GID=1000

# Dotfiles source — "always the latest" by default; pin a tag/commit for
# reproducible builds.
ARG DOTFILES_REPO=https://github.com/sebastienrousseau/dotfiles.git
ARG DOTFILES_REF=main

###############################################################################
# Stage: toolchain  (LANGUAGE-SPECIFIC — Rust via rustup, minimal profile)
#   Installs a checksum-verified rustup + the pinned stable toolchain with the
#   rust-analyzer / rust-src / clippy components, plus the cargo tools we ship.
#   Everything lands under a single relocatable prefix (/opt/langdev/toolchain)
#   that the final stage copies in — no build tools leak into the runtime image.
###############################################################################
FROM alpine:${ALPINE_VERSION}@${ALPINE_DIGEST} AS toolchain

# Pinned, checksum-verified toolchain inputs. Bump together (see README).
ARG RUST_VERSION=1.98.0
ARG RUSTUP_VERSION=1.29.0
ARG CARGO_AUDIT_VERSION=0.22.2
ARG CARGO_WATCH_VERSION=8.5.3

# Relocatable prefix: CARGO_HOME + RUSTUP_HOME live side by side so the final
# stage can COPY the whole tree and get a working toolchain on PATH.
ENV RUSTUP_HOME=/opt/langdev/toolchain/rustup \
    CARGO_HOME=/opt/langdev/toolchain/cargo \
    PATH=/opt/langdev/toolchain/cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Build-only packages (curl to fetch rustup, build-base to compile crates).
# These stay in the toolchain stage and never reach the runtime image.
# hadolint ignore=DL3018
RUN apk add --no-cache \
      bash \
      ca-certificates \
      curl \
      build-base \
 && update-ca-certificates

# Install rustup with a verified checksum (no `curl | sh`), then the pinned
# stable toolchain with the LSP + clippy + source components.
RUN set -eux; \
    apkArch="$(apk --print-arch)"; \
    case "$apkArch" in \
      x86_64)  rustArch='x86_64-unknown-linux-musl'; \
               rustupSha256='9cd3fda5fd293890e36ab271af6a786ee22084b5f6c2b83fd8323cec6f0992c1' ;; \
      aarch64) rustArch='aarch64-unknown-linux-musl'; \
               rustupSha256='88761caacddb92cd79b0b1f939f3990ba1997d701a38b3e8dd6746a562f2a759' ;; \
      *) echo >&2 "unsupported architecture: $apkArch"; exit 1 ;; \
    esac; \
    url="https://static.rust-lang.org/rustup/archive/${RUSTUP_VERSION}/${rustArch}/rustup-init"; \
    curl -fsSL "$url" -o /tmp/rustup-init; \
    echo "${rustupSha256}  /tmp/rustup-init" | sha256sum -c -; \
    chmod +x /tmp/rustup-init; \
    /tmp/rustup-init -y --no-modify-path --profile minimal \
      --default-toolchain "$RUST_VERSION" --default-host "$rustArch" \
      --component rust-analyzer rust-src clippy; \
    rm -f /tmp/rustup-init; \
    rustc --version; \
    cargo --version; \
    rustup component list --installed

# Pinned, --locked cargo tools. Strip build caches afterwards to keep the
# copied prefix small (registry sources/git checkouts aren't needed at runtime).
RUN set -eux; \
    cargo install --locked --version "${CARGO_AUDIT_VERSION}" cargo-audit; \
    cargo install --locked --version "${CARGO_WATCH_VERSION}" cargo-watch; \
    rm -rf "${CARGO_HOME}/registry" "${CARGO_HOME}/git"

###############################################################################
# Stage: env-build  (COMMON — apply the user's dotfiles + bake nvim plugins)
###############################################################################
FROM alpine:${ALPINE_VERSION}@${ALPINE_DIGEST} AS env-build
ARG USERNAME USER_UID USER_GID DOTFILES_REPO DOTFILES_REF
# Tools needed to clone+apply dotfiles and compile/install nvim plugins.
# hadolint ignore=DL3018
RUN apk add --no-cache \
      bash ca-certificates chezmoi curl git \
      neovim ripgrep fd fzf bat \
      build-base cmake
RUN addgroup -g "${USER_GID}" "${USERNAME}" \
 && adduser -D -u "${USER_UID}" -G "${USERNAME}" -s /bin/bash "${USERNAME}"
COPY --chown=${USER_UID}:${USER_GID} common/bootstrap-dotfiles.sh /usr/local/bin/langdev-bootstrap-dotfiles
RUN chmod 0755 /usr/local/bin/langdev-bootstrap-dotfiles
USER ${USERNAME}
ENV HOME=/home/${USERNAME}
# 1) Clone + chezmoi-apply the user's dotfiles (brings bashrc, tmux, nvim…).
RUN DOTFILES_REPO="${DOTFILES_REPO}" DOTFILES_REF="${DOTFILES_REF}" \
      langdev-bootstrap-dotfiles
# 2) Drop the Rust LSP spec into the dotfiles' nvim (auto-imported via the
#    config's `plugins.local`), then bake the full plugin set headless so the
#    runtime needs no network on first launch.
COPY --chown=${USER_UID}:${USER_GID} nvim/plugins.local/ /home/${USERNAME}/.config/nvim/lua/plugins.local/
RUN nvim --headless "+Lazy! restore" +qa 2>&1 | tail -n 5 || true \
 && nvim --headless "+Lazy! sync"    +qa 2>&1 | tail -n 5 || true \
 && nvim --headless "+TSUpdateSync"  +qa 2>&1 | tail -n 5 || true

###############################################################################
#                              COMMON BASE
###############################################################################
FROM alpine:${ALPINE_VERSION}@${ALPINE_DIGEST} AS base
ARG USERNAME USER_UID USER_GID

LABEL org.opencontainers.image.title="rustdev" \
      org.opencontainers.image.licenses="Apache-2.0 OR MIT" \
      org.opencontainers.image.vendor="Sebastien Rousseau"

# Runtime deps: editor, multiplexer (tmux — available by default), and the
# CLI tools the dotfiles expect. `tini` is PID 1 (compose sets init:true).
# hadolint ignore=DL3018
RUN apk add --no-cache \
      bash \
      bat \
      ca-certificates \
      chezmoi \
      curl \
      fd \
      fzf \
      git \
      less \
      mosh-server \
      neovim \
      ripgrep \
      tini \
      tmux \
      ttyd \
      tzdata \
      zoxide \
 && update-ca-certificates

RUN addgroup -g "${USER_GID}" "${USERNAME}" \
 && adduser -D -u "${USER_UID}" -G "${USERNAME}" -s /bin/bash "${USERNAME}"

# Bring in the fully-populated home from env-build: the applied dotfiles
# (~/.bashrc, ~/.config/tmux, ~/.config/nvim, ~/.config/shell/*, …) plus the
# baked nvim plugin set. One COPY captures everything chezmoi wrote.
COPY --from=env-build --chown=${USER_UID}:${USER_GID} /home/${USERNAME} /home/${USERNAME}

# Entrypoint & IDE tooling (tmux-loading, strict-mode, AI & MCP).
COPY common/entrypoint.sh /usr/local/bin/langdev-entrypoint
COPY common/tmux-ide.sh /usr/local/bin/tmux-ide
COPY common/muxtree.sh /usr/local/bin/muxtree
COPY common/doctor.sh /usr/local/bin/langdev-doctor
COPY common/mcp-server.sh /usr/local/bin/mcp-server
COPY common/ai-pack.sh /usr/local/bin/ai-pack
COPY common/mcp.json /etc/langdev-mcp.json
COPY common/tmux.conf /etc/tmux.conf
RUN chmod 0755 /usr/local/bin/langdev-entrypoint /usr/local/bin/tmux-ide /usr/local/bin/muxtree \
               /usr/local/bin/langdev-doctor /usr/local/bin/mcp-server /usr/local/bin/ai-pack \
 && chmod 0644 /etc/tmux.conf /etc/langdev-mcp.json \
 && mkdir -p /usr/local/lib/langdev

# --- Hardening ---------------------------------------------------------------
# Sticky bit preserved (1777, NOT 777). Strip setuid/setgid bits everywhere.
RUN chmod 1777 /tmp \
 && find / -xdev -type f \( -perm -4000 -o -perm -2000 \) -exec chmod -s {} + 2>/dev/null || true

USER ${USERNAME}
WORKDIR /work
ENV HOME=/home/${USERNAME} \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    EDITOR=nvim \
    XDG_CONFIG_HOME=/home/${USERNAME}/.config \
    XDG_DATA_HOME=/home/${USERNAME}/.local/share \
    XDG_STATE_HOME=/home/${USERNAME}/.local/state \
    XDG_CACHE_HOME=/home/${USERNAME}/.cache

# Cheap, honest liveness probe (no full-FS scans).
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD nvim --version >/dev/null 2>&1 || exit 1

ENTRYPOINT ["/usr/local/bin/langdev-entrypoint"]

###############################################################################
# Stage: final  (Rust runtime — tiny: toolchain artifacts only, no build tools)
#   Copies the relocatable rustup/cargo prefix from the toolchain stage and
#   installs the language env fragment to /etc/profile.d. No build tools here.
###############################################################################
FROM base AS final

# Relocatable Rust toolchain built + checksum-verified in the toolchain stage.
COPY --from=toolchain --chown=1000:1000 /opt/langdev/toolchain /opt/langdev/toolchain

# Language PATH/env for login shells, sourced via /etc/profile → profile.d.
# Root-owned, 0644. Kept OUT of the user's chezmoi dotfiles so those stay
# pristine and langdev-agnostic; the script guards against duplicate PATH
# entries so it's safe to re-source.
USER root
COPY dotfiles.d/rust.sh /etc/profile.d/rust.sh
RUN chown root:root /etc/profile.d/rust.sh \
 && chmod 0644 /etc/profile.d/rust.sh
USER dev

# rust-analyzer, cargo, clippy, cargo-audit, cargo-watch are all on PATH.
ENV RUSTUP_HOME=/opt/langdev/toolchain/rustup \
    CARGO_HOME=/opt/langdev/toolchain/cargo \
    PATH=/opt/langdev/toolchain/cargo/bin:/home/dev/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
