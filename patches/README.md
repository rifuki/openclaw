# OpenClaw WhatsApp Multi-Bubble Patch (Portable)

Created: 2026-03-06
Maintainer: dolorisu

This patch guarantees WhatsApp multi-bubble delivery by splitting text that contains `\n\n` at compiled runtime for both delivery paths:
- `dist/deliver-*.js` (tool/message delivery)
- `dist/channel-web-*.js` + `dist/web-*.js` (auto-reply path, including group)

## Canonical script

`~/.openclaw/patches/apply-multibubble-dist-patch.py`

## Usage

Check status (no changes):

```bash
python3 ~/.openclaw/patches/apply-multibubble-dist-patch.py --status
```

Dry run:

```bash
python3 ~/.openclaw/patches/apply-multibubble-dist-patch.py --dry-run
```

Apply patch:

```bash
python3 ~/.openclaw/patches/apply-multibubble-dist-patch.py
```

Restart gateway (systemd user service):

```bash
systemctl --user restart openclaw-gateway
systemctl --user status openclaw-gateway --no-pager -l
```

## Reapply rules

Run patch again whenever:
- OpenClaw is updated
- OpenClaw is reinstalled
- Node/toolchain version changes
- New machine setup

## Verification

1. Run `--status` and confirm `deliver` + `web` entries are patched.
2. Restart gateway service.
3. Send `/reset` then test group reply with 3-4 paragraphs.
4. Confirm WhatsApp bubbles are separate.
