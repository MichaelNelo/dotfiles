#!/usr/bin/env bash
# yazi-newtab-shell.sh — open a new zellij tab with an interactive shell,
# starting in yazi's current directory. Sibling of yazi-newtab.sh but no
# prompt: just spawns a fresh shell tab.
#
# Invocation from yazi keymap:
#     shell --orphan 'yazi-newtab-shell.sh'

set -u

# Inline layout: redeclare default_tab_template so tab-bar/status-bar plugins
# still appear (zellij does NOT merge with the global template when --layout
# is passed to new-tab). cwd on the pane makes the shell start in yazi's PWD.
workdir="$(mktemp -d --tmpdir yazi-newtab-shell.XXXXXX)"
layout_path="$workdir/layout.kdl"

# Escape PWD for KDL strings: \ → \\, " → \"
cwd_kdl="${PWD//\\/\\\\}"
cwd_kdl="${cwd_kdl//\"/\\\"}"

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
    tab name="shell" {
        pane cwd="$cwd_kdl"
    }
}
EOF

tab_id="$(zellij action new-tab --layout "$layout_path" 2>/dev/null)"
[[ -n "$tab_id" ]] && zellij action go-to-tab-by-id "$tab_id" >/dev/null 2>&1

rm -rf "$workdir"
