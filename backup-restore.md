# Backup and Restore

CubeOS includes a built-in backup system that protects your configuration, app data, and system state. This guide covers creating backups, scheduling automatic backups, and restoring from a backup.

## Table of Contents

- [Overview](#overview)
- [What Gets Backed Up](#what-gets-backed-up)
- [Backup Scopes](#backup-scopes)
- [Creating a Backup](#creating-a-backup)
- [Backup Destinations](#backup-destinations)
- [Encryption](#encryption)
- [Scheduled Backups](#scheduled-backups)
- [Restoring from a Backup](#restoring-from-a-backup)
- [Bare-Metal Restore](#bare-metal-restore)
- [Troubleshooting](#troubleshooting)

---

## Overview

Backups protect you from SD card failures, accidental misconfiguration, and data loss. CubeOS offers three backup scopes so you can balance speed and storage against completeness. Backups can be stored locally, on USB drives, or on network shares.

All backups are compressed archives. You can optionally encrypt them with a device key (works only on the same Pi) or a passphrase (portable to any Pi).

## What Gets Backed Up

| Data | Included In |
|------|-------------|
| SQLite database (`cubeos.db`) | All scopes |
| System configuration (`defaults.env`, `secrets.env`) | All scopes |
| Setup completion flag | All scopes |
| App configurations (compose files, environment files) | Tier 2 and above |
| Network settings (WiFi AP config, VPN configs) | Tier 2 and above |
| Pi-hole configuration | Tier 2 and above |
| Nginx Proxy Manager configuration | Tier 2 and above |
| Docker volumes (app data) | Tier 3 only |
| Local Docker registry images | Tier 3 only |

**Not included in any backup**: The CubeOS operating system itself, Docker engine, or system packages. These are part of the base image and are restored by flashing a new SD card.

## Backup Scopes

### Tier 1: Database and Config

- **Size**: ~2 MB
- **Speed**: Seconds
- **Recommended frequency**: Daily
- **What it covers**: Database, system config files, secrets

This is the fastest backup. It captures your entire system state -- installed apps, port allocations, DNS entries, proxy rules, user settings, and credentials. Restoring a Tier 1 backup on a fresh CubeOS installation rebuilds the system to its previous state, though apps will need to re-pull their Docker images.

### Tier 2: App Configurations

- **Size**: ~5-20 MB
- **Speed**: Under a minute
- **Recommended frequency**: Weekly
- **What it covers**: Everything in Tier 1, plus app compose files, environment files, network configuration, VPN configs, Pi-hole settings, NPM rules

Tier 2 adds all the configuration files that apps and services use. This is useful if you've customized app settings, created VPN configurations, or set up complex proxy rules.

### Tier 3: Full Backup

- **Size**: 100 MB - 10 GB (depends on installed apps and data)
- **Speed**: Minutes to tens of minutes
- **Recommended frequency**: Weekly or before major changes
- **What it covers**: Everything in Tier 2, plus all Docker volumes and local registry images

A full backup includes all app data stored in Docker volumes. This means databases, media files, uploaded documents, and any other persistent data your apps have created. Restoring from a Tier 3 backup gives you an exact replica of your system, data and all.

## Creating a Backup

### From the Dashboard

1. Open the dashboard at [http://cubeos.cube](http://cubeos.cube).
2. Navigate to **Settings** > **Backups**.
3. Click **Create Backup**.
4. Choose the backup scope (Tier 1, 2, or 3).
5. Choose the destination (local, USB, or network share).
6. Optionally enable encryption (see [Encryption](#encryption)).
7. Click **Start Backup**.
8. Progress is displayed in real time. Do not power off the Pi during backup.

### From the API

```bash
curl -X POST http://api.cubeos.cube/api/v1/system/backup \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"scope": "tier1", "destination": "local"}'
```

## Backup Destinations

### Local Storage

Backups are stored on the Pi's SD card or SSD at `/cubeos/backups/`. This is the fastest option but does not protect against storage failure. Use local backups as a complement to external backups, not as your only copy.

### USB Drive

1. Plug a USB drive into the Pi.
2. The drive appears in Dashboard > Storage.
3. When creating a backup, select the USB drive as the destination.
4. Backups are written to the root of the USB drive in a `cubeos-backups/` directory.

USB drives are the recommended external backup destination. They're fast, portable, and work in OFFLINE mode.

### NFS Share

1. Go to Dashboard > Storage > Mounts.
2. Add an NFS mount (server address and export path).
3. The mounted share appears as a backup destination.

### SMB Share

1. Go to Dashboard > Storage > Mounts.
2. Add an SMB mount (server address, share name, credentials).
3. The mounted share appears as a backup destination.

Network shares require ONLINE_ETH or ONLINE_WIFI mode.

## Encryption

CubeOS supports two encryption modes for backups:

### Device Mode (Default)

- Backups are encrypted with a key unique to the Pi's hardware.
- **Pro**: No passphrase to remember. Fully automatic.
- **Con**: The backup can only be restored on the same Pi. If the Pi is lost or damaged, the backup is unrecoverable.
- **Best for**: Routine daily backups where the Pi itself is safe.

### Portable Mode

- Backups are encrypted with a passphrase you provide.
- **Pro**: Can be restored on any Pi running CubeOS.
- **Con**: You must remember or securely store the passphrase. If lost, the backup is unrecoverable.
- **Best for**: Backups stored off-site, USB drives that travel, or preparing for Pi replacement.

### Unencrypted

You can also create unencrypted backups. These can be restored on any Pi and don't require a passphrase, but the contents (including secrets and credentials) are stored in plain text.

## Scheduled Backups

Automatic backups run on a schedule so you don't have to remember.

### Setting Up a Schedule

1. Go to Dashboard > Settings > Backups > Schedule.
2. Configure:
   - **Frequency**: Daily, weekly, or custom cron expression
   - **Time**: When to run (defaults to 3:00 AM)
   - **Scope**: Which tier to back up
   - **Destination**: Where to store the backup
   - **Encryption**: Device mode, portable mode, or none
3. Save the schedule.

### Retention Policy

Set how many backups to keep. When the limit is reached, the oldest backup is deleted automatically.

| Suggestion | Frequency | Retention |
|------------|-----------|-----------|
| Minimal protection | Weekly Tier 1 | Keep 4 (one month) |
| Standard protection | Daily Tier 1 + Weekly Tier 2 | Keep 7 daily + 4 weekly |
| Full protection | Daily Tier 1 + Weekly Tier 3 | Keep 7 daily + 4 weekly |

Adjust retention based on your available storage space.

## Restoring from a Backup

### From the Dashboard

1. Go to Dashboard > Settings > Backups.
2. Browse available backups (local, USB, or network shares).
3. Select the backup to restore.
4. If the backup is encrypted, enter the passphrase (portable mode) or confirm device key (device mode).
5. Review what will be restored.
6. Click **Restore**.
7. The system applies the backup and restarts affected services.

### What Happens During Restore

- **Tier 1 restore**: Database and config files are replaced. Apps are reconciled against the restored database -- missing apps are re-deployed from available images.
- **Tier 2 restore**: Same as Tier 1, plus app configuration files and network settings are restored.
- **Tier 3 restore**: Same as Tier 2, plus Docker volumes and registry images are restored. This gives you an exact copy of the previous system state.

Restoring does not affect the base operating system. CubeOS itself remains intact.

## Bare-Metal Restore

If your SD card fails or you want to set up a new Pi with an existing backup:

1. Flash a fresh CubeOS image to a new SD card (see [Getting Started](getting-started.md#flash-the-image)).
2. Insert the SD card and plug in a USB drive containing a CubeOS backup.
3. Power on the Pi.
4. During first boot, CubeOS detects the backup on the USB drive.
5. The setup wizard offers to restore from the backup instead of starting fresh.
6. Select the backup and provide the passphrase if encrypted (portable mode).
7. CubeOS restores the configuration and rebuilds the system.

For device-mode encrypted backups, bare-metal restore only works if you're using the same Pi. For portable-mode backups, any Pi will work.

## Troubleshooting

### "Backup failed: not enough space"

- Check available storage on the destination: Dashboard > Storage.
- For Tier 3 backups, you may need a larger USB drive or network share.
- Run a Tier 1 backup instead if storage is limited -- it's only ~2 MB.
- Delete old backups to free space.

### "Cannot restore: backup is from a different CubeOS version"

- CubeOS backups include version information. Major version mismatches may prevent restore.
- Update CubeOS to the version matching the backup, then restore.
- Tier 1 and Tier 2 backups are generally forward-compatible across minor versions.

### "USB drive not detected"

- Try a different USB port.
- Make sure the drive is formatted as ext4, FAT32, or exFAT.
- Check Dashboard > Storage to see if the drive appears.
- Some USB hubs may not provide enough power. Connect the drive directly to the Pi.

### "Restore completed but apps are not running"

- After a Tier 1 or Tier 2 restore, apps need to re-pull their Docker images. This requires either:
  - Internet access (ONLINE_ETH or ONLINE_WIFI mode), or
  - The images being present in the local Docker registry
- Check Dashboard > Apps for app status. Apps in "Pending" state are waiting for image pulls.
- A Tier 3 restore includes all images, so this issue does not occur.

### "Encrypted backup won't decrypt"

- Double-check the passphrase (portable mode). It is case-sensitive.
- Device-mode backups only work on the same Pi. If you're on a different Pi, you need a portable-mode backup.
- There is no passphrase recovery. If the passphrase is lost, the backup cannot be decrypted.
