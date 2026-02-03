# Changelog

All notable changes to MacServerMonitor will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- Data visualization charts
- Historical trends
- Performance optimizations

## [1.2.0] - 2026-02-03

### Added
- **Alert History Recording**
  - Automatic recording of all alert events
  - Maximum 1000 events with 30-day retention
  - Persistent storage in UserDefaults
  - Multi-device support

- **Alert Severity Levels**
  - Warning/Critical classification
  - Automatic severity calculation based on threshold exceeded
  - Visual distinction with color coding

- **Alert History UI** (⌘+H)
  - Complete alert event list
  - Filtering by device, type, severity, status
  - Time range selection (1h, 24h, 7d, 30d, all)
  - Real-time statistics display
  - Event duration tracking

- **Data Export**
  - CSV format for spreadsheet analysis
  - JSON format for data processing
  - Native macOS save panel

- **Alert Silence Mode**
  - Quick silence options (1h, 4h, 24h, indefinite)
  - Scheduled silence with flexible time ranges
  - Weekday repeat rules
  - Automatic expiration
  - Manual end silence option
  - Settings integration

- **Notifications**
  - Added alert history button to dashboard
  - Command+H shortcut for alert history
  - Bell icon with active alert indicator

### Changed
- Integrated alert history with AlertEngine
- Multi-device alert tracking
- Improved alert state management
- Enhanced settings UI with silence status

### Fixed
- Compiler warnings cleanup
- Unused variable removal
- Code quality improvements

## [1.1.0] - 2026-01-XX

### Added
- **Multi-Device Monitoring**
  - Automatic device discovery on local network
  - Device manager UI (⌘+D)
  - Unified dashboard for all devices
  - Card/List view modes
  - Real-time data synchronization

- **Device Registry**
  - Persistent device storage
  - Enable/disable devices
  - Device status tracking (online/offline)
  - Manual device addition

- **Remote Metrics Collection**
  - HTTP API integration
  - 5-second update interval
  - Automatic retry on failure

### Changed
- Dashboard redesigned for multi-device
- Improved settings UI
- Better device identification

## [1.0.2] - 2026-01-XX

### Added
- **Dark Mode**
  - Light/Dark theme support
  - Theme picker in settings
  - Persistent theme selection
  - System appearance integration

- **Theme Manager**
  - Real-time theme switching
  - NSApp.appearance control

## [1.0.0] - 2026-01-XX

### Added
- **Core Monitoring**
  - CPU usage monitoring
  - Memory usage tracking
  - Disk usage percentage
  - Network connectivity status

- **Alert System**
  - Configurable thresholds
  - Sound alerts
  - Alert throttling
  - Consecutive sample validation

- **Dashboard**
  - Real-time metrics display
  - Visual indicators
  - Minimal charts

- **Settings**
  - Refresh interval (5s/10s/30s)
  - Alert thresholds
  - Network probe target

- **HTTP API**
  - JSON metrics endpoint
  - Token-based authentication
  - CORS support for LAN access

### Architecture
- MVVM pattern
- ObservableObject for reactive UI
- Singleton managers
- UserDefaults for persistence

---

## Version Format

- **Major.Minor.Patch** (e.g., 1.2.0)
- Major: Breaking changes or major features
- Minor: New features, backwards compatible
- Patch: Bug fixes, minor improvements

## Release Notes

For detailed release information, see [Releases](https://github.com/SepineTam/MacServerMonitor/releases).
