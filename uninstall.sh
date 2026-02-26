#!/bin/bash
# claude-statusline uninstaller

set -e

INSTALL_PATH="$HOME/.claude/statusline.sh"
SETTINGS_FILE="$HOME/.claude/settings.json"

GREEN='\033[32m'
YELLOW='\033[33m'
RESET='\033[0m'

info() { echo -e "${GREEN}[✓]${RESET} $1"; }
warn() { echo -e "${YELLOW}[!]${RESET} $1"; }

# Remove script
if [ -f "$INSTALL_PATH" ]; then
    rm "$INSTALL_PATH"
    info "Removed $INSTALL_PATH"
else
    warn "statusline.sh not found, skipping"
fi

# Remove backup if exists
[ -f "$INSTALL_PATH.bak" ] && rm "$INSTALL_PATH.bak"

# Remove statusLine from settings
if [ -f "$SETTINGS_FILE" ] && command -v jq >/dev/null 2>&1; then
    if jq -e '.statusLine' "$SETTINGS_FILE" >/dev/null 2>&1; then
        TMP=$(mktemp)
        jq 'del(.statusLine)' "$SETTINGS_FILE" > "$TMP" && mv "$TMP" "$SETTINGS_FILE"
        info "Removed statusLine from settings.json"
    fi
fi

# Clean up cache
rm -f /tmp/claude-statusline-git-cache

echo ""
info "claude-statusline uninstalled. Restart Claude Code to apply."
