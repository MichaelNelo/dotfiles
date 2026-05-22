#!/bin/bash
# Zsh login wrapper - forces login shell to load .zprofile (PATH config)
exec zsh -l -i "$@"
