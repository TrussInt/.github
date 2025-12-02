#!/usr/bin/env bash
set -euo pipefail

TABLE="| Rank | Contributor | Commits |\n|------|-------------|----------|\n"
rank=1

while read -r user commits; do
  TABLE="${TABLE}| ${rank} | @${user} | ${commits} |\n"
  rank=$((rank+1))
done < top_contributors.txt

awk -v table="$TABLE" '
  /<!-- TOP_CONTRIBUTORS_START -->/ {
    print "<!-- TOP_CONTRIBUTORS_START -->"
    print table
    skip=1
    next
  }
  /<!-- TOP_CONTRIBUTORS_END -->/ {
    print "<!-- TOP_CONTRIBUTORS_END -->"
    skip=0
    next
  }
  !skip { print }
' profile/README.md > profile/README.tmp

mv profile/README.tmp profile/README.md