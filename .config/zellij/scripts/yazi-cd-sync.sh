#!/usr/bin/env bash
# Fan a yazi cd out to sibling yazi instances + kak + lazygit.
#
# Usage:  yazi-cd-sync.sh <cwd> <source_client_id>
#
# `ya emit-to` remotely cd's another yazi instance (more reliable than
# ps.pub_to for this — no need for the receiver's init.lua to route).
# When the receiver cd's, ITS local `cd` sub fires and re-enters this
# script.  A tiny same-URL/500ms debounce lock breaks the loop so we
# don't bounce forever.
set -u
[[ $# -lt 1 ]] && exit 0
cwd="$1"
src="${2:-0}"
source "$(dirname "$0")/grs-env.sh"

lock_dir="${XDG_RUNTIME_DIR:-/tmp}"
lock_file="$lock_dir/grs-cd-sync-${GRS_SESSION}.lock"

now=$(date +%s%N)
if [[ -r "$lock_file" ]]; then
    read -r last_url last_ts < "$lock_file" 2>/dev/null || last_url=""
    if [[ "$last_url" == "$cwd" ]]; then
        age_ms=$(( (now - last_ts) / 1000000 ))
        if (( age_ms < 500 )); then
            exit 0
        fi
    fi
fi
printf '%s %s\n' "$cwd" "$now" > "$lock_file"

# Fan cd to yazi siblings.  Skips the source client (its cd already
# fired).  If a receiver isn't up, ya emit-to fails silently.
for target in 1001 1002 1003; do
    if [[ "$target" != "$src" ]]; then
        ya emit-to "$target" cd "$cwd" >/dev/null 2>&1 &
    fi
done

# lazygit follow — background write in case the reader isn't attached.
if [[ -p "$GRS_CWD_FIFO" ]]; then
    printf '%s\n' "$cwd" > "$GRS_CWD_FIFO" &
fi

# kak change-directory — only if the session pointer is live.
session=""
[[ -r "$GRS_NVR_POINTER" ]] && session="$(cat "$GRS_NVR_POINTER" 2>/dev/null)"
if [[ -n "$session" ]] && kak -l 2>/dev/null | grep -qF "$session"; then
    printf "change-directory '%s'\n" "${cwd//\'/\'\'}" | kak -p "$session"
fi

exit 0
