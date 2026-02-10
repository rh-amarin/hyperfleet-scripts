#!/bin/bash
# Search for cluster by name and set as current
source "$(dirname "$(realpath "$0")")/hf.lib.sh"

# Get name from argument or saved file
if [[ -n "${1:-}" ]]; then
    SEARCH_NAME="$1"
    hf_set_cluster_name "$SEARCH_NAME"
else
    SEARCH_NAME=$(hf_cluster_name) || exit 1
fi

hf_require_jq
hf_info "Searching for cluster: $SEARCH_NAME"

RESULT=$(hf_get "/clusters?search=name='$SEARCH_NAME'")
echo "$RESULT" | jq

COUNT=$(echo "$RESULT" | jq '.items | length')
if [[ "$COUNT" -eq 1 ]]; then
    CLUSTER_ID=$(echo "$RESULT" | jq -r '.items[0].id')
    hf_set_cluster_id "$CLUSTER_ID"
elif [[ "$COUNT" -gt 1 ]]; then
    hf_warn "Multiple clusters found. Use a more specific search."
else
    hf_warn "No clusters found matching '$SEARCH_NAME'"
fi
