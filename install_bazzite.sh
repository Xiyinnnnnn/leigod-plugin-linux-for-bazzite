#!/bin/sh
set -e

VERSION="1.2.2.15"
BASE="/opt/leigod"
SERVICE_FILE="/etc/systemd/system/leigod_plugin.service"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { printf "${GREEN}[INFO]${NC} %s\n" "$*"; }
warn()  { printf "${YELLOW}[WARN]${NC} %s\n" "$*"; }
error() { printf "${RED}[ERROR]${NC} %s\n" "$*"; exit 1; }

if [ "$(id -u)" -ne 0 ]; then error "Please run as root (sudo bash install_bazzite.sh)"; fi

ARCH=$(uname -m)
if [ "$ARCH" != "x86_64" ]; then error "Only x86_64 supported, current: $ARCH"; fi

if ! command -v systemctl >/dev/null 2>&1; then
    error "systemd not found. This package requires systemd."
fi

IS_ATOMIC=false
if grep -qi "bazzite" /etc/os-release 2>/dev/null || \
   grep -qi "fedora.*atomic" /etc/os-release 2>/dev/null || \
   [ -f /etc/ostree-release ] 2>/dev/null; then
    IS_ATOMIC=true
    info "Detected Bazzite/Fedora Atomic system"
fi

detect_pkg_manager() {
    if [ "$IS_ATOMIC" = true ]; then
        if command -v ipset >/dev/null 2>&1 && command -v curl >/dev/null 2>&1; then
            info "ipset and curl already available, skipping package install"
            PKG_MANAGER="none"
            return
        fi
        if command -v rpm-ostree >/dev/null 2>&1; then
            PKG_MANAGER="rpm-ostree"
            info "Using rpm-ostree (Bazzite Atomic)"
            return
        fi
        if command -v dnf >/dev/null 2>&1; then
            PKG_MANAGER="dnf-atomic"
            info "Using dnf (fallback on Atomic)"
            return
        fi
        error "No package manager found on Atomic system"
    fi

    if command -v apt >/dev/null 2>&1; then
        PKG_MANAGER="apt"; PKG_INSTALL="apt install -y"; PKG_UPDATE="apt update"
    elif command -v dnf >/dev/null 2>&1; then
        PKG_MANAGER="dnf"; PKG_INSTALL="dnf install -y"; PKG_UPDATE="dnf check-update || true"
    elif command -v yum >/dev/null 2>&1; then
        PKG_MANAGER="yum"; PKG_INSTALL="yum install -y"; PKG_UPDATE="yum makecache"
    elif command -v zypper >/dev/null 2>&1; then
        PKG_MANAGER="zypper"; PKG_INSTALL="zypper install -y"; PKG_UPDATE="zypper refresh"
    elif command -v pacman >/dev/null 2>&1; then
        PKG_MANAGER="pacman"; PKG_INSTALL="pacman -S --noconfirm"; PKG_UPDATE="pacman -Sy"
    elif command -v apk >/dev/null 2>&1; then
        PKG_MANAGER="apk"; PKG_INSTALL="apk add"; PKG_UPDATE="apk update"
    else
        warn "Cannot detect package manager. Please manually install: ipset curl"
        PKG_MANAGER="manual"
    fi
    info "Detected package manager: $PKG_MANAGER"
}

install_deps() {
    case "$PKG_MANAGER" in
        none) ;;
        rpm-ostree)
            info "Installing dependencies via rpm-ostree..."
            DEPS=""
            command -v ipset >/dev/null 2>&1 || DEPS="$DEPS ipset"
            command -v curl >/dev/null 2>&1  || DEPS="$DEPS curl"
            if [ -n "$DEPS" ]; then
                rpm-ostree install $DEPS
                info "Dependencies installed via rpm-ostree."
                info "${YELLOW}⚠  Bazzite 需要重启才能生效！${NC}"
                info "Run: ${GREEN}systemctl reboot${NC}"
                info "After reboot, run this script again to continue installation."
                exit 0
            fi
            ;;
        dnf-atomic)
            info "Installing dependencies via dnf (Atomic fallback)..."
            dnf install -y ipset curl || error "Failed to install dependencies"
            info "Dependencies installed."
            ;;
        manual)
            warn "Skipping package install. Make sure ipset and curl are installed."
            ;;
        *)
            info "Updating package lists..."
            $PKG_UPDATE >/dev/null 2>&1 || true
            info "Installing dependencies: ipset curl..."
            $PKG_INSTALL ipset curl >/dev/null 2>&1 || error "Failed to install dependencies"
            info "Dependencies installed."
            ;;
    esac
}

download_binaries() {
    local base_url="http://119.3.40.126"
    info "Downloading Leigod binary from $base_url/acc-gw.router.amd64..."
    curl -# -o "$BASE/acc-gw.router.amd64" "$base_url/acc-gw.router.amd64" || \
        error "Failed to download acc-gw.router.amd64"
    cp "$BASE/acc-gw.router.amd64" "$BASE/acc_upgrade_monitor"
    info "Downloading IP database..."
    curl -# -o "$BASE/config/ipdatacloud_country.xdb" "$base_url/ipdatacloud_country.xdb" || \
        error "Failed to download ipdatacloud_country.xdb"
    chmod 755 "$BASE/acc-gw.router.amd64" "$BASE/acc_upgrade_monitor"
    info "Binaries downloaded."
}

install_files() {
    info "Installing files to $BASE..."
    mkdir -p "$BASE/config"
    cp -r "$SCRIPT_DIR/opt/leigod/"* "$BASE/"
    chmod 755 "$BASE/steamdeck_acc_monitor.sh" "$BASE/leigod_uninstall.sh"
    info "Files installed."
}

create_symlink() {
    if [ -d /home/leigod ] && [ ! -L /home/leigod ]; then
        if rmdir /home/leigod 2>/dev/null; then
            info "Removed empty directory /home/leigod"
        else
            warn "/home/leigod is a non-empty directory. Please move it manually."
        fi
    fi
    if [ ! -L /home/leigod ]; then
        ln -sf "$BASE" /home/leigod
        info "Created symlink /home/leigod -> $BASE"
    fi
}

setup_service() {
    info "Creating systemd service..."
    cat > "$SERVICE_FILE" << 'SERVICEEOF'
[Unit]
Description=Leigod Plugin Service
Wants=network-online.target
After=network.target network-online.target

[Service]
ExecStart=/opt/leigod/steamdeck_acc_monitor.sh
KillMode=control-group
Restart=always
RestartSec=3
BindReadOnlyPaths=/opt/leigod/fake_product_name:/sys/class/dmi/id/product_name
BindReadOnlyPaths=/opt/leigod/fake_os-release:/etc/os-release

[Install]
WantedBy=default.target
SERVICEEOF
    systemctl daemon-reload
    systemctl enable leigod_plugin.service
    info "Service enabled (will auto-start on boot)."
}

start_service() {
    info "Starting Leigod Plugin Service..."
    systemctl start leigod_plugin.service 2>/dev/null || true
    sleep 2
    if systemctl is-active --quiet leigod_plugin.service; then
        info "Service is running."
    else
        warn "Service is not running. Check: systemctl status leigod_plugin.service"
    fi
}

print_summary() {
    echo ""
    echo "============================================"
    echo " Leigod Plugin v$VERSION installed!"
    echo "============================================"
    echo ""
    echo " Next steps:"
    echo "   1. Open the Leigod mobile app"
    echo "   2. Bind the device (scan QR code)"
    echo "   3. Start acceleration"
    echo ""
    echo " Manage: systemctl {status|restart|stop} leigod_plugin.service"
    echo " Uninstall: sudo bash uninstall.sh"
    echo ""
}

echo ""
echo "Leigod Plugin v$VERSION Installer (Bazzite Edition)"
echo "============================================"
echo ""

detect_pkg_manager
install_deps
install_files
download_binaries
create_symlink
setup_service
start_service
print_summary
