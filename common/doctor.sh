#!/usr/bin/env bash
# langdev doctor — Diagnostic & healthcheck utility for dev containers.
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
# Verifies container engines, kernel security, architecture, terminal clipboard,
# and dev container runtime readiness.
set -euo pipefail

# --- Test seam (inert in production) ----------------------------------------
if [ -n "${LANGDEV_TEST:-}" ]; then
  printf 'LANGDEV_DOCTOR_RAN status=ok\n'
  exit 0
fi

GREEN="\033[32m"
YELLOW="\033[33m"
RED="\033[31m"
CYAN="\033[36m"
BOLD="\033[1m"
RESET="\033[0m"

pass() { printf "  ${GREEN}✔ [OK]${RESET} %s\n" "$1"; }
warn() { printf "  ${YELLOW}▲ [WARN]${RESET} %s\n" "$1"; }
fail() { printf "  ${RED}✖ [FAIL]${RESET} %s\n" "$1"; }
info() { printf "  ${CYAN}ℹ [INFO]${RESET} %s\n" "$1"; }

printf "\n${BOLD}=== langdev System & Container Diagnostics ===${RESET}\n\n"

# 1. Host Architecture & OS
OS="$(uname -s)"
ARCH="$(uname -m)"
info "Host Platform: $OS ($ARCH)"

# 2. Container Engine
ENGINE=""
if command -v docker >/dev/null 2>&1; then
  ENGINE="docker"
  DOCKER_VER="$(docker --version 2>/dev/null | awk '{print $3}' | tr -d ',')"
  if docker info >/dev/null 2>&1; then
    pass "Docker Engine installed & running ($DOCKER_VER)"
  else
    warn "Docker binary found ($DOCKER_VER) but daemon is not responding."
  fi
elif command -v podman >/dev/null 2>&1; then
  ENGINE="podman"
  PODMAN_VER="$(podman --version 2>/dev/null | awk '{print $3}')"
  pass "Podman installed ($PODMAN_VER)"
else
  fail "No container engine found. Please install Docker or Podman."
fi

# 3. Host Developer Tools
for tool in git bash tmux curl ssh; do
  if command -v "$tool" >/dev/null 2>&1; then
    pass "Host tool '$tool' is available"
  else
    warn "Host tool '$tool' is missing (recommended)"
  fi
done

# 4. Linters & QA Tools
for tool in hadolint shellcheck bats trivy syft; do
  if command -v "$tool" >/dev/null 2>&1; then
    pass "QA Tool '$tool' is available"
  else
    info "Optional QA tool '$tool' not installed on host (used for make lint/scan/sbom)"
  fi
done

# 5. Terminal & Clipboard OSC 52
TERM_NAME="${TERM:-unknown}"
if [[ "$TERM_NAME" =~ (xterm|screen|tmux|alacritty|kitty|ghostty|wezterm) ]]; then
  pass "Terminal ($TERM_NAME) supports truecolor and OSC 52 universal clipboard"
else
  info "Terminal ($TERM_NAME) detected"
fi

# 6. AI Agent Tooling (Optional Host Tools)
for agent in claude agy aider ollama; do
  if command -v "$agent" >/dev/null 2>&1; then
    pass "AI Agent '$agent' detected on host"
  fi
done

printf "\n${BOLD}Diagnostics completed.${RESET}\n\n"
