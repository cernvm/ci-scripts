#!/usr/bin/env bash
#
# Rerun all failing GitHub Actions workflow runs for a pull request's head
# commit. Only failed (and dependent) jobs are rerun via `gh run rerun --failed`,
# not entire runs from scratch.
#
# Usage:
#   ./rerun-failed-pr-checks.sh <pr-number> [repo]
#   ./rerun-failed-pr-checks.sh <pr-url>
#
# Examples:
#   ./rerun-failed-pr-checks.sh 4404 cvmfs/cvmfs
#   ./rerun-failed-pr-checks.sh https://github.com/cvmfs/cvmfs/pull/4404
#
set -euo pipefail

usage() {
  echo "Usage: $0 <pr-number-or-url> [repo]" >&2
  echo "  $0 4404 cvmfs/cvmfs" >&2
  echo "  $0 https://github.com/cvmfs/cvmfs/pull/4404" >&2
  exit 1
}

command -v gh >/dev/null 2>&1 || { echo "error: gh CLI not found" >&2; exit 1; }
[[ $# -ge 1 ]] || usage

pr_arg="$1"

if [[ "$pr_arg" =~ ^https://github\.com/([^/]+/[^/]+)/pull/([0-9]+) ]]; then
  repo="${BASH_REMATCH[1]}"
  pr_number="${BASH_REMATCH[2]}"
else
  pr_number="$pr_arg"
  repo="${2:-$(gh repo view --json nameWithOwner -q .nameWithOwner)}"
fi

echo "Repo: $repo   PR: #$pr_number"

head_sha="$(gh pr view "$pr_number" --repo "$repo" --json headRefOid -q .headRefOid)"
echo "Head commit: $head_sha"

# One workflow can produce multiple runs at the same SHA (re-triggers, matrix
# re-runs, etc). Grab the failing/cancelled/timed-out ones and dedupe run IDs.
mapfile -t failed_run_ids < <(
  gh run list --repo "$repo" --commit "$head_sha" -L 200 \
    --json databaseId,status,conclusion \
    -q '.[] | select(.status == "completed" and (.conclusion == "failure" or .conclusion == "cancelled" or .conclusion == "timed_out" or .conclusion == "startup_failure")) | .databaseId' \
  | sort -un
)

if [[ ${#failed_run_ids[@]} -eq 0 ]]; then
  echo "No failing workflow runs found for PR #$pr_number at $head_sha."
  exit 0
fi

echo "Found ${#failed_run_ids[@]} failing run(s); rerunning failed jobs:"
for run_id in "${failed_run_ids[@]}"; do
  echo "  -> gh run rerun $run_id --failed"
  gh run rerun "$run_id" --repo "$repo" --failed
done
