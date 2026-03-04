# BUGS.md — Known Issues & Root Causes

---

## [FIXED] Group messages silently dropped for groups not in `groups` allowlist

**Date:** 2026-03-05  
**Version:** 2026.3.2  
**Status:** Fixed (workaround applied)

### Symptom

Bot tidak merespons pesan dari group manapun kecuali group yang punya entry eksplisit di `channels.whatsapp.accounts.<id>.groups`. Pesan masuk tercatat di `web-inbound` log (`enqueueInboundMessage`) tapi tidak pernah sampai ke `gateway/channels/whatsapp/inbound` — tidak ada `applyGroupGating`, tidak ada `processMessage`, tidak ada reply.

Log yang muncul (berhenti di sini):
```
{"module":"web-inbound"} | inbound message | {"from":"120363423885927820@g.us", ...}
```

Log yang **tidak** muncul (untuk group yang tidak bekerja):
```
{"subsystem":"gateway/channels/whatsapp/inbound"} Inbound message ...
```

### Root Cause

`resolveChannelGroupPolicy` di `channel-web-sl83aqDv.js` menggunakan logic:

```js
const hasGroups = Boolean(groups && Object.keys(groups).length > 0);
const allowlistEnabled = groupPolicy === "allowlist" || hasGroups;
```

**Keberadaan satu entry apapun di `groups` object langsung mengaktifkan allowlist mode**, terlepas dari nilai `groupPolicy`. Sehingga:

- `groupPolicy: "open"` + `groups: { "jid-A": {...} }` → allowlist aktif, hanya jid-A yang allowed
- `groupPolicy: "open"` + `groups: {}` → allowlist tidak aktif, semua group allowed

`groupAllowFrom: ["*"]` tidak membantu karena ini dipakai di layer access control yang berbeda (sebelum gating), bukan di `resolveChannelGroupPolicy`.

Penolakan terjadi **silent** — hanya di-log lewat `logVerbose` yang tidak muncul di log level default:
```
Skipping group message <jid> (not in allowlist)
```

### Fix

Tambah wildcard `"*": {}` ke `channels.whatsapp.accounts.<id>.groups`:

```json
"accounts": {
  "doloris": {
    "groupPolicy": "open",
    "groups": {
      "*": {},
      "120363407344095162@g.us": {
        "requireMention": false
      }
    }
  }
}
```

`"*": {}` = allow semua group, tanpa override `requireMention` (default: true = require mention). Group dengan entry eksplisit bisa override per-group.

**Hot-reload:** perubahan `channels.whatsapp.accounts.*.groups.*` langsung applied tanpa restart gateway.

### Diagnosis Steps

1. Cek `openclaw channels logs --channel whatsapp` — kalau pesan group tidak muncul di `gateway/channels/whatsapp/inbound`, berarti terjadi di layer ini
2. Cek apakah `channels.whatsapp.accounts.<id>.groups` punya entry — kalau ada tapi tidak ada `"*"`, itu penyebabnya
3. Enable verbose logging untuk konfirmasi: akan muncul `Skipping group message <jid> (not in allowlist)`

### Related Config Fields

- `channels.whatsapp.groupPolicy` — channel-level, tapi **tidak override** allowlist yang aktif karena `hasGroups`
- `channels.whatsapp.accounts.<id>.groupPolicy` — account-level, sama
- `channels.whatsapp.groupAllowFrom` — layer berbeda (access control pre-gating), tidak membantu
- `channels.whatsapp.groups` — channel-level groups, sama behavior-nya
- `channels.whatsapp.accounts.<id>.groups` — account-level groups, **ini yang paling berpengaruh**

---
