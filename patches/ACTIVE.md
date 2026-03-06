# Active Patch Files (Use These)

## Canonical script
- `apply-multibubble-dist-patch.py`
  Portable runtime patcher for compiled dist files:
  - `deliver-*.js`
  - `channel-web-*.js`
  - `web-*.js`

## Runbook
1. `python3 ~/.openclaw/patches/apply-multibubble-dist-patch.py --status`
2. `python3 ~/.openclaw/patches/apply-multibubble-dist-patch.py --dry-run`
3. `python3 ~/.openclaw/patches/apply-multibubble-dist-patch.py`
4. `systemctl --user restart openclaw-gateway`
5. `systemctl --user status openclaw-gateway --no-pager -l`
6. Test `/reset` on WhatsApp and verify multi-bubble in group.

## Supporting docs
- `README.md`
- `QUICKSTART.txt`
- `DEBUG_ANALYSIS.md`

## Important
Do NOT use `src/channel.ts` patch flow anymore.
Current runtime behavior requires patching compiled `dist` files.
