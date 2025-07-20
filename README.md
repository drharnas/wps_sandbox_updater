# WPS Office AUR Auto-Updater & Sandbox Wrapper

This project provides a secure wrapper around `wps`, `et`, `wpp`, and `wpspdf` which:

- Automatically checks for new versions in AUR (`https://aur.archlinux.org/packages/wps-office`)
- Notifies the user using a graphical dialog (Zenity or KDialog)
- If accepted, downloads and installs the new version via `makepkg -si`
- Wraps the original binaries in Firejail sandbox (`--net=none --noprofile`)

## Install

```bash
curl -sSL https://raw.githubusercontent.com/drharnas/wps_sandbox_updater/main/install.sh | bash
```

## Requirements

- git
- base-devel
- firejail
- zenity or kdialog

## Purpose

Enhances security by sandboxing WPS Office and keeping it up to date via direct AUR rebuilds.
