# Frequently Asked Questions

## Access & Login

### How do I access the CubeOS dashboard?

Connect to the CubeOS WiFi network (named CubeOS-XXXX), then open http://cubeos.cube in your browser. Alternatively, use http://192.168.42.1.

### What are the default login credentials?

Username: `admin`  
Password: `cubeos`

Change your password after first login in Settings → Security.

### How do I access Pi-hole?

Go to http://pihole.cubeos.cube/admin and login with password `cubeos`.

### How do I access Nginx Proxy Manager?

Go to http://npm.cubeos.cube and login with:
- Email: cubeos@cubeos.app
- Password: cubeos123

### What is the WiFi password?

The default password is printed on your device label. If using default: `cubeos`

### How do I change the WiFi password?

Go to Dashboard → Network → WiFi, enter a new password, and click Save. You'll need to reconnect with the new password.

## Services & Apps

### How do I add a new app?

Use Dockge at http://dockge.cubeos.cube:
1. Click "+ Compose"
2. Paste your docker-compose.yml
3. Click "Deploy"

### How do I restart a service?

Go to Dashboard → Services, click on the service, then click "Restart".

### How do I view service logs?

1. Dashboard → Services → click service → Logs
2. Or use http://logs.cubeos.cube for all container logs
3. Or run: `docker logs <container_name>`

### Why is a service showing as offline?

Check if the container is running:
1. Go to http://logs.cubeos.cube to see errors
2. Or run `docker ps` to see container status
3. Try restarting: Dashboard → Services → Restart

### How do I stop a service?

Dashboard → Services → click service → Stop button.

## System & Hardware

### How do I check system temperature?

The dashboard shows CPU temperature on the main page. Or run: `vcgencmd measure_temp`

### How do I check available storage?

Dashboard shows disk usage. Or run: `df -h`

### How do I reboot CubeOS?

Dashboard → Settings → System → Reboot. Or run: `sudo reboot`

### How do I shut down CubeOS safely?

Dashboard → Settings → System → Shutdown. Or run: `sudo shutdown -h now`

### Does CubeOS have a battery backup?

If you have a UPS HAT installed, battery status appears in the dashboard. CubeOS supports the PiSugar and similar UPS boards.

## Network & Connectivity

### How do I connect CubeOS to the internet?

Connect an Ethernet cable from your router to the Pi. CubeOS will share this internet connection with WiFi clients.

### Can I use CubeOS without internet?

Yes! CubeOS works offline. Some features like app updates won't work, but core functionality remains available.

### How do I block ads on all devices?

All devices connected to CubeOS WiFi automatically use Pi-hole for DNS, which blocks ads. No configuration needed.

### How do I whitelist a website in Pi-hole?

Go to http://pihole.cubeos.cube/admin → Domains → Add domain → "Add to Whitelist"

### How do I see who's connected to WiFi?

Dashboard → Network → Clients shows all connected devices.

## AI Assistant

### What is "Ask CubeOS"?

Ask CubeOS is an AI assistant powered by Ollama running locally on your device. It can answer questions about CubeOS and help with troubleshooting.

### Is the AI assistant connected to the internet?

No. The AI runs completely locally on your Raspberry Pi. Your conversations are private and never leave your device.

### The AI assistant shows "Offline" - how do I fix it?

1. Check if Ollama is running: `docker ps | grep ollama`
2. If not running, start it: `docker start cubeos-ollama`
3. The model may need to be downloaded - this happens automatically on first use

## Troubleshooting

### I forgot my password - how do I reset it?

SSH into the Pi and run:
```bash
docker exec -it cubeos-api sh -c "sqlite3 /app/data/cubeos.db \"UPDATE users SET password_hash='...' WHERE username='admin'\""
```
Or reflash the SD card for a fresh start.

### The dashboard won't load

1. Make sure you're connected to CubeOS WiFi
2. Try http://192.168.42.1 instead of http://cubeos.cube
3. Clear your browser cache
4. Check if API is running: `docker ps | grep api`

### Services are slow or unresponsive

1. Check CPU/memory: Dashboard shows these stats
2. You may be running too many services
3. Consider using an SSD instead of SD card
4. Pi 5 performs better than Pi 4

### WiFi keeps disconnecting

1. Move closer to the Pi
2. Try changing WiFi channel in Network settings
3. Check for interference from other devices
4. Restart hostapd: `systemctl restart hostapd`

### Can't access .cubeos.cube domains

1. Make sure you're on CubeOS WiFi (not your home network)
2. DNS is provided by Pi-hole - check it's running
3. Try the IP directly: http://192.168.42.1

## Backup & Recovery

### How do I backup my settings?

Dashboard → Settings → Backup → Create Backup

### How do I restore from backup?

Dashboard → Settings → Backup → select backup → Restore

### Where are backups stored?

Backups are stored in `/cubeos/backups/` on the device.
