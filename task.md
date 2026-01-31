# Tasks (v1)

This task list is designed for AI-assisted implementation.
Complete tasks strictly in order. Do not skip.
Each task should be implemented as a small, reviewable change.

Scope must follow:
- docs/spec.md
- docs/architecture.md
- docs/api.md
- docs/constraints.md

---

## 0. Repo Setup

- [ ] T0.1 Create `docs/` structure and add baseline docs
  - Deliverables:
    - docs/spec.md
    - docs/architecture.md
    - docs/api.md
    - docs/constraints.md
    - docs/tasks.md (this file)
  - Acceptance:
    - All files exist and contain the agreed content
    - README links to these docs
    - README clearly states "macOS only"

---

## 1. Project Skeleton (macOS app)

- [ ] T1.1 Create a macOS SwiftUI app project skeleton
  - Deliverables:
    - A buildable macOS app target
    - Basic app entry point
  - Acceptance:
    - Project builds and runs on macOS
    - Shows an empty window (placeholder)

- [ ] T1.2 Implement the proposed folder/module layout (logical)
  - Deliverables:
    - Sources/Core/...
    - Sources/UI/...
    - Sources/Remote/...
  - Acceptance:
    - Code compiles
    - No cyclic imports
    - Core does not import UI/Remote

---

## 2. Settings (typed wrapper)

- [ ] T2.1 Define `AppSettings` model + `SettingsStore` wrapper over UserDefaults
  - Deliverables:
    - Keys exactly as defined in docs/spec.md
    - Typed getters/setters with defaults
  - Acceptance:
    - Changing a setting updates values in memory and persists via UserDefaults
    - No hard-coded magic numbers outside SettingsStore

- [ ] T2.2 Add Settings UI (minimal) for refresh + thresholds + server config
  - Deliverables:
    - SettingsView with controls for:
      - refresh interval (5/10/30)
      - memory/cpu/disk thresholds
      - consecutive samples N
      - alert repeat minutes
      - network probe target
      - http enabled, port, token (read-only display + regenerate button optional)
  - Acceptance:
    - Changing controls updates SettingsStore
    - UI is usable but minimal (no fancy styling required)

---

## 3. Metrics Models & Store

- [ ] T3.1 Define metrics DTO/models per docs/api.md and docs/spec.md
  - Deliverables:
    - MemoryMetrics, CpuMetrics, DiskMetrics, NetworkMetrics
    - Snapshot model including timestamp
  - Acceptance:
    - All required fields exist with correct types/units
    - JSON encoding schema matches docs/api.md

- [ ] T3.2 Implement `MetricStore` (latest snapshot + ring buffers)
  - Deliverables:
    - Latest snapshot storage
    - In-memory ring buffers for:
      - memory_used_percent
      - cpu_usage_percent
      - disk_used_percent
      - network_status
    - Configurable max points, default 60
  - Acceptance:
    - Adding new samples updates latest snapshot
    - Series arrays always return up to N points, in chronological order
    - No disk persistence for series

---

## 4. Samplers (native APIs only)

- [ ] T4.1 Implement `DiskSampler` (root "/" used percent)
  - Deliverables:
    - DiskMetrics.used_percent
  - Acceptance:
    - Value is 0-100 and stable
    - Uses native APIs (no shell commands)

- [ ] T4.2 Implement `CpuSampler` (usage percent + load averages)
  - Deliverables:
    - CpuMetrics.usage_percent
    - CpuMetrics.load1/load5/load15
  - Acceptance:
    - usage_percent updates across samples (not always 0)
    - load averages are available
    - Uses native APIs only

- [ ] T4.3 Implement `MemorySampler`
  - Deliverables:
    - MemoryMetrics.total_bytes, used_bytes, used_percent
    - MemoryMetrics.compressed_bytes (if available)
    - MemoryMetrics.swap_used_bytes (if available)
  - Acceptance:
    - Values are non-negative and plausible
    - used_percent matches used_bytes/total_bytes
    - Uses native APIs only

- [ ] T4.4 Implement `NetworkSampler` (connectivity)
  - Deliverables:
    - NetworkMetrics.status ("normal"|"down")
    - NetworkMetrics.last_ok_timestamp
    - Probe target support: "gateway" or hostname/IP
    - 2 consecutive failures -> down
  - Acceptance:
    - Network status flips if probe target is unreachable
    - Uses native APIs (no shell ping)

---

## 5. Sampling Orchestrator

- [ ] T5.1 Implement `SamplingCoordinator`
  - Deliverables:
    - A timer-based sampler that runs at refresh_interval_seconds
    - Collects metrics from all samplers
    - Writes snapshot + series to MetricStore
  - Acceptance:
    - Interval changes apply without restart
    - No extra sampling triggered by remote requests
    - No high-frequency busy loops

---

## 6. Alert Engine + Sound

- [ ] T6.1 Implement `AlertEngine` with state model
  - Deliverables:
    - Evaluates thresholds for memory/cpu/disk with N consecutive samples
    - Evaluates network down status
    - Produces alert state per type
    - Implements throttling: repeat sound every X minutes while alerting
  - Acceptance:
    - First violation triggers alerting
    - Sustained alert triggers repeated reminders at configured interval
    - Recovery clears alert state

- [ ] T6.2 Implement `SoundPlayer` using system sounds (macOS)
  - Deliverables:
    - Plays default system alert sound
    - Non-blocking
  - Acceptance:
    - Sound plays on alert trigger
    - Sound does not loop continuously
    - No UI freeze

- [ ] T6.3 Wire AlertEngine -> SoundPlayer
  - Acceptance:
    - End-to-end alert pipeline works

---

## 7. Dashboard UI (monitoring panel)

- [ ] T7.1 Implement `DashboardView` showing current snapshot
  - Deliverables:
    - Memory card (used %, used bytes, swap if available)
    - CPU card (usage %, load averages)
    - Disk card (used %)
    - Network card (status + last ok time)
  - Acceptance:
    - Values update on refresh interval
    - Clear visual status for alerting (e.g., red outline)

- [ ] T7.2 Add lightweight trend display (simple)
  - Deliverables:
    - Sparkline or minimal chart for 3 series:
      - memory_used_percent
      - cpu_usage_percent
      - disk_used_percent
  - Acceptance:
    - Trend updates correctly with ring buffer
    - No expensive animation loops

---

## 8. Remote HTTP Server (LAN)

- [ ] T8.1 Implement `HttpServer` skeleton (read-only)
  - Deliverables:
    - Start/stop based on settings
    - Listens on configured port
    - Token auth (Bearer)
  - Acceptance:
    - Rejects missing/invalid token with 401
    - Runs without privileged permissions

- [ ] T8.2 Implement `GET /api/v1/status`
  - Deliverables:
    - JSON response matches docs/api.md
  - Acceptance:
    - Schema matches and is parseable

- [ ] T8.3 Implement `GET /api/v1/series`
  - Deliverables:
    - Query param `points` respected with caps (default 60, max 300)
  - Acceptance:
    - Returns correct length and order

- [ ] T8.4 Implement `GET /api/v1/config`
  - Deliverables:
    - Returns non-sensitive config summary
  - Acceptance:
    - Does not expose token or private info

---

## 9. Hardening & Acceptance

- [ ] T9.1 Add basic error handling + safe defaults
  - Acceptance:
    - No crash if a sampler field is unavailable (use 0 or null as defined)

- [ ] T9.2 Validate constraints compliance
  - Acceptance:
    - No shell command execution
    - No privileged permissions
    - No OS portability work

- [ ] T9.3 Minimal manual test checklist (docs)
  - Deliverables:
    - docs/test-checklist.md
  - Acceptance:
    - Contains steps to validate:
      - refresh interval changes
      - threshold alerts
      - alert throttling
      - http endpoints
      - token auth

---

## Notes for AI Implementation

- Do not implement anything not requested in spec.
- Prefer simple code and clear names.
- Keep changes small and incremental.
- Avoid third-party dependencies unless absolutely necessary.

