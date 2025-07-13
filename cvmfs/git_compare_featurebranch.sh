#!/usr/bin/env bash
#
# compare-feature-with-main.sh
#
# Usage:
#   ./compare-feature-with-main.sh <feature-branch> [main-branch]
#
# Example:
#   ./compare-feature-with-main.sh feature/login-refactor main
#
# Exit codes:
#   0  : Success
#   1  : Bad arguments or git failure

# Helper: strip bracket-tags like “[rpm]” and PR markers like “(#3738)”
strip_meta() {
  sed -E -e 's/\[[^][]+\]//g' \
         -e 's/[[:space:]]*\(#[0-9]+\)//g' \
         -e 's/^[[:space:]]+//; s/[[:space:]]+$//'
}


set -euo pipefail

feature_branch="${1:-}"
main_branch="${2:-devel}"

if [[ -z "${feature_branch}" ]]; then
  echo "Usage: $0 <feature-branch> [main-branch]" >&2
  exit 1
fi

# Ensure both branches exist locally
git rev-parse --verify "${feature_branch}" >/dev/null
git rev-parse --verify "${main_branch}"    >/dev/null

# 1. Determine merge-base
merge_base="$(git merge-base "${main_branch}" "${feature_branch}")"

echo "Merge-base: ${merge_base}"

# 2. Obtain commit list unique to the feature branch (newest first)
feature_commits=()
while IFS= read -r sha; do
  feature_commits+=("${sha}")
done < <(git rev-list --reverse "${main_branch}..${feature_branch}")

echo "Commits unique to ${feature_branch}: ${#feature_commits[@]}"

# 3. Check each commit title against main branch history
echo
printf '%-12s | %-8s | %s\n' "Commit SHA" "In main?" "Title"
printf '%.0s-' {1..80}
echo

for sha in "${feature_commits[@]}"; do
  raw_title="$(git log -n1 --format='%s' "${sha}")"
  title="$(strip_meta <<< "${raw_title}")"

  # Look for an exact-string match for the title in main’s log
  git log "${main_branch}" --grep="${title}" > /tmp/gitlog;
  if [ -s /tmp/gitlog ]; then
    present="yes"
  else
    present="no"
  fi

  printf '%-12s | %-8s | %s\n' "${sha:0:12}" "${present}" "${raw_title}"
done

