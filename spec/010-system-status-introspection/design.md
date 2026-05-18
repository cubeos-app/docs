# Design — System status introspection (spec/010)

Diagnostic surface for operators + automation. Three audiences:

1. Dashboard widgets (sparklines, health badges)
2. cubeos-cli (text summary, exit-code scripting)
3. External Prometheus (optional flag)

## File-level paths (future-work)

| Function | Path |
|---|---|
| Status endpoint | new `api/internal/handlers/system_status.go` |
| Hardware endpoint | new `api/internal/handlers/system_hardware.go` |
| Health probes | new `api/internal/handlers/system_health.go` |
| Audit search | new `api/internal/handlers/system_audit.go` |
| Boot-history (extends spec/001) | new `api/internal/handlers/system_boot_history.go` |
| Stack resources | extend existing `api/internal/handlers/apps.go` OR new `system_stack_resources.go` |
| Prometheus exporter | new `api/internal/handlers/metrics.go` |
| Collector / cache | new `api/internal/managers/system_collectors.go` |
| Dashboard sparklines | new `dashboard/src/components/dashboard/ResourceSparkline.vue` |
| cubeos-cli | new `cubeos-cli/cmd/system.go` (separate repo) |

## Architecture

```
+----------------+
|  collectors    |  every 5s
|  - /proc/stat  |
|  - /proc/meminfo
|  - df / blkid  |
|  - vcgencmd    |  (Pi temperature)
|  - HAL probes  |  (gps, iridium, meshtastic via existing /gps + /iridium + /meshtastic endpoints)
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

## Why in-memory cache

Repeated `/proc` reads + `vcgencmd` calls per request would dominate CPU on a Pi. Cache for 10s:

- /system/status served from cache 99%+ of the time
- Per-request CPU cost ~0.1 ms
- Worst-case staleness 10 seconds (acceptable for diagnostics)

## Out of scope

- Long-term metrics storage (operator uses external Prometheus + retention).
- Alerting rules (CubeOS provides metrics, operator owns alerts).
- Distributed tracing (single-Pi runtime — flame graphs + structured logs cover it).
