# SPDX-License-Identifier: Apache-2.0 OR MIT
# shellcheck shell=bash
# Shared bats helpers: sandbox setup, a hermetic PATH builder, and stub-log
# assertions. Sourced from every *.bats file via `load helpers/common`.

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(cd "$TEST_DIR/.." && pwd)"
STUBS_BIN="$TEST_DIR/helpers/bin"
export TEST_DIR REPO_ROOT STUBS_BIN

# common_setup — per-test sandbox. Gives each test a private $HOME, a fresh
# stub invocation log, and turns on the scripts' LANGDEV_TEST seam.
common_setup() {
  SANDBOX="${BATS_TEST_TMPDIR:?bats must provide BATS_TEST_TMPDIR}"
  export HOME="$SANDBOX/home"
  mkdir -p "$HOME"
  export STUB_LOG="$SANDBOX/stub.log"
  : > "$STUB_LOG"
  export LANGDEV_TEST=1
  # Drop any XDG/langdev vars inherited from the caller's environment so the
  # scripts fall back to their documented defaults under the sandbox HOME.
  unset XDG_CACHE_HOME XDG_STATE_HOME XDG_DATA_HOME XDG_CONFIG_HOME
  unset LANGDEV_WORKDIR LANGDEV_RUNTIME_HOOK LANGDEV_NO_TMUX \
        LANGDEV_FAKE_TTY LANGDEV_SOURCE TMUX
  unset DOTFILES_REPO DOTFILES_REF DOTFILES_DEST GIT_NAME GIT_EMAIL
}

# hermetic_path <stub>... — build a clean PATH containing ONLY a whitelist of
# real coreutils plus the named stubs. Because the PATH is closed, stub
# presence is fully deterministic: include `rsync` to hit langdev-sync's rsync
# branch, omit it to hit the cp fallback; include `tmux` to hit the entrypoint
# tmux branch, omit it for the login-shell fallback.
hermetic_path() {
  local bindir="$SANDBOX/bin"
  rm -rf "$bindir"
  mkdir -p "$bindir"
  local t real
  for t in bash sh env mkdir rmdir rm cp mv cat mktemp grep sed awk ls \
           dirname basename chmod printf test; do
    real="$(command -v "$t" 2>/dev/null || true)"
    [ -n "$real" ] && ln -sf "$real" "$bindir/$t"
  done
  for t in "$@"; do
    ln -sf "$STUBS_BIN/$t" "$bindir/$t"
  done
  export PATH="$bindir"
}

# stublog_has <substring> — assert a stub recorded a matching invocation.
stublog_has() {
  grep -F -q -- "$1" "$STUB_LOG"
}
