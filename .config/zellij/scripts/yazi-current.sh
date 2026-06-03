#!/usr/bin/env bash
source "$(dirname "$0")/grs-env.sh"
export YAZI_CONFIG_HOME="$HOME/.config/yazi/current"
export EDITOR="bash $(dirname "$0")/kak-edit.sh"
export GRS_OPEN_HOOK="zellij action go-to-tab 2"
exec yazi --client-id 1001 "$@"
