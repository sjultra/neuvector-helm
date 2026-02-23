# Onboarding downstream clusters into NeuVector (local = primary)

## Verified cluster names (Fleet)

| Cluster   | Namespace     | Role        | Status    |
|-----------|---------------|------------|-----------|
| **local** | fleet-local   | Primary (NeuVector master – already deployed) | — |
| c-68tw8   | fleet-default | Downstream | **Available** |
| c-2kqph   | fleet-default | Downstream | **Available** |
| c-r5mdv   | fleet-default | Downstream | Unavailable |
| c-vn9q2   | fleet-default | Downstream | Unavailable |

**In scope for member deployment:** only **c-68tw8** and **c-2kqph**.

## 1. Master URL (local cluster)

- **Fed-master service:** `neuvector-svc-controller-fed-master` (NodePort **30443**, port 11443).
- **Reachable URL:** `https://31.220.85.63:30443`  
  (control-plane node: `dus-dev-gen-app-01.vzxy.net`, IP `31.220.85.63`).

Ensure firewalls allow **11443** (or the NodePort **30443**) from downstream clusters to this IP.

## 2. Deploy members (Helm – no Fleet)

Use Helm on each downstream cluster. No Git or credentials on the cluster.

**Option A – script (one command per cluster)**  
From the repo root, with a kubeconfig that targets the cluster:

```bash
./scripts/deploy-member-helm.sh /path/to/c-68tw8-kubeconfig
./scripts/deploy-member-helm.sh /path/to/c-2kqph-kubeconfig
```

Get each cluster’s kubeconfig from Rancher: cluster → **Kubeconfig** (or **Download KubeConfig**).

**Option B – manual Helm**  
Add the repo and install with the member values:

```bash
helm repo add neuvector https://neuvector.github.io/neuvector-helm/
helm repo update

# For c-68tw8 (switch KUBECONFIG to that cluster)
KUBECONFIG=/path/to/c-68tw8-kubeconfig helm upgrade --install neuvector-member neuvector/core \
  -n cattle-neuvector-system --create-namespace -f values/neuvector-member.yaml

# For c-2kqph (switch KUBECONFIG to that cluster)
KUBECONFIG=/path/to/c-2kqph-kubeconfig helm upgrade --install neuvector-member neuvector/core \
  -n cattle-neuvector-system --create-namespace -f values/neuvector-member.yaml
```

Values file: `values/neuvector-member.yaml` (controller + enforcers + manager, no scanner; fed-worker on NodePort 30444).

## 3. One-time UI join (per downstream cluster)

NeuVector does not support fully automated join via Helm; you complete the join once in the UI.

### On the primary (local)

1. Open NeuVector on the **local** cluster (e.g. `https://31.220.85.63:31213`).
2. Log in (e.g. admin / admin).
3. **Multiple Clusters** (top right) → **Promote to primary**.
4. Enter primary controller URL: `31.220.85.63` and port `30443` (or `11443` if you use the service port).
5. Save, then **Generate token** and copy the token (valid ~1 hour).

### On each downstream cluster (c-68tw8, c-2kqph)

1. Open NeuVector for **that** cluster (from Rancher: cluster → **Launch NeuVector**, or use that cluster’s manager NodePort).
2. Log in (e.g. admin / admin).
3. **Multiple Clusters** → **Join**.
4. Enter **this** cluster’s controller IP/hostname and port (fed-worker; from the member chart it’s NodePort **30444** – use the node IP and 30444).
5. Paste the token from the primary; complete Join.

Repeat for the second cluster (generate a new token if the previous one expired).

## 4. Check

Back on the primary UI, **Multiple Clusters** should list the 2 remote clusters (c-68tw8, c-2kqph). You can switch context and manage each from the same console.

## Minimal member footprint

- **Controller:** 1 replica  
- **Enforcer:** DaemonSet (one per node)  
- **Manager:** enabled (for Join and optional local UI)  
- **Scanner:** disabled  
- **Updater:** disabled  
