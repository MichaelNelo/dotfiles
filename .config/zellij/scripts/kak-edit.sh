#!/usr/bin/env bash
# Editor bridge invoked by yazi opener (block=false, no TTY).  Sends
# `edit <file>` to the kak session started by kak-listen.sh; if that
# session is gone we exit non-zero on purpose — spawning a new kak here
# would fail (no TTY) and leave yazi's task list stuck.
source "$(dirname "$0")/grs-env.sh"
session=""
[[ -r "$GRS_NVR_POINTER" ]] && session="$(cat "$GRS_NVR_POINTER" 2>/dev/null)"
if [[ -n "$session" ]] && kak -l 2>/dev/null | grep -qF "$session"; then
    for f in "$@"; do
        printf "evaluate-commands -try-client client0 edit '%s'\n" "${f//\'/\'\'}"
    done | kak -p "$session"
    exit 0
fi
# Log to a per-session file the user can tail to diagnose the layout.
log="${XDG_STATE_HOME:-$HOME/.local/state}/grs-kak-edit.log"
mkdir -p "$(dirname "$log")"
{
    printf '[%s] no live kak session (pointer=%q content=%q)\n' \
        "$(date -Is)" "$GRS_NVR_POINTER" "$session"
    printf '  kak -l:\n'
    kak -l 2>&1 | sed 's/^/    /'
} >> "$log"
exit 1
