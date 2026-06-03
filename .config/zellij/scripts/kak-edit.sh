#!/usr/bin/env bash
source "$(dirname "$0")/grs-env.sh"
session=""
[[ -r "$GRS_NVR_POINTER" ]] && session="$(cat "$GRS_NVR_POINTER" 2>/dev/null)"
if [[ -n "$session" ]] && kak -l 2>/dev/null | grep -qF "$session"; then
    for f in "$@"; do
        printf "evaluate-commands -try-client client0 edit '%s'\n" "${f//\'/\'\'}"
    done | kak -p "$session"
    exit 0
fi
exec kak "$@"
