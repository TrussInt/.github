#!/usr/bin/env bash
set -euo pipefail

SINCE_DATE=$(date -u -d '1 month ago' +'%Y-%m-%dT%H:%M:%SZ')
> all_commits.txt

fetch_commits() {
  local repo=$1
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
}

echo "$REPOS" | while read -r repo; do
  [[ -n "$repo" ]] && fetch_commits "$repo"
done

grep -v '^$' all_commits.txt \
  | sort | uniq -c | sort -nr | head -n 5 \
  | awk '{print $2, $1}' \
  > top_contributors.txt