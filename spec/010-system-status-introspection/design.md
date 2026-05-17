# Design — System status introspection (spec/010)

Diagnostic surface for operators + automation. Three audiences:

1. Dashboard widgets (sparklines, health badges)
2. cubeos-cli (text summary, exit-code-based scripting)
3. External Prometheus (when the optional flag is on)

## Architecture

```
+----------------+
|  collectors    |  every 5s
|  - /proc/stat  |
|  - /proc/meminfo
|  - df / blkid  |
|  - vcgencmd    |  (Pi temperature)
|  - HAL probes  |
+--------+-------+
         │
         ▼
+----------------+
|  cache (in-mem)|
|  10s TTL       |
+--------+-------+
         │
         ▼
+----------------+
|  HTTP handlers |
|  /system/*     |
+----------------+
```

## Why an in-memory cache

Repeated `/proc` reads + `vcgencmd` calls per request would dominate CPU on a Pi. Caching for 10s means:

- /system/status served from cache 99%+ of the time
- Per-request CPU cost ~0.1 ms
- Worst-case staleness 10 seconds (acceptable for diagnostic-grade data)

## HAL probe set

| Probe                | Returns                                       | Frequency |
|----------------------|-----------------------------------------------|-----------|
| `gps`                | lock status, satellite count, fix quality     | 5 s       |
| `iridium`            | signal bars, last-handshake-at, queue depth   | 30 s      |
| `meshtastic`         | neighbor count, packet rates                  | 10 s      |
| `zigbee`             | coordinator state, joined-device count        | 30 s      |
| `cellular`           | signal bars, technology, RSRP                 | 30 s      |
| `temperature_cpu`    | C                                             | 5 s       |
| `temperature_board`  | C                                             | 5 s       |

Hardware-absent probes return `{available: false}`.

## Health probe set

| Probe          | Healthy | Degraded                                  | Unhealthy                                |
|----------------|---------|-------------------------------------------|------------------------------------------|
| `hal`          | HTTP 200 on /hal/health | response > 500 ms          | unreachable or HTTP non-200             |
| `swarm`        | `docker info` succeeds + leader present | leader missing | `docker info` fails                     |
| `pihole_dns`   | dig 1.1.1.1 via Pi-hole succeeds | high latency       | dig fails                                |
| `npm`          | NPM API /health 200 | response > 1s                   | unreachable                              |
| `registry`     | GET /v2/_catalog 200 | not 200                         | unreachable                              |
| `disk_root`    | < 80% used | 80-95% used                              | > 95% used                               |
| `disk_data`    | < 80% used (/cubeos/) | 80-95% used                  | > 95% used                               |
| `temperature`  | < 70 C | 70-80 C                                       | > 80 C                                    |
| `audit_log`    | append-only writable | log rotation overdue          | write failure                            |

## Secret redaction (REQ-1019)

```python
# pseudocode
def redact(env_dict):
    for k, v in env_dict.items():
        if any(suffix in k for suffix in ['_SECRET', '_KEY', '_TOKEN', '_PASSWORD', '_PASS']):
            env_dict[k] = '[REDACTED]'
    return env_dict
```

Applied at every place we expose process env vars (e.g. when surfacing service definitions in the Swarm GUI). The redaction is FRESH on every response — no caching of unredacted data.

## Prometheus exposition (REQ-1016)

When `prometheus_exporter: true` in `/cubeos/config/defaults.env`:
- `/metrics` exposes process_*, go_*, plus custom `cubeos_*` metrics:
  - `cubeos_coreapp_health{name="pihole",status="healthy"}` 1
  - `cubeos_temperature_c{sensor="cpu"}` 47.5
  - `cubeos_hal_probe_duration_ms{probe="gps"}` 8
  - `cubeos_swarm_tasks_db_bytes` ...

When the flag is off, `/metrics` returns 404 to keep attack surface minimal.

## Out of scope

- Long-term metrics storage (use external Prometheus + retention strategy).
- Alerting rules (operator configures externally; CubeOS provides metrics, not alerts).
- Distributed tracing (single-Pi runtime — flame graphs / structured logs cover the use case).
