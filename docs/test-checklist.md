# Test Checklist (v1)

This document provides a manual testing checklist for validating the MacServerMonitor application.

## Prerequisites

- macOS 13+ system
- Xcode installed (for building)
- Local network access for HTTP server testing

## Build and Run

1. Build the project
   ```bash
   swift build
   ```
   - Expected: Build completes without errors
   - Expected: Executable created at `.build/debug/MacServerMonitor`

2. Run the application
   ```bash
   swift run
   ```
   - Expected: Application window opens
   - Expected: Dashboard displays metrics after a few seconds

## Dashboard UI Tests

### Metrics Display

- [ ] Memory card shows used percentage
- [ ] Memory card shows total and used bytes in readable format (GB/MB)
- [ ] CPU card shows usage percentage
- [ ] CPU card shows load averages (1m, 5m, 15m)
- [ ] Disk card shows used percentage
- [ ] Network card shows status (Normal/Down)
- [ ] Network card shows "Last OK" time when down

### Refresh Interval

- [ ] Open Settings
- [ ] Change refresh interval from 5s to 10s
- [ ] Close settings and observe footer
- [ ] Expected: Footer shows "Refresh: 10s"
- [ ] Expected: Metrics update every 10 seconds

### Alert Visual States

- [ ] Lower memory threshold to 10% in Settings
- [ ] Wait for 2 consecutive samples
- [ ] Expected: Memory card shows red border
- [ ] Restore threshold to default
- [ ] Expected: Red border disappears after 1 sample

## Settings Tests

### Threshold Changes

- [ ] Change memory threshold to 75%
- [ ] Change CPU threshold to 85%
- [ ] Change disk threshold to 90%
- [ ] Close and reopen settings
- [ ] Expected: All values are persisted

### Alert Behavior

- [ ] Change consecutive samples to 1
- [ ] Change alert repeat interval to 1 minute
- [ ] Close and reopen settings
- [ ] Expected: Values are persisted

### Network Settings

- [ ] Change probe target to "google.com"
- [ ] Close and reopen settings
- [ ] Expected: Value is persisted

### HTTP Server Settings

- [ ] Note the current token
- [ ] Change HTTP port to 17891
- [ ] Click "Regenerate" button
- [ ] Expected: New token is generated
- [ ] Disable HTTP server
- [ ] Close and reopen settings
- [ ] Expected: Settings persist

### Reset to Defaults

- [ ] Change several settings
- [ ] Click "Reset to Defaults"
- [ ] Expected: All settings return to default values
- [ ] Expected: Token is NOT reset

## Alert Tests

### Memory Alert

- [ ] Set memory threshold to 10%
- [ ] Wait 2 consecutive samples (10s if interval is 5s)
- [ ] Expected: System alert sound plays
- [ ] Expected: Memory card has red border
- [ ] Restore threshold to 85%
- [ ] Wait for 1 sample
- [ ] Expected: Red border disappears
- [ ] Expected: No sound plays on recovery

### CPU Alert

- [ ] Set CPU threshold to 10%
- [ ] Run CPU-intensive task (e.g., `yes > /dev/null`)
- [ ] Wait 2 consecutive samples
- [ ] Expected: Alert sound plays
- [ ] Expected: CPU card has red border
- [ ] Stop CPU-intensive task
- [ ] Restore threshold
- [ ] Expected: Alert clears

### Disk Alert

- [ ] Set disk threshold to 10%
- [ ] Wait 2 consecutive samples
- [ ] Expected: Alert triggers if disk > 10%
- [ ] Restore threshold

### Network Alert

- [ ] Set probe target to "192.0.2.1" (non-routable IP)
- [ ] Wait 2 consecutive samples
- [ ] Expected: Alert sound plays
- [ ] Expected: Network card shows "Down" status
- [ ] Expected: Network card has red border
- [ ] Restore probe target to "gateway"
- [ ] Wait 2 consecutive samples
- [ ] Expected: Alert clears

### Alert Throttling

- [ ] Set alert repeat interval to 1 minute
- [ ] Trigger a memory alert (threshold to 10%)
- [ ] Note the time of first alert sound
- [ ] Wait 1 minute
- [ ] Expected: Second alert sound plays
- [ ] Wait another minute
- [ ] Expected: Third alert sound plays
- [ ] Restore threshold

## HTTP API Tests

### Start HTTP Server

1. Check the token in Settings
2. Ensure HTTP server is enabled
3. Note the port (default 17891)

### Authentication Tests

- [ ] Test without token
  ```bash
  curl http://localhost:17891/api/v1/status
  ```
  Expected: 401 Unauthorized

- [ ] Test with invalid token
  ```bash
  curl -H "Authorization: Bearer wrong" http://localhost:17891/api/v1/status
  ```
  Expected: 401 Unauthorized

- [ ] Test with valid token
  ```bash
  curl -H "Authorization: Bearer YOUR_TOKEN" http://localhost:17891/api/v1/status
  ```
  Expected: 200 OK with JSON response

### Status Endpoint

```bash
curl -H "Authorization: Bearer YOUR_TOKEN" http://localhost:17891/api/v1/status
```

Verify:
- [ ] Response is valid JSON
- [ ] Contains `timestamp` field
- [ ] Contains `metrics.memory` with `total_bytes`, `used_bytes`, `used_percent`
- [ ] Contains `metrics.cpu` with `usage_percent`, `load1`, `load5`, `load15`
- [ ] Contains `metrics.disk` with `used_percent`
- [ ] Contains `metrics.network` with `status` ("normal" or "down"), `last_ok_timestamp`
- [ ] Contains `alerts.active` (boolean)
- [ ] Contains `alerts.items` array with `type`, `status`, `since_timestamp`, `next_sound_timestamp`

### Series Endpoint

```bash
curl -H "Authorization: Bearer YOUR_TOKEN" "http://localhost:17891/api/v1/series?points=10"
```

Verify:
- [ ] Response is valid JSON
- [ ] Contains `timestamp` field
- [ ] Contains `series.memory_used_percent` array with 10 elements
- [ ] Contains `series.cpu_usage_percent` array with 10 elements
- [ ] Contains `series.disk_used_percent` array with 10 elements
- [ ] Contains `series.network_status` array with 10 elements

Test query params:
- [ ] Request with `points=300` - expect 300 data points
- [ ] Request with `points=500` - expect max 300 data points (capped)
- [ ] Request without `points` - expect default 60 data points

### Config Endpoint

```bash
curl -H "Authorization: Bearer YOUR_TOKEN" http://localhost:17891/api/v1/config
```

Verify:
- [ ] Response is valid JSON
- [ ] Contains `refresh_interval_seconds`
- [ ] Contains `thresholds.memory_percent`, `thresholds.cpu_percent`, `thresholds.disk_percent`
- [ ] Contains `network_probe_target`
- [ ] Contains `port`
- [ ] Does NOT contain token or sensitive information

### 404 Test

```bash
curl -H "Authorization: Bearer YOUR_TOKEN" http://localhost:17891/api/v1/invalid
```
Expected: 404 Not Found

## Constraints Compliance

### Platform

- [ ] Application only builds on macOS
- [ ] Application uses macOS-specific APIs (NWPathMonitor, host_processor_info, etc.)

### Permissions

- [ ] Application runs without sudo/admin
- [ ] Application does not request Accessibility permissions
- [ ] Application does not request Full Disk Access
- [ ] Application runs in user space only

### No Shell Commands

- [ ] Codebase does not contain `Process`, `NSTask`, or `shell` commands
- [ ] All metrics use native APIs (URLResourceKey, host_statistics64, etc.)

### Performance

- [ ] Application CPU usage is minimal at idle
- [ ] Sampling respects configured interval (verify with timestamps)
- [ ] No busy loops detected (check Activity Monitor)

### Architecture

- [ ] Core module does not import UI or Remote
- [ ] UI module depends only on Core
- [ ] Remote module depends only on Core
- [ ] No cyclic dependencies

## Clean Up

After testing:

1. Reset all settings to defaults in Settings panel
2. Quit the application
3. Optionally delete build artifacts:
   ```bash
   swift package clean
   ```
