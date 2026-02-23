# NeuVector Federation Configuration

## Problem: Sub-clusters Not Showing Up

If your NeuVector sub-clusters are not appearing in the master cluster's UI, the most common cause is **missing federation configuration** in the member cluster deployments.

## Root Cause

The main `fleet.yaml` deployment was missing federation configuration. Member clusters need to be configured to connect to the master cluster endpoint.

## Solution

### For Member Clusters (Sub-clusters)

Add federation configuration to point to your master cluster. You have several options:

#### Option 1: Add to Environment-Specific Values Files

Edit the appropriate environment file (e.g., `values/env-production.yaml`) and add:

```yaml
neuvector-core:
  federation:
    master: "https://31.220.85.63:30443"  # Your master cluster endpoint
```

#### Option 2: Use Fleet Targeting

In `fleet.yaml`, add federation configuration to specific targets:

```yaml
targets:
  - name: production
    clusterSelector:
      matchLabels:
        env: production
    valuesFiles:
      - values/base.yaml
      - values/env-production.yaml
    values:
      neuvector-core:
        federation:
          master: "https://31.220.85.63:30443"  # Master endpoint
```

#### Option 3: Create a Member Cluster Values File

Create `values/member-clusters.yaml`:

```yaml
# Federation configuration for member clusters
neuvector-core:
  federation:
    master: "https://31.220.85.63:30443"  # Master cluster endpoint
```

Then reference it in `fleet.yaml` for member clusters (not the master).

### For Master Cluster

**DO NOT** set `federation.master` on the master cluster. Leave it empty or omit the setting entirely.

## Master Cluster Endpoint

The master cluster endpoint format is:
- `https://<master-ip-or-hostname>:<port>`
- Default port is typically `30443` or `11443`
- The endpoint must be externally accessible from member clusters

To find your master cluster endpoint:
1. On the master cluster, check the `fed-master` service:
   ```bash
   kubectl get svc -n cattle-neuvector-system | grep fed-master
   ```
2. Use the external IP and port shown

## Network Requirements

For federation to work, ensure:

1. **Network Connectivity**: Member clusters must be able to reach the master cluster on the federation port (typically 30443 or 11443)
2. **Firewall Rules**: Allow traffic between clusters on the federation ports
3. **Time Synchronization**: System clocks must be synchronized between all clusters
4. **Service Exposure**: The master cluster's `fed-master` service must be externally accessible

## Verification

After applying federation configuration:

1. **Check Controller Logs** on member clusters:
   ```bash
   kubectl logs -n cattle-neuvector-system -l app=neuvector-controller-pod | grep -i federation
   ```

2. **Verify Service Endpoints**:
   ```bash
   # On master cluster
   kubectl get svc -n cattle-neuvector-system fed-master
   
   # On member clusters
   kubectl get svc -n cattle-neuvector-system fed-worker
   ```

3. **Check Federation Status** in NeuVector UI:
   - Navigate to **Settings** → **Federation**
   - Member clusters should appear in the list

## Troubleshooting

### Sub-clusters Still Not Showing

1. **Verify Federation Configuration**:
   ```bash
   # Check if federation is configured
   kubectl get configmap -n cattle-neuvector-system neuvector-controller -o yaml | grep -i federation
   ```

2. **Check Network Connectivity**:
   ```bash
   # From a member cluster pod, test connectivity to master
   kubectl run -it --rm debug --image=curlimages/curl --restart=Never -- \
     curl -k https://31.220.85.63:30443
   ```

3. **Verify Time Synchronization**:
   ```bash
   # Check time on both clusters
   date
   # Should be within seconds of each other
   ```

4. **Check Controller Logs for Errors**:
   ```bash
   kubectl logs -n cattle-neuvector-system -l app=neuvector-controller-pod --tail=100
   ```

### Common Issues

- **Expired Federation Token**: Tokens expire after ~1 hour. Generate a new token on the master cluster
- **Firewall Blocking**: Ensure federation ports are open between clusters
- **Wrong Endpoint**: Verify the master endpoint is correct and accessible
- **Time Drift**: Clusters must have synchronized clocks

## References

- [NeuVector Multi-Cluster Documentation](https://open-docs.neuvector.com/next/navigation/multicluster/)
- [NeuVector Troubleshooting Guide](https://open-docs.neuvector.com/next/troubleshooting/troubleshooting/)

