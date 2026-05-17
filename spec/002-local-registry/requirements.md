# Requirements — Local registry (spec/002)

Source: `architecture/08_LOCAL_REGISTRY.md` + `01_REQUIREMENTS.md` §1.8 + Article III (Offline-first) + Article XIV (Local registry only for coreapps).

> ID convention: 200-block (`200..299`).

## Functional requirements

### Registry shape

REQ-200: The system shall run a Docker registry as a Swarm stack listening on `localhost:5000`.
REQ-201: The system shall NOT expose the registry on any network interface other than loopback.
REQ-202: The system shall persist registry data at `/cubeos/data/registry/` so it survives container restarts.
REQ-203: While the system is operating, the registry shall be the only image source consulted at coreapp pull time.

### Image population

REQ-204: The system shall populate the local registry with all coreapp images at image-build time during Packer image construction.
REQ-205: The system shall pin every coreapp image to a SHA-256 digest in the compose files to prevent silent upstream mutation.
REQ-206: When a coreapp is updated via CI auto-deploy, the system shall push the new image to the local registry before issuing `docker stack deploy`.

### Operator-curated user apps

REQ-207: The system shall provide a dashboard action to import a tar-archived image into the local registry from a USB stick or local file.
REQ-208: When an imported image is added to the registry, the system shall record its source filename and import timestamp to `/cubeos/data/registry/imports.log`.
REQ-209: The system shall NOT delete imported images automatically — operator-curated content is sticky.

### Offline guarantees

REQ-210: While the system is in `offline_hotspot` mode, the system shall NOT attempt any pull from a remote registry.
REQ-211: If a coreapp's compose file references an image not present in the local registry, then the system shall fail the deploy with an actionable error message listing the missing image.

### Garbage collection

REQ-212: The system shall expose a dashboard action to garbage-collect untagged registry layers older than 30 days.
REQ-213: When garbage collection runs, the system shall NOT delete any layer referenced by an actively-deployed stack.
REQ-214: The system shall log every garbage-collection event to `/cubeos/data/registry/gc.log` with byte-reclaimed counts.

### Health + introspection

REQ-215: The system shall expose `GET /api/v1/registry/status` returning storage usage, image count, last-import timestamp, last-GC timestamp.
REQ-216: While the registry is unreachable, the dashboard shall display a critical-severity health banner blocking app-install actions.
REQ-217: The system shall mirror the registry health into the cubeos-cli `system health` command output.
