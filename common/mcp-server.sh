#!/usr/bin/env bash
# langdev mcp-server — Model Context Protocol (MCP) stdio server for dev containers.
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
# Implements JSON-RPC 2.0 stdio transport exposing container tools to AI agents:
#   - git_status, git_diff, git_log
#   - read_file, list_files
#   - run_tests, run_command
set -euo pipefail

# --- Test seam (inert in production) ----------------------------------------
if [ -n "${LANGDEV_TEST:-}" ]; then
  printf 'MCP_SERVER_RAN args=%s\n' "${*:-none}"
  exit 0
fi

WORKDIR="${LANGDEV_WORKDIR:-/work}"
[ -d "$WORKDIR" ] || WORKDIR="$PWD"
cd "$WORKDIR" || true

handle_tools_list() {
  cat << 'EOF'
{"jsonrpc":"2.0","id":1,"result":{"tools":[
  {"name":"list_files","description":"List files in the workspace","inputSchema":{"type":"object","properties":{"path":{"type":"string","description":"Relative directory path"}}}},
  {"name":"read_file","description":"Read contents of a file","inputSchema":{"type":"object","required":["path"],"properties":{"path":{"type":"string","description":"Relative file path"}}}},
  {"name":"git_status","description":"Get current git status and branch","inputSchema":{"type":"object","properties":{}}},
  {"name":"git_diff","description":"Get git diff of unstaged/staged changes","inputSchema":{"type":"object","properties":{"staged":{"type":"boolean"}}}},
  {"name":"run_tests","description":"Run the project test suite","inputSchema":{"type":"object","properties":{"args":{"type":"string"}}}},
  {"name":"run_command","description":"Run a shell command safely inside container","inputSchema":{"type":"object","required":["command"],"properties":{"command":{"type":"string"}}}}
]}}
EOF
}

handle_tool_call() {
  local tool_name="$1"
  local arg="$2"

  case "$tool_name" in
    list_files)
      local target_path="${arg:-.}"
      local files
      files=$(find "$target_path" -maxdepth 3 -not -path '*/.*' 2>/dev/null | head -n 100)
      printf '{"jsonrpc":"2.0","id":1,"result":{"content":[{"type":"text","text":%s}]}}\n' \
        "$(printf '%s' "$files" | python3 -c 'import json, sys; print(json.dumps(sys.stdin.read()))' 2>/dev/null || printf '"%s"' "$files")"
      ;;
    read_file)
      if [ -f "$arg" ]; then
        local content
        content=$(cat "$arg")
        printf '{"jsonrpc":"2.0","id":1,"result":{"content":[{"type":"text","text":%s}]}}\n' \
          "$(printf '%s' "$content" | python3 -c 'import json, sys; print(json.dumps(sys.stdin.read()))' 2>/dev/null || printf '"%s"' "$content")"
      else
        printf '{"jsonrpc":"2.0","id":1,"error":{"code":-32602,"message":"File not found: %s"}}\n' "$arg"
      fi
      ;;
    git_status)
      local st
      st=$(git status --short --branch 2>&1 || echo "Not a git repo")
      printf '{"jsonrpc":"2.0","id":1,"result":{"content":[{"type":"text","text":%s}]}}\n' \
        "$(printf '%s' "$st" | python3 -c 'import json, sys; print(json.dumps(sys.stdin.read()))' 2>/dev/null || printf '"%s"' "$st")"
      ;;
    git_diff)
      local diff
      diff=$(git diff 2>&1 || echo "No diff available")
      printf '{"jsonrpc":"2.0","id":1,"result":{"content":[{"type":"text","text":%s}]}}\n' \
        "$(printf '%s' "$diff" | python3 -c 'import json, sys; print(json.dumps(sys.stdin.read()))' 2>/dev/null || printf '"%s"' "$diff")"
      ;;
    run_tests)
      local test_out="No tests configured"
      if [ -f "Makefile" ] && grep -q '^test:' Makefile; then
        test_out=$(make test 2>&1 || true)
      elif [ -f "Cargo.toml" ]; then
        test_out=$(cargo test 2>&1 || true)
      elif [ -f "pyproject.toml" ] || [ -f "setup.py" ]; then
        test_out=$(pytest 2>&1 || true)
      elif [ -f "go.mod" ]; then
        test_out=$(go test ./... 2>&1 || true)
      fi
      printf '{"jsonrpc":"2.0","id":1,"result":{"content":[{"type":"text","text":%s}]}}\n' \
        "$(printf '%s' "$test_out" | python3 -c 'import json, sys; print(json.dumps(sys.stdin.read()))' 2>/dev/null || printf '"%s"' "$test_out")"
      ;;
    run_command)
      local cmd_out
      cmd_out=$(bash -c "$arg" 2>&1 || true)
      printf '{"jsonrpc":"2.0","id":1,"result":{"content":[{"type":"text","text":%s}]}}\n' \
        "$(printf '%s' "$cmd_out" | python3 -c 'import json, sys; print(json.dumps(sys.stdin.read()))' 2>/dev/null || printf '"%s"' "$cmd_out")"
      ;;
    *)
      printf '{"jsonrpc":"2.0","id":1,"error":{"code":-32601,"message":"Method not found"}}\n'
      ;;
  esac
}

case "${1:-}" in
  --tools)
    handle_tools_list
    exit 0
    ;;
  --call)
    handle_tool_call "${2:-}" "${3:-}"
    exit 0
    ;;
  -h|--help)
    cat << 'EOF'
Usage: mcp-server [OPTIONS]

Model Context Protocol (MCP) stdio server for langdev containers.

Options:
  --tools             Output available MCP tools list in JSON-RPC format
  --call <tool> [arg] Execute an MCP tool directly and return JSON-RPC response
  -h, --help          Show this help message
EOF
    exit 0
    ;;
  *)
    # stdio JSON-RPC loop
    while read -r line; do
      if echo "$line" | grep -q '"method":"initialize"'; then
        printf '{"jsonrpc":"2.0","id":1,"result":{"protocolVersion":"2024-11-05","capabilities":{"tools":{}},"serverInfo":{"name":"langdev-mcp","version":"0.0.3"}}}\n'
      elif echo "$line" | grep -q '"method":"tools/list"'; then
        handle_tools_list
      elif echo "$line" | grep -q '"method":"tools/call"'; then
        tool=$(echo "$line" | grep -o '"name":"[^"]*"' | cut -d'"' -f4)
        handle_tool_call "$tool" ""
      else
        printf '{"jsonrpc":"2.0","id":1,"result":{}}\n'
      fi
    done
    ;;
esac
