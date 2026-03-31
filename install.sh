#!/bin/bash

set -e

BINARY_NAME="ats-exporter"
SERVICE_NAME="ats-exporter"
INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="/etc/ats-exporter"
SERVICE_USER="ats-exporter"
SERVICE_GROUP="ats-exporter"

DEFAULT_LISTEN_ADDRESS=":9090"
DEFAULT_METRICS_PATH="/metrics"
DEFAULT_ATS_URL="http://localhost:80/_stats"
DEFAULT_ATS_TIMEOUT="10s"
DEFAULT_LOG_LEVEL="info"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "Please run as root"
        exit 1
    fi
}

detect_arch() {
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)
            echo "amd64"
            ;;
        aarch64)
            echo "arm64"
            ;;
        armv7l)
            echo "arm"
            ;;
        *)
            log_error "Unsupported architecture: $ARCH"
            exit 1
            ;;
    esac
}

detect_os() {
    OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    case $OS in
        linux)
            echo "linux"
            ;;
        darwin)
            echo "darwin"
            ;;
        *)
            log_error "Unsupported OS: $OS"
            exit 1
            ;;
    esac
}

get_latest_version() {
    local repo="lwnmengjing/ats-exporter"
    local version=$(curl -s "https://api.github.com/repos/${repo}/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    if [ -z "$version" ]; then
        log_error "Failed to get latest version"
        exit 1
    fi
    echo "$version"
}

download_binary() {
    local version="$1"
    local os="$2"
    local arch="$3"
    local repo="lwnmengjing/ats-exporter"
    local url="https://github.com/${repo}/releases/download/${version}/ats-exporter-${version}-${os}-${arch}.tar.gz"
    
    log_info "Downloading ${BINARY_NAME} ${version} for ${os}-${arch}..."
    
    local tmp_dir=$(mktemp -d)
    local tmp_file="${tmp_dir}/${BINARY_NAME}.tar.gz"
    
    if ! curl -sL -o "$tmp_file" "$url"; then
        log_error "Failed to download binary from $url"
        rm -rf "$tmp_dir"
        exit 1
    fi
    
    tar -xzf "$tmp_file" -C "$tmp_dir"
    
    mv "${tmp_dir}/${BINARY_NAME}" "${INSTALL_DIR}/${BINARY_NAME}"
    chmod +x "${INSTALL_DIR}/${BINARY_NAME}"
    
    rm -rf "$tmp_dir"
    
    log_info "Binary installed to ${INSTALL_DIR}/${BINARY_NAME}"
}

create_user() {
    if ! id -u "${SERVICE_USER}" >/dev/null 2>&1; then
        log_info "Creating user ${SERVICE_USER}..."
        useradd --system --no-create-home --shell /bin/false "${SERVICE_USER}"
    fi
}

create_config_dir() {
    if [ ! -d "${CONFIG_DIR}" ]; then
        log_info "Creating config directory ${CONFIG_DIR}..."
        mkdir -p "${CONFIG_DIR}"
    fi
    chown -R "${SERVICE_USER}:${SERVICE_GROUP}" "${CONFIG_DIR}"
}

create_systemd_service() {
    log_info "Creating systemd service..."
    
    local service_file="/etc/systemd/system/${SERVICE_NAME}.service"
    
    cat > "$service_file" << EOF
[Unit]
Description=Apache Traffic Server Exporter
Documentation=https://github.com/lwnmengjing/ats-exporter
After=network.target

[Service]
Type=simple
User=${SERVICE_USER}
Group=${SERVICE_GROUP}
ExecStart=${INSTALL_DIR}/${BINARY_NAME} \
    --web.listen-address=${LISTEN_ADDRESS:-$DEFAULT_LISTEN_ADDRESS} \
    --web.telemetry-path=${METRICS_PATH:-$DEFAULT_METRICS_PATH} \
    --ats.url=${ATS_URL:-$DEFAULT_ATS_URL} \
    --ats.timeout=${ATS_TIMEOUT:-$DEFAULT_ATS_TIMEOUT} \
    --log.level=${LOG_LEVEL:-$DEFAULT_LOG_LEVEL}
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    log_info "Systemd service created at ${service_file}"
}

enable_service() {
    log_info "Enabling ${SERVICE_NAME} service..."
    systemctl enable "${SERVICE_NAME}"
}

start_service() {
    log_info "Starting ${SERVICE_NAME} service..."
    systemctl start "${SERVICE_NAME}"
    
    sleep 2
    
    if systemctl is-active --quiet "${SERVICE_NAME}"; then
        log_info "${SERVICE_NAME} service is running"
    else
        log_error "${SERVICE_NAME} service failed to start"
        journalctl -u "${SERVICE_NAME}" --no-pager -n 20
        exit 1
    fi
}

show_status() {
    echo ""
    log_info "Installation complete!"
    echo ""
    echo "Binary: ${INSTALL_DIR}/${BINARY_NAME}"
    echo "Service: ${SERVICE_NAME}"
    echo ""
    echo "Configuration (via environment variables or service file):"
    echo "  LISTEN_ADDRESS: ${LISTEN_ADDRESS:-$DEFAULT_LISTEN_ADDRESS}"
    echo "  METRICS_PATH:   ${METRICS_PATH:-$DEFAULT_METRICS_PATH}"
    echo "  ATS_URL:        ${ATS_URL:-$DEFAULT_ATS_URL}"
    echo "  ATS_TIMEOUT:    ${ATS_TIMEOUT:-$DEFAULT_ATS_TIMEOUT}"
    echo "  LOG_LEVEL:      ${LOG_LEVEL:-$DEFAULT_LOG_LEVEL}"
    echo ""
    echo "Useful commands:"
    echo "  sudo systemctl status ${SERVICE_NAME}   # Check service status"
    echo "  sudo systemctl restart ${SERVICE_NAME}  # Restart service"
    echo "  sudo journalctl -u ${SERVICE_NAME} -f    # View logs"
    echo ""
}

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --listen-address ADDRESS   Listen address (default: ${DEFAULT_LISTEN_ADDRESS})"
    echo "  --metrics-path PATH        Metrics path (default: ${DEFAULT_METRICS_PATH})"
    echo "  --ats-url URL              ATS stats URL (default: ${DEFAULT_ATS_URL})"
    echo "  --ats-timeout TIMEOUT       ATS timeout (default: ${DEFAULT_ATS_TIMEOUT})"
    echo "  --log-level LEVEL          Log level (default: ${DEFAULT_LOG_LEVEL})"
    echo "  --version VERSION          Version to install (default: latest)"
    echo "  --help                     Show this help message"
    echo ""
    echo "Environment variables:"
    echo "  LISTEN_ADDRESS, METRICS_PATH, ATS_URL, ATS_TIMEOUT, LOG_LEVEL"
}

main() {
    local version=""
    local os=$(detect_os)
    local arch=$(detect_arch)

    while [[ $# -gt 0 ]]; do
        case $1 in
            --listen-address)
                LISTEN_ADDRESS="$2"
                shift 2
                ;;
            --metrics-path)
                METRICS_PATH="$2"
                shift 2
                ;;
            --ats-url)
                ATS_URL="$2"
                shift 2
                ;;
            --ats-timeout)
                ATS_TIMEOUT="$2"
                shift 2
                ;;
            --log-level)
                LOG_LEVEL="$2"
                shift 2
                ;;
            --version)
                version="$2"
                shift 2
                ;;
            --help)
                usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done

    check_root

    if [ -z "$version" ]; then
        version=$(get_latest_version)
    fi

    log_info "Installing ${BINARY_NAME} ${version}..."

    download_binary "$version" "$os" "$arch"
    create_user
    create_config_dir
    create_systemd_service
    enable_service
    start_service
    show_status
}

main "$@"