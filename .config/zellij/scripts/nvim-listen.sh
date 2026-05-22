#!/usr/bin/env bash
source "$(dirname "$0")/grs-env.sh"
[[ -S "$NVR_SOCKET" ]] && rm -f "$NVR_SOCKET"
exec nvim --listen "$NVR_SOCKET"
