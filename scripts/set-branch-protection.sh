#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0 OR MIT
#
# set-branch-protection.sh — apply the langdev branch-protection ruleset to a
# repo's default branch via the GitHub API. Run by a maintainer (or CI actor)
# holding an admin-scoped token. Idempotent: re-running re-asserts the policy.
#
# It enables, on the target branch:
#   * required pull request before merge (with stale-review dismissal)
#   * required status checks: the CI jobs + the Scorecard analysis
#   * required *signed* commits
#   * required linear history
#   * force-push and branch-deletion blocked
#
# Usage:
#   scripts/set-branch-protection.sh [--repo owner/name] [--branch main] \
#                                    [--reviews N] [--enforce-admins] [--dry-run]
#
# Defaults: --repo from `gh repo view` (current repo), --branch main,
#           --reviews 1, admins NOT enforced (a solo owner keeps a break-glass
#           path; pass --enforce-admins to close it once a second maintainer
#           exists).
#
# Requires: gh (authenticated) OR GH_TOKEN/GITHUB_TOKEN in the environment.
set -euo pipefail

REPO=""
BRANCH="main"
REVIEWS="1"
ENFORCE_ADMINS="false"
DRY_RUN="0"

# Status-check contexts = the `name:` of each required job. Keep in sync with
# templates/github-workflows/ci.yml and scorecard.yml.
CONTEXTS=(
  "shellcheck"
  "hadolint"
  "bats + kcov (>=95%)"
  "build + trivy + sbom"
  "Scorecard analysis"
)

while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo)            REPO="$2"; shift 2 ;;
    --branch)          BRANCH="$2"; shift 2 ;;
    --reviews)         REVIEWS="$2"; shift 2 ;;
    --enforce-admins)  ENFORCE_ADMINS="true"; shift ;;
    --dry-run)         DRY_RUN="1"; shift ;;
    -h|--help)         grep '^#' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

if ! command -v gh >/dev/null 2>&1; then
  echo "error: gh (GitHub CLI) is required" >&2
  exit 127
fi

if [ -z "$REPO" ]; then
  REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner)"
fi
echo "Target: $REPO@$BRANCH  (reviews=$REVIEWS, enforce_admins=$ENFORCE_ADMINS)"

# Build the required_status_checks contexts JSON array.
contexts_json="$(printf '%s\n' "${CONTEXTS[@]}" | jq -R . | jq -s .)"

protection_body="$(jq -n \
  --argjson contexts "$contexts_json" \
  --argjson reviews "$REVIEWS" \
  --argjson admins "$ENFORCE_ADMINS" \
  '{
    required_status_checks: { strict: true, contexts: $contexts },
    enforce_admins: $admins,
    required_pull_request_reviews: {
      dismiss_stale_reviews: true,
      require_code_owner_reviews: true,
      required_approving_review_count: $reviews
    },
    restrictions: null,
    required_linear_history: true,
    allow_force_pushes: false,
    allow_deletions: false,
    block_creations: false,
    required_conversation_resolution: true
  }')"

if [ "$DRY_RUN" = "1" ]; then
  echo "--- DRY RUN: branch protection body ---"
  echo "$protection_body"
  echo "--- DRY RUN: would also PUT required_signatures ---"
  exit 0
fi

echo "Applying branch protection..."
printf '%s' "$protection_body" | gh api \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  "repos/$REPO/branches/$BRANCH/protection" \
  --input -

echo "Requiring signed commits..."
gh api \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  "repos/$REPO/branches/$BRANCH/protection/required_signatures" >/dev/null

echo "Done. Branch protection + required signatures applied to $REPO@$BRANCH."
