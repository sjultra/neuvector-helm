# Values Files Structure

This directory contains environment-specific values files for GitOps deployments.

## File Structure

```
values/
├── base.yaml              # Common configuration for all environments
├── env-development.yaml   # Development environment overrides
├── env-staging.yaml       # Staging environment overrides
├── env-production.yaml    # Production environment overrides
├── daily-scan.yaml        # Daily scan configuration (can be merged)
├── weekly-scan.yaml       # Weekly scan configuration (can be merged)
└── rancher-config.yaml    # Example Rancher configuration
```

## Usage

### With Fleet (GitOps)

The `fleet.yaml` file automatically references these values files based on cluster labels:

```yaml
targets:
  - name: production
    clusterSelector:
      matchLabels:
        env: production
    valuesFiles:
      - values/base.yaml
      - values/env-production.yaml
```

### With Helm (Local Testing)

```bash
# Install with base + production values
helm install neuvector ./charts/neuvector \
  -f values/base.yaml \
  -f values/env-production.yaml

# Install with base + development values
helm install neuvector ./charts/neuvector \
  -f values/base.yaml \
  -f values/env-development.yaml
```

## Configuration

### Setting Rancher URL

Edit the appropriate environment file:

```yaml
# values/env-production.yaml
global:
  rancher:
    url: "https://rancher.example.com"

neuvector-core:
  global:
    cattle:
      url: "https://rancher.example.com"  # Must match above
  controller:
    ranchersso:
      enabled: true
```

### Adding New Environments

1. Create a new file: `values/env-<environment>.yaml`
2. Add a target in `fleet.yaml`:
   ```yaml
   - name: <environment>
     clusterSelector:
       matchLabels:
         env: <environment>
     valuesFiles:
       - values/base.yaml
       - values/env-<environment>.yaml
   ```

## Values Merging

Values files are merged in order (later files override earlier ones):
1. `base.yaml` - Common defaults
2. `env-*.yaml` - Environment-specific overrides
3. Inline `values:` in Fleet targets (if any)

## Best Practices

1. **Keep base.yaml generic** - Only common settings that apply to all environments
2. **Environment-specific settings** - Put in `env-*.yaml` files
3. **Sensitive data** - Consider using Kubernetes Secrets or external secret management
4. **Version control** - Commit all values files to Git for GitOps
5. **Documentation** - Document any non-obvious settings in comments

