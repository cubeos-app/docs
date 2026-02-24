# Developer Guide

This guide is for contributors and developers who want to build CubeOS from source, understand the architecture, or create custom apps.

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Repository Structure](#repository-structure)
- [Development Setup](#development-setup)
- [Building from Source](#building-from-source)
- [Running Locally](#running-locally)
- [Testing](#testing)
- [CI/CD Pipeline](#cicd-pipeline)
- [Contributing](#contributing)
- [Creating Custom Apps](#creating-custom-apps)
- [API Overview](#api-overview)

---

## Architecture Overview

CubeOS is composed of four main components that run on a single Raspberry Pi:

```
+-----------+     +-----------+     +-----+
|  Dashboard| --> |    API    | --> | HAL |
|  (Vue 3)  |     |   (Go)   |     | (Go)|
+-----------+     +-----------+     +-----+
     :6011             :6010          :6005
                        |
                   +---------+
                   |  SQLite |
                   +---------+
                        |
                +---------------+
                | Docker Swarm  |
                | (containers)  |
                +---------------+
```

- **Dashboard**: Vue 3 single-page application. Communicates with the API via REST and WebSocket.
- **API**: Go service that handles all business logic, manages Docker Swarm, and exposes a REST API with Swagger documentation.
- **HAL (Hardware Abstraction Layer)**: Privileged Go service that interfaces with hardware -- GPIO, I2C, sensors, power management, storage, and network configuration. Runs with host network and device access.
- **Docker Swarm**: Single-node swarm that orchestrates all containerized services. Self-heals failed containers automatically.
- **SQLite**: Stores desired state, app metadata, port allocations, DNS entries, and configuration. Uses `modernc.org/sqlite` (pure Go, no CGO).

### Core Design Principles

1. **Swarm is the source of truth** for container state. The database stores desired state and metadata. `ReconcileState()` syncs them at boot.
2. **HAL boundary**: The API container never touches host services directly. All hardware and host operations go through HAL via REST calls.
3. **Offline-first**: Everything works without internet. The local Docker registry caches images for offline installation.
4. **No CGO**: All Go code compiles with `CGO_DISABLED=1`.

## Repository Structure

CubeOS is split across six repositories:

| Repository | Language | Port | Purpose |
|------------|----------|------|---------|
| `api` | Go 1.24 | 6010 | Backend REST API, orchestrator, FlowEngine workflows |
| `dashboard` | Vue 3 + Vite | 6011 | Web dashboard SPA |
| `hal` | Go | 6005 | Hardware abstraction layer (privileged) |
| `coreapps` | Docker Compose | -- | System service configurations (Pi-hole, NPM, etc.) |
| `releases` | Packer | -- | Raspberry Pi image builder |
| `docs` | Markdown | -- | Documentation (this repo) |

### API Internal Structure

```
api/
  cmd/cubeos-api/         # Entry point and adapter wiring
  internal/
    handlers/             # HTTP handlers (one file per domain)
    managers/             # Business logic (Orchestrator, SwarmManager, etc.)
    flowengine/           # Workflow engine (saga orchestrator, activities)
      workflows/          # Workflow definitions (app_install, app_remove, etc.)
      activities/         # Activity implementations
    middleware/           # HTTP middleware (auth, logging, CORS, etc.)
    models/               # Data models
    database/             # SQLite schema, migrations, queries
  docs/                   # Swagger generated docs
```

### Dashboard Structure

```
dashboard/src/
  api/                    # API client
  components/             # Reusable Vue components
  views/                  # Page-level components
  stores/                 # Pinia state management
  router/                 # Vue Router configuration
  assets/                 # Static assets (icons, styles)
```

## Development Setup

### Prerequisites

| Tool | Version | Purpose |
|------|---------|---------|
| Go | 1.24+ | API and HAL development |
| Node.js | 20+ | Dashboard development |
| npm | 10+ | Dashboard package management |
| Docker | 24+ | Running containers locally |
| Git | 2.30+ | Version control |
| golangci-lint | latest | Go linting (optional but recommended) |
| swag | latest | Swagger doc generation (optional) |

### Clone the Repositories

```bash
mkdir -p ~/cubeos && cd ~/cubeos

# Clone each repo
git clone https://github.com/cubeos-app/api.git
git clone https://github.com/cubeos-app/dashboard.git
git clone https://github.com/cubeos-app/hal.git
git clone https://github.com/cubeos-app/coreapps.git
git clone https://github.com/cubeos-app/releases.git
git clone https://github.com/cubeos-app/docs.git
```

### Environment Variables

The API reads configuration from environment variables. For local development, create a `.env` file in the `api/` directory:

```bash
CUBEOS_PORT=6010
CUBEOS_DB_PATH=./cubeos.db
CUBEOS_DATA_DIR=./data
JWT_SECRET=dev-secret-change-me
HAL_URL=http://localhost:6005
CORS_ALLOWED_ORIGINS=http://localhost:6011
```

Source it before running:

```bash
set -a && source .env && set +a
```

## Building from Source

### API

```bash
cd api

# Build for current platform
make build                # Output: build/cubeos

# Cross-compile for Raspberry Pi
make build-arm64          # Output: build/cubeos-arm64

# Other useful commands
make fmt                  # Format code with gofmt
make lint                 # Run golangci-lint
make tidy                 # Run go mod tidy
```

The API must compile with `CGO_ENABLED=0`. Never use `mattn/go-sqlite3`.

### Dashboard

```bash
cd dashboard

# Install dependencies
npm install

# Build for production
npm run build             # Output: dist/
```

### HAL

```bash
cd hal

# Build for current platform
go build -o build/hal ./cmd/hal

# Cross-compile for ARM64
GOOS=linux GOARCH=arm64 CGO_ENABLED=0 go build -o build/hal-arm64 ./cmd/hal
```

### Full Image (Packer)

Building a complete CubeOS image requires Packer and ARM64 emulation:

```bash
cd releases
packer build cubeos.pkr.hcl
```

This produces a `.img` file ready to flash to an SD card. See the `releases` repository for detailed build instructions.

## Running Locally

### API

```bash
cd api
make run                  # Runs: go run ./cmd/cubeos-api
```

The API starts on port 6010. Swagger docs are available at `http://localhost:6010/swagger/index.html`.

### Dashboard

```bash
cd dashboard
npm run dev               # Dev server with hot reload on port 6011
```

The dev server proxies API requests to `http://localhost:6010`.

### Preview Dashboard Build

```bash
cd dashboard
npm run build && npm run preview
```

## Testing

### API Tests

```bash
cd api

# Run all tests
make test                 # go test -v ./...

# Run handler tests only
make test-handlers        # go test -v ./internal/handlers/...

# Run a specific test
go test -v -run TestFunctionName ./internal/handlers/

# Verify routes match Swagger docs
make verify-routes
```

Tests use table-driven patterns. Handlers are tested with `httptest` against mock managers.

### Dashboard Tests

```bash
cd dashboard
npm run test              # Run unit tests
npm run test:e2e          # Run end-to-end tests (if configured)
```

### Testing on a Raspberry Pi

For integration testing, deploy to a Pi:

1. Push to the `main` branch.
2. The CI/CD pipeline builds and deploys automatically.
3. SSH into the Pi: `ssh cubeos@cubeos.cube`
4. Check service status: `docker service ls`
5. View logs: `docker service logs cubeos-api`

## CI/CD Pipeline

Each repository has a GitLab CI/CD pipeline that triggers on pushes to `main`:

1. **Build**: Compiles the code (Go build or npm build).
2. **Test**: Runs the test suite.
3. **Lint**: Checks code style and formatting.
4. **Deploy**: Builds a Docker image, pushes to the Pi's local registry, and updates the Swarm service.

**Never manually pull or restart services on the Pi.** Push to `main` and the pipeline handles everything.

### Checking Pipeline Status

```bash
# Check latest pipeline status
curl -s --header "PRIVATE-TOKEN: $GITLAB_TOKEN" \
  "https://gitlab.nuclearlighters.net/api/v4/projects/PROJECT_ID/pipelines/latest" | jq '.status'
```

Project IDs: api=13, dashboard=14, docs=16, coreapps=19, releases=20, hal=22.

## Contributing

### Workflow

1. Fork the relevant repository.
2. Create a feature branch from `main`: `git checkout -b feat/my-feature`
3. Make your changes.
4. Run formatters and linters:
   - Go: `make fmt && make lint`
   - Dashboard: `npm run lint`
5. Run tests: `make test` or `npm run test`
6. Commit using conventional commits:
   - `feat:` -- New feature
   - `fix:` -- Bug fix
   - `refactor:` -- Code restructuring
   - `docs:` -- Documentation changes
   - `test:` -- Test changes
   - `chore:` -- Build/tooling changes
7. Push and open a pull request.

### Code Style

**Go (API and HAL)**:
- Follow [Effective Go](https://go.dev/doc/effective_go) guidelines.
- Router: chi v5 (not gin, not mux).
- Always handle errors. Never use `_` to discard errors.
- Use `context.Context` for cancellation and timeouts.
- All handlers must have complete Swagger annotations (`@Summary`, `@Description`, `@Tags`, `@Param`, `@Success`, `@Failure`, `@Router`).
- No hardcoded URLs, ports, IPs, or environment-specific values. Use `os.Getenv()` with defaults.
- Run `gofmt` before every commit.

**Vue (Dashboard)**:
- Vue 3 Composition API with `<script setup>`. Never use Options API.
- Pinia for state management.
- Tailwind CSS utility classes only. No custom CSS files.
- Monochrome SVG icons only. No emojis in the UI.
- All views must be responsive (phone and desktop).

## Creating Custom Apps

You can create and install custom Docker apps on CubeOS. Each app is a Docker Compose file deployed as a Swarm stack.

### App Structure

```
/cubeos/apps/my-app/
  docker-compose.yml      # Required: Swarm-compatible compose file
  .env                    # Optional: environment variables
```

### Compose File Requirements

```yaml
version: "3.8"

services:
  my-app:
    image: my-app-image:latest
    ports:
      - "6100:8080"         # Must use a port in the 6100-6999 range
    volumes:
      - my-app-data:/data
    deploy:
      replicas: 1
      restart_policy:
        condition: on-failure
        delay: 5s
        max_attempts: 3

volumes:
  my-app-data:
```

### Port Allocation

All apps must use a port in the `6100-6999` range. When installing through the dashboard or API, ports are allocated automatically. For manual installations, check which ports are in use:

```bash
curl -s http://api.cubeos.cube/api/v1/ports \
  -H "Authorization: Bearer YOUR_TOKEN" | jq
```

### FQDN Convention

Each app gets a subdomain under `cubeos.cube`. The subdomain matches the app name:
- App name: `my-app` -> FQDN: `my-app.cubeos.cube`
- DNS and reverse proxy entries are created automatically on install.

### Installing a Custom App via API

```bash
curl -X POST http://api.cubeos.cube/api/v1/apps \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "my-app",
    "image": "my-app-image:latest",
    "port": 6100,
    "description": "My custom application"
  }'
```

The API returns `202 Accepted` and the installation runs as an async workflow. Monitor progress in the dashboard or via the workflows API.

## API Overview

The CubeOS API is a REST API running on port 6010. Full interactive documentation is available via Swagger.

### Swagger Documentation

- On the Pi: [http://api.cubeos.cube/swagger/index.html](http://api.cubeos.cube/swagger/index.html)
- Local development: [http://localhost:6010/swagger/index.html](http://localhost:6010/swagger/index.html)

### Authentication

All endpoints except `/api/v1/health` and `/api/v1/auth/login` require a JWT token.

```bash
# Get a token
TOKEN=$(curl -s -X POST http://api.cubeos.cube/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username": "admin", "password": "YOUR_PASSWORD"}' | jq -r '.token')

# Use the token
curl -s http://api.cubeos.cube/api/v1/apps \
  -H "Authorization: Bearer $TOKEN"
```

Tokens expire after 24 hours.

### Key Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/v1/auth/login` | Authenticate and get JWT token |
| `GET` | `/api/v1/health` | Health check (no auth) |
| `GET` | `/api/v1/apps` | List all apps |
| `POST` | `/api/v1/apps` | Install an app (async, returns 202) |
| `DELETE` | `/api/v1/apps/{name}` | Uninstall an app |
| `POST` | `/api/v1/apps/{name}/start` | Start an app |
| `POST` | `/api/v1/apps/{name}/stop` | Stop an app |
| `GET` | `/api/v1/system/info` | System information |
| `GET` | `/api/v1/system/stats` | CPU, memory, disk, temperature |
| `GET` | `/api/v1/network/status` | Current network configuration |
| `POST` | `/api/v1/network/mode` | Change network mode |
| `GET` | `/api/v1/workflows` | List workflow runs |
| `GET` | `/api/v1/workflows/{id}` | Get workflow run details |

### Middleware Stack

Requests pass through middleware in this order:

1. Logger
2. Recovery (panic handler)
3. RealIP
4. RequestID
5. CORS
6. Timeout (60 seconds)
7. MaxBodySize (10 MB)
8. SetupRequired (redirects to wizard if not set up)
9. JWTAuth (validates token)

Refer to the Swagger documentation for complete endpoint specifications, request/response schemas, and error codes.
