#!/usr/bin/env bash
# Per-session IPC paths. Sourced by every grs script.
export GRS_SESSION="${ZELLIJ_SESSION_NAME:-default}"
GRS_RUNTIME="${XDG_RUNTIME_DIR:-/tmp}"
# Tag DDS kind names with the zellij session so two zellij sessions don't
# cross-talk on the per-user yazi-dds broker.
export GRS_DDS_TAG="$GRS_SESSION"
# Pointer file: nvim-listen.sh writes the per-pane NVR socket path here so
# yazi panes can late-bind via nvr-edit.sh. Within a single zellij session
# multiple grs layouts share this file (last writer wins).
export GRS_NVR_POINTER="$GRS_RUNTIME/grs-nvr-$GRS_SESSION.path"
export GRS_CWD_FIFO="$GRS_RUNTIME/grs-cwd-$GRS_SESSION.fifo"
