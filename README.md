# MacServerMonitor
Mac devices (as server) monitor.

<p align="center">
  <img src="Resources/MacServerMonitor_Logo.png" alt="MacServerMonitor Logo" width="200"/>
</p>

> **Note:** This project was developed with assistance from AI tools.

MacServerMonitor is a lightweight monitoring panel designed for macOS devices that are used as long-running servers.

It focuses on a small set of critical system resources and provides:
- clear real-time visibility,
- configurable threshold-based alerts,
- and optional LAN-based remote monitoring,

while keeping energy consumption and system overhead as low as possible.

This project is intended for personal use, with a clean and extensible structure that makes future open-sourcing possible.

## AI Tools Used

This project was developed with assistance from the following AI tools:

- **Code Generation:** [GLM-4.7](https://github.com/THUDM/GLM-4) by Zhipu AI
- **AI Assistant Framework:** [Claude Code](https://claude.com/claude-code) by Anthropic
- **Logo Design:** [Lovart.ai](https://lovart.ai) (powered by Nano Banana model)
- **Documentation:** ChatGPT by OpenAI

Special thanks to these AI tools for making this project possible.

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

- [x] Basic dashboard UI
- [x] Memory monitoring and visualization
- [x] CPU usage and load monitoring
- [x] Disk usage monitoring (percentage-based)
- [x] Network connectivity detection
- [x] Configurable alert thresholds
- [x] Sound alert system with throttling
- [x] Settings panel
- [x] Built-in HTTP API for LAN monitoring
- [x] Remote status JSON endpoint
- [x] Documentation and architecture notes

---

## Status

✅ **v1.0 Complete** - All planned features implemented.

This project targets macOS 13+ only.

### Quick Start

```bash
# Build
swift build

# Run
swift run

# Build release app
swift build -c release

# The packaged app will be at: build/MacServerMonitor.app
```

