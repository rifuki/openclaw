#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"
CONFIG_PATH="${OPENCLAW_CONFIG_PATH:-$STATE_DIR/openclaw.json}"

if ! command -v jq >/dev/null 2>&1; then
  echo "error: jq is required" >&2
  exit 1
fi

if [ "$#" -ne 1 ]; then
  echo "usage: $0 <doloris|miku>"
  exit 1
fi

TARGET="$1"
case "$TARGET" in
  doloris|miku) ;;
  *)
    echo "error: target must be 'doloris' or 'miku'"
    exit 1
    ;;
esac

if [ ! -f "$CONFIG_PATH" ]; then
  echo "error: config not found at $CONFIG_PATH" >&2
  exit 1
fi

if [ "$(jq -r --arg t "$TARGET" '.agents.list | map(select(.id == $t)) | length' "$CONFIG_PATH")" -eq 0 ]; then
  echo "error: agent '$TARGET' not found in .agents.list"
  exit 1
fi

if [ "$(jq -r --arg t "$TARGET" '.channels.whatsapp.accounts | has($t)' "$CONFIG_PATH")" != "true" ]; then
  echo "error: whatsapp account '$TARGET' not found in channels.whatsapp.accounts"
  exit 1
fi

backup="$CONFIG_PATH.switch-backup-$(date +%Y%m%d-%H%M%S)"
cp "$CONFIG_PATH" "$backup"

tmp="$CONFIG_PATH.tmp"
jq --arg t "$TARGET" '
  .agents.list |= (map(select(.id == $t)) | map(.default = true))
  | .bindings = (
      [ .bindings[]
        | select(.agentId == $t and ((.match.channel // "") == "whatsapp") and ((.match.accountId // "") == $t))
      ]
      | if length > 0 then . else [{"agentId": $t, "match": {"channel": "whatsapp", "accountId": $t}}] end
    )
  | .channels.whatsapp.accounts |= with_entries(select(.key == $t))
' "$CONFIG_PATH" > "$tmp"
mv "$tmp" "$CONFIG_PATH"

echo "updated: switched to '$TARGET'-only mode"
echo "backup: $backup"

openclaw gateway restart >/dev/null
echo "gateway: restarted"

echo
echo "=== agents ==="
openclaw agents
echo
echo "=== channels ==="
openclaw channels status
