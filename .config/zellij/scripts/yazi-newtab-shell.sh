#!/usr/bin/env bash
# Tab name = template (truncated). Escape double quotes for KDL.
workdir="$(mktemp -d --tmpdir yazi-newtab.XXXXXX)" layout_path="$workdir/layout.kdl"
tab_name="shell"

set -x

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
            command "nu";
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
