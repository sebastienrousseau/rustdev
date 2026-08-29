#!/usr/bin/env bats
# SPDX-License-Identifier: Apache-2.0 OR MIT
# Unit tests for common/explorer.sh
load helpers/common

setup() { common_setup; }

SCRIPT="common/explorer.sh"

@test "explorer: runs in test seam with status ok" {
  run bash "$REPO_ROOT/$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"EXPLORER_RAN status=ok"* ]]
}
