#!/usr/bin/env bash
set -uo pipefail

if [[ -z "${ACTIONS_PAT:-}" ]]; then
  echo "ERROR: ACTIONS_PAT is not set."
  exit 1
fi

SINCE_DATE=$(date -u -d '1 month ago' +'%Y-%m-%dT%H:%M:%SZ')
> all_commits.txt

get_default_branch() {
  local repo="$1"
  http_code_dev=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: Bearer $ACTIONS_PAT" \
    "https://api.github.com/repos/$repo/branches/dev")
  if [[ "$http_code_dev" == "200" ]]; then
    echo "dev"
    return 0
  fi

  http_code_main=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: Bearer $ACTIONS_PAT" \
    "https://api.github.com/repos/$repo/branches/main")
  if [[ "$http_code_main" == "200" ]]; then
    echo "main"
    return 0
  fi

  echo "WARNING: No dev or main branch found for $repo or missing permissions" >&2
  return 1
}

fetch_commits() {
  local repo=$1
  local TARGET_BRANCH
  TARGET_BRANCH=$(get_default_branch "$repo") || { echo "Skipping $repo"; return 0; }

  local page=1

  while :; do
    response=$(curl -s \
      -H "Authorization: Bearer $ACTIONS_PAT" \
      "https://api.github.com/repos/${repo}/commits?sha=${TARGET_BRANCH}&since=${SINCE_DATE}&per_page=100&page=${page}")

    if ! echo "$response" | jq -e 'type=="array"' >/dev/null 2>&1; then
      echo "Skipping $repo (page $page). GitHub returned non-array:"
      echo "$response"
      break
    fi

    count=$(echo "$response" | jq length)
    [[ "$count" -eq 0 ]] && break

    # Extract authors safely
    echo "$response" | jq -r '.[].author.login // empty' >> all_commits.txt

    page=$((page + 1))
  done
  return 0
}

echo "$REPOS" | while read -r repo; do
  if [[ -n "$repo" ]]; then
    fetch_commits "$repo" || echo "Skip $repo, error ignored"
  fi
done

grep -v '^$' all_commits.txt \
  | sort | uniq -c | sort -nr | head -n 5 \
  | awk '{print $2, $1}' \
  > top_contributors.txt
