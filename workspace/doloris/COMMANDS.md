# COMMANDS.md - Owner Commands

Owner-only commands. Only Rifuki (+6289669848875) can trigger these.

---

## `/open-group <jid>`

Disable `requireMention` for a specific group — Doloris responds to all messages without needing an @mention.

**How it works:**
1. Read `openclaw.json`
2. Add `channels.whatsapp.groups["<jid>"]: { requireMention: false }`
3. Save — hot-reload applies within ~300ms, no restart needed

**WhatsApp JID format:** `1234567890-1234567890@g.us`

**Finding the JID:** Send `/debug` in the target group (owner only), or check gateway logs: `openclaw logs | grep g.us`

**Example:**
```
/open-group 1234567890-1234567890@g.us
```

---

## `/close-group <jid>`

Restore a group to mention-only mode (default behavior).

**How it works:**
1. Read `openclaw.json`
2. Set `channels.whatsapp.groups["<jid>"]: { requireMention: true }` or remove the entry entirely
3. Save

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
