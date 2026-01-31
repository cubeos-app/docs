# CubeOS Core Apps Inventory

**Document:** 05_COREAPPS_INVENTORY.md  
**Version:** 2.0  
**Last Updated:** January 31, 2026

---

## 1. Overview

This document inventories all apps in the `coreapps` repository and defines their fate in the Swarm migration.

---

## 2. Final Disposition Matrix

| App | Decision | Port | Type | Notes |
|-----|----------|------|------|-------|
| pihole | **KEEP** | 6001 | system | DNS + DHCP, host network |
| npm | **KEEP** | 6000 | system | Reverse proxy, host network |
| registry | **NEW** | 5000 | system | Local Docker registry |
| cubeos-api | **SPLIT** | 6010 | platform | Renamed from orchestrator |
| cubeos-dashboard | **SPLIT** | 6011 | platform | Separated from api |
| dozzle | **KEEP** | 6012 | platform | Log viewer |
| watchdog | **KEEP** | - | platform | Health monitor |
| wireguard | **NEW** | 6020 | network | VPN client |
| openvpn | **NEW** | 6021 | network | VPN client |
| tor | **NEW** | 6022 | network | Privacy routing |
| ollama | **KEEP** | 6030 | ai | LLM server (moved from 11434) |
| chromadb | **KEEP** | 6031 | ai | Vector database (moved from 8000) |
| docs-indexer | **KEEP** | 6032 | ai | RAG indexer |
| backup | **REVIEW** | - | platform | Needs SMB/NFS support |
| diagnostics | **KEEP** | 6040 | platform | System diagnostics |
| reset | **KEEP** | 6041 | platform | Factory reset |
| terminal | **KEEP** | 6042 | platform | Web terminal |
| dockge | **REMOVE** | - | - | Replaced by Swarm |
| gpio | **REMOVE** | - | - | Redundant, API handles I2C |
| nettools | **REMOVE** | - | - | Not actively used |
| usb-monitor | **REMOVE** | - | - | Can be user app if needed |

---

## 3. Detailed App Specifications

### 3.1 Infrastructure Layer (System)

#### pihole
```yaml
# /cubeos/coreapps/pihole/appconfig/docker-compose.yml
services:
  pihole:
    image: pihole/pihole:latest
    container_name: cubeos-pihole
    restart: unless-stopped
    network_mode: host
    volumes:
      - ../appdata/etc-pihole:/etc/pihole
      - ../appdata/etc-dnsmasq.d:/etc/dnsmasq.d
    environment:
      - TZ=${TZ:-UTC}
      - FTLCONF_webserver_port=6001
      - FTLCONF_webserver_api_password=${PIHOLE_PASSWORD}
      - FTLCONF_dns_listeningMode=all
      - FTLCONF_dns_upstreams=1.1.1.1;8.8.8.8
      - FTLCONF_dhcp_active=true
      - FTLCONF_dhcp_start=10.42.24.10
      - FTLCONF_dhcp_end=10.42.24.250
      - FTLCONF_dhcp_router=10.42.24.1
      - FTLCONF_dhcp_netmask=255.255.255.0
    env_file:
      - /cubeos/config/defaults.env
      - /cubeos/config/secrets.env
    cap_add:
      - NET_ADMIN
      - NET_RAW
    deploy:
      resources:
        limits:
          memory: 256M
    labels:
      - "cubeos.type=system"
      - "cubeos.port=6001"
```

#### npm (Nginx Proxy Manager)
```yaml
# /cubeos/coreapps/npm/appconfig/docker-compose.yml
services:
  npm:
    image: jc21/nginx-proxy-manager:latest
    container_name: cubeos-npm
    restart: unless-stopped
    network_mode: host
    volumes:
      - ../appdata/data:/data
      - ../appdata/letsencrypt:/etc/letsencrypt
    environment:
      - TZ=${TZ:-UTC}
    env_file:
      - /cubeos/config/defaults.env
    deploy:
      resources:
        limits:
          memory: 256M
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:6000/api/"]
      interval: 30s
      timeout: 10s
      retries: 3
    labels:
      - "cubeos.type=system"
      - "cubeos.port=6000"
```

#### registry
```yaml
# /cubeos/coreapps/registry/appconfig/docker-compose.yml
services:
  registry:
    image: registry:2
    container_name: cubeos-registry
    restart: unless-stopped
    ports:
      - "5000:5000"
    volumes:
      - /cubeos/data/registry:/var/lib/registry
      - ./config.yml:/etc/docker/registry/config.yml:ro
    environment:
      - REGISTRY_HTTP_ADDR=0.0.0.0:5000
      - REGISTRY_STORAGE_DELETE_ENABLED=true
    deploy:
      resources:
        limits:
          memory: 256M
    healthcheck:
      test: ["CMD", "wget", "-q", "--spider", "http://localhost:5000/v2/"]
      interval: 30s
      timeout: 5s
      retries: 3
    labels:
      - "cubeos.type=system"
      - "cubeos.port=5000"
```

### 3.2 Platform Layer

#### cubeos-api
```yaml
# /cubeos/coreapps/cubeos-api/appconfig/docker-compose.yml
services:
  api:
    image: ghcr.io/cubeos-app/api:latest
    container_name: cubeos-api
    restart: unless-stopped
    ports:
      - "6010:6010"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - /cubeos:/cubeos
      - /etc/hostapd:/etc/hostapd:ro
      - /sys:/sys:ro
      - /proc:/proc:ro
    environment:
      - CUBEOS_PORT=6010
      - CUBEOS_DATA_DIR=/cubeos/data
      - CUBEOS_DB_PATH=/cubeos/data/cubeos.db
    env_file:
      - /cubeos/config/defaults.env
      - /cubeos/config/secrets.env
    devices:
      - /dev/i2c-1:/dev/i2c-1
    deploy:
      resources:
        limits:
          memory: 128M
    healthcheck:
      test: ["CMD", "wget", "-q", "--spider", "http://localhost:6010/health"]
      interval: 30s
      timeout: 5s
      retries: 3
    labels:
      - "cubeos.type=platform"
      - "cubeos.port=6010"
```

#### cubeos-dashboard
```yaml
# /cubeos/coreapps/cubeos-dashboard/appconfig/docker-compose.yml
services:
  dashboard:
    image: ghcr.io/cubeos-app/dashboard:latest
    container_name: cubeos-dashboard
    restart: unless-stopped
    ports:
      - "6011:80"
    environment:
      - API_URL=http://10.42.24.1:6010
    env_file:
      - /cubeos/config/defaults.env
    deploy:
      resources:
        limits:
          memory: 64M
    healthcheck:
      test: ["CMD", "wget", "-q", "--spider", "http://localhost:80/"]
      interval: 30s
      timeout: 5s
      retries: 3
    labels:
      - "cubeos.type=platform"
      - "cubeos.port=6011"
```

#### dozzle
```yaml
# /cubeos/coreapps/dozzle/appconfig/docker-compose.yml
services:
  dozzle:
    image: amir20/dozzle:latest
    container_name: cubeos-dozzle
    restart: unless-stopped
    ports:
      - "6012:8080"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
    environment:
      - DOZZLE_LEVEL=info
      - DOZZLE_TAILSIZE=300
    deploy:
      resources:
        limits:
          memory: 64M
    labels:
      - "cubeos.type=platform"
      - "cubeos.port=6012"
```

### 3.3 Network Layer

#### wireguard
```yaml
# /cubeos/coreapps/wireguard/appconfig/docker-compose.yml
services:
  wireguard:
    image: linuxserver/wireguard:latest
    container_name: cubeos-wireguard
    restart: unless-stopped
    ports:
      - "6020:51820/udp"
    volumes:
      - /cubeos/config/vpn/wireguard:/config
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=${TZ:-UTC}
    env_file:
      - /cubeos/config/defaults.env
    cap_add:
      - NET_ADMIN
      - SYS_MODULE
    sysctls:
      - net.ipv4.conf.all.src_valid_mark=1
    deploy:
      resources:
        limits:
          memory: 128M
    labels:
      - "cubeos.type=network"
      - "cubeos.port=6020"
```

#### openvpn
```yaml
# /cubeos/coreapps/openvpn/appconfig/docker-compose.yml
services:
  openvpn:
    image: dperson/openvpn-client:latest
    container_name: cubeos-openvpn
    restart: unless-stopped
    ports:
      - "6021:1194/udp"
    volumes:
      - /cubeos/config/vpn/openvpn:/vpn
    environment:
      - TZ=${TZ:-UTC}
    env_file:
      - /cubeos/config/defaults.env
    cap_add:
      - NET_ADMIN
    devices:
      - /dev/net/tun
    deploy:
      resources:
        limits:
          memory: 128M
    labels:
      - "cubeos.type=network"
      - "cubeos.port=6021"
```

#### tor
```yaml
# /cubeos/coreapps/tor/appconfig/docker-compose.yml
services:
  tor:
    image: dperson/torproxy:latest
    container_name: cubeos-tor
    restart: unless-stopped
    ports:
      - "6022:9050"   # SOCKS proxy
      - "6023:9051"   # Control port
    environment:
      - TZ=${TZ:-UTC}
    env_file:
      - /cubeos/config/defaults.env
    deploy:
      resources:
        limits:
          memory: 128M
    labels:
      - "cubeos.type=network"
      - "cubeos.port=6022"
```

### 3.4 AI/ML Layer

#### ollama
```yaml
# /cubeos/coreapps/ollama/appconfig/docker-compose.yml
services:
  ollama:
    image: ollama/ollama:latest
    container_name: cubeos-ollama
    restart: unless-stopped
    ports:
      - "6030:11434"
    volumes:
      - ../appdata:/root/.ollama
    environment:
      - OLLAMA_HOST=0.0.0.0
    deploy:
      resources:
        limits:
          memory: 2G
    labels:
      - "cubeos.type=ai"
      - "cubeos.port=6030"
```

#### chromadb
```yaml
# /cubeos/coreapps/chromadb/appconfig/docker-compose.yml
services:
  chromadb:
    image: chromadb/chroma:latest
    container_name: cubeos-chromadb
    restart: unless-stopped
    ports:
      - "6031:8000"
    volumes:
      - ../appdata:/chroma/chroma
    environment:
      - IS_PERSISTENT=TRUE
      - ANONYMIZED_TELEMETRY=FALSE
    deploy:
      resources:
        limits:
          memory: 512M
    labels:
      - "cubeos.type=ai"
      - "cubeos.port=6031"
```

---

## 4. Final Directory Structure

```
/cubeos/coreapps/
├── pihole/
│   ├── appconfig/
│   │   ├── docker-compose.yml
│   │   └── .env
│   └── appdata/
├── npm/
│   ├── appconfig/
│   │   └── docker-compose.yml
│   └── appdata/
├── registry/
│   ├── appconfig/
│   │   ├── docker-compose.yml
│   │   └── config.yml
│   └── appdata/
├── cubeos-api/
│   ├── appconfig/
│   │   └── docker-compose.yml
│   └── appdata/
├── cubeos-dashboard/
│   └── appconfig/
│       └── docker-compose.yml
├── dozzle/
│   └── appconfig/
│       └── docker-compose.yml
├── watchdog/
│   └── appconfig/
│       └── docker-compose.yml
├── wireguard/
│   └── appconfig/
│       └── docker-compose.yml
├── openvpn/
│   └── appconfig/
│       └── docker-compose.yml
├── tor/
│   └── appconfig/
│       └── docker-compose.yml
├── ollama/
│   ├── appconfig/
│   │   └── docker-compose.yml
│   └── appdata/
├── chromadb/
│   ├── appconfig/
│   │   └── docker-compose.yml
│   └── appdata/
├── docs-indexer/
│   ├── appconfig/
│   │   └── docker-compose.yml
│   ├── appdata/
│   └── src/
├── backup/
│   └── appconfig/
│       └── docker-compose.yml
├── diagnostics/
│   └── appconfig/
│       └── docker-compose.yml
├── reset/
│   └── appconfig/
│       └── docker-compose.yml
├── terminal/
│   └── appconfig/
│       └── docker-compose.yml
├── deploy-coreapps.sh
└── README.md
```

---

## 5. Migration Checklist

### Phase 1: Cleanup
- [ ] Delete `dockge/` directory
- [ ] Delete `gpio/` directory
- [ ] Delete `nettools/` directory
- [ ] Delete `usb-monitor/` directory
- [x] Remove any MuleCube references

### Phase 2: Restructure
- [ ] Rename `orchestrator/` to `cubeos-api/`
- [ ] Create `cubeos-dashboard/` directory
- [ ] Create `registry/` directory
- [ ] Create `wireguard/` directory
- [ ] Create `openvpn/` directory
- [ ] Create `tor/` directory

### Phase 3: Update Compose Files
- [ ] Update all ports to new scheme
- [ ] Update subnet to 10.42.24.0/24
- [ ] Add env_file references
- [ ] Add deploy blocks
- [ ] Add healthchecks
- [ ] Add CubeOS labels

### Phase 4: Test
- [ ] Test each coreapp as Swarm stack
- [ ] Test boot sequence
- [ ] Verify port allocations
- [ ] Test VPN connectivity
- [ ] Test Tor routing

---

*Document Version: 2.0*  
*Last Updated: January 31, 2026*
