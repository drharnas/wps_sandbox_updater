#!/bin/bash
set -e

REMOTE_VERSION_URL="https://raw.githubusercontent.com/<twoja_nazwa_uzytkownika>/wps-sandbox-updater/main/VERSION"
LOCAL_VERSION_FILE="/usr/local/lib/wps-sandbox-updater/VERSION"
BINARIES=(et wps wpp wpspdf)

download_latest() {
    echo "🔽 Aktualizacja..."
    for bin in "${BINARIES[@]}"; do
        target="/usr/bin/$bin"
        backup="/usr/bin/${bin}_orig"

        if [[ -f "$target" && ! -f "$backup" ]]; then
            echo "🧠 Tworzenie kopii: $target → $backup"
            mv "$target" "$backup"
        fi

        echo "🛡️ Tworzenie wrappera firejail dla: $bin"
        cat <<EOF > "$target"
#!/bin/bash
exec firejail --noprofile --net=none "/usr/bin/${bin}_orig" "\$@"
EOF
        chmod +x "$target"
    done
}

main() {
    echo "🔍 Sprawdzanie wersji..."

    remote_version=$(curl -sSL "$REMOTE_VERSION_URL")
    local_version=$(cat "$LOCAL_VERSION_FILE" 2>/dev/null || echo "0")

    if [[ "$remote_version" != "$local_version" ]]; then
        echo "🆕 Dostępna nowa wersja: $remote_version (zainstalowana: $local_version)"
        echo "$remote_version" > "$LOCAL_VERSION_FILE"
        download_latest
    else
        echo "✅ Wersja aktualna: $local_version"
    fi
}

main
