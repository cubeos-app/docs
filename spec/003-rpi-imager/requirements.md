# Requirements — Raspberry Pi Imager listing (spec/003)

Source: `architecture/10_RASPBERRY_PI_IMAGER.md` + `CUBEOS_PROJECT_ROADMAP_v4.md` §2 (Phase 5 = ~95% DONE; Pi Foundation submission is the last item).

> ID convention: 300-block (`300..399`).

## Functional requirements

### Manifest production

REQ-300: The system shall produce `pi-imager-manifest.json` on every successful Packer image build.
REQ-301: The system shall include SHA-256 digest, image-size, release-date, release-notes-url, and download-URL in the manifest for each image variant (Pi 5 full / Pi 5 lite / Pi 4 full / Pi 4 lite / x86_64 full).
REQ-302: The system shall upload `pi-imager-manifest.json` to `get.cubeos.app/pi-imager-manifest.json` on every release.
REQ-303: When a new image is published, the system shall verify the SHA-256 in the manifest matches the actual published artifact before exposing the new manifest version.

### Operator-side flow

REQ-304: When the operator opens Raspberry Pi Imager and selects "Other general-purpose OS → CubeOS", the system manifest shall list every published image variant.
REQ-305: The system shall present human-readable names for each variant: "CubeOS Pi 5 (full)", "CubeOS Pi 5 (lite — no AI/ML)", etc.
REQ-306: While the user is downloading, the Pi Imager shall verify the SHA-256 against the manifest entry and abort on mismatch.

### Pi Foundation submission

REQ-307: The system shall submit the canonical manifest URL `https://get.cubeos.app/pi-imager-manifest.json` to the Raspberry Pi Foundation for inclusion in the official Pi Imager catalog (Phase 5 final item per roadmap §2).
REQ-308: The system shall maintain backward compatibility on the canonical manifest URL — the URL path shall not change once submitted to the Pi Foundation.

### Image variants

REQ-309: The system shall publish a Pi 5 full image including all coreapps + the local registry pre-populated with all coreapp images.
REQ-310: The system shall publish a Pi 5 lite image excluding the AI/ML coreapps (ollama, chromadb, docs-indexer) — same OS, smaller image size for low-storage SD cards.
REQ-311: The system shall publish equivalent Pi 4 variants (full + lite) with the same coreapp set as their Pi 5 counterparts.
REQ-312: The system shall publish an x86_64 full image suitable for Proxmox LXC or bare-metal install.

### Hashing + signing

REQ-313: The system shall compute the SHA-256 of each published image and embed it in the manifest.
REQ-314: The system shall sign the manifest with the CubeOS release key and publish the signature at `get.cubeos.app/pi-imager-manifest.json.sig`.
REQ-315: When Pi Imager fetches the manifest, the Pi Imager shall verify the signature against the published CubeOS release pubkey if it supports manifest signatures, otherwise fall back to operator-driven verification.

### Release-notes integration

REQ-316: The system shall include a `release_notes_url` field in each manifest entry pointing at the GitLab release page for that version.
REQ-317: When the operator clicks the "Release notes" link in Pi Imager, the operator's browser shall open the GitLab release page.

### Backward compatibility

REQ-318: The system shall keep all historical image versions in the manifest for at least 12 months after release.
REQ-319: When a version reaches end-of-life, the system shall mark its manifest entry with `eol: true` rather than deleting the entry.
