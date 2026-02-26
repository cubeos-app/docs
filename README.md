# CubeOS Documentation

Welcome to CubeOS - an open-source operating system for self-hosted ARM64 servers.

## What is CubeOS?

CubeOS transforms single-board computers like Raspberry Pi into powerful, easy-to-manage home servers. It provides a beautiful web dashboard for managing services, network settings, and system resources without needing terminal access.

## Quick Links

### User Guides

- [Getting Started](getting-started.md) - First-time setup from flash to first app
- [Network Modes](network-modes.md) - OFFLINE, Ethernet, and WiFi connectivity
- [Backup and Restore](backup-restore.md) - Backups, encryption, and recovery
- [FAQ](faq.md) - Frequently asked questions

### Reference

- [Dashboard Guide](guides/dashboard.md) - Using the web interface
- [App Store Guide](guides/app-store.md) - Browsing, installing, and managing apps
- [Services Guide](guides/services.md) - Managing applications
- [Network Guide](guides/network.md) - WiFi, DHCP, and DNS configuration details
- [Troubleshooting](guides/troubleshooting.md) - Common issues and solutions
- [API Reference](reference/api.md) - REST API documentation

### Developer

- [Developer Guide](developer-guide.md) - Building from source, contributing, custom apps

## Default Access

| Service | URL | Default Credentials |
|---------|-----|---------------------|
| Dashboard | http://cubeos.cube | admin / cubeos |
| Pi-hole | http://pihole.cubeos.cube/admin | cubeos |
| NPM | http://npm.cubeos.cube | cubeos@cubeos.app / cubeos123 |
| Logs | http://logs.cubeos.cube | (no auth) |

## System Requirements

- Raspberry Pi 4 or 5 (4GB+ RAM recommended)
- 16GB+ microSD card or USB storage
- Power supply (official recommended)
- Ethernet cable (optional, has WiFi AP)

## Network

CubeOS operates on the `10.42.24.0/24` subnet with the domain `cubeos.cube`.

| Setting | Value |
|---------|-------|
| Gateway | 10.42.24.1 |
| DNS | 10.42.24.1 (Pi-hole) |
| DHCP Range | 10.42.24.10 - 10.42.24.250 |
| Domain | cubeos.cube |

## Architecture

Architecture documentation is in [architecture/](architecture/):
- [Project Overview](architecture/00_PROJECT_OVERVIEW.md)
- [Architecture](architecture/02_ARCHITECTURE.md)
- [Database Schema](architecture/03_DATABASE_SCHEMA.md)
- [Boot Sequence](architecture/04_BOOT_SEQUENCE.md)
- [API Contracts](architecture/07_API_CONTRACTS.md)

## Support

- GitHub: https://github.com/cubeos-app
- Documentation: https://docs.cubeos.app
