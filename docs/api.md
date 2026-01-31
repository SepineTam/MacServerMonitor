# HTTP API (LAN, macOS only)

## Auth
- Require header: Authorization: Bearer <token>
- If missing/invalid: 401

## Endpoints

### GET /api/v1/status
Response 200 (application/json):
{
  "timestamp": 0,
  "metrics": {
    "memory": { "total_bytes": 0, "used_bytes": 0, "used_percent": 0, "compressed_bytes": 0, "swap_used_bytes": 0 },
    "cpu": { "usage_percent": 0, "load1": 0, "load5": 0, "load15": 0 },
    "disk": { "used_percent": 0 },
    "network": { "status": "normal", "last_ok_timestamp": 0 }
  },
  "alerts": {
    "active": false,
    "items": [
      { "type": "memory", "status": "normal|alerting", "since_timestamp": 0, "next_sound_timestamp": 0 }
    ]
  }
}

### GET /api/v1/series
Query params:
- points=60 (default 60, max 300)
Response 200:
{
  "timestamp": 0,
  "series": {
    "memory_used_percent": [0,0,0],
    "cpu_usage_percent": [0,0,0],
    "disk_used_percent": [0,0,0],
    "network_status": ["normal","down"]
  }
}

### GET /api/v1/config
Response 200:
{
  "refresh_interval_seconds": 5,
  "thresholds": {
    "memory_percent": 85,
    "cpu_percent": 90,
    "disk_percent": 90
  },
  "network_probe_target": "gateway",
  "port": 17890
}

## Error format
- 4xx/5xx:
{
  "error": { "code": "string", "message": "string" }
}

