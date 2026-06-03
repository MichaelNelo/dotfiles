#!/usr/bin/env bash
# yazi-newtab.sh — spawn a floating ask pane, let the user type a command,
# then open a new zellij tab running that command full-screen.
#
# Invocation from yazi keymap:
#     shell --orphan 'yazi-newtab.sh "$0" "$@"'
#
# Tokens: %f (hovered) %F (selected) %d (cwd) %D (dirname of %f) %%.
#
# Two-phase:
#   Outer — invoked from yazi, writes selection to tmp file, spawns ask.
#   Inner (--inner) — prompts user, expands tokens, creates new zellij tab.

set -u

# Opt-in debug: YAZI_NEWTAB_DEBUG=1 to trace into /tmp/yazi-newtab.log
if [[ -n "${YAZI_NEWTAB_DEBUG:-}" ]]; then
    exec 2>>/tmp/yazi-newtab.log
    set -x
fi

##############################################################################
# Inner phase: running inside the floating ask pane
##############################################################################

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

    # Per-invocation tmp dir so concurrent `c n` invocations don't race.
    workdir="$(mktemp -d --tmpdir yazi-newtab.XXXXXX)"
    runner_path="$workdir/runner.sh"
    layout_path="$workdir/layout.kdl"

    {
        echo '#!/usr/bin/env bash'
        echo 'set +e'
        printf '%s\n' "$cmd"
        echo 'ec=$?'
        echo 'echo'
        echo "printf '[exit %s — press Enter to exit] ' \"\$ec\""
        echo 'read -r _'
        printf 'rm -rf %q\n' "$workdir"
    } > "$runner_path"
    chmod +x "$runner_path"

    # Tab name = template (truncated). Escape double quotes for KDL.
    tab_name="${template:0:40}"
    tab_name="${tab_name//\"/\\\"}"

    # Inline layout: redeclare default_tab_template so tab-bar/status-bar
    # plugins still appear (zellij does NOT merge with the global template
    # when --layout is passed to new-tab). `command` and `args` MUST be
    # sibling nodes inside the pane block — `pane command="..."` (attribute
    # form) doesn't allow `args` to attach.
    cat > "$layout_path" <<EOF
layout {
    default_tab_template {
        pane size=1 borderless=true {
            plugin location="tab-bar";
        }
        children;
        pane size=2 borderless=true {
            plugin location="status-bar";
        }
    }
    tab name="$tab_name" {
        pane {
            command "bash";
            args "$runner_path";
        }
    }
}
EOF

    # Create the tab and capture its stable id (printed to stdout by zellij).
    # Suppress stdout so the id doesn't pollute the floating pane. We use
    # go-to-tab-by-id (not go-to-tab, which takes a 1-based INDEX) because
    # new-tab returns the stable id, not the index.
    tab_id="$(zellij action new-tab --layout "$layout_path" 2>/dev/null)"
    if [[ -n "$tab_id" ]]; then
        zellij action go-to-tab-by-id "$tab_id" >/dev/null 2>&1
    fi
    exit 0
fi

##############################################################################
# Outer phase: invoked from yazi
##############################################################################

file_first="${1:-}"; [[ $# -ge 1 ]] && shift

sel_file="$(mktemp --tmpdir yazi-newtab-sel.XXXXXX)"
printf '%s\n' "$file_first" "$@" > "$sel_file"

self="$(readlink -f -- "$0" 2>/dev/null || printf '%s' "$0")"

zellij action new-pane \
    --floating \
    --close-on-exit \
    --cwd "$PWD" \
    --name "yazi:newtab" \
    -- bash "$self" --inner "$sel_file"
