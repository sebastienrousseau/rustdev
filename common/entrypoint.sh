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

# tmux is available by default and LOADED for interactive sessions.
# Attaches to (or creates) a persistent 'langdev' session so panes/windows
# survive detach. Opt out with LANGDEV_NO_TMUX=1. Falls through to a plain
# login shell when tmux is absent, output isn't a TTY, or we're already
# inside tmux.
if [ -z "${TMUX:-}" ] \
   && [ "${LANGDEV_NO_TMUX:-0}" != "1" ] \
   && [ -t 1 ] \
   && command -v tmux >/dev/null 2>&1; then
  exec tmux new-session -A -s langdev
fi

exec /bin/bash --login
