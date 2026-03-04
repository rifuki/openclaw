# OpenClaw VPS Setup (Single Agent)

This guide is for a fresh VPS where this repo is cloned and you want to run only one agent (`doloris` or `miku`).

## Choose one mode

- `doloris`-only
- `miku`-only

Do not configure both unless you explicitly need dual-account runtime.

## 1) Install and start gateway service

```bash
openclaw gateway install --force
openclaw gateway restart
```

## 2) Switch config to single-agent mode

```bash
# Doloris-only
~/.openclaw/scripts/switch-active-agent.sh doloris

# OR Miku-only
~/.openclaw/scripts/switch-active-agent.sh miku
```

This updates `openclaw.json` to keep only the selected agent/binding/account.

## 3) Login WhatsApp for selected account

```bash
# If using Doloris-only
openclaw channels login --channel whatsapp --account doloris

# If using Miku-only
openclaw channels login --channel whatsapp --account miku
```

## 4) Configure model auth

```bash
openclaw configure --section model
```

## 5) Normalize Codex auth for selected agent

```bash
# Doloris-only
~/.openclaw/scripts/normalize-codex-auth.sh doloris

# OR Miku-only
~/.openclaw/scripts/normalize-codex-auth.sh miku
```

If needed, also purge global default profile:

```bash
~/.openclaw/scripts/normalize-codex-auth.sh --purge-main-default doloris
# or miku
```

## 6) Restart and verify

```bash
openclaw gateway restart
openclaw agents
openclaw channels status
openclaw doctor
```

## Optional: unlink/remove old account

```bash
~/.openclaw/scripts/unlink-whatsapp-accounts.sh doloris
# or miku
```

## Notes

- Runtime folders under `agents/` are local state and are not expected to come from git.
- If `configure` reintroduces `openai-codex:default`, rerun normalize for the selected agent.
- Keep auth files private (`chmod 600`) and credentials dir private (`chmod 700`).
