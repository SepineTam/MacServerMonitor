# Constraints

This document defines **hard constraints** for the MacServerMonitor project.
All implementations MUST strictly follow these rules.

Violating any constraint below should be considered a bug.

---

## Platform Constraints

- This project is **macOS only**.
- Do NOT add support for Windows, Linux, or cross-platform abstractions.
- Do NOT introduce platform-conditional branches for other operating systems.
- Target macOS 13+.

---

## Permission Constraints

The application MUST NOT require or request any of the following:

- Administrator (root) privileges
- Accessibility permissions
- Full Disk Access
- Screen recording permissions
- System extensions, kernel extensions, or drivers

The app must run entirely in **user space**.

---

## Execution Constraints

- Do NOT execute external system commands.
  - Forbidden examples:
    - `top`
    - `vm_stat`
    - `ps`
    - `df`
    - `netstat`
    - `ifconfig`
    - `ping` via shell
- Do NOT use `Process`, `NSTask`, or any shell-based execution.
- All system metrics must be collected via **native macOS system APIs**.

---

## Performance & Energy Constraints

- The application is expected to run for long periods.
- CPU usage should remain minimal under normal conditions.
- Sampling frequency must strictly follow the configured refresh interval.
- Remote HTTP requests MUST NOT trigger additional sampling.
- Avoid unnecessary allocations, background threads, or high-frequency timers.
- No busy loops, no polling faster than the configured interval.

---

## Architecture Constraints

- Core logic MUST be decoupled from UI.
- UI code MUST NOT directly collect system metrics.
- Sampling, alert evaluation, UI rendering, and HTTP serving must be separate modules.
- Core modules MUST NOT depend on UI or HTTP server modules.
- No cyclic dependencies between modules.

---

## State & Storage Constraints

- Short-term history should be stored **in memory only** (ring buffers).
- Persistent storage is limited to configuration/settings.
- Do NOT introduce databases, files, or logging systems for metric history in v1.

---

## Alerting Constraints

- Alerts must follow a state-based model:
  - normal
  - alerting
  - throttled
- Alert sounds must:
  - Trigger immediately on first violation
  - Be throttled according to configuration
  - Stop automatically when the system recovers
- Alerts must NOT loop continuously or block the main thread.

---

## Networking Constraints

- The built-in HTTP server is **read-only**.
- No remote control, command execution, or configuration mutation via HTTP.
- Authentication must be token-based (Bearer token).
- The server is intended for **LAN usage only**.
- Do NOT expose WebSocket, gRPC, or long-lived streaming connections in v1.

---

## Dependency Constraints

- Prefer system frameworks and standard libraries.
- Avoid heavy third-party dependencies.
- Do NOT introduce Electron, Tauri, or web-based UI frameworks.
- Do NOT introduce cross-platform runtime layers.

---

## Scope Constraints (v1)

The following are explicitly **out of scope** for v1 and MUST NOT be implemented:

- Temperature monitoring
- Fan speed monitoring
- GPU utilization
- Per-process network traffic analysis
- Long-term historical storage
- Cloud integration
- User accounts or authentication systems

---

## Implementation Philosophy

When in doubt:
- Choose the simpler solution.
- Choose the lower-energy solution.
- Choose clarity over cleverness.
- Do not add features unless explicitly specified in `spec.md`.

If a feature or behavior is not described in the documentation, it should NOT be implemented.

