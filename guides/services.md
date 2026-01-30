# Services Guide

CubeOS runs applications as Docker containers. This guide explains how to manage them.

## Pre-installed Services

### Pi-hole (DNS & DHCP)

**URL**: http://pihole.cubeos.cube/admin  
**Password**: cubeos

Pi-hole blocks ads and trackers at the network level. All devices connected to CubeOS WiFi automatically use Pi-hole for DNS.

Features:
- Blocks ads on all devices (including smart TVs, phones)
- Shows DNS query logs
- Custom blocklists
- Local DNS records

### Nginx Proxy Manager (NPM)

**URL**: http://npm.cubeos.cube  
**Login**: cubeos@cubeos.app / cubeos123

NPM manages reverse proxies for all services. It handles:
- Subdomain routing (pihole.cubeos.cube, etc.)
- SSL certificates (Let's Encrypt)
- Access control

### Dockge (Container Manager)

**URL**: http://dockge.cubeos.cube

Dockge provides a visual interface for managing Docker Compose stacks. Use it to:
- Deploy new applications
- Edit container configurations
- View logs and stats
- Start/stop containers

### Dozzle (Log Viewer)

**URL**: http://logs.cubeos.cube

Real-time log viewer for all containers. Features:
- Live log streaming
- Search and filter
- Multiple containers view
- Download logs

## Managing Services

### From Dashboard

1. Go to **Services** page
2. Click on a service card
3. Use the action buttons:
   - **Restart** - Restarts the container
   - **Stop** - Stops the container
   - **Logs** - View recent logs

### From Dockge

1. Go to http://dockge.cubeos.cube
2. Click on a stack
3. Use the controls to manage containers

### From Terminal

1. Go to http://terminal.cubeos.cube
2. Use Docker commands:

```bash
# List running containers
docker ps

# View logs
docker logs cubeos-pihole

# Restart a service
docker restart cubeos-api

# Stop a service
docker stop cubeos-ollama
```

## Installing New Apps

### Using the App Store (Coming Soon)

The built-in App Store will offer one-click installation of popular self-hosted apps.

### Using Dockge

1. Go to http://dockge.cubeos.cube
2. Click **+ Compose**
3. Paste your docker-compose.yml
4. Click **Deploy**

### Popular Apps to Self-Host

| App | Purpose |
|-----|---------|
| Nextcloud | File sync & cloud storage |
| Home Assistant | Smart home automation |
| Jellyfin | Media server |
| Gitea | Git hosting |
| Vaultwarden | Password manager |
| Immich | Photo backup |

## Resource Usage

Monitor container resources on the Dashboard or via:

```bash
docker stats
```

Tips for Raspberry Pi:
- Limit containers to 2-4GB RAM total
- Avoid running too many services simultaneously
- Use lightweight alternatives when available

## Troubleshooting Services

### Service won't start

1. Check logs: `docker logs <container_name>`
2. Verify port isn't in use: `ss -tlnp | grep <port>`
3. Check available memory: `free -h`

### Service is slow

1. Check CPU usage: `htop`
2. Monitor I/O: `iotop`
3. Consider using faster storage (SSD vs SD card)

### Can't access service

1. Verify container is running: `docker ps`
2. Check NPM proxy configuration
3. Verify DNS: `nslookup service.cubeos.cube 192.168.42.1`
