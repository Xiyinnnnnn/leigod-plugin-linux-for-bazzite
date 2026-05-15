#!/bin/sh
set -e

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="/tmp/opencode/leigod-plugin-build"
OUTPUT="$REPO_DIR/packages/leigod-plugin_1.2.2.15_amd64.deb"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR/DEBIAN" "$BUILD_DIR/opt/leigod/config"

# Copy files
cp "$REPO_DIR/opt/leigod/acc-gw.router.amd64" "$BUILD_DIR/opt/leigod/"
cp "$REPO_DIR/opt/leigod/acc-gw.router.amd64" "$BUILD_DIR/opt/leigod/acc_upgrade_monitor"
cp "$REPO_DIR/opt/leigod/steamdeck_acc_monitor.sh" "$BUILD_DIR/opt/leigod/"
cp "$REPO_DIR/opt/leigod/plugin_common.sh" "$BUILD_DIR/opt/leigod/"
cp "$REPO_DIR/opt/leigod/leigod_uninstall.sh" "$BUILD_DIR/opt/leigod/"
cp "$REPO_DIR/opt/leigod/fake_os-release" "$BUILD_DIR/opt/leigod/"
cp "$REPO_DIR/opt/leigod/fake_product_name" "$BUILD_DIR/opt/leigod/"
cp "$REPO_DIR/opt/leigod/config/acc_version.ini" "$BUILD_DIR/opt/leigod/config/"
cp "$REPO_DIR/opt/leigod/config/new_upgrade_conf.json" "$BUILD_DIR/opt/leigod/config/"
cp "$REPO_DIR/opt/leigod/config/ipdatacloud_country.xdb" "$BUILD_DIR/opt/leigod/config/"
cp "$REPO_DIR/opt/leigod/config/accelerator.ini" "$BUILD_DIR/opt/leigod/config/"
touch "$BUILD_DIR/opt/leigod/config/accelerator"

# Debian control files
cp "$REPO_DIR/debian/control" "$BUILD_DIR/DEBIAN/"
cp "$REPO_DIR/debian/preinst" "$BUILD_DIR/DEBIAN/"
cp "$REPO_DIR/debian/postinst" "$BUILD_DIR/DEBIAN/"
cp "$REPO_DIR/debian/prerm" "$BUILD_DIR/DEBIAN/"
cp "$REPO_DIR/debian/postrm" "$BUILD_DIR/DEBIAN/"

# Permissions
chmod 755 "$BUILD_DIR/DEBIAN/preinst" "$BUILD_DIR/DEBIAN/postinst"
chmod 755 "$BUILD_DIR/DEBIAN/prerm" "$BUILD_DIR/DEBIAN/postrm"
chmod 755 "$BUILD_DIR/opt/leigod/acc-gw.router.amd64" "$BUILD_DIR/opt/leigod/acc_upgrade_monitor"
chmod 755 "$BUILD_DIR/opt/leigod/steamdeck_acc_monitor.sh" "$BUILD_DIR/opt/leigod/leigod_uninstall.sh"

fakeroot dpkg-deb --build "$BUILD_DIR" "$OUTPUT"
rm -rf "$BUILD_DIR"
echo "Built: $OUTPUT"
