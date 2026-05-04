#!/bin/bash
# Show NodePool adapter statuses in table format (Available and Finalized only)
# Usage: hf.nodepool.statuses.table.sh [nodepool_id]
source "$(dirname "$(realpath "$0")")/hf.lib.sh"
hf_require_config api-url api-version cluster-id nodepool-id

hf_require_jq
CLUSTER_ID=$(hf_cluster_id)

NODEPOOL_ARG=""
for arg in "$@"; do
  [[ "$arg" != "-w" ]] && NODEPOOL_ARG="$arg"
done

NODEPOOL_ID=$(hf_nodepool_id "$NODEPOOL_ARG")
URL="${HF_API_URL}/api/hyperfleet/${HF_API_VERSION}/clusters/${CLUSTER_ID}/nodepools/${NODEPOOL_ID}/statuses"

hf_info "Getting statuses table for nodepool: $NODEPOOL_ID"

GREEN=$(printf '\033[32m')
RED=$(printf '\033[31m')
YELLOW=$(printf '\033[33m')
RESET=$(printf '\033[0m')

curl -s "$URL" | jq -r '
  def cond(t):
    map(select(.type == t)) | .[0].status // "-" |
    if . == "True" then ""
    elif . == "False" then ""
    elif . == "Unknown" then ""
    else . end;
  (["ADAPTER", "GEN", "Available", "Finalized"] | @tsv),
  (["---", "---", "---", "---"] | @tsv),
  (.items[] | [
    .adapter,
    (.observed_generation // 0 | tostring),
    (.conditions | cond("Available")),
    (.conditions | cond("Finalized"))
  ] | @tsv)
' | awk -v green="$GREEN" -v red="$RED" -v yellow="$YELLOW" -v reset="$RESET" '
BEGIN { FS = "\t" }
{
  row[NR] = $0
  n = split($0, f, "\t")
  if (n > ncols) ncols = n
  for (i = 1; i <= n; i++) {
    cell = f[i]
    if      (cell == "\001") dw = 4
    else if (cell == "\002") dw = 5
    else if (cell == "\003") dw = 7
    else                     dw = length(cell)
    if (dw > cw[i]) cw[i] = dw
  }
}
END {
  for (r = 1; r <= NR; r++) {
    n = split(row[r], f, "\t")
    for (i = 1; i <= ncols; i++) {
      cell = (i <= n) ? f[i] : ""
      if      (cell == "\001") { display = green "True"    reset; dw = 4 }
      else if (cell == "\002") { display = red   "False"   reset; dw = 5 }
      else if (cell == "\003") { display = yellow "Unknown" reset; dw = 7 }
      else                     { display = cell;                   dw = length(cell) }
      pad = cw[i] - dw
      if (i < ncols) printf "%s%*s  ", display, pad, ""
      else           printf "%s\n", display
    }
  }
}'
