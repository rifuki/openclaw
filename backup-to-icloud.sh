#!/bin/bash
#
# OpenClaw Backup → iCloud
# Backs up local .openclaw files to iCloud as source of truth.
# Run this after making changes to config, workspace, or cron.
#
# Usage:
#   bash backup-to-icloud.sh          # backup semua
#   bash backup-to-icloud.sh --memory # include memory/sqlite (stop gateway dulu!)
#

set -e

ICLOUD="$HOME/Library/Mobile Documents/com~apple~CloudDocs/rifuki/.openclaw"
LOCAL="$HOME/.openclaw"
INCLUDE_MEMORY=false
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")

# Parse flags
for arg in "$@"; do
    [ "$arg" = "--memory" ] && INCLUDE_MEMORY=true
done

echo "OpenClaw Backup → iCloud"
echo "========================"
echo "Time: $TIMESTAMP"
echo ""

# Check iCloud folder
if [ ! -d "$ICLOUD" ]; then
    echo "Error: iCloud folder not found: $ICLOUD"
    exit 1
fi

BACKED_UP=0
SKIPPED=0

_copy() {
    local src="$1" dst="$2"
    if [ -f "$src" ]; then
        mkdir -p "$(dirname "$dst")"
        cp -f "$src" "$dst"
        echo "  ✓ $(basename "$src")"
        BACKED_UP=$((BACKED_UP + 1))
    else
        echo "  - $(basename "$src") (not found, skipped)"
        SKIPPED=$((SKIPPED + 1))
    fi
}

# 1. workspace/*.md
echo "workspace/*.md"
mkdir -p "$ICLOUD/workspace"
for md in "$LOCAL/workspace/"*.md; do
    [ -f "$md" ] || continue
    _copy "$md" "$ICLOUD/workspace/$(basename "$md")"
done

# 2. openclaw.json
echo "openclaw.json"
_copy "$LOCAL/openclaw.json" "$ICLOUD/openclaw.json"

# 3. agents/main/agent/
echo "agents/main/agent/"
mkdir -p "$ICLOUD/agents/main/agent"
for f in "$LOCAL/agents/main/agent/"*.json; do
    [ -f "$f" ] || continue
    _copy "$f" "$ICLOUD/agents/main/agent/$(basename "$f")"
done

# 4. cron/jobs.json
echo "cron/"
_copy "$LOCAL/cron/jobs.json" "$ICLOUD/cron/jobs.json"

# 5. memory/ (optional, requires --memory flag)
echo "memory/"
if [ "$INCLUDE_MEMORY" = true ]; then
    if pgrep -f "openclaw.*gateway" > /dev/null 2>&1; then
        echo "  ✗ Gateway masih running! Stop dulu: openclaw daemon stop"
        echo "    Atau jalankan tanpa --memory untuk skip sqlite."
        SKIPPED=$((SKIPPED + 1))
    else
        mkdir -p "$ICLOUD/memory"
        for f in "$LOCAL/memory/"*; do
            [ -f "$f" ] || continue
            _copy "$f" "$ICLOUD/memory/$(basename "$f")"
        done
    fi
else
    echo "  - skipped (pakai --memory untuk include sqlite)"
fi

echo ""
echo "Done: $BACKED_UP files backed up, $SKIPPED skipped."
echo "iCloud: $ICLOUD"
