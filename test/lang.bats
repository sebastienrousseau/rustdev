#!/usr/bin/env bats
# SPDX-License-Identifier: Apache-2.0 OR MIT
# Unit tests for dotfiles.d/rust.sh — the Rust language profile fragment
# installed to /etc/profile.d and sourced by login shells. The fragment only
# exports toolchain env and prepends cargo's bin to PATH (guarded, so it is
# safe to re-source). These tests source it in a hermetic sandbox and assert
# it sets that environment without error and is idempotent.
load helpers/common

setup() { common_setup; }

SCRIPT="dotfiles.d/rust.sh"

@test "rust.sh: sets the toolchain env and prepends cargo bin to PATH" {
  run bash -c '
    set -euo pipefail
    export PATH="/langdev-base"
    # shellcheck source=/dev/null
    source "$1"
    printf "RUSTUP_HOME=%s\n" "$RUSTUP_HOME"
    printf "CARGO_HOME=%s\n" "$CARGO_HOME"
    printf "PATHVAL=%s\n" "$PATH"
  ' _ "$REPO_ROOT/$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"RUSTUP_HOME=/opt/langdev/toolchain/rustup"* ]]
  [[ "$output" == *"CARGO_HOME=/opt/langdev/toolchain/cargo"* ]]
  [[ "$output" == *"PATHVAL=/opt/langdev/toolchain/cargo/bin:/langdev-base"* ]]
}

@test "rust.sh: is idempotent — re-sourcing does not duplicate the PATH entry" {
  run bash -c '
    set -euo pipefail
    export PATH="/langdev-base"
    source "$1"; source "$1"
    printf "PATHVAL=%s" "$PATH"
  ' _ "$REPO_ROOT/$SCRIPT"
  [ "$status" -eq 0 ]
  pathval="${output#PATHVAL=}"
  n="$(printf '%s' "$pathval" | grep -oF '/opt/langdev/toolchain/cargo/bin' | wc -l)"
  [ "$n" -eq 1 ]
}
