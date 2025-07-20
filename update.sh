#!/bin/bash
set -e

# Directory for AUR build
AUR_DIR="/tmp/wps-office-aur"

# Check dependencies
for cmd in git makepkg sudo firejail; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Error: Required command '$cmd' not found."
        exit 1
    fi
done

echo "🔄 Updating WPS Office from AUR..."

# Remove previous AUR directory if exists
rm -rf "$AUR_DIR"

# Clone the official AUR wps-office repo
git clone https://aur.archlinux.org/wps-office.git "$AUR_DIR"

# Build and install package
cd "$AUR_DIR"
makepkg -si --noconfirm

echo "🧹 Cleaning up build files..."
rm -rf "$AUR_DIR"

# Backup original binaries and create firejail wrappers
BINARIES=(wps et wpp wpspdf)
for bin in "${BINARIES[@]}"; do
    ORIG="/usr/bin/$bin"
    BACKUP="/usr/bin/${bin}_orig"
    WRAPPER="/usr/bin/$bin"

    if [[ -f "$ORIG" && ! -f "$BACKUP" ]]; then
        echo "Backing up $ORIG to $BACKUP"
        sudo mv "$ORIG" "$BACKUP"
    fi

    echo "Creating firejail wrapper for $bin"

    sudo tee "$WRAPPER" > /dev/null <<EOF
#!/bin/bash
exec firejail --noprofile --net=none "$BACKUP" "\$@"
EOF
    sudo chmod +x "$WRAPPER"
done

echo "✅ Update completed. WPS Office now runs sandboxed via firejail."
