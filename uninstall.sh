#!/bin/sh
set -e

BASE="/opt/leigod"
SERVICE_NAME="leigod_plugin.service"
SERVICE_FILE="/etc/systemd/system/$SERVICE_NAME"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
info()  { printf "${GREEN}[INFO]${NC} %s\n" "$*"; }
warn()  { printf "${YELLOW}[WARN]${NC} %s\n" "$*"; }
error() { printf "${RED}[ERROR]${NC} %s\n" "$*"; exit 1; }

if [ "$(id -u)" -ne 0 ]; then error "Please run as root (sudo ./uninstall.sh)"; fi

echo ""; echo "Leigod Plugin Uninstaller"; echo "========================="
printf "${YELLOW}Remove Leigod Plugin? [y/N] ${NC}"
read -r confirm
if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then info "Cancelled."; exit 0; fi

systemctl stop "$SERVICE_NAME" 2>/dev/null || true
systemctl disable "$SERVICE_NAME" 2>/dev/null || true
rm -f "$SERVICE_FILE"
systemctl daemon-reload 2>/dev/null || true

for proc in acc-gw.router.amd64 acc_upgrade_monitor steamdeck_acc_monitor.sh; do
    pids=$(pidof "$proc" 2>/dev/null || true)
    [ -n "$pids" ] && kill -9 $pids 2>/dev/null || true
done

rm -rf "$BASE" /tmp/acc

if [ -L /home/leigod ] && [ "$(readlink /home/leigod)" = "$BASE" ]; then
    rm -f /home/leigod
fi

echo ""; echo "============================================"; echo " Leigod Plugin uninstalled."; echo "============================================"; echo ""
