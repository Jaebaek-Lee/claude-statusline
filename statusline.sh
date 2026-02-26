#!/bin/bash
# claude-statusline - Context-aware status line for Claude Code
# https://github.com/Jaebaek-Lee/claude-statusline

input=$(cat)

MODEL=$(echo "$input" | jq -r '.model.display_name')
DIR=$(echo "$input" | jq -r '.workspace.current_dir')
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
CONTEXT_SIZE=$(echo "$input" | jq -r '.context_window.context_window_size // 200000')
LINES_ADDED=$(echo "$input" | jq -r '.cost.total_lines_added // 0')
LINES_REMOVED=$(echo "$input" | jq -r '.cost.total_lines_removed // 0')

# ANSI colors
GREEN='\033[32m'
YELLOW='\033[33m'
ORANGE='\033[38;5;208m'
RED='\033[31m'
BOLD_RED='\033[1;31m'
CYAN='\033[36m'
RESET='\033[0m'

# --- Core concept: 90% real = 100% displayed ---
# Claude Code auto-compresses at ~90-95%, so treat 90% as the effective limit.
# The progress bar fills to 100% when real usage hits 90%.
EFFECTIVE_MAX=90
if [ "$PCT" -ge "$EFFECTIVE_MAX" ]; then
    EFFECTIVE_PCT=100
else
    EFFECTIVE_PCT=$((PCT * 100 / EFFECTIVE_MAX))
fi

# Color thresholds (based on real percentage)
#   0-49%  green    - plenty of room
#  50-69%  yellow   - getting warm
#  70-84%  orange   - compress recommended
#  85-89%  bold red - compress soon
#  90%+   bold red ▓ - COMPRESS NOW
if [ "$PCT" -ge 90 ]; then
    BAR_COLOR="$BOLD_RED"
    BAR_CHAR='▓'
elif [ "$PCT" -ge 85 ]; then
    BAR_COLOR="$BOLD_RED"
elif [ "$PCT" -ge 70 ]; then
    BAR_COLOR="$ORANGE"
elif [ "$PCT" -ge 50 ]; then
    BAR_COLOR="$YELLOW"
else
    BAR_COLOR="$GREEN"
fi

BAR_CHAR="${BAR_CHAR:-█}"

# Build progress bar (20 chars for good resolution)
BAR_WIDTH=20
FILLED=$((EFFECTIVE_PCT * BAR_WIDTH / 100))
[ "$FILLED" -gt "$BAR_WIDTH" ] && FILLED=$BAR_WIDTH
EMPTY=$((BAR_WIDTH - FILLED))
BAR=""
[ "$FILLED" -gt 0 ] && BAR=$(printf "%${FILLED}s" | sed "s/ /$BAR_CHAR/g")
[ "$EMPTY" -gt 0 ] && BAR="${BAR}$(printf "%${EMPTY}s" | tr ' ' '░')"

# Warning message
WARNING=""
if [ "$PCT" -ge 90 ]; then
    WARNING=" ${BOLD_RED}⚠ COMPRESS NOW${RESET}"
elif [ "$PCT" -ge 85 ]; then
    WARNING=" ${BOLD_RED}⚠ compress soon${RESET}"
elif [ "$PCT" -ge 70 ]; then
    WARNING=" ${ORANGE}← compress recommended${RESET}"
fi

format_k() {
  if [ "$1" -ge 1000 ]; then
    echo "$((($1 + 500) / 1000))k"
  else
    echo "$1"
  fi
}
CONTEXT_K=$(format_k "$CONTEXT_SIZE")

# Git branch (cached 5s for performance)
CACHE_FILE="/tmp/claude-statusline-git-cache"
CACHE_MAX_AGE=5
cache_is_stale() {
    [ ! -f "$CACHE_FILE" ] || \
    [ $(($(date +%s) - $(stat -f %m "$CACHE_FILE" 2>/dev/null || stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0))) -gt $CACHE_MAX_AGE ]
}
BRANCH=""
if cache_is_stale; then
    if git rev-parse --git-dir > /dev/null 2>&1; then
        git branch --show-current 2>/dev/null > "$CACHE_FILE"
    else
        echo "" > "$CACHE_FILE"
    fi
fi
CACHED_BRANCH=$(cat "$CACHE_FILE" 2>/dev/null)
[ -n "$CACHED_BRANCH" ] && BRANCH=" | 🌿 ${CACHED_BRANCH}"

# Line 1: Model, directory, git, lines changed
LINES_INFO=""
[ "$LINES_ADDED" -gt 0 ] && LINES_INFO="${GREEN}+${LINES_ADDED}${RESET}"
[ "$LINES_REMOVED" -gt 0 ] && LINES_INFO="${LINES_INFO} ${RED}-${LINES_REMOVED}${RESET}"
[ -n "$LINES_INFO" ] && LINES_INFO=" | ${LINES_INFO}"

echo -e "${CYAN}[$MODEL]${RESET} 📁 ${DIR##*/}${BRANCH}${LINES_INFO}"

# Line 2: Context bar (90% = full) with real percentage + warning
echo -e "${BAR_COLOR}${BAR}${RESET} ${PCT}%/${EFFECTIVE_MAX}% (${CONTEXT_K})${WARNING}"
