#!/usr/bin/env sh
# macOS/Linux launcher for WearOS Bridge. Requires PowerShell 7+ (pwsh).
dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

if ! command -v pwsh >/dev/null 2>&1; then
    cat >&2 <<'EOF'
WearOS Bridge needs PowerShell 7 (pwsh), which was not found on PATH.
  macOS:   brew install --cask powershell
  Ubuntu:  sudo snap install powershell --classic
           (or see https://learn.microsoft.com/powershell/scripting/install/install-ubuntu)
EOF
    exit 127
fi

exec pwsh -NoProfile -File "$dir/wearos-bridge.ps1" "$@"
