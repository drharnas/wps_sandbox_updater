#!/bin/bash
set -e

BINARIES=(wps et wpp wpspdf)
WRAPPER_DIR="$HOME/.local/share/wps-office-sandbox"
AUR_DIR="/tmp/wps-office-aur"

mkdir -p "$WRAPPER_DIR"

# Dependencies
for cmd in git makepkg firejail; do
    command -v "$cmd" >/dev/null || { echo "Missing dependency: $cmd"; exit 1; }
done

# Clone and build WPS Office from AUR
echo "📦 Cloning AUR package..."
rm -rf "$AUR_DIR"
git clone https://aur.archlinux.org/wps-office.git "$AUR_DIR"
cd "$AUR_DIR"
makepkg -si --noconfirm

# Create updater script
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

# Create firejail wrappers in /usr/bin
for bin in "${BINARIES[@]}"; do
    ORIG="/usr/bin/$bin"
    ORIG_BACKUP="/usr/bin/${bin}_orig"
    WRAPPER="/usr/bin/$bin"

    if [[ -f "$ORIG" && ! -f "$ORIG_BACKUP" ]]; then
        echo "🧠 Backing up $ORIG to $ORIG_BACKUP"
        sudo mv "$ORIG" "$ORIG_BACKUP"
    fi

    echo "⚙️ Installing wrapper to $WRAPPER"
    sudo tee "$WRAPPER" > /dev/null <<EOF
#!/bin/bash
set -e

command -v firejail >/dev/null || { echo "firejail not found."; exit 1; }

GUI=""
if command -v zenity >/dev/null; then GUI="zenity";
elif command -v kdialog >/dev/null; then GUI="kdialog";
else echo "Missing GUI tool: zenity or kdialog."; exit 1;
fi

LOCAL_VER=\$(pacman -Q wps-office 2>/dev/null | awk '{print \$2}')
REMOTE_VER=\$(curl -s "https://aur.archlinux.org/rpc/?v=5&type=info&arg=wps-office" | grep -Po '"Version":"\\K[^"]+')

if [[ "\$LOCAL_VER" != "\$REMOTE_VER" ]]; then
    MSG="New WPS Office version available: \$REMOTE_VER (installed: \$LOCAL_VER).\\nUpdate now?"
    if [[ "\$GUI" == "zenity" ]]; then
        zenity --question --width=300 --title="WPS Office Update" --text="\$MSG" && exec "$WRAPPER_DIR/update.sh"
    else
        kdialog --yesno "\$MSG" && exec "$WRAPPER_DIR/update.sh"
    fi
    exit 0
fi

exec firejail --noprofile --net=none "/usr/bin/${bin}_orig" "\$@"
EOF

    sudo chmod +x "$WRAPPER"
done

echo "✅ Installation complete. WPS Office is now sandboxed and autoupdated!"
