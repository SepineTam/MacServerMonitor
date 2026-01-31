# MacServerMonitor
Mac devices (as server) monitor. 

> Notes: This project is made by AI including documents. 

MacServerMonitor is a lightweight monitoring panel designed for macOS devices that are used as long-running servers.

It focuses on a small set of critical system resources and provides:
- clear real-time visibility,
- configurable threshold-based alerts,
- and optional LAN-based remote monitoring,

while keeping energy consumption and system overhead as low as possible.

This project is intended for personal use, with a clean and extensible structure that makes future open-sourcing possible.

---

## Features

- **Resource Monitoring**
  - Memory usage
  - CPU usage and load
  - Disk usage (percentage-based)
  - Network connectivity status

- **Alerting**
  - Configurable thresholds for memory, CPU, disk, and network
  - Sound alerts using system notification sounds
  - Alert throttling to avoid repeated noisy warnings

- **Dashboard**
  - Window-based monitoring dashboard
  - Suitable for dedicated external displays
  - Simple visual indicators and lightweight charts

- **Settings**
  - Adjustable refresh interval (e.g. 5s / 10s / 30s)
  - Fully configurable alert thresholds
  - Alert enable/disable per metric

- **LAN Remote Monitoring**
  - Built-in lightweight HTTP server
  - Read-only status access from other devices in the same local network
  - Token-based access control

---

## Design Principles

- Low energy consumption for long-running usage
- Minimal system permissions
- No background daemons or privileged helpers
- Focus on actionable signals instead of exhaustive metrics
- Clean architecture for future extensibility

---

## Roadmap

- [ ] Basic dashboard UI
- [ ] Memory monitoring and visualization
- [ ] CPU usage and load monitoring
- [ ] Disk usage monitoring (percentage-based)
- [ ] Network connectivity detection
- [ ] Configurable alert thresholds
- [ ] Sound alert system with throttling
- [ ] Settings panel
- [ ] Built-in HTTP API for LAN monitoring
- [ ] Remote status JSON endpoint
- [ ] Documentation and architecture notes

---

## Status

This project is under active development and currently targets macOS only.

