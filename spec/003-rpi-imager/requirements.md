# Requirements — Raspberry Pi Imager listing (spec/003)

Source: `architecture/10_RASPBERRY_PI_IMAGER.md` + `CUBEOS_PROJECT_ROADMAP_v4.md` §2 (Phase 5).

> ID convention: 300-block.

REQ-300: The system shall produce `pi-imager-manifest.json` on every successful Packer image build.
REQ-301: The system shall include SHA-256 digest, image-size, release-date, release-notes-url, and download-URL in the manifest for each image variant.
REQ-302: The system shall upload `pi-imager-manifest.json` to `get.cubeos.app/pi-imager-manifest.json` on every release.
REQ-303: When a new image is published, the system shall verify the SHA-256 in the manifest matches the actual published artifact before exposing the new manifest version.
REQ-304: When the operator opens Raspberry Pi Imager and selects "Other general-purpose OS → CubeOS", the system manifest shall list every published image variant.
REQ-305: The system shall present a human-readable name for each variant in the form "CubeOS Pi 5 (full)" and "CubeOS Pi 5 (lite — no AI/ML)" — one name per published variant.
REQ-306: While the user is downloading, the Pi Imager shall verify the SHA-256 against the manifest entry and abort on mismatch.
REQ-307: The system shall submit the canonical manifest URL `https://get.cubeos.app/pi-imager-manifest.json` to the Raspberry Pi Foundation for catalog inclusion.
REQ-308: The system shall maintain backward compatibility on the canonical manifest URL — the URL path shall not change.
REQ-309: The system shall publish Pi 5 full + Pi 5 lite + Pi 4 full + Pi 4 lite + x86_64 full image variants.
REQ-310: The system shall compute SHA-256 of each published image and embed in the manifest.
REQ-311: The system shall sign the manifest with the CubeOS release key and publish the signature at `get.cubeos.app/pi-imager-manifest.json.sig`.
REQ-312: When Pi Imager fetches the manifest, the Pi Imager shall verify the signature against the published CubeOS release pubkey if it supports manifest signatures.
REQ-313: The system shall include a `release_notes_url` field in each manifest entry pointing at the GitLab release page.
REQ-314: The system shall keep all historical image versions in the manifest for at least 12 months after release.
REQ-315: When a version reaches end-of-life, the system shall mark its manifest entry with `eol: true` rather than deleting.
