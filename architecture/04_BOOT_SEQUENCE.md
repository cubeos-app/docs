# CubeOS Boot Sequence

**Document:** 04_BOOT_SEQUENCE.md  
**Version:** 2.0  
**Last Updated:** January 31, 2026

---

## 1. Overview

CubeOS has two boot modes:
1. **First Boot** - Initial setup, wizard mode
2. **Normal Boot** - Recovery/reconciliation mode

The boot sequence ensures services start in the correct order with proper dependencies.

---

## 2. Boot Order Summary

```
+-------+------------------+----------------------------------+----------+
| Order | Component        | Description                      | Type     |
+-------+------------------+----------------------------------+----------+
|   1   | Kernel + systemd | Linux boot                       | Host     |
|   2   | Watchdog         | Hardware watchdog enabled        | Host     |
|   3   | Docker           | Docker daemon starts             | Host     |
|   4   | Swarm Init       | Docker Swarm initialized         | Docker   |
|   5   | Pi-hole          | DNS + DHCP (host network)        | Stack    |
|   6   | NPM              | Reverse proxy (host network)     | Stack    |
|   7   | Registry         | Local Docker registry            | Stack    |
|   8   | hostapd          | WiFi Access Point                | Host     |
|   9   | cubeos-api       | Backend API (initializes DB)     | Stack    |
|  10   | cubeos-dashboard | Web frontend                     | Stack    |
|  11   | Other coreapps   | dozzle, watchdog, etc.           | Stack    |
|  12   | User apps        | Based on profile                 | Stack    |
+-------+------------------+----------------------------------+----------+
```

**Critical Note:** Database initialization happens when cubeos-api starts (step 9). All previous services operate without database access.

---

## 3. Boot Detection Logic

### 3.1 Decision Tree

```
System Power On
       |
       v
+------------------+
| systemd starts   |
| cubeos-init      |
+------------------+
       |
       v
+------------------+
| Enable watchdog  |
| (15s timeout)    |
+------------------+
       |
       v
+------------------+
| Check: Does      |
| /cubeos/data/    |
| .setup_complete  |
| exist?           |
+------------------+
       |
  +----+----+
  |         |
  NO        YES
  |         |
  v         v
FIRST     NORMAL
BOOT      BOOT
```

### 3.2 Detection Script

```bash
#!/bin/bash
# /usr/local/bin/cubeos-boot-detect.sh

SETUP_FLAG="/cubeos/data/.setup_complete"
DB_PATH="/cubeos/data/cubeos.db"

if [ ! -f "$SETUP_FLAG" ]; then
    echo "first-boot"
    exit 0
fi

if [ ! -f "$DB_PATH" ]; then
    echo "first-boot"
    exit 0
fi

echo "normal-boot"
exit 0
```

---

## 4. First Boot Sequence

### 4.1 Timeline

```
T+0s    Power on
T+5s    Linux kernel boots
T+10s   systemd reaches multi-user.target
T+12s   Watchdog enabled (15s timeout)
T+15s   cubeos-init.service starts
T+20s   Docker daemon ready
T+25s   Swarm initialized (--task-history-limit 1)
T+30s   Pi-hole stack deployed
T+40s   NPM stack deployed
T+45s   Registry stack deployed
T+50s   hostapd starts (AP active: CubeOS-Setup)
T+55s   cubeos-api stack deployed
        - Database created
        - Schema initialized
        - System apps seeded
        - Default profiles created
T+65s   cubeos-dashboard stack deployed
T+70s   Dashboard shows setup wizard
```

### 4.2 Detailed Steps

```
+------------------------------------------------------------------+
|                     FIRST BOOT SEQUENCE                           |
+------------------------------------------------------------------+

1. SYSTEM INITIALIZATION
   |
   +---> [cubeos-init.service] Runs /usr/local/bin/cubeos-first-boot.sh
         |
         +---> Enable hardware watchdog
         |     systemctl start watchdog
         |
         +---> Create directory structure
         |     mkdir -p /cubeos/{config,coreapps,apps,data,mounts}
         |
         +---> Generate secrets
         |     /usr/local/bin/cubeos-generate-secrets.sh
         |     -> /cubeos/config/secrets.env
         |
         +---> Create defaults.env
         |     -> /cubeos/config/defaults.env
         |
         +---> Initialize Docker Swarm
               docker swarm init \
                 --advertise-addr 10.42.24.1 \
                 --task-history-limit 1

2. INFRASTRUCTURE LAYER
   |
   +---> Deploy Pi-hole (network_mode: host)
   |     docker stack deploy -c /cubeos/coreapps/pihole/... pihole
   |     |
   |     +---> Wait for healthy (max 60s)
   |           Port 6001 responding
   |
   +---> Deploy NPM (network_mode: host)
   |     docker stack deploy -c /cubeos/coreapps/npm/... npm
   |     |
   |     +---> Wait for healthy (max 60s)
   |           Port 6000 responding
   |
   +---> Deploy Registry
   |     docker stack deploy -c /cubeos/coreapps/registry/... registry
   |     |
   |     +---> Wait for healthy (max 30s)
   |           Port 5000 responding
   |
   +---> Start hostapd (systemd)
         systemctl start hostapd
         |
         +---> AP broadcasting: "CubeOS-Setup" (open network)
         +---> DHCP: 10.42.24.10 - 10.42.24.250

3. PLATFORM LAYER
   |
   +---> Deploy cubeos-api
   |     docker stack deploy -c /cubeos/coreapps/cubeos-api/... cubeos-api
   |     |
   |     +---> On startup, API performs:
   |           1. Create /cubeos/data/cubeos.db if not exists
   |           2. Initialize schema (all tables)
   |           3. Run migrations
   |           4. Seed system apps to database
   |           5. Seed default profiles
   |           6. Set system_state.setup_complete = false
   |     |
   |     +---> Wait for healthy (max 60s)
   |           Port 6010 /health responding
   |
   +---> Deploy cubeos-dashboard
         docker stack deploy -c /cubeos/coreapps/cubeos-dashboard/... dashboard
         |
         +---> Wait for healthy
               Port 6011 responding

4. READY FOR SETUP
   |
   +---> User connects to WiFi AP "CubeOS-Setup"
   +---> User opens http://cubeos.cube or http://10.42.24.1
   +---> Dashboard shows setup wizard
   |
   +---> Wizard steps:
         1. Set admin password
         2. Configure WiFi AP name/password
         3. Select network mode (OFFLINE/ONLINE_ETH/ONLINE_WIFI)
         4. If ONLINE_WIFI: scan and connect to upstream WiFi
         5. Select profile (Full/Minimal/Offline)
         6. Complete setup

5. SETUP COMPLETE
   |
   +---> API updates database:
   |     - system_state.setup_complete = true
   |     - network_config.mode = selected_mode
   |     - Apply selected profile
   |
   +---> API creates file: /cubeos/data/.setup_complete
   |
   +---> Restart hostapd with new SSID/password
   |
   +---> Deploy remaining coreapps based on profile
   |
   +---> System enters normal operation
```

### 4.3 First Boot Scripts

#### cubeos-first-boot.sh

```bash
#!/bin/bash
# /usr/local/bin/cubeos-first-boot.sh

set -e

LOG_FILE="/var/log/cubeos-first-boot.log"
exec 1> >(tee -a "$LOG_FILE") 2>&1

echo "=== CubeOS First Boot ==="
echo "Started at: $(date)"

# Enable watchdog
echo "Enabling hardware watchdog..."
if [ -e /dev/watchdog ]; then
    systemctl start watchdog || true
fi

# Create directory structure
echo "Creating directory structure..."
mkdir -p /cubeos/{config,coreapps,apps,data,mounts}
mkdir -p /cubeos/data/registry
mkdir -p /cubeos/config/vpn/{wireguard,openvpn}

# Copy default configs
if [ ! -f /cubeos/config/defaults.env ]; then
    cat > /cubeos/config/defaults.env << 'EOF'
# CubeOS Default Configuration
TZ=UTC
DOMAIN=cubeos.cube
GATEWAY_IP=10.42.24.1
SUBNET=10.42.24.0/24
DHCP_RANGE_START=10.42.24.10
DHCP_RANGE_END=10.42.24.250
EOF
fi

# Generate secrets
if [ ! -f /cubeos/config/secrets.env ]; then
    echo "Generating secrets..."
    /usr/local/bin/cubeos-generate-secrets.sh
fi

# Wait for Docker
echo "Waiting for Docker..."
timeout 60 bash -c 'until docker info > /dev/null 2>&1; do sleep 1; done'

# Initialize Swarm
if ! docker info 2>/dev/null | grep -q "Swarm: active"; then
    echo "Initializing Docker Swarm..."
    docker swarm init \
        --advertise-addr 10.42.24.1 \
        --task-history-limit 1
fi

# Create overlay network
docker network create --driver overlay --attachable cubeos-network 2>/dev/null || true

# Deploy infrastructure
echo "Deploying Pi-hole..."
docker stack deploy -c /cubeos/coreapps/pihole/appconfig/docker-compose.yml pihole
wait_for_health "Pi-hole" "http://localhost:6001/admin/" 60

echo "Deploying NPM..."
docker stack deploy -c /cubeos/coreapps/npm/appconfig/docker-compose.yml npm
wait_for_health "NPM" "http://localhost:6000/api/" 60

echo "Deploying Registry..."
docker stack deploy -c /cubeos/coreapps/registry/appconfig/docker-compose.yml registry
wait_for_health "Registry" "http://localhost:5000/v2/" 30

# Start AP with open network for setup
echo "Starting WiFi AP (setup mode)..."
# Configure hostapd for open network
cat > /etc/hostapd/hostapd.conf << 'EOF'
interface=wlan0
driver=nl80211
ssid=CubeOS-Setup
hw_mode=g
channel=7
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=0
EOF
systemctl restart hostapd

# Deploy platform services
echo "Deploying CubeOS API..."
docker stack deploy -c /cubeos/coreapps/cubeos-api/appconfig/docker-compose.yml cubeos-api
wait_for_health "API" "http://localhost:6010/health" 60

echo "Deploying CubeOS Dashboard..."
docker stack deploy -c /cubeos/coreapps/cubeos-dashboard/appconfig/docker-compose.yml dashboard
wait_for_health "Dashboard" "http://localhost:6011/" 30

echo "=== First Boot Complete ==="
echo "Connect to WiFi 'CubeOS-Setup' and open http://10.42.24.1"

# Helper function
wait_for_health() {
    local name="$1"
    local url="$2"
    local timeout="$3"
    
    echo "Waiting for $name to be healthy..."
    for i in $(seq 1 $timeout); do
        if curl -sf "$url" > /dev/null 2>&1; then
            echo "$name is healthy"
            return 0
        fi
        sleep 1
    done
    echo "WARNING: $name health check timed out"
    return 1
}
```

#### cubeos-generate-secrets.sh

```bash
#!/bin/bash
# /usr/local/bin/cubeos-generate-secrets.sh

SECRETS_FILE="/cubeos/config/secrets.env"

generate_password() {
    openssl rand -base64 32 | tr -dc 'a-zA-Z0-9' | head -c 24
}

generate_secret() {
    openssl rand -hex 32
}

cat > "$SECRETS_FILE" << EOF
# CubeOS Generated Secrets
# Generated at: $(date)
# DO NOT COMMIT THIS FILE TO GIT

# API JWT Secret
JWT_SECRET=$(generate_secret)

# Default admin password (must change on first login)
ADMIN_PASSWORD=$(generate_password)

# Pi-hole admin password
PIHOLE_PASSWORD=$(generate_password)

# NPM default credentials
NPM_ADMIN_EMAIL=admin@cubeos.cube
NPM_ADMIN_PASSWORD=$(generate_password)
EOF

chmod 600 "$SECRETS_FILE"
echo "Secrets generated: $SECRETS_FILE"
```

---

## 5. Normal Boot Sequence (Recovery)

### 5.1 Timeline

```
T+0s    Power on
T+5s    Linux kernel boots
T+10s   systemd reaches multi-user.target
T+12s   Watchdog enabled
T+15s   cubeos-init.service starts
T+20s   Docker daemon ready
T+22s   Swarm rejoins (already initialized)
T+25s   Swarm reconciles all stacks automatically
T+30s   Pi-hole healthy
T+35s   NPM healthy
T+40s   hostapd starts (AP with saved config)
T+45s   cubeos-api healthy
T+50s   API runs ReconcileState()
T+55s   All enabled apps reconciled
T+60s   Network mode applied (NAT if online)
T+65s   System fully operational
```

### 5.2 Normal Boot Script

```bash
#!/bin/bash
# /usr/local/bin/cubeos-normal-boot.sh

set -e

LOG_FILE="/var/log/cubeos-boot.log"
exec 1> >(tee -a "$LOG_FILE") 2>&1

echo "=== CubeOS Normal Boot ==="
echo "Started at: $(date)"

# Enable watchdog
if [ -e /dev/watchdog ]; then
    systemctl start watchdog || true
fi

# Wait for Docker
echo "Waiting for Docker..."
timeout 60 bash -c 'until docker info > /dev/null 2>&1; do sleep 1; done'

# Verify Swarm
if ! docker info 2>/dev/null | grep -q "Swarm: active"; then
    echo "WARNING: Swarm not active, reinitializing..."
    docker swarm init \
        --advertise-addr 10.42.24.1 \
        --force-new-cluster \
        --task-history-limit 1 || true
fi

# Swarm auto-reconciles stacks
echo "Waiting for infrastructure..."

# Verify critical services
for i in $(seq 1 60); do
    if docker stack services pihole 2>/dev/null | grep -q "1/1"; then
        echo "Pi-hole running"
        break
    fi
    sleep 1
done

for i in $(seq 1 60); do
    if docker stack services npm 2>/dev/null | grep -q "1/1"; then
        echo "NPM running"
        break
    fi
    sleep 1
done

# Verify API (triggers ReconcileState on startup)
for i in $(seq 1 60); do
    if curl -sf http://localhost:6010/health > /dev/null 2>&1; then
        echo "API is healthy"
        break
    fi
    sleep 1
done

echo "=== Boot Complete ==="
```

---

## 6. systemd Service Files

### 6.1 cubeos-init.service

```ini
# /etc/systemd/system/cubeos-init.service

[Unit]
Description=CubeOS Initialization
After=docker.service
Wants=docker.service
Before=hostapd.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/bash -c '\
    if [ "$(/usr/local/bin/cubeos-boot-detect.sh)" = "first-boot" ]; then \
        /usr/local/bin/cubeos-first-boot.sh; \
    else \
        /usr/local/bin/cubeos-normal-boot.sh; \
    fi'
StandardOutput=journal
StandardError=journal
TimeoutStartSec=300

[Install]
WantedBy=multi-user.target
```

### 6.2 watchdog.service (systemd built-in)

```ini
# /etc/systemd/system.conf.d/99-watchdog.conf

[Manager]
RuntimeWatchdogSec=15
RebootWatchdogSec=10min
```

---

## 7. Database Initialization Timing

**Critical:** The database is initialized ONLY when `cubeos-api` starts:

```go
// cmd/cubeos-api/main.go

func main() {
    // Load configuration
    cfg := config.Load()
    
    // Connect to database (creates file if not exists)
    db, err := sqlx.Connect("sqlite", cfg.DatabasePath)
    if err != nil {
        log.Fatalf("Failed to connect to database: %v", err)
    }
    
    // Initialize schema
    if err := database.InitSchema(db); err != nil {
        log.Fatalf("Failed to initialize schema: %v", err)
    }
    
    // Run migrations
    if err := database.Migrate(db); err != nil {
        log.Fatalf("Failed to run migrations: %v", err)
    }
    
    // Seed system apps (idempotent)
    orchestrator := managers.NewOrchestrator(db)
    if err := orchestrator.SeedSystemApps(); err != nil {
        log.Printf("Warning: Failed to seed system apps: %v", err)
    }
    
    // Reconcile state on normal boot
    if isNormalBoot() {
        if err := orchestrator.ReconcileState(); err != nil {
            log.Printf("Warning: Reconciliation error: %v", err)
        }
    }
    
    // Start server...
}
```

**Services that DON'T need database:**
- Pi-hole (reads from .env and volumes)
- NPM (has its own internal DB)
- Registry (file-based storage)
- hostapd (reads /etc/hostapd/hostapd.conf)

**Services that DO need database:**
- cubeos-api (creates and manages it)
- cubeos-dashboard (queries via API)

---

## 8. Failure Handling

### 8.1 Watchdog Reset

If any boot step hangs for >15 seconds without kicking the watchdog, the system reboots automatically.

### 8.2 Infrastructure Failure Recovery

```bash
# If Pi-hole fails repeatedly
# System still boots, but no DNS/DHCP
# Dashboard shows critical warning

# If NPM fails
# Services still accessible by IP:port
# Dashboard shows warning

# If API fails
# Swarm keeps containers running
# Dashboard shows connection error
# Manual intervention: docker stack deploy ... cubeos-api
```

### 8.3 Manual Recovery

```bash
# Force restart all CubeOS stacks
docker stack ls | grep -v NAME | awk '{print $1}' | xargs -I {} docker stack rm {}
sleep 10
/usr/local/bin/cubeos-first-boot.sh

# Factory reset
rm -f /cubeos/data/.setup_complete
rm -f /cubeos/data/cubeos.db
rm -rf /cubeos/config/secrets.env
reboot
```

---

*Document Version: 2.0*  
*Last Updated: January 31, 2026*
