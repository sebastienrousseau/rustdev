# ~/.bashrc.d/rust.sh — Rust language fragment (rustdev)
# SPDX-License-Identifier: MIT
#
# Sourced by the common ~/.bashrc for interactive shells. Sets the Rust
# environment for the pre-installed, relocatable toolchain and adds a few
# aliases ONLY for tools that are actually installed in the image
# (cargo build/test, clippy, cargo-audit). No host PATH is propagated.

# Relocatable toolchain prefix baked in at build time.
export RUSTUP_HOME=/opt/langdev/toolchain/rustup
export CARGO_HOME=/opt/langdev/toolchain/cargo

# Put cargo's bin (rustc/cargo/clippy/rust-analyzer proxies + installed tools)
# on PATH without clobbering the existing PATH.
case ":${PATH}:" in
  *":${CARGO_HOME}/bin:"*) ;;
  *) export PATH="${CARGO_HOME}/bin:${PATH}" ;;
esac

# --- Aliases (only for tools present in the image) ---------------------------
alias cb='cargo build'
alias cr='cargo run'
alias ct='cargo test'
alias cc='cargo check'
alias ccl='cargo clippy --all-targets --all-features'
alias cw='cargo watch -x check'
alias caudit='cargo audit'
