Feature: System status introspection (spec/010)

  # Covers: REQ-1000, REQ-1001, REQ-1002, REQ-1003, REQ-1004, REQ-1005, REQ-1006, REQ-1007, REQ-1008, REQ-1009, REQ-1010, REQ-1011, REQ-1012, REQ-1013, REQ-1014, REQ-1015, REQ-1016, REQ-1017, REQ-1018

  Scenario: /system/status returns key metrics within 100 ms
    When the operator GETs /api/v1/system/status
    Then the response includes cpu_pct, ram_used, ram_total, disk_*, temp_c, uptime_s
    And response time is under 100 ms (served from cache)

  Scenario: GPS lock surfaces in status response on a GPS-equipped Pi
    Given the Pi has a UART GPS receiver connected
    When the operator GETs /api/v1/system/status
    Then the response includes gps.fix_quality + gps.satellite_count

  Scenario: /system/health returns per-subsystem status with remediation
    Given pihole DNS is unresponsive
    When the operator GETs /api/v1/system/health
    Then pihole_dns shows status=unhealthy
    And pihole_dns includes a remediation field

  Scenario: Stack resources endpoint returns sparkline-ready data
    When the operator GETs /api/v1/system/stacks/pihole/resources
    Then the response includes cpu_pct + memory_mb + net_rx_bps + net_tx_bps

  Scenario: Audit-log search filters work
    When the operator GETs /api/v1/system/audit?event_type=profile_switch&from=2026-05-10
    Then only profile_switch events on or after 2026-05-10 are returned

  Scenario: Hardware endpoint lists detected components
    When the operator GETs /api/v1/system/hardware
    Then the response includes SoC, CPU, RAM, disks, WiFi adapters, USB devices, GPIO, serial ports

  Scenario: USB hotplug surfaces via WebSocket
    Given the dashboard is subscribed to the hardware-change WebSocket channel
    When the operator plugs in a USB WiFi adapter
    Then the dashboard receives a WebSocket event within 2 seconds

  Scenario: cubeos-cli system status prints text summary
    When the operator runs `cubeos-cli system status`
    Then output includes CPU%, RAM used, disk usage, temperature
    And exit code is 0

  Scenario: cubeos-cli system health exits non-zero on unhealthy
    Given pihole DNS is unresponsive
    When the operator runs `cubeos-cli system health`
    Then exit code is non-zero (suitable for cron)

  Scenario: /metrics returns 404 when prometheus_exporter flag is off
    Given prometheus_exporter feature flag is false
    When the operator GETs /metrics
    Then HTTP 404 is returned

  Scenario: /metrics returns Prometheus exposition format when flag is on
    Given prometheus_exporter feature flag is true
    When the operator GETs /metrics
    Then Content-Type is text/plain; version=0.0.4
    And the body includes cubeos_coreapp_health, cubeos_temperature_c, go_*, process_*

  Scenario: Secret env vars never appear in responses
    Given a coreapp has env DB_PASSWORD=p@ssw0rd
    When the operator GETs /api/v1/system/stacks/<app>/resources
    Then the response contains no occurrence of "p@ssw0rd"
    And the env var key DB_PASSWORD shows value "[REDACTED]"
