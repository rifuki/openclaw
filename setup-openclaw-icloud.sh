#!/bin/bash
#
# OpenClaw iCloud Sync Setup Script
# Run this on any new device to sync .openclaw from iCloud
#

set -e

ICLOUD="$HOME/Library/Mobile Documents/com~apple~CloudDocs/rifuki/.openclaw"
LOCAL="$HOME/.openclaw"
BACKUP="$HOME/.openclaw.backup.$(date +%Y%m%d_%H%M%S)"

echo "OpenClaw iCloud Sync Setup"
echo "=========================="

# Check iCloud folder
if [ ! -d "$ICLOUD" ]; then
    echo "Error: iCloud folder not found: $ICLOUD"
    echo "Pastikan iCloud Drive aktif dan sudah sync dari M1."
    exit 1
fi
echo "iCloud folder found"

# Backup existing local .openclaw jika bukan symlink
if [ -d "$LOCAL" ] && [ ! -L "$LOCAL" ]; then
    echo "Existing .openclaw found. Backup: $BACKUP"
    mv "$LOCAL" "$BACKUP"
fi
mkdir -p "$BACKUP" 2>/dev/null || true

# Pastikan .openclaw adalah folder lokal biasa (bukan symlink)
mkdir -p "$LOCAL"

# ── Shared via iCloud ──────────────────────────────────────────

# 1. memory/ (seluruh folder)
echo "Linking memory/..."
[ -e "$LOCAL/memory" ] && mv "$LOCAL/memory" "$BACKUP/memory.old" 2>/dev/null || true
ln -sf "$ICLOUD/memory" "$LOCAL/memory"

# 2. workspace/*.md (per file)
echo "Linking workspace/*.md..."
mkdir -p "$LOCAL/workspace"
for md in "$ICLOUD/workspace/"*.md; do
    [ -f "$md" ] || continue
    filename="$(basename "$md")"
    ln -sf "$md" "$LOCAL/workspace/$filename"
    echo "  -> $filename"
done

# 3. cron/ (seluruh folder)
echo "Linking cron/..."
[ -e "$LOCAL/cron" ] && mv "$LOCAL/cron" "$BACKUP/cron.old" 2>/dev/null || true
ln -sf "$ICLOUD/cron" "$LOCAL/cron"

# 4. openclaw.json
echo "Linking openclaw.json..."
[ -f "$LOCAL/openclaw.json" ] && mv "$LOCAL/openclaw.json" "$BACKUP/openclaw.json.old" 2>/dev/null || true
ln -sf "$ICLOUD/openclaw.json" "$LOCAL/openclaw.json"

# 5. agents/main/agent/ (auth-profiles + models)
echo "Linking agents/main/agent/..."
mkdir -p "$ICLOUD/agents/main/agent"
mkdir -p "$LOCAL/agents/main"
[ -e "$LOCAL/agents/main/agent" ] && mv "$LOCAL/agents/main/agent" "$BACKUP/agent.old" 2>/dev/null || true
ln -sf "$ICLOUD/agents/main/agent" "$LOCAL/agents/main/agent"

# ── Device-specific (lokal, tidak ke iCloud) ──────────────────

echo "Creating device-specific local folders..."
mkdir -p "$LOCAL/identity"
mkdir -p "$LOCAL/credentials"
mkdir -p "$LOCAL/logs"
mkdir -p "$LOCAL/agents/main/sessions"
mkdir -p "$LOCAL/delivery-queue/failed"
mkdir -p "$LOCAL/media/inbound"
mkdir -p "$LOCAL/media/outbound"
mkdir -p "$LOCAL/canvas"
mkdir -p "$LOCAL/completions"

# Restore completions dari backup kalau ada
if [ -d "$BACKUP/completions" ]; then
    echo "Restoring completions from backup..."
    cp -r "$BACKUP/completions/." "$LOCAL/completions/"
fi

echo ""
echo "Setup complete!"
echo ""
echo "Synced via iCloud:"
echo "  memory/              (shared memory + sqlite)"
echo "  workspace/*.md       (agent identity files)"
echo "  cron/                (scheduled tasks)"
echo "  openclaw.json        (config)"
echo "  agents/main/agent/   (agent settings, jika ada)"
echo ""
echo "Device-specific (local only):"
echo "  identity/            (device ID unik)"
echo "  credentials/         (auth per device)"
echo "  logs/"
echo "  agents/main/sessions/"
echo ""
echo "Next steps:"
echo "1. openclaw daemon install && openclaw daemon start"
echo "2. openclaw doctor"
echo "3. Pair channel (WhatsApp/Telegram) per device"
