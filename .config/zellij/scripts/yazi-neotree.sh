#!/usr/bin/env bash
source "$(dirname "$0")/grs-env.sh"
export YAZI_CONFIG_HOME="$HOME/.config/yazi/neotree"
export EDITOR="bash $(dirname "$0")/kak-edit.sh"
export GRS_OPEN_HOOK="zellij action move-focus left"
exec yazi --client-id 1003 "$@"
