# Legacy Patch Artifacts

These files are archived for reference only.
They are not used by the current runtime patch flow.

- `apply-multibubble-patch.py` (source-based, patches `src/channel.ts`)
- `channel.ts.patched`
- `PATCH_DETAILS.md`

Reason archived:
OpenClaw runtime executes compiled `dist` JavaScript. Source-only patching is not reliable without rebuild.

Use this instead:
- `../apply-multibubble-dist-patch.py`
