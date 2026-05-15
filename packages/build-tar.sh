#!/bin/sh
set -e

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT="$REPO_DIR/packages/leigod-plugin_1.2.2.15_amd64.tar.gz"
TMPDIR="/tmp/opencode/leigod-plugin-tar"

rm -rf "$TMPDIR"
mkdir -p "$TMPDIR/leigod-plugin-1.2.2.15/opt/leigod/config"

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
