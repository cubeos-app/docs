# Steering — Release pipeline

Three independent pipelines from `architecture/12_INSTALL_PUBLISH_PIPELINE.md`.

## 1. Per-component CI auto-deploy (push to main)

| Trigger | What runs | Where it deploys |
|---|---|---|
| `git push origin main` on `api/` / `dashboard/` / `hal/` / `coreapps/` | CI: build → test → push to registry → SSH to each Pi → `docker stack deploy --resolve-image never` | Every Pi in the deployment manifest |
| Same on `coreapps/` | CI lints compose + transforms to Swarm format + deploys | Same |

Per Article XV. The deployment manifest is operator-maintained (per-Pi SSH key + hostname).

## 2. Image build (Packer)

Triggered by:
- A commit on `releases/` matching `^chore: bump version to v\d+\.\d+\.\d+$`
- OR a manual GitLab web-trigger

Build matrix:
- Pi 5 (aarch64) — full + lite variants
- Pi 4 (aarch64) — full + lite
- x86_64 — full

Outputs go to GitLab Releases + GitHub Releases (via `dot-github/` mirror CI) + `get.cubeos.app/downloads/vX.Y.Z/` + the Pi Imager manifest JSON.

## 3. Install script sync

`releases/install.sh` is the curl-installer (`curl -fsSL https://get.cubeos.app | bash`).

On change to `install.sh`:
1. CI lints with shellcheck
2. Uploads to `get.cubeos.app/install.sh` via the website CDN
3. CDN cache invalidation (1-min TTL)

## Tag-all-repos

After a successful Packer build, `releases/` CI runs `tag-all-repos.sh` which tags every CubeOS-family repo (api, dashboard, hal, coreapps, releases, docsindex, docs) with `vX.Y.Z` and pushes to GitLab + GitHub remotes.

## Article XVI guard

```
^chore: bump version to v\d+\.\d+\.\d+$
```

Commits not matching this regex do NOT trigger Packer. Accidental Packer runs cost 30+ min of build time + pollute release artifacts.

## Update flow on a running Pi

| Update type | Trigger | Operator action |
|---|---|---|
| Coreapp image change | Auto via per-component CI | None |
| OS package update | `cubeos-cli system update && cubeos-cli system upgrade` | Required |
| Major image-level OTA | Operator downloads new `.img.xz` and reflashes | Required; `/cubeos/` data partition survives reflash |

Image-level OTA without reflash is **deferred** per `adr/0007-ota-strategy.md`.

## Rollback

- Per-component: `git revert <bad-commit> && git push` — CI auto-deploys the revert.
- Image-level: keep the previous `.img.xz` for SD-card reflash.

## CI infrastructure

- All builds run on the GPU VM.
- Build host has registry access (`localhost:5000`).
- Pi deployment uses SSH key auth from CI variables vault.
