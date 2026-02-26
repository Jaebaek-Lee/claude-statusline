#!/bin/bash
# claude-statusline updater
# Usage: curl -fsSL https://raw.githubusercontent.com/Jaebaek-Lee/claude-statusline/main/update.sh | bash

set -e

REPO="Jaebaek-Lee/claude-statusline"
SCRIPT_URL="https://raw.githubusercontent.com/$REPO/main/statusline.sh"
INSTALL_PATH="$HOME/.claude/statusline.sh"

GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
RESET='\033[0m'

info()  { echo -e "${GREEN}[✓]${RESET} $1"; }
warn()  { echo -e "${YELLOW}[!]${RESET} $1"; }
error() { echo -e "${RED}[✗]${RESET} $1"; exit 1; }

if [ ! -f "$INSTALL_PATH" ]; then
    error "claude-statusline not installed. Run the install script first."
fi

# Download latest
TMP=$(mktemp)
curl -fsSL "$SCRIPT_URL" -o "$TMP"

# Compare with current
if diff -q "$INSTALL_PATH" "$TMP" > /dev/null 2>&1; then
    rm "$TMP"
    info "Already up to date."
else
    cp "$INSTALL_PATH" "$INSTALL_PATH.bak"
    mv "$TMP" "$INSTALL_PATH"
    chmod +x "$INSTALL_PATH"
    info "Updated! Previous version backed up to statusline.sh.bak"
    info "Restart Claude Code or send a message to apply."
fi
