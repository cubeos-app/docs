# CubeOS Production Hardening

**Document:** 09_PRODUCTION_HARDENING.md  
**Version:** 1.0  
**Last Updated:** January 31, 2026

---

## 1. Overview

This document covers security hardening and reliability configurations for production CubeOS deployments.

---

## 2. Kernel Hardening

### 2.1 Sysctl Configuration

```bash
# /etc/sysctl.d/99-cubeos-security.conf

# Network hardening
net.ipv4.tcp_syncookies = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.log_martians = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1

# IPv6 hardening (if not using IPv6)
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0

# Kernel security
kernel.sysrq = 0
kernel.randomize_va_space = 2
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
fs.suid_dumpable = 0

# Network performance
net.core.somaxconn = 1024
net.ipv4.tcp_max_syn_backlog = 2048
```

Apply with: `sysctl --system`

### 2.2 AppArmor

Enable AppArmor (available in Raspberry Pi kernels 5.4.72+):

```bash
# Add to /boot/firmware/cmdline.txt
apparmor=1 security=apparmor

# Install packages
apt install apparmor apparmor-profiles apparmor-utils

# Verify
aa-status
```

---

## 3. SSH Hardening

### 3.1 SSH Server Configuration

```bash
# /etc/ssh/sshd_config.d/99-cubeos-hardening.conf

# Disable root login
PermitRootLogin no

# Key-only authentication
PasswordAuthentication no
PubkeyAuthentication yes
AuthenticationMethods publickey

# Limit attempts
MaxAuthTries 3
MaxSessions 5
LoginGraceTime 30

# Disable unnecessary features
X11Forwarding no
AllowTcpForwarding no
AllowAgentForwarding no
PermitTunnel no

# Modern algorithms only
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org
HostKeyAlgorithms ssh-ed25519,rsa-sha2-512,rsa-sha2-256

# Idle timeout
ClientAliveInterval 300
ClientAliveCountMax 2
```

### 3.2 SSH Host Key Regeneration

```bash
# Remove weak keys
rm /etc/ssh/ssh_host_dsa_key*
rm /etc/ssh/ssh_host_ecdsa_key*

# Generate strong Ed25519 key
ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ""

# Remove weak Diffie-Hellman moduli
awk '$5 >= 3071' /etc/ssh/moduli > /etc/ssh/moduli.safe
mv /etc/ssh/moduli.safe /etc/ssh/moduli

# Restart SSH
systemctl restart sshd
```

---

## 4. Watchdog Timer

### 4.1 Hardware Watchdog Configuration

The Raspberry Pi has a built-in hardware watchdog with a **15-second maximum timeout**.

```bash
# /boot/config.txt
dtparam=watchdog=on

# /etc/systemd/system.conf.d/99-watchdog.conf
[Manager]
RuntimeWatchdogSec=15
RebootWatchdogSec=10min
```

### 4.2 Verification

```bash
# Check watchdog is active
journalctl | grep -i 'hardware watchdog'
# Should show: "Set hardware watchdog to 15s"

# Check device exists
ls -la /dev/watchdog*
```

---

## 5. Fail2ban

### 5.1 Installation and Configuration

```bash
apt install fail2ban
```

```ini
# /etc/fail2ban/jail.d/cubeos.conf

[DEFAULT]
bantime = 86400
findtime = 600
maxretry = 3
backend = systemd

[sshd]
enabled = true
port = ssh
maxretry = 3

[nginx-http-auth]
enabled = true
port = http,https
logpath = /var/log/nginx/error.log

[nginx-limit-req]
enabled = true
port = http,https
logpath = /var/log/nginx/error.log
```

### 5.2 Service Management

```bash
systemctl enable fail2ban
systemctl start fail2ban

# Check status
fail2ban-client status
fail2ban-client status sshd
```

---

## 6. SD Card Longevity

### 6.1 Journald Configuration (Volatile Logs)

```ini
# /etc/systemd/journald.conf.d/99-cubeos.conf

[Journal]
Storage=volatile
SystemMaxUse=20M
RuntimeMaxUse=30M
MaxRetentionSec=1week
Compress=yes
ForwardToSyslog=no
```

### 6.2 tmpfs Mounts

```bash
# /etc/fstab additions

tmpfs  /tmp              tmpfs  defaults,noatime,nosuid,nodev,size=100m  0  0
tmpfs  /var/tmp          tmpfs  defaults,noatime,nosuid,nodev,size=50m   0  0
tmpfs  /var/log          tmpfs  defaults,noatime,nosuid,nodev,size=50m   0  0
tmpfs  /var/lib/sudo     tmpfs  defaults,noatime,nosuid,nodev,size=1m    0  0
```

### 6.3 Read-Only Root Filesystem (Optional)

For maximum SD card protection, CubeOS can be configured with a read-only root:

```bash
# /usr/local/bin/cubeos-enable-readonly.sh

#!/bin/bash
# Enable read-only root with overlay

# Add to cmdline.txt
# fsck.mode=skip noswap ro

# Mount root as read-only
mount -o remount,ro /
mount -o remount,ro /boot/firmware

# Convenience aliases (add to /etc/bash.bashrc)
echo 'alias ro="sudo mount -o remount,ro / ; sudo mount -o remount,ro /boot/firmware"' >> /etc/bash.bashrc
echo 'alias rw="sudo mount -o remount,rw / ; sudo mount -o remount,rw /boot/firmware"' >> /etc/bash.bashrc
```

**Note:** When read-only mode is enabled, use `rw` to temporarily enable writes for configuration changes.

---

## 7. Docker Hardening

### 7.1 Docker Daemon Configuration

```json
// /etc/docker/daemon.json
{
    "storage-driver": "overlay2",
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "3"
    },
    "insecure-registries": ["localhost:5000"],
    "registry-mirrors": ["http://localhost:5000"],
    "live-restore": true,
    "userland-proxy": false,
    "no-new-privileges": true
}
```

### 7.2 Docker Swarm Optimizations

```bash
# Set task history limit to reduce memory
docker swarm update --task-history-limit 1

# Initialize with optimized settings
docker swarm init \
    --advertise-addr 10.42.24.1 \
    --task-history-limit 1
```

---

## 8. Firewall Configuration

### 8.1 Base iptables Rules

```bash
#!/bin/bash
# /usr/local/bin/cubeos-firewall.sh

# Flush existing rules
iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X

# Default policies
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# Allow loopback
iptables -A INPUT -i lo -j ACCEPT

# Allow established connections
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow local network (CubeOS subnet)
iptables -A INPUT -s 10.42.24.0/24 -j ACCEPT

# Allow Docker bridge
iptables -A INPUT -i docker0 -j ACCEPT

# Allow DHCP
iptables -A INPUT -p udp --dport 67 -j ACCEPT

# Allow DNS
iptables -A INPUT -p udp --dport 53 -j ACCEPT
iptables -A INPUT -p tcp --dport 53 -j ACCEPT

# Save rules
iptables-save > /etc/iptables/rules.v4
```

### 8.2 Network Mode Firewall Rules

See `02_ARCHITECTURE.md` Section 6.3 for network-mode-specific firewall rules.

---

## 9. Automatic Security Updates

### 9.1 Unattended Upgrades

```bash
apt install unattended-upgrades

# /etc/apt/apt.conf.d/50unattended-upgrades
Unattended-Upgrade::Origins-Pattern {
    "origin=Debian,codename=${distro_codename},label=Debian-Security";
    "origin=Raspbian,codename=${distro_codename},label=Raspbian-Security";
};

Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Remove-New-Unused-Dependencies "true";
```

### 9.2 Enable Automatic Updates

```bash
# /etc/apt/apt.conf.d/20auto-upgrades
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
APT::Periodic::AutocleanInterval "7";
```

---

## 10. Hardening Checklist

### Pre-Deployment

- [ ] SSH key-only authentication configured
- [ ] Root login disabled
- [ ] Fail2ban installed and configured
- [ ] Sysctl hardening applied
- [ ] Watchdog timer enabled
- [ ] Journald configured for volatile storage
- [ ] Docker daemon optimized
- [ ] Default passwords changed

### Post-Deployment

- [ ] Run SSH audit: `ssh-audit localhost`
- [ ] Verify watchdog: `journalctl | grep watchdog`
- [ ] Check fail2ban: `fail2ban-client status`
- [ ] Verify firewall: `iptables -L -n`
- [ ] Test auto-restart: kill a service, verify recovery

### Optional (High Security)

- [ ] Enable AppArmor profiles
- [ ] Enable read-only root filesystem
- [ ] Configure automatic security updates
- [ ] Set up external logging (syslog server)

---

## 11. Security Configuration Files

All hardening configuration files are installed during first boot from:

```
/cubeos/config/hardening/
├── sysctl.d/
│   └── 99-cubeos-security.conf
├── ssh/
│   └── 99-cubeos-hardening.conf
├── fail2ban/
│   └── cubeos.conf
├── systemd/
│   ├── journald.conf.d/
│   │   └── 99-cubeos.conf
│   └── system.conf.d/
│       └── 99-watchdog.conf
└── docker/
    └── daemon.json
```

---

*Document Version: 1.0*  
*Last Updated: January 31, 2026*
