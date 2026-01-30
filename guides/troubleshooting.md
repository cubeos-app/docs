# Troubleshooting Guide

## Quick Diagnostics

Run these commands to quickly diagnose issues:

```bash
# System health
vcgencmd measure_temp          # CPU temperature
free -h                         # Memory usage
df -h                          # Disk space
uptime                         # System uptime and load

# Docker services
docker ps                      # Running containers
docker ps -a                   # All containers (including stopped)
docker logs <container>        # Container logs

# Network
ip addr                        # Network interfaces
ping -c 3 8.8.8.8             # Internet connectivity
nslookup cubeos.cube          # DNS resolution
```

## Common Issues

### Dashboard Not Loading

**Symptoms:** Browser shows "Cannot connect" or times out

**Solutions:**

1. **Verify you're on CubeOS WiFi**
   - Check your WiFi connection
   - Should be connected to "CubeOS-XXXX"

2. **Try IP address directly**
   - Go to http://192.168.42.1
   - If this works, DNS issue (see below)

3. **Check API container**
   ```bash
   docker ps | grep api
   docker logs cubeos-api --tail 50
   docker restart cubeos-api
   ```

4. **Check dashboard container**
   ```bash
   docker ps | grep dashboard
   docker restart cubeos-dashboard
   ```

### DNS Not Working

**Symptoms:** Can reach 192.168.42.1 but not cubeos.cube

**Solutions:**

1. **Check Pi-hole is running**
   ```bash
   docker ps | grep pihole
   docker restart cubeos-pihole
   ```

2. **Test DNS directly**
   ```bash
   nslookup cubeos.cube 192.168.42.1
   ```

3. **Flush DNS cache on your device**
   - Windows: `ipconfig /flushdns`
   - Mac: `sudo dscacheutil -flushcache`
   - Linux: `systemd-resolve --flush-caches`

### No Internet on WiFi Clients

**Symptoms:** Connected to CubeOS WiFi but can't reach internet

**Solutions:**

1. **Check Pi has internet**
   ```bash
   ping -c 3 8.8.8.8
   curl -I https://google.com
   ```

2. **Check Ethernet connection**
   ```bash
   ip link show eth0
   # Should show "state UP"
   ```

3. **Check IP forwarding**
   ```bash
   cat /proc/sys/net/ipv4/ip_forward
   # Should be 1
   # If 0, enable it:
   echo 1 > /proc/sys/net/ipv4/ip_forward
   ```

4. **Check NAT rules**
   ```bash
   iptables -t nat -L -n | grep MASQUERADE
   # Should show masquerade rule
   ```

### WiFi AP Not Working

**Symptoms:** CubeOS WiFi network not visible

**Solutions:**

1. **Check hostapd status**
   ```bash
   systemctl status hostapd
   journalctl -u hostapd -n 50
   ```

2. **Check WiFi interface**
   ```bash
   ip link show wlan0
   iw dev wlan0 info
   ```

3. **Restart WiFi AP**
   ```bash
   systemctl restart hostapd
   ```

4. **Check for hardware issues**
   ```bash
   dmesg | grep -i wifi
   dmesg | grep -i wlan
   ```

### Container Won't Start

**Symptoms:** Service shows as stopped, restart fails

**Solutions:**

1. **Check logs for errors**
   ```bash
   docker logs <container_name> --tail 100
   ```

2. **Check available resources**
   ```bash
   free -h          # Memory
   df -h            # Disk space
   docker system df # Docker disk usage
   ```

3. **Check port conflicts**
   ```bash
   ss -tlnp | grep <port>
   ```

4. **Remove and recreate container**
   ```bash
   docker compose -f /path/to/compose.yml up -d <service>
   ```

### System Running Slow

**Symptoms:** Dashboard sluggish, services unresponsive

**Solutions:**

1. **Check CPU temperature** (throttling occurs at 80°C+)
   ```bash
   vcgencmd measure_temp
   ```

2. **Check resource usage**
   ```bash
   htop
   docker stats
   ```

3. **Identify heavy containers**
   ```bash
   docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"
   ```

4. **Free up memory**
   ```bash
   docker system prune -f
   sync && echo 3 > /proc/sys/vm/drop_caches
   ```

5. **Consider stopping unused services**

### Password Reset

**Problem:** Forgot admin password

**Solution:**

1. **SSH into the Pi** (if SSH is enabled)
   ```bash
   ssh root@192.168.42.1
   ```

2. **Reset password in database**
   ```bash
   # Generate new hash for password "cubeos"
   docker exec cubeos-api sh -c "echo 'cubeos' | htpasswd -niBC 10 admin"
   
   # Or reset to default
   sqlite3 /cubeos/data/api/cubeos.db "UPDATE users SET password_hash='\$2a\$10\$...' WHERE username='admin'"
   ```

3. **Restart API**
   ```bash
   docker restart cubeos-api
   ```

### Out of Disk Space

**Symptoms:** Services failing, "no space left on device" errors

**Solutions:**

1. **Check disk usage**
   ```bash
   df -h
   du -sh /var/lib/docker/*
   ```

2. **Clean Docker resources**
   ```bash
   docker system prune -a -f
   docker volume prune -f
   ```

3. **Remove old logs**
   ```bash
   truncate -s 0 /var/log/*.log
   journalctl --vacuum-time=1d
   ```

4. **Check for large files**
   ```bash
   find / -type f -size +100M 2>/dev/null
   ```

## Getting Help

If these solutions don't work:

1. **Check logs** at http://logs.cubeos.cube
2. **Search issues** at https://github.com/cubeos-app/cubeos/issues
3. **Ask the AI assistant** - "Ask CubeOS" in the dashboard
4. **Create an issue** with:
   - CubeOS version
   - Pi model
   - Steps to reproduce
   - Relevant logs
