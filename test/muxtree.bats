#!/usr/bin/env bats
# SPDX-License-Identifier: Apache-2.0 OR MIT
# Unit tests for common/muxtree.sh
load helpers/common

setup() { common_setup; }

SCRIPT="common/muxtree.sh"

@test "muxtree: --help prints usage and exits 0" {
  run bash "$REPO_ROOT/$SCRIPT" --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"Usage: muxtree"* ]]
}

@test "muxtree: unknown command exits 2" {
  run bash "$REPO_ROOT/$SCRIPT" invalid-cmd
  [ "$status" -eq 2 ]
  [[ "$output" == *"error: unknown command"* ]]
}

@test "muxtree: new/create records command" {
  run bash "$REPO_ROOT/$SCRIPT" new feat/ai-agent
  [ "$status" -eq 0 ]
  [[ "$output" == *"MUXTREE_RAN cmd=new args=feat/ai-agent"* ]]
}

@test "muxtree: list records command" {
  run bash "$REPO_ROOT/$SCRIPT" list
  [ "$status" -eq 0 ]
  [[ "$output" == *"MUXTREE_RAN cmd=list"* ]]
}

@test "muxtree: switch records command" {
  run bash "$REPO_ROOT/$SCRIPT" switch feat/ai-agent
  [ "$status" -eq 0 ]
  [[ "$output" == *"MUXTREE_RAN cmd=switch args=feat/ai-agent"* ]]
}

@test "muxtree: remove records command" {
  run bash "$REPO_ROOT/$SCRIPT" remove feat/ai-agent
  [ "$status" -eq 0 ]
  [[ "$output" == *"MUXTREE_RAN cmd=remove args=feat/ai-agent"* ]]
}
