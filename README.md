# NeuVector Helm Chart for k3s with Rancher Fleet

A modular Helm chart for deploying NeuVector on k3s clusters managed by Rancher, with integrated Fleet support and configurable scan frequencies.

## Features

- ✅ **Modular Design**: Wrapper chart around upstream NeuVector Helm chart
- ✅ **Rancher Fleet Integration**: Ready for GitOps deployment via Fleet
- ✅ **Configurable Scan Frequency**: Daily or weekly scan schedules
- ✅ **k3s Optimized**: Pre-configured for k3s container runtime
- ✅ **Rancher SSO Integration**: Built-in Rancher Single Sign-On support

## Structure

```
neuvector-helm/
├── charts/
│   └── neuvector/              # Custom Helm chart wrapper
│       ├── Chart.yaml          # Chart metadata and dependencies
│       ├── values.yaml         # Default values
│       └── templates/
│           ├── scan-config-job.yaml  # Post-install job for scan config
│           └── _helpers.tpl    # Template helpers
├── values/
│   ├── base.yaml               # Base configuration (common to all envs)
│   ├── env-production.yaml      # Production environment overrides
│   ├── env-staging.yaml         # Staging environment overrides
│   ├── env-development.yaml    # Development environment overrides
│   ├── daily-scan.yaml          # Daily scan configuration
│   └── weekly-scan.yaml         # Weekly scan configuration
├── fleet.yaml                  # Rancher Fleet configuration
└── README.md                   # This file
```

## Prerequisites

- k3s cluster
- Rancher 2.6+ with Fleet enabled
- kubectl configured to access your cluster
- Helm 3.x (for local testing)

## Quick Start

### Option 1: Deploy via Rancher Fleet (GitOps - Recommended)

This chart is designed for GitOps workflows with Fleet:

1. **Configure Environment Values**
   ```bash
   # Edit environment-specific values files
   # Production: values/env-production.yaml
   # Staging: values/env-staging.yaml
   # Development: values/env-development.yaml
   
   # Set your Rancher URL in the appropriate env file:
   # global.rancher.url and neuvector-core.global.cattle.url
   ```

2. **Label Your Clusters**
   ```bash
   # Label clusters with environment
   kubectl label cluster <cluster-name> env=production
   kubectl label cluster <cluster-name> env=staging
   kubectl label cluster <cluster-name> env=development
   ```

3. **Create Fleet GitRepo in Rancher**
   - Navigate to **Fleet** → **GitRepos** in Rancher UI
   - Create a new GitRepo pointing to this repository
   - Fleet will automatically deploy based on cluster labels

4. **Verify Deployment**
   ```bash
   # Check Fleet bundles
   kubectl get bundles -A
   ```

The `fleet.yaml` uses Fleet targeting to automatically deploy the correct configuration to each cluster based on labels. No manual steps required after initial setup!

### Option 2: Deploy with Helm (Local Testing)

```bash
# Add NeuVector Helm repository
helm repo add neuvector https://neuvector.github.io/neuvector-helm/
helm repo update

# Install with base + environment values
helm dependency update charts/neuvector

# Production
helm install neuvector ./charts/neuvector \
  --namespace cattle-neuvector-system \
  --create-namespace \
  -f values/base.yaml \
  -f values/env-production.yaml

# Development
helm install neuvector ./charts/neuvector \
  --namespace cattle-neuvector-system \
  --create-namespace \
  -f values/base.yaml \
  -f values/env-development.yaml
```

## Configuration

### Scan Frequency

Configure scan frequency using values files or Fleet targeting:

#### Daily Scan
```yaml
scan:
  enabled: true
  frequency: "daily"
  schedule:
    daily: "0 2 * * *"    # Daily at 2 AM UTC
```

#### Weekly Scan
```yaml
scan:
  enabled: true
  frequency: "weekly"
  schedule:
    weekly: "0 2 * * 0"   # Weekly on Sunday at 2 AM UTC
```

### Fleet Targeting (GitOps)

The chart uses Fleet targeting to automatically deploy environment-specific configurations:

```yaml
# fleet.yaml automatically targets clusters by label
targets:
  - name: production
    clusterSelector:
      matchLabels:
        env: production
    valuesFiles:
      - values/base.yaml
      - values/env-production.yaml
```

**To use this:**
1. Label your clusters: `kubectl label cluster <name> env=production`
2. Edit `values/env-production.yaml` with your settings
3. Commit to Git - Fleet will automatically deploy

See `values/README.md` for details on the values file structure.

### Configuration Variables

**Important**: Before deploying, you must configure the Rancher URL in `fleet.yaml`.

#### Required Configuration

1. **Rancher Server URL**: Replace `RANCHER_URL_PLACEHOLDER` in `fleet.yaml` with your actual Rancher server URL:
   ```yaml
   global:
     rancher:
       url: "https://rancher.your-domain.com"  # Replace this
   
   neuvector-core:
     global:
       cattle:
         url: "https://rancher.your-domain.com"  # Replace this
   ```

2. **Namespace** (optional): Default is `cattle-neuvector-system`. Change in `fleet.yaml` if needed:
   ```yaml
   defaultNamespace: your-namespace
   global:
     namespace: your-namespace
   ```

3. **Runtime Path** (optional): Default is for k3s. Adjust if using different runtime:
   ```yaml
   global:
     runtime:
       path: /run/k3s/containerd/containerd.sock  # k3s default
       # path: /run/containerd/containerd.sock     # standard containerd
       # path: /var/run/docker.sock                # docker
   ```

#### Key Configuration Options

```yaml
# Global configuration
global:
  rancher:
    url: "https://rancher.your-domain.com"  # Rancher server URL
  namespace: cattle-neuvector-system         # Deployment namespace
  runtime:
    path: /run/k3s/containerd/containerd.sock  # Container runtime path

# NeuVector core chart settings (dependency alias: neuvector-core)
neuvector-core:
  runtimePath: /run/k3s/containerd/containerd.sock
  global:
    cattle:
      url: "https://rancher.your-domain.com"  # Must match global.rancher.url
  controller:
    ranchersso:
      enabled: true  # Enable if Rancher URL is set

# Scan configuration
scan:
  enabled: true
  frequency: "weekly"  # Options: "daily" or "weekly"
  schedule:
    daily: "0 2 * * *"    # Daily at 2 AM UTC
    weekly: "0 2 * * 0"   # Weekly on Sunday at 2 AM UTC

# Registry scan settings
registryScan:
  enabled: true
  scanLayers: true
  scanSecrets: true
```

#### Quick Configuration Setup

For a quick setup, you can:

1. **Edit `fleet.yaml` directly**: Replace `RANCHER_URL_PLACEHOLDER` with your Rancher URL
2. **Use a values file**: Copy `values/example-rancher-config.yaml`, customize it, and reference it in `fleet.yaml`
3. **Use Fleet targeting**: Set different Rancher URLs per cluster/environment (see `fleet-targets-example.yaml`)

## Applying Scan Schedules

The Helm chart creates a ConfigMap with scan configuration. To apply scan schedules to your registries:

### Via NeuVector UI

1. Access NeuVector through Rancher UI
2. Navigate to **Assets** → **Registries**
3. For each registry, configure the scan schedule:
   - **Daily**: `0 2 * * *` (2 AM UTC daily)
   - **Weekly**: `0 2 * * 0` (2 AM UTC on Sundays)

### Via NeuVector REST API

You can use the NeuVector REST API to programmatically configure scan schedules. The ConfigMap created by the chart contains the schedule values:

```bash
# Get scan configuration
kubectl get configmap neuvector-scan-config -n cattle-neuvector-system -o yaml
```

Example API call to configure registry scan schedule:

```bash
# Get API token
TOKEN=$(curl -k -X POST \
  -H "Content-Type: application/json" \
  -d '{"password":{"username":"admin","password":"admin"}}' \
  https://neuvector-controller:10443/v1/auth | jq -r '.token.token')

# Update registry scan schedule
curl -k -X PATCH \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"schedule":{"schedule":"0 2 * * 0"}}' \
  https://neuvector-controller:10443/v1/scan/registry/{registry_id}
```

## Troubleshooting

### Check Deployment Status

```bash
# Check NeuVector pods
kubectl get pods -n cattle-neuvector-system

# Check scan config job
kubectl get jobs -n cattle-neuvector-system

# View scan config ConfigMap
kubectl get configmap -n cattle-neuvector-system | grep scan-config
```

### View Scan Config Job Logs

```bash
# Get job pod name
JOB_POD=$(kubectl get pods -n cattle-neuvector-system -l app.kubernetes.io/component=scan-config -o jsonpath='{.items[0].metadata.name}')

# View logs
kubectl logs $JOB_POD -n cattle-neuvector-system
```

### Common Issues

1. **Controller pod not ready**: Wait a few minutes for NeuVector to fully initialize
2. **Scan config job fails**: Check RBAC permissions for the service account
3. **Fleet deployment fails**: Verify the chart path in `fleet.yaml` is correct

## Upgrading

```bash
# Update dependencies
helm dependency update charts/neuvector

# Upgrade release
helm upgrade neuvector ./charts/neuvector \
  --namespace cattle-neuvector-system \
  -f values/weekly-scan.yaml
```

## Uninstalling

```bash
helm uninstall neuvector --namespace cattle-neuvector-system
```

## References

- [NeuVector Documentation](https://open-docs.neuvector.com/)
- [NeuVector Helm Chart](https://github.com/neuvector/neuvector-helm)
- [Rancher Fleet Documentation](https://fleet.rancher.io/)

## License

This chart is provided as-is. Please refer to NeuVector's licensing terms.

