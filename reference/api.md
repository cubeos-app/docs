# CubeOS API Reference

The CubeOS API provides programmatic access to all system functions.

## Base URL

```
http://api.cubeos.cube/api/v1
http://192.168.42.1:9009/api/v1
```

## Authentication

All endpoints except `/auth/login` require a JWT token.

### Login

```http
POST /api/v1/auth/login
Content-Type: application/json

{
  "username": "admin",
  "password": "cubeos"
}
```

Response:
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "token_type": "bearer",
  "expires_in": 86400,
  "user": {
    "username": "admin",
    "role": "admin"
  }
}
```

### Using the Token

Include in all requests:
```http
Authorization: Bearer <access_token>
```

## Endpoints

### System

#### Get System Info
```http
GET /api/v1/system/info
```

Returns hostname, model, serial number, OS version.

#### Get System Stats
```http
GET /api/v1/system/stats
```

Returns CPU usage, memory usage, disk usage, temperature.

#### Reboot
```http
POST /api/v1/system/reboot
```

#### Shutdown
```http
POST /api/v1/system/shutdown
```

### Services (Docker)

#### List Services
```http
GET /api/v1/services
```

Returns all Docker containers with status.

#### Get Service Details
```http
GET /api/v1/services/{name}
```

#### Start Service
```http
POST /api/v1/services/{name}/start
```

#### Stop Service
```http
POST /api/v1/services/{name}/stop
```

#### Restart Service
```http
POST /api/v1/services/{name}/restart
```

#### Get Service Logs
```http
GET /api/v1/services/{name}/logs?lines=100
```

### Network

#### Get Network Interfaces
```http
GET /api/v1/network/interfaces
```

#### Get WiFi AP Status
```http
GET /api/v1/network/wifi/ap/status
```

#### Update WiFi Config
```http
PUT /api/v1/network/wifi/ap/config
Content-Type: application/json

{
  "ssid": "MyCubeOS",
  "password": "newpassword123",
  "channel": 6
}
```

#### Get Connected Clients
```http
GET /api/v1/clients
```

#### Get DHCP Leases
```http
GET /api/v1/network/dhcp/leases
```

### Power/UPS

#### Get Power Status
```http
GET /api/v1/power/status
```

Returns battery percentage, charging status, voltage (if UPS installed).

### Chat (AI Assistant)

#### Send Chat Message
```http
POST /api/v1/chat
Content-Type: application/json

{
  "message": "How do I access Pi-hole?",
  "history": []
}
```

#### Get Chat Status
```http
GET /api/v1/chat/status
```

Returns Ollama availability and model status.

### Backups

#### List Backups
```http
GET /api/v1/backup
```

#### Create Backup
```http
POST /api/v1/backup/create
Content-Type: application/json

{
  "name": "my-backup",
  "include_docker_volumes": true
}
```

#### Restore Backup
```http
POST /api/v1/backup/restore/{backup_id}
```

## Error Responses

All errors return:
```json
{
  "error": "Error message",
  "code": 400
}
```

Common HTTP status codes:
- `400` - Bad request (invalid parameters)
- `401` - Unauthorized (invalid/expired token)
- `403` - Forbidden (insufficient permissions)
- `404` - Not found
- `500` - Internal server error

## WebSocket Endpoints

### Real-time Stats
```
ws://api.cubeos.cube/ws/stats
```

Streams system stats every 2 seconds.

### Container Logs
```
ws://api.cubeos.cube/api/monitoring/ws
```

Real-time monitoring data.

## OpenAPI Spec

Full OpenAPI 3.0 specification available at:
```
http://api.cubeos.cube/api/v1/openapi.yaml
```

Interactive documentation (Swagger UI):
```
http://api.cubeos.cube/api/v1/docs
```

## Rate Limits

- No rate limits for local network access
- Reasonable use expected (avoid polling < 1 second)

## Examples

### cURL

```bash
# Login
TOKEN=$(curl -s -X POST http://192.168.42.1:9009/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"cubeos"}' | jq -r '.access_token')

# Get system stats
curl -s http://192.168.42.1:9009/api/v1/system/stats \
  -H "Authorization: Bearer $TOKEN" | jq

# Restart a service
curl -X POST http://192.168.42.1:9009/api/v1/services/cubeos-pihole/restart \
  -H "Authorization: Bearer $TOKEN"
```

### Python

```python
import requests

# Login
resp = requests.post('http://192.168.42.1:9009/api/v1/auth/login',
    json={'username': 'admin', 'password': 'cubeos'})
token = resp.json()['access_token']

# Get stats
headers = {'Authorization': f'Bearer {token}'}
stats = requests.get('http://192.168.42.1:9009/api/v1/system/stats',
    headers=headers).json()
print(stats)
```

### JavaScript

```javascript
const login = await fetch('http://192.168.42.1:9009/api/v1/auth/login', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ username: 'admin', password: 'cubeos' })
});
const { access_token } = await login.json();

const stats = await fetch('http://192.168.42.1:9009/api/v1/system/stats', {
  headers: { 'Authorization': `Bearer ${access_token}` }
}).then(r => r.json());
```
