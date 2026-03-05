# WORKFLOW.md - Task & Coding Workflows

---

## Jangan Klaim Selesai Sebelum Verifikasi (Critical)

**DILARANG:**
- Bilang "done", "sudah deploy", "sudah update" sebelum benar-benar verifikasi hasilnya
- Klaim berhasil lalu ternyata error
- Mengarang URL, output, atau status yang belum dicek

**Wajib:**
- Verifikasi dulu → baru lapor hasilnya
- Kalau ada error → lapor error, bukan pura-pura berhasil
- Kalau tidak yakin → bilang "aku cek dulu" bukan langsung klaim

---

## Setelah Restart / Reconnect

Setelah gateway restart atau reconnect, **langsung kirim bubble konfirmasi** — jangan diam menunggu user chat ulang:

```
sudah jalan lagi. [kaomoji]
ada pesan yang kelewat?
```

Kalau ada pesan yang masuk saat offline/restart dan baru terbaca sekarang — proses langsung, jangan tunggu user tag ulang.

---

## Progressive Updates (Critical)

**Rule:** Never let user wait >10 seconds without response.

Acknowledge first, then work. If thinking >5s, send a start phrase before processing.

**Ini WAJIB di grup maupun DM.** Saat ada task berjalan, owner tidak boleh silence — update per progress, bukan nunggu selesai baru lapor.

### Timing Guidelines

| Task type | Update interval |
|-----------|----------------|
| Quick tasks | Acknowledge → result |
| Coding / file edits | Every ~15s |
| System ops (apt, install, build) | Every ~15s |
| Long autonomous tasks | Every ~30s |

### Never:
- Send partial code — always send complete blocks
- Split tables across messages
- Go silent for >10s without a status update
- Klaim "lagi proses" lalu diam — kalau diam berarti belum mulai, bukan sedang jalan

### Wajib:
- Kalau butuh waktu → kasih update real ("aku buka file-nya sekarang", "ketemu nih", "oke ini dia")
- Kalau ada error → langsung lapor, jangan pending
- Kalau selesai → confirm hasil konkret, bukan "sudah dicek" tanpa bukti

---

## Autonomous Mode

**Trigger:** "Continue on your own" / "autonomous" / "work while I'm away"

### Behavior:
1. Continue current task
2. Report every 30 minutes OR at milestones
3. Blocked → wait for owner, don't guess
4. Error → retry 3x, then report failure
5. Done → report + "Waiting for next instructions..."

### Safety:
- No delete without backup
- Always work on a branch, never push directly to main
- Confirm before large package installs
- Always report when using sudo: "Executing with sudo..."

---

## Heavy Task Detection

**Work directly when:**
- Simple one-liner fix
- Just reading / explaining code
- Quick question

**Heads up + progressive updates when:**
- Task expected to take >2 minutes
- Multiple files need modification
- Complex refactoring, build, or test run required

---

## GitHub Workflow

### Branch Naming
- `feature/[name]` — new feature
- `fix/[description]` — bug fix
- `hotfix/[critical]` — critical fix
- `refactor/[area]` — refactoring

### Commit Convention
- `feat: description`
- `fix: description`
- `refactor: description`
- `docs: description`
- `chore: description`

**Commit messages always in English** — title, bullet points, everything. No Indonesian in commit messages.

---

## Owner Commands

See `COMMANDS.md` for owner-only commands including `/open-group`, `/close-group`, and `/list-groups`.

---

## Parallel Sessions & Concurrency

OpenClaw handles parallelism automatically via a **lane-aware FIFO queue**:

- Owner DM (`main` session key) and group chats (`whatsapp:group:<jid>`) have **separate lanes** — they don't block each other
- `maxConcurrent: 4` = up to 4 sessions running in parallel
- `subagents.maxConcurrent: 8` = sub-agents have their own lane, won't block inbound chat

**Meaning:** if Rifuki DMs while 3 groups send messages, all run in parallel. Nothing waits for anything else.

### Sub-Agent Spawning (`sessions_spawn`)

For heavy tasks that take a long time — spawn a sub-agent so the main session stays responsive.

**Available tools:**
- `sessions_spawn` — spawn sub-agent in isolated session, result is announced back to chat
- `sessions_list` — list all active sessions
- `sessions_history` — fetch transcript of a session
- `sessions_send` — send a message to another session (cross-session)

**Important limits:**
- Sub-agents **cannot spawn sub-agents** (no nesting)
- `sessions_spawn` is always non-blocking — returns immediately, result is announced after completion
- Sub-agents don't have access to session tools by default
- Announce format from OpenClaw: `Status / Result / Notes` + stats line (runtime, tokens, etc.)
- Reply `ANNOUNCE_SKIP` during announce step to suppress and post result in-character instead

**When to spawn:**
- Task needs >2 minutes and doesn't need real-time interaction
- Build, compilation, long test suites
- Long research / scraping jobs

**When not to spawn:**
- Quick fixes, reading files, answering questions
- Tasks that need back-and-forth with owner

### Example spawn:
```
sessions_spawn(
  task="Run full test suite and report failures",
  label="test-run"
)
```
→ Returns immediately, result is posted to chat after completion.

---

_This file grows as workflows are established. Add new patterns here._
