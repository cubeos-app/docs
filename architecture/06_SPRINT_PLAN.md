# CubeOS Sprint Plan

**Document:** 06_SPRINT_PLAN.md  
**Version:** 2.0  
**Last Updated:** January 31, 2026

---

## 1. Project Timeline

| Sprint | Duration | Focus |
|--------|----------|-------|
| Sprint 0 | Day 1 | Setup, cleanup, documentation |
| Sprint 1 | Days 2-4 | SwarmManager + Infrastructure |
| Sprint 2 | Days 5-7 | Orchestrator + Database |
| Sprint 3 | Days 8-10 | API Handlers + Network Modes |
| Sprint 4 | Days 11-12 | Frontend + Swarm GUI |
| Sprint 5 | Days 13-14 | Testing, Hardening, Imager |

---

## 2. Sprint 0: Foundation (Day 1)

**Goal:** Clean slate, documentation complete, ready to code

### Tasks

| ID | Task | Est. | Status |
|----|------|------|--------|
| S0-01 | Create architecture documentation | 2h | DONE |
| S0-02 | Clean up coreapps (remove dockge, gpio, nettools, usb-monitor) | 30m | TODO |
| S0-03 | Create cubeos-api directory structure | 30m | TODO |
| S0-04 | Create cubeos-dashboard directory structure | 30m | TODO |
| S0-05 | Create registry directory structure | 30m | TODO |
| S0-06 | Create wireguard directory structure | 15m | TODO |
| S0-07 | Create openvpn directory structure | 15m | TODO |
| S0-08 | Create tor directory structure | 15m | TODO |
| S0-09 | Update subnet to 10.42.24.0/24 in all configs | 1h | TODO |
| S0-10 | Update all ports to new scheme | 1h | TODO |
| S0-11 | Create defaults.env template | 30m | TODO |
| S0-12 | Remove MuleCube references from code | 1h | TODO |
| S0-13 | Update CI/CD for separated api/dashboard | 1h | TODO |

### Deliverables

- [x] Complete documentation in `/docs/architecture/`
- [ ] Clean coreapps directory structure
- [ ] Separated API and Dashboard compose files
- [ ] All new coreapp directories created
- [ ] Updated subnet and port scheme

---

## 3. Sprint 1: SwarmManager + Infrastructure (Days 2-4)

**Goal:** Docker Swarm working, infrastructure services deployed as stacks

### Tasks

| ID | Task | Est. | Status |
|----|------|------|--------|
| S1-01 | Create `internal/managers/swarm.go` | 4h | TODO |
| S1-02 | Implement SwarmManager.Init() | 1h | TODO |
| S1-03 | Implement SwarmManager.DeployStack() | 2h | TODO |
| S1-04 | Implement SwarmManager.RemoveStack() | 1h | TODO |
| S1-05 | Implement SwarmManager.GetServiceStatus() | 2h | TODO |
| S1-06 | Implement SwarmManager.GetServiceLogs() | 1h | TODO |
| S1-07 | Implement SwarmManager.ListStacks() | 1h | TODO |
| S1-08 | Implement SwarmManager.SetTaskHistoryLimit() | 30m | TODO |
| S1-09 | Update pihole compose (10.42.24.x subnet) | 1h | TODO |
| S1-10 | Update npm compose (host mode confirmed) | 1h | TODO |
| S1-11 | Create registry compose | 1h | TODO |
| S1-12 | Create cubeos-api compose | 1h | TODO |
| S1-13 | Create cubeos-dashboard compose | 1h | TODO |
| S1-14 | Test manual stack deploy on Pi | 2h | TODO |
| S1-15 | Test Swarm reconciliation (kill container) | 1h | TODO |
| S1-16 | Test ARM64 architecture workaround | 1h | TODO |
| S1-17 | Write SwarmManager unit tests | 2h | TODO |

### Deliverables

- [ ] `internal/managers/swarm.go` complete and tested
- [ ] All infrastructure compose files Swarm-compatible
- [ ] Manual `docker stack deploy` working for all coreapps
- [ ] Swarm auto-restart verified

---

## 4. Sprint 2: Orchestrator + Database (Days 5-7)

**Goal:** Unified Orchestrator coordinating all app operations

### Tasks

| ID | Task | Est. | Status |
|----|------|------|--------|
| S2-01 | Create `internal/database/schema.go` | 2h | TODO |
| S2-02 | Create `internal/database/migrations.go` | 1h | TODO |
| S2-03 | Create new `internal/models/app.go` | 2h | TODO |
| S2-04 | Create new `internal/models/profile.go` | 1h | TODO |
| S2-05 | Create new `internal/models/network.go` | 1h | TODO |
| S2-06 | Create `internal/managers/orchestrator.go` | 4h | TODO |
| S2-07 | Implement Orchestrator.InstallApp() | 3h | TODO |
| S2-08 | Implement Orchestrator.UninstallApp() | 2h | TODO |
| S2-09 | Implement Orchestrator.StartApp() | 1h | TODO |
| S2-10 | Implement Orchestrator.StopApp() | 1h | TODO |
| S2-11 | Implement Orchestrator.GetApp() | 1h | TODO |
| S2-12 | Implement Orchestrator.ListApps() | 1h | TODO |
| S2-13 | Implement Orchestrator.ReconcileState() | 3h | TODO |
| S2-14 | Implement Orchestrator.SeedSystemApps() | 2h | TODO |
| S2-15 | Create `internal/managers/ports.go` (new scheme) | 2h | TODO |
| S2-16 | Update ComposeTransformer for Swarm | 2h | TODO |
| S2-17 | Write Orchestrator unit tests | 3h | TODO |

### Deliverables

- [ ] New database schema implemented
- [ ] `internal/managers/orchestrator.go` complete
- [ ] App install/uninstall working end-to-end
- [ ] ReconcileState() working for boot recovery
- [ ] Port allocation following strict scheme

---

## 5. Sprint 3: API Handlers + Network Modes (Days 8-10)

**Goal:** New unified API endpoints, network mode switching

### Tasks

| ID | Task | Est. | Status |
|----|------|------|--------|
| S3-01 | Create `internal/handlers/apps.go` | 4h | TODO |
| S3-02 | Implement GET /api/v1/apps | 1h | TODO |
| S3-03 | Implement GET /api/v1/apps/{name} | 1h | TODO |
| S3-04 | Implement POST /api/v1/apps (install) | 2h | TODO |
| S3-05 | Implement DELETE /api/v1/apps/{name} | 1h | TODO |
| S3-06 | Implement POST /api/v1/apps/{name}/start | 1h | TODO |
| S3-07 | Implement POST /api/v1/apps/{name}/stop | 1h | TODO |
| S3-08 | Implement POST /api/v1/apps/{name}/restart | 1h | TODO |
| S3-09 | Implement GET /api/v1/apps/{name}/logs | 1h | TODO |
| S3-10 | Create `internal/managers/network.go` | 3h | TODO |
| S3-11 | Implement NetworkManager.SetMode() | 2h | TODO |
| S3-12 | Implement NetworkManager.ScanWiFiNetworks() | 2h | TODO |
| S3-13 | Implement NetworkManager.ConnectToWiFi() | 2h | TODO |
| S3-14 | Create `internal/handlers/network.go` | 2h | TODO |
| S3-15 | Implement profile endpoints | 3h | TODO |
| S3-16 | Create `internal/managers/vpn.go` | 2h | TODO |
| S3-17 | Create `internal/handlers/vpn.go` | 2h | TODO |
| S3-18 | Create `internal/managers/mounts.go` (SMB/NFS) | 3h | TODO |
| S3-19 | Create `internal/handlers/mounts.go` | 2h | TODO |
| S3-20 | Update main.go route registration | 1h | TODO |
| S3-21 | Update OpenAPI spec | 2h | TODO |
| S3-22 | Write API integration tests | 3h | TODO |

### Deliverables

- [ ] New `/api/v1/apps` endpoints working
- [ ] Network mode switching working
- [ ] WiFi scanning and connection working
- [ ] VPN management endpoints
- [ ] SMB/NFS mount endpoints
- [ ] Profile system functional

---

## 6. Sprint 4: Frontend + Swarm GUI (Days 11-12)

**Goal:** Dashboard uses new API, built-in Swarm management GUI

### Tasks

| ID | Task | Est. | Status |
|----|------|------|--------|
| S4-01 | Create new `stores/apps.js` | 3h | TODO |
| S4-02 | Create `components/swarm/` directory | 1h | TODO |
| S4-03 | Create SwarmOverview.vue component | 3h | TODO |
| S4-04 | Create StackList.vue component | 2h | TODO |
| S4-05 | Create ServiceDetail.vue component | 2h | TODO |
| S4-06 | Update Services component to use new API | 2h | TODO |
| S4-07 | Create `components/network/` directory | 1h | TODO |
| S4-08 | Create NetworkModeSelector.vue | 2h | TODO |
| S4-09 | Create WiFiConnector.vue (scan/connect) | 3h | TODO |
| S4-10 | Create `components/vpn/` directory | 1h | TODO |
| S4-11 | Create VPNManager.vue | 2h | TODO |
| S4-12 | Create TorToggle.vue (per-app) | 1h | TODO |
| S4-13 | Update profile selection UI | 2h | TODO |
| S4-14 | Replace emojis with monochrome SVG icons | 2h | TODO |
| S4-15 | Remove old stores (appmanager, appstore) | 1h | TODO |
| S4-16 | Test all dashboard features | 2h | TODO |

### Deliverables

- [ ] Dashboard uses new `/api/v1/apps` endpoints
- [ ] Swarm GUI integrated (stacks, services, logs)
- [ ] Network mode selector working
- [ ] WiFi connection UI working
- [ ] VPN management UI working
- [ ] No emojis, proper monochrome icons

---

## 7. Sprint 5: Testing, Hardening, Imager (Days 13-14)

**Goal:** Production-ready, secure, distributable via Pi Imager

### Tasks

| ID | Task | Est. | Status |
|----|------|------|--------|
| S5-01 | End-to-end boot sequence test | 2h | TODO |
| S5-02 | Power loss recovery test | 2h | TODO |
| S5-03 | CasaOS app install test | 2h | TODO |
| S5-04 | Network mode switching test | 2h | TODO |
| S5-05 | VPN connectivity test | 1h | TODO |
| S5-06 | Create `/etc/sysctl.d/99-cubeos-security.conf` | 30m | TODO |
| S5-07 | Create `/etc/ssh/sshd_config.d/99-cubeos.conf` | 30m | TODO |
| S5-08 | Configure fail2ban | 1h | TODO |
| S5-09 | Configure watchdog timer | 30m | TODO |
| S5-10 | Configure journald for tmpfs | 30m | TODO |
| S5-11 | Create read-only root option script | 1h | TODO |
| S5-12 | Create Raspberry Pi Imager JSON manifest | 1h | TODO |
| S5-13 | Test image with Raspberry Pi Imager | 1h | TODO |
| S5-14 | Performance testing (boot time <90s) | 1h | TODO |
| S5-15 | Memory usage verification (<1GB idle) | 1h | TODO |
| S5-16 | Update user documentation | 2h | TODO |
| S5-17 | Create CHANGELOG.md | 1h | TODO |
| S5-18 | Final code review | 2h | TODO |
| S5-19 | Tag release v2.0.0 | 30m | TODO |

### Deliverables

- [ ] All tests passing
- [ ] Security hardening applied
- [ ] Raspberry Pi Imager manifest created
- [ ] Boot completes in <90 seconds
- [ ] Memory usage <1GB idle
- [ ] Documentation complete
- [ ] Release tagged

---

## 8. Task Dependencies

```
Sprint 0 (Foundation)
    |
    v
Sprint 1 (SwarmManager)
    |
    +---> Sprint 2 (Orchestrator + Database)
              |
              +---> Sprint 3 (API + Network)
                        |
                        +---> Sprint 4 (Frontend)
                                  |
                                  +---> Sprint 5 (Testing + Release)
```

---

## 9. Risk Mitigation

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Swarm ARM64 issues | Medium | High | Test early, use --resolve-image never |
| WiFi client mode complexity | Medium | Medium | Research wpa_supplicant, test on Pi |
| Memory issues (tasks.db) | Medium | Medium | Set task-history-limit 1 |
| Pi Imager rejection | Low | Low | Follow spec exactly, test thoroughly |
| Timeline slip | Medium | Medium | Prioritize core features |

---

## 10. Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Boot time | <90s | Stopwatch: power-on to dashboard |
| Idle RAM | <1GB | `docker stats` + `free -m` |
| API response | <500ms | `time curl /api/v1/apps` |
| Test coverage | >60% | `go test -cover` |
| Swarm overhead | <100MB | Compare before/after Swarm |
| Security score | A+ | SSH audit tool |

---

*Document Version: 2.0*  
*Last Updated: January 31, 2026*
