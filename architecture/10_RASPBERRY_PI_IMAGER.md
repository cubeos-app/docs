# CubeOS Raspberry Pi Imager Listing

**Document:** 10_RASPBERRY_PI_IMAGER.md  
**Version:** 1.0  
**Last Updated:** January 31, 2026

---

## 1. Overview

CubeOS will be distributed via the official Raspberry Pi Imager application, making it easily accessible to millions of Raspberry Pi users. This document covers the technical requirements and submission process.

---

## 2. Image Technical Requirements

### 2.1 Image Format

| Requirement | Specification |
|-------------|---------------|
| Format | Raw disk image (.img) |
| Compression | XZ preferred (.img.xz) |
| Partition layout | MBR with FAT32 boot + ext4 root |
| Boot partition | /boot/firmware (FAT32) |
| Architecture | ARM64 (aarch64) |
| Supported devices | Pi 4 (64-bit), Pi 5 (64-bit) |

### 2.2 Customization Support

For CubeOS to support Imager's customization wizard (hostname, SSH keys, WiFi), it must implement cloud-init:

```yaml
# Required cloud-init configuration
# /boot/firmware/user-data

#cloud-config
hostname: cubeos
manage_etc_hosts: true

users:
  - name: cubeos
    groups: sudo, docker
    shell: /bin/bash
    sudo: ALL=(ALL) NOPASSWD:ALL
    lock_passwd: false
    ssh_authorized_keys: []  # Populated by Imager

# Network configuration from Imager
# /boot/firmware/network-config
```

### 2.3 First Boot Configuration

CubeOS must process Imager customizations on first boot:

```bash
#!/bin/bash
# /usr/local/bin/cubeos-process-imager-config.sh

# Check if Imager customization was applied
if [ -f /boot/firmware/user-data ]; then
    # cloud-init handles this automatically
    cloud-init status --wait
fi

# Process custom CubeOS setup
if [ -f /boot/firmware/cubeos-config.txt ]; then
    source /boot/firmware/cubeos-config.txt
    # Apply custom settings
fi
```

---

## 3. JSON Manifest Format

### 3.1 Repository JSON Structure

The Raspberry Pi Imager uses JSON V4 format (Imager 2.0+):

```json
{
    "os_list": [
        {
            "name": "CubeOS (64-bit)",
            "description": "Open-source ARM64 server OS for Raspberry Pi - Docker, self-hosting, offline-first",
            "url": "https://releases.cubeos.app/images/cubeos-2.0.0-arm64.img.xz",
            "icon": "https://releases.cubeos.app/images/cubeos-icon-40x40.png",
            "website": "https://cubeos.app",
            "release_date": "2026-02-15",
            "extract_size": 4294967296,
            "extract_sha256": "ef1c726f03b91d81d432646c304b52d546814dec5b3c8c9e8a71a935d34b7c4a",
            "image_download_size": 1073741824,
            "image_download_sha256": "a1b2c3d4e5f6...",
            "devices": ["pi4-64bit", "pi5-64bit"],
            "init_format": "cloudinit"
        }
    ]
}
```

### 3.2 Required Fields

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Display name in CHOOSE OS menu |
| `description` | string | Brief description (shown in list) |
| `url` | string | HTTPS URL to compressed image |
| `icon` | string | URL to 40x40 pixel PNG or SVG |
| `extract_size` | integer | Uncompressed image size in bytes |
| `extract_sha256` | string | SHA256 of **extracted** .img file |
| `image_download_size` | integer | Compressed file size in bytes |
| `release_date` | string | Format: YYYY-MM-DD |

### 3.3 Optional Fields

| Field | Type | Description |
|-------|------|-------------|
| `website` | string | Project website URL |
| `devices` | array | Supported device identifiers |
| `init_format` | string | `"cloudinit"` or `"systemd"` |
| `image_download_sha256` | string | SHA256 of compressed file |

### 3.4 Device Identifiers

```json
"devices": [
    "pi4-64bit",
    "pi5-64bit"
]
```

Available identifiers:
- `pi4-32bit`, `pi4-64bit`
- `pi5-64bit`
- `pi400-32bit`, `pi400-64bit`
- `pi3-64bit`
- `cm4-64bit`, `cm5-64bit`

---

## 4. CubeOS Manifest File

### 4.1 Full Manifest

```json
{
    "os_list": [
        {
            "name": "CubeOS",
            "description": "Open-source server OS for Raspberry Pi with Docker, self-hosting, and offline-first design",
            "icon": "https://releases.cubeos.app/images/cubeos-icon.png",
            "subitems_url": "https://releases.cubeos.app/rpi-imager.json"
        }
    ]
}
```

### 4.2 Subitems JSON (Hosted by CubeOS)

```json
{
    "os_list": [
        {
            "name": "CubeOS 2.0 (64-bit)",
            "description": "Recommended for Pi 4/5 with 2GB+ RAM",
            "url": "https://releases.cubeos.app/images/cubeos-2.0.0-arm64.img.xz",
            "icon": "https://releases.cubeos.app/images/cubeos-icon-40x40.png",
            "website": "https://cubeos.app",
            "release_date": "2026-02-15",
            "extract_size": 4294967296,
            "extract_sha256": "INSERT_ACTUAL_SHA256_HERE",
            "image_download_size": 1073741824,
            "image_download_sha256": "INSERT_ACTUAL_SHA256_HERE",
            "devices": ["pi4-64bit", "pi5-64bit", "pi400-64bit", "cm4-64bit", "cm5-64bit"],
            "init_format": "cloudinit"
        },
        {
            "name": "CubeOS 2.0 Lite (64-bit)",
            "description": "Minimal installation for Pi 4/5 with 1GB RAM",
            "url": "https://releases.cubeos.app/images/cubeos-2.0.0-lite-arm64.img.xz",
            "icon": "https://releases.cubeos.app/images/cubeos-icon-40x40.png",
            "website": "https://cubeos.app",
            "release_date": "2026-02-15",
            "extract_size": 2147483648,
            "extract_sha256": "INSERT_ACTUAL_SHA256_HERE",
            "image_download_size": 536870912,
            "devices": ["pi4-64bit", "pi5-64bit"],
            "init_format": "cloudinit"
        }
    ]
}
```

---

## 5. Image Build Process

### 5.1 Packer Configuration

```hcl
# releases/packer/cubeos.pkr.hcl

source "arm" "cubeos" {
  file_urls             = ["https://downloads.raspberrypi.org/raspios_lite_arm64/images/..."]
  file_checksum_type    = "sha256"
  file_checksum         = "..."
  file_target_extension = "xz"
  image_build_method    = "resize"
  image_path            = "cubeos-${var.version}-arm64.img"
  image_size            = "8G"
  image_type            = "dos"
  
  image_partitions {
    name         = "boot"
    type         = "c"
    start_sector = "2048"
    filesystem   = "fat"
    size         = "512M"
    mountpoint   = "/boot/firmware"
  }
  
  image_partitions {
    name         = "root"
    type         = "83"
    start_sector = "1050624"
    filesystem   = "ext4"
    size         = "0"
    mountpoint   = "/"
  }
  
  qemu_binary_destination_path = "/usr/bin/qemu-aarch64-static"
}

build {
  sources = ["source.arm.cubeos"]
  
  provisioner "shell" {
    scripts = [
      "scripts/01-base-setup.sh",
      "scripts/02-install-docker.sh",
      "scripts/03-install-cubeos.sh",
      "scripts/04-hardening.sh",
      "scripts/05-cleanup.sh"
    ]
  }
  
  post-processor "compress" {
    output = "cubeos-${var.version}-arm64.img.xz"
  }
  
  post-processor "checksum" {
    checksum_types = ["sha256"]
    output         = "cubeos-${var.version}-arm64.img.sha256"
  }
}
```

### 5.2 Build Scripts

```bash
#!/bin/bash
# releases/packer/scripts/03-install-cubeos.sh

# Install CubeOS components
mkdir -p /cubeos/{config,coreapps,apps,data,mounts}

# Copy coreapps
cp -r /tmp/coreapps/* /cubeos/coreapps/

# Install boot scripts
cp /tmp/scripts/cubeos-*.sh /usr/local/bin/
chmod +x /usr/local/bin/cubeos-*.sh

# Enable CubeOS service
cp /tmp/systemd/cubeos-init.service /etc/systemd/system/
systemctl enable cubeos-init.service

# Install cloud-init for Imager customization
apt-get install -y cloud-init

# Configure cloud-init datasource
cat > /etc/cloud/cloud.cfg.d/99-cubeos.cfg << 'EOF'
datasource_list: [NoCloud]
datasource:
  NoCloud:
    seedfrom: /boot/firmware/
EOF

# Pre-pull core Docker images
docker pull pihole/pihole:latest
docker pull jc21/nginx-proxy-manager:latest
docker pull registry:2
# ... more images
```

### 5.3 SHA256 Calculation

```bash
#!/bin/bash
# releases/scripts/calculate-checksums.sh

IMAGE="cubeos-2.0.0-arm64.img"
COMPRESSED="${IMAGE}.xz"

# Extract size
EXTRACT_SIZE=$(stat -f%z "$IMAGE" 2>/dev/null || stat -c%s "$IMAGE")

# Extract SHA256
EXTRACT_SHA256=$(sha256sum "$IMAGE" | cut -d' ' -f1)

# Download size
DOWNLOAD_SIZE=$(stat -f%z "$COMPRESSED" 2>/dev/null || stat -c%s "$COMPRESSED")

# Download SHA256
DOWNLOAD_SHA256=$(sha256sum "$COMPRESSED" | cut -d' ' -f1)

echo "extract_size: $EXTRACT_SIZE"
echo "extract_sha256: $EXTRACT_SHA256"
echo "image_download_size: $DOWNLOAD_SIZE"
echo "image_download_sha256: $DOWNLOAD_SHA256"
```

---

## 6. Testing

### 6.1 Local Testing with Custom Repository

```bash
# Test with custom repository URL
rpi-imager --repo https://releases.cubeos.app/rpi-imager.json

# Or for local testing
rpi-imager --repo file:///path/to/local/rpi-imager.json
```

### 6.2 Validation Checklist

- [ ] Image boots successfully on Pi 4
- [ ] Image boots successfully on Pi 5
- [ ] Imager customization (hostname) works
- [ ] Imager customization (SSH keys) works
- [ ] Imager customization (WiFi) works
- [ ] SHA256 checksums match exactly
- [ ] Image size matches manifest
- [ ] Icon displays correctly (40x40 PNG)
- [ ] Website link works
- [ ] First-boot wizard displays

---

## 7. Submission Process

### 7.1 Prerequisites

1. Working image tested on all target devices
2. Hosted JSON manifest at HTTPS URL
3. Hosted image at HTTPS URL with stable URL
4. 40x40 pixel icon image
5. Checksum files

### 7.2 Submission Steps

1. **Prepare Assets:**
   - Image file (.img.xz)
   - JSON manifest
   - Icon (40x40 PNG)
   - SHA256 checksums

2. **Host Files:**
   - Use GitHub Releases or dedicated CDN
   - Ensure stable, permanent URLs
   - Enable HTTPS

3. **Test Thoroughly:**
   - Use `rpi-imager --repo` for local testing
   - Test on all supported devices
   - Verify all checksums

4. **Submit Request:**
   - Fill out form at: https://www.raspberrypi.com/news/how-to-add-your-own-images-to-imager/
   - Provide JSON manifest URL
   - Wait for review (typically 1-2 weeks)

5. **Maintain:**
   - Keep URLs stable
   - Update manifest for new releases
   - Respond to any Foundation feedback

---

## 8. Hosting Infrastructure

### 8.1 GitHub Releases (Recommended)

```yaml
# .github/workflows/release.yml

name: Release Image

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Build Image
        run: |
          cd releases/packer
          packer build cubeos.pkr.hcl
      
      - name: Calculate Checksums
        run: |
          ./releases/scripts/calculate-checksums.sh > checksums.txt
      
      - name: Update Manifest
        run: |
          ./releases/scripts/update-manifest.sh
      
      - name: Create Release
        uses: softprops/action-gh-release@v1
        with:
          files: |
            cubeos-*.img.xz
            cubeos-*.sha256
            rpi-imager.json
```

### 8.2 CDN URLs

```
https://github.com/cubeos-app/releases/releases/download/v2.0.0/cubeos-2.0.0-arm64.img.xz
https://releases.cubeos.app/images/cubeos-2.0.0-arm64.img.xz  (redirect to GitHub)
https://releases.cubeos.app/rpi-imager.json  (manifest)
https://releases.cubeos.app/images/cubeos-icon-40x40.png  (icon)
```

---

## 9. Release Checklist

### Pre-Release

- [ ] All tests pass
- [ ] Image boots on Pi 4 and Pi 5
- [ ] Imager customization works
- [ ] Documentation updated
- [ ] Changelog updated

### Release

- [ ] Build final image
- [ ] Calculate all checksums
- [ ] Update JSON manifest with correct values
- [ ] Upload to GitHub Releases
- [ ] Verify download URLs work
- [ ] Test with `rpi-imager --repo`

### Post-Release

- [ ] Update website download links
- [ ] Announce release
- [ ] Monitor for issues
- [ ] If first listing: submit to Raspberry Pi Foundation

---

*Document Version: 1.0*  
*Last Updated: January 31, 2026*
