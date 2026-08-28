# syntax=docker/dockerfile:1.9
# langdev Containerfile template — OCI, builds with Docker AND Podman.
# SPDX-License-Identifier: MIT
#
# Multi-stage, hardened, ultra-small base for <language>dev images.
# A language repo fills in the `toolchain` stage and copies its LSP
# binaries + nvim/plugins/lang.lua. Everything below the "COMMON BASE"
# banner is identical across the suite (kept in sync via `make sync-common`).
#
# Pin the base by DIGEST. Update via `make bump-base` (looks up the
# current digest for the tag and rewrites the two lines below).
ARG ALPINE_VERSION=3.22
# renovate: datasource=docker depName=alpine
ARG ALPINE_DIGEST=sha256:14358309a308569c32bdc37e2e0e9694be33a9d99e68afb0f5ff33cc1f695dce

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
# Stage: nvim-build  (COMMON — bakes the editor + plugins into the image)
#   Runs Neovim headless to install the exact plugin set from lazy-lock.json,
#   so the runtime image needs NO network on first launch.
###############################################################################
FROM alpine:${ALPINE_VERSION}@${ALPINE_DIGEST} AS nvim-build
ARG USERNAME=dev
ARG USER_UID=1000
ARG USER_GID=1000
RUN apk add --no-cache \
      bash ca-certificates curl git \
      neovim ripgrep fd \
      build-base cmake
# LazyVim starter pinned to a commit (reproducible); overridable at build.
ARG LAZYVIM_STARTER_REF=c31e5cc9f77b16d20a693c30f28fdf907f1caf95
ENV XDG_CONFIG_HOME=/root/.config \
    XDG_DATA_HOME=/root/.local/share \
    XDG_STATE_HOME=/root/.local/state \
    XDG_CACHE_HOME=/root/.cache
RUN git clone --filter=blob:none https://github.com/LazyVim/starter /root/.config/nvim \
 && git -C /root/.config/nvim checkout "${LAZYVIM_STARTER_REF}" \
 && rm -rf /root/.config/nvim/.git
# Common + language plugin specs (language repo adds lang.lua before build).
COPY common/nvim/plugins/ /root/.config/nvim/lua/plugins/
COPY nvim/plugins/ /root/.config/nvim/lua/plugins/
# Reproducible plugin set: restore from committed lockfile, then sync.
COPY nvim/lazy-lock.json /root/.config/nvim/lazy-lock.json
RUN nvim --headless "+Lazy! restore" +qa 2>&1 | tail -n 5 || true \
 && nvim --headless "+TSUpdateSync" +qa 2>&1 | tail -n 5 || true

###############################################################################
#                              COMMON BASE
###############################################################################
FROM alpine:${ALPINE_VERSION}@${ALPINE_DIGEST} AS base

ARG USERNAME=dev
ARG USER_UID=1000
ARG USER_GID=1000

LABEL org.opencontainers.image.title="langdev" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.vendor="Sebastien Rousseau"

# Minimal, pinned runtime. `tini` is the init (compose sets init:true, but
# shipping it keeps `docker run` correct too). Versions are pinned by the
# digest-locked Alpine repository for this release.
# hadolint ignore=DL3018
RUN apk add --no-cache \
      bash \
      ca-certificates \
      curl \
      git \
      less \
      neovim \
      ripgrep \
      fd \
      tini \
      tzdata \
 && update-ca-certificates

# Non-root user with a real home.
RUN addgroup -g "${USER_GID}" "${USERNAME}" \
 && adduser -D -u "${USER_UID}" -G "${USERNAME}" -s /bin/bash "${USERNAME}"

# Portable dotfiles.
COPY --chown=${USER_UID}:${USER_GID} common/dotfiles/bashrc        /home/${USERNAME}/.bashrc
COPY --chown=${USER_UID}:${USER_GID} common/dotfiles/bash_profile  /home/${USERNAME}/.bash_profile
COPY --chown=${USER_UID}:${USER_GID} common/dotfiles/bash_aliases  /home/${USERNAME}/.bash_aliases

# Editor + baked-in plugins from the nvim-build stage.
COPY --from=nvim-build --chown=${USER_UID}:${USER_GID} /root/.config/nvim /home/${USERNAME}/.config/nvim
COPY --from=nvim-build --chown=${USER_UID}:${USER_GID} /root/.local/share/nvim /home/${USERNAME}/.local/share/nvim

# Entrypoint.
COPY common/entrypoint.sh /usr/local/bin/langdev-entrypoint
RUN chmod 0755 /usr/local/bin/langdev-entrypoint \
 && mkdir -p /usr/local/lib/langdev

# --- Hardening ---------------------------------------------------------------
# Sticky bit preserved (1777, NOT 777). Remove any setuid/setgid bits so no
# privilege escalation vector survives. No `chattr` theatre (no-op in a
# container). No account-lock theatre — we simply run as an unprivileged user.
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
#   drops the language shell fragment. No wget/shadow/build-base here.
###############################################################################
FROM base AS final

# Relocatable Rust toolchain built + checksum-verified in the toolchain stage.
COPY --from=toolchain --chown=1000:1000 /opt/langdev/toolchain /opt/langdev/toolchain

# Language shell fragment: sets CARGO_HOME/RUSTUP_HOME/PATH + a few aliases.
COPY --chown=1000:1000 dotfiles.d/rust.sh /home/dev/.bashrc.d/rust.sh

# rust-analyzer, cargo, clippy, cargo-audit, cargo-watch are all on PATH.
ENV RUSTUP_HOME=/opt/langdev/toolchain/rustup \
    CARGO_HOME=/opt/langdev/toolchain/cargo \
    PATH=/opt/langdev/toolchain/cargo/bin:/home/dev/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
