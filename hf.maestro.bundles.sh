#!/bin/bash
# List maestro resource bundles
source "$(dirname "$(realpath "$0")")/hf.lib.sh"

curl -s "${HF_MAESTRO_HTTP_ENDPOINT}/api/maestro/v1/resource-bundles" | jq
