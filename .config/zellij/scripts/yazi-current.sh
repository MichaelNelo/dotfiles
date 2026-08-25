#!/usr/bin/env bash
# yazi-current lives in the grs-explore tab; on <Enter> it sends the file
# to the kak session (grs-edit tab, if open) and jumps the user there.
# go-to-tab-name works regardless of tab index because grs-explore and
# grs-edit are independent layouts.
source "$(dirname "$0")/grs-env.sh"
export YAZI_CONFIG_HOME="$HOME/.config/yazi/current"
export EDITOR="bash $(dirname "$0")/kak-edit.sh"
export GRS_OPEN_HOOK="bash $(dirname "$0")/focus-editor.sh"
exec yazi --client-id 1001 "$@"
