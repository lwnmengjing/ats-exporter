#!/bin/bash

set -e

BINARY_NAME="ats-exporter"
SERVICE_NAME="ats-exporter"
INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="/etc/ats-exporter"
SERVICE_USER="ats-exporter"
SERVICE_GROUP="ats-exporter"
REPO="lwnmengjing/ats-exporter"

DEFAULT_LISTEN_ADDRESS=":9090"
DEFAULT_METRICS_PATH="/metrics"
DEFAULT_ATS_URL="http://localhost:80/_stats"
DEFAULT_ATS_TIMEOUT="10s"
DEFAULT_LOG_LEVEL="info"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "Please run as root (use sudo)"
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
    local version=$(curl -sfL "https://api.github.com/repos/${REPO}/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    if [ -z "$version" ]; then
        log_error "Failed to get latest version"
        exit 1
    fi
    echo "$version"
}

check_installed() {
    if [ -f "${INSTALL_DIR}/${BINARY_NAME}" ]; then
        return 0
    fi
    return 1
}

get_installed_version() {
    if check_installed; then
        ${INSTALL_DIR}/${BINARY_NAME} --version 2>/dev/null | grep "Version:" | awk '{print $2}' || echo "unknown"
    else
        echo "not installed"
    fi
}

download_binary() {
    local version="$1"
    local os="$2"
    local arch="$3"
    local url="https://github.com/${REPO}/releases/download/${version}/ats-exporter-${version}-${os}-${arch}.tar.gz"
    
    log_step "Downloading ${BINARY_NAME} ${version} for ${os}-${arch}..."
    
    local tmp_dir=$(mktemp -d)
    local tmp_file="${tmp_dir}/${BINARY_NAME}.tar.gz"
    
    if ! curl -sfL -o "$tmp_file" "$url"; then
        log_error "Failed to download binary from $url"
        rm -rf "$tmp_dir"
        exit 1
    fi
    
    if ! tar -xzf "$tmp_file" -C "$tmp_dir"; then
        log_error "Failed to extract archive"
        rm -rf "$tmp_dir"
        exit 1
    fi
    
    if [ -f "${INSTALL_DIR}/${BINARY_NAME}" ]; then
        log_info "Removing old binary..."
        rm -f "${INSTALL_DIR}/${BINARY_NAME}"
    fi
    
    mv "${tmp_dir}/${BINARY_NAME}" "${INSTALL_DIR}/${BINARY_NAME}"
    chmod +x "${INSTALL_DIR}/${BINARY_NAME}"
    
    rm -rf "$tmp_dir"
    
    log_info "Binary installed to ${INSTALL_DIR}/${BINARY_NAME}"
}

create_user() {
    if ! id -u "${SERVICE_USER}" >/dev/null 2>&1; then
        log_step "Creating user ${SERVICE_USER}..."
        useradd --system --no-create-home --shell /bin/false "${SERVICE_USER}"
    fi
}

create_config_dir() {
    if [ ! -d "${CONFIG_DIR}" ]; then
        log_step "Creating config directory ${CONFIG_DIR}..."
        mkdir -p "${CONFIG_DIR}"
    fi
    chown -R "${SERVICE_USER}:${SERVICE_GROUP}" "${CONFIG_DIR}"
}

create_env_file() {
    local env_file="${CONFIG_DIR}/${BINARY_NAME}.env"
    
    if [ ! -f "$env_file" ]; then
        log_step "Creating environment file ${env_file}..."
        cat > "$env_file" << EOF
# ATS Exporter Configuration
# Uncomment and modify as needed

# LISTEN_ADDRESS=${DEFAULT_LISTEN_ADDRESS}
# METRICS_PATH=${DEFAULT_METRICS_PATH}
# ATS_URL=${DEFAULT_ATS_URL}
# ATS_TIMEOUT=${DEFAULT_ATS_TIMEOUT}
# LOG_LEVEL=${DEFAULT_LOG_LEVEL}
EOF
        chown "${SERVICE_USER}:${SERVICE_GROUP}" "$env_file"
    fi
}

create_systemd_service() {
    log_step "Creating systemd service..."
    
    local service_file="/etc/systemd/system/${SERVICE_NAME}.service"
    
    cat > "$service_file" << EOF
[Unit]
Description=Apache Traffic Server Exporter
Documentation=https://github.com/${REPO}
After=network.target

[Service]
Type=simple
User=${SERVICE_USER}
Group=${SERVICE_GROUP}
EnvironmentFile=-${CONFIG_DIR}/${BINARY_NAME}.env
ExecStart=${INSTALL_DIR}/${BINARY_NAME} \\
    --web.listen-address=\${LISTEN_ADDRESS:-${DEFAULT_LISTEN_ADDRESS}} \\
    --web.telemetry-path=\${METRICS_PATH:-${DEFAULT_METRICS_PATH}} \\
    --ats.url=\${ATS_URL:-${DEFAULT_ATS_URL}} \\
    --ats.timeout=\${ATS_TIMEOUT:-${DEFAULT_ATS_TIMEOUT}} \\
    --log.level=\${LOG_LEVEL:-${DEFAULT_LOG_LEVEL}}
Restart=on-failure
RestartSec=5s
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    log_info "Systemd service created at ${service_file}"
}

enable_service() {
    log_step "Enabling ${SERVICE_NAME} service..."
    systemctl enable "${SERVICE_NAME}" >/dev/null 2>&1
}

start_service() {
    log_step "Starting ${SERVICE_NAME} service..."
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

stop_service() {
    if systemctl is-active --quiet "${SERVICE_NAME}" 2>/dev/null; then
        log_step "Stopping ${SERVICE_NAME} service..."
        systemctl stop "${SERVICE_NAME}"
    fi
}

disable_service() {
    if systemctl is-enabled --quiet "${SERVICE_NAME}" 2>/dev/null; then
        log_step "Disabling ${SERVICE_NAME} service..."
        systemctl disable "${SERVICE_NAME}" >/dev/null 2>&1
    fi
}

remove_service_file() {
    local service_file="/etc/systemd/system/${SERVICE_NAME}.service"
    if [ -f "$service_file" ]; then
        log_step "Removing systemd service file..."
        rm -f "$service_file"
        systemctl daemon-reload
    fi
}

remove_user() {
    if id -u "${SERVICE_USER}" >/dev/null 2>&1; then
        log_step "Removing user ${SERVICE_USER}..."
        userdel "${SERVICE_USER}" 2>/dev/null || true
    fi
}

remove_binary() {
    if [ -f "${INSTALL_DIR}/${BINARY_NAME}" ]; then
        log_step "Removing binary..."
        rm -f "${INSTALL_DIR}/${BINARY_NAME}"
    fi
}

remove_config_dir() {
    if [ -d "${CONFIG_DIR}" ]; then
        log_step "Removing config directory..."
        rm -rf "${CONFIG_DIR}"
    fi
}

show_status() {
    echo ""
    log_info "Installation complete!"
    echo ""
    echo "Binary:      ${INSTALL_DIR}/${BINARY_NAME}"
    echo "Config:      ${CONFIG_DIR}/${BINARY_NAME}.env"
    echo "Service:     ${SERVICE_NAME}"
    echo ""
    echo "Configuration (edit ${CONFIG_DIR}/${BINARY_NAME}.env or pass flags):"
    echo "  LISTEN_ADDRESS: ${LISTEN_ADDRESS:-$DEFAULT_LISTEN_ADDRESS}"
    echo "  METRICS_PATH:   ${METRICS_PATH:-$DEFAULT_METRICS_PATH}"
    echo "  ATS_URL:        ${ATS_URL:-$DEFAULT_ATS_URL}"
    echo "  ATS_TIMEOUT:    ${ATS_TIMEOUT:-$DEFAULT_ATS_TIMEOUT}"
    echo "  LOG_LEVEL:      ${LOG_LEVEL:-$DEFAULT_LOG_LEVEL}"
    echo ""
    echo "Useful commands:"
    echo "  sudo systemctl status ${SERVICE_NAME}      # Check service status"
    echo "  sudo systemctl restart ${SERVICE_NAME}     # Restart service"
    echo "  sudo journalctl -u ${SERVICE_NAME} -f       # View logs"
    echo "  sudo vi ${CONFIG_DIR}/${BINARY_NAME}.env    # Edit config"
    echo ""
}

do_install() {
    local version="$1"
    local os=$(detect_os)
    local arch=$(detect_arch)
    
    if check_installed; then
        log_warn "${BINARY_NAME} is already installed (version: $(get_installed_version))"
        read -p "Do you want to upgrade? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Installation cancelled"
            exit 0
        fi
        stop_service
    fi
    
    log_info "Installing ${BINARY_NAME} ${version}..."
    
    download_binary "$version" "$os" "$arch"
    create_user
    create_config_dir
    create_env_file
    create_systemd_service
    enable_service
    start_service
    show_status
}

do_upgrade() {
    local version="$1"
    local os=$(detect_os)
    local arch=$(detect_arch)
    
    if ! check_installed; then
        log_error "${BINARY_NAME} is not installed. Use 'install' command first."
        exit 1
    fi
    
    local current_version=$(get_installed_version)
    log_info "Current version: ${current_version}"
    log_info "Upgrading to version: ${version}"
    
    stop_service
    download_binary "$version" "$os" "$arch"
    start_service
    
    log_info "Upgrade complete!"
}

do_uninstall() {
    if ! check_installed; then
        log_warn "${BINARY_NAME} is not installed"
        exit 0
    fi
    
    log_info "Uninstalling ${BINARY_NAME}..."
    
    stop_service
    disable_service
    remove_service_file
    remove_binary
    
    read -p "Remove configuration directory ${CONFIG_DIR}? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        remove_config_dir
    fi
    
    read -p "Remove user '${SERVICE_USER}'? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        remove_user
    fi
    
    log_info "Uninstall complete!"
}

do_status() {
    echo ""
    echo "=== ${BINARY_NAME} Status ==="
    echo ""
    
    if check_installed; then
        echo "Installed:    Yes"
        echo "Version:      $(get_installed_version)"
        echo "Binary:       ${INSTALL_DIR}/${BINARY_NAME}"
        echo "Config:       ${CONFIG_DIR}/${BINARY_NAME}.env"
        echo ""
        
        if systemctl is-active --quiet "${SERVICE_NAME}" 2>/dev/null; then
            echo "Service:      Running"
            echo "PID:          $(systemctl show --property MainPID --value ${SERVICE_NAME})"
        elif systemctl is-enabled --quiet "${SERVICE_NAME}" 2>/dev/null; then
            echo "Service:      Stopped (enabled)"
        else
            echo "Service:      Not configured"
        fi
    else
        echo "Installed:    No"
    fi
    echo ""
}

usage() {
    echo "Usage: $0 <command> [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  install     Install ${BINARY_NAME} (default command)"
    echo "  upgrade     Upgrade to a new version"
    echo "  uninstall   Remove ${BINARY_NAME}"
    echo "  status      Show installation status"
    echo ""
    echo "Options for install/upgrade:"
    echo "  --listen-address ADDR    Listen address (default: ${DEFAULT_LISTEN_ADDRESS})"
    echo "  --metrics-path PATH      Metrics path (default: ${DEFAULT_METRICS_PATH})"
    echo "  --ats-url URL            ATS stats URL (default: ${DEFAULT_ATS_URL})"
    echo "  --ats-timeout TIMEOUT    ATS timeout (default: ${DEFAULT_ATS_TIMEOUT})"
    echo "  --log-level LEVEL        Log level (default: ${DEFAULT_LOG_LEVEL})"
    echo "  --version VERSION        Version to install (default: latest)"
    echo ""
    echo "Environment variables:"
    echo "  LISTEN_ADDRESS, METRICS_PATH, ATS_URL, ATS_TIMEOUT, LOG_LEVEL"
    echo ""
    echo "Examples:"
    echo "  # Install latest version"
    echo "  curl -sL https://raw.githubusercontent.com/${REPO}/main/install.sh | sudo bash"
    echo ""
    echo "  # Install specific version"
    echo "  sudo ./install.sh install --version v1.0.0"
    echo ""
    echo "  # Install with custom options"
    echo "  sudo ./install.sh install --ats-url http://localhost:8080/_stats --listen-address :9150"
    echo ""
    echo "  # Upgrade to latest"
    echo "  sudo ./install.sh upgrade"
    echo ""
    echo "  # Uninstall"
    echo "  sudo ./install.sh uninstall"
    echo ""
}

parse_args() {
    COMMAND="${1:-install}"
    shift || true
    
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
                VERSION="$2"
                shift 2
                ;;
            -h|--help)
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
}

main() {
    parse_args "$@"
    
    case "$COMMAND" in
        install)
            check_root
            if [ -z "$VERSION" ]; then
                VERSION=$(get_latest_version)
            fi
            do_install "$VERSION"
            ;;
        upgrade)
            check_root
            if [ -z "$VERSION" ]; then
                VERSION=$(get_latest_version)
            fi
            do_upgrade "$VERSION"
            ;;
        uninstall|remove)
            check_root
            do_uninstall
            ;;
        status)
            do_status
            ;;
        help|--help|-h)
            usage
            exit 0
            ;;
        *)
            log_error "Unknown command: $COMMAND"
            usage
            exit 1
            ;;
    esac
}

main "$@"