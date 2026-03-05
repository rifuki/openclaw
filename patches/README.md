# OpenClaw WhatsApp Multi-Bubble Patch (Portable)

Created: 2026-03-06  
Maintainer: dolorisu

This patch guarantees WhatsApp multi-bubble delivery by splitting text that contains `\n\n` at the compiled runtime layer.

## Current Status

- Active flow: compiled runtime patch (`dist/deliver-*.js`)
- Canonical guide: `ACTIVE.md`
- Legacy artifacts: `legacy/README_LEGACY.md`

## Main script

`~/.openclaw/patches/apply-multibubble-dist-patch.py`

## Usage

Dry run:

```bash
python3 ~/.openclaw/patches/apply-multibubble-dist-patch.py --dry-run
```

Apply patch:

```bash
python3 ~/.openclaw/patches/apply-multibubble-dist-patch.py
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
- Node/toolchain version changes
- New machine setup

## Verification

1. Send `/reset` on WhatsApp
2. Greeting must be multi-bubble from first reply
3. If needed, verify multiple message IDs in session logs
