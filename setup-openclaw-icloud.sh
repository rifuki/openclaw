#!/bin/bash
#
# OpenClaw iCloud Setup Script
# Copies config from iCloud to local — no symlinks, fully local runtime.
# iCloud = source of truth for initial setup & backup only.
#
# Usage: bash setup-openclaw-icloud.sh
#

set -e

ICLOUD="$HOME/Library/Mobile Documents/com~apple~CloudDocs/rifuki/.openclaw"
LOCAL="$HOME/.openclaw"
BACKUP="$HOME/.openclaw.backup.$(date +%Y%m%d_%H%M%S)"

echo "OpenClaw Setup"
echo "=============="

# Check iCloud folder
if [ ! -d "$ICLOUD" ]; then
    echo "Error: iCloud folder not found: $ICLOUD"
    echo "Pastikan iCloud Drive aktif dan sudah sync."
    exit 1
fi
echo "iCloud source found"

# Backup existing local .openclaw
if [ -d "$LOCAL" ] && [ ! -L "$LOCAL" ]; then
    echo "Existing .openclaw found. Backup: $BACKUP"
    mv "$LOCAL" "$BACKUP"
fi
mkdir -p "$BACKUP" 2>/dev/null || true
mkdir -p "$LOCAL"

# ── Copied from iCloud (file asli, no symlinks) ────────────────

# 1. workspace/*.md
echo "Copying workspace/*.md..."
mkdir -p "$LOCAL/workspace"
for md in "$ICLOUD/workspace/"*.md; do
    [ -f "$md" ] || continue
    filename="$(basename "$md")"
    cp -f "$md" "$LOCAL/workspace/$filename"
    echo "  -> $filename"
done

# 2. openclaw.json
echo "Copying openclaw.json..."
cp -f "$ICLOUD/openclaw.json" "$LOCAL/openclaw.json"

# 3. agents/main/agent/ (auth-profiles + models)
echo "Copying agents/main/agent/..."
mkdir -p "$ICLOUD/agents/main/agent"
mkdir -p "$LOCAL/agents/main/agent"
for f in "$ICLOUD/agents/main/agent/"*.json; do
    [ -f "$f" ] || continue
    cp -f "$f" "$LOCAL/agents/main/agent/$(basename "$f")"
    echo "  -> $(basename "$f")"
done

# 4. cron/
echo "Copying cron/..."
mkdir -p "$LOCAL/cron"
[ -f "$ICLOUD/cron/jobs.json" ] && cp -f "$ICLOUD/cron/jobs.json" "$LOCAL/cron/jobs.json"

# ── Device-specific (local only) ──────────────────────────────

echo "Creating local-only folders..."
mkdir -p "$LOCAL/memory"
mkdir -p "$LOCAL/identity"
mkdir -p "$LOCAL/credentials"
mkdir -p "$LOCAL/logs"
mkdir -p "$LOCAL/agents/main/sessions"
mkdir -p "$LOCAL/delivery-queue/failed"
mkdir -p "$LOCAL/media/inbound"
mkdir -p "$LOCAL/media/outbound"
mkdir -p "$LOCAL/canvas"
mkdir -p "$LOCAL/completions"
mkdir -p "$LOCAL/devices"

# Restore completions dari backup kalau ada
if [ -d "$BACKUP/completions" ]; then
    echo "Restoring completions from backup..."
    cp -r "$BACKUP/completions/." "$LOCAL/completions/"
fi

echo ""
echo "Setup complete!"
echo ""
echo "Copied from iCloud:"
echo "  workspace/*.md       (agent identity files)"
echo "  openclaw.json        (config)"
echo "  agents/main/agent/   (auth-profiles, models)"
echo "  cron/                (scheduled tasks)"
echo ""
echo "Local only (not from iCloud):"
echo "  memory/              (sqlite — per device)"
echo "  identity/            (device ID)"
echo "  credentials/         (channel auth per device)"
echo "  logs/, sessions/, etc."
echo ""
echo "Next steps:"
echo "1. openclaw daemon install"
echo "2. openclaw doctor"
echo "3. Pair channel (WhatsApp/Telegram) per device"
