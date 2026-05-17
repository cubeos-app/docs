# Steering — Release pipeline

How CubeOS commits become deployed bits on a Pi. Condensed from `architecture/12_INSTALL_PUBLISH_PIPELINE.md`.

## The three pipelines

CubeOS has three independent release pipelines, each on its own trigger:

1. **Per-component CI auto-deploy** — push to `main` on api/dashboard/hal/coreapps → CI builds → pushes image to local registry on every running Pi → Pi pulls + restarts stack.
2. **Image build (Packer)** — `chore: bump version to vX.Y.Z` commit OR web-trigger on `releases/` repo → Packer builds Pi 5 + Pi 4 + x86_64 images → uploads to release artifacts.
3. **Install script sync** — change to `install.sh` in `releases/` → CI syncs to `get.cubeos.app/install.sh` (curl-installer endpoint).

## Per-component CI auto-deploy

| Trigger              | What runs              | Where it deploys                                      |
|----------------------|------------------------|-------------------------------------------------------|
| `git push origin main` on `api/` | GitLab CI: build → test → push image to GPU registry → SSH to each registered Pi → `docker stack deploy --resolve-image never` | Every Pi registered in the deployment manifest        |
| Same on `dashboard/`             | Same                    | Same                                                  |
| Same on `hal/`                   | Same (privileged: includes systemd unit reload via SSH) | Same                                                  |
| Same on `coreapps/`              | CI lints compose files + transforms to Swarm format + deploys updated stacks | Same                                                  |

Deployment manifest: maintained out-of-band by operator (per-Pi SSH key + hostname). Article XV makes this auto-deploy explicit and operator-acknowledged.

## Image build (Packer)

Triggered by:
- A commit on `releases/` matching the regex `^chore: bump version to v\d+\.\d+\.\d+$`
- OR a manual GitLab web-trigger button

Build matrix:
- Pi 5 (aarch64) — full image (`cubeos-pi5-vX.Y.Z.img.xz`) + lite image (no AI/ML coreapps for low-storage setups)
- Pi 4 (aarch64) — same dual variant
- x86_64 — full image only (`cubeos-x86-vX.Y.Z.img.xz`); Proxmox LXC tarball

Build duration on the build VM: ~30 min full, ~22 min lite.

Outputs:
- GitLab Releases (project 20)
- GitHub Releases (mirrored via `dot-github/` CI)
- `get.cubeos.app/downloads/vX.Y.Z/`
- `pi-imager-manifest.json` updated with new SHA-256 + size + URL

## Install script sync

`releases/install.sh` is the canonical curl-installer:
```
curl -fsSL https://get.cubeos.app | bash
```

On change to `install.sh` in `releases/`:
1. CI lints the script (`shellcheck`).
2. CI uploads to `get.cubeos.app/install.sh` via the website's CDN.
3. CDN cache invalidation triggered (1-min TTL).

## Tag-all-repos

After a Packer build completes successfully, `releases/` CI runs `tag-all-repos.sh` which:
1. Tags `api`, `dashboard`, `hal`, `coreapps`, `releases`, `docsindex`, `docs` with `vX.Y.Z`.
2. Pushes tags to each repo's GitLab + GitHub remote.

This is the single point at which the entire CubeOS family's git state converges on a version label.

## The Packer trigger regex (Article XVI guard)

```
^chore: bump version to v\d+\.\d+\.\d+$
```

A commit message that doesn't match this regex will NOT trigger Packer. This is intentional — Packer runs cost 30+ minutes of build-VM time and pollute the release artifact set. Article XVI exists to prevent accidental triggers.

## Boot-side install flow

1. Operator picks CubeOS in Raspberry Pi Imager (or downloads `.img.xz` manually).
2. Pi Imager flashes SD card with the image.
3. Pi boots; `cubeos-init.service` runs (per `04_BOOT_SEQUENCE.md`).
4. First-boot wizard prompts for SSH pubkey + network mode + access profile.
5. Operator points browser at `cubeos.cube` (or the Pi's IP if not in `all_in_one`); dashboard appears.

## Update flow on a running Pi

| Update type             | Trigger                                                     | Operator action                          |
|-------------------------|-------------------------------------------------------------|------------------------------------------|
| Coreapp image change    | Auto via per-component CI on push to main                   | None                                     |
| OS package update       | `cubeos-cli system update && cubeos-cli system upgrade`     | Required (per security-baseline.md Layer 10) |
| Major image-level OTA   | Operator downloads new `.img.xz` and reflashes              | Required; data persists on `/cubeos/`    |

Image-level OTA without reflash is **explicitly deferred** per `adr/0007-ota-strategy.md` (extending the existing `decisions/adr-ota-updates.md`).

## Rollback

- Per-component: `git revert <bad-commit> && git push` — CI auto-deploys the revert.
- Image-level: keep the previous version's `.img.xz` for SD-card reflash; `/cubeos/` data partition survives the reflash.

## CI infrastructure facts

- All builds run on the GPU VM (per `CUBEOS_PROJECT_ROADMAP_v4.md` §2 row "Infrastructure" — "CI/CD via SSH").
- The build VM has registry access (`localhost:5000` for image push).
- Pi deployment uses SSH key authentication; the deploy key lives in the GitLab CI variables vault.
