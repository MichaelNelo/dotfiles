#!/usr/bin/env bash
source "$(dirname "$0")/grs-env.sh"
KAK_SESSION="grs-$GRS_SESSION-${ZELLIJ_PANE_ID:-pane}"
printf '%s\n' "$KAK_SESSION" > "$GRS_NVR_POINTER"
exec kak -s "$KAK_SESSION"
