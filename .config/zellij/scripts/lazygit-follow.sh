#!/usr/bin/env bash
set -u
source "$(dirname "$0")/grs-env.sh"

mkdir -p "$(dirname "$GRS_CWD_FIFO")"
[[ -p "$GRS_CWD_FIFO" ]] || mkfifo "$GRS_CWD_FIFO"

closest_repo() {
    git -C "$1" rev-parse --show-toplevel 2>/dev/null || printf '%s' "$1"
}

current_repo=""
lazypid=0

start_lazygit() {
    if [[ "$lazypid" -ne 0 ]]; then
        kill "$lazypid" 2>/dev/null
        wait "$lazypid" 2>/dev/null
    fi
    (cd "$1" && exec lazygit) &
    lazypid=$!
    current_repo="$1"
}

cleanup() {
    if [[ "$lazypid" -ne 0 ]]; then
        kill "$lazypid" 2>/dev/null
    fi
    rm -f "$GRS_CWD_FIFO"
    exit 0
}
trap cleanup INT TERM EXIT

start_lazygit "$(closest_repo "$PWD")"

# fd 3 keeps the fifo open so reads don't EOF when writers close
exec 3<>"$GRS_CWD_FIFO"
while IFS= read -r cwd <&3; do
    repo="$(closest_repo "$cwd")"
    [[ "$repo" != "$current_repo" ]] && start_lazygit "$repo"
done
