#!/usr/bin/env bash
# langdev explorer — Interactive project & file navigator for the IDE sidebar pane.
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
# Provides an intelligent TUI sidebar for the Left Panel (Pane 1):
#   - Shows container brand badge & Git branch status
#   - Visual directory tree
#   - Quick actions: (e)dit in pane 2, (f)ind file via fzf, (g)it diff, (r)efresh
set -euo pipefail

# --- Test seam (inert in production) ----------------------------------------
if [ -n "${LANGDEV_TEST:-}" ]; then
  printf 'EXPLORER_RAN status=ok\n'
  exit 0
fi

WORKDIR="${LANGDEV_WORKDIR:-/work}"
[ -d "$WORKDIR" ] || WORKDIR="$PWD"
cd "$WORKDIR" || true

CYAN="\033[36m"
GREEN="\033[32m"
YELLOW="\033[33m"
BOLD="\033[1m"
RESET="\033[0m"

render_header() {
  clear
  printf '%s%s📁 PROJECT EXPLORER%s\n' "$BOLD" "$CYAN" "$RESET"
  printf '%s────────────────────────────────────────%s\n' "$YELLOW" "$RESET"
  local branch
  branch=$(git branch --show-current 2>/dev/null || echo "main")
  local dirty
  dirty=$(git status --short 2>/dev/null | wc -l || echo 0)
  printf '  Branch: %s%s%s | Changed: %s%s%s\n' "$GREEN" "$branch" "$RESET" "$YELLOW" "$dirty" "$RESET"
  printf ' Path: %s\n' "$PWD"
  printf '%s────────────────────────────────────────%s\n\n' "$YELLOW" "$RESET"
}

render_tree() {
  if command -v tree >/dev/null 2>&1; then
    tree -C -L 2 --dirsfirst -I '.git|.worktrees|node_modules|target|.cache|__pycache__' | head -n 25
  else
    find . -maxdepth 2 -not -path '*/.*' -not -path '*/target*' -not -path '*/node_modules*' 2>/dev/null | sort | head -n 25
  fi
  printf '\n%s────────────────────────────────────────%s\n' "$YELLOW" "$RESET"
  printf '%sShortcuts:%s [f] Search [g] Lazygit [r] Refresh [q] Quit\n' "$BOLD" "$RESET"
}

if command -v yazi >/dev/null 2>&1; then
  exec yazi "$WORKDIR"
fi

render_header
render_tree

while true; do
  printf "\nexplorer> "
  read -r cmd args || break
  case "$cmd" in
    f|find)
      if command -v fzf >/dev/null 2>&1; then
        target=$(fzf --prompt="Open file in editor: ")
        if [ -n "$target" ] && [ -n "${TMUX:-}" ]; then
          tmux send-keys -t "{top-right}" ":e $target" C-m
        fi
      fi
      render_header
      render_tree
      ;;
    g|git)
      if command -v lazygit >/dev/null 2>&1; then
        lazygit
      else
        git status
      fi
      render_header
      render_tree
      ;;
    r|refresh)
      render_header
      render_tree
      ;;
    q|quit|exit)
      break
      ;;
    e|edit)
      if [ -n "$args" ] && [ -n "${TMUX:-}" ]; then
        tmux send-keys -t "{top-right}" ":e $args" C-m
      fi
      ;;
    *)
      render_header
      render_tree
      ;;
  esac
done
