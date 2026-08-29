#!/usr/bin/env bash
# langdev common entrypoint — strict, signal-safe, non-root.
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
# Designed to run under an init (tini) via compose `init: true`, so it
# does not need to reap zombies itself. It simply prepares the writable
# runtime dirs (on a read-only rootfs these are tmpfs mounts) and then
# execs either the requested command or an interactive login shell.
set -euo pipefail

# --- Test seams (inert in production) ---------------------------------------
# These exist ONLY so the unit tests (test/*.bats) can exercise every branch
# hermetically, with no container and no root. All default to the production
# values, so an unset LANGDEV_TEST leaves runtime behaviour byte-identical.
#
#   LANGDEV_WORKDIR       project dir to cd into            (default /work)
#   LANGDEV_RUNTIME_HOOK  optional per-language hook script (default the
#                         /usr/local/lib path the Containerfile installs)
#   LANGDEV_TEST          when set, `exec` is shadowed by a function that
#                         records its argv and exits instead of replacing the
#                         process, and the stdout-TTY probe is forced via
#                         LANGDEV_FAKE_TTY. See test/README.md.
: "${LANGDEV_WORKDIR:=/work}"
: "${LANGDEV_RUNTIME_HOOK:=/usr/local/lib/langdev/runtime-hook.sh}"

_is_tty() {
  if [ -n "${LANGDEV_TEST:-}" ]; then
    [ "${LANGDEV_FAKE_TTY:-0}" = "1" ]
  else
    [ -t 1 ]
  fi
}

if [ -n "${LANGDEV_TEST:-}" ]; then
  # Faithful model of `exec`: it terminates the script (the real exec
  # replaces the process), but records argv so a test can assert on it.
  exec() { printf 'LANGDEV_EXEC %s\n' "$*"; exit "${LANGDEV_EXEC_RC:-0}"; }
fi

# XDG dirs live under $HOME, which is backed by tmpfs on a read-only
# rootfs (see compose). Create them if missing so editors/tools behave.
: "${XDG_CACHE_HOME:=$HOME/.cache}"
: "${XDG_STATE_HOME:=$HOME/.local/state}"
: "${XDG_DATA_HOME:=$HOME/.local/share}"
mkdir -p "$XDG_CACHE_HOME" "$XDG_STATE_HOME" "$XDG_DATA_HOME" || true

# Project directory bind-mounted by the user; default working dir.
if [ -d "$LANGDEV_WORKDIR" ]; then
  cd "$LANGDEV_WORKDIR" || true
fi

# Optional per-language runtime hook (e.g. start a server). Must be
# idempotent and fast; provided by the language image if needed.
if [ -x "$LANGDEV_RUNTIME_HOOK" ]; then
  # shellcheck source=/dev/null
  . "$LANGDEV_RUNTIME_HOOK"
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
   && _is_tty \
   && command -v tmux >/dev/null 2>&1; then
  exec tmux new-session -A -s langdev
fi

exec /bin/bash --login
