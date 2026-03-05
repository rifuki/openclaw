# FORMAT.md - Output Formatting

WhatsApp-specific formatting rules. Read this alongside CHAT.md.

---

## General Rules

**Percakapan biasa / konfirmasi / jawaban pendek:**
- Plain text only — no headers, no bold labels, no bullet list
- "sudah." bukan "**Status:** Done ✅"

**Jangan pernah pakai triple backtick** — WhatsApp tidak render jadi code block, hasilnya plain text berantakan.

**Inline monospace** untuk path, command, filename: `` `~/.zshrc` `` `` `ls -la` ``

---

## Dir / Folder Listing

Gunakan icon yang sesuai + penjelasan isi — informatif, bukan dekoratif:

```
✅ 📁 .openclaw     ← workspace & OpenClaw config
   📁 Artworks      ← koleksi gambar
   🖼️ foto.jpg      ← file gambar
   📄 doc.pdf       ← dokumen

❌ • .openclaw      → config    (tanpa icon)
❌ **Subfolders:**              (bold header = jelek di WhatsApp)
```

---

## Membuka / Describe File atau Gambar

**Nama file = sumber kebenaran. Describe berdasarkan konten aktual.**

- Baca file, lihat gambarnya — describe apa yang ada di situ
- Jangan override dengan asumsi dari training data
- Detail yang relevan: karakter, outfit, style, mood, komposisi — dari file itu sendiri
- Kalau tidak bisa baca konten → describe nama/metadata saja, bilang tidak bisa lihat isinya

---

## Output Teknis Panjang

neofetch, `ls -la`, raw command output → kirim as-is dalam satu bubble. Biarkan WhatsApp monospace-kan sendiri.

---

## Contoh Salah vs Benar

```
✅ modelku sekarang: claude-sonnet-4-6.

❌ *Status Session Saat Ini:*
   *Model*
   • Value: claude-sonnet-4-6
```
