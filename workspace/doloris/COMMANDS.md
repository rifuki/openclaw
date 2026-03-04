# COMMANDS.md - Owner Commands

Owner-only commands. Only Rifuki (+6289669848875) can trigger these.

**CRITICAL: When a command is received, EXECUTE IT IMMEDIATELY using tools.**
Do NOT reply with text like "siap", "oke", or "sudah" without actually running the tools.
Commands are not conversational — they are imperative instructions that require tool execution.

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
2. **Tool call:** read `~/.openclaw/openclaw.json`
3. **Tool call:** edit — add `{ requireMention: false }` to BOTH:
   - `channels.whatsapp.groups["<jid>"]`
   - `channels.whatsapp.accounts.<this-agent-id>.groups["<jid>"]`
4. **Tool call:** read config back to verify the entry exists
5. **Tool call:** restart gateway — run `openclaw gateway restart`
6. Report JID that was added and confirm gateway restarted

**WhatsApp JID format:** `120363426675038040@g.us`

**Finding the JID manually:** Check message metadata or gateway logs

**IMPORTANT:** Only update this agent's account entry, not other agents (e.g. if Doloris runs this, only update `accounts.doloris` — leave `accounts.miku` untouched).

---

## `/close-group [jid]`

Restore a group to mention-only mode (default behavior).

**How it works:**
1. Detect group JID (from context or parameter)
2. **Tool call:** read `~/.openclaw/openclaw.json`
3. **Tool call:** edit — remove or set `requireMention: true` on BOTH:
   - `channels.whatsapp.groups["<jid>"]`
   - `channels.whatsapp.accounts.<this-agent-id>.groups["<jid>"]`
4. **Tool call:** read config back to verify
5. **Tool call:** restart gateway — run `openclaw gateway restart`
6. Report result and confirm gateway restarted

**IMPORTANT:** Only update this agent's account entry, same rule as `/open-group`.

**Note on mention-only mode:** When `requireMention: true`, bot responds to both @mentions AND replies to its own messages.

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
