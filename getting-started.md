# Getting Started with CubeOS

This guide walks you through setting up CubeOS for the first time -- from flashing the image to installing your first app.

## Table of Contents

- [What You Need](#what-you-need)
- [Download CubeOS](#download-cubeos)
- [Flash the Image](#flash-the-image)
- [First Boot](#first-boot)
- [Connect to CubeOS](#connect-to-cubeos)
- [Setup Wizard](#setup-wizard)
- [Dashboard Overview](#dashboard-overview)
- [Install Your First App](#install-your-first-app)
- [Next Steps](#next-steps)

---

## What You Need

Before you start, make sure you have the following:

| Item | Details |
|------|---------|
| **Raspberry Pi** | Pi 4 or Pi 5 (64-bit). Minimum 2 GB RAM, 4 GB recommended. |
| **microSD Card** | 16 GB minimum, 32 GB recommended. Class 10 or faster. |
| **Power Supply** | USB-C: 5V 3A for Pi 4, 5V 5A for Pi 5. Use the official power supply. |
| **Ethernet Cable** | Optional. Required only if you want internet via Ethernet (ONLINE_ETH mode). |
| **A Device with WiFi** | Phone, tablet, or computer to connect to the CubeOS WiFi network. |

Optional but useful:
- USB SSD for better performance and reliability than a microSD card
- HDMI monitor to see boot progress (not required)
- USB WiFi adapter for ONLINE_WIFI mode (RTL8812AU chipset recommended)

## Download CubeOS

There are two ways to get the CubeOS image:

### Option A: Raspberry Pi Imager (Recommended)

1. Download and install [Raspberry Pi Imager](https://www.raspberrypi.com/software/).
2. Open Raspberry Pi Imager.
3. Click "Choose OS" and scroll to "Other general-purpose OS".
4. Select "CubeOS".
5. Choose the variant:
   - **CubeOS Full** -- All features, recommended for 4 GB+ RAM
   - **CubeOS Lite** -- Core platform only, for 2 GB RAM boards
6. Continue to the flashing step below.

### Option B: Direct Download

1. Go to [cubeos.app/download](https://cubeos.app/download).
2. Download the `.img.xz` file for your board.
3. Continue to the flashing step below.

## Flash the Image

### Using Raspberry Pi Imager

1. In Raspberry Pi Imager, click "Choose Storage" and select your microSD card.
2. Before flashing, click the gear icon to customize settings:
   - **Hostname**: Leave as default or set a custom name
   - **SSH**: Enable if you want remote terminal access (optional)
   - **WiFi**: These settings configure the *client* WiFi, not the CubeOS access point. Leave blank for now.
3. Click "Write" and wait for the process to complete.
4. Safely eject the SD card.

### Using balenaEtcher

1. Download and install [balenaEtcher](https://etcher.balena.io/).
2. Click "Flash from file" and select the downloaded `.img.xz` file.
3. Select your microSD card as the target.
4. Click "Flash!" and wait for completion.
5. Safely eject the SD card.

**Important**: Flashing will erase everything on the SD card. Make sure you select the correct drive.

## First Boot

1. Insert the microSD card into your Raspberry Pi.
2. If you want internet access, plug in an Ethernet cable now.
3. Connect the power supply. The Pi will start automatically.
4. Wait approximately 90 seconds for the first boot to complete.

During first boot, CubeOS:
- Initializes the file system
- Enables the hardware watchdog
- Starts Docker and Docker Swarm
- Deploys core infrastructure (DNS, reverse proxy, local registry)
- Creates the WiFi access point
- Starts the API and dashboard
- Presents the setup wizard

If you have a monitor connected, you'll see boot progress on screen. A monitor is not required -- everything works headless.

## Connect to CubeOS

Once boot completes (about 90 seconds), CubeOS creates a WiFi access point:

1. On your phone, tablet, or computer, open WiFi settings.
2. Look for a network named **CubeOS** (or **CubeOS-Setup** on first boot).
3. Connect using the default password: **cubeos1234**
4. Open a web browser and navigate to one of:
   - [http://cubeos.cube](http://cubeos.cube) (recommended)
   - [http://10.42.24.1](http://10.42.24.1) (use this if the domain doesn't resolve)

The setup wizard loads automatically on first boot.

**Tip**: If `cubeos.cube` doesn't resolve immediately, wait 10-15 seconds for DNS to initialize, or use the IP address directly.

## Setup Wizard

The setup wizard guides you through initial configuration in five steps.

### Step 1: Admin Password

Set your admin password. This is used to log in to the dashboard and API.

**Write this password down.** There is no password recovery without a factory reset.

### Step 2: WiFi Access Point

Configure the WiFi network that CubeOS broadcasts:
- **Network Name (SSID)**: Choose a name for your CubeOS WiFi (default: CubeOS)
- **Password**: Set a WiFi password (minimum 8 characters)

After this step, your device will disconnect briefly as the access point restarts with the new name and password. Reconnect to the new network to continue.

### Step 3: Network Mode

Choose how CubeOS connects to the internet:

| Mode | When to Use |
|------|-------------|
| **OFFLINE** | No internet needed. Fully air-gapped. Best for field deployments, secure environments, or when you just want a local server. |
| **ONLINE via Ethernet** | You have an Ethernet cable plugged into a router or switch. Internet is shared with all WiFi clients. Best for home or office use. |
| **ONLINE via WiFi** | You have a USB WiFi adapter and want to connect to an existing WiFi network for internet. The Pi's built-in WiFi stays as the access point. |

If you choose ONLINE via WiFi, the wizard scans for available networks and lets you select one to connect to.

You can change the network mode at any time from the dashboard. See [Network Modes](network-modes.md) for full details.

### Step 4: Profile

Choose a pre-configured set of apps:

| Profile | Description |
|---------|-------------|
| **Full** | All features enabled. Dashboard, app store, file browser, log viewer, monitoring, and more. |
| **Minimal** | Core platform only. Dashboard and essential services. Add apps later as needed. |
| **Offline** | Optimized for air-gapped operation. Includes apps pre-loaded in the local registry. |

You can customize which apps are enabled at any time after setup.

### Step 5: Complete Setup

Review your settings and confirm. CubeOS applies the configuration and loads the dashboard. This takes about 15-30 seconds.

## Dashboard Overview

After setup, the dashboard is your home base for managing CubeOS.

![Dashboard Overview](../images/dashboard-overview.png)

The sidebar (or bottom navigation on phones) gives you access to:

| Section | What You Can Do |
|---------|-----------------|
| **Home** | System status at a glance -- CPU, memory, temperature, storage, uptime |
| **Apps** | View and manage installed apps. Start, stop, restart, or uninstall. |
| **App Store** | Browse and install new apps with one click. |
| **Network** | View current network mode, connected WiFi clients, DNS status. Switch modes. |
| **Storage** | Manage storage, USB drives, network mounts (SMB/NFS). |
| **Settings** | System configuration, updates, backups, user management. |

### Key URLs

Once CubeOS is running, these addresses work from any device connected to the CubeOS WiFi:

| Service | URL |
|---------|-----|
| Dashboard | [http://cubeos.cube](http://cubeos.cube) |
| Pi-hole Admin | [http://pihole.cubeos.cube/admin](http://pihole.cubeos.cube/admin) |
| Log Viewer (Dozzle) | [http://logs.cubeos.cube](http://logs.cubeos.cube) |
| Nginx Proxy Manager | [http://npm.cubeos.cube](http://npm.cubeos.cube) |
| API Swagger Docs | [http://api.cubeos.cube/swagger/index.html](http://api.cubeos.cube/swagger/index.html) |

Every installed app gets its own subdomain under `cubeos.cube`, automatically configured.

## Install Your First App

Let's install an app to see how the App Store works:

1. Open the dashboard at [http://cubeos.cube](http://cubeos.cube).
2. Navigate to **App Store** in the sidebar.
3. Browse the available apps or use the search bar.
4. Find an app you want to install (for example, a file browser or media server).
5. Click **Install**.
6. A progress indicator shows the installation steps in real time:
   - Port allocation
   - Directory creation
   - Docker image pull (if online) or local registry pull (if offline)
   - Stack deployment
   - DNS and proxy configuration
7. Once complete, the app appears in your **Apps** page.
8. Click the app to open it, or visit its FQDN (e.g., `http://files.cubeos.cube`).

Installation typically takes 10-30 seconds for cached images, or up to a few minutes if the image needs to be downloaded.

## Next Steps

Now that CubeOS is up and running, here are some things to explore:

- **[Network Modes](network-modes.md)** -- Learn about OFFLINE, Ethernet, and WiFi modes in detail, and how to switch between them.
- **[Backup and Restore](backup-restore.md)** -- Set up scheduled backups to protect your data and configuration.
- **[FAQ](faq.md)** -- Answers to common questions about CubeOS.
- **System Updates** -- Check for updates in Settings to keep your system current.
- **[Troubleshooting](guides/troubleshooting.md)** -- Solutions to common issues.
- **[API Reference](reference/api.md)** -- For advanced users who want to automate tasks via the REST API.
