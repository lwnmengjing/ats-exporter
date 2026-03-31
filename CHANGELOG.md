# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- CI workflow with lint, build, test, and docker jobs
- Release workflow for automated binary releases
- One-click installation script (`install.sh`) with systemd service support
- Deployment documentation

## [1.0.0] - 2026-03-31

### Added
- Initial release
- Prometheus exporter for Apache Traffic Server metrics
- HTTP request/response statistics (counts, sizes, timings)
- Cache statistics (hits, misses, hit ratios, bytes)
- Network statistics (connections, bytes transferred)
- DNS/HostDB statistics (lookups, hits, timings)
- Log statistics (bytes written, events)
- Cluster statistics (nodes, connections)
- Configurable via command-line flags
- Docker support
- Graceful shutdown handling
- Version information support

### Features
- Modern Go 1.24+ implementation
- Comprehensive ATS metrics collection
- Configurable listen address and metrics path
- Customizable ATS URL and timeout
- Multiple log levels (debug, info, warn, error)