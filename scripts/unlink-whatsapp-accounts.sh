#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -eq 0 ]; then
  echo "usage: $0 <accountId...>"
  echo "example: $0 doloris miku"
  exit 1
fi

for account_id in "$@"; do
  echo
  echo "=== Unlink WhatsApp account: $account_id ==="

  echo "- logout session"
  if ! openclaw channels logout --channel whatsapp --account "$account_id"; then
    echo "  warning: logout failed or account not linked (continuing)"
  fi

  echo "- remove account from config"
  if ! openclaw channels remove --channel whatsapp --account "$account_id"; then
    echo "  warning: remove failed or account not found (continuing)"
  fi
done

echo
echo "=== Restart gateway ==="
openclaw gateway restart || true

echo
echo "=== Channel status ==="
openclaw channels status || true
