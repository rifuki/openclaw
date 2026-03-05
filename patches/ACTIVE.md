# Active Patch Files (Use These)

## Canonical script
- `apply-multibubble-dist-patch.py`  
  Portable runtime patcher for compiled `dist/deliver-*.js`.

## Runbook
1. `python3 ~/.openclaw/patches/apply-multibubble-dist-patch.py --dry-run`
2. `python3 ~/.openclaw/patches/apply-multibubble-dist-patch.py`
3. `openclaw gateway stop`
4. `openclaw-gateway &`
5. Test `/reset` on WhatsApp.

## Supporting docs
- `README.md`
- `QUICKSTART.txt`
- `DEBUG_ANALYSIS.md`

## Important
Do NOT use `src/channel.ts` patch flow anymore.
Current OpenClaw runtime behavior requires patching compiled `dist` files.
