#!/bin/bash
# Auto-launch tmux script - compatible with all Linux flavors
# This script checks if tmux is installed and either launches it or shows a helpful message

if command -v tmux >/dev/null 2>&1; then
    # tmux is available - launch it
    # Try to attach to existing session 'main', or create it if it doesn't exist
    exec tmux new-session -A -s main
else
    # tmux is not installed - show helpful message
    echo "============================================"
    echo "  tmux is not installed on this server"
    echo "============================================"
    echo "You can install it with:"
    echo "  Ubuntu/Debian: sudo apt update && sudo apt install tmux"
    echo "  CentOS/RHEL:   sudo yum install tmux"
    echo "  Fedora:        sudo dnf install tmux"
    echo "  Alpine:        sudo apk add tmux"
    echo "  Arch:          sudo pacman -S tmux"
    echo "============================================"
    echo
    # Start regular shell
    exec $SHELL
fi