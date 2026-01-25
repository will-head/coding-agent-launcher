#!/bin/zsh
# tmux-wrapper.sh - Wrapper script to set TERM before launching tmux
#
# This script sets TERM to a known value (xterm-256color) before launching tmux.
# This fixes compatibility issues with terminals that send exotic TERM values
# (like Ghostty's xterm-ghostty) that don't exist in the VM's terminfo database.
#
# By setting TERM in the script environment rather than explicitly in the command,
# this also avoids issues with tools like opencode that hang when TERM is set
# explicitly in the command environment.

export TERM=xterm-256color
exec /opt/homebrew/bin/tmux "$@"
