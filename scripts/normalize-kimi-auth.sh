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

# Source of truth: main agent
MAIN_AUTH_FILE="$STATE_DIR/agents/main/agent/auth-profiles.json"

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
  echo "🚨 IMPORTANT: This will copy the SAME Kimi API key to ALL agents!"
  echo "   Each agent will get its own profile (kimi-coding:default), but they"
  echo "   will all use the SAME underlying API key."
  echo ""
  echo "   If you want SEPARATE API keys for each agent, you must:"
  echo "   1. Generate different API keys from Kimi dashboard"
  echo "   2. Manually configure each agent with its own key"
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
  echo "This will normalize Kimi auth for: $AGENT_NAME"
  echo ""
  read -p "Continue? (y/N): " confirm
  if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
  fi
  echo ""
fi

changed=0

# Source of truth: main agent
MAIN_MODELS_FILE="$STATE_DIR/agents/main/agent/models.json"

# Check if main has apiKey in models.json (bug from openclaw configure)
if [ -f "$MAIN_MODELS_FILE" ]; then
  has_apikey_in_models=$(jq -r '.providers["kimi-coding"] | has("apiKey") | if . then 1 else 0 end' "$MAIN_MODELS_FILE" 2>/dev/null || echo "0")
  if [ "$has_apikey_in_models" -eq 1 ]; then
    echo "⚠️  Found apiKey in main/agent/models.json (security issue)"
    read -p "Remove apiKey from main/agent/models.json? (y/N): " cleanup_confirm
    if [[ "$cleanup_confirm" =~ ^[Yy]$ ]]; then
      jq 'del(.providers["kimi-coding"].apiKey)' "$MAIN_MODELS_FILE" > "$MAIN_MODELS_FILE.tmp" && mv "$MAIN_MODELS_FILE.tmp" "$MAIN_MODELS_FILE"
      echo "[OK]   Removed apiKey from main/agent/models.json"
      changed=1
    fi
    echo ""
  fi
fi

# Check if main has kimi-coding:default
has_main_default=0
if [ -f "$MAIN_AUTH_FILE" ]; then
  has_main_default=$(jq -r '.profiles | has("kimi-coding:default") | if . then 1 else 0 end' "$MAIN_AUTH_FILE")
fi

while IFS= read -r agent_id; do
  [ -z "$agent_id" ] && continue
  auth_file="$STATE_DIR/agents/$agent_id/agent/auth-profiles.json"

  if [ ! -f "$auth_file" ]; then
    echo "[SKIP] $agent_id -> auth store missing"
    continue
  fi

  # Check if agent already has kimi-coding profile
  has_agent_profile=$(jq -r '.profiles | has("kimi-coding:default") | if . then 1 else 0 end' "$auth_file")

  if [ "$has_main_default" -eq 1 ]; then
    # Copy from main to agent
    if [ "$has_agent_profile" -eq 0 ]; then
      # Get the profile from main and add to agent
      jq --slurpfile main "$MAIN_AUTH_FILE" '
        .profiles["kimi-coding:default"] = $main[0].profiles["kimi-coding:default"]
        | .order["kimi-coding"] = ["kimi-coding:default"]
      ' "$auth_file" > "$auth_file.tmp"
      echo "[OK]   $agent_id -> copied kimi-coding:default from main"
      changed=1
    else
      # Agent already has it, just update order
      jq '.order["kimi-coding"] = ["kimi-coding:default"]' "$auth_file" > "$auth_file.tmp"
      echo "[OK]   $agent_id -> pinned order to kimi-coding:default"
      changed=1
    fi
    mv "$auth_file.tmp" "$auth_file"
  else
    # Main doesn't have it, check if agent has it standalone
    if [ "$has_agent_profile" -eq 1 ]; then
      jq '.order["kimi-coding"] = ["kimi-coding:default"]' "$auth_file" > "$auth_file.tmp"
      mv "$auth_file.tmp" "$auth_file"
      echo "[OK]   $agent_id -> pinned order to kimi-coding:default"
      changed=1
    else
      echo "[SKIP] $agent_id -> no kimi-coding profile found"
    fi
  fi
done <<< "$AGENT_IDS_RAW"

if [ "$changed" -eq 1 ]; then
  echo "[DONE] Kimi auth normalization completed"
  echo "[NEXT] openclaw gateway restart"
else
  echo "[DONE] No changes needed"
fi

if [ "$PURGE_MAIN_DEFAULT" -eq 1 ]; then
  if [ -f "$MAIN_AUTH_FILE" ]; then
    jq 'del(.profiles["kimi-coding:default"])' "$MAIN_AUTH_FILE" > "$MAIN_AUTH_FILE.tmp" && mv "$MAIN_AUTH_FILE.tmp" "$MAIN_AUTH_FILE"
    echo "[OK]   main -> purged kimi-coding:default"
  else
    echo "[SKIP] main -> no auth store found"
  fi
fi

if [ "$PURGE_ALL_DEFAULTS" -eq 1 ]; then
  for auth in "$STATE_DIR"/agents/*/agent/auth-profiles.json; do
    [ -f "$auth" ] || continue
    jq 'del(.profiles["kimi-coding:default"])' "$auth" > "$auth.tmp" && mv "$auth.tmp" "$auth"
    echo "[OK]   $(basename "$(dirname "$(dirname "$auth")")") -> purged kimi-coding:default"
  done
fi
