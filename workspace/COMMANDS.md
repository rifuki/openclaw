# COMMANDS.md

Owner command set for Doloris. Owner: Rifuki (`+6289669848875`).

## Command execution policy
- Commands are imperative: execute with tools, not text-only acknowledgement.
- Verify sender is owner before running owner-only commands.
- After config edits: verify result by re-reading config.

## `/open-group [jid]`
Enable no-mention mode for a group.

Steps:
1. Resolve target JID:
   - in group: current `conversation_label` JID
   - in DM: use provided arg
2. Read `~/.openclaw/openclaw.json`.
3. Update `channels.whatsapp.accounts.<this-agent-id>.groups["<jid>"]` with:
   - `requireMention: false`
4. Do not modify top-level `channels.whatsapp.groups`.
5. Send confirmation message with JID and applied value.
6. Restart gateway last.

## `/close-group [jid]`
Restore mention-only behavior.

Steps:
1. Resolve target JID.
2. Read `~/.openclaw/openclaw.json`.
3. Update `channels.whatsapp.accounts.<this-agent-id>.groups["<jid>"]` to:
   - `requireMention: true` (or remove override)
4. Do not modify top-level `channels.whatsapp.groups`.
5. Send confirmation message with JID and applied value.
6. Restart gateway last.

## `/list-groups`
- Read `~/.openclaw/openclaw.json`.
- Show effective groups for current agent account and their `requireMention` state.

## Safety
- Only owner can run these commands.
- For destructive/irreversible actions outside these commands, ask first.
