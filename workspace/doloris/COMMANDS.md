# COMMANDS.md - Owner Commands

Owner-only commands. Only Rifuki (+6289669848875) can trigger these.

---

## `/open-group [jid]`

Disable `requireMention` for a group — Doloris responds to all messages without needing an @mention.

**Usage:**

1. **Called from within a group (no JID needed):**
   ```
   /open-group
   ```
   - Auto-detect current group JID from message context
   - Add to whitelist with `requireMention: false`

2. **Called from DM with explicit JID:**
   ```
   /open-group 120363426675038040@g.us
   ```

**How it works:**
1. Detect group JID (from context or parameter)
2. Read `openclaw.json`
3. Add entry to BOTH:
   - `channels.whatsapp.groups["<jid>"]: { requireMention: false }`
   - `channels.whatsapp.accounts.doloris.groups["<jid>"]: { requireMention: false }`
   - `channels.whatsapp.accounts.miku.groups["<jid>"]: { requireMention: false }`
4. Save file with proper JSON formatting
5. Config auto-reloads (~300ms), no restart needed
6. **VERIFY** by reading config back and confirming entry exists
7. Report success with group JID shown

**WhatsApp JID format:** `120363426675038040@g.us`

**Finding the JID manually:** Check message metadata or gateway logs

**IMPORTANT:** Must add to ALL THREE locations for bot to work in that group without mention.

---

## `/close-group <jid>`

Restore a group to mention-only mode (default behavior).

**How it works:**
1. Read `openclaw.json`
2. Set `channels.whatsapp.groups["<jid>"]: { requireMention: true }` or remove the entry entirely
3. Save

**Note on mention-only mode:** When `requireMention: true`, Doloris responds to both @mentions AND replies to her own messages. Replying to a Doloris message counts as an implicit mention — no explicit `@Doloris` needed.

---

## `/list-groups`

Show all groups configured in `openclaw.json` (everything under `channels.whatsapp.groups`).

**How it works:**
1. Read `openclaw.json`
2. Extract and display `channels.whatsapp.groups` contents

---

## Note on Group Invites

OpenClaw has no event hook for "bot was added to a new group."

Doloris will respond automatically when the first message arrives from a new group — as long as `groupPolicy` is not `disabled` and the sender is in `allowFrom`. Owner notification is manual (check logs, or ask Doloris directly).

---

## Access & Safety Rules

- All commands above are **owner-only** — verify sender before executing
- Owner (Rifuki) has **full access** — exec, bash, elevated tools, everything
- For actions requiring confirmation (destructive, irreversible, or outbound): propose first, wait for owner approval, then execute
- The `!` prefix in chat triggers direct bash execution via OpenClaw — this is different from agent-initiated exec tools (which go through normal confirmation flow)
- After modifying `openclaw.json`, confirm to owner that the change was saved
