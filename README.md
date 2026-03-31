# ATS Exporter

[![License](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Go Report](https://goreportcard.com/badge/github.com/lwnmengjing/ats-exporter)](https://goreportcard.com/report/github.com/lwnmengjing/ats-exporter)
[![Go Version](https://img.shields.io/badge/Go-1.24+-00ADD8.svg)](https://go.dev/dl/)
[![Release](https://img.shields.io/github/v/release/lwnmengjing/ats-exporter?include_prereleases)](https://github.com/lwnmengjing/ats-exporter/releases)
[![CI](https://github.com/lwnmengjing/ats-exporter/workflows/CI/badge.svg)](https://github.com/lwnmengjing/ats-exporter/actions)

A Prometheus exporter for Apache Traffic Server metrics.

## Features

- Exports comprehensive ATS metrics to Prometheus format
- Modern Go 1.24+ implementation
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
| `--ats.method` | `traffic_ctl` | Method to fetch ATS metrics: `http` or `traffic_ctl` |
| `--ats.url` | `http://localhost:80/_stats` | ATS stats endpoint URL (used when `method=http`) |
| `--ats.traffic_ctl.path` | `traffic_ctl` | Path to traffic_ctl binary (used when `method=traffic_ctl`) |
| `--ats.timeout` | `10s` | Timeout for ATS scraping |
| `--log.level` | `info` | Log level (debug, info, warn, error) |
| `--version` | `false` | Show version information |

## Methods to Fetch Metrics

The exporter supports two methods to fetch ATS metrics:

### traffic_ctl Method (Recommended)

Uses the `traffic_ctl metric match` command to fetch metrics. This is more secure as it doesn't require exposing the HTTP stats endpoint.

```bash
# Run with traffic_ctl method (default)
./ats-exporter --ats.method=traffic_ctl

# Specify custom traffic_ctl path
./ats-exporter --ats.method=traffic_ctl --ats.traffic_ctl.path=/usr/bin/traffic_ctl
```

**Requirements:**
- `traffic_ctl` must be installed and accessible
- The exporter must run on the same host as ATS (or have access to traffic_ctl)

### HTTP Method

Uses the ATS HTTP stats endpoint (`/_stats`) to fetch metrics.

```bash
# Run with HTTP method
./ats-exporter --ats.method=http --ats.url=http://localhost:80/_stats
```

**Requirements:**
- ATS stats endpoint must be enabled in `records.config`
- Suitable for remote monitoring

## Docker

```bash
# Build Docker image
docker build -t ats-exporter:latest .

# Run container with traffic_ctl method (needs access to host's traffic_ctl)
docker run -p 9090:9090 \
    -v /usr/bin/traffic_ctl:/usr/bin/traffic_ctl:ro \
    ats-exporter:latest --ats.method=traffic_ctl

# Run container with HTTP method (for remote monitoring)
docker run -p 9090:9090 ats-exporter:latest \
    --ats.method=http --ats.url=http://ats-server:80/_stats
```

## Prometheus Configuration

Add the following to your `prometheus.yml`:

```yaml
scrape_configs:
  - job_name: 'ats'
    static_configs:
      - targets: ['localhost:9090']
```

## Deployment

### Quick Install

Download and run the install script:

```bash
curl -sSLo install.sh https://raw.githubusercontent.com/lwnmengjing/ats-exporter/main/install.sh
chmod +x install.sh
# Optional: review install.sh before running
sudo ./install.sh install
```

### Install Options

```bash
# Install specific version
sudo ./install.sh install --version v1.0.0

# Install with custom ATS URL and listen port
sudo ./install.sh install --ats-url http://localhost:8080/_stats --listen-address :9150

# Install with debug logging
sudo ./install.sh install --log-level debug
```

### Configuration

After installation, you can configure the exporter by editing the environment file:

```bash
sudo vi /etc/ats-exporter/ats-exporter.env
```

Configuration options:

| Variable | Default | Description |
|----------|---------|-------------|
| `LISTEN_ADDRESS` | `:9090` | Address to listen on |
| `METRICS_PATH` | `/metrics` | Path for metrics endpoint |
| `ATS_URL` | `http://localhost:80/_stats` | ATS stats endpoint URL |
| `ATS_TIMEOUT` | `10s` | Timeout for ATS scraping |
| `LOG_LEVEL` | `info` | Log level (debug, info, warn, error) |
| `ATS_METHOD` | `http` | How to collect ATS stats (`http` or `traffic_ctl`) |
| `TRAFFIC_CTL_PATH` | `/usr/bin/traffic_ctl` | Path to the `traffic_ctl` binary (used when `ATS_METHOD=traffic_ctl`) |

After modifying the configuration, restart the service:

```bash
sudo systemctl restart ats-exporter
```

### Service Management

```bash
# Check service status
sudo systemctl status ats-exporter

# Start/Stop/Restart service
sudo systemctl start ats-exporter
sudo systemctl stop ats-exporter
sudo systemctl restart ats-exporter

# View logs
sudo journalctl -u ats-exporter -f

# Enable/Disable service on boot
sudo systemctl enable ats-exporter
sudo systemctl disable ats-exporter
```

### Upgrade

```bash
# Upgrade to latest version
sudo ./install.sh upgrade

# Upgrade to specific version
sudo ./install.sh upgrade --version v1.1.0
```

### Uninstall

```bash
sudo ./install.sh uninstall
```

### Manual Installation

If you prefer manual installation:

```bash
# Download the binary
VERSION=v1.0.0
curl -sL https://github.com/lwnmengjing/ats-exporter/releases/download/${VERSION}/ats-exporter-${VERSION}-linux-amd64.tar.gz | tar xz

# Move to bin directory
sudo mv ats-exporter /usr/local/bin/
sudo chmod +x /usr/local/bin/ats-exporter

# Create user
sudo useradd --system --no-create-home --shell /bin/false ats-exporter

# Create systemd service
sudo cat > /etc/systemd/system/ats-exporter.service << 'EOF'
[Unit]
Description=Apache Traffic Server Exporter
After=network.target

[Service]
Type=simple
User=ats-exporter
Group=ats-exporter
ExecStart=/usr/local/bin/ats-exporter \
    --web.listen-address=:9090 \
    --web.telemetry-path=/metrics \
    --ats.url=http://localhost:80/_stats
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# Enable and start
sudo systemctl daemon-reload
sudo systemctl enable ats-exporter
sudo systemctl start ats-exporter
```

## ATS Configuration

The exporter supports two methods to collect metrics from Apache Traffic Server.

### Method 1: traffic_ctl (Recommended)

This method uses the `traffic_ctl metric match` command and doesn't require any additional ATS configuration. It's more secure as it doesn't expose a HTTP endpoint.

**Prerequisites:**
- `traffic_ctl` must be installed (comes with ATS installation)
- The exporter must run on the same host as ATS or have access to the traffic_ctl binary

**No additional ATS configuration required.** Simply run:

```bash
# Default method (traffic_ctl)
./ats-exporter

# Or explicitly
./ats-exporter --ats.method=traffic_ctl
```

### Method 2: HTTP Stats Endpoint

If you prefer to use the HTTP endpoint or need remote monitoring, configure ATS to expose the stats endpoint.

#### Enable Stats Endpoint

Add the following to your `records.config` (typically located at `/etc/trafficserver/records.config`):

```
# Enable HTTP statistics
CONFIG proxy.config.http.enable_http_stats INT 1
CONFIG proxy.config.http.record_slow_requests INT 1

# Enable stats endpoint (JSON format)
CONFIG proxy.config.http_ui_enabled INT 1
```

#### Stats Endpoint URL

By default, ATS exposes stats at:
- **URL**: `http://localhost:80/_stats`
- **Port**: ATS proxy port (default 80 or 8080)

You can verify the endpoint is working:

```bash
curl http://localhost:80/_stats
```

Should return JSON with metrics like:
```json
{
  "global": {
    "proxy.process.http.total_incoming_connections": 123,
    "proxy.process.http.current_client_connections": 5,
    ...
  }
}
```

### Common ATS Stats Configuration

For comprehensive metrics collection, consider enabling:

```
# HTTP statistics
CONFIG proxy.config.http.enable_http_stats INT 1
CONFIG proxy.config.http.record_slow_requests INT 1
CONFIG proxy.config.http.record_cop_transactions INT 1

# Cache statistics
CONFIG proxy.config.cache.enable_read_while_writer INT 1

# DNS/HostDB statistics (enabled by default)
CONFIG proxy.config.hostdb.enabled INT 1

# Network statistics
CONFIG proxy.config.net.enable_stats INT 1
```

### Custom Stats Port

If ATS is running on a different port, update the exporter configuration:

```bash
# In /etc/ats-exporter/ats-exporter.env
ATS_URL=http://localhost:8080/_stats
```

Or pass via command line:
```bash
./ats-exporter --ats.url=http://your-ats-server:8080/_stats
```

### ATS Documentation

For more details on ATS configuration, see:
- [ATS Administration Guide](https://docs.trafficserver.apache.org/en/latest/admin-guide/index.en.html)
- [TS Records Config](https://docs.trafficserver.apache.org/en/latest/admin-guide/files/records.config.en.html)

## License

MIT License