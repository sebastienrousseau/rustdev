#!/usr/bin/env bats
# SPDX-License-Identifier: Apache-2.0 OR MIT
# Unit tests for common/entrypoint.sh — the strict-mode, tmux-loading
# container entrypoint. The LANGDEV_TEST seam shadows `exec` so the process is
# not replaced; every branch's exec target is asserted via the recorded argv.
load helpers/common

setup() { common_setup; }

SCRIPT="common/entrypoint.sh"

@test "entrypoint: execs the passed command, cds the workdir, sources the hook" {
  hermetic_path
  export LANGDEV_WORKDIR="$SANDBOX/work"
  mkdir -p "$LANGDEV_WORKDIR"
  hook="$SANDBOX/hook.sh"
  printf '#!/usr/bin/env bash\necho HOOK_RAN\n' > "$hook"
  chmod +x "$hook"
  export LANGDEV_RUNTIME_HOOK="$hook"
  run bash "$REPO_ROOT/$SCRIPT" printf hello
  [ "$status" -eq 0 ]
  [[ "$output" == *"HOOK_RAN"* ]]
  [[ "$output" == *"LANGDEV_EXEC printf hello"* ]]
  # XDG dirs were created under the sandbox HOME.
  [ -d "$HOME/.cache" ]
  [ -d "$HOME/.local/state" ]
  [ -d "$HOME/.local/share" ]
}

@test "entrypoint: skips the hook when it is absent or not executable" {
  hermetic_path
  export LANGDEV_RUNTIME_HOOK="$SANDBOX/does-not-exist.sh"
  run bash "$REPO_ROOT/$SCRIPT" true
  [ "$status" -eq 0 ]
  [[ "$output" != *"HOOK_RAN"* ]]
  [[ "$output" == *"LANGDEV_EXEC true"* ]]
}

@test "entrypoint: loads tmux for an interactive TTY session" {
  hermetic_path tmux
  export LANGDEV_FAKE_TTY=1
  unset TMUX
  run bash "$REPO_ROOT/$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"LANGDEV_EXEC tmux new-session -A -s langdev"* ]]
}

@test "entrypoint: LANGDEV_NO_TMUX falls back to a login shell" {
  hermetic_path tmux
  export LANGDEV_FAKE_TTY=1
  export LANGDEV_NO_TMUX=1
  run bash "$REPO_ROOT/$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"LANGDEV_EXEC /bin/bash --login"* ]]
}

@test "entrypoint: a non-TTY stdout falls back to a login shell" {
  hermetic_path tmux
  export LANGDEV_FAKE_TTY=0
  run bash "$REPO_ROOT/$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"LANGDEV_EXEC /bin/bash --login"* ]]
}

@test "entrypoint: no tmux installed falls back to a login shell" {
  hermetic_path
  export LANGDEV_FAKE_TTY=1
  run bash "$REPO_ROOT/$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"LANGDEV_EXEC /bin/bash --login"* ]]
}

@test "entrypoint: does not nest tmux when already inside a session" {
  hermetic_path tmux
  export LANGDEV_FAKE_TTY=1
  export TMUX="/tmp/tmux-1000/default,123,0"
  run bash "$REPO_ROOT/$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"LANGDEV_EXEC /bin/bash --login"* ]]
}
