# CubeOS API Contracts

**Document:** 07_API_CONTRACTS.md  
**Version:** 2.0  
**Last Updated:** January 31, 2026

---

## 1. Overview

This document defines the new unified API endpoints for CubeOS. The old fragmented endpoints (`/appstore`, `/appmanager`, `/services`) are deprecated in favor of unified resources.

---

## 2. Base URL

```
http://api.cubeos.cube/api/v1
http://10.42.24.1:6010/api/v1
```

---

## 3. Authentication

All endpoints (except `/auth/login` and `/health`) require JWT authentication.

```
Authorization: Bearer <token>
```

---

## 4. Apps Resource

### List All Apps

```http
GET /api/v1/apps
```

**Query Parameters:**
| Param | Type | Description |
|-------|------|-------------|
| type | string | Filter: `system`, `platform`, `network`, `ai`, `user` |
| status | string | Filter: `running`, `stopped` |
| enabled | boolean | Filter by boot-enabled state |

**Response:**
```json
{
    "apps": [
        {
            "id": 1,
            "name": "pihole",
            "display_name": "Pi-hole",
            "description": "DNS + DHCP Server",
            "type": "system",
            "category": "infrastructure",
            "enabled": true,
            "ports": [
                {"port": 6001, "protocol": "tcp", "description": "Admin UI", "is_primary": true}
            ],
            "fqdns": [
                {"fqdn": "pihole.cubeos.cube", "subdomain": "pihole"}
            ],
            "status": {
                "running": true,
                "health": "healthy",
                "replicas": "1/1"
            }
        }
    ]
}
```

### Get Single App

```http
GET /api/v1/apps/{name}
```

### Install App

```http
POST /api/v1/apps
```

**Request:**
```json
{
    "name": "filebrowser",
    "display_name": "File Browser",
    "source": "casaos",
    "store_app_id": "filebrowser"
}
```

**Response:**
```json
{
    "id": 10,
    "name": "filebrowser",
    "display_name": "File Browser",
    "type": "user",
    "ports": [{"port": 6100, "protocol": "tcp", "is_primary": true}],
    "fqdns": [{"fqdn": "filebrowser.cubeos.cube"}],
    "status": {"running": true, "health": "starting"}
}
```

### Uninstall App

```http
DELETE /api/v1/apps/{name}?keep_data=false
```

### Start/Stop/Restart App

```http
POST /api/v1/apps/{name}/start
POST /api/v1/apps/{name}/stop
POST /api/v1/apps/{name}/restart
```

### Enable/Disable App (Boot)

```http
POST /api/v1/apps/{name}/enable
POST /api/v1/apps/{name}/disable
```

### Get App Logs

```http
GET /api/v1/apps/{name}/logs?lines=100&since=2026-01-31T00:00:00Z
```

### Set App Tor Routing

```http
POST /api/v1/apps/{name}/tor
```

**Request:**
```json
{
    "enabled": true
}
```

---

## 5. Network Resource

### Get Network Status

```http
GET /api/v1/network/status
```

**Response:**
```json
{
    "mode": "online_eth",
    "internet": true,
    "ap": {
        "ssid": "CubeOS",
        "interface": "wlan0",
        "clients": 3
    },
    "upstream": {
        "interface": "eth0",
        "ip": "192.168.1.100",
        "gateway": "192.168.1.1"
    },
    "subnet": "10.42.24.0/24",
    "gateway_ip": "10.42.24.1"
}
```

### Set Network Mode

```http
POST /api/v1/network/mode
```

**Request (OFFLINE):**
```json
{
    "mode": "offline"
}
```

**Request (ONLINE_ETH):**
```json
{
    "mode": "online_eth"
}
```

**Request (ONLINE_WIFI):**
```json
{
    "mode": "online_wifi",
    "ssid": "HomeNetwork",
    "password": "secret123"
}
```

### Scan WiFi Networks

```http
GET /api/v1/network/wifi/scan
```

**Response:**
```json
{
    "networks": [
        {
            "ssid": "HomeNetwork",
            "bssid": "AA:BB:CC:DD:EE:FF",
            "signal": -45,
            "security": "WPA2",
            "frequency": 2437
        }
    ]
}
```

### Get AP Configuration

```http
GET /api/v1/network/ap/config
```

### Update AP Configuration

```http
PUT /api/v1/network/ap/config
```

**Request:**
```json
{
    "ssid": "MyCubeOS",
    "password": "newpassword123",
    "channel": 6,
    "hidden": false
}
```

---

## 6. VPN Resource

### List VPN Configurations

```http
GET /api/v1/vpn/configs
```

**Response:**
```json
{
    "configs": [
        {
            "id": 1,
            "name": "work-vpn",
            "type": "wireguard",
            "is_active": true,
            "auto_connect": false
        }
    ]
}
```

### Add VPN Configuration

```http
POST /api/v1/vpn/configs
```

**Request:**
```json
{
    "name": "work-vpn",
    "type": "wireguard",
    "config": "base64-encoded-config-file"
}
```

### Delete VPN Configuration

```http
DELETE /api/v1/vpn/configs/{id}
```

### Connect/Disconnect VPN

```http
POST /api/v1/vpn/configs/{id}/connect
POST /api/v1/vpn/configs/{id}/disconnect
```

### Get VPN Status

```http
GET /api/v1/vpn/status
```

**Response:**
```json
{
    "active_config": "work-vpn",
    "type": "wireguard",
    "connected": true,
    "public_ip": "203.0.113.50",
    "connected_since": "2026-01-31T10:00:00Z"
}
```

---

## 7. Mounts Resource (SMB/NFS)

### List Mounts

```http
GET /api/v1/mounts
```

**Response:**
```json
{
    "mounts": [
        {
            "id": 1,
            "name": "nas-backup",
            "type": "smb",
            "remote_path": "//192.168.1.50/backup",
            "local_path": "/cubeos/mounts/nas-backup",
            "is_mounted": true,
            "auto_mount": true
        }
    ]
}
```

### Add Mount

```http
POST /api/v1/mounts
```

**Request (SMB):**
```json
{
    "name": "nas-backup",
    "type": "smb",
    "remote_path": "//192.168.1.50/backup",
    "username": "backupuser",
    "password": "secret",
    "auto_mount": true
}
```

**Request (NFS):**
```json
{
    "name": "nfs-share",
    "type": "nfs",
    "remote_path": "192.168.1.50:/exports/data",
    "options": "rw,soft",
    "auto_mount": false
}
```

### Delete Mount

```http
DELETE /api/v1/mounts/{id}
```

### Mount/Unmount

```http
POST /api/v1/mounts/{id}/mount
POST /api/v1/mounts/{id}/unmount
```

---

## 8. Profiles Resource

### List Profiles

```http
GET /api/v1/profiles
```

**Response:**
```json
{
    "profiles": [
        {
            "id": 1,
            "name": "full",
            "display_name": "Full",
            "description": "All services enabled",
            "is_active": true,
            "is_system": true,
            "apps": [
                {"app_id": 1, "app_name": "pihole", "enabled": true},
                {"app_id": 2, "app_name": "npm", "enabled": true}
            ]
        }
    ],
    "active_profile": "full"
}
```

### Apply Profile

```http
POST /api/v1/profiles/{name}/apply
```

**Response:**
```json
{
    "profile": "minimal",
    "started": ["pihole", "npm", "api", "dashboard"],
    "stopped": ["ollama", "chromadb"]
}
```

### Create Custom Profile

```http
POST /api/v1/profiles
```

**Request:**
```json
{
    "name": "custom",
    "display_name": "My Profile",
    "apps": [
        {"app_name": "pihole", "enabled": true},
        {"app_name": "ollama", "enabled": false}
    ]
}
```

---

## 9. Backup Resource

### List Backups

```http
GET /api/v1/backups
```

### Create Backup

```http
POST /api/v1/backups
```

**Request:**
```json
{
    "name": "manual-backup",
    "destination": "nas-backup",
    "include_apps": ["*"]
}
```

### Schedule Backup

```http
POST /api/v1/backups/schedule
```

**Request:**
```json
{
    "name": "nightly",
    "destination": "nas-backup",
    "schedule": "0 2 * * *",
    "retention_days": 30
}
```

### Restore Backup

```http
POST /api/v1/backups/{id}/restore
```

---

## 10. Registry Resource

### Get Registry Status

```http
GET /api/v1/registry/status
```

**Response:**
```json
{
    "online": true,
    "url": "http://localhost:5000",
    "disk_usage": {
        "bytes": 5368709120,
        "human": "5.0 GB"
    },
    "image_count": 25
}
```

### List Cached Images

```http
GET /api/v1/registry/images
```

### Cleanup Registry

```http
POST /api/v1/registry/cleanup
```

**Request:**
```json
{
    "keep_tags": 2,
    "older_than_days": 30
}
```

---

## 11. System Resource

```http
GET  /api/v1/system/info
GET  /api/v1/system/stats
GET  /api/v1/system/temperature
POST /api/v1/system/reboot
POST /api/v1/system/shutdown
```

---

## 12. Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `UNAUTHORIZED` | 401 | Missing or invalid JWT |
| `FORBIDDEN` | 403 | Insufficient permissions |
| `APP_NOT_FOUND` | 404 | App does not exist |
| `PROFILE_NOT_FOUND` | 404 | Profile does not exist |
| `MOUNT_NOT_FOUND` | 404 | Mount does not exist |
| `APP_ALREADY_EXISTS` | 409 | App with name already exists |
| `PORT_CONFLICT` | 409 | Port already allocated |
| `SYSTEM_APP_PROTECTED` | 403 | Cannot modify system app |
| `OFFLINE_IMAGE_UNAVAILABLE` | 503 | Image not cached, offline |
| `VPN_CONNECTION_FAILED` | 500 | VPN connection error |
| `MOUNT_FAILED` | 500 | SMB/NFS mount error |
| `WIFI_CONNECTION_FAILED` | 500 | WiFi connection error |

---

## 13. Deprecated Endpoints

The following are **deprecated** and will be removed in v3.0:

| Deprecated | Replacement |
|------------|-------------|
| `/api/v1/services/*` | `/api/v1/apps/*` |
| `/api/v1/appstore/*` | `/api/v1/apps/*` |
| `/api/v1/appmanager/*` | `/api/v1/apps/*` |

---

*Document Version: 2.0*  
*Last Updated: January 31, 2026*
