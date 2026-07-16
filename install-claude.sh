#!/usr/bin/env bash
# Onboard a repo to the central Claude workflows (sebko/github-actions).
#
# Run it from INSIDE a local clone of the target repo:
#     cd ~/github/some-repo
#     ~/github/github-actions/install-claude.sh
#
# It: writes the two ~8-line caller workflows, creates the `skip-review` label,
# and checks that the CLAUDE_CODE_OAUTH_TOKEN secret exists (setting it if you
# export CLAUDE_CODE_OAUTH_TOKEN first). It does NOT commit — review, then commit.
set -euo pipefail

command -v gh >/dev/null || { echo "gh CLI required"; exit 1; }
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "run inside a git repo"; exit 1; }

REPO="$(gh repo view --json nameWithOwner -q .nameWithOwner)"
echo "Onboarding: $REPO"

# 1. Caller workflows (the only files that land in the repo; they never change).
mkdir -p .github/workflows

cat > .github/workflows/claude-code-review.yml <<'YAML'
name: Claude Code Review

on:
  pull_request:
    types: [opened, ready_for_review, reopened]

jobs:
  review:
    uses: sebko/github-actions/.github/workflows/claude-review.yml@v1
    secrets: inherit
YAML

cat > .github/workflows/claude.yml <<'YAML'
name: Claude Code

on:
  issue_comment:
    types: [created]
  pull_request_review_comment:
    types: [created]
  issues:
    types: [opened, assigned]
  pull_request_review:
    types: [submitted]

jobs:
  claude:
    uses: sebko/github-actions/.github/workflows/claude-mention.yml@v1
    secrets: inherit
YAML
echo "  ✓ wrote .github/workflows/{claude-code-review,claude}.yml"

# 2. skip-review label (idempotent).
gh label create "skip-review" \
  --color BFD4F2 \
  --description "Opt this PR out of the automated Claude review" \
  --force >/dev/null
echo "  ✓ ensured 'skip-review' label"

# 3. Auth secret. Set it if you exported CLAUDE_CODE_OAUTH_TOKEN, else just report.
if gh secret list --json name -q '.[].name' 2>/dev/null | grep -qx CLAUDE_CODE_OAUTH_TOKEN; then
  echo "  ✓ CLAUDE_CODE_OAUTH_TOKEN already set"
elif [ -n "${CLAUDE_CODE_OAUTH_TOKEN:-}" ]; then
  gh secret set CLAUDE_CODE_OAUTH_TOKEN --body "$CLAUDE_CODE_OAUTH_TOKEN" >/dev/null
  echo "  ✓ set CLAUDE_CODE_OAUTH_TOKEN from env"
else
  echo "  ! CLAUDE_CODE_OAUTH_TOKEN not set. Get a token with:  claude setup-token"
  echo "    then re-run with:  CLAUDE_CODE_OAUTH_TOKEN=<token> $0"
fi

echo "Done. Review, then: git add .github/workflows && git commit -m 'ci: Claude review + mentions' && push."
