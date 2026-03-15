#!/bin/bash
# Show status table for all HyperFleet GitHub repositories
source "$(dirname "$(realpath "$0")")/hf.lib.sh"

hf_require_jq
command -v gh &>/dev/null || hf_die "gh (GitHub CLI) is required but not installed"

REPOS=(
  "https://github.com/openshift-hyperfleet/hyperfleet-api-spec"
  "https://github.com/openshift-hyperfleet/hyperfleet-api"
  "https://github.com/openshift-hyperfleet/hyperfleet-sentinel"
  "https://github.com/openshift-hyperfleet/hyperfleet-adapter"
  "https://github.com/openshift-hyperfleet/hyperfleet-infra"
  "https://github.com/openshift-hyperfleet/hyperfleet-e2e"
  "https://github.com/openshift-hyperfleet/architecture"
)

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

# Fetch all repos in parallel
for i in "${!REPOS[@]}"; do
  repo_url="${REPOS[$i]}"
  repo_path="${repo_url#https://github.com/}"
  (
    commit=$(gh api "repos/$repo_path/commits?per_page=1" \
      --jq '.[0].sha[0:7]' 2>/dev/null)
    [[ -z "$commit" ]] && commit="-"

    pr_json=$(gh api "repos/$repo_path/pulls?state=open&per_page=1" 2>/dev/null)
    pr_url=$(printf '%s' "$pr_json" | jq -r '.[0].html_url // "-"')
    pr_branch=$(printf '%s' "$pr_json" | jq -r '.[0].head.ref // "-"')

    printf '%s\t%s\t%s\t%s\n' "$repo_url" "$commit" "$pr_url" "$pr_branch" \
      > "$tmpdir/$i"
  ) &
done
wait

# Collect rows in original order
rows=()
rows+=("REPOSITORY	COMMIT	PR URL	PR BRANCH")
rows+=("---	---	---	---")
for i in "${!REPOS[@]}"; do
  rows+=("$(cat "$tmpdir/$i")")
done

printf '%s\n' "${rows[@]}" | awk \
  -v bold="$BOLD" -v cyan="$CYAN" -v nc="$NC" \
'BEGIN { FS = "\t" }
{
  row[NR] = $0
  n = split($0, f, "\t")
  if (n > ncols) ncols = n
  for (i = 1; i <= n; i++) {
    w = length(f[i])
    if (w > cw[i]) cw[i] = w
  }
}
END {
  for (r = 1; r <= NR; r++) {
    n = split(row[r], f, "\t")
    is_header = (r == 1)
    for (i = 1; i <= ncols; i++) {
      cell = (i <= n) ? f[i] : ""
      pad  = cw[i] - length(cell)
      if (is_header) display = bold cyan cell nc
      else           display = cell
      if (i < ncols) printf "%s%*s  ", display, pad, ""
      else           printf "%s", display
    }
    printf "\n"
  }
}'
