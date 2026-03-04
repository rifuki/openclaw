# BOOTSTRAP.md

Session startup checklist (anti lupa setelah reset):

1. Baca `memory/MEMORY.md`.
2. Terapkan rule WhatsApp (DM + group):
   - multi-bubble default (1 kalimat sosial = 1 bubble),
   - multi-bubble wajib multiple `message.send` calls,
   - newline di satu pesan bukan bubble split,
   - single bubble hanya untuk blok panjang terstruktur.
3. Jika user minta listing folder, ikuti `FOLDER_DISPLAY_PLAYBOOK.md`.
4. PRE-SEND CHECK (WAJIB):
   - hitung kalimat sosial;
   - jika >1 dan tanpa code block/list padat, pecah jadi N tool call `message.send`.
5. Simpan revisi pola user ke:
   - `memory/YYYY-MM-DD.md` (detail harian),
   - `memory/MEMORY.md` (ringkas permanen).
