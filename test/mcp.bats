#!/usr/bin/env bats
# SPDX-License-Identifier: Apache-2.0 OR MIT
# Unit tests for common/mcp-server.sh
load helpers/common

setup() { common_setup; }

SCRIPT="common/mcp-server.sh"

@test "mcp-server: runs with default args in test seam" {
  run bash "$REPO_ROOT/$SCRIPT"
  [ "$status" -eq 0 ]
  [[ "$output" == *"MCP_SERVER_RAN"* ]]
}

@test "mcp-server: accepts tools query" {
  run bash "$REPO_ROOT/$SCRIPT" --tools
  [ "$status" -eq 0 ]
  [[ "$output" == *"MCP_SERVER_RAN args=--tools"* ]]
}
