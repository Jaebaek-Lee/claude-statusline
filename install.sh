#!/bin/bash
# claude-statusline installer
# Usage: curl -fsSL https://raw.githubusercontent.com/Jaebaek-Lee/claude-statusline/main/install.sh | bash

set -e

REPO="Jaebaek-Lee/claude-statusline"
SCRIPT_URL="https://raw.githubusercontent.com/$REPO/main/statusline.sh"
INSTALL_DIR="$HOME/.claude"
INSTALL_PATH="$INSTALL_DIR/statusline.sh"
SETTINGS_FILE="$INSTALL_DIR/settings.json"

# Colors
GREEN='\033[32m'
YELLOW='\033[33m'
RED='\033[31m'
RESET='\033[0m'

info()  { echo -e "${GREEN}[✓]${RESET} $1"; }
warn()  { echo -e "${YELLOW}[!]${RESET} $1"; }
error() { echo -e "${RED}[✗]${RESET} $1"; exit 1; }

# Check dependencies
command -v jq >/dev/null 2>&1 || error "jq is required. Install it: brew install jq (macOS) or apt install jq (Linux)"
command -v curl >/dev/null 2>&1 || error "curl is required"

# Create ~/.claude if needed
mkdir -p "$INSTALL_DIR"

# Backup existing statusline
if [ -f "$INSTALL_PATH" ]; then
    cp "$INSTALL_PATH" "$INSTALL_PATH.bak"
    warn "Existing statusline.sh backed up to statusline.sh.bak"
fi

# Download statusline script
curl -fsSL "$SCRIPT_URL" -o "$INSTALL_PATH"
chmod +x "$INSTALL_PATH"
info "Downloaded statusline.sh to $INSTALL_PATH"

# Update settings.json
if [ -f "$SETTINGS_FILE" ]; then
    # Check if statusLine already configured
    if echo "$(cat "$SETTINGS_FILE")" | jq -e '.statusLine' >/dev/null 2>&1; then
        EXISTING=$(cat "$SETTINGS_FILE" | jq -r '.statusLine.command // ""')
        if [ "$EXISTING" = "~/.claude/statusline.sh" ]; then
            info "settings.json already configured"
        else
            warn "settings.json has a different statusLine config: $EXISTING"
            warn "To use claude-statusline, update statusLine.command to \"~/.claude/statusline.sh\""
        fi
    else
        # Add statusLine to existing settings
        TMP=$(mktemp)
        jq '. + {"statusLine": {"type": "command", "command": "~/.claude/statusline.sh"}}' "$SETTINGS_FILE" > "$TMP" && mv "$TMP" "$SETTINGS_FILE"
        info "Added statusLine to settings.json"
    fi
else
    # Create minimal settings
    cat > "$SETTINGS_FILE" << 'EOF'
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}
EOF
    info "Created settings.json with statusLine config"
fi

echo ""
info "claude-statusline installed successfully!"
echo "  Restart Claude Code or send a message to see it."
echo ""
echo "  Uninstall: curl -fsSL https://raw.githubusercontent.com/$REPO/main/uninstall.sh | bash"
