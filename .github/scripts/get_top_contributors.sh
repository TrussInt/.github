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

    count=$(echo "$response" | jq length)

    if [[ "$count" -eq 0 ]]; then
      break
    fi

    echo "$response" | jq -r '.[].author.login // empty' >> all_commits.txt
    page=$((page + 1))
  done
}

echo "$REPOS" | while read -r repo; do
  [[ -n "$repo" ]] && fetch_commits "$repo"
done

grep -v '^$' all_commits.txt \
  | sort \
  | uniq -c \
  | sort -nr \
  | head -n 5 \
  | awk '{print $2, $1}' \
  > top_contributors.txt