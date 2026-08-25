#!/usr/bin/env bash
source "$(dirname "$0")/grs-env.sh"
export YAZI_CONFIG_HOME="$HOME/.config/yazi/neotree"
export EDITOR="bash $(dirname "$0")/kak-edit.sh"
export GRS_OPEN_HOOK="bash $(dirname "$0")/focus-editor.sh"
exec yazi --client-id 1003 "$@"
