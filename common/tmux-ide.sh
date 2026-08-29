#!/usr/bin/env bash
# langdev tmux-ide — IDE grid layout & AI workspace launcher.
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
# Automates the 4-pane VS Code-style terminal IDE grid:
#   [Left 20%: Explorer/Context] [Center-Top 56%: Editor] [Right 24%: AI Agent]
#                                [Center-Bottom 56%: Terminal]
set -euo pipefail

LAYOUT="ide"
SESSION="${TMUX_SESSION:-langdev}"
WORKDIR="${LANGDEV_WORKDIR:-/work}"
AUTO_MODE=0
LAUNCH_ATTACH=0

usage() {
  cat << 'EOF'
Usage: tmux-ide [OPTIONS]

Options:
  -l, --layout <ide|minimalist|split|focus>
                        Layout geometry to apply (default: ide)
  -s, --session <name>  Target tmux session name (default: current or langdev)
  -w, --workdir <dir>   Working directory (default: /work or $PWD)
  -a, --auto            Auto-initialize only if the window has 1 pane
  --launch              Create/attach session and launch IDE
  -h, --help            Show this help message

Keybindings in tmux:
  Prefix + i   Rebuild 4-pane VS Code grid layout
  Prefix + I   Rebuild 3-pane Minimalist layout
  Prefix + F   Toggle Focus / Maximize active pane
  Prefix + m   Open muxtree Git worktree manager
  Prefix + 1..4 Select Pane 1 (Explorer), 2 (Editor), 3 (Terminal), 4 (AI)
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    -l|--layout) LAYOUT="$2"; shift 2 ;;
    -s|--session) SESSION="$2"; shift 2 ;;
    -w|--workdir) WORKDIR="$2"; shift 2 ;;
    -a|--auto) AUTO_MODE=1; shift ;;
    --launch) LAUNCH_ATTACH=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "error: unknown argument '$1'" >&2; exit 2 ;;
  esac
done

[ -d "$WORKDIR" ] || WORKDIR="$PWD"

# --- Test seam (inert in production) ----------------------------------------
if [ -n "${LANGDEV_TEST:-}" ]; then
  printf 'TMUX_IDE_RAN layout=%s session=%s workdir=%s auto=%d\n' \
    "$LAYOUT" "$SESSION" "$WORKDIR" "$AUTO_MODE"
  exit 0
fi

if ! command -v tmux >/dev/null 2>&1; then
  echo "error: tmux is required but not installed." >&2
  exit 1
fi

# If outside tmux and --launch requested, create session or attach
if [ -z "${TMUX:-}" ] && [ "$LAUNCH_ATTACH" -eq 1 ]; then
  if tmux has-session -t "$SESSION" 2>/dev/null; then
    exec tmux attach-session -t "$SESSION"
  fi
  tmux new-session -d -s "$SESSION" -c "$WORKDIR"
  "$0" --session "$SESSION" --workdir "$WORKDIR" --layout "$LAYOUT"
  exec tmux attach-session -t "$SESSION"
fi

TARGET_WIN="${SESSION}:"

# In auto mode, only format if window currently has exactly 1 pane
if [ "$AUTO_MODE" -eq 1 ]; then
  PANE_COUNT=$(tmux list-panes -t "$TARGET_WIN" 2>/dev/null | wc -l || echo 1)
  if [ "$PANE_COUNT" -gt 1 ]; then
    exit 0
  fi
fi

# Detect AI CLI tools available in container
AI_CMD=""
if command -v claude >/dev/null 2>&1; then
  AI_CMD="claude"
elif command -v agy >/dev/null 2>&1; then
  AI_CMD="agy"
elif command -v ollama >/dev/null 2>&1; then
  AI_CMD="ollama run llama3.2"
fi

apply_ide_layout() {
  # Kill other panes if rebuilding existing window
  PANE_COUNT=$(tmux list-panes -t "$TARGET_WIN" 2>/dev/null | wc -l || echo 1)
  if [ "$PANE_COUNT" -gt 1 ]; then
    tmux kill-pane -a -t "$TARGET_WIN.1" 2>/dev/null || true
  fi

  # 1. Split Left Panel (20% width) for Explorer / Context
  tmux split-window -h -b -l 20% -t "$TARGET_WIN.1" -c "$WORKDIR"

  # 2. Split Right Panel (30% of remaining 80% = 24% total) for AI Agent
  tmux split-window -h -l 30% -t "$TARGET_WIN.2" -c "$WORKDIR"

  # 3. Split Center Bottom (30% height) for Integrated Terminal
  tmux split-window -v -l 30% -t "$TARGET_WIN.2" -c "$WORKDIR"

  # Set Pane Titles
  tmux select-pane -t "$TARGET_WIN.1" -T "Explorer / Context"
  tmux select-pane -t "$TARGET_WIN.2" -T "Editor (Neovim)"
  tmux select-pane -t "$TARGET_WIN.3" -T "Integrated Terminal"
  tmux select-pane -t "$TARGET_WIN.4" -T "AI Agent"

  # Left Pane: File explorer or project overview banner
  if command -v yazi >/dev/null 2>&1; then
    tmux send-keys -t "$TARGET_WIN.1" "yazi" C-m
  else
    tmux send-keys -t "$TARGET_WIN.1" "clear && ls -la && echo '' && echo '📁 [Explorer Pane] Type e <file> to edit'" C-m
  fi

  # Center-Top Pane: Launch Editor
  if command -v nvim >/dev/null 2>&1; then
    tmux send-keys -t "$TARGET_WIN.2" "nvim ." C-m
  fi

  # Right Pane: AI Agent or Assistant prompt
  if [ -n "$AI_CMD" ]; then
    tmux send-keys -t "$TARGET_WIN.4" "$AI_CMD" C-m
  else
    tmux send-keys -t "$TARGET_WIN.4" "clear && echo '🤖 [AI Agent Pane] Ready for claude / agy / ai tooling' && echo ''" C-m
  fi

  # Center-Bottom Pane: Ready shell
  tmux send-keys -t "$TARGET_WIN.3" "clear" C-m

  # Focus Center-Top (Editor)
  tmux select-pane -t "$TARGET_WIN.2"
}

apply_minimalist_layout() {
  PANE_COUNT=$(tmux list-panes -t "$TARGET_WIN" 2>/dev/null | wc -l || echo 1)
  if [ "$PANE_COUNT" -gt 1 ]; then
    tmux kill-pane -a -t "$TARGET_WIN.1" 2>/dev/null || true
  fi

  # Right 35% for AI Agent
  tmux split-window -h -l 35% -t "$TARGET_WIN.1" -c "$WORKDIR"
  # Bottom 30% of left side for Terminal
  tmux split-window -v -l 30% -t "$TARGET_WIN.1" -c "$WORKDIR"

  tmux select-pane -t "$TARGET_WIN.1" -T "Editor (Neovim)"
  tmux select-pane -t "$TARGET_WIN.2" -T "Integrated Terminal"
  tmux select-pane -t "$TARGET_WIN.3" -T "AI Agent"

  if command -v nvim >/dev/null 2>&1; then
    tmux send-keys -t "$TARGET_WIN.1" "nvim ." C-m
  fi
  if [ -n "$AI_CMD" ]; then
    tmux send-keys -t "$TARGET_WIN.3" "$AI_CMD" C-m
  fi

  tmux select-pane -t "$TARGET_WIN.1"
}

case "$LAYOUT" in
  ide) apply_ide_layout ;;
  minimalist) apply_minimalist_layout ;;
  focus) tmux resize-pane -Z ;;
  *) echo "error: unknown layout '$LAYOUT'" >&2; exit 2 ;;
esac
