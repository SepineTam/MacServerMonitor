# Architecture (macOS only)

## Module Boundaries
- Core (no UI)
  - Samplers: MemorySampler, CpuSampler, DiskSampler, NetworkSampler
  - MetricStore: latest snapshot + short-term ring buffers
  - AlertEngine: threshold evaluation + throttling + state
  - SettingsStore: typed settings wrapper over UserDefaults
- UI
  - DashboardView
  - SettingsView
  - ViewModels subscribe to MetricStore + AlertEngine
- Remote
  - HttpServer (read-only)
  - Auth middleware (Bearer token)

## Data Flow
Sampler -> MetricStore -> (UI, HttpServer)
MetricStore -> AlertEngine -> (UI, SoundPlayer)

## Dependency Rules
- UI depends on Core
- Remote depends on Core
- Core must NOT depend on UI/Remote
- No cyclic imports

## File Layout (suggested)
- Sources/
  - Core/
    - Samplers/
    - Store/
    - Alerts/
    - Settings/
    - Models/
  - UI/
  - Remote/

## Performance Constraints
- Sampling uses system APIs, no external command execution.
- No continuous high-frequency rendering.

