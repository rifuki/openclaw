# OpenClaw Multi-Bubble WhatsApp Patch 🦞

**Created:** 2026-03-06  
**Purpose:** Auto-split messages with `\n\n` into multiple WhatsApp bubbles  
**Problem Solved:** Doloris reverts to single-bubble messages despite knowing multi-bubble rule

---

## 🎯 What This Patch Does

**Before Patch:**
- Doloris generates: `"satu\n\ndua\n\ntiga"`
- WhatsApp receives: 1 bubble with "Read more" button ❌

**After Patch:**
- Doloris generates: `"satu\n\ndua\n\ntiga"`
- Middleware splits automatically
- WhatsApp receives: 3 separate bubbles ✅

---

## 🚀 Quick Start (Reapply After Update)

### Method 1: Automated Script (Recommended)

```bash
# Run the patch script
python3 ~/.openclaw/patches/apply-multibubble-patch.py

# Restart gateway
pkill -f openclaw-gateway && openclaw-gateway &
```

### Method 2: Manual Patch

If the script doesn't work:

```bash
# Find your OpenClaw installation
find ~/.local/share/mise/installs/node -name "channel.ts" -path "*/whatsapp/*"

# Edit the file and replace sendText function (see PATCH_DETAILS.md)
nano ~/.local/share/mise/installs/node/24.14.0/lib/node_modules/openclaw/extensions/whatsapp/src/channel.ts
```

---

## 📁 Files in This Directory

```
~/.openclaw/patches/
├── README.md                    # This file
├── apply-multibubble-patch.py   # Automated patch script
├── channel.ts.patched          # Reference: fully patched file
└── PATCH_DETAILS.md            # Technical details & code changes
```

---

## 🔧 Technical Details

### Modified Function: `sendText` in `channel.ts`

**Logic Added:**
1. Split text by `\n\n` pattern
2. If 1 bubble → send normally
3. If multiple bubbles → send each with 150ms delay
4. Return metadata with `_multiBubble: true`

### Code Change:

```typescript
// NEW: Auto-split middleware
const bubbles = text.split(/\n\n+/).map(s => s.trim()).filter(s => s.length > 0);

if (bubbles.length <= 1) {
  // Single bubble - send normally
  const result = await send(to, text, { ... });
  return { channel: "whatsapp", ...result };
}

// NEW: Multiple bubbles - send each separately
const results = [];
for (let i = 0; i < bubbles.length; i++) {
  const result = await send(to, bubbles[i], { ... });
  results.push(result);
  if (i < bubbles.length - 1) {
    await new Promise(r => setTimeout(r, 150)); // Maintain order
  }
}

return { 
  channel: "whatsapp", 
  ...results[0], 
  _multiBubble: true, 
  _bubbleCount: bubbles.length 
};
```

---

## ⚠️ Important Notes

### When to Reapply
- **After OpenClaw update:** Run patch script again
- **After reinstall:** Run patch script again
- **After node version change:** Run patch script again

### Backup Files
- Original files are backed up with timestamp: `channel.ts.backup.YYYYMMDD_HHMMSS`
- To restore: `cp channel.ts.backup.XXX channel.ts`

### Testing
After applying patch, test with:
```bash
openclaw agent --to main -m "Test: satu\n\ndua\n\ntiga" --deliver
```
Should see 3 separate WhatsApp bubbles.

---

## 🐛 Troubleshooting

### "Patch not found"
- Make sure OpenClaw is installed: `openclaw --version`
- Check node versions: `ls ~/.local/share/mise/installs/node/`

### "Already patched"
- This is fine! Patch is idempotent (safe to run multiple times)

### "Pattern not found"
- OpenClaw version may have changed
- Check `channel.ts.patched` for reference
- Manually apply changes or contact support

### Messages still single bubble
1. Make sure gateway is restarted after patching
2. Check if `_multiBubble: true` appears in session logs
3. Verify WhatsApp is receiving multiple message IDs

---

## 📊 Why This Solution?

| Approach | Pros | Cons |
|----------|------|------|
| **Prompt Engineering** (tried) | No code changes | Unreliable - model reverts |
| **Memory Files** (tried) | Persistent context | Still dependent on bootstrap |
| **System Prompt** (tried) | Always loaded | Model still defaults to single bubble |
| **Middleware (This)** ✅ | 100% reliable, transparent | Requires patching |

**This middleware approach is the only 100% reliable solution** because it works at the gateway level, not the model level.

---

## 🔒 Safety

- ✅ Non-destructive (creates backups)
- ✅ Idempotent (safe to run multiple times)
- ✅ Backward compatible (single bubbles still work)
- ✅ No data loss (only modifies delivery logic)

---

## 📝 Changelog

**2026-03-06 - v1.0**
- Initial patch implementation
- Added auto-split middleware
- Created patch script and documentation

---

**Questions?** Check the troubleshooting section or review `channel.ts.patched` for the complete implementation reference.
