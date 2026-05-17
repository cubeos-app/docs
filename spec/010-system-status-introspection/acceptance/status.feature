Feature: System status introspection (spec/010)

  # REQ-1000 + REQ-1001
  Scenario: /system/status returns key metrics within 100 ms
    When the operator GETs /api/v1/system/status
    Then the response includes cpu_pct, ram_used, ram_total, disk_*, temp_c, uptime_s
    And the response time is under 100 ms (served from cache)

  # REQ-1002 — hardware-specific metrics
  Scenario: GPS lock surfaces in status response on a GPS-equipped Pi
    Given the Pi has a UART GPS receiver connected
    When the operator GETs /api/v1/system/status
    Then the response includes gps.fix_quality
    And the response includes gps.satellite_count

  # REQ-1003 + REQ-1004
  Scenario: /system/health returns per-subsystem status with remediation
    Given pihole DNS is unresponsive
    When the operator GETs /api/v1/system/health
    Then pihole_dns shows status=unhealthy
    And pihole_dns includes a remediation field with actionable next steps

  # REQ-1005 — expanded health detail
  Scenario: Expanded health returns per-check result
    When the operator GETs /api/v1/system/health?expanded=true
    Then the response is an array of per-check objects
    And each includes name, status, latency_ms, last_run_at

  # REQ-1006 + REQ-1007 — per-coreapp resources
  Scenario: Stack resources endpoint returns sparkline-ready data
    When the operator GETs /api/v1/system/stacks/pihole/resources
    Then the response includes cpu_pct + memory_mb + net_rx_bps + net_tx_bps
    And the dashboard sparkline renders within 50 ms

  # REQ-1008 + REQ-1009 — audit-log search
  Scenario: Audit-log search filters work
    When the operator GETs /api/v1/system/audit?event_type=profile_switch&from=2026-05-10
    Then only profile_switch events on or after 2026-05-10 are returned
    And rotated audit log files are included in the search corpus

  # REQ-1011 + REQ-1012 — hardware enumeration + hotplug
  Scenario: Hardware endpoint lists detected components
    When the operator GETs /api/v1/system/hardware
    Then the response includes SoC, CPU, RAM, disks, WiFi adapters, USB devices, GPIO, serial ports

  Scenario: USB hotplug surfaces via WebSocket
    Given the dashboard is subscribed to the hardware-change WebSocket channel
    When the operator plugs in a USB WiFi adapter
    Then the dashboard receives a WebSocket event within 2 seconds
    And the event includes the new adapter's details

  # REQ-1013 + REQ-1014 — CLI mirror
  Scenario: cubeos-cli system status prints text summary
    When the operator runs `cubeos-cli system status`
    Then output includes CPU%, RAM used, disk usage, temperature
    And exit code is 0

  Scenario: cubeos-cli system health exits non-zero on unhealthy
    Given pihole DNS is unresponsive
    When the operator runs `cubeos-cli system health`
    Then exit code is non-zero (suitable for cron)
    And stderr names the unhealthy subsystem

  # REQ-1016 + REQ-1017 — Prometheus exporter
  Scenario: /metrics returns 404 when prometheus_exporter flag is off
    Given prometheus_exporter feature flag is false
    When the operator GETs /metrics
    Then the response is HTTP 404

  Scenario: /metrics returns Prometheus exposition format when flag is on
    Given prometheus_exporter feature flag is true
    When the operator GETs /metrics
    Then the response Content-Type is text/plain; version=0.0.4
    And the body includes cubeos_coreapp_health{}, cubeos_temperature_c{}, go_*, process_*

  # REQ-1018 + REQ-1019 — secret redaction
  Scenario: Secret env vars never appear in responses
    Given a coreapp has env DB_PASSWORD=p@ssw0rd
    When the operator GETs /api/v1/system/stacks/<app>/resources
    Then the response contains no occurrence of "p@ssw0rd"
    And the env var key DB_PASSWORD shows value "[REDACTED]"
