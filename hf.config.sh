#!/bin/bash
# Show or set HyperFleet configuration
# Usage: hf.config.sh [show|set|clear] [key] [value]
source "$(dirname "$(realpath "$0")")/hf.lib.sh"

show_config() {
    echo -e "${BOLD}HyperFleet Configuration${NC}"
    echo ""
    echo "  Config dir: $HF_CONFIG_DIR"
    echo ""
    echo "  api-url:      ${HF_API_URL:-<not set>}"
    echo "  api-version:  ${HF_API_VERSION:-<not set>}"
    echo "  token:        ${HF_TOKEN:+<set>}${HF_TOKEN:-<not set>}"
    echo "  context:      ${HF_KUBE_CONTEXT:-<not set>}"
    echo "  namespace:    ${HF_KUBE_NAMESPACE:-<not set>}"
    echo "  gcp-project:  ${HF_GCP_PROJECT:-<not set>}"
    echo "  cluster-id:   $(cat "$HF_CLUSTER_ID_FILE" 2>/dev/null || echo '<not set>')"
    echo "  cluster-name: $(cat "$HF_CLUSTER_NAME_FILE" 2>/dev/null || echo '<not set>')"
    echo ""
    echo -e "${BOLD}Maestro Configuration${NC}"
    echo ""
    echo "  maestro-consumer:       ${HF_MAESTRO_CONSUMER:-<not set>}"
    echo "  maestro-http-endpoint:  ${HF_MAESTRO_HTTP_ENDPOINT:-<not set>}"
    echo "  maestro-grpc-endpoint:  ${HF_MAESTRO_GRPC_ENDPOINT:-<not set>}"
    echo "  maestro-namespace:      ${HF_MAESTRO_NAMESPACE:-<not set>}"
    echo ""
    echo ""
    echo -e "${BOLD}Port Forward Configuration${NC}"
    echo ""
    echo "  pf-api-port:            ${HF_PF_API_PORT:-<not set>}"
    echo "  pf-pg-port:             ${HF_PF_PG_PORT:-<not set>}"
    echo "  pf-maestro-http-port:   ${HF_PF_MAESTRO_HTTP_PORT:-<not set>}"
    echo "  pf-maestro-http-remote: ${HF_PF_MAESTRO_HTTP_REMOTE_PORT:-<not set>}"
    echo "  pf-maestro-grpc-port:   ${HF_PF_MAESTRO_GRPC_PORT:-<not set>}"
    echo ""
    echo -e "${BOLD}Database Configuration${NC}"
    echo ""
    echo "  db-host:      ${HF_DB_HOST:-<not set>}"
    echo "  db-port:      ${HF_DB_PORT:-<not set>}"
    echo "  db-name:      ${HF_DB_NAME:-<not set>}"
    echo "  db-user:      ${HF_DB_USER:-<not set>}"
    echo "  db-password:  ${HF_DB_PASSWORD:+<set>}${HF_DB_PASSWORD:-<not set>}"
}

set_config() {
    local key="$1" value="$2"
    [[ -z "$key" ]] && hf_die "Usage: hf.config.sh set <key> <value>"
    [[ -z "$value" ]] && hf_die "Usage: hf.config.sh set <key> <value>"

    case "$key" in
        api-url)      hf_set_api_url "$value" ;;
        api-version)  hf_set_api_version "$value" ;;
        token)        hf_set_token "$value" ;;
        context)      hf_set_context "$value" ;;
        namespace)    hf_set_namespace "$value" ;;
        gcp-project)  hf_set_gcp_project "$value" ;;
        cluster-id)   hf_set_cluster_id "$value" ;;
        cluster-name) hf_set_cluster_name "$value" ;;
        maestro-consumer)       hf_set_maestro_consumer "$value" ;;
        maestro-http-endpoint)  hf_set_maestro_http_endpoint "$value" ;;
        maestro-grpc-endpoint)  hf_set_maestro_grpc_endpoint "$value" ;;
        maestro-namespace)      hf_set_maestro_namespace "$value" ;;
        pf-api-port)            hf_set_pf_api_port "$value" ;;
        pf-pg-port)             hf_set_pf_pg_port "$value" ;;
        pf-maestro-http-port)   hf_set_pf_maestro_http_port "$value" ;;
        pf-maestro-http-remote-port) hf_set_pf_maestro_http_remote_port "$value" ;;
        pf-maestro-grpc-port)   hf_set_pf_maestro_grpc_port "$value" ;;
        db-host)      hf_set_db_host "$value" ;;
        db-port)      hf_set_db_port "$value" ;;
        db-name)      hf_set_db_name "$value" ;;
        db-user)      hf_set_db_user "$value" ;;
        db-password)  hf_set_db_password "$value" ;;
        *)            hf_die "Unknown config key: $key" ;;
    esac
}

clear_config() {
    local key="$1"
    [[ -z "$key" ]] && hf_die "Usage: hf.config.sh clear <key>"

    case "$key" in
        api-url)      rm -f "$HF_API_URL_FILE" && hf_info "api-url cleared" ;;
        api-version)  rm -f "$HF_API_VERSION_FILE" && hf_info "api-version cleared" ;;
        token)        rm -f "$HF_TOKEN_FILE" && hf_info "token cleared" ;;
        context)      hf_clear_context ;;
        namespace)    hf_clear_namespace ;;
        gcp-project)  rm -f "$HF_GCP_PROJECT_FILE" && hf_info "gcp-project cleared" ;;
        cluster-id)   rm -f "$HF_CLUSTER_ID_FILE" && hf_info "cluster-id cleared" ;;
        cluster-name) rm -f "$HF_CLUSTER_NAME_FILE" && hf_info "cluster-name cleared" ;;
        maestro-consumer)       rm -f "$HF_MAESTRO_CONSUMER_FILE" && hf_info "maestro-consumer cleared" ;;
        maestro-http-endpoint)  rm -f "$HF_MAESTRO_HTTP_ENDPOINT_FILE" && hf_info "maestro-http-endpoint cleared" ;;
        maestro-grpc-endpoint)  rm -f "$HF_MAESTRO_GRPC_ENDPOINT_FILE" && hf_info "maestro-grpc-endpoint cleared" ;;
        maestro-namespace)      rm -f "$HF_MAESTRO_NAMESPACE_FILE" && hf_info "maestro-namespace cleared" ;;
        pf-api-port)            rm -f "$HF_PF_API_PORT_FILE" && hf_info "pf-api-port cleared" ;;
        pf-pg-port)             rm -f "$HF_PF_PG_PORT_FILE" && hf_info "pf-pg-port cleared" ;;
        pf-maestro-http-port)   rm -f "$HF_PF_MAESTRO_HTTP_PORT_FILE" && hf_info "pf-maestro-http-port cleared" ;;
        pf-maestro-http-remote-port) rm -f "$HF_PF_MAESTRO_HTTP_REMOTE_PORT_FILE" && hf_info "pf-maestro-http-remote-port cleared" ;;
        pf-maestro-grpc-port)   rm -f "$HF_PF_MAESTRO_GRPC_PORT_FILE" && hf_info "pf-maestro-grpc-port cleared" ;;
        db-host)      rm -f "$HF_DB_HOST_FILE" && hf_info "db-host cleared" ;;
        db-port)      rm -f "$HF_DB_PORT_FILE" && hf_info "db-port cleared" ;;
        db-name)      rm -f "$HF_DB_NAME_FILE" && hf_info "db-name cleared" ;;
        db-user)      rm -f "$HF_DB_USER_FILE" && hf_info "db-user cleared" ;;
        db-password)  rm -f "$HF_DB_PASSWORD_FILE" && hf_info "db-password cleared" ;;
        all)
            rm -f "$HF_API_URL_FILE" "$HF_API_VERSION_FILE" "$HF_TOKEN_FILE" \
                  "$HF_CONTEXT_FILE" "$HF_NAMESPACE_FILE" "$HF_GCP_PROJECT_FILE" \
                  "$HF_CLUSTER_ID_FILE" "$HF_CLUSTER_NAME_FILE" \
                  "$HF_MAESTRO_CONSUMER_FILE" "$HF_MAESTRO_HTTP_ENDPOINT_FILE" "$HF_MAESTRO_GRPC_ENDPOINT_FILE" \
                  "$HF_MAESTRO_NAMESPACE_FILE" \
                  "$HF_PF_API_PORT_FILE" "$HF_PF_PG_PORT_FILE" "$HF_PF_MAESTRO_HTTP_PORT_FILE" "$HF_PF_MAESTRO_HTTP_REMOTE_PORT_FILE" "$HF_PF_MAESTRO_GRPC_PORT_FILE" \
                  "$HF_DB_HOST_FILE" "$HF_DB_PORT_FILE" "$HF_DB_NAME_FILE" \
                  "$HF_DB_USER_FILE" "$HF_DB_PASSWORD_FILE"
            hf_info "All config cleared"
            ;;
        *)            hf_die "Unknown config key: $key" ;;
    esac
}

case "${1:-show}" in
    show)   show_config ;;
    set)    set_config "${2:-}" "${3:-}" ;;
    clear)  clear_config "${2:-}" ;;
    *)
        hf_usage "[show|set|clear]"
        echo "Commands:"
        echo "  show                Show current configuration"
        echo "  set <key> <value>   Set a configuration value"
        echo "  clear <key>         Clear a configuration value"
        echo "  clear all           Clear all configuration"
        echo ""
        echo "HyperFleet Keys:"
        echo "  api-url, api-version, token, context, namespace, gcp-project, cluster-id, cluster-name"
        echo ""
        echo "Maestro Keys:"
        echo "  maestro-consumer, maestro-http-endpoint, maestro-grpc-endpoint, maestro-namespace"
        echo ""
        echo "Port Forward Keys:"
        echo "  pf-api-port, pf-pg-port, pf-maestro-http-port, pf-maestro-http-remote-port, pf-maestro-grpc-port"
        echo ""
        echo "Database Keys:"
        echo "  db-host, db-port, db-name, db-user, db-password"
        echo ""
        echo "Note: For interactive database configuration, use hf.db.config.sh"
        ;;
esac
