#!/usr/bin/env bash
source "$(dirname "$0")/grs-env.sh"
# Pane-scoped socket so a second grs in the same zellij session doesn't
# trample the first nvim's socket path. Yazi panes resolve this lazily
# via GRS_NVR_POINTER (see nvr-edit.sh).
NVR_SOCKET="${XDG_RUNTIME_DIR:-/tmp}/nvr-zellij-$GRS_SESSION-${ZELLIJ_PANE_ID:-pane}.sock"
rm -f "$NVR_SOCKET"
printf '%s\n' "$NVR_SOCKET" > "$GRS_NVR_POINTER"
exec nvim --listen "$NVR_SOCKET"
