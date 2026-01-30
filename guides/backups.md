# Backup & Recovery Guide

CubeOS includes built-in backup functionality to protect your configuration and data.

## What Gets Backed Up

A CubeOS backup includes:

- **System configuration** - WiFi settings, hostname, timezone
- **User accounts** - Admin credentials and preferences
- **Service configurations** - Docker compose files, app settings
- **Pi-hole settings** - Blocklists, custom DNS, DHCP leases
- **NPM configurations** - Proxy hosts, SSL certificates
- **Docker volumes** (optional) - Application data

## Creating a Backup

### Via Dashboard

1. Go to **Settings** → **Backup**
2. Click **Create Backup**
3. Enter a name (e.g., "before-update-2024")
4. Choose options:
   - ☑ Include Docker volumes (larger, but complete)
   - ☑ Include logs
5. Click **Create**
6. Wait for completion (may take several minutes)

### Via API

```bash
TOKEN="your-token"
curl -X POST http://192.168.42.1:9009/api/v1/backup/create \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name": "my-backup", "include_docker_volumes": true}'
```

### Via Command Line

```bash
# Quick backup
/cubeos/scripts/backup.sh

# With custom name
/cubeos/scripts/backup.sh --name "pre-update"

# Include everything
/cubeos/scripts/backup.sh --full
```

## Backup Storage

Backups are stored in `/cubeos/backups/` with structure:

```
/cubeos/backups/
├── backup-2024-01-30-1200.tar.gz
├── backup-pre-update.tar.gz
└── backup-weekly-auto.tar.gz
```

## Automatic Backups

CubeOS can create automatic backups:

1. Go to **Settings** → **Backup** → **Schedule**
2. Enable automatic backups
3. Choose frequency:
   - Daily (keeps last 7)
   - Weekly (keeps last 4)
   - Monthly (keeps last 12)
4. Set preferred time

## Restoring from Backup

### Via Dashboard

1. Go to **Settings** → **Backup**
2. Find your backup in the list
3. Click **Restore**
4. Confirm the restore
5. System will reboot automatically

### Via Command Line

```bash
# List available backups
ls /cubeos/backups/

# Restore specific backup
/cubeos/scripts/restore.sh /cubeos/backups/backup-2024-01-30.tar.gz

# System will reboot after restore
```

### Manual Restore (Emergency)

If you can't access the dashboard:

```bash
# Extract backup
cd /tmp
tar -xzf /cubeos/backups/backup-name.tar.gz

# Restore configuration
cp -r tmp/cubeos/* /cubeos/

# Restart services
docker compose -f /cubeos/coreapps/orchestrator/appconfig/docker-compose.yml up -d

# Reboot
reboot
```

## Downloading Backups

To keep backups off-device:

### Via Dashboard

1. Go to **Settings** → **Backup**
2. Click the download icon next to a backup
3. Save to your computer

### Via SCP

```bash
scp root@192.168.42.1:/cubeos/backups/backup-name.tar.gz ./
```

## Uploading Backups

To restore from a backup file:

### Via Dashboard

1. Go to **Settings** → **Backup**
2. Click **Upload Backup**
3. Select your .tar.gz file
4. Click **Upload**
5. Then click **Restore**

### Via SCP

```bash
scp ./backup-name.tar.gz root@192.168.42.1:/cubeos/backups/
```

## Best Practices

1. **Backup before updates** - Always backup before upgrading CubeOS
2. **Test restores** - Periodically verify backups work
3. **Off-site copies** - Download important backups to another device
4. **Label clearly** - Use descriptive names like "before-homeassistant-install"
5. **Don't rely solely on SD card** - SD cards can fail

## Disaster Recovery

If CubeOS won't boot:

1. **Flash fresh CubeOS image** to SD card
2. Boot the Pi
3. **Upload your backup** via dashboard or SCP
4. **Restore from backup**
5. All settings and apps will be recovered

## What's NOT Backed Up

- **Operating system** - You'll need a fresh CubeOS image
- **External storage** - USB drives must be backed up separately
- **Large media files** - Consider separate backup for media libraries
