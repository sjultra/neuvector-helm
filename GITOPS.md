# GitOps Deployment Guide

This chart is designed for GitOps workflows with Rancher Fleet. All configuration is stored in Git and automatically deployed to clusters based on labels.

## Quick Start

### 1. Configure Your Environments

Edit the environment-specific values files:

```bash
# Production
vim values/env-production.yaml

# Staging  
vim values/env-staging.yaml

# Development
vim values/env-development.yaml
```

Set your Rancher URL in each file:
```yaml
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

### 2. Label Your Clusters

```bash
# Production clusters
kubectl label cluster <cluster-name> env=production

# Staging clusters
kubectl label cluster <cluster-name> env=staging

# Development clusters
kubectl label cluster <cluster-name> env=development
```

### 3. Create Fleet GitRepo

In Rancher UI:
1. Navigate to **Fleet** → **GitRepos**
2. Click **Create**
3. Set:
   - **Name**: `neuvector`
   - **Repository URL**: Your Git repository URL
   - **Branch**: `main` (or your default branch)
   - **Path**: `/` (root of repo)

### 4. Verify Deployment

```bash
# Check Fleet bundles
kubectl get bundles -A | grep neuvector

# Check deployments
kubectl get deployments -n cattle-neuvector-system

# View Fleet logs
kubectl logs -n fleet-system -l app=fleet-controller
```

## How It Works

### Values File Structure

```
values/
├── base.yaml              # Common config (all environments)
├── env-production.yaml    # Production overrides
├── env-staging.yaml       # Staging overrides
└── env-development.yaml   # Development overrides
```

### Fleet Targeting

The `fleet.yaml` uses cluster labels to automatically select the right values:

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

### Values Merging

Values are merged in order (later files override earlier):
1. `base.yaml` - Common defaults
2. `env-*.yaml` - Environment-specific overrides
3. Inline `values:` in Fleet targets (if any)

## Adding New Environments

1. **Create values file**: `values/env-<name>.yaml`
   ```yaml
   global:
     rancher:
       url: "https://rancher-<env>.example.com"
   
   scan:
     frequency: "weekly"
   ```

2. **Add Fleet target** in `fleet.yaml`:
   ```yaml
   - name: <name>
     clusterSelector:
       matchLabels:
         env: <name>
     valuesFiles:
       - values/base.yaml
       - values/env-<name>.yaml
   ```

3. **Label clusters**: `kubectl label cluster <name> env=<name>`

4. **Commit to Git** - Fleet will automatically deploy

## Best Practices

### 1. Environment Isolation

- Keep environment-specific configs in separate files
- Never commit secrets to Git (use Kubernetes Secrets or external secret management)
- Use different Rancher URLs per environment if possible

### 2. Configuration Management

- **Base config**: Common settings in `base.yaml`
- **Environment overrides**: Only differences in `env-*.yaml`
- **Documentation**: Comment non-obvious settings

### 3. Git Workflow

```bash
# Make changes
vim values/env-production.yaml

# Test locally
helm template ./charts/neuvector \
  -f values/base.yaml \
  -f values/env-production.yaml

# Commit and push
git add values/env-production.yaml
git commit -m "Update production NeuVector config"
git push
```

### 4. Rollback

If something goes wrong:

```bash
# Revert in Git
git revert <commit-hash>
git push

# Or manually update Fleet bundle
kubectl patch bundle <bundle-name> -n <namespace> --type merge \
  -p '{"spec":{"targets":[...]}}'
```

## Troubleshooting

### Fleet Not Deploying

```bash
# Check GitRepo status
kubectl get gitrepo -A

# Check bundle status
kubectl get bundles -A

# View Fleet controller logs
kubectl logs -n fleet-system -l app=fleet-controller --tail=100
```

### Wrong Environment Deployed

```bash
# Check cluster labels
kubectl get clusters -o yaml | grep -A 5 labels

# Verify Fleet target matching
kubectl get bundles -o yaml | grep -A 10 clusterSelector
```

### Values Not Applied

```bash
# Check which values files are being used
kubectl get bundles <bundle-name> -o yaml | grep -A 20 valuesFiles

# Verify values file exists in Git
git ls-files values/
```

## Advanced: Multi-Cluster Setup

For multiple clusters in the same environment:

```yaml
targets:
  - name: production-us-east
    clusterSelector:
      matchLabels:
        env: production
        region: us-east
    valuesFiles:
      - values/base.yaml
      - values/env-production.yaml
      - values/regions/us-east.yaml  # Region-specific overrides
```

## Security Considerations

1. **Secrets**: Never commit secrets to Git
   - Use Kubernetes Secrets
   - Use external secret management (Sealed Secrets, External Secrets Operator, etc.)
   - Reference secrets in values files: `secretName: neuvector-secrets`

2. **RBAC**: Ensure Fleet has proper permissions
   ```yaml
   # Fleet service account needs cluster-admin or equivalent
   ```

3. **Network Policies**: Consider restricting Fleet controller network access

## References

- [Rancher Fleet Documentation](https://fleet.rancher.io/)
- [Helm Values Files](https://helm.sh/docs/chart_template_guide/values_files/)
- [GitOps Best Practices](https://www.gitops.tech/)

