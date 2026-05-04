#!/bin/bash
# List all clusters in table format
source "$(dirname "$(realpath "$0")")/hf.lib.sh"
hf_require_config api-url api-version

hf_require_jq

GREEN=$(printf '\033[32m')
RED=$(printf '\033[31m')
YELLOW=$(printf '\033[33m')
RESET=$(printf '\033[0m')

CLUSTERS=$(hf_get "/clusters")

STATUSES_MAP='{}'
while IFS= read -r ID; do
  S=$(hf_get "/clusters/$ID/statuses" 2>/dev/null || echo '{"items":[]}')
  STATUSES_MAP=$(jq -n --argjson m "$STATUSES_MAP" --arg id "$ID" --argjson s "$S" \
    '$m + {($id): ($s.items // [])}')
done < <(echo "$CLUSTERS" | jq -r '.items[].id')

jq -n -r \
  --argjson clusters "$CLUSTERS" \
  --argjson statuses "$STATUSES_MAP" \
  --arg green "$GREEN" --arg red "$RED" --arg yellow "$YELLOW" --arg reset "$RESET" '
  $clusters.items as $items |

  # Condition types from status.conditions (aggregate: Ready, Reconciled, Available, etc.)
  ([$clusters.items[].status.conditions[].type] | unique | map(select(endswith("Successful") | not))) as $ctypes |

  # Adapter names from statuses
  ([($statuses | to_entries[].value[]) | .adapter] | unique) as $adapters |

  # Build header row
  (["ID", "NAME", "GEN"] + $ctypes + $adapters | @tsv),

  # Build separator row
  (["---", "---", "---"] + ($ctypes | map("---")) + ($adapters | map("---")) | @tsv),

  # Build data rows
  ($items[] |
    . as $cluster |
    ($statuses[$cluster.id] // []) as $cstatus |
    (if $cluster.deleted_time != null then "Finalized" else "Available" end) as $ctype |

    [.id, .name, ((.generation // 0 | tostring) + (if .deleted_time != null then "\u0004" else "" end))] +

    # Condition columns from status.conditions
    [$ctypes[] as $t |
      ($cluster.status.conditions | map(select(.type == $t)) | .[0]) as $cond |
      if $cond == null then "-"
      else
        ($cond.observed_generation | if . != null then tostring else "" end) as $gen |
        if   $cond.status == "True"    then "" + $gen
        elif $cond.status == "False"   then "" + $gen
        elif $cond.status == "Unknown" then "" + $gen
        elif $cond.status == "" or $cond.status == null then "-"
        else $cond.status end
      end] +

    # Adapter columns from statuses
    [$adapters[] as $a |
      ($cstatus | map(select(.adapter == $a)) | .[0]) as $astat |
      if $astat == null then "-"
      else
        ($astat.observed_generation | if . != null then tostring else "" end) as $gen |
        ($astat.conditions | map(select(.type == $ctype)) | .[0].status) as $s |
        if   $s == "True"    then "" + $gen
        elif $s == "False"   then "" + $gen
        elif $s == "Unknown" then "" + $gen
        elif $s == null      then "-"
        else $s end
      end]
    | @tsv
  )
' | awk -v green="$GREEN" -v red="$RED" -v yellow="$YELLOW" -v reset="$RESET" '
BEGIN { FS = "\t" }
function dw(cell,    c, gen, pos) {
  c = substr(cell, 1, 1)
  if (c == "\001" || c == "\002" || c == "\003") {
    gen = substr(cell, 2)
    return 1 + (gen != "" ? 1 + length(gen) : 0)
  }
  pos = index(cell, "\004")
  if (pos > 0) return (pos - 1) + 3
  return length(cell)
}
function render(cell,    c, gen, pos) {
  c = substr(cell, 1, 1)
  if (c == "\001") { gen = substr(cell, 2); return green "●" reset (gen != "" ? " " gen : "") }
  if (c == "\002") { gen = substr(cell, 2); return red   "●" reset (gen != "" ? " " gen : "") }
  if (c == "\003") { gen = substr(cell, 2); return yellow "●" reset (gen != "" ? " " gen : "") }
  pos = index(cell, "\004")
  if (pos > 0) return substr(cell, 1, pos - 1) " " red "❌" reset
  return cell
}
{
  row[NR] = $0
  n = split($0, f, "\t")
  if (n > ncols) ncols = n
  for (i = 1; i <= n; i++) {
    w = dw(f[i])
    if (w > cw[i]) cw[i] = w
  }
}
END {
  for (r = 1; r <= NR; r++) {
    n = split(row[r], f, "\t")
    for (i = 1; i <= ncols; i++) {
      cell = (i <= n) ? f[i] : ""
      pad = cw[i] - dw(cell)
      if (i < ncols) printf "%s%*s  ", render(cell), pad, ""
      else           printf "%s", render(cell)
    }
    printf "\n"
  }
}'
