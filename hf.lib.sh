#!/bin/bash
#
# hf.lib.sh - Shared library for HyperFleet scripts
# Source this file in your hf.* scripts:
#   source "$(dirname "$(realpath "$0")")/hf.lib.sh"
#

# ============================================================================
# Configuration
# ============================================================================

HF_CONFIG_DIR="${HF_CONFIG_DIR:-$HOME/.config/hf}"

# Ensure config directory exists
mkdir -p "$HF_CONFIG_DIR"

# Helper to load value from file if env var is not set
_hf_load() {
  local var="$1" file="$2" default="${3:-}"
  if [[ -z "${!var:-}" ]]; then
    if [[ -f "$file" ]]; then
      printf -v "$var" '%s' "$(cat "$file")"
    else
      printf -v "$var" '%s' "$default"
    fi
  fi
}

# Config file paths
HF_API_URL_FILE="$HF_CONFIG_DIR/api-url"
HF_API_VERSION_FILE="$HF_CONFIG_DIR/api-version"
HF_TOKEN_FILE="$HF_CONFIG_DIR/token"
HF_CONTEXT_FILE="$HF_CONFIG_DIR/context"
HF_NAMESPACE_FILE="$HF_CONFIG_DIR/namespace"
HF_GCP_PROJECT_FILE="$HF_CONFIG_DIR/gcp-project"
HF_CLUSTER_ID_FILE="$HF_CONFIG_DIR/cluster-id"
HF_CLUSTER_NAME_FILE="$HF_CONFIG_DIR/cluster-name"
HF_DB_HOST_FILE="$HF_CONFIG_DIR/db-host"
HF_DB_PORT_FILE="$HF_CONFIG_DIR/db-port"
HF_DB_NAME_FILE="$HF_CONFIG_DIR/db-name"
HF_DB_USER_FILE="$HF_CONFIG_DIR/db-user"
HF_DB_PASSWORD_FILE="$HF_CONFIG_DIR/db-password"

# Load config from files (env vars take precedence)
_hf_load HF_API_URL "$HF_API_URL_FILE" "http://localhost:8000"
_hf_load HF_API_VERSION "$HF_API_VERSION_FILE" "v1"
_hf_load HF_TOKEN "$HF_TOKEN_FILE" ""
_hf_load HF_KUBE_CONTEXT "$HF_CONTEXT_FILE" ""
_hf_load HF_KUBE_NAMESPACE "$HF_NAMESPACE_FILE" ""
_hf_load HF_GCP_PROJECT "$HF_GCP_PROJECT_FILE" "hcm-hyperfleet"
_hf_load HF_DB_HOST "$HF_DB_HOST_FILE" "localhost"
_hf_load HF_DB_PORT "$HF_DB_PORT_FILE" "5432"
_hf_load HF_DB_NAME "$HF_DB_NAME_FILE" ""
_hf_load HF_DB_USER "$HF_DB_USER_FILE" ""
_hf_load HF_DB_PASSWORD "$HF_DB_PASSWORD_FILE" ""

# ============================================================================
# Colors
# ============================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ============================================================================
# Logging
# ============================================================================

hf_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
hf_warn() { echo -e "${YELLOW}[WARN]${NC} $1" >&2; }
hf_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
hf_debug() { [[ -n "${HF_DEBUG:-}" ]] && echo -e "${CYAN}[DEBUG]${NC} $1"; }

hf_die() {
  hf_error "$1"
  exit 1
}

# ============================================================================
# Cluster ID Management
# ============================================================================

# Get cluster ID from argument, file, or fail
hf_cluster_id() {
  local id="${1:-}"
  if [[ -n "$id" ]]; then
    echo "$id"
  elif [[ -f "$HF_CLUSTER_ID_FILE" ]]; then
    cat "$HF_CLUSTER_ID_FILE"
  else
    hf_die "No cluster ID specified and none saved. Use hf.cluster.search.sh to set one."
  fi
}

# Save cluster ID to file
hf_set_cluster_id() {
  echo "$1" >"$HF_CLUSTER_ID_FILE"
  hf_info "Current cluster set to: $1"
}

# Get cluster name from argument or file
hf_cluster_name() {
  local name="${1:-}"
  if [[ -n "$name" ]]; then
    echo "$name"
  elif [[ -f "$HF_CLUSTER_NAME_FILE" ]]; then
    cat "$HF_CLUSTER_NAME_FILE"
  else
    hf_die "No cluster name specified and none saved."
  fi
}

# Save cluster name to file
hf_set_cluster_name() {
  echo "$1" >"$HF_CLUSTER_NAME_FILE"
  hf_debug "Cluster name saved: $1"
}

# ============================================================================
# Config Setters
# ============================================================================

# Generic setter: saves value to file and updates variable
_hf_set() {
  local var="$1" file="$2" value="$3" label="$4"
  echo "$value" >"$file"
  printf -v "$var" '%s' "$value"
  hf_info "$label set to: $value"
}

# Generic clear: removes file and clears variable
_hf_clear() {
  local var="$1" file="$2" label="$3"
  rm -f "$file"
  printf -v "$var" '%s' ""
  hf_info "$label cleared"
}

hf_set_context() { _hf_set HF_KUBE_CONTEXT "$HF_CONTEXT_FILE" "$1" "Context"; }
hf_set_namespace() { _hf_set HF_KUBE_NAMESPACE "$HF_NAMESPACE_FILE" "$1" "Namespace"; }
hf_set_api_url() { _hf_set HF_API_URL "$HF_API_URL_FILE" "$1" "API URL"; }
hf_set_api_version() { _hf_set HF_API_VERSION "$HF_API_VERSION_FILE" "$1" "API version"; }
hf_set_token() { _hf_set HF_TOKEN "$HF_TOKEN_FILE" "$1" "Token"; }
hf_set_gcp_project() { _hf_set HF_GCP_PROJECT "$HF_GCP_PROJECT_FILE" "$1" "GCP project"; }
hf_set_db_host() { _hf_set HF_DB_HOST "$HF_DB_HOST_FILE" "$1" "DB host"; }
hf_set_db_port() { _hf_set HF_DB_PORT "$HF_DB_PORT_FILE" "$1" "DB port"; }
hf_set_db_name() { _hf_set HF_DB_NAME "$HF_DB_NAME_FILE" "$1" "DB name"; }
hf_set_db_user() { _hf_set HF_DB_USER "$HF_DB_USER_FILE" "$1" "DB user"; }
hf_set_db_password() { _hf_set HF_DB_PASSWORD "$HF_DB_PASSWORD_FILE" "$1" "DB password"; }

hf_clear_context() { _hf_clear HF_KUBE_CONTEXT "$HF_CONTEXT_FILE" "Context"; }
hf_clear_namespace() { _hf_clear HF_KUBE_NAMESPACE "$HF_NAMESPACE_FILE" "Namespace"; }

# ============================================================================
# API Helpers
# ============================================================================

# Get API base URL
hf_api_base() {
  echo "${HF_API_URL}/api/hyperfleet/${HF_API_VERSION}"
}

# Make an API request
# Usage: hf_api GET /clusters
#        hf_api POST /clusters "$json_payload"
hf_api() {
  local method="$1"
  local endpoint="$2"
  local data="${3:-}"

  local url="$(hf_api_base)${endpoint}"
  local curl_args=(
    -X "$method"
    --http1.1
    -s
    -H 'Accept: application/json'
  )

  if [[ -n "$HF_TOKEN" ]]; then
    curl_args+=(-H "Authorization: Bearer $HF_TOKEN")
  fi

  if [[ -n "$data" ]]; then
    curl_args+=(-H 'Content-Type: application/json')
    curl_args+=(-d "$data")
  fi

  hf_debug "API: $method $url"
  curl "${curl_args[@]}" "$url"
}

# Shorthand for common API methods
hf_get() { hf_api GET "$1"; }
hf_post() { hf_api POST "$1" "$2"; }
hf_delete() { hf_api DELETE "$1"; }

# ============================================================================
# Requirement Checks
# ============================================================================

hf_require_jq() {
  command -v jq &>/dev/null || hf_die "jq is required but not installed"
}

hf_require_kubectl() {
  command -v kubectl &>/dev/null || hf_die "kubectl is required but not installed"
}

hf_require_gcloud() {
  command -v gcloud &>/dev/null || hf_die "gcloud is required but not installed"
}

hf_require_viddy() {
  command -v viddy &>/dev/null || hf_die "viddy is required for watch mode but not installed"
}

hf_require_psql() {
  command -v psql &>/dev/null || hf_die "psql (PostgreSQL client) is required but not installed"
}

# ============================================================================
# Kubernetes Helpers
# ============================================================================

# Get kubectl with context if set
hf_kubectl() {
  if [[ -n "$HF_KUBE_CONTEXT" ]]; then
    kubectl --context="$HF_KUBE_CONTEXT" "$@"
  else
    kubectl "$@"
  fi
}

# Get kubectl with context and namespace if set
hf_kubectl_ns() {
  if [[ -n "$HF_KUBE_CONTEXT" ]] && [[ -n "$HF_KUBE_NAMESPACE" ]]; then
    kubectl --context="$HF_KUBE_CONTEXT" -n "$HF_KUBE_NAMESPACE" "$@"
  elif [[ -n "$HF_KUBE_NAMESPACE" ]]; then
    kubectl -n "$HF_KUBE_NAMESPACE" "$@"
  else
    kubectl "$@"
  fi
}

# Find postgres pod
hf_find_postgres_pod() {
  hf_require_kubectl
  [[ -z "$HF_KUBE_CONTEXT" ]] && hf_die "HF_KUBE_CONTEXT not set"
  [[ -z "$HF_KUBE_NAMESPACE" ]] && hf_die "HF_KUBE_NAMESPACE not set"

  local pod
  pod=$(hf_kubectl_ns get pods -o name 2>/dev/null | grep -i postgres | head -1 | sed 's|pod/||')
  [[ -z "$pod" ]] && hf_die "Could not find postgres pod in namespace $HF_KUBE_NAMESPACE"
  echo "$pod"
}

# ============================================================================
# Script Info
# ============================================================================

# Print script usage header
hf_usage() {
  local script_name
  script_name=$(basename "$0")
  echo -e "${BOLD}Usage:${NC} $script_name $1"
  echo ""
}
