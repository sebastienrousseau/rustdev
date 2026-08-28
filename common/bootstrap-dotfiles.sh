#!/usr/bin/env bash
# langdev — build-time dotfiles bootstrap.
# SPDX-License-Identifier: MIT
#
# Clones the user's chezmoi-managed dotfiles repo and applies it for the
# current (build) user. Run as the `dev` user in the Containerfile so the
# result is owned correctly. Bundles the LATEST dotfiles by default; pin a
# tag/commit via DOTFILES_REF for reproducible builds.
#
# Env (all overridable as Containerfile build ARGs -> ENV):
#   DOTFILES_REPO  git URL of the dotfiles repo (public → no auth needed)
#   DOTFILES_REF   branch/tag/commit to check out (default: main = latest)
#   DOTFILES_DEST  where to clone (default: $HOME/.dotfiles — matches the
#                  repo's chezmoi sourceDir convention)
#   GIT_NAME/GIT_EMAIL  identity baked into the applied git config
set -euo pipefail

: "${DOTFILES_REPO:=https://github.com/sebastienrousseau/dotfiles.git}"
: "${DOTFILES_REF:=main}"
: "${DOTFILES_DEST:=$HOME/.dotfiles}"
: "${GIT_NAME:=Sebastien Rousseau}"
: "${GIT_EMAIL:=sebastian.rousseau@gmail.com}"

echo "[langdev] cloning dotfiles ${DOTFILES_REPO}@${DOTFILES_REF}"
rm -rf "$DOTFILES_DEST"
git clone --depth 1 --branch "$DOTFILES_REF" "$DOTFILES_REPO" "$DOTFILES_DEST" 2>/dev/null \
  || git clone "$DOTFILES_REPO" "$DOTFILES_DEST"   # ref may be a commit, not a branch
if [ "$DOTFILES_REF" != "main" ]; then
  git -C "$DOTFILES_DEST" checkout -q "$DOTFILES_REF" || true
fi
# Record the exact commit bundled, for provenance.
git -C "$DOTFILES_DEST" rev-parse HEAD > "$HOME/.dotfiles.commit" || true

# Non-interactive chezmoi config so no promptString stalls the build.
mkdir -p "$HOME/.config/chezmoi"
cat > "$HOME/.config/chezmoi/chezmoi.toml" <<TOML
[data]
    profile = "container"
    theme = "tokyonight-night"
    git_name = "${GIT_NAME}"
    git_email = "${GIT_EMAIL}"
    git_signingkey = ""
    git_signingformat = "ssh"
    age_identity = ""
    age_recipient = ""
TOML

# Apply. The repo's .chezmoiroot points chezmoi at its `defaults/` subdir.
# --no-tty keeps promptString on its defaults; keep going on non-fatal
# per-file errors (GUI/macOS entries are already gated by .chezmoiignore).
export CHEZMOI_NO_TTY=1
chezmoi apply --source "$DOTFILES_DEST" --no-tty --keep-going \
  || echo "[langdev] chezmoi apply reported non-fatal issues (continuing)"

echo "[langdev] dotfiles applied (commit $(cat "$HOME/.dotfiles.commit" 2>/dev/null || echo unknown))"
