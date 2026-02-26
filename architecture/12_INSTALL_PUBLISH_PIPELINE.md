# 12 — Curl Installer Publish Pipeline

_How `install.sh` flows from source code to `https://get.cubeos.app`._

## Overview

The CubeOS curl installer (`curl -fsSL https://get.cubeos.app | sudo bash`) is a 1,338-line
Bash script that installs CubeOS in Tier 2 (container-only) mode on any Linux system. It lives
in two places and reaches users via the website's nginx container.

## File Locations

| Location | Purpose |
|----------|---------|
| `releases/curl/install.sh` | **Source of truth** — maintained alongside CLI and compose template |
| `website/static/install.sh` | **Serving copy** — Hugo copies this into `public/` at build time |

Both files are currently identical (1,338 lines, version `0.2.0-beta.01`).

## Pipeline: Source to Live

```
releases/curl/install.sh    (source of truth)
        │
        │  ❶ Automatic — releases CI "sync-installer" job
        │    (clones website repo, copies file, commits + pushes if changed)
        ▼
website/static/install.sh   (serving copy in website repo)
        │
        │  ❷ Automatic — website CI triggers on push to main
        ▼
website CI pipeline (.gitlab-ci.yml)
   ├─ build:   Hugo --minify → public/install.sh (from static/)
   ├─ docker:  Docker build → GHCR (ghcr.io/cubeos-app/website:latest)
   └─ deploy:  AWX job template → pulls image on DMZ → restarts container
        │
        │  ❸ Automatic (CI/CD)
        ▼
DMZ server (nllei01dmz01)
   └─ nginx container serves get.cubeos.app
      ├─ location = /           → content-negotiation (curl → /install.sh, browser → index.html)
      ├─ location = /install.sh → text/plain, Cache-Control: max-age=300
      └─ location /channels/    → JSON channel metadata
```

### Step-by-step

1. **Edit** `releases/curl/install.sh` (the source of truth in the releases repo).
2. **Commit and push** to `releases/main`.
3. Releases CI `sync-installer` job runs automatically:
   - Clones the website repo using `GITLAB_TOKEN`
   - Copies `curl/install.sh` → `website/static/install.sh`
   - Commits and pushes only if the file changed (no-op otherwise)
4. Website CI triggers automatically on the push:
   - **build** stage: Hugo builds static site, copies `static/install.sh` → `public/install.sh`
   - **docker** stage: Docker image built with `public/` baked in, pushed to GHCR
   - **deploy** stage: AWX job pulls new image on DMZ, restarts the website container
5. Live at `https://get.cubeos.app` within ~5 minutes of push to releases.

## Content Negotiation (nginx)

The nginx config (`website/nginx.conf`) detects curl/wget/HTTPie/PowerShell user agents:

```nginx
location = / {
    if ($http_user_agent ~* "^(curl|Wget|wget|HTTPie|PowerShell)") {
        rewrite ^ /install.sh last;
    }
    try_files $uri $uri/ /index.html;
}
```

- `curl https://get.cubeos.app` → serves `install.sh` as `text/plain`
- Browser visit → serves the Hugo-rendered landing page

## What the Releases Pipeline Does (and Does Not Do)

The releases repo's `upload-releases` job (triggered on **tag push** `v*`) handles:

| Uploaded to DMZ | Destination |
|----------------|-------------|
| Full/Lite `.img.xz` + checksums | `/srv/cubeos-releases/data/releases/{VERSION}/` |
| `docker-compose.yml` (from template) | Same release directory |
| `cubeos-cli.sh` | Same release directory |
| `rpi-imager.json` | Same release directory |
| Channel JSON (`beta.json`, etc.) | `/srv/cubeos-website/data/channels/` |

**Synced separately (on every push to main, not just tags):**
- `install.sh` — the `sync-installer` job copies it to the website repo automatically
- NOT part of `upload-to-releases-server.sh` — handled by its own CI job

## How to Publish a New Version

### Update install.sh content (bug fix, new feature)

```bash
# Edit source of truth, commit, and push — sync is automatic
cd releases
vim curl/install.sh
git add curl/install.sh && git commit -m "fix: installer XYZ"
git push origin main
# sync-installer CI job copies to website repo → website CI redeploys
```

### Bump CUBEOS_VERSION for a new release

```bash
# Update version in releases/curl/install.sh (lines 10-11)
cd releases
sed -i 's/CUBEOS_INSTALLER_VERSION=.*/CUBEOS_INSTALLER_VERSION="X.Y.Z"/' curl/install.sh
sed -i 's/CUBEOS_VERSION=.*/CUBEOS_VERSION="X.Y.Z"/' curl/install.sh
git add curl/install.sh && git commit -m "feat: bump installer to vX.Y.Z"
git push origin main
# sync-installer CI job copies to website repo → website CI redeploys
```

### Verify the live version

```bash
# Compare live vs repo
curl -fsSL https://get.cubeos.app > /tmp/live-install.sh
diff releases/curl/install.sh /tmp/live-install.sh
# Should show no differences

# Check version string
curl -fsSL https://get.cubeos.app | head -11 | grep VERSION
```

## Version Strings in install.sh

Lines 10-11 of `install.sh` contain hardcoded version strings:

```bash
CUBEOS_INSTALLER_VERSION="0.2.0-beta.01"
CUBEOS_VERSION="0.2.0-beta.01"
```

- `CUBEOS_INSTALLER_VERSION` — tracks the installer script's own version
- `CUBEOS_VERSION` — the CubeOS release version the installer will deploy

These must be manually updated when releasing a new version. There is no automatic
substitution from CI variables or channel metadata at build time.

## Gaps and Risks

### ~~1. Manual Copy Between Repos~~ — RESOLVED

The `sync-installer` CI job in `releases/.gitlab-ci.yml` now automatically copies
`curl/install.sh` to `website/static/install.sh` on every push to `releases/main`.
The job is a no-op when the file hasn't changed (uses `git diff --staged --quiet` guard).

### 2. Hardcoded Version Strings (MEDIUM)

`CUBEOS_VERSION` is hardcoded in install.sh rather than fetched from channel metadata at
runtime. When a new release is cut, the installer must be manually updated in two repos.

**Current mitigation:** The installer could read from `https://get.cubeos.app/channels/latest.json`
at runtime instead of relying on the hardcoded value — the channel infrastructure already exists.

### 3. No Smoke Test After Deploy (LOW)

The website pipeline deploys via AWX but does not verify that the live install.sh is
accessible and valid after deployment. A malformed nginx config or Hugo build error could
silently break the install path.

**Mitigation:** Add a post-deploy curl check in the website CI deploy stage.

## Related Files

| File | Repo | Purpose |
|------|------|---------|
| `curl/install.sh` | releases | Source of truth for installer |
| `curl/cubeos-cli.sh` | releases | Post-install CLI (status, update, backup, etc.) |
| `curl/docker-compose.yml.template` | releases | Compose template used during install |
| `static/install.sh` | website | Serving copy baked into Docker image |
| `nginx.conf` | website | Content negotiation + caching rules |
| `layouts/partials/install-command.html` | website | Copy-paste block on landing page |
| `scripts/upload-to-releases-server.sh` | releases | Uploads images + CLI to DMZ (not install.sh) |
| `scripts/update-channels.sh` | releases | Updates channel JSON on DMZ website |
| `.gitlab-ci.yml` | website | Hugo → GHCR → AWX deploy pipeline |
| `.gitlab-ci.yml` | releases | Image builds, releases, uploads, install.sh sync |
