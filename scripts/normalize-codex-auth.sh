#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"
CONFIG_PATH="${OPENCLAW_CONFIG_PATH:-$STATE_DIR/openclaw.json}"
PURGE_MAIN_DEFAULT=0
PURGE_ALL_DEFAULTS=0
AGENT_ARGS=""
SKIP_CONFIRM=0

for arg in "$@"; do
  case "$arg" in
    --purge-main-default)
      PURGE_MAIN_DEFAULT=1
      ;;
    --purge-all-defaults)
      PURGE_ALL_DEFAULTS=1
      ;;
    --yes|-y)
      SKIP_CONFIRM=1
      ;;
    --*)
      echo "error: unknown option: $arg" >&2
      echo "usage: $0 [--purge-main-default] [--purge-all-defaults] [--yes] <agentId...>" >&2
      exit 1
      ;;
    *)
      if [ -z "$AGENT_ARGS" ]; then
        AGENT_ARGS="$arg"
      else
        AGENT_ARGS="$AGENT_ARGS
$arg"
      fi
      ;;
  esac
done

if ! command -v jq >/dev/null 2>&1; then
  echo "error: jq is required" >&2
  exit 1
fi

if [ ! -f "$CONFIG_PATH" ]; then
  echo "error: config not found at $CONFIG_PATH" >&2
  exit 1
fi

if [ -n "$AGENT_ARGS" ]; then
  AGENT_IDS_RAW=$(printf '%b\n' "$AGENT_ARGS")
else
  AGENT_IDS_RAW=$(jq -r '.agents.list[]?.id // empty' "$CONFIG_PATH")
fi

if [ -z "$AGENT_IDS_RAW" ]; then
  echo "no agents found in $CONFIG_PATH"
  exit 0
fi

# Count agents
AGENT_COUNT=$(echo "$AGENT_IDS_RAW" | grep -c '^' || true)

# Show warning for multiple agents
if [ "$AGENT_COUNT" -gt 1 ] && [ "$SKIP_CONFIRM" -eq 0 ]; then
  echo ""
  echo "⚠️  WARNING: Multiple agents detected ($AGENT_COUNT agents)"
  echo ""
  echo "Agents to be normalized:"
  echo "$AGENT_IDS_RAW" | sed 's/^/  - /'
  echo ""
  echo "🚨 IMPORTANT: This will share the SAME Codex OAuth credentials across all agents!"
  echo "   Each agent will get its own profile (openai-codex:<agent>), but they will"
  echo "   all use the SAME underlying API key/account."
  echo ""
  echo "   If you want SEPARATE accounts for each agent, you must:"
  echo "   1. Run this script for ONE agent at a time"
  echo "   2. Manually re-authenticate with different accounts between runs"
  echo ""
  read -p "Continue? (y/N): " confirm
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
  fi
  echo ""
elif [ "$AGENT_COUNT" -eq 1 ] && [ "$SKIP_CONFIRM" -eq 0 ]; then
  AGENT_NAME=$(echo "$AGENT_IDS_RAW" | head -1)
  echo ""
  echo "This will normalize Codex auth for: $AGENT_NAME"
  echo ""
  read -p "Continue? (y/N): " confirm
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
  fi
  echo ""
fi

changed=0

while IFS= read -r agent_id; do
  [ -z "$agent_id" ] && continue
  auth_file="$STATE_DIR/agents/$agent_id/agent/auth-profiles.json"

  if [ ! -f "$auth_file" ]; then
    echo "[SKIP] $agent_id -> auth store missing"
    continue
  fi

  has_default=$(jq -r '.profiles | has("openai-codex:default")' "$auth_file")
  has_agent=$(jq -r --arg aid "$agent_id" '.profiles | has("openai-codex:" + $aid)' "$auth_file")

  if [ "$has_default" != "true" ] && [ "$has_agent" != "true" ]; then
    echo "[SKIP] $agent_id -> no openai-codex profile found"
    continue
  fi

  tmp_file="$auth_file.tmp"

  if [ "$has_default" = "true" ] && [ "$has_agent" != "true" ]; then
    jq --arg aid "$agent_id" '
      .profiles["openai-codex:" + $aid] = .profiles["openai-codex:default"]
      | del(.profiles["openai-codex:default"])
      | .order["openai-codex"] = ["openai-codex:" + $aid]
    ' "$auth_file" > "$tmp_file"
    echo "[OK]   $agent_id -> promoted openai-codex:default to openai-codex:$agent_id"
    changed=1
  elif [ "$has_default" = "true" ] && [ "$has_agent" = "true" ]; then
    jq --arg aid "$agent_id" '
      del(.profiles["openai-codex:default"])
      | .order["openai-codex"] = ["openai-codex:" + $aid]
    ' "$auth_file" > "$tmp_file"
    echo "[OK]   $agent_id -> removed openai-codex:default, kept openai-codex:$agent_id"
    changed=1
  else
    jq --arg aid "$agent_id" '
      .order["openai-codex"] = ["openai-codex:" + $aid]
    ' "$auth_file" > "$tmp_file"
    echo "[OK]   $agent_id -> pinned order to openai-codex:$agent_id"
    changed=1
  fi

  mv "$tmp_file" "$auth_file"
done <<< "$AGENT_IDS_RAW"

if [ "$changed" -eq 1 ]; then
  echo "[DONE] Codex auth normalization completed"
  echo "[NEXT] openclaw gateway restart"
else
  echo "[DONE] No changes needed"
fi

if [ "$PURGE_MAIN_DEFAULT" -eq 1 ]; then
  main_auth="$STATE_DIR/agents/main/agent/auth-profiles.json"
  if [ -f "$main_auth" ]; then
    jq 'del(.profiles["openai-codex:default"])' "$main_auth" > "$main_auth.tmp" && mv "$main_auth.tmp" "$main_auth"
    echo "[OK]   main -> purged openai-codex:default"
  else
    echo "[SKIP] main -> no auth store found"
  fi
fi

if [ "$PURGE_ALL_DEFAULTS" -eq 1 ]; then
  for auth in "$STATE_DIR"/agents/*/agent/auth-profiles.json; do
    [ -f "$auth" ] || continue
    jq 'del(.profiles["openai-codex:default"])' "$auth" > "$auth.tmp" && mv "$auth.tmp" "$auth"
    echo "[OK]   $(basename "$(dirname "$(dirname "$auth")")") -> purged openai-codex:default"
  done
fi
