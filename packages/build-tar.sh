#!/bin/sh
set -e

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT="$REPO_DIR/packages/leigod-plugin_1.2.2.15_amd64.tar.gz"
TMPDIR="/tmp/opencode/leigod-plugin-tar"

BASE_URL="http://119.3.40.126"
mkdir -p "$TMPDIR/leigod-plugin-1.2.2.15/opt/leigod/config"

# Download binaries from Leigod official server
echo "Downloading Leigod binary..."
curl -# -o "$TMPDIR/leigod-plugin-1.2.2.15/opt/leigod/acc-gw.router.amd64" "$BASE_URL/acc-gw.router.amd64"
cp "$TMPDIR/leigod-plugin-1.2.2.15/opt/leigod/acc-gw.router.amd64" "$TMPDIR/leigod-plugin-1.2.2.15/opt/leigod/acc_upgrade_monitor"
echo "Downloading IP database..."
curl -# -o "$TMPDIR/leigod-plugin-1.2.2.15/opt/leigod/config/ipdatacloud_country.xdb" "$BASE_URL/ipdatacloud_country.xdb"

# Copy files
cp -r "$REPO_DIR/opt/leigod/"* "$TMPDIR/leigod-plugin-1.2.2.15/opt/leigod/"
cp "$REPO_DIR/install.sh" "$TMPDIR/leigod-plugin-1.2.2.15/"
cp "$REPO_DIR/uninstall.sh" "$TMPDIR/leigod-plugin-1.2.2.15/"

# Permissions
chmod 755 "$TMPDIR/leigod-plugin-1.2.2.15/install.sh"
chmod 755 "$TMPDIR/leigod-plugin-1.2.2.15/uninstall.sh"
chmod 755 "$TMPDIR/leigod-plugin-1.2.2.15/opt/leigod/acc-gw.router.amd64"
chmod 755 "$TMPDIR/leigod-plugin-1.2.2.15/opt/leigod/acc_upgrade_monitor"
chmod 755 "$TMPDIR/leigod-plugin-1.2.2.15/opt/leigod/steamdeck_acc_monitor.sh"
chmod 755 "$TMPDIR/leigod-plugin-1.2.2.15/opt/leigod/leigod_uninstall.sh"

cd "$TMPDIR" && tar czf "$OUTPUT" "leigod-plugin-1.2.2.15/"
rm -rf "$TMPDIR"
echo "Built: $OUTPUT"
