#!/bin/bash
set -e

REPO_URL="https://raw.githubusercontent.com/drharnas/wps-sandbox-updater/main"
INSTALL_DIR="/usr/local/lib/wps-sandbox-updater"

# Create local install directory
mkdir -p "$INSTALL_DIR"

# Download updater script and version file
curl -sSL "$REPO_URL/update.sh" -o "$INSTALL_DIR/update.sh"
curl -sSL "$REPO_URL/VERSION" -o "$INSTALL_DIR/VERSION"
chmod +x "$INSTALL_DIR/update.sh"

# Run the updater
"$INSTALL_DIR/update.sh"
