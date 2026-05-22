#!/usr/bin/env bash
# Derives per-zellij-session IPC paths. Sourced by every grs script.
export GRS_SESSION="${ZELLIJ_SESSION_NAME:-default}"
GRS_RUNTIME="${XDG_RUNTIME_DIR:-/tmp}"
export NVR_SOCKET="$GRS_RUNTIME/nvr-zellij-$GRS_SESSION.sock"
export GRS_CWD_FIFO="$GRS_RUNTIME/grs-cwd-$GRS_SESSION.fifo"
