# Design — Pi Imager listing (spec/003)

Final piece of Track A Phase 5. Once submitted + accepted, CubeOS appears in the official Pi Imager catalog under "Other general-purpose OS".

## Pipeline

```
git tag vX.Y.Z (chore: bump version commit)
   │
   ▼
Packer builds 5 image variants
   │
   ▼
CI: sha256sum each image → assemble pi-imager-manifest.json → sign with release key
   │
   ▼
CI: upload to GitLab Releases + get.cubeos.app/downloads/vX.Y.Z/
   │
   ▼
CI: upload manifest + signature to canonical URLs
   │
   ▼
(if not yet listed) operator submits to Pi Foundation form
```

## File-level paths (releases/ — CGC: parent dir structure verified)

| Function | Path |
|---|---|
| Manifest generator | `releases/scripts/generate-pi-imager-manifest.sh` (new) |
| Upload script | `releases/scripts/upload-manifest.sh` (new) |
| Signing script | `releases/scripts/sign-manifest.sh` (new) |
| Verification | `releases/scripts/verify-manifest.sh` (new) |
| Manifest template | `releases/manifests/pi-imager-template.json` (new) |

## Manifest schema (Pi Imager v1)

```json
{
  "name": "CubeOS",
  "description": "Self-hosted OS for personal cloud.",
  "icon": "https://cubeos.app/icon.png",
  "website": "https://cubeos.app",
  "release_date": "2026-05-17",
  "subitems": [
    {
      "name": "CubeOS Pi 5 (full)",
      "description": "All coreapps including AI/ML.",
      "url": "https://get.cubeos.app/downloads/v0.2.0/cubeos-pi5-full-v0.2.0.img.xz",
      "image_download_size": 3700000000,
      "extract_size": 8200000000,
      "extract_sha256": "abc...",
      "release_notes_url": "https://gitlab.../releases/-/releases/v0.2.0",
      "eol": false
    }
  ]
}
```

## Out of scope

- Pi Imager UI customisation — Pi Foundation owns those slots.
- Multi-variant install — operator does that post-boot.
- Network install — not a CubeOS Pi Imager feature.
