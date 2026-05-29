#!/usr/bin/env bash
source "$(dirname "$0")/grs-env.sh"
export YAZI_CONFIG_HOME="$HOME/dotfiles/.config/yazi/current"
export EDITOR="$(dirname "$0")/nvr-edit.sh"
export GRS_OPEN_HOOK="zellij action go-to-tab-name edit"
exec yazi --client-id 1001 "$@"
