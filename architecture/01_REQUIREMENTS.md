# CubeOS Requirements Specification

**Document:** 01_REQUIREMENTS.md  
**Version:** 2.0  
**Last Updated:** January 31, 2026

---

## 1. Functional Requirements

### 1.1 Boot Sequence

| ID | Requirement | Priority |
|----|-------------|----------|
| BOOT-01 | System must initialize Docker Swarm on first boot | Critical |
| BOOT-02 | Database must initialize before API starts | Critical |
| BOOT-03 | Pi-hole must start before any other containerized service | Critical |
| BOOT-04 | NPM must start after Pi-hole, before user-facing services | Critical |
| BOOT-05 | Access Point (hostapd) must start after DHCP (Pi-hole) is ready | Critical |
| BOOT-06 | System must detect first-boot vs recovery-boot | Critical |
| BOOT-07 | First boot must show setup wizard, not full service stack | High |
| BOOT-08 | Recovery boot must restore all services to last known state | High |
| BOOT-09 | Boot sequence must complete within 90 seconds on Pi 5 | Medium |
| BOOT-10 | Hardware watchdog must be enabled during boot | High |

### 1.2 Service Management

| ID | Requirement | Priority |
|----|-------------|----------|
| SVC-01 | All services must be deployed as Docker Swarm stacks | Critical |
| SVC-02 | Each service must have exactly one Swarm stack | Critical |
| SVC-03 | Service status must be queried from Swarm, not cached | Critical |
| SVC-04 | Failed services must auto-restart via Swarm reconciliation | Critical |
| SVC-05 | Services must support start/stop/restart operations | High |
| SVC-06 | Services must support enable/disable (persist across reboot) | High |
| SVC-07 | Service logs must be accessible via API | High |
| SVC-08 | Service resource usage (CPU/RAM) must be queryable | Medium |
| SVC-09 | Swarm task history limit must be set to 1 (memory optimization) | High |
| SVC-10 | Dashboard must include built-in Swarm management GUI | High |

### 1.3 App Installation

| ID | Requirement | Priority |
|----|-------------|----------|
| APP-01 | Apps must be installable from CasaOS-compatible app stores | High |
| APP-02 | Apps must be installable from local registry (offline) | Critical |
| APP-03 | Any docker-compose.yml must be transformable to Swarm format | High |
| APP-04 | Port allocation must be automatic and conflict-free | High |
| APP-05 | FQDN assignment must be automatic (subdomain.cubeos.cube) | High |
| APP-06 | NPM proxy host must be created automatically on install | High |
| APP-07 | Pi-hole DNS entry must be created automatically on install | High |
| APP-08 | App uninstall must clean up all resources (stack, DNS, proxy) | High |
| APP-09 | All apps must use strict port range (6000-6999), no exceptions | High |

### 1.4 Port Allocation

| ID | Requirement | Priority |
|----|-------------|----------|
| PORT-01 | System ports: 6000-6099 (infrastructure and platform) | Critical |
| PORT-02 | User app ports: 6100-6999 (dynamically allocated) | Critical |
| PORT-03 | No hardcoded exceptions - all apps comply with port scheme | High |
| PORT-04 | Reserved system ports (22, 53, 67, 80, 443) handled by host mode services | Critical |
| PORT-05 | Ollama must be moved from 11434 to 6xxx range | High |

### 1.5 Profile System

| ID | Requirement | Priority |
|----|-------------|----------|
| PRF-01 | System must support multiple profiles (Full, Minimal, Offline, Custom) | High |
| PRF-02 | Each profile defines which apps are enabled at boot | High |
| PRF-03 | Switching profiles must stop disabled apps, start enabled apps | High |
| PRF-04 | Profile changes must persist across reboot | High |
| PRF-05 | Users must be able to create custom profiles | Medium |

### 1.6 Network Modes

| ID | Requirement | Priority |
|----|-------------|----------|
| NET-01 | System must support OFFLINE mode (AP only, no internet) | Critical |
| NET-02 | System must support ONLINE_ETH mode (AP + NAT via eth0) | Critical |
| NET-03 | System must support ONLINE_WIFI mode (AP + NAT via USB WiFi dongle) | High |
| NET-04 | ONLINE_WIFI must provide UI to scan/select/connect to upstream WiFi | High |
| NET-05 | WiFi credentials must be stored securely in .env file | High |
| NET-06 | Network mode must be switchable via dashboard | High |
| NET-07 | Subnet must be 10.42.24.0/24 (avoid common conflicts) | Critical |
| NET-08 | Firewall rules must be managed automatically per network mode | High |

### 1.7 VPN and Privacy

| ID | Requirement | Priority |
|----|-------------|----------|
| VPN-01 | WireGuard client must be available as coreapp | High |
| VPN-02 | OpenVPN client must be available as coreapp | High |
| VPN-03 | VPN configurations must be importable via dashboard | Medium |
| VPN-04 | Tor client must be available as coreapp | Medium |
| VPN-05 | Tor routing must be toggleable per-app | Medium |
| VPN-06 | VPN/Tor status must be visible in dashboard | Medium |

### 1.8 Local Registry

| ID | Requirement | Priority |
|----|-------------|----------|
| REG-01 | CubeOS must run a local Docker registry | Critical |
| REG-02 | Registry must cache images from ghcr.io and docker.io | High |
| REG-03 | At least 20 curated apps must be pre-cached for offline use | High |
| REG-04 | Registry must support image cleanup (remove old versions) | Medium |
| REG-05 | Registry must proxy requests to upstream when online | High |
| REG-06 | Core service images must always be available locally | Critical |

### 1.9 Health Monitoring

| ID | Requirement | Priority |
|----|-------------|----------|
| HLT-01 | All services must have health checks defined | High |
| HLT-02 | Unhealthy services must be detected within 60 seconds | High |
| HLT-03 | System must expose health status via API | High |
| HLT-04 | Dashboard must show real-time health indicators | High |
| HLT-05 | Critical service failures must trigger recovery actions | Medium |
| HLT-06 | Hardware watchdog must reboot system on hang (15s timeout) | High |

### 1.10 Storage and Backup

| ID | Requirement | Priority |
|----|-------------|----------|
| STG-01 | SMB client must be able to mount remote shares | High |
| STG-02 | NFS client must be able to mount remote shares | High |
| STG-03 | Mounted shares must be usable as backup targets | High |
| STG-04 | External backup to SMB/NFS must be configurable | High |
| STG-05 | Backup must include app data, configs, and database | High |
| STG-06 | Scheduled automatic backups must be supported | Medium |

### 1.11 Configuration Management

| ID | Requirement | Priority |
|----|-------------|----------|
| CFG-01 | All configurable values must be in .env files, not hardcoded | High |
| CFG-02 | Central defaults.env must provide shared configuration | High |
| CFG-03 | Per-app .env files must override central defaults | High |
| CFG-04 | Secrets must be generated on first boot, stored securely | High |
| CFG-05 | Configuration changes must not require container rebuild | Medium |

### 1.12 Distribution

| ID | Requirement | Priority |
|----|-------------|----------|
| DIST-01 | Image must be flashable via Raspberry Pi Imager | Critical |
| DIST-02 | Image must be compatible with official Raspberry Pi SD card utility | Critical |
| DIST-03 | JSON manifest must be provided for Imager listing | High |
| DIST-04 | Image must support Imager customization (hostname, SSH keys) | High |
| DIST-05 | Apply for official listing in Raspberry Pi Imager | Medium |

---

## 2. Non-Functional Requirements

### 2.1 Performance

| ID | Requirement | Target |
|----|-------------|--------|
| PERF-01 | API response time for service list | < 500ms |
| PERF-02 | API response time for single service status | < 200ms |
| PERF-03 | App install time (cached image) | < 30 seconds |
| PERF-04 | App install time (pull from registry) | < 5 minutes |
| PERF-05 | Memory overhead of Swarm mode | < 100MB |
| PERF-06 | Idle system RAM usage (core services only) | < 1GB |
| PERF-07 | Boot to dashboard accessible | < 90 seconds |

### 2.2 Reliability

| ID | Requirement | Target |
|----|-------------|--------|
| REL-01 | System uptime | 99.9% (8.7 hours downtime/year) |
| REL-02 | Recovery from power loss | < 2 minutes to full operation |
| REL-03 | Service auto-restart on failure | < 30 seconds |
| REL-04 | Data persistence across reboot | 100% (no data loss) |
| REL-05 | Watchdog reboot on system hang | 15 seconds max |

### 2.3 Security

| ID | Requirement | Priority |
|----|-------------|----------|
| SEC-01 | API must require JWT authentication | Critical |
| SEC-02 | Default password must be changed on first boot | Critical |
| SEC-03 | Secrets must not be committed to git | Critical |
| SEC-04 | Container images must be pulled from trusted sources only | High |
| SEC-05 | Docker socket access must be read-only where possible | Medium |
| SEC-06 | SSH must use key-only authentication by default | High |
| SEC-07 | Fail2ban must be installed and configured | High |
| SEC-08 | Kernel hardening via sysctl | High |
| SEC-09 | AppArmor profiles should be available | Medium |

### 2.4 Maintainability

| ID | Requirement | Priority |
|----|-------------|----------|
| MNT-01 | Code must pass gofmt and go vet | Critical |
| MNT-02 | All public functions must have documentation | High |
| MNT-03 | Complex logic must have inline comments | High |
| MNT-04 | No hardcoded IP addresses or domains | High |
| MNT-05 | All configuration must be environment-driven | High |
| MNT-06 | Read-only root filesystem must be an option | Medium |
| MNT-07 | Logs must use tmpfs to reduce SD card wear | High |

### 2.5 Extensibility (Future-Proof)

| ID | Requirement | Priority |
|----|-------------|----------|
| EXT-01 | Data models must support multi-node Swarm expansion | High |
| EXT-02 | API must be versioned (/api/v1/) | Critical |
| EXT-03 | Database schema must support migrations | High |
| EXT-04 | Plugin/extension system architecture must be considered | Medium |
| EXT-05 | White-label theming must remain supported | High |

---

## 3. Constraints

### 3.1 Technical Constraints

| Constraint | Description |
|------------|-------------|
| No CGO | Go binaries must compile without CGO for cross-platform builds |
| Single Node (v1) | Swarm must operate in single-node mode (multi-node future) |
| ARM64 Primary | All containers must have ARM64 images available |
| SQLite Only | No external database services (PostgreSQL, MySQL) |
| Offline Capable | All core functionality must work without internet |
| 6 Repos Max | All code must fit within existing 6 repositories |

### 3.2 Business Constraints

| Constraint | Description |
|------------|-------------|
| Apache 2.0 | All CubeOS code must remain Apache 2.0 licensed |
| No MuleCube | Remove all MuleCube branding from CubeOS code |
| White-Label Ready | UI must support theming for commercial products |

### 3.3 UI Constraints

| Constraint | Description |
|------------|-------------|
| No Emojis | Use monochrome SVG icons (Apple-style) |
| Tailwind Only | No custom CSS unless absolutely necessary |
| Mobile Responsive | Dashboard must work on mobile devices |
| Dark Mode | Support both light and dark themes |

---

## 4. Acceptance Criteria

### 4.1 Definition of Done

A feature is "done" when:

1. Code compiles without errors or warnings
2. Code passes `gofmt` and `go vet`
3. Unit tests pass (where applicable)
4. Feature works on Raspberry Pi 5 (ARM64)
5. Feature works offline (where applicable)
6. Documentation is updated
7. No hardcoded values remain
8. Code is committed and pushed

### 4.2 Migration Complete Criteria

The migration is complete when:

1. All core services run as Swarm stacks
2. Old AppStore/AppManager tables are deprecated
3. New unified API endpoints work
4. Dashboard uses new API exclusively
5. Profile system works with new architecture
6. Local registry is operational
7. System boots and self-heals reliably
8. CasaOS apps can be installed
9. Network modes switchable (OFFLINE/ONLINE_ETH/ONLINE_WIFI)
10. VPN clients available
11. All tests pass
12. Documentation is complete
13. Raspberry Pi Imager manifest created

---

*Document Version: 2.0*  
*Last Updated: January 31, 2026*
