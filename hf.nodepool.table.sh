#!/bin/bash
# List all NodePools for the current cluster in table format
# Usage: hf.nodepool.table.sh [cluster_id]
source "$(dirname "$(realpath "$0")")/hf.lib.sh"
hf_require_config api-url api-version cluster-id

hf_require_jq
CLUSTER_ID=$(hf_cluster_id "${1:-}")

hf_get "/clusters/${CLUSTER_ID}/nodepools" | jq -r '
  # Collect all unique condition types across all nodepools
  ([.items[].status.conditions[]?.type] | unique) as $types |

  # Store items for later use
  .items as $items |

  # Build header row
  (["ID", "NAME", "REPLICAS", "TYPE"] + $types | @tsv),

  # Build separator row
  (["---", "---", "---", "---"] + ($types | map("---")) | @tsv),

  # Build data rows
  ($items[] | . as $np |
    [.id, .name, (.spec.replicas | tostring), (.spec.platform.type // "-")] +
    [$types[] as $t | (($np.status.conditions // []) | map(select(.type == $t)) | .[0].status |
      if . == "True" then "##GRN##"
      elif . == "False" then "##RED##"
      elif . == "Unknown" then "##YLW##"
      elif . == "" or . == null then "-"
      else . end)]
    | @tsv
  )
' | column -t -s $'\t' | sed \
    -e "s/##GRN##/${GREEN}●${NC}/g" \
    -e "s/##RED##/${RED}●${NC}/g" \
    -e "s/##YLW##/${YELLOW}●${NC}/g"
