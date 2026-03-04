#!/usr/bin/env bash
set -euo pipefail

STATE_DIR="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"
CONFIG_PATH="${OPENCLAW_CONFIG_PATH:-$STATE_DIR/openclaw.json}"
PURGE_MAIN_DEFAULT=0

if [ "${1:-}" = "--purge-main-default" ]; then
  PURGE_MAIN_DEFAULT=1
  shift
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "error: jq is required" >&2
  exit 1
fi

if [ ! -f "$CONFIG_PATH" ]; then
  echo "error: config not found at $CONFIG_PATH" >&2
  exit 1
fi

if [ "$#" -gt 0 ]; then
  AGENT_IDS_RAW=$(printf '%s\n' "$@")
else
  AGENT_IDS_RAW=$(jq -r '.agents.list[]?.id // empty' "$CONFIG_PATH")
fi

if [ -z "$AGENT_IDS_RAW" ]; then
  echo "no agents found in $CONFIG_PATH"
  exit 0
fi

changed=0

while IFS= read -r agent_id; do
  [ -z "$agent_id" ] && continue
  auth_file="$STATE_DIR/agents/$agent_id/agent/auth-profiles.json"

  if [ ! -f "$auth_file" ]; then
    echo "skip $agent_id: missing $auth_file"
    continue
  fi

  has_default=$(jq -r '.profiles | has("openai-codex:default")' "$auth_file")
  has_agent=$(jq -r --arg aid "$agent_id" '.profiles | has("openai-codex:" + $aid)' "$auth_file")

  if [ "$has_default" != "true" ] && [ "$has_agent" != "true" ]; then
    echo "skip $agent_id: no codex profile found"
    continue
  fi

  tmp_file="$auth_file.tmp"

  if [ "$has_default" = "true" ] && [ "$has_agent" != "true" ]; then
    jq --arg aid "$agent_id" '
      .profiles["openai-codex:" + $aid] = .profiles["openai-codex:default"]
      | del(.profiles["openai-codex:default"])
      | .order["openai-codex"] = ["openai-codex:" + $aid]
    ' "$auth_file" > "$tmp_file"
    echo "updated $agent_id: promoted openai-codex:default -> openai-codex:$agent_id"
    changed=1
  elif [ "$has_default" = "true" ] && [ "$has_agent" = "true" ]; then
    jq --arg aid "$agent_id" '
      del(.profiles["openai-codex:default"])
      | .order["openai-codex"] = ["openai-codex:" + $aid]
    ' "$auth_file" > "$tmp_file"
    echo "updated $agent_id: kept openai-codex:$agent_id and removed openai-codex:default"
    changed=1
  else
    jq --arg aid "$agent_id" '
      .order["openai-codex"] = ["openai-codex:" + $aid]
    ' "$auth_file" > "$tmp_file"
    echo "updated $agent_id: pinned order to openai-codex:$agent_id"
    changed=1
  fi

  mv "$tmp_file" "$auth_file"
done <<< "$AGENT_IDS_RAW"

if [ "$changed" -eq 1 ]; then
  echo "done: normalized codex auth profiles"
  echo "next: run 'openclaw gateway restart'"
else
  echo "done: nothing to change"
fi

if [ "$PURGE_MAIN_DEFAULT" -eq 1 ]; then
  main_auth="$STATE_DIR/agents/main/agent/auth-profiles.json"
  if [ -f "$main_auth" ]; then
    jq 'del(.profiles["openai-codex:default"])' "$main_auth" > "$main_auth.tmp" && mv "$main_auth.tmp" "$main_auth"
    echo "purged: openai-codex:default from agents/main auth store"
  else
    echo "skip purge: no $main_auth"
  fi
fi
