#!/usr/bin/env bats
# SPDX-License-Identifier: Apache-2.0 OR MIT
# Unit tests for bin/langdev-sync — vendors the shared common/ core into a
# repo. Hermetic: git and rsync are test doubles on a closed PATH, so the
# local-path vs git-URL and rsync vs cp branches are all deterministic.
load helpers/common

setup() { common_setup; }

SCRIPT="bin/langdev-sync"

@test "langdev-sync: --help prints usage and exits 0" {
  hermetic_path
  run bash "$REPO_ROOT/$SCRIPT" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"vendor the shared common/ core"* ]]
  [[ "$output" == *"Usage:"* ]]
}

@test "langdev-sync: unknown arg exits 2" {
  hermetic_path
  run bash "$REPO_ROOT/$SCRIPT" --bogus
  [ "$status" -eq 2 ]
  [[ "$output" == *"unknown arg: --bogus"* ]]
}

@test "langdev-sync: clones a git URL source and rsyncs into ./common" {
  hermetic_path git rsync
  cd "$SANDBOX"
  run bash "$REPO_ROOT/$SCRIPT" --source https://github.com/sebastienrousseau/langdev.git
  [ "$status" -eq 0 ]
  stublog_has "git clone --depth 1 https://github.com/sebastienrousseau/langdev.git"
  stublog_has "rsync -a --delete"
  [[ "$output" == *"synced common/ from"* ]]
}

@test "langdev-sync: accepts an scp-style git@ source" {
  hermetic_path git rsync
  cd "$SANDBOX"
  run bash "$REPO_ROOT/$SCRIPT" --source git@github.com:sebastienrousseau/langdev.git
  [ "$status" -eq 0 ]
  stublog_has "git clone --depth 1 git@github.com:sebastienrousseau/langdev.git"
}

@test "langdev-sync: copies from a local path with cp when rsync is absent" {
  hermetic_path git   # no rsync stub -> command -v rsync fails -> cp fallback
  local src_root="$SANDBOX/src"
  mkdir -p "$src_root/common"
  printf '# core\n' > "$src_root/common/entrypoint.sh"
  mkdir -p "$SANDBOX/dest"
  cd "$SANDBOX/dest"
  run bash "$REPO_ROOT/$SCRIPT" --source "$src_root"
  [ "$status" -eq 0 ]
  [ -f "./common/entrypoint.sh" ]
  [[ "$output" == *"synced common/ from"* ]]
}

@test "langdev-sync: LANGDEV_SOURCE env is used when no --source is given" {
  hermetic_path git rsync
  local src_root="$SANDBOX/env-src"
  mkdir -p "$src_root/common"
  printf '# core\n' > "$src_root/common/entrypoint.sh"
  export LANGDEV_SOURCE="$src_root"
  mkdir -p "$SANDBOX/dest2"
  cd "$SANDBOX/dest2"
  run bash "$REPO_ROOT/$SCRIPT"
  [ "$status" -eq 0 ]
  stublog_has "rsync -a --delete"
  [[ "$output" == *"synced common/ from: $src_root"* ]]
}

@test "langdev-sync: errors when the source has no common/ directory" {
  hermetic_path git
  local empty="$SANDBOX/empty"
  mkdir -p "$empty"
  run bash "$REPO_ROOT/$SCRIPT" --source "$empty"
  [ "$status" -eq 1 ]
  [[ "$output" == *"no common/ found"* ]]
}
