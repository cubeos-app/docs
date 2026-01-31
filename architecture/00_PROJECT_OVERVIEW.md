# CubeOS Swarm Migration Project

**Project Start Date:** January 31, 2026  
**Target Completion:** ~2 weeks (14 days)  
**Status:** Planning Phase

---

## Executive Summary

CubeOS is migrating from docker-compose to Docker Swarm single-node mode to solve the "Three-Headed Hydra" problem: three independent components (Services, AppManager, AppStore) managing containers without coordination, causing data fragmentation and status desynchronization.

This migration also incorporates production hardening, offline-first architecture with local registry, multiple network modes, VPN/Tor support, and preparation for official Raspberry Pi Imager listing.

### The Core Problem

```
CURRENT STATE (BROKEN)
                                    
    Dashboard                       
        |                           
   +----+----+----------+           
   |         |          |           
Services  AppManager  AppStore      
Handler                             
   |         |          |           
   |    apps table   installed_     
   |                 apps table     
   |         |          |           
   v         v          v           
+---------------------------+       
|      Docker Engine        | <-- All three call Docker directly
+---------------------------+       
```

### The Solution

```
TARGET STATE (UNIFIED)
                                    
    Dashboard                       
        |                           
        v                           
+------------------+                
|   Unified API    |                
|   /api/v1/apps   |                
+--------+---------+                
         |                          
         v                          
+------------------+                
|   Orchestrator   | <-- Single coordinator
+--------+---------+                
         |                          
         v                          
+------------------+                
|  SwarmManager    | <-- Docker Swarm API wrapper
+--------+---------+                
         |                          
         v                          
+------------------+                
|  Docker Swarm    | <-- Single Source of Truth
+------------------+                
```

---

## Project Goals

### Primary Goals

1. **Single Source of Truth** - Docker Swarm becomes the authoritative state for all containers
2. **Unified Data Model** - One `apps` table, deprecate `installed_apps`
3. **Self-Healing** - Swarm's built-in reconciliation restarts failed containers
4. **Declarative State** - Desired state stored in DB, Swarm enforces it
5. **Offline-First** - Local container registry for offline app installation
6. **Future-Proof** - Extensible architecture for multi-node Swarm, plugins

### Secondary Goals

1. **Clean Architecture** - Separate API and Dashboard into independent stacks
2. **CasaOS Compatibility** - Transform any compose file to Swarm-compatible format
3. **Profile System** - Enable/disable apps based on selected profile
4. **Zero-Downtime Updates** - Rolling updates via Swarm
5. **Raspberry Pi Imager Listing** - Official distribution channel
6. **Production Hardening** - SSH, watchdog, read-only root, fail2ban

### Non-Goals (Out of Scope for v1.0)

1. Multi-node Swarm clustering (architecture supports it, not implemented)
2. Kubernetes migration (explicitly rejected)
3. Custom orchestrator development (use Swarm instead)
4. Third-party Swarm GUI (building our own in dashboard)

---

## Key Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Orchestration | Docker Swarm single-node | Built-in, zero overhead, keeps compose format, future multi-node ready |
| Database | SQLite (keep) | Perfect for single-node, pure Go driver available |
| Subnet | `10.42.24.0/24` | Avoids common 192.168.x.x conflicts |
| Pi-hole networking | `network_mode: host` | Required for DHCP broadcast |
| NPM networking | `network_mode: host` | Handles 80/443, reduces NAT complexity |
| API/Dashboard | Separate stacks | Independent release cycles, cleaner architecture |
| Local registry | Required | Offline-first requirement |
| Config management | Per-app `.env` + central defaults | Balance of separation and DRY |
| Domain | `cubeos.cube` | Single canonical internal domain |
| Port allocation | Strict 6xxx range, no exceptions | Simplicity and predictability |
| Swarm GUI | Built into dashboard | No third-party dependencies |
| Distribution | Raspberry Pi Imager | Official channel, maximum reach |

---

## Network Modes

CubeOS supports three network operating modes:

| Mode | Description | Internet Source | Use Case |
|------|-------------|-----------------|----------|
| `OFFLINE` | Access Point only, air-gapped | None | Field deployment, secure environments |
| `ONLINE_ETH` | AP + NAT via Ethernet | eth0 | Home/office with wired uplink |
| `ONLINE_WIFI` | AP + NAT via USB WiFi dongle | wlan1 (client) | Mobile deployment, no ethernet |

---

## Success Criteria

### Minimum Viable Migration (Week 1)

- [ ] Swarm initialized and stable on Pi
- [ ] Pi-hole deployed as Swarm stack
- [ ] NPM deployed as Swarm stack
- [ ] cubeos-api deployed as Swarm stack
- [ ] cubeos-dashboard deployed as Swarm stack
- [ ] Basic health checks working
- [ ] Manual stack deploy/remove working

### Full Migration (Week 2)

- [ ] New unified database schema
- [ ] Orchestrator component complete
- [ ] CasaOS compose transformation working
- [ ] Profile system migrated
- [ ] Frontend updated with Swarm GUI
- [ ] Local registry operational
- [ ] Network mode switching working
- [ ] VPN clients (WireGuard, OpenVPN) in coreapps
- [ ] End-to-end testing complete

### Production Readiness

- [ ] SSH hardening configured
- [ ] Watchdog timer enabled
- [ ] Read-only root filesystem option
- [ ] Fail2ban installed and configured
- [ ] Raspberry Pi Imager JSON manifest created
- [ ] Image builds automated

---

## Repository Structure

| Repo | Purpose | Status |
|------|---------|--------|
| `api` | Go backend API | Major refactor |
| `dashboard` | Vue.js 3 frontend | Updates + Swarm GUI |
| `coreapps` | System Docker apps | Cleanup + restructure + new apps |
| `scripts` | Deployment scripts | Update for Swarm |
| `releases` | Packer image builder | Boot sequence + Imager manifest |
| `docs` | User documentation | Update post-migration |

---

## Risk Assessment

| Risk | Impact | Mitigation |
|------|--------|------------|
| Swarm instability on Pi | High | Test thoroughly, use --task-history-limit 1 |
| Pi-hole DHCP breaks | Critical | Keep `network_mode: host`, test first |
| Data loss during migration | Medium | Fresh start (no migration), backup configs |
| Extended downtime | Medium | Prepare rollback SD card |
| CasaOS incompatibility | Low | Transform layer handles edge cases |
| ARM64 architecture mismatch | Medium | Use --resolve-image never workaround |
| Memory exhaustion (tasks.db) | Medium | Set task-history-limit 1, monitor |

---

## Document Index

| Doc | Title | Description |
|-----|-------|-------------|
| 00 | PROJECT_OVERVIEW | This document |
| 01 | REQUIREMENTS | Functional and non-functional requirements |
| 02 | ARCHITECTURE | Technical architecture and components |
| 03 | DATABASE_SCHEMA | New unified database design |
| 04 | BOOT_SEQUENCE | Startup and recovery logic |
| 05 | COREAPPS_INVENTORY | What stays, goes, changes |
| 06 | SPRINT_PLAN | Sprint breakdown and tasks |
| 07 | API_CONTRACTS | API endpoint specifications |
| 08 | LOCAL_REGISTRY | Offline registry design |
| 09 | PRODUCTION_HARDENING | Security and reliability |
| 10 | RASPBERRY_PI_IMAGER | Distribution requirements |

---

*Document Version: 2.0*  
*Last Updated: January 31, 2026*
