# CubeOS Local Registry Design

**Document:** 08_LOCAL_REGISTRY.md  
**Version:** 2.0  
**Last Updated:** January 31, 2026

---

## 1. Overview

CubeOS is an **offline-first** operating system. Users must be able to install apps without internet access. This requires a local Docker registry that:

1. Caches images from upstream registries (ghcr.io, docker.io)
2. Stores curated offline app images
3. Serves as the primary pull source for CubeOS

---

## 2. Architecture

### 2.1 High-Level Design

```
                          INTERNET
                              |
                              v
              +---------------+---------------+
              |                               |
              v                               v
        ghcr.io                          docker.io
              |                               |
              +---------------+---------------+
                              |
                              v
                  +---------------------+
                  |   PULL-THROUGH      |
                  |   PROXY MODE        |
                  +---------------------+
                              |
                              v
+----------------------------------------------------------+
|                    CUBEOS LOCAL REGISTRY                  |
|                     (localhost:5000)                      |
+----------------------------------------------------------+
|  +-----------------+  +-----------------+                 |
|  | CURATED IMAGES  |  | CACHED IMAGES   |                 |
|  | (pre-loaded)    |  | (on-demand)     |                 |
|  |                 |  |                 |                 |
|  | - filebrowser   |  | - user apps     |                 |
|  | - jellyfin      |  | - updated       |                 |
|  | - 20+ apps      |  |   versions      |                 |
|  +-----------------+  +-----------------+                 |
+----------------------------------------------------------+
                              |
                              v
              +-------------------------------+
              |      CUBEOS SERVICES          |
              |   (always pull from local)    |
              +-------------------------------+
```

### 2.2 Registry Compose File

```yaml
# /cubeos/coreapps/registry/appconfig/docker-compose.yml

services:
  registry:
    image: registry:2
    container_name: cubeos-registry
    restart: unless-stopped
    ports:
      - "5000:5000"
    volumes:
      - /cubeos/data/registry:/var/lib/registry
      - ./config.yml:/etc/docker/registry/config.yml:ro
    environment:
      - REGISTRY_HTTP_ADDR=0.0.0.0:5000
      - REGISTRY_STORAGE_DELETE_ENABLED=true
    deploy:
      resources:
        limits:
          memory: 256M
    healthcheck:
      test: ["CMD", "wget", "-q", "--spider", "http://localhost:5000/v2/"]
      interval: 30s
      timeout: 5s
      retries: 3
    labels:
      - "cubeos.type=system"
      - "cubeos.port=5000"
```

### 2.3 Registry Configuration

```yaml
# /cubeos/coreapps/registry/appconfig/config.yml

version: 0.1
log:
  level: info
storage:
  filesystem:
    rootdirectory: /var/lib/registry
  delete:
    enabled: true
  maintenance:
    uploadpurging:
      enabled: true
      age: 168h  # 7 days
      interval: 24h
http:
  addr: :5000
  headers:
    X-Content-Type-Options: [nosniff]
proxy:
  remoteurl: https://registry-1.docker.io
```

---

## 3. Curated App List

### 3.1 Pre-loaded Images (Offline Bundle)

These images ship with CubeOS or are downloaded during setup:

| App | Image | Size | Category |
|-----|-------|------|----------|
| filebrowser | filebrowser/filebrowser | ~30MB | Files |
| jellyfin | jellyfin/jellyfin | ~500MB | Media |
| homeassistant | homeassistant/home-assistant | ~1GB | Automation |
| nextcloud | nextcloud | ~800MB | Cloud |
| vaultwarden | vaultwarden/server | ~100MB | Security |
| uptime-kuma | louislam/uptime-kuma | ~200MB | Monitoring |
| freshrss | freshrss/freshrss | ~100MB | News |
| photoprism | photoprism/photoprism | ~400MB | Photos |
| syncthing | syncthing/syncthing | ~50MB | Sync |
| code-server | codercom/code-server | ~400MB | Dev |
| gitea | gitea/gitea | ~100MB | Dev |
| wikijs | requarks/wiki | ~400MB | Docs |
| hedgedoc | quay.io/hedgedoc/hedgedoc | ~300MB | Docs |
| mealie | hkotel/mealie | ~200MB | Recipes |
| paperless-ngx | paperlessngx/paperless-ngx | ~300MB | Documents |
| audiobookshelf | advplyr/audiobookshelf | ~200MB | Media |
| calibre-web | linuxserver/calibre-web | ~200MB | Books |
| navidrome | deluan/navidrome | ~50MB | Music |
| homepage | ghcr.io/gethomepage/homepage | ~150MB | Dashboard |
| immich | ghcr.io/immich-app/immich-server | ~500MB | Photos |

**Total estimated size: ~5-6GB**

### 3.2 Pre-loading Script

```bash
#!/bin/bash
# scripts/preload-images.sh

REGISTRY="localhost:5000"
CURATED_APPS=(
    "filebrowser/filebrowser:latest"
    "jellyfin/jellyfin:latest"
    "homeassistant/home-assistant:latest"
    "nextcloud:latest"
    "vaultwarden/server:latest"
    "louislam/uptime-kuma:latest"
    "freshrss/freshrss:latest"
    "syncthing/syncthing:latest"
    "gitea/gitea:latest"
    "requarks/wiki:latest"
    "hkotel/mealie:latest"
    "paperlessngx/paperless-ngx:latest"
    "advplyr/audiobookshelf:latest"
    "linuxserver/calibre-web:latest"
    "deluan/navidrome:latest"
    "ghcr.io/gethomepage/homepage:latest"
)

for image in "${CURATED_APPS[@]}"; do
    echo "Pre-loading: $image"
    docker pull "$image"
    
    # Tag for local registry
    local_tag="$REGISTRY/${image#*/}"
    docker tag "$image" "$local_tag"
    docker push "$local_tag"
done

echo "Pre-loading complete"
```

---

## 4. RegistryManager

### 4.1 Go Implementation

```go
// internal/managers/registry.go

package managers

import (
    "encoding/json"
    "fmt"
    "net/http"
    "os"
    "path/filepath"
    "time"
)

type RegistryManager struct {
    registryURL string
    client      *http.Client
}

func NewRegistryManager(url string) *RegistryManager {
    return &RegistryManager{
        registryURL: url,
        client:      &http.Client{Timeout: 30 * time.Second},
    }
}

// CheckImage checks if an image exists locally
func (r *RegistryManager) CheckImage(image, tag string) (bool, error) {
    url := fmt.Sprintf("%s/v2/%s/manifests/%s", r.registryURL, image, tag)
    req, _ := http.NewRequest("HEAD", url, nil)
    req.Header.Set("Accept", "application/vnd.docker.distribution.manifest.v2+json")
    
    resp, err := r.client.Do(req)
    if err != nil {
        return false, err
    }
    defer resp.Body.Close()
    
    return resp.StatusCode == 200, nil
}

// ListImages returns all images in the registry
func (r *RegistryManager) ListImages() ([]string, error) {
    url := fmt.Sprintf("%s/v2/_catalog", r.registryURL)
    resp, err := r.client.Get(url)
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()
    
    var catalog struct {
        Repositories []string `json:"repositories"`
    }
    if err := json.NewDecoder(resp.Body).Decode(&catalog); err != nil {
        return nil, err
    }
    return catalog.Repositories, nil
}

// GetImageTags returns tags for an image
func (r *RegistryManager) GetImageTags(image string) ([]string, error) {
    url := fmt.Sprintf("%s/v2/%s/tags/list", r.registryURL, image)
    resp, err := r.client.Get(url)
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()
    
    var tags struct {
        Tags []string `json:"tags"`
    }
    if err := json.NewDecoder(resp.Body).Decode(&tags); err != nil {
        return nil, err
    }
    return tags.Tags, nil
}

// DeleteImage deletes an image from the registry
func (r *RegistryManager) DeleteImage(image, tag string) error {
    // Get manifest digest first
    url := fmt.Sprintf("%s/v2/%s/manifests/%s", r.registryURL, image, tag)
    req, _ := http.NewRequest("GET", url, nil)
    req.Header.Set("Accept", "application/vnd.docker.distribution.manifest.v2+json")
    
    resp, err := r.client.Do(req)
    if err != nil {
        return err
    }
    digest := resp.Header.Get("Docker-Content-Digest")
    resp.Body.Close()
    
    if digest == "" {
        return fmt.Errorf("could not get digest for %s:%s", image, tag)
    }
    
    // Delete by digest
    url = fmt.Sprintf("%s/v2/%s/manifests/%s", r.registryURL, image, digest)
    req, _ = http.NewRequest("DELETE", url, nil)
    resp, err = r.client.Do(req)
    if err != nil {
        return err
    }
    defer resp.Body.Close()
    
    if resp.StatusCode != 202 {
        return fmt.Errorf("delete failed with status %d", resp.StatusCode)
    }
    return nil
}

// GetDiskUsage returns registry storage usage in bytes
func (r *RegistryManager) GetDiskUsage() (int64, error) {
    var size int64
    err := filepath.Walk("/cubeos/data/registry", func(_ string, info os.FileInfo, err error) error {
        if err != nil {
            return err
        }
        if !info.IsDir() {
            size += info.Size()
        }
        return nil
    })
    return size, err
}

// IsOnline checks if upstream registries are reachable
func (r *RegistryManager) IsOnline() bool {
    client := &http.Client{Timeout: 5 * time.Second}
    resp, err := client.Get("https://registry-1.docker.io/v2/")
    if err != nil {
        return false
    }
    defer resp.Body.Close()
    return resp.StatusCode == 200 || resp.StatusCode == 401
}
```

---

## 5. Compose File Transformation

When installing apps, image references are rewritten:

```go
// internal/managers/compose.go

func (t *ComposeTransformer) RewriteImages(compose *ComposeFile) error {
    for name, service := range compose.Services {
        original := service.Image
        
        // Skip if already local
        if strings.HasPrefix(original, "localhost:5000/") {
            continue
        }
        
        // Skip CubeOS images (built locally)
        if strings.HasPrefix(original, "ghcr.io/cubeos-app/") {
            continue
        }
        
        // Rewrite to local registry
        // docker.io/library/nginx -> localhost:5000/library/nginx
        // ghcr.io/user/repo -> localhost:5000/user/repo
        local := "localhost:5000/" + strings.TrimPrefix(
            strings.TrimPrefix(original, "docker.io/"),
            "ghcr.io/",
        )
        
        service.Image = local
        compose.Services[name] = service
    }
    return nil
}
```

---

## 6. Offline Mode Behavior

```go
// internal/managers/orchestrator.go

func (o *Orchestrator) InstallApp(req InstallRequest) (*App, error) {
    online := o.registry.IsOnline()
    
    // Check local availability
    exists, _ := o.registry.CheckImage(req.Image, req.Tag)
    
    if !exists && !online {
        return nil, &AppError{
            Code:    "OFFLINE_IMAGE_UNAVAILABLE",
            Message: fmt.Sprintf("Image %s:%s not available offline", req.Image, req.Tag),
        }
    }
    
    // If online and not cached, pull-through will fetch it
    // Continue with installation...
}
```

---

## 7. Storage Management API

```go
// GET /api/v1/registry/status
type RegistryStatus struct {
    Online    bool   `json:"online"`
    URL       string `json:"url"`
    DiskUsage struct {
        Bytes int64  `json:"bytes"`
        Human string `json:"human"`
    } `json:"disk_usage"`
    ImageCount int `json:"image_count"`
}

// GET /api/v1/registry/images
type RegistryImage struct {
    Name    string   `json:"name"`
    Tags    []string `json:"tags"`
    Size    int64    `json:"size"`
    Curated bool     `json:"curated"`
}

// POST /api/v1/registry/cleanup
type CleanupRequest struct {
    KeepTags      int `json:"keep_tags"`
    OlderThanDays int `json:"older_than_days"`
}

type CleanupResponse struct {
    DeletedBytes int64 `json:"deleted_bytes"`
    DeletedCount int   `json:"deleted_count"`
}
```

---

## 8. Docker Daemon Configuration

```json
// /etc/docker/daemon.json
{
    "insecure-registries": ["localhost:5000"],
    "registry-mirrors": ["http://localhost:5000"],
    "storage-driver": "overlay2",
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "3"
    }
}
```

---

*Document Version: 2.0*  
*Last Updated: January 31, 2026*
