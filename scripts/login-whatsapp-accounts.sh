#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -eq 0 ]; then
  echo "usage: $0 <accountId...>"
  echo "example: $0 doloris miku"
  exit 1
fi

for account_id in "$@"; do
  echo
  echo "=== Login WhatsApp account: $account_id ==="
  echo "Scan QR untuk account '$account_id' saat diminta."
  openclaw channels login --channel whatsapp --account "$account_id"
done

echo
echo "=== Channel status ==="
openclaw channels status || true
