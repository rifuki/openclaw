# OpenClaw Setup Flow (Doloris + Miku)

Stable setup flow for this private repo: Doloris + Miku, with per-agent WhatsApp routing and per-agent Codex auth.

## Quickstart

```bash
# 1) add agent(s)
openclaw agents add

# 2) login channel account(s)
openclaw channels login --channel whatsapp --account doloris
openclaw channels login --channel whatsapp --account miku

# 3) login Codex OAuth for that account
openclaw configure --section model

# 4) normalize auth profile for only that agent
~/.openclaw/scripts/normalize-codex-auth.sh doloris
~/.openclaw/scripts/normalize-codex-auth.sh miku
openclaw gateway restart
```

## 0) Create agents first (required)

`normalize-codex-auth.sh` does not create agent folders or auth files from zero.
Create each agent first, then run channel/model auth flows.

```bash
openclaw agents add
```

Repeat for each agent id you want (for example `doloris`, `miku`, `alpha`, `beta`).

Verify:

```bash
openclaw agents
```

## 1) Agent <-> Channel binding (routing)

Use `openclaw.json` bindings to route each channel account to one agent.

Example:

```json
"bindings": [
  { "agentId": "doloris", "match": { "channel": "whatsapp", "accountId": "doloris" } },
  { "agentId": "miku", "match": { "channel": "whatsapp", "accountId": "miku" } }
]
```

## 2) Login channel credentials per account

```bash
openclaw channels login --channel whatsapp --account doloris
openclaw channels login --channel whatsapp --account miku
```

Credentials land in:

- `~/.openclaw/credentials/whatsapp/doloris/`
- `~/.openclaw/credentials/whatsapp/miku/`

Account ids can be custom. The only requirement is that bindings map each
`accountId` to an existing `agentId`.

## 3) Login OpenAI Codex OAuth (when needed)

Run OAuth flow:

```bash
openclaw configure --section model
```

After this, OpenClaw may create `openai-codex:default` profiles.

If an agent auth file does not exist yet, run the model auth flow once for that
agent before normalize.

### OAuth with different accounts per agent

If Doloris and Miku use different ChatGPT/Codex accounts, do this separately:

1. Login account for Doloris via `openclaw configure --section model`
2. Normalize only Doloris
3. Login account for Miku via `openclaw configure --section model`
4. Normalize only Miku

Do **not** normalize both agents after a single login if accounts are different.

## 4) Normalize auth profiles (important)

Run this immediately after model configure:

```bash
~/.openclaw/scripts/normalize-codex-auth.sh <agentId>
openclaw gateway restart
```

Examples:

```bash
~/.openclaw/scripts/normalize-codex-auth.sh doloris
openclaw gateway restart

~/.openclaw/scripts/normalize-codex-auth.sh miku
openclaw gateway restart
```

Optional cleanup of global default profile in `agents/main`:

```bash
~/.openclaw/scripts/normalize-codex-auth.sh --purge-main-default doloris
~/.openclaw/scripts/normalize-codex-auth.sh --purge-main-default miku
```

What it does:

- Renames `openai-codex:default` -> `openai-codex:<agentId>` for the target agent
- Pins auth order for that agent (`openai-codex:<agentId>`)
- Removes `openai-codex:default` from target agent if specific profile already exists
- Optional: `--purge-main-default` to remove `openai-codex:default` from `agents/main`

Manual commands (without script):

```bash
# pin profile selection per agent/provider
openclaw models auth order set --agent doloris --provider openai-codex openai-codex:doloris
openclaw models auth order set --agent miku --provider openai-codex openai-codex:miku

# verify pinning
openclaw models auth order get --agent doloris --provider openai-codex
openclaw models auth order get --agent miku --provider openai-codex
```

## 5) Verify

```bash
openclaw agents
openclaw channels status
openclaw models --agent doloris
openclaw models --agent miku
openclaw models auth order get --agent doloris --provider openai-codex
openclaw models auth order get --agent miku --provider openai-codex
```

## Notes

- Avoid `openclaw doctor --fix` unless needed.
- If `doctor`/`configure` reintroduces `openai-codex:default`, rerun step 4 for the same agent.
- `normalize-codex-auth.sh` skips agents that do not have an auth store file yet.
- Kimi keys are static API keys in each agent auth file:
  - `~/.openclaw/agents/doloris/agent/auth-profiles.json`
  - `~/.openclaw/agents/miku/agent/auth-profiles.json`
