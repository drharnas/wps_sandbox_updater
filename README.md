# WPS Sandbox Updater

This tool automatically checks for updates and replaces original WPS Office binaries with secure wrappers using `firejail`.

## What it does

- Checks if a newer version is available by comparing with the version in this repository.
- If a new version is found:
  - It backs up the original binaries:  
    `/usr/bin/wps`, `/usr/bin/wpp`, `/usr/bin/et`, `/usr/bin/wpspdf` → `/usr/bin/*_orig`
  - Replaces them with wrapper scripts that launch the original binaries inside a network-isolated `firejail` sandbox.
  - Ensures the new scripts are executable.

## Supported binaries

- `et`
- `wps`
- `wpp`
- `wpspdf`

## Example wrapper

After installation, calling `/usr/bin/wps` will actually execute:

```bash
firejail --noprofile --net=none /usr/bin/wps_orig "$@"
