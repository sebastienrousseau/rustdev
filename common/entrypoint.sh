#!/usr/bin/env bash
# langdev common entrypoint — strict, signal-safe, non-root.
# SPDX-License-Identifier: MIT
#
# Designed to run under an init (tini) via compose `init: true`, so it
# does not need to reap zombies itself. It simply prepares the writable
# runtime dirs (on a read-only rootfs these are tmpfs mounts) and then
# execs either the requested command or an interactive login shell.
set -euo pipefail

# XDG dirs live under $HOME, which is backed by tmpfs on a read-only
# rootfs (see compose). Create them if missing so editors/tools behave.
: "${XDG_CACHE_HOME:=$HOME/.cache}"
: "${XDG_STATE_HOME:=$HOME/.local/state}"
: "${XDG_DATA_HOME:=$HOME/.local/share}"
mkdir -p "$XDG_CACHE_HOME" "$XDG_STATE_HOME" "$XDG_DATA_HOME" || true

# Project directory bind-mounted by the user; default working dir.
if [ -d /work ]; then
  cd /work || true
fi

# Optional per-language runtime hook (e.g. start a server). Must be
# idempotent and fast; provided by the language image if needed.
if [ -x /usr/local/lib/langdev/runtime-hook.sh ]; then
  # shellcheck source=/dev/null
  . /usr/local/lib/langdev/runtime-hook.sh
fi

if [ "$#" -gt 0 ]; then
  exec "$@"
fi

exec /bin/bash --login
