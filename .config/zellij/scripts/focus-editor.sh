#!/usr/bin/env bash
# Focus the "editor" pane in the grs-edit tab.
#
# Runs the zellij action sequence FULLY detached (new session via setsid,
# fds closed, HUP-immune) and appends a debug trace to
# ~/.local/state/focus-editor.log so we can see whether it fired and what
# zellij returned.
#
# Why the paranoia: lazygit's customCommand with `subprocess: false`
# waits for the child to exit AND for all inherited fds to close, then
# re-renders its own pane.  A plain `... &` inside the same session /
# process group can be killed or race-cancelled by that re-render, so we
# fully detach (setsid + nohup + </dev/null >/dev/null 2>&1).
#
# Zellij has no CLI to focus a pane by name; we rely on the fixed
# grs-edit layout (editor top-left, shell bottom-left, yazi-neotree
# full-height right) — `move-focus left` then `move-focus up` lands on
# top-left from any pane inside grs-edit.
log="${XDG_STATE_HOME:-$HOME/.local/state}/focus-editor.log"
mkdir -p "$(dirname "$log")"

setsid nohup bash -c '
    ts() { date -Is; }
    log="'"$log"'"
    printf "[%s] focus-editor start (ZELLIJ=%s)\n" "$(ts)" "${ZELLIJ:-<unset>}" >> "$log"
    sleep 0.15
    printf "[%s] go-to-tab-name edit: " "$(ts)" >> "$log"
    zellij action go-to-tab-name edit >> "$log" 2>&1
    printf "  (rc=%d)\n" "$?" >> "$log"
    sleep 0.05
    printf "[%s] move-focus left: " "$(ts)" >> "$log"
    zellij action move-focus left >> "$log" 2>&1
    printf "  (rc=%d)\n" "$?" >> "$log"
    sleep 0.03
    printf "[%s] move-focus up: " "$(ts)" >> "$log"
    zellij action move-focus up >> "$log" 2>&1
    printf "  (rc=%d)\n" "$?" >> "$log"
' </dev/null >/dev/null 2>&1 &
disown 2>/dev/null || true
