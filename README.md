# HyperFleet Scripts

CLI utilities for managing HyperFleet clusters, databases, and Kubernetes resources.

## Config System

All scripts use a **file-based configuration** system with environment variable overrides:

- **Config location**: `~/.config/hf/` (one file per setting)
- **Precedence**: Environment variables > config files > defaults
- **Shared state**: Settings persist across script invocations

### Managed via `hf.config.sh`

```bash
hf.config.sh                      # Show current configuration
hf.config.sh set api-url <url>    # Set API URL
hf.config.sh clear token          # Clear auth token
hf.config.sh clear all            # Reset everything
```

**HyperFleet settings**: `api-url`, `api-version`, `token`, `context`, `namespace`, `gcp-project`, `cluster-id`, `cluster-name`

**Database settings**: `db-host`, `db-port`, `db-name`, `db-user`, `db-password`

Interactive database setup: `hf.db.config.sh`

## Scripts Overview

### Cluster Management

| Script | Description |
|--------|-------------|
| `hf.cluster.create.sh` | Create a new cluster via API |
| `hf.cluster.delete.sh` | Delete cluster by ID |
| `hf.cluster.get.sh` | Get cluster details by ID |
| `hf.cluster.search.sh` | Search clusters by name and set as current |
| `hf.cluster.list.sh` | List all clusters |
| `hf.cluster.table.sh` | Display clusters in table format |
| `hf.cluster.id.sh` | Show current cluster ID |
| `hf.cluster.conditions.sh` | Show cluster conditions |
| `hf.cluster.statuses.sh` | Show cluster status history |

### Database Operations

| Script | Description |
|--------|-------------|
| `hf.db.config.sh` | Interactive database configuration |
| `hf.db.query.sh` | Execute SQL queries or files |
| `hf.db.delete.sh` | Delete database records |
| `hf.db.statuses.sh` | Query cluster status table |
| `hf.db.statuses.delete.sh` | Delete status records |

### Kubernetes Helpers

| Script | Description |
|--------|-------------|
| `hf.kube.context.sh` | Select and save kubectl context/namespace |
| `hf.kube.debug.pod.sh` | Create debug pod in cluster |
| `hf.kube.port.forward.sh` | Port forward to services/pods |
| `hf.logs.sh` | Tail pod logs with context |

### Other Utilities

| Script | Description |
|--------|-------------|
| `hf.adapter.status.sh` | Check adapter status |
| `hf.pubsub.publish.sh` | Publish messages to Pub/Sub |
| `hf.maestro.list.sh` | List maestro resources |
| `hf.lib.sh` | Shared library (logging, API helpers, config loaders) |

## Common Patterns

**Search and set current cluster**:
```bash
hf.cluster.search.sh my-cluster-name
```

**Query cluster details** (uses saved cluster-id):
```bash
hf.cluster.get.sh
```

**Configure kubectl context**:
```bash
hf.kube.context.sh select
```

**Run database query**:
```bash
hf.db.query.sh "SELECT * FROM clusters LIMIT 10"
hf.db.query.sh -f schema.sql
```

## Architecture

- **hf.lib.sh**: Core library providing config loading, API helpers, logging, and Kubernetes wrappers
- **File-based state**: Each config value stored separately in `~/.config/hf/` for easy inspection and editing
- **Environment override**: Set `HF_API_URL`, `HF_TOKEN`, etc. to override file config
- **Consistent interface**: All scripts source `hf.lib.sh` for unified behavior and error handling
