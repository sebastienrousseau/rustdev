#!/usr/bin/env bash
# langdev muxtree — Pair Git worktrees with tmux sessions for parallel AI tasks.
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
# Allows spinning up isolated branches in dedicated Git worktrees, each attached
# to an independent tmux IDE session with full multi-pane layout.
set -euo pipefail

usage() {
  cat << 'EOF'
Usage: muxtree <command> [arguments]

Commands:
  new, create <branch>   Create a git worktree and launch a dedicated tmux session
  list, ls               List all active worktrees and their paired tmux sessions
  switch, sw <branch>    Switch tmux client to a worktree session
  remove, rm <branch>    Kill the tmux session and remove the git worktree
  menu                   Interactive worktree & task switcher
  help, -h               Show this help message
EOF
}

CMD="${1:-help}"

# --- Test seam (inert in production) ----------------------------------------
if [ -n "${LANGDEV_TEST:-}" ]; then
  if [ "$CMD" = "help" ] || [ "$CMD" = "-h" ] || [ "$CMD" = "--help" ]; then
    usage
    exit 0
  fi
  case "$CMD" in
    new|create|list|ls|switch|sw|remove|rm|menu)
      printf 'MUXTREE_RAN cmd=%s args=%s\n' "$CMD" "${*:2}"
      exit 0
      ;;
    *)
      echo "error: unknown command '$CMD'" >&2
      usage
      exit 2
      ;;
  esac
fi

ensure_git_repo() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "error: muxtree must be run inside a Git repository." >&2
    exit 1
  fi
}

cmd_new() {
  ensure_git_repo
  local branch="${1:-}"
  if [ -z "$branch" ]; then
    echo "error: please provide a branch name (e.g. muxtree new feat/ai-agent)" >&2
    exit 1
  fi

  local git_root
  git_root="$(git rev-parse --show-toplevel)"
  local safe_name
  safe_name="$(echo "$branch" | tr '/' '-')"
  local worktree_dir="$git_root/.worktrees/$safe_name"
  local session_name="langdev-$safe_name"

  mkdir -p "$git_root/.worktrees"

  if [ ! -d "$worktree_dir" ]; then
    echo "[muxtree] Creating git worktree at $worktree_dir for branch $branch..."
    if git show-ref --verify --quiet "refs/heads/$branch"; then
      git worktree add "$worktree_dir" "$branch"
    else
      git worktree add -b "$branch" "$worktree_dir"
    fi
  fi

  echo "[muxtree] Launching tmux IDE session '$session_name'..."
  if ! tmux has-session -t "$session_name" 2>/dev/null; then
    tmux new-session -d -s "$session_name" -c "$worktree_dir"
    if command -v tmux-ide >/dev/null 2>&1; then
      tmux-ide --session "$session_name" --workdir "$worktree_dir" --layout ide
    fi
  fi

  if [ -n "${TMUX:-}" ]; then
    tmux switch-client -t "$session_name"
  else
    tmux attach-session -t "$session_name"
  fi
}

cmd_list() {
  ensure_git_repo
  echo "=== Active Git Worktrees & Paired TMUX Sessions ==="
  printf "%-25s %-35s %-15s\n" "BRANCH" "WORKTREE PATH" "TMUX SESSION"
  printf "%-25s %-35s %-15s\n" "-------------------------" "-----------------------------------" "---------------"

  git worktree list --porcelain | while read -r line; do
    if [[ "$line" =~ ^worktree\ (.*) ]]; then
      local wt_path="${BASH_REMATCH[1]}"
      read -r head_line
      read -r branch_line
      local branch_name="detached"
      if [[ "$branch_line" =~ ^branch\ refs/heads/(.*) ]]; then
        branch_name="${BASH_REMATCH[1]}"
      fi
      local safe_name
      safe_name="$(echo "$branch_name" | tr '/' '-')"
      local session_name="langdev-$safe_name"
      local status="inactive"
      if tmux has-session -t "$session_name" 2>/dev/null; then
        status="🟢 active"
      fi
      printf "%-25s %-35s %-15s\n" "$branch_name" "$wt_path" "$status"
    fi
  done
}

cmd_switch() {
  local branch="${1:-}"
  if [ -z "$branch" ]; then
    echo "error: please provide a branch name." >&2
    exit 1
  fi
  local safe_name
  safe_name="$(echo "$branch" | tr '/' '-')"
  local session_name="langdev-$safe_name"

  if tmux has-session -t "$session_name" 2>/dev/null; then
    if [ -n "${TMUX:-}" ]; then
      tmux switch-client -t "$session_name"
    else
      tmux attach-session -t "$session_name"
    fi
  else
    echo "error: session '$session_name' not found. Run 'muxtree new $branch' to create it." >&2
    exit 1
  fi
}

cmd_remove() {
  ensure_git_repo
  local branch="${1:-}"
  if [ -z "$branch" ]; then
    echo "error: please provide a branch name." >&2
    exit 1
  fi

  local git_root
  git_root="$(git rev-parse --show-toplevel)"
  local safe_name
  safe_name="$(echo "$branch" | tr '/' '-')"
  local worktree_dir="$git_root/.worktrees/$safe_name"
  local session_name="langdev-$safe_name"

  if tmux has-session -t "$session_name" 2>/dev/null; then
    echo "[muxtree] Closing tmux session '$session_name'..."
    tmux kill-session -t "$session_name" || true
  fi

  if [ -d "$worktree_dir" ]; then
    echo "[muxtree] Removing git worktree at $worktree_dir..."
    git worktree remove "$worktree_dir" --force || true
  fi
  echo "[muxtree] Cleaned up worktree for '$branch'."
}

cmd_menu() {
  ensure_git_repo
  local branches
  branches=$(git worktree list | awk '{print $3}' | tr -d '[]' || true)

  if command -v fzf >/dev/null 2>&1; then
    local selected
    selected=$(echo "$branches" | fzf --prompt="Select worktree task: " --header="[muxtree Parallel AI Workspaces]")
    if [ -n "$selected" ]; then
      cmd_switch "$selected"
    fi
  else
    echo "Select an active worktree:"
    select b in $branches "Create new task worktree" "Cancel"; do
      case "$b" in
        "Create new task worktree")
          read -r -p "Enter new branch name: " new_branch
          cmd_new "$new_branch"
          break
          ;;
        "Cancel"|"") break ;;
        *) cmd_switch "$b"; break ;;
      esac
    done
  fi
}

case "$CMD" in
  new|create) cmd_new "${2:-}" ;;
  list|ls) cmd_list ;;
  switch|sw) cmd_switch "${2:-}" ;;
  remove|rm) cmd_remove "${2:-}" ;;
  menu) cmd_menu ;;
  help|-h|--help) usage ;;
  *) echo "error: unknown command '$CMD'" >&2; usage; exit 2 ;;
esac
