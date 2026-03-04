# FOLDER_DISPLAY_PLAYBOOK.md

Standar output untuk AI lain agar sekali baca langsung paham format tampilan folder sesuai preferensi Rifuki.

---

## Tujuan

- Output harus rapi, sejajar, mudah dipindai cepat.
- Bedakan folder vs file secara visual.
- Hindari dump mentah yang panjang dan berantakan.

---

## Aturan Wajib

1. Gunakan blok monospace:
   - wajib pakai ```text ... ``` agar alignment stabil.
2. Gunakan ikon tipe item:
   - `📁` = folder
   - `📄` = file non-gambar
   - `🖼️` = file gambar (.png/.jpg/.jpeg/.gif/.webp)
3. Format 1 baris per item:
   - `<ikon> <nama item padded>  ← <tipe>`
4. Urutan listing:
   - pertahankan urutan alfabetis (case-insensitive) agar konsisten.
5. Header wajib:
   - baris judul konteks
   - baris path target
6. Jangan kirim raw tree ribuan baris kecuali diminta eksplisit.

---

## Template Final (Default)

```text
Isi iCloud Drive Rifuki
~/Library/Mobile Documents/com~apple~CloudDocs/<target>/

📄 <file_name_1>    ← file
📁 <folder_name_1>  ← folder
🖼️ <image_name_1>   ← file
```

---

## Contoh Nyata (Approved Style)

```text
Isi iCloud Drive Rifuki
~/Library/Mobile Documents/com~apple~CloudDocs/rifuki/

📄 .DS_Store                                    ← file
📁 .openclaw                                    ← folder
📁 .ssh                                         ← folder
🖼️ 2025_11_20_01_26_14_IMG_1343 DELETE GPP.GIF  ← file
📁 Artworks                                     ← folder
📁 Backup                                       ← folder
📁 Bondage                                      ← folder
📁 games                                        ← folder
📁 Macbook M1                                   ← folder
📁 Macbook M2                                   ← folder
📁 mgodonf                                      ← folder
📁 Other                                        ← folder
📁 Pictures                                     ← folder
📁 Web3                                         ← folder
```

---

## Decision Rule (Single vs Multi Bubble)

- Jika konten listing folder pakai alignment/template di atas:
  - kirim **dalam 1 bubble** (karena satu blok teks terstruktur).
- Jika ada chat sosial sebelum/sesudah listing:
  - chat sosial kirim bubble terpisah.
  - blok listing tetap 1 bubble.

Contoh:
1) Bubble 1: konfirmasi singkat.
2) Bubble 2: blok ```text``` listing.
3) Bubble 3: pertanyaan lanjutan (mau buka subfolder mana).

---

## Anti-Pattern (Jangan Dilakukan)

- Jangan pakai format paragraf acak tanpa alignment.
- Jangan campur ikon folder/file tidak konsisten.
- Jangan pakai panah tidak sejajar di plain text non-monospace.
- Jangan kirim dump penuh 10k+ baris tanpa diminta.

---

## One-Line Reminder for Other AIs

"Untuk tampilan folder Rifuki: selalu pakai blok ```text``` yang sejajar, ikon tipe item (📁/📄/🖼️), format `<ikon> <nama> ← <tipe>`, dan sertakan contoh approved style bila perlu."
