# App Store Guide

CubeOS includes a built-in App Store with curated self-hosted applications that install in one click. Every app runs as an isolated service and is accessible via its own `appname.cubeos.cube` subdomain — no port numbers to remember, no manual configuration.

## Browsing the App Store

### Opening the App Store

1. Open the CubeOS Dashboard at `http://cubeos.cube`
2. Click **Apps** in the sidebar
3. Select the **App Store** tab

The App Store has two sub-tabs: **Browse** (the catalog) and **Installed** (apps you've already added).

### Searching and Filtering

The Browse view provides three filter controls at the top:

- **Search** — type any keyword to search across app names, descriptions, and image names. Results update as you type.
- **Category** — filter by category (e.g. Media, Productivity, Development). When you have offline-cached apps, an "Offline Apps" category appears automatically.
- **Store** — filter by source. Only visible when multiple stores are configured. An "Offline Apps" virtual store appears when cached apps exist.

### App Cards

Each app in the grid shows:

- **App icon** — loaded from the store catalog, with a fallback icon for offline-cached apps
- **App name and tagline** — the name and a brief description
- **Installed badge** — a green checkmark in the top-right corner if the app is already installed
- **Offline indicator** — a download icon in the top-left for apps stored in the local registry (see [Offline Apps](#offline-apps)). Green for fully cached apps, gray for store apps that have been partially cached.

Apps that are not yet installed show two buttons:

- **Install** — starts the install flow immediately
- **Cache Offline** — downloads the app's image to the local registry without deploying it (see [Offline Apps](#offline-apps))

Click anywhere on the card (not a button) to open a detail sheet with a full description, screenshots, and architecture compatibility badges. ARM64-compatible apps are highlighted in green since CubeOS runs natively on ARM64 hardware.

### Results Footer

The bottom of the grid shows a count like "Showing 47 apps (40 store + 7 offline)" so you know how many apps are available from each source.

## Installing an App

### Step 1: Configure Volumes

After clicking **Install**, a confirmation modal appears with the app's storage settings:

- **Data Volumes** — persistent storage for your app data. Each volume shows its container path and host path. Click **Browse** to pick a custom directory, or accept the defaults under `/cubeos/data/apps/<name>/`.
- **Config Volumes** — internal configuration volumes shown in a collapsed section. These are read-only and don't need changes.
- **Network Configuration** (Advanced mode only) — override the auto-assigned port or subdomain.

Click **Install with Defaults** to proceed, or **Install with Custom Settings** if you changed any paths.

> **Tip:** In Standard mode, apps with no configurable volumes skip this step entirely and begin installing immediately.

### Step 2: Watch the Progress

A progress modal appears with a real-time step indicator. Each step shows a spinner while active, a green checkmark when done, or a red X on failure:

| Step | What happens |
|------|-------------|
| Validating manifest | Checks the app definition is complete and valid |
| Reading configuration | Loads the app's service template from the store |
| Allocating port | Reserves a port in the 6100–6999 range |
| Processing manifest | Applies CubeOS-specific settings to the template |
| Creating directories | Creates data and config directories on disk |
| Preparing containers | Remaps volume paths and writes the final service configuration |
| Deploying containers | Launches the app's containers |
| Starting services | Waits for the app to become healthy (up to 5 minutes for large apps) |
| Saving configuration | Records the app in the CubeOS database |
| Configuring DNS | Adds `appname.cubeos.cube` to local DNS |
| Setting up access | Creates a reverse proxy so the subdomain routes to the app |
| Detecting web interface | Probes for the app's web UI endpoint |
| Ready! | Installation complete |

A progress bar fills as steps complete. The percentage is shown in the footer.

### Step 3: Open the App

When installation succeeds:

- An **Open App** button appears — it opens `http://appname.cubeos.cube` in a new tab
- A **Done** button closes the modal
- The app immediately appears in the **My Apps** tab

### What Happens if Installation Fails?

If any step fails, CubeOS automatically rolls back all completed steps in reverse order — containers are removed, the port is released, DNS and proxy entries are cleaned up, and directories are deleted. Your system stays in a clean state. The error message is shown in the progress modal so you know what went wrong.

### Automatic Offline Caching

After a successful install, CubeOS automatically caches the app's image and metadata in the local registry. This means reinstalling the same app later — even without internet — uses the locally stored copy.

## Offline Apps

### What the Download Icon Means

A download icon on an app card means the app's image is stored in the CubeOS local registry and can be installed without internet access.

Apps get cached in the local registry in two ways:

1. **Automatically** — every app you install is cached after deployment succeeds
2. **Manually** — click **Cache Offline** on any app card to pre-download its image without installing it

### Installing Offline

Offline apps install the same way as online apps. The only difference is that the image is pulled from the local registry instead of the internet, which is faster and works even when CubeOS is in Offline Hotspot mode with no internet connection.

In the install confirmation modal, offline apps display a green "Cached Locally — Offline" badge and show the cached image details.

The install progress shows slightly different steps for offline apps since there's no store manifest to read:

| Step | What happens |
|------|-------------|
| Validating app | Checks the app definition is valid |
| Allocating port | Reserves a port in the 6100–6999 range |
| Creating directories | Creates data and config directories on disk |
| Generating configuration | Writes the service configuration from cached metadata |
| Deploying containers | Launches the app's containers from the local registry |
| Starting services | Waits for the app to become healthy |
| Saving to database | Records the app in the CubeOS database |
| Configuring DNS | Adds `appname.cubeos.cube` to local DNS |
| Setting up access | Creates a reverse proxy for the subdomain |
| Ready! | Installation complete |

### Syncing the Store Catalog

Click the **Sync** button in the App Store header to refresh the catalog from remote stores. When offline, the catalog still shows all locally cached apps — you never lose access to apps you've already cached.

## Managing Installed Apps

### My Apps Tab

The **My Apps** tab shows all installed apps in a responsive grid. Each card displays:

- **App icon and name**
- **Status indicator** — green dot (running), pulsing amber dot (unhealthy), gray dot (stopped)
- **Status text** — "running" or "stopped"
- **Port numbers** (Advanced mode only) — shown at the bottom of the card

### Favorites

Click the star icon on any app card to pin it as a favorite. Favorites appear in a dedicated section at the top of My Apps for quick access.

### Category Filters

Filter apps using the category chips at the top of the grid:

- **All Apps** — shows everything
- **Category chips** — one per category (e.g. Media, Productivity), each showing the number of apps
- **CubeOS Core** — toggle to show built-in system services

### Actions

Hover over a card (or tap on mobile) to reveal action buttons:

| Button | Action | Notes |
|--------|--------|-------|
| **Play** | Start a stopped app | No confirmation needed |
| **Stop** | Stop a running app | Confirmation dialog. Not available for core system services. |
| **Restart** | Restart a running app | Confirmation dialog |
| **Star** | Toggle favorite | Pins the app to the favorites section |
| **Open** | Open the app's web UI | Only shown when the app is running and has a web interface |
| **Info** | Open the detail sheet | Shows Overview, Logs, and Docker tabs |

Clicking a running app's card directly opens its web UI in a new tab — no need to find the Open button.

### Viewing Logs

There are two ways to view app logs:

1. **Detail sheet** — click the Info button on any app card, then select the **Logs** tab. Shows the last 50 log lines with a Refresh button.
2. **Dozzle** — go to `http://logs.cubeos.cube` for full-featured log viewing with live streaming, search, multi-container views, and log downloads.

### Docker Details (Advanced Mode)

In the detail sheet, the **Docker** tab (Advanced mode only) shows:

- Container ID and image name
- Resource limits (memory, CPU)
- Networks
- Mounts with source and target paths, including read-only flags

## Removing an App

1. Open the app's detail sheet by clicking the **Info** button on its card
2. Scroll to the **Danger Zone** at the bottom of the Overview tab
3. Click **Uninstall**
4. A confirmation dialog appears with a **Delete app data** checkbox (checked by default):
   - **Checked**: all app data under `/cubeos/data/apps/<name>/` is permanently deleted
   - **Unchecked**: app data is preserved on disk for future reinstallation
5. Click **Confirm** to proceed

The removal progress is shown step by step:

| Step | What happens |
|------|-------------|
| Validating app | Confirms the app exists and can be removed |
| Stopping services | Shuts down the app's running containers |
| Removing containers | Removes the app's container definitions |
| Removing DNS entry | Deletes `appname.cubeos.cube` from local DNS |
| Removing proxy | Removes the reverse proxy route for the subdomain |
| Removing configuration | Deletes the app record from the database (ports and DNS entries are released automatically) |
| Cleaning up files | Removes directories from disk (skipped if you chose to keep app data) |
| Uninstalled | Removal complete |

Core system services (Pi-hole, Nginx Proxy Manager, Dozzle, etc.) cannot be uninstalled — the Danger Zone is hidden for these apps.

### Preserving Data for Reinstallation

If you uncheck "Delete app data" before uninstalling, the app's data directories remain at `/cubeos/data/apps/<name>/`. When you reinstall the same app later, it picks up the existing data automatically — useful for apps like databases or media servers where you want to keep your content.

## Troubleshooting

### App Stuck at "Starting Services"

The "Starting services" step waits for the app to become healthy. This can take a while for large apps.

1. **Wait** — the step allows up to 5 minutes, which is needed for large apps (e.g. Jellyfin at ~500 MB) especially on SD card storage
2. **Check logs** — go to `http://logs.cubeos.cube` and look for the app's container to see if there are startup errors
3. **Check disk space** — large apps need free space for both the image and runtime data
4. **If it fails** — CubeOS automatically rolls back all completed steps. Check the error message in the progress modal and retry

### App Not Accessible After Install

If installation completed but `appname.cubeos.cube` doesn't load in your browser:

1. **Check the app is running** — look for a green status dot in My Apps
2. **Check DNS** — make sure your device is connected to the CubeOS network and using CubeOS as its DNS server
3. **Try the direct address** — in Advanced mode, the app's port is shown on the card. Try `http://10.42.24.1:<port>` directly to bypass DNS
4. **Check the proxy** — go to `http://npm.cubeos.cube` and verify a proxy host exists for the app's subdomain
5. **Restart the app** — sometimes a restart resolves initial connectivity issues

### App Store Shows No Apps or Stale Listings

1. Click the **Sync** button in the App Store header to refresh the catalog
2. Verify internet connectivity — the store catalog requires a network connection to fetch new listings
3. Even without internet, all locally cached apps always appear in the catalog

### Installation Rolled Back

If an install fails and you see rollback steps completing, CubeOS has cleaned up automatically. Common causes:

- **Port conflict** — another service is already using the allocated port. Check the Ports view (Advanced mode) for conflicts
- **Disk full** — not enough space for the app image or data directories
- **Image pull failure** — the app's image couldn't be downloaded. Check internet connectivity, or cache the app offline first and then install from the local registry
