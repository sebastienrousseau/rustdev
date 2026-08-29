#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0 OR MIT
# langdev test runner. Runs the bats suite under kcov and enforces a line
# coverage floor (default 95%). This is the gate CI's `coverage` job runs.
#
# Usage:
#   test/run.sh                 # bats + kcov, fail if coverage < 95%
#   COVERAGE_THRESHOLD=90 test/run.sh
#   test/run.sh --no-coverage   # just run bats (no kcov)
set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$TEST_DIR/.." && pwd)"
THRESHOLD="${COVERAGE_THRESHOLD:-95}"
COV_DIR="${COVERAGE_DIR:-$REPO_ROOT/coverage}"

if ! command -v bats >/dev/null 2>&1; then
  echo "error: bats not found — install bats-core (https://github.com/bats-core/bats-core)" >&2
  exit 127
fi

# Allow a plain run without the coverage gate (fast local iteration).
if [ "${1:-}" = "--no-coverage" ] || [ "${LANGDEV_NO_COVERAGE:-0}" = "1" ]; then
  exec bats --recursive "$TEST_DIR"
fi

if ! command -v kcov >/dev/null 2>&1; then
  echo "error: kcov not found — install kcov to measure coverage, or pass" >&2
  echo "       --no-coverage to run the suite without the gate." >&2
  exit 127
fi

rm -rf "$COV_DIR"
mkdir -p "$COV_DIR"

# kcov traces every bash subprocess bats spawns; --include-pattern narrows the
# report to the three scripts under test (stubs and bats internals excluded).
kcov \
  --clean \
  --include-pattern=bootstrap-dotfiles.sh,entrypoint.sh,langdev-sync,rust.sh,doctor.sh,explorer.sh,mcp-server.sh,ai-pack.sh,muxtree.sh,tmux-ide.sh \
  --exclude-pattern=/test/,/helpers/ \
  "$COV_DIR" \
  bats --recursive "$TEST_DIR"

# Prefer kcov's merged summary; fall back to the first coverage.json emitted.
summary="$(find "$COV_DIR" -name 'coverage.json' -path '*merged*' 2>/dev/null | head -n1)"
if [ -z "$summary" ]; then
  summary="$(find "$COV_DIR" -name 'coverage.json' 2>/dev/null | head -n1)"
fi
if [ -z "$summary" ]; then
  echo "error: kcov produced no coverage.json under $COV_DIR" >&2
  exit 1
fi

# coverage.json carries e.g. "percent_covered": "97.50"
pct="$(grep -o '"percent_covered"[[:space:]]*:[[:space:]]*"[0-9.]*"' "$summary" \
  | head -n1 | grep -o '[0-9.]\+' || true)"
if [ -z "$pct" ]; then
  echo "error: could not parse percent_covered from $summary" >&2
  exit 1
fi

echo "----------------------------------------------------------------"
printf 'line coverage: %s%%   (threshold: %s%%)\n' "$pct" "$THRESHOLD"
echo "report: $COV_DIR"
echo "----------------------------------------------------------------"

# Float comparison via awk (avoids bash integer-only arithmetic).
if awk -v p="$pct" -v t="$THRESHOLD" 'BEGIN { exit !(p + 0 >= t + 0) }'; then
  echo "coverage gate: PASS"
else
  echo "coverage gate: FAIL — line coverage ${pct}% is below ${THRESHOLD}%" >&2
  exit 1
fi
