# ATS Exporter

A Prometheus exporter for Apache Traffic Server metrics.

## Features

- Exports comprehensive ATS metrics to Prometheus format
- Modern Go 1.25+ implementation
- Configurable via command-line flags
- Docker support
- Graceful shutdown handling

## Metrics

The exporter collects the following types of metrics:

- HTTP request/response statistics (counts, sizes, timings)
- Cache statistics (hits, misses, hit ratios, bytes)
- Network statistics (connections, bytes transferred)
- DNS/HostDB statistics (lookups, hits, timings)
- Log statistics (bytes written, events)
- Cluster statistics (nodes, connections)

## Building

```bash
# Build locally
make build

# Build with version info
make build VERSION=1.0.0 REVISION=$(git rev-parse --short HEAD) BRANCH=$(git branch --show-current)
```

## Running

```bash
# Run with default settings
./ats-exporter

# Run with custom ATS URL
./ats-exporter --ats.url=http://localhost:8080/_stats

# Run with debug logging
./ats-exporter --log.level=debug

# Show version
./ats-exporter --version
```

## Command Line Options

| Flag | Default | Description |
|------|---------|-------------|
| `--web.listen-address` | `:9090` | Address to listen on |
| `--web.telemetry-path` | `/metrics` | Path for metrics endpoint |
| `--ats.url` | `http://localhost:80/_stats` | ATS stats endpoint URL |
| `--ats.timeout` | `10s` | Timeout for ATS scraping |
| `--log.level` | `info` | Log level (debug, info, warn, error) |
| `--version` | `false` | Show version information |

## Docker

```bash
# Build Docker image
docker build -t ats-exporter:latest .

# Run container
docker run -p 9090:9090 ats-exporter:latest --ats.url=http://ats-server:80/_stats
```

## Prometheus Configuration

Add the following to your `prometheus.yml`:

```yaml
scrape_configs:
  - job_name: 'ats'
    static_configs:
      - targets: ['localhost:9090']
```

## ATS Configuration

Make sure your Apache Traffic Server has the stats endpoint enabled by adding the following to `records.config`:

```
CONFIG proxy.config.http.record_slow_requests INT 1
CONFIG proxy.config.http.enable_http_stats INT 1
```

## License

MIT License