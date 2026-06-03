#!/usr/bin/env bash
# Ad-hoc variant of yazi-float.sh: spawn a floating zellij pane, prompt the
# user for a command template, expand tokens, and run it.
#
# Invocation from yazi keymap (mirror of yazi-float.sh):
#     shell --orphan 'yazi-ask.sh "$0" "$@"'
#
# Tokens: %f (hovered) %F (selected) %d (cwd) %D (dirname of %f) %%.
#
# The script runs in two phases: outer (called from yazi) spawns the float
# and re-invokes itself with --inner inside the float. Inner phase prompts
# and executes.

set -u

if [[ "${1:-}" == "--inner" ]]; then
    sel_file="${2:?missing selection file}"
    mapfile -t files < "$sel_file" 2>/dev/null || true
    rm -f "$sel_file"

    hovered="${files[0]:-}"
    selected=("${files[@]:1}")

    echo "cwd:      $PWD"
    [[ -n "$hovered" ]]                && echo "hovered:  $hovered"
    [[ ${#selected[@]} -gt 0 ]]         && echo "selected: ${#selected[@]} item(s)"
    echo

    read -e -r -p "cmd (tokens %f %F %d %D)> " template
    if [[ -z "$template" ]]; then
        zellij action close-pane
        exit 0
    fi

    files_quoted=""
    if [[ ${#selected[@]} -gt 0 ]]; then
        for f in "${selected[@]}"; do
            files_quoted+="$(printf '%q' "$f") "
        done
    elif [[ -n "$hovered" ]]; then
        files_quoted="$(printf '%q' "$hovered")"
    fi
    files_quoted="${files_quoted% }"

    if [[ -n "$hovered" ]]; then
        file_dir="$(dirname -- "$hovered")"
    else
        file_dir="$PWD"
    fi

    PLACEHOLDER=$'\x1e'
    cmd="$template"
    cmd="${cmd//%%/$PLACEHOLDER}"
    cmd="${cmd//%F/$files_quoted}"
    cmd="${cmd//%f/$(printf '%q' "$hovered")}"
    cmd="${cmd//%D/$(printf '%q' "$file_dir")}"
    cmd="${cmd//%d/$(printf '%q' "$PWD")}"
    cmd="${cmd//$PLACEHOLDER/%}"

    printf '\n$ %s\n\n' "$cmd"
    bash -c "$cmd"
    ec=$?
    printf '\n[exit %s — press Enter to close] ' "$ec"
    read -r _
    zellij action close-pane
    exit 0
fi

# Outer phase: invoked from yazi. Stash selection in a tmp file (avoids
# argv-length and quoting headaches in the zellij CLI invocation) and spawn
# the floating pane that will re-enter this script with --inner.

file_first="${1:-}"
[[ $# -ge 1 ]] && shift

sel_file="$(mktemp --tmpdir yazi-ask-sel.XXXXXX)"
printf '%s\n' "$file_first" "$@" > "$sel_file"

self="$(readlink -f -- "$0" 2>/dev/null || printf '%s' "$0")"

zellij action new-pane \
    --floating \
    --cwd "$PWD" \
    --name "yazi:ask" \
    -- bash "$self" --inner "$sel_file"
