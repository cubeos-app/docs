# Design — Raspberry Pi Imager listing (spec/003)

The final piece of Track A Phase 5. Once submitted + accepted, CubeOS appears in the official Pi Imager catalog under "Other general-purpose OS" — the canonical distribution channel for Pi-targeted OSes.

## Pipeline integration

```
git tag vX.Y.Z (chore: bump version to vX.Y.Z commit)
   │
   ▼
Packer builds 5 image variants (Pi 5 full+lite, Pi 4 full+lite, x86_64 full)
   │
   ▼
CI: sha256sum each image → assemble pi-imager-manifest.json → sign with release key
   │
   ▼
CI: upload images to GitLab Releases + get.cubeos.app/downloads/vX.Y.Z/
   │
   ▼
CI: upload manifest + signature to:
   https://get.cubeos.app/pi-imager-manifest.json
   https://get.cubeos.app/pi-imager-manifest.json.sig
   │
   ▼
(if not yet listed) operator submits manifest URL to Pi Foundation form
   │
   ▼
Pi Imager pulls manifest periodically → CubeOS appears in catalog
```

## Manifest schema (Pi Imager v1)

```json
{
  "name": "CubeOS",
  "description": "Self-hosted OS for personal cloud. Pi-hole + NPM + app store + dashboard out of the box.",
  "icon": "https://cubeos.app/icon.png",
  "website": "https://cubeos.app",
  "release_date": "2026-05-17",
  "subitems": [
    {
      "name": "CubeOS Pi 5 (full)",
      "description": "All coreapps including AI/ML stack. Recommended for 64GB+ SD card.",
      "url": "https://get.cubeos.app/downloads/v0.2.0/cubeos-pi5-full-v0.2.0.img.xz",
      "image_download_size": 3700000000,
      "extract_size": 8200000000,
      "extract_sha256": "abc123...",
      "release_notes_url": "https://gitlab.nuclearlighters.net/products/cubeos/releases/-/releases/v0.2.0",
      "eol": false
    },
    ... lite + Pi 4 variants ...
  ]
}
```

## Why `extract_sha256` matters

Pi Imager verifies the *extracted* image (post-`xz -d`) against `extract_sha256`. Operator gets a corruption-free Pi out of the box. CI must verify the sha256 BEFORE the manifest goes live (REQ-303) — a manifest with a wrong hash would brick every download attempt.

## Out of scope

- Pi Imager UI customisation (icon, splash) — Pi Foundation owns those slots.
- Multi-variant install (e.g. "with WireGuard pre-configured") — out of scope; operator does that post-boot via dashboard.
- Network install (NFS root) — operator can do this externally; not a CubeOS Pi Imager feature.
