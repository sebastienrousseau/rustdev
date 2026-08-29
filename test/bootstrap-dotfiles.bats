#!/usr/bin/env bats
# SPDX-License-Identifier: Apache-2.0 OR MIT
# Unit tests for common/bootstrap-dotfiles.sh — the build-time dotfiles
# bootstrap. Hermetic: git and chezmoi are test doubles on a closed PATH.
load helpers/common

setup() { common_setup; }

SCRIPT="common/bootstrap-dotfiles.sh"

@test "bootstrap: clones default repo@main and applies chezmoi" {
  hermetic_path git chezmoi
  run bash "$REPO_ROOT/$SCRIPT"
  [ "$status" -eq 0 ]
  stublog_has "git clone --depth 1 --branch main https://github.com/sebastienrousseau/dotfiles.git"
  stublog_has "chezmoi apply --source"
  [ -f "$HOME/.config/chezmoi/chezmoi.toml" ]
  grep -q 'git_name = "Sebastien Rousseau"' "$HOME/.config/chezmoi/chezmoi.toml"
  grep -q 'git_email = "sebastian.rousseau@gmail.com"' "$HOME/.config/chezmoi/chezmoi.toml"
  grep -q 'git_signingformat = "ssh"' "$HOME/.config/chezmoi/chezmoi.toml"
  [ -f "$HOME/.dotfiles.commit" ]
}

@test "bootstrap: main ref does not trigger the explicit checkout" {
  hermetic_path git chezmoi
  run bash "$REPO_ROOT/$SCRIPT"
  [ "$status" -eq 0 ]
  # With ref=main the shallow --branch clone is authoritative; no checkout.
  run grep -c "checkout" "$STUB_LOG"
  [ "$output" -eq 0 ]
}

@test "bootstrap: honours overridden DOTFILES_REPO/REF/GIT identity" {
  hermetic_path git chezmoi
  export DOTFILES_REPO="https://example.com/my/dots.git"
  export DOTFILES_REF="v1.2.3"
  export GIT_NAME="Ada Lovelace"
  export GIT_EMAIL="ada@example.com"
  run bash "$REPO_ROOT/$SCRIPT"
  [ "$status" -eq 0 ]
  stublog_has "git clone --depth 1 --branch v1.2.3 https://example.com/my/dots.git"
  # ref != main -> explicit checkout of the tag/commit.
  stublog_has "checkout -q v1.2.3"
  grep -q 'git_name = "Ada Lovelace"' "$HOME/.config/chezmoi/chezmoi.toml"
  grep -q 'git_email = "ada@example.com"' "$HOME/.config/chezmoi/chezmoi.toml"
}

@test "bootstrap: honours a custom DOTFILES_DEST" {
  hermetic_path git chezmoi
  export DOTFILES_DEST="$SANDBOX/custom-dotfiles"
  run bash "$REPO_ROOT/$SCRIPT"
  [ "$status" -eq 0 ]
  stublog_has "$SANDBOX/custom-dotfiles"
}

@test "bootstrap: falls back to a full clone when the ref is not a branch" {
  hermetic_path git chezmoi
  export DOTFILES_REF="abc123def456"
  export STUB_GIT_BRANCH_FAIL=1
  run bash "$REPO_ROOT/$SCRIPT"
  [ "$status" -eq 0 ]
  # The shallow --branch clone was attempted and failed...
  stublog_has "git clone --depth 1 --branch abc123def456"
  # ...so the plain clone ran, then the ref was checked out.
  stublog_has "checkout -q abc123def456"
}

@test "bootstrap: continues when chezmoi apply reports non-fatal issues" {
  hermetic_path git chezmoi
  export STUB_CHEZMOI_RC=1
  run bash "$REPO_ROOT/$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"non-fatal issues (continuing)"* ]]
}

@test "bootstrap: records the bundled commit for provenance" {
  hermetic_path git chezmoi
  export STUB_GIT_SHA="deadbeefdeadbeefdeadbeefdeadbeefdeadbeef"
  run bash "$REPO_ROOT/$SCRIPT"
  [ "$status" -eq 0 ]
  grep -q "deadbeefdeadbeefdeadbeefdeadbeefdeadbeef" "$HOME/.dotfiles.commit"
  [[ "$output" == *"deadbeefdeadbeefdeadbeefdeadbeefdeadbeef"* ]]
}
