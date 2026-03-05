# Patch Technical Details

## Exact Code Changes

### File: `extensions/whatsapp/src/channel.ts`

### Function Modified: `sendText`

---

## ORIGINAL CODE:

```typescript
sendText: async ({ to, text, accountId, deps, gifPlayback }) => {
  const send = deps?.sendWhatsApp ?? getWhatsAppRuntime().channel.whatsapp.sendMessageWhatsApp;
  const result = await send(to, text, {
    verbose: false,
    accountId: accountId ?? undefined,
    gifPlayback,
  });
  return { channel: "whatsapp", ...result };
},
```

---

## PATCHED CODE:

```typescript
sendText: async ({ to, text, accountId, deps, gifPlayback }) => {
  const send = deps?.sendWhatsApp ?? getWhatsAppRuntime().channel.whatsapp.sendMessageWhatsApp;
  
  // Auto-split multi-bubble messages (middleware)
  const bubbles = text.split(/\n\n+/).map(s => s.trim()).filter(s => s.length > 0);
  
  if (bubbles.length <= 1) {
    // Single bubble - send normally
    const result = await send(to, text, {
      verbose: false,
      accountId: accountId ?? undefined,
      gifPlayback,
    });
    return { channel: "whatsapp", ...result };
  }
  
  // Multiple bubbles - send each separately
  const results = [];
  for (let i = 0; i < bubbles.length; i++) {
    const result = await send(to, bubbles[i], {
      verbose: false,
      accountId: accountId ?? undefined,
      gifPlayback: i === 0 ? gifPlayback : false,
    });
    results.push(result);
    // Small delay to maintain order
    if (i < bubbles.length - 1) {
      await new Promise(r => setTimeout(r, 150));
    }
  }
  
  return { channel: "whatsapp", ...results[0], _multiBubble: true, _bubbleCount: bubbles.length };
},
```

---

## How to Apply Manually

1. Open `extensions/whatsapp/src/channel.ts`
2. Find the `sendText` function in the `outbound` section
3. Replace the entire function body with the PATCHED CODE above
4. Save and restart the gateway

---

## Verification

After patching, check for these indicators:

1. **In the code:** Look for `_multiBubble: true` in the return statement
2. **In session logs:** Look for `_multiBubble: true` in message metadata
3. **In WhatsApp:** Multiple separate bubbles instead of one with "Read more"

---

## Regex Pattern Explanation

```typescript
const bubbles = text.split(/\n\n+/).map(s => s.trim()).filter(s => s.length > 0);
```

- `\n\n+` : Matches two or more consecutive newlines
- `.map(s => s.trim())` : Remove leading/trailing whitespace from each bubble
- `.filter(s => s.length > 0)` : Remove empty strings

This handles:
- `"hello\n\nworld"` → `["hello", "world"]`
- `"hello\n\n\nworld"` → `["hello", "world"]` (extra newlines)
- `"hello world"` → `["hello world"]` (no split needed)
