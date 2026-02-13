#!/bin/bash
# List all clusters in table format
source "$(dirname "$(realpath "$0")")/hf.lib.sh"

hf_require_jq

# Color codes
GREEN=$(printf '\033[32m')
RED=$(printf '\033[31m')
YELLOW=$(printf '\033[33m')
RESET=$(printf '\033[0m')

hf_get "/clusters" | jq -r '
  # Collect all unique condition types across all clusters
  ([.items[].status.conditions[].type] | unique) as $types |

  # Store items for later use
  .items as $items |

  # Build header row
  (["ID", "NAME"] + $types | @tsv),

  # Build separator row
  (["---", "---"] + ($types | map("---")) | @tsv),

  # Build data rows
  ($items[] | . as $cluster |
    [.id, .name] + [$types[] as $t | ($cluster.status.conditions | map(select(.type == $t)) | .[0].status |
      if . == "True" then "##GRN##"
      elif . == "False" then "##RED##"
      elif . == "Unknown" then "##YLW##"
      elif . == "" or . == null then "-"
      else . end)]
    | @tsv
  )
' | column -t -s $'\t' | sed \
    -e "s/##GRN##/${GREEN}●${RESET}/g" \
    -e "s/##RED##/${RED}●${RESET}/g" \
    -e "s/##YLW##/${YELLOW}●${RESET}/g"
