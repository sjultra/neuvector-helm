# On-Demand Scanning Configuration

## Overview
NeuVector scanning is configured to only occur when manually requested, not automatically, to avoid overburdening clusters.

## Configuration Applied

### 1. Disabled Automatic CVE Updates
```yaml
updater:
  enabled: false
```
- Prevents automatic CVE database updates
- CVE updates can be triggered manually when needed
- Reduces background resource usage

### 2. Scanner Configuration
- **1 scanner per cluster** (not per node)
- Scanners are available but idle until manually triggered
- No automatic scan schedules configured

## How NeuVector Scanning Works

NeuVector scanning is controlled through:
1. **NeuVector UI** - Manual scan triggers
2. **NeuVector REST API** - Programmatic scan requests
3. **Registry scan schedules** - Configured per registry (disabled by default)

## Important Notes

### Automatic Scanning is Disabled
- ✅ No automatic registry scans
- ✅ No scheduled CVE updates
- ✅ Scanners are idle until manually triggered
- ✅ Scans only occur when explicitly requested via UI or API

### Manual Scanning Options

1. **Via NeuVector UI**:
   - Navigate to **Assets** → **Registries**
   - Select a registry
   - Click **Scan Now** button

2. **Via REST API**:
   ```bash
   # Get API token
   TOKEN=$(curl -k -X POST \
     -H "Content-Type: application/json" \
     -d '{"password":{"username":"admin","password":"admin"}}' \
     https://neuvector-controller:10443/v1/auth | jq -r '.token.token')
   
   # Trigger scan
   curl -k -X POST \
     -H "Authorization: Bearer $TOKEN" \
     https://neuvector-controller:10443/v1/scan/registry/{registry_id}/scan
   ```

3. **Via Rancher UI**:
   - Access NeuVector through Rancher
   - Use the scan functionality in the NeuVector interface

## Resource Usage

With on-demand scanning:
- **Scanners**: Idle, minimal CPU/memory usage
- **Controllers**: Normal operation (required for coordination)
- **Enforcers**: Normal operation (security enforcement)
- **No background scanning**: No automatic resource consumption

## Enabling Scheduled Scans (If Needed Later)

If you want to enable scheduled scans in the future:

1. **Via NeuVector UI**:
   - Go to **Assets** → **Registries**
   - Configure scan schedule per registry
   - Set schedule (e.g., "0 2 * * *" for daily at 2 AM)

2. **Via API**:
   ```bash
   curl -k -X PATCH \
     -H "Authorization: Bearer $TOKEN" \
     -H "Content-Type: application/json" \
     -d '{"schedule":{"schedule":"0 2 * * *"}}' \
     https://neuvector-controller:10443/v1/scan/registry/{registry_id}
   ```

## Current Configuration Summary

✅ **Automatic scanning**: Disabled
✅ **CVE updater**: Disabled  
✅ **Scanner replicas**: 1 per cluster
✅ **Scanning mode**: On-demand only
✅ **Resource usage**: Minimal (idle scanners)

Scans will only occur when explicitly requested through the UI or API.

