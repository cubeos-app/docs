# Dashboard Guide

The CubeOS Dashboard is your central control panel for managing your server.

## Accessing the Dashboard

- **URL**: http://cubeos.cube (when on CubeOS WiFi)
- **Alternative**: http://192.168.42.1
- **Login**: admin / cubeos (change after first login!)

## Dashboard Sections

### Main Dashboard

The home screen shows:

- **System Health** - CPU, memory, disk, temperature at a glance
- **AI Assistant** - Click "Ask Now" to chat with CubeOS
- **Quick Stats** - Uptime, connected clients, network traffic
- **Services Overview** - Status of all running applications

### Services Page

View and manage all Docker containers:

- **Green dot** = Running
- **Yellow dot** = Paused or restarting
- **Red dot** = Stopped

Click any service to:
- View logs
- Restart/Stop/Start
- See resource usage

### Network Page

Manage network settings:

- **WiFi Configuration** - Change SSID and password
- **Connected Clients** - See who's connected
- **DHCP Leases** - View IP assignments

### Settings

Configure CubeOS:

- **System** - Hostname, timezone, updates
- **Security** - Change password, manage users
- **Backups** - Create and restore backups
- **About** - Version info and support links

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `?` | Show help |
| `g d` | Go to Dashboard |
| `g s` | Go to Services |
| `g n` | Go to Network |
| `g t` | Go to Settings |

## Dark/Light Mode

Click the theme toggle (sun/moon icon) in the top right corner to switch between dark and light modes. Your preference is saved automatically.

## Mobile Access

The dashboard is fully responsive. On mobile:

- Sidebar collapses to hamburger menu
- Touch-friendly buttons and controls
- Same functionality as desktop

## Session & Security

- Sessions expire after 24 hours
- Idle timeout after 30 minutes
- Use a strong password
- Consider setting up HTTPS (see NPM guide)
