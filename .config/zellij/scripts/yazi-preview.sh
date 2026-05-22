#!/usr/bin/env bash
source "$(dirname "$0")/grs-env.sh"
export YAZI_CONFIG_HOME="$HOME/dotfiles/.config/yazi/preview"
unset EDITOR GRS_OPEN_HOOK
exec yazi --client-id 1002 "$@"
