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

Make sure your Apache Traffic Server has the stats endpoint enabled by adding the following to `records.config`:

```
CONFIG proxy.config.http.record_slow_requests INT 1
CONFIG proxy.config.http.enable_http_stats INT 1
```

## License

MIT License