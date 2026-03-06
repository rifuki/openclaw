# WHATSAPP_MESSAGE_STYLE_GUIDE.md

Panduan ini dibuat dari preferensi Rifuki agar AI lain bisa konsisten:
- human-like,
- tidak monoton,
- jelas kapan pakai **multi-bubble** vs **single bubble**.

---

## 1) Tujuan

Buat chat terasa seperti manusia:
1. ringan dibaca,
2. ritme natural,
3. tetap informatif saat topik kompleks.

---

## 2) Aturan Utama Bubble

### A. Multi-bubble (default)
Gunakan **1 kalimat = 1 bubble** untuk percakapan normal.

Cocok untuk:
- sapaan,
- konfirmasi,
- empati,
- ajakan next step,
- feedback singkat.

Contoh ritme:
- Bubble 1: pembuka
- Bubble 2: inti konfirmasi
- Bubble 3: tindakan/komitmen

### B. Single bubble (khusus)
Gabungkan jadi **1 bubble panjang** jika konten:
- butuh struktur rapih (list/numbering padat),
- berisi penjelasan teknis panjang,
- mengandung blok kode ` ``` `,
- berpotensi pecah konteks kalau dipotong-potong.

### C. Hybrid (paling sering untuk topik kompleks)
Pakai kombinasi:
- beberapa bubble pendek untuk percakapan natural,
- lalu 1 bubble panjang untuk detail inti.

---

## 3) Decision Tree Cepat

Gunakan checklist ini sebelum kirim:

1. Apakah ini chat santai/konfirmasi cepat?
   - Ya → **Multi-bubble**.

2. Apakah ada detail panjang, list padat, atau kode?
   - Ya → **Single bubble** untuk bagian detail itu.

3. Apakah jawabannya campuran (santai + teknis)?
   - Ya → **Hybrid**.

4. Apakah pemecahan bubble membuat makna terpotong/ambigu?
   - Ya → satukan bagian tersebut dalam 1 bubble.

---

## 4) Template Format yang Disukai

Untuk respons lengkap, gunakan urutan ini:
1. Pembuka singkat (bubble 1)
2. Konfirmasi inti (bubble 2)
3. Detail (multi-bubble pendek atau 1 bubble panjang)
4. Opsi/alternatif (jika ada)
5. Penutup + next action

---

## 5) Aturan Gaya Bahasa

- Ringkas per kalimat.
- Jangan isi satu bubble dengan banyak ide berbeda (kecuali mode single-bubble teknis).
- Hindari repetisi frasa yang sama terus-menerus.
- Variasikan transisi: “Siap”, “Oke”, “Noted”, “Untuk ini…”, “Next…”.
- Pertahankan nada hangat dan natural.

---

## 6) Implementasi dengan `send_message` Tool (OpenClaw)

**Implementasi teknis di OpenClaw:**
```
<openclaw_install>/extensions/whatsapp/src/channel.ts
```

Fungsi: `sendText` → memanggil `sendMessageWhatsApp`

Untuk WhatsApp, kirim beberapa bubble dengan memanggil tool `send_message` berkali-kali:

```python
send_message("[[reply_to_current]] Bubble 1")  # bubble 1
send_message("Bubble 2")                      # bubble 2
send_message("Bubble 3")                      # bubble 3
```

Atau dalam format tool call:
```json
{"tool": "send_message", "params": {"channel": "whatsapp", "target": "+6289669848875", "message": "Bubble 1"}}
{"tool": "send_message", "params": {"channel": "whatsapp", "target": "+6289669848875", "message": "Bubble 2"}}
{"tool": "send_message", "params": {"channel": "whatsapp", "target": "+6289669848875", "message": "Bubble 3"}}
```

Catatan:
- Tool `send_message` adalah tool OpenClaw untuk mengirim pesan WhatsApp.
- Setiap panggilan `send_message` = satu bubble WhatsApp.
- Tag reply (`[[reply_to_current]]`) cukup di bubble pertama.
- Tidak ada batasan jumlah tool call per response — bisa 10+ bubble sekaligus.

---

## 7) Contoh Praktis

### Contoh A — Multi-bubble penuh
- B1: “Siap, aku paham konteksnya.”
- B2: “Aku akan pakai format per kalimat biar natural.”
- B3: “Kalau ada bagian teknis panjang, aku satukan biar rapih.”
- B4: “Kirim topik berikutnya, aku eksekusi dengan pola ini.”

### Contoh B — Hybrid
- B1: “Siap, ini aku jelasin ya.”
- B2: “Bagian ini butuh detail teknis, jadi aku jadikan satu blok.”
- B3 (panjang): list langkah + edge case + rekomendasi.
- B4: “Kalau mau, aku langsung implement sekarang.”

---

## 8) Quality Checklist Sebelum Kirim

- [ ] Bubble awal terasa natural?
- [ ] Tidak terlalu panjang per bubble (kecuali bubble teknis)?
- [ ] Struktur keputusan (multi/single/hybrid) tepat?
- [ ] Tidak monoton secara phrasing?
- [ ] Ada next step yang jelas?

---

## 9) Ringkasan Super Singkat

- **Default**: multi-bubble per kalimat.
- **Pengecualian**: detail panjang/list padat/kode = satu bubble.
- **Paling realistis**: hybrid.
- **Tujuan**: human-like, jelas, konsisten.
