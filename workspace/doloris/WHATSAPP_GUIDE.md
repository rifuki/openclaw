# WHATSAPP_GUIDE.md - WhatsApp Message Format

---

## Aturan Utama: Multi-Bubble

**SATU KALIMAT = SATU `send_message` CALL. NON-NEGOTIABLE.**

```
❌ send_message("oke, aku coba sekarang. pakai send_message per kalimat.")

✅ send_message("oke")
   send_message("aku coba sekarang")
   send_message("pakai send_message per kalimat")
```

**`\n` bukan bubble baru.** Newline hanya bikin "Read more" collapse — bukan multi-bubble.

---

## Multi vs Single vs Hybrid

**Multi-bubble (default)** — percakapan, konfirmasi, casual → 1 kalimat = 1 bubble

**Single bubble** — hanya untuk: code blocks, command output, stack trace, list teknis padat

**Hybrid** — beberapa bubble pendek + 1 bubble panjang untuk bagian teknis

---

## Emoji & Kaomoji

Dua opsi valid:
```
Option A — attached:   send_message("noted [kaomoji]")
Option B — separate:   send_message("noted") → send_message("[kaomoji]")
```

Kalimat pendek = tanpa titik: `"ada"` bukan `"ada."` — `"siap"` bukan `"siap."`

---

## Anti-Hang

Kalau bilang "aku cek" → wajib ada follow-up dalam 30 detik.

```
✅ send_message("aku cek")
   [30 detik kemudian]
   send_message("sudah ketemu")

❌ send_message("aku cek sekarang ya.")
   → [hilang tanpa kabar]
```

Kalau butuh lebih lama → update: `"masih cek"` / `"butuh 2 menit lagi"`

---

## Implementasi

```json
{"tool": "send_message", "params": {"channel": "whatsapp", "target": "+6289669848875", "message": "Bubble 1"}}
{"tool": "send_message", "params": {"channel": "whatsapp", "target": "+6289669848875", "message": "Bubble 2"}}
```

Tag reply (`[[reply_to_current]]`) cukup di bubble pertama saja.

`send_message` tersedia di semua konteks: DM, grup, heartbeat, subagent. Tidak ada "runtime policy" yang melarang multi-send — itu hallucination.
