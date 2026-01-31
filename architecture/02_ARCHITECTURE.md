# CubeOS Technical Architecture

**Document:** 02_ARCHITECTURE.md  
**Version:** 2.0  
**Last Updated:** January 31, 2026

---

## 1. System Overview

### 1.1 High-Level Architecture

```
+------------------------------------------------------------------+
|                        CUBEOS SYSTEM                              |
+------------------------------------------------------------------+
|                                                                    |
|  +------------------------+     +---------------------------+     |
|  |     HOST SERVICES      |     |    DOCKER SWARM           |     |
|  |  (systemd managed)     |     |    (container runtime)    |     |
|  +------------------------+     +---------------------------+     |
|  |                        |     |                           |     |
|  |  - hostapd (WiFi AP)   |     |  INFRASTRUCTURE LAYER     |     |
|  |  - wpa_supplicant      |     |  +---------------------+  |     |
|  |  - systemd-resolved    |     |  | pihole (host mode)  |  |     |
|  |  - cubeos-init.service |     |  | npm (host mode)     |  |     |
|  |  - watchdog            |     |  | registry            |  |     |
|  |  - fail2ban            |     |  +---------------------+  |     |
|  +------------------------+     |                           |     |
|                                 |  PLATFORM LAYER           |     |
|                                 |  +---------------------+  |     |
|                                 |  | cubeos-api          |  |     |
|                                 |  | cubeos-dashboard    |  |     |
|                                 |  | dozzle (logging)    |  |     |
|                                 |  | watchdog            |  |     |
|                                 |  +---------------------+  |     |
|                                 |                           |     |
|                                 |  NETWORK LAYER            |     |
|                                 |  +---------------------+  |     |
|                                 |  | wireguard           |  |     |
|                                 |  | openvpn             |  |     |
|                                 |  | tor                 |  |     |
|                                 |  +---------------------+  |     |
|                                 |                           |     |
|                                 |  APPLICATION LAYER        |     |
|                                 |  +---------------------+  |     |
|                                 |  | ollama              |  |     |
|                                 |  | chromadb            |  |     |
|                                 |  | docs-indexer        |  |     |
|                                 |  | user-installed apps |  |     |
|                                 |  +---------------------+  |     |
|                                 +---------------------------+     |
+------------------------------------------------------------------+
```

### 1.2 Service Layers

| Layer | Services | Network Mode | Port Range | Startup Order |
|-------|----------|--------------|------------|---------------|
| Infrastructure | pihole, npm, registry | host | 53,67,80,443,5000,6000,6001 | 1, 2, 3 |
| Platform | api, dashboard, dozzle, watchdog | bridge | 6010-6019 | 4, 5, 6, 7 |
| Network | wireguard, openvpn, tor | bridge | 6020-6029 | 8, 9, 10 |
| AI/ML | ollama, chromadb, docs-indexer | bridge | 6030-6039 | 11, 12, 13 |
| Application | user apps | bridge | 6100-6999 | 14+ |

---

## 2. Component Architecture

### 2.1 API Server Components

```
cmd/cubeos-api/main.go
    |
    v
internal/
├── config/
│   └── config.go              # Environment loading, defaults
│
├── database/
│   ├── database.go            # SQLite connection
│   ├── schema.go              # Schema definitions
│   └── migrations.go          # Schema migrations
│
├── managers/
│   ├── swarm.go               # Docker Swarm API wrapper
│   ├── orchestrator.go        # Central coordinator
│   ├── registry.go            # Local registry manager
│   ├── compose.go             # Compose file parsing/transformation
│   ├── npm.go                 # NPM API client
│   ├── pihole.go              # Pi-hole API client
│   ├── ports.go               # Port allocation
│   ├── network.go             # Network mode management
│   ├── vpn.go                 # VPN client management
│   ├── backup.go              # Backup to SMB/NFS
│   ├── system.go              # System info (CPU, RAM, temp)
│   └── ...                    # Other existing managers
│
├── handlers/
│   ├── apps.go                # Unified app endpoints
│   ├── profiles.go            # Profile endpoints
│   ├── network.go             # Network mode endpoints
│   ├── vpn.go                 # VPN endpoints
│   ├── backup.go              # Backup endpoints
│   ├── system.go              # System endpoints
│   └── ...                    # Other handlers
│
└── models/
    ├── app.go                 # Unified app model
    ├── profile.go             # Profile model
    ├── network.go             # Network mode model
    └── ...                    # Other models
```

### 2.2 SwarmManager

The SwarmManager wraps the Docker Swarm API:

```go
// internal/managers/swarm.go

type SwarmManager struct {
    client *client.Client
    ctx    context.Context
}

// Core operations
func (s *SwarmManager) Init(advertiseAddr string) error
func (s *SwarmManager) IsSwarmActive() (bool, error)
func (s *SwarmManager) DeployStack(name, composePath string) error
func (s *SwarmManager) RemoveStack(name string) error
func (s *SwarmManager) GetStackServices(name string) ([]swarm.Service, error)
func (s *SwarmManager) GetServiceStatus(name string) (*ServiceStatus, error)
func (s *SwarmManager) GetServiceLogs(name string, lines int) ([]string, error)
func (s *SwarmManager) UpdateService(name string, opts UpdateOptions) error
func (s *SwarmManager) ListStacks() ([]Stack, error)
func (s *SwarmManager) SetTaskHistoryLimit(limit int) error  // Memory optimization
```

### 2.3 Orchestrator

The Orchestrator coordinates all app operations:

```go
// internal/managers/orchestrator.go

type Orchestrator struct {
    db            *sql.DB
    swarm         *SwarmManager
    npm           *NPMManager
    pihole        *PiholeManager
    registry      *RegistryManager
    ports         *PortManager
    network       *NetworkManager
}

// High-level operations
func (o *Orchestrator) InstallApp(req InstallRequest) (*App, error)
func (o *Orchestrator) UninstallApp(name string) error
func (o *Orchestrator) StartApp(name string) error
func (o *Orchestrator) StopApp(name string) error
func (o *Orchestrator) RestartApp(name string) error
func (o *Orchestrator) EnableApp(name string) error
func (o *Orchestrator) DisableApp(name string) error
func (o *Orchestrator) GetApp(name string) (*App, error)
func (o *Orchestrator) ListApps() ([]*App, error)
func (o *Orchestrator) ApplyProfile(profileID int) error
func (o *Orchestrator) ReconcileState() error
func (o *Orchestrator) SetNetworkMode(mode NetworkMode) error
```

### 2.4 NetworkManager

Manages network modes and connectivity:

```go
// internal/managers/network.go

type NetworkMode string

const (
    NetworkModeOffline    NetworkMode = "offline"
    NetworkModeOnlineETH  NetworkMode = "online_eth"
    NetworkModeOnlineWiFi NetworkMode = "online_wifi"
)

type NetworkManager struct {
    currentMode NetworkMode
    db          *sql.DB
}

func (n *NetworkManager) GetCurrentMode() NetworkMode
func (n *NetworkManager) SetMode(mode NetworkMode) error
func (n *NetworkManager) ScanWiFiNetworks() ([]WiFiNetwork, error)
func (n *NetworkManager) ConnectToWiFi(ssid, password string) error
func (n *NetworkManager) GetWiFiStatus() (*WiFiStatus, error)
func (n *NetworkManager) EnableNAT(sourceInterface, destInterface string) error
func (n *NetworkManager) DisableNAT() error
func (n *NetworkManager) ConfigureFirewall(mode NetworkMode) error
```

---

## 3. Data Flow

### 3.1 App Installation Flow

```
User clicks "Install" in Dashboard
            |
            v
POST /api/v1/apps
{name: "filebrowser", store_id: "casaos-official"}
            |
            v
+-------------------+
| Apps Handler      |
+-------------------+
            |
            v
+-------------------+
| Orchestrator      |
+-------------------+
     |    |    |
     |    |    +---> PortManager.AllocatePort() --> returns 6100
     |    |
     |    +---> ComposeTransformer.Transform() --> Swarm-ready YAML
     |
     +---> Write to /cubeos/apps/filebrowser/appconfig/docker-compose.yml
            |
            v
+-------------------+
| SwarmManager      |
+-------------------+
            |
            +---> docker stack deploy -c ... filebrowser
            |
            v
+-------------------+
| NPMManager        |
+-------------------+
            |
            +---> Create proxy host: filebrowser.cubeos.cube -> localhost:6100
            |
            v
+-------------------+
| PiholeManager     |
+-------------------+
            |
            +---> Add DNS: filebrowser.cubeos.cube -> 10.42.24.1
            |
            v
+-------------------+
| Database          |
+-------------------+
            |
            +---> INSERT INTO apps (name, port, fqdn, enabled, ...)
            |
            v
Return {id: 1, name: "filebrowser", fqdn: "filebrowser.cubeos.cube", ...}
```

### 3.2 Network Mode Switch Flow

```
User selects "ONLINE_WIFI" mode in Dashboard
            |
            v
POST /api/v1/network/mode
{mode: "online_wifi", ssid: "HomeNetwork", password: "***"}
            |
            v
+-------------------+
| Network Handler   |
+-------------------+
            |
            v
+-------------------+
| NetworkManager    |
+-------------------+
     |    |    |
     |    |    +---> Save credentials to /cubeos/config/wifi.env
     |    |
     |    +---> wpa_supplicant connect to HomeNetwork via wlan1
     |
     +---> Wait for connection (timeout 30s)
            |
            v
+-------------------+
| Firewall Config   |
+-------------------+
            |
            +---> Enable NAT: wlan0 -> wlan1
            +---> Update iptables rules
            |
            v
+-------------------+
| Database          |
+-------------------+
            |
            +---> UPDATE system_state SET network_mode = 'online_wifi'
            |
            v
Return {mode: "online_wifi", internet: true, upstream_ssid: "HomeNetwork"}
```

---

## 4. Directory Structure

### 4.1 System Directories

```
/cubeos/
├── config/
│   ├── defaults.env           # Shared defaults (TZ, DOMAIN, GATEWAY_IP)
│   ├── secrets.env            # Generated secrets (not in git)
│   ├── wifi.env               # WiFi credentials (ONLINE_WIFI mode)
│   └── vpn/                   # VPN configuration files
│       ├── wireguard/
│       └── openvpn/
│
├── coreapps/                  # System services (protected)
│   ├── pihole/
│   │   ├── appconfig/
│   │   │   ├── docker-compose.yml
│   │   │   └── .env
│   │   └── appdata/
│   ├── npm/
│   ├── registry/
│   ├── cubeos-api/
│   ├── cubeos-dashboard/
│   ├── dozzle/
│   ├── watchdog/
│   ├── wireguard/
│   ├── openvpn/
│   ├── tor/
│   ├── ollama/
│   ├── chromadb/
│   └── docs-indexer/
│
├── apps/                      # User-installed apps (removable)
│   └── {app-name}/
│       ├── appconfig/
│       │   ├── docker-compose.yml
│       │   └── .env
│       └── appdata/
│
├── mounts/                    # SMB/NFS mount points
│   └── {mount-name}/
│
└── data/
    ├── cubeos.db              # SQLite database
    ├── .setup_complete        # First-boot flag file
    └── registry/              # Registry storage
```

### 4.2 Repository Structure

```
api/                           # Go backend
├── cmd/cubeos-api/main.go
├── internal/
│   ├── config/
│   ├── database/
│   ├── handlers/
│   ├── managers/
│   ├── middleware/
│   └── models/
├── go.mod
├── Dockerfile
├── Makefile
└── .gitlab-ci.yml

dashboard/                     # Vue.js frontend
├── src/
│   ├── api/
│   ├── components/
│   │   ├── swarm/             # Swarm management GUI
│   │   ├── network/           # Network mode UI
│   │   ├── vpn/               # VPN configuration UI
│   │   └── ...
│   ├── stores/
│   ├── router/
│   └── assets/
├── package.json
├── Dockerfile
└── .gitlab-ci.yml

coreapps/                      # Docker compose files
├── pihole/
├── npm/
├── registry/
├── cubeos-api/
├── cubeos-dashboard/
├── dozzle/
├── watchdog/
├── wireguard/
├── openvpn/
├── tor/
├── ollama/
├── chromadb/
├── docs-indexer/
├── deploy-coreapps.sh
└── .gitlab-ci.yml

scripts/                       # Deployment and utility scripts
├── init-swarm.sh
├── first-boot.sh
├── recovery.sh
├── backup.sh
├── network-mode.sh
└── hardening.sh

releases/                      # Packer image builder
├── packer/
├── imager-manifest.json       # Raspberry Pi Imager JSON
└── .gitlab-ci.yml

docs/                          # Documentation
├── architecture/
├── user-guide/
└── api-reference/
```

---

## 5. Network Architecture

### 5.1 Network Topology (ONLINE_ETH Mode)

```
                    INTERNET
                        |
                        v
+------------------[eth0]------------------+
|                                          |
|            Raspberry Pi 5                |
|         Subnet: 10.42.24.0/24            |
|         Gateway: 10.42.24.1              |
|                                          |
|   +----------------+  +---------------+  |
|   |   Pi-hole      |  |     NPM       |  |
|   | (host network) |  | (host network)|  |
|   |                |  |               |  |
|   | DNS: 53        |  | HTTP: 80      |  |
|   | DHCP: 67       |  | HTTPS: 443    |  |
|   | Admin: 6001    |  | Admin: 6000   |  |
|   +----------------+  +---------------+  |
|                                          |
|   +------------------------------------+ |
|   |        cubeos-network (bridge)     | |
|   |                                    | |
|   |  +----------+  +---------------+   | |
|   |  | api:6010 |  | dashboard:6011|   | |
|   |  +----------+  +---------------+   | |
|   |                                    | |
|   |  +----------+  +---------------+   | |
|   |  | ollama   |  | chromadb      |   | |
|   |  | :6030    |  | :6031         |   | |
|   |  +----------+  +---------------+   | |
|   +------------------------------------+ |
|                                          |
|   NAT: 10.42.24.0/24 -> eth0            |
|                                          |
+------------------[wlan0]-----------------+
                        |
                        v
              WiFi Access Point
             (10.42.24.0/24)
                        |
                        v
                Connected Clients
            (10.42.24.10 - 10.42.24.250)
```

### 5.2 Network Topology (ONLINE_WIFI Mode)

```
                    INTERNET
                        |
                        v
              Upstream WiFi Router
                        |
                        v
+------------------[wlan1]-----------------+
|            (USB WiFi Dongle)             |
|            Client connection             |
|                                          |
|            Raspberry Pi 5                |
|         Subnet: 10.42.24.0/24            |
|                                          |
|   NAT: 10.42.24.0/24 -> wlan1           |
|                                          |
+------------------[wlan0]-----------------+
                        |
                        v
              WiFi Access Point
             (10.42.24.0/24)
                        |
                        v
                Connected Clients
```

### 5.3 Port Allocation (Strict Scheme)

| Range | Purpose | Examples |
|-------|---------|----------|
| 22 | SSH | System |
| 53 | DNS | Pi-hole |
| 67 | DHCP | Pi-hole |
| 80, 443 | HTTP/HTTPS | NPM |
| 5000 | Local Registry | registry |
| 6000 | NPM Admin | npm |
| 6001 | Pi-hole Admin | pihole |
| 6010-6019 | Platform Services | api (6010), dashboard (6011), dozzle (6012) |
| 6020-6029 | Network Services | wireguard (6020), openvpn (6021), tor (6022) |
| 6030-6039 | AI/ML Services | ollama (6030), chromadb (6031), docs-indexer (6032) |
| 6040-6099 | Reserved | Future system services |
| 6100-6999 | User Applications | Dynamically allocated |

**NO EXCEPTIONS** - All apps must comply with this scheme.

### 5.4 DNS Resolution

All services accessible via `{service}.cubeos.cube`:

| FQDN | Target | Port |
|------|--------|------|
| cubeos.cube | 10.42.24.1 | 80 (NPM) |
| api.cubeos.cube | 10.42.24.1 | 6010 |
| pihole.cubeos.cube | 10.42.24.1 | 6001 |
| npm.cubeos.cube | 10.42.24.1 | 6000 |
| ollama.cubeos.cube | 10.42.24.1 | 6030 |
| {app}.cubeos.cube | 10.42.24.1 | {allocated} |

---

## 6. Security Architecture

### 6.1 Authentication Flow

```
Client                    API                      Database
   |                       |                           |
   |  POST /auth/login     |                           |
   |  {user, password}     |                           |
   |---------------------->|                           |
   |                       |  SELECT user WHERE ...    |
   |                       |-------------------------->|
   |                       |  user record              |
   |                       |<--------------------------|
   |                       |                           |
   |                       |  bcrypt.Compare()         |
   |                       |                           |
   |  {token: "eyJ..."}    |                           |
   |<----------------------|                           |
   |                       |                           |
   |  GET /api/v1/apps     |                           |
   |  Authorization: Bearer eyJ...                     |
   |---------------------->|                           |
   |                       |  jwt.Verify()             |
   |                       |                           |
   |  [{apps...}]          |                           |
   |<----------------------|                           |
```

### 6.2 Secrets Management

| Secret | Generation | Storage |
|--------|------------|---------|
| API JWT Secret | Random 32 bytes on first boot | `/cubeos/config/secrets.env` |
| NPM Admin Password | Generated on first boot | `/cubeos/coreapps/npm/appconfig/.env` |
| Pi-hole Password | Generated on first boot | `/cubeos/coreapps/pihole/appconfig/.env` |
| WiFi Credentials | User input | `/cubeos/config/wifi.env` |
| VPN Keys | User import or generated | `/cubeos/config/vpn/` |

### 6.3 Firewall Rules (Per Network Mode)

**OFFLINE Mode:**
```bash
# Block all outbound except local
iptables -P OUTPUT DROP
iptables -A OUTPUT -o lo -j ACCEPT
iptables -A OUTPUT -d 10.42.24.0/24 -j ACCEPT
```

**ONLINE_ETH Mode:**
```bash
# NAT for AP clients
iptables -t nat -A POSTROUTING -s 10.42.24.0/24 -o eth0 -j MASQUERADE
iptables -A FORWARD -i wlan0 -o eth0 -j ACCEPT
iptables -A FORWARD -i eth0 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT
```

**ONLINE_WIFI Mode:**
```bash
# NAT for AP clients via USB WiFi
iptables -t nat -A POSTROUTING -s 10.42.24.0/24 -o wlan1 -j MASQUERADE
iptables -A FORWARD -i wlan0 -o wlan1 -j ACCEPT
iptables -A FORWARD -i wlan1 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT
```

---

## 7. Future-Proofing

### 7.1 Multi-Node Swarm Readiness

The architecture supports expansion to multi-node Swarm:

```go
// Database schema supports node tracking
type Node struct {
    ID        string
    Hostname  string
    Role      string  // "manager" | "worker"
    Status    string
    JoinedAt  time.Time
}

// SwarmManager can be extended
func (s *SwarmManager) AddWorker(joinToken string) error
func (s *SwarmManager) ListNodes() ([]Node, error)
func (s *SwarmManager) DrainNode(nodeID string) error
```

### 7.2 Plugin Architecture Considerations

```go
// Future plugin interface
type Plugin interface {
    Name() string
    Version() string
    Init(ctx context.Context) error
    Shutdown() error
    RegisterRoutes(r chi.Router)
}
```

---

*Document Version: 2.0*  
*Last Updated: January 31, 2026*
