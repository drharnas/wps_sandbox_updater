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

    echo "⚙ Installing wrapper for $bin"
    cat <<EOF > "$target"
#!/bin/bash
set -e

# Check dependencies
command -v firejail >/dev/null || { echo "firejail not found."; exit 1; }
GUI=""
if command -v zenity >/dev/null; then GUI="zenity";
elif command -v kdialog >/dev/null; then GUI="kdialog";
