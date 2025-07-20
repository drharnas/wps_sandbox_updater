#!/bin/bash
set -e

BINARIES=(wps et wpp wpspdf)
WRAPPER_DIR="/usr/local/lib/wps-office-sandbox"
AUR_DIR="/tmp/wps-office-aur"

# Dependencies
for cmd in git makepkg firejail; do
    command -v "$cmd" >/dev/null || { echo "Missing dependency: $cmd"; exit 1; }
done

mkdir -p "$WRAPPER_DIR"

# Clone and build WPS Office from AUR
echo "📦 Cloning AUR package..."
rm -rf "$AUR_DIR"
git clone https://aur.archlinux.org/wps-office.git "$AUR_DIR"
cd "$AUR_DIR"
makepkg -si --noconfirm

# Install wrapper for each binary
for bin in "${BINARIES[@]}"; do
    orig="/usr/bin/${bin}_orig"
    target="/usr/bin/$bin"

    if [[ -f "$target" && ! -f "$orig" ]]; then
        echo "🧠 Backing up $bin to ${bin}_orig"
        mv "$target" "$orig"
    fi

    echo "⚙️ Installing wrapper for $bin"
    cat <<EOF > "$target"
#!/bin/bash
set -e

# Check dependencies
command -v firejail >/dev/null || { echo "firejail not found."; exit 1; }
GUI=""
if command -v zenity >/dev/null; then GUI="zenity";
elif command -v kdialog >/dev/null; then GUI="kdialog";
else echo "Missing GUI tool: zenity or kdialog."; exit 1;
fi

# Get versions
LOCAL_VER=\$(pacman -Q wps-office 2>/dev/null | awk '{print \$2}')
REMOTE_VER=\$(curl -s "https://aur.archlinux.org/rpc/?v=5&type=info&arg=wps-office" | grep -Po '"Version":"\K[^"]+')

# Ask to update
if [[ "\$LOCAL_VER" != "\$REMOTE_VER" ]]; then
    MSG="New WPS Office version available: \$REMOTE_VER (installed: \$LOCAL_VER).\nUpdate now?"
    if [[ "\$GUI" == "zenity" ]]; then
        zenity --question --width=300 --title="WPS Office Update" --text="\$MSG" && exec "$WRAPPER_DIR/update.sh"
    else
        kdialog --yesno "\$MSG" && exec "$WRAPPER_DIR/update.sh"
    fi
    exit 0
fi

# Run sandboxed
exec firejail --noprofile --net=none "/usr/bin/${bin}_orig" "\$@"
EOF

    chmod +x "$target"
done

# Copy updater
cat <<'EOF' > "$WRAPPER_DIR/update.sh"
#!/bin/bash
set -e

AUR_DIR="/tmp/wps-office-aur"

echo "🔁 Updating WPS Office from AUR..."
rm -rf "$AUR_DIR"
git clone https://aur.archlinux.org/wps-office.git "$AUR_DIR"
cd "$AUR_DIR"
makepkg -si --noconfirm
EOF

chmod +x "$WRAPPER_DIR/update.sh"

echo "✅ Installation complete. Launch WPS as usual (e.g. wps, et...)"
