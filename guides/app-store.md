# App Store Guide

CubeOS includes a built-in App Store with curated self-hosted applications that install in one click. Apps run as Docker Swarm services and are accessible via `appname.cubeos.cube` subdomains.

## Browsing the App Store

### Opening the App Store

1. Navigate to **Apps** in the Dashboard sidebar
2. Select the **App Store** tab

The App Store has two sub-tabs: **Browse** and **Installed**.

### Searching and Filtering

The Browse view provides three filter controls:

- **Search** — free-text search across app names, descriptions, and image names
- **Category** — dropdown filter (e.g. Media, Productivity, Development). An "Offline Apps" category appears automatically when cached apps are available
- **Store** — filter by store source (only shown when multiple stores are configured). An "Offline Apps" virtual store appears when cached apps exist

### App Cards

Each app card in the grid shows:

- **App icon** — loaded from the store, with a fallback icon for offline-cached apps
- **App name** — truncated if long
- **Category or tagline** — brief description beneath the name
- **Installed badge** — green checkmark in the top-right corner if the app is already installed
- **Offline indicator** — download arrow icon in the top-left for apps available in the local registry (see [Offline Apps](#offline-apps))

Cards for apps that are not yet installed show two buttons:

- **Install** — starts the install flow immediately
- **Cache Offline** — downloads the app image to the local registry without deploying it

Clicking a card (rather than a button) opens a detail sheet with screenshots, architecture compatibility badges (ARM64 highlighted in green), and a full description.

### Results Footer

The bottom of the grid shows a count like "Showing 47 apps (40 store + 7 offline)" so you know what mix of sources is displayed.

## Installing an App

### Step 1: Configure Volumes

After clicking **Install**, a confirmation modal appears:

- **Data Volumes** — external volumes that persist your app data. Each shows the container path and the host path (editable). Use the **Browse** button to pick a custom directory, or accept the defaults under `/cubeos/data/apps/<name>/`
- **Config Volumes** — internal/config volumes shown collapsed, read-only
- **Network Configuration** (Advanced mode only) — override the auto-assigned port or subdomain

Click **Install with Defaults** (or **Install with Custom Settings** if you changed paths).

### Step 2: Watch the Progress

A progress modal appears with a real-time step indicator powered by the FlowEngine. Each step shows a spinner while active, a green checkmark when done, or a red X on failure:

| Step | What happens |
|------|-------------|
| Validating manifest | Checks the app definition is valid |
| Reading configuration | Loads the app's Docker Compose template |
| Allocating port | Reserves a port in the 6100-6999 range |
| Processing manifest | Applies CubeOS-specific settings to the template |
| Creating directories | Creates data/config directories on disk |
| Preparing containers | Remaps volumes to safe CubeOS paths and writes the final compose file |
| Deploying containers | Runs `docker stack deploy` via Swarm |
| Starting services | Waits for the container to converge and become healthy (up to 5 minutes for large images) |
| Saving configuration | Records the app in the database |
| Configuring DNS | Adds `appname.cubeos.cube` to Pi-hole |
| Setting up access | Creates a reverse proxy entry in Nginx Proxy Manager |
| Detecting web interface | Probes for the app's web UI endpoint |
| Ready! | Final health check via HAL |

A progress bar under the header fills as steps complete.

### Step 3: Open the App

When installation succeeds:

- An **Open App** button appears — it opens `http://appname.cubeos.cube` in a new tab
- A **Done** button closes the modal
- The app immediately appears in the **My Apps** tab

If installation fails, the FlowEngine automatically rolls back completed steps in reverse order (removes the stack, releases the port, cleans up directories) so your system stays clean. The error message is shown in the progress modal.

### Automatic Offline Caching

After a successful install, CubeOS automatically caches the app's Docker image and manifest in the local registry (port 5000). This means if you reinstall the same app later — even without internet — the image is already available locally.

## Offline Apps

### What the Download Icon Means

A download arrow icon on an app card means the app image is stored in the CubeOS local Docker registry and can be installed without internet access.

Apps get cached in the local registry in two ways:

1. **Automatically** — every app you install is cached after deployment
2. **Manually** — click **Cache Offline** on any app card to pre-download its image without installing it

### Installing Offline

Offline apps install identically to online apps. The only difference is that Docker pulls the image from the local registry (`localhost:5000`) instead of the internet, which is faster and works in OFFLINE network mode.

In the install confirmation modal, offline apps display a green "Offline" badge and a note: "Cached locally — no internet required."

### Syncing the Store Catalog

Click the **Sync** button in the App Store header to refresh the catalog from remote stores. When offline, the catalog still shows all locally cached apps.

## Managing Installed Apps

### My Apps Tab

The **My Apps** tab shows all installed apps in a responsive grid. Each card displays:

- **App icon and name**
- **Status dot** — green (healthy), amber pulsing (unhealthy), gray (stopped)
- **Status text** — "Running" or "Stopped"
- **Port numbers** (Advanced mode only)

#### Favorites

Click the star icon on any app to pin it as a favorite. Favorites appear in a dedicated section at the top of the tab.

#### Category Filters

Filter by category chips: Infrastructure, Platform, Network & Privacy, AI & ML, Applications. A "CubeOS Core" toggle shows system services, and "All Apps" shows everything.

### Actions

Hover over a card (or tap on mobile) to reveal action buttons:

| Button | Action | Notes |
|--------|--------|-------|
| Play | Start a stopped app | No confirmation needed |
| Stop | Stop a running app | Confirmation dialog (not available for core services) |
| Restart | Restart a running app | Confirmation dialog |
| Star | Toggle favorite | Pins to favorites section |
| Open | Open the app's web UI | Only shown when running and the app has a web interface |
| Info | Open the detail sheet | Shows Overview, Logs, and Docker tabs |

Clicking a running app card directly opens its web UI in a new tab.

### Viewing Logs

There are two ways to view app logs:

1. **Detail sheet** — click the Info button on any app card, then select the **Logs** tab. Shows the last 50 log lines with a Refresh button
2. **Dozzle** — go to http://logs.cubeos.cube for full-featured log viewing with live streaming, search, multi-container views, and log downloads

### Environment Variables and Docker Details

In the app detail sheet, the **Docker** tab (Advanced mode only) shows:

- Container ID and image
- Resource limits (memory, CPU)
- Networks
- Mounts (source path, target path, read-only flag)

## Removing an App

1. Open the app's detail sheet (click the Info button)
2. Scroll to the **Danger Zone** at the bottom of the Overview tab
3. Click **Uninstall App**
4. A confirmation dialog appears:
   - **"Also delete app data"** checkbox — checked by default
   - If checked: all app data under `/cubeos/data/apps/<name>/` is permanently deleted
   - If unchecked: app data is preserved on disk for future reinstallation

5. Click **Uninstall** to confirm

The FlowEngine runs the removal workflow:

| Step | What happens |
|------|-------------|
| Stopping services | Scales the Swarm service to zero and removes the stack |
| Removing DNS entry | Deletes `appname.cubeos.cube` from Pi-hole |
| Removing proxy | Removes the Nginx Proxy Manager host |
| Removing configuration | Deletes the app record (cascades to ports and FQDNs) |
| Cleaning up files | Removes directories if "delete app data" was selected |

Core system services (Pi-hole, NPM, Dozzle, etc.) cannot be uninstalled — the Danger Zone is hidden for these apps.

### Preserving Data for Reinstallation

If you uncheck "Also delete app data" before uninstalling, the app's data directories remain at `/cubeos/data/apps/<name>/`. When you reinstall the same app later, it picks up the existing data automatically.

## Troubleshooting

### App Stuck Installing

If an app appears stuck at "Starting services" (the convergence step), it usually means the container image is large and still downloading, or the container is failing to start.

1. **Wait** — the convergence step allows up to 5 minutes, which is needed for large images (e.g. Jellyfin at ~500MB) on SD card storage
2. **Check Dozzle** — go to http://logs.cubeos.cube and look for the app's container to see startup errors
3. **Check disk space** — large apps need free space for both the image and runtime data. SSH in and run `df -h`
4. **If it fails** — the FlowEngine automatically rolls back all completed steps. Check the error message in the progress modal and retry

### App Not Accessible After Install

If installation completed but `appname.cubeos.cube` doesn't load:

1. **Check the app is running** — look for a green status dot in My Apps
2. **Check DNS** — from a device on the CubeOS network, run `nslookup appname.cubeos.cube 10.42.24.1`
3. **Check NPM** — go to http://npm.cubeos.cube and verify a proxy host exists for the app's subdomain
4. **Try the direct port** — in Advanced mode, the app's port is shown on the card. Try `http://10.42.24.1:<port>` directly
5. **Restart the app** — sometimes a restart resolves initial connectivity issues

### Registry Sync Issues

If the App Store shows no apps or stale listings:

1. Click the **Sync** button in the App Store header
2. Verify internet connectivity — the store catalog requires a network connection to fetch (but cached/offline apps always appear)
3. Check that the local Docker registry is running: look for the registry service in the Docker tab (Advanced mode)

### Installation Rolled Back

If an install fails and you see the rollback steps completing, the FlowEngine has cleaned up automatically. Common causes:

- **Port conflict** — another service is using the allocated port. Check the Ports tab (Advanced mode) for conflicts
- **Disk full** — not enough space for the Docker image or app data
- **Image pull failure** — the app's Docker image couldn't be downloaded. Check internet connectivity or use an offline-cached version
