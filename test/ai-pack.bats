#!/usr/bin/env bats
# SPDX-License-Identifier: Apache-2.0 OR MIT
# Unit tests for common/ai-pack.sh
load helpers/common

setup() { common_setup; }

SCRIPT="common/ai-pack.sh"

@test "ai-pack: runs in test seam with defaults" {
  run bash "$REPO_ROOT/$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"AI_PACK_RAN format=xml output=stdout"* ]]
}

@test "ai-pack: honours custom format and output" {
  run bash "$REPO_ROOT/$SCRIPT" --format markdown --output context.md
  [ "$status" -eq 0 ]
  [[ "$output" == *"AI_PACK_RAN format=markdown output=context.md"* ]]
}
