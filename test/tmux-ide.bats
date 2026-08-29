#!/usr/bin/env bats
# SPDX-License-Identifier: Apache-2.0 OR MIT
# Unit tests for common/tmux-ide.sh
load helpers/common

setup() { common_setup; }

SCRIPT="common/tmux-ide.sh"

@test "tmux-ide: --help prints usage and exits 0" {
  run bash "$REPO_ROOT/$SCRIPT" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage: tmux-ide"* ]]
  [[ "$output" == *"Prefix + i"* ]]
}

@test "tmux-ide: unknown arg exits 2" {
  run bash "$REPO_ROOT/$SCRIPT" --bogus-arg
  [ "$status" -eq 2 ]
  [[ "$output" == *"error: unknown argument"* ]]
}

@test "tmux-ide: executes default ide layout" {
  run bash "$REPO_ROOT/$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"TMUX_IDE_RAN layout=ide"* ]]
}

@test "tmux-ide: honours custom layout and session" {
  run bash "$REPO_ROOT/$SCRIPT" --layout minimalist --session custom-ses
  [ "$status" -eq 0 ]
  [[ "$output" == *"TMUX_IDE_RAN layout=minimalist session=custom-ses"* ]]
}

@test "tmux-ide: honours --auto mode" {
  run bash "$REPO_ROOT/$SCRIPT" --auto
  [ "$status" -eq 0 ]
  [[ "$output" == *"auto=1"* ]]
}
