# CubeOS Documentation

Welcome to CubeOS - an open-source operating system for self-hosted ARM64 servers.

## What is CubeOS?

CubeOS transforms single-board computers like Raspberry Pi into powerful, easy-to-manage home servers. It provides a beautiful web dashboard for managing services, network settings, and system resources without needing terminal access.

## Quick Links

- [Getting Started](guides/getting-started.md) - First-time setup
- [Dashboard Guide](guides/dashboard.md) - Using the web interface
- [Services Guide](guides/services.md) - Managing applications
- [Network Guide](guides/network.md) - WiFi, DHCP, and DNS
- [FAQ](faq/general.md) - Frequently asked questions
- [Troubleshooting](guides/troubleshooting.md) - Common issues and solutions
- [API Reference](reference/api.md) - REST API documentation

## Default Access

| Service | URL | Default Credentials |
|---------|-----|---------------------|
| Dashboard | http://cubeos.cube | admin / cubeos |
| Pi-hole | http://pihole.cubeos.cube/admin | cubeos |
| NPM | http://npm.cubeos.cube | cubeos@cubeos.app / cubeos123 |
| Dockge | http://dockge.cubeos.cube | (same as dashboard) |
| Logs | http://logs.cubeos.cube | (no auth) |

## System Requirements

- Raspberry Pi 4 or 5 (4GB+ RAM recommended)
- 16GB+ microSD card or USB storage
- Power supply (official recommended)
- Ethernet cable (optional, has WiFi AP)

## Support

- GitHub: https://github.com/cubeos-app
- Documentation: https://docs.cubeos.app
