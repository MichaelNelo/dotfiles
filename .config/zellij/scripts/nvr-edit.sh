#!/usr/bin/env bash
# Late-binding nvr wrapper. Resolves the current session's nvim socket
# from GRS_NVR_POINTER at exec time, so yazi can start before nvim-listen.sh
# has registered. Falls back to a plain nvim if no pointer is available.
source "$(dirname "$0")/grs-env.sh"
sock=""
[[ -r "$GRS_NVR_POINTER" ]] && sock="$(cat "$GRS_NVR_POINTER" 2>/dev/null)"
if [[ -n "$sock" && -S "$sock" ]]; then
    exec nvr --servername "$sock" --remote-silent "$@"
fi
exec nvim "$@"
