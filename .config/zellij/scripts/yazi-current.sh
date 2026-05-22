#!/usr/bin/env bash
source "$(dirname "$0")/grs-env.sh"
export YAZI_CONFIG_HOME="$HOME/dotfiles/.config/yazi/current"
export EDITOR="nvr --servername $NVR_SOCKET --remote-silent"
export GRS_OPEN_HOOK="zellij action go-to-tab 2"
exec yazi --client-id 1001 "$@"
