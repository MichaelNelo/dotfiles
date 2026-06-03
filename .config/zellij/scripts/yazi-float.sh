#!/usr/bin/env bash
# Spawn a zellij floating pane running a command derived from a template.
# Invoked from yazi's `shell` action. yazi sets cwd to the explorer's cwd
# and passes hovered+selected as positional args; the keybinding forwards
# them as `"$0" "$@"`.
#
# Tokens in the template (with safe shell-quoting via printf %q):
#   %f  hovered/first file
#   %F  all selected files, individually quoted, space-separated
#   %d  cwd ($PWD)
#   %D  dirname of %f
#   %%  literal '%'
#
# Floating pane stays open after the command exits, showing the exit code
# and waiting for Enter.

set -u

if [[ $# -lt 1 ]]; then
    echo "usage: $0 <template> [hovered] [selected...]" >&2
    exit 2
fi

template="$1"
shift

file_first="${1:-}"
[[ $# -ge 1 ]] && shift

selection=()
if [[ $# -gt 0 ]]; then
    selection=("$@")
elif [[ -n "$file_first" ]]; then
    selection=("$file_first")
fi

files_quoted=""
for f in "${selection[@]}"; do
    files_quoted+="$(printf '%q' "$f") "
done
files_quoted="${files_quoted% }"

if [[ -n "$file_first" ]]; then
    file_dir="$(dirname -- "$file_first")"
else
    file_dir="$PWD"
fi

file_first_q="$(printf '%q' "$file_first")"
file_dir_q="$(printf '%q' "$file_dir")"
cwd_q="$(printf '%q' "$PWD")"

PLACEHOLDER=$'\x1e'
cmd="$template"
cmd="${cmd//%%/$PLACEHOLDER}"
cmd="${cmd//%F/$files_quoted}"
cmd="${cmd//%f/$file_first_q}"
cmd="${cmd//%D/$file_dir_q}"
cmd="${cmd//%d/$cwd_q}"
cmd="${cmd//$PLACEHOLDER/%}"

title="${cmd%% *}"
title="${title##*/}"
title="${title:0:30}"

zellij action new-pane \
    --floating \
    --cwd "$PWD" \
    --name "yazi:$title" \
    -- bash -c "$cmd
ec=\$?
printf '\n[exit %s — press Enter to close] ' \"\$ec\"
read -r _
zellij action close-pane"
