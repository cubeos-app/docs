# CubeOS Database Schema

**Document:** 03_DATABASE_SCHEMA.md  
**Version:** 2.0  
**Last Updated:** January 31, 2026

---

## 1. Overview

The new schema consolidates the fragmented `apps` and `installed_apps` tables into a single, unified data model. Docker Swarm is the Single Source of Truth for container state; the database stores configuration and metadata only.

### 1.1 Design Principles

1. **Swarm is Truth** - Container running state comes from Swarm, not DB
2. **DB stores Config** - Database stores what *should* be running, not what *is* running
3. **Single App Table** - No more `apps` vs `installed_apps` confusion
4. **Referential Integrity** - Foreign keys enforced, cascading deletes
5. **Audit Trail** - Created/updated timestamps on all tables
6. **Future-Proof** - Schema supports multi-node expansion

---

## 2. Schema Definition

### 2.1 Core Tables

```sql
-- =============================================================================
-- APPS: Unified application registry
-- =============================================================================
CREATE TABLE apps (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    name            TEXT UNIQUE NOT NULL,           -- Stack name (lowercase, no spaces)
    display_name    TEXT NOT NULL,                  -- Human-readable name
    description     TEXT DEFAULT '',
    
    -- Classification
    type            TEXT NOT NULL DEFAULT 'user',   -- 'system' | 'platform' | 'network' | 'ai' | 'user'
    category        TEXT DEFAULT 'other',           -- 'infrastructure' | 'media' | 'productivity' | etc.
    source          TEXT DEFAULT 'custom',          -- 'cubeos' | 'casaos' | 'custom'
    store_id        TEXT DEFAULT NULL,              -- Reference to app store (if installed from store)
    
    -- Paths
    compose_path    TEXT NOT NULL,                  -- /cubeos/{core}apps/{name}/appconfig/docker-compose.yml
    data_path       TEXT DEFAULT '',                -- /cubeos/{core}apps/{name}/appdata
    
    -- State (desired, not actual)
    enabled         BOOLEAN DEFAULT TRUE,           -- Should start on boot
    
    -- Networking
    tor_enabled     BOOLEAN DEFAULT FALSE,          -- Route through Tor
    vpn_enabled     BOOLEAN DEFAULT FALSE,          -- Route through VPN
    
    -- Metadata
    icon_url        TEXT DEFAULT '',
    version         TEXT DEFAULT '',
    homepage        TEXT DEFAULT '',
    
    -- Timestamps
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_apps_name ON apps(name);
CREATE INDEX idx_apps_type ON apps(type);
CREATE INDEX idx_apps_enabled ON apps(enabled);

-- =============================================================================
-- PORT_ALLOCATIONS: Track assigned ports per app
-- =============================================================================
CREATE TABLE port_allocations (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    app_id          INTEGER NOT NULL,
    port            INTEGER NOT NULL,
    protocol        TEXT DEFAULT 'tcp',             -- 'tcp' | 'udp'
    description     TEXT DEFAULT '',                -- 'Web UI' | 'API' | etc.
    is_primary      BOOLEAN DEFAULT FALSE,          -- Main access port for the app
    
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (app_id) REFERENCES apps(id) ON DELETE CASCADE,
    UNIQUE(port, protocol)
);

CREATE INDEX idx_ports_app ON port_allocations(app_id);
CREATE INDEX idx_ports_port ON port_allocations(port);

-- =============================================================================
-- FQDNS: DNS entries and reverse proxy mappings
-- =============================================================================
CREATE TABLE fqdns (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    app_id          INTEGER NOT NULL,
    fqdn            TEXT UNIQUE NOT NULL,           -- filebrowser.cubeos.cube
    subdomain       TEXT NOT NULL,                  -- filebrowser
    backend_port    INTEGER NOT NULL,               -- Port to proxy to
    ssl_enabled     BOOLEAN DEFAULT FALSE,          -- HTTPS enabled
    npm_proxy_id    INTEGER DEFAULT NULL,           -- NPM proxy host ID
    
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    
    FOREIGN KEY (app_id) REFERENCES apps(id) ON DELETE CASCADE
);

CREATE INDEX idx_fqdns_app ON fqdns(app_id);
CREATE INDEX idx_fqdns_subdomain ON fqdns(subdomain);

-- =============================================================================
-- PROFILES: Service profiles (Full, Minimal, Offline, Custom)
-- =============================================================================
CREATE TABLE profiles (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    name            TEXT UNIQUE NOT NULL,
    display_name    TEXT NOT NULL,
    description     TEXT DEFAULT '',
    is_active       BOOLEAN DEFAULT FALSE,          -- Only one can be active
    is_system       BOOLEAN DEFAULT FALSE,          -- System profiles can't be deleted
    
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- PROFILE_APPS: Which apps are enabled in each profile
-- =============================================================================
CREATE TABLE profile_apps (
    profile_id      INTEGER NOT NULL,
    app_id          INTEGER NOT NULL,
    enabled         BOOLEAN DEFAULT TRUE,
    
    PRIMARY KEY (profile_id, app_id),
    FOREIGN KEY (profile_id) REFERENCES profiles(id) ON DELETE CASCADE,
    FOREIGN KEY (app_id) REFERENCES apps(id) ON DELETE CASCADE
);

CREATE INDEX idx_profile_apps_profile ON profile_apps(profile_id);

-- =============================================================================
-- SYSTEM_STATE: System-wide state and flags
-- =============================================================================
CREATE TABLE system_state (
    key             TEXT PRIMARY KEY,
    value           TEXT NOT NULL,
    updated_at      DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- APP_HEALTH: Health check configuration per app
-- =============================================================================
CREATE TABLE app_health (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    app_id          INTEGER UNIQUE NOT NULL,
    
    -- Health check settings
    check_endpoint  TEXT DEFAULT '',                -- HTTP endpoint to check
    check_interval  INTEGER DEFAULT 30,             -- Seconds between checks
    check_timeout   INTEGER DEFAULT 10,             -- Seconds before timeout
    max_retries     INTEGER DEFAULT 3,              -- Retries before marking unhealthy
    
    -- Alert settings
    alert_after     INTEGER DEFAULT 300,            -- Seconds unhealthy before alert
    
    FOREIGN KEY (app_id) REFERENCES apps(id) ON DELETE CASCADE
);

-- =============================================================================
-- NETWORK_CONFIG: Network mode and WiFi settings
-- =============================================================================
CREATE TABLE network_config (
    id              INTEGER PRIMARY KEY CHECK (id = 1),  -- Single row
    mode            TEXT DEFAULT 'offline',         -- 'offline' | 'online_eth' | 'online_wifi'
    wifi_ssid       TEXT DEFAULT '',                -- Upstream WiFi SSID (for online_wifi)
    wifi_password   TEXT DEFAULT '',                -- Encrypted or reference to secrets.env
    eth_interface   TEXT DEFAULT 'eth0',
    wifi_ap_interface TEXT DEFAULT 'wlan0',
    wifi_client_interface TEXT DEFAULT 'wlan1',     -- USB dongle
    
    updated_at      DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- VPN_CONFIGS: VPN configuration profiles
-- =============================================================================
CREATE TABLE vpn_configs (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    name            TEXT UNIQUE NOT NULL,
    type            TEXT NOT NULL,                  -- 'wireguard' | 'openvpn'
    config_path     TEXT NOT NULL,                  -- Path to config file
    is_active       BOOLEAN DEFAULT FALSE,          -- Currently connected
    auto_connect    BOOLEAN DEFAULT FALSE,          -- Connect on boot
    
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- MOUNTS: SMB/NFS mount configurations
-- =============================================================================
CREATE TABLE mounts (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    name            TEXT UNIQUE NOT NULL,           -- Mount point name
    type            TEXT NOT NULL,                  -- 'smb' | 'nfs'
    remote_path     TEXT NOT NULL,                  -- //server/share or server:/path
    local_path      TEXT NOT NULL,                  -- /cubeos/mounts/{name}
    username        TEXT DEFAULT '',                -- For SMB
    password        TEXT DEFAULT '',                -- Encrypted or reference
    options         TEXT DEFAULT '',                -- Mount options
    auto_mount      BOOLEAN DEFAULT FALSE,          -- Mount on boot
    is_mounted      BOOLEAN DEFAULT FALSE,          -- Current state
    
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- BACKUPS: Backup job configurations
-- =============================================================================
CREATE TABLE backups (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    name            TEXT UNIQUE NOT NULL,
    destination     TEXT NOT NULL,                  -- Mount name or path
    include_apps    TEXT DEFAULT '*',               -- JSON array or '*' for all
    schedule        TEXT DEFAULT '',                -- Cron expression
    retention_days  INTEGER DEFAULT 30,
    last_run        DATETIME,
    last_status     TEXT DEFAULT '',
    
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- USERS: Authentication
-- =============================================================================
CREATE TABLE users (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    username        TEXT UNIQUE NOT NULL,
    password_hash   TEXT NOT NULL,
    role            TEXT DEFAULT 'admin',           -- 'admin' | 'user' | 'readonly'
    
    created_at      DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- PREFERENCES: User/system preferences
-- =============================================================================
CREATE TABLE preferences (
    key             TEXT PRIMARY KEY,
    value           TEXT NOT NULL,
    updated_at      DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- =============================================================================
-- NODES: For future multi-node Swarm support
-- =============================================================================
CREATE TABLE nodes (
    id              TEXT PRIMARY KEY,               -- Docker node ID
    hostname        TEXT NOT NULL,
    role            TEXT DEFAULT 'worker',          -- 'manager' | 'worker'
    status          TEXT DEFAULT 'unknown',         -- 'ready' | 'down' | 'unknown'
    ip_address      TEXT,
    
    joined_at       DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_seen       DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

### 2.2 Seed Data

```sql
-- =============================================================================
-- DEFAULT PROFILES
-- =============================================================================
INSERT INTO profiles (name, display_name, description, is_system) VALUES
    ('full', 'Full', 'All services enabled', TRUE),
    ('minimal', 'Minimal', 'Only essential services', TRUE),
    ('offline', 'Offline', 'Optimized for offline use', TRUE);

-- =============================================================================
-- SYSTEM STATE DEFAULTS
-- =============================================================================
INSERT INTO system_state (key, value) VALUES
    ('setup_complete', 'false'),
    ('swarm_initialized', 'false'),
    ('last_boot', ''),
    ('version', '1.0.0'),
    ('domain', 'cubeos.cube'),
    ('gateway_ip', '10.42.24.1'),
    ('subnet', '10.42.24.0/24');

-- =============================================================================
-- DEFAULT NETWORK CONFIG
-- =============================================================================
INSERT INTO network_config (id, mode) VALUES (1, 'offline');

-- =============================================================================
-- CORE APPS (seeded on first boot by API)
-- =============================================================================
-- See SeedSystemApps() in orchestrator.go
```

---

## 3. Data Model (Go)

### 3.1 App Model

```go
// internal/models/app.go

package models

import "time"

type AppType string

const (
    AppTypeSystem   AppType = "system"   // Infrastructure (pihole, npm)
    AppTypePlatform AppType = "platform" // CubeOS services (api, dashboard)
    AppTypeNetwork  AppType = "network"  // VPN, Tor
    AppTypeAI       AppType = "ai"       // Ollama, ChromaDB
    AppTypeUser     AppType = "user"     // User-installed apps
)

type AppSource string

const (
    AppSourceCubeOS AppSource = "cubeos"
    AppSourceCasaOS AppSource = "casaos"
    AppSourceCustom AppSource = "custom"
)

type App struct {
    ID          int64     `db:"id" json:"id"`
    Name        string    `db:"name" json:"name"`
    DisplayName string    `db:"display_name" json:"display_name"`
    Description string    `db:"description" json:"description"`
    Type        AppType   `db:"type" json:"type"`
    Category    string    `db:"category" json:"category"`
    Source      AppSource `db:"source" json:"source"`
    StoreID     *string   `db:"store_id" json:"store_id,omitempty"`
    ComposePath string    `db:"compose_path" json:"compose_path"`
    DataPath    string    `db:"data_path" json:"data_path"`
    Enabled     bool      `db:"enabled" json:"enabled"`
    TorEnabled  bool      `db:"tor_enabled" json:"tor_enabled"`
    VPNEnabled  bool      `db:"vpn_enabled" json:"vpn_enabled"`
    IconURL     string    `db:"icon_url" json:"icon_url"`
    Version     string    `db:"version" json:"version"`
    Homepage    string    `db:"homepage" json:"homepage"`
    CreatedAt   time.Time `db:"created_at" json:"created_at"`
    UpdatedAt   time.Time `db:"updated_at" json:"updated_at"`
    
    // Related data
    Ports []Port `db:"-" json:"ports,omitempty"`
    FQDNs []FQDN `db:"-" json:"fqdns,omitempty"`
    
    // Runtime status from Swarm
    Status *AppStatus `db:"-" json:"status,omitempty"`
}

type AppStatus struct {
    Running     bool   `json:"running"`
    Health      string `json:"health"`
    Replicas    string `json:"replicas"`
    LastStarted string `json:"last_started,omitempty"`
    Error       string `json:"error,omitempty"`
}

type Port struct {
    ID          int64  `db:"id" json:"id"`
    AppID       int64  `db:"app_id" json:"app_id"`
    Port        int    `db:"port" json:"port"`
    Protocol    string `db:"protocol" json:"protocol"`
    Description string `db:"description" json:"description"`
    IsPrimary   bool   `db:"is_primary" json:"is_primary"`
}

type FQDN struct {
    ID          int64  `db:"id" json:"id"`
    AppID       int64  `db:"app_id" json:"app_id"`
    FQDN        string `db:"fqdn" json:"fqdn"`
    Subdomain   string `db:"subdomain" json:"subdomain"`
    BackendPort int    `db:"backend_port" json:"backend_port"`
    SSLEnabled  bool   `db:"ssl_enabled" json:"ssl_enabled"`
    NPMProxyID  *int   `db:"npm_proxy_id" json:"npm_proxy_id,omitempty"`
}
```

### 3.2 Network Model

```go
// internal/models/network.go

package models

import "time"

type NetworkMode string

const (
    NetworkModeOffline    NetworkMode = "offline"
    NetworkModeOnlineETH  NetworkMode = "online_eth"
    NetworkModeOnlineWiFi NetworkMode = "online_wifi"
)

type NetworkConfig struct {
    ID                   int         `db:"id" json:"id"`
    Mode                 NetworkMode `db:"mode" json:"mode"`
    WiFiSSID             string      `db:"wifi_ssid" json:"wifi_ssid"`
    WiFiPassword         string      `db:"wifi_password" json:"-"`  // Never expose
    EthInterface         string      `db:"eth_interface" json:"eth_interface"`
    WiFiAPInterface      string      `db:"wifi_ap_interface" json:"wifi_ap_interface"`
    WiFiClientInterface  string      `db:"wifi_client_interface" json:"wifi_client_interface"`
    UpdatedAt            time.Time   `db:"updated_at" json:"updated_at"`
}

type VPNConfig struct {
    ID          int64     `db:"id" json:"id"`
    Name        string    `db:"name" json:"name"`
    Type        string    `db:"type" json:"type"`  // wireguard | openvpn
    ConfigPath  string    `db:"config_path" json:"config_path"`
    IsActive    bool      `db:"is_active" json:"is_active"`
    AutoConnect bool      `db:"auto_connect" json:"auto_connect"`
    CreatedAt   time.Time `db:"created_at" json:"created_at"`
    UpdatedAt   time.Time `db:"updated_at" json:"updated_at"`
}

type Mount struct {
    ID         int64     `db:"id" json:"id"`
    Name       string    `db:"name" json:"name"`
    Type       string    `db:"type" json:"type"`  // smb | nfs
    RemotePath string    `db:"remote_path" json:"remote_path"`
    LocalPath  string    `db:"local_path" json:"local_path"`
    Username   string    `db:"username" json:"username,omitempty"`
    Options    string    `db:"options" json:"options,omitempty"`
    AutoMount  bool      `db:"auto_mount" json:"auto_mount"`
    IsMounted  bool      `db:"is_mounted" json:"is_mounted"`
    CreatedAt  time.Time `db:"created_at" json:"created_at"`
}
```

---

## 4. Port Allocation Logic

```go
// internal/managers/ports.go

const (
    // System reserved (host mode services)
    PortSSH      = 22
    PortDNS      = 53
    PortDHCP     = 67
    PortHTTP     = 80
    PortHTTPS    = 443
    
    // Infrastructure range
    PortRegistry = 5000
    PortNPM      = 6000
    PortPihole   = 6001
    
    // Platform range: 6010-6019
    PortAPI       = 6010
    PortDashboard = 6011
    PortDozzle    = 6012
    
    // Network range: 6020-6029
    PortWireGuard = 6020
    PortOpenVPN   = 6021
    PortTor       = 6022
    
    // AI/ML range: 6030-6039
    PortOllama    = 6030
    PortChromaDB  = 6031
    PortDocsIndex = 6032
    
    // User apps: 6100-6999
    UserPortMin = 6100
    UserPortMax = 6999
)

func (p *PortManager) AllocateUserPort() (int, error) {
    // Find next available port in 6100-6999 range
    var maxPort int
    err := p.db.QueryRow(`
        SELECT COALESCE(MAX(port), 6099) 
        FROM port_allocations 
        WHERE port >= ? AND port <= ?
    `, UserPortMin, UserPortMax).Scan(&maxPort)
    
    if err != nil {
        return 0, err
    }
    
    nextPort := maxPort + 1
    if nextPort > UserPortMax {
        return 0, fmt.Errorf("no available ports in user range")
    }
    
    return nextPort, nil
}
```

---

## 5. Migration Notes

### 5.1 Fresh Start Approach

Since we're doing a fresh start (not migrating data):

1. Delete old `cubeos.db`
2. API creates new schema on startup
3. API seeds system apps (pihole, npm, api, dashboard, etc.)
4. API seeds default profiles
5. User re-installs any custom apps

### 5.2 Schema Versioning

```go
// internal/database/migrations.go

const CurrentSchemaVersion = 1

func (db *Database) Migrate() error {
    var version int
    err := db.QueryRow("SELECT value FROM system_state WHERE key = 'schema_version'").Scan(&version)
    if err != nil {
        version = 0
    }
    
    if version < 1 {
        // Initial schema - already applied in InitSchema
    }
    
    // Future migrations:
    // if version < 2 { ... }
    
    db.Exec("INSERT OR REPLACE INTO system_state (key, value) VALUES ('schema_version', ?)", CurrentSchemaVersion)
    return nil
}
```

---

*Document Version: 2.0*  
*Last Updated: January 31, 2026*
