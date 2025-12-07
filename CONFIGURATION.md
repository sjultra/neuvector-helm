# Configuration Guide

This guide explains how to configure the NeuVector Helm chart for your environment.

## Quick Start Configuration

### Step 1: Set Your Rancher URL

Edit `fleet.yaml` and replace `RANCHER_URL_PLACEHOLDER` with your Rancher server URL:

```yaml
global:
  rancher:
    url: "https://rancher.your-domain.com"  # Replace this

neuvector-core:
  global:
    cattle:
      url: "https://rancher.your-domain.com"  # Replace this
```

### Step 2: Verify Other Settings

Check these settings in `fleet.yaml`:

- **Namespace**: Default is `cattle-neuvector-system`
- **Runtime Path**: Default is `/run/k3s/containerd/containerd.sock` (for k3s)
- **Scan Frequency**: Default is `weekly` (can be `daily` or `weekly`)

## Configuration Options

### Global Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `global.rancher.url` | `""` | Rancher server URL for SSO integration |
| `global.namespace` | `cattle-neuvector-system` | Kubernetes namespace for deployment |
| `global.runtime.path` | `/run/k3s/containerd/containerd.sock` | Container runtime socket path |

### NeuVector Core Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `neuvector-core.runtimePath` | `/run/k3s/containerd/containerd.sock` | Container runtime path |
| `neuvector-core.global.cattle.url` | `""` | Rancher server URL (must match `global.rancher.url`) |
| `neuvector-core.controller.ranchersso.enabled` | `false` | Enable Rancher SSO (auto-enabled if URL is set) |

### Scan Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `scan.enabled` | `true` | Enable scan configuration job |
| `scan.frequency` | `"weekly"` | Scan frequency: `"daily"` or `"weekly"` |
| `scan.schedule.daily` | `"0 2 * * *"` | Cron schedule for daily scans (2 AM UTC) |
| `scan.schedule.weekly` | `"0 2 * * 0"` | Cron schedule for weekly scans (Sunday 2 AM UTC) |

## Configuration Methods

### Method 1: Direct Edit (Simple)

Edit `fleet.yaml` directly and replace placeholders:

```yaml
global:
  rancher:
    url: "https://rancher.vzxy.net"  # Your Rancher URL
```

### Method 2: Values File (Recommended)

1. Copy `values/example-rancher-config.yaml`:
   ```bash
   cp values/example-rancher-config.yaml values/my-rancher-config.yaml
   ```

2. Edit `values/my-rancher-config.yaml` with your settings

3. Reference it in `fleet.yaml` or use with Helm:
   ```bash
   helm install neuvector ./charts/neuvector -f values/my-rancher-config.yaml
   ```

### Method 3: Fleet Targeting (Advanced)

Use Fleet's targeting feature to set different configurations per cluster:

```yaml
# In fleet.yaml
targets:
  - name: production
    clusterSelector:
      matchLabels:
        env: prod
    values:
      global:
        rancher:
          url: "https://rancher-prod.example.com"
      scan:
        frequency: "daily"
  
  - name: development
    clusterSelector:
      matchLabels:
        env: dev
    values:
      global:
        rancher:
          url: "https://rancher-dev.example.com"
      scan:
        frequency: "weekly"
```

## Runtime Path Configuration

The default runtime path is for k3s. Adjust based on your container runtime:

| Runtime | Path |
|---------|------|
| k3s | `/run/k3s/containerd/containerd.sock` |
| Standard containerd | `/run/containerd/containerd.sock` |
| Docker | `/var/run/docker.sock` |

Set in `fleet.yaml`:

```yaml
global:
  runtime:
    path: /run/containerd/containerd.sock  # Adjust as needed

neuvector-core:
  runtimePath: /run/containerd/containerd.sock  # Must match
```

## Disabling Rancher SSO

If you don't want to use Rancher SSO:

1. Leave `global.rancher.url` empty or remove it
2. Set `neuvector-core.controller.ranchersso.enabled: false`

```yaml
global:
  rancher:
    url: ""  # Empty or omit

neuvector-core:
  global:
    cattle:
      url: ""  # Empty or omit
  controller:
    ranchersso:
      enabled: false
```

## Environment-Specific Configuration

### Production

```yaml
global:
  rancher:
    url: "https://rancher-prod.example.com"

scan:
  frequency: "daily"  # More frequent scans
  schedule:
    daily: "0 2 * * *"  # 2 AM UTC daily
```

### Development

```yaml
global:
  rancher:
    url: "https://rancher-dev.example.com"

scan:
  frequency: "weekly"  # Less frequent scans
  schedule:
    weekly: "0 2 * * 0"  # Sunday 2 AM UTC
```

## Troubleshooting

### Issue: Rancher SSO not working

**Solution**: Ensure both `global.rancher.url` and `neuvector-core.global.cattle.url` are set to the same value, and `neuvector-core.controller.ranchersso.enabled` is `true`.

### Issue: Wrong runtime path

**Solution**: Verify your container runtime and update `global.runtime.path` and `neuvector-core.runtimePath` accordingly.

### Issue: Scan configuration not applied

**Solution**: Check that `scan.enabled` is `true` and verify the scan config job completed successfully:
```bash
kubectl get jobs -n cattle-neuvector-system
kubectl logs -n cattle-neuvector-system -l app.kubernetes.io/component=scan-config
```

## Validation

After configuration, validate your settings:

```bash
# Check fleet.yaml syntax
helm lint ./charts/neuvector

# Dry-run to see what would be deployed
helm install neuvector ./charts/neuvector --dry-run --debug
```

## References

- [NeuVector Documentation](https://open-docs.neuvector.com/)
- [Rancher Fleet Documentation](https://fleet.rancher.io/)
- [Helm Values Files](https://helm.sh/docs/chart_template_guide/values_files/)

