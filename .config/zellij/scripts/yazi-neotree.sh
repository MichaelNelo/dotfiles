#!/usr/bin/env bash
# yazi instance used as a neotree-style sidebar in the edit tab.
# Same config dir as yazi-current (single-column layout, opener=nvr) but a
# distinct DDS client-id and a focus-shift hook that moves to the nvim pane
# on its left after opening a file.

source "$(dirname "$0")/grs-env.sh"
export YAZI_CONFIG_HOME="$HOME/dotfiles/.config/yazi/neotree"
export EDITOR="nvr --servername $NVR_SOCKET --remote-silent"
export GRS_OPEN_HOOK="zellij action move-focus left"
exec yazi --client-id 1003 "$@"
