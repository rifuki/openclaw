# OpenClaw WhatsApp Multi-Bubble Patch (Portable)

Created: 2026-03-06  
Maintainer: dolorisu

This patch guarantees WhatsApp multi-bubble delivery by splitting text that contains `\n\n` at the **compiled runtime layer**.

## Why this version

- Old approach patched `src/channel.ts` only.
- OpenClaw runtime uses compiled files in `dist/`.
- Result: source patch alone may not run.

This portable patch targets `dist/deliver-*.js` directly and survives different installation layouts.

## Main script

`~/.openclaw/patches/apply-multibubble-dist-patch.py`

## What it does

- Discovers OpenClaw `dist/` directories across common installs (mise/nvm/volta/asdf/npm-global)
- Patches all matching `deliver-*.js` files
- Adds WhatsApp split logic before normal chunking
- Skips already-patched files (idempotent)
- Creates backups when writing changes

## Usage

Dry run:

```bash
python3 ~/.openclaw/patches/apply-multibubble-dist-patch.py --dry-run
```

Apply patch:

```bash
python3 ~/.openclaw/patches/apply-multibubble-dist-patch.py
```

Optional custom scan root:

```bash
python3 ~/.openclaw/patches/apply-multibubble-dist-patch.py --scan-root /opt --scan-root /srv
```

Restart gateway:

```bash
openclaw gateway stop
openclaw-gateway &
```

## Reapply rules

Run patch again whenever:

- OpenClaw is updated
- OpenClaw is reinstalled
- Node toolchain version changes
- New machine setup

## Verification checklist

1. Send `/reset` from WhatsApp.
2. Check greeting appears as separate bubbles.
3. If needed, verify multiple message IDs in session log.

## Notes

- This patch is a delivery safety net.
- Doloris can still send true multi-tool calls natively.
- If native behavior regresses, patched runtime still forces multi-bubble split on `\n\n` text.
