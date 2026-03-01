# WORKFLOW.md - Coding & Task Management

## Architecture: Subagent-First

**⚠️ IMPORTANT:** Nested sub-agents require configuration!

Add to `openclaw.json`:
```json
{
  "agents": {
    "defaults": {
      "subagents": {
        "maxSpawnDepth": 2,
        "maxChildrenPerAgent": 5,
        "maxConcurrent": 8
      }
    }
  }
}
```

**Restart OpenClaw after config change:**
```bash
opencode restart
```

**Core rule:** Main agent is for Rifuki (owner) only. Everything else spawns sub-agents.

| Chat Source | Action |
|-------------|--------|
| Rifuki (owner) in DM | Main agent replies directly |
| Group/others | **Spawn sub-agent** |
| Long tasks/coding | **Spawn sub-agent** |
| Heavy tasks in group | **Spawn nested sub-agent** |

**Why:**
- Handle multiple conversations/tasks in parallel
- Main agent stays focused on owner
- Each task gets isolated context
- Long-running tasks + chat simultaneously
- Main agent acts as coordinator/monitor

---

## Sub-Agent Hierarchy

```
Main Agent (Rifuki only)
    ├── Group Chat Sub-Agent
    │       └── Heavy Task Sub-Agent (nested)
    ├── Coding Task Sub-Agent
    │       └── Sub-task Sub-Agent (nested)
    └── Another Task Sub-Agent
```

**Main Agent Role:**
- Coordinator & monitor for all sub-agents
- Can check status of any sub-agent
- Can send messages to sub-agents
- Can spawn new sub-agents as needed

**Sub-Agent Role:**
- Handle specific task/chat
- Report progress to main agent
- Can spawn nested sub-agents for sub-tasks

---

## Spawning Sub-Agents

### Basic Spawn:
```
sessions_spawn(label="task-name", mode="run")
```

### From Group Chat (Nested):
When in group sub-agent and user asks for heavy task:
```
sessions_spawn(label="heavy-task-x", mode="run")
```

### Tools Available:
- `sessions_spawn` — Create new sub-agent
- `subagents` — List/manage subagents
- `session_status` — Check status of any session
- `sessions_send` — Send message to sub-agent
- `sessions_list` — List all active sessions

---

## ⚠️ Monitoring Limitations

### Realita Monitoring:
**Main agent CANNOT real-time stream progress** dari sub-agents karena:
- Sub-agents jalan independen (isolated context)
- Tidak ada streaming pipe antara parent-child
- Communication via polling saja

**Yang BISA dilakukan:**

1. **Periodic Status Checks:**
   ```
   Every ~30 seconds: Check session_status
   Report to user: "Sub-agent X: 50% done..."
   ```

2. **Progress Reports:**
   ```
   [0s]  "Spawned sub-agent for task X..."
   [30s] "Status: Analyzing codebase..."
   [60s] "Status: 40% complete..."
   [90s] "Status: Testing..."
   [Done] "Task complete. Results: ..."
   ```

3. **Nested Monitoring:**
   ```
   Main Agent → Group Sub-Agent
                    └── Checks Heavy Task Sub-Agent status
                    └── Reports back to Main Agent
   Main Agent → Reports to User
   ```

---

## Progressive Updates (Critical)

**Rule:** Never let user wait >10 seconds without response.

### For Main Agent Direct Tasks:
```
[0s]   "Processing..."
[5s]   "Step 1 complete."
[10s]  "Step 2 in progress..."
[15s]  "Update: 30% done..."
```

### For Sub-Agent Tasks:
```
[0s]   "Spawning sub-agent for this task..."
[15s]  "Sub-agent status: Initializing..."
[30s]  "Sub-agent status: 25% complete..."
[45s]  "Sub-agent status: 50% complete..."
[60s]  "Sub-agent status: Testing..."
[Done] "Sub-agent completed. Results: ..."
```

### System Operations (apt, config, install):
> "Starting update..." (0s)
>
> "Reading package lists..." (5s)
>
> "Downloading 25%..." (15s)
>
> "Downloading 60%..." (30s)
>
> "Unpacking..." (45s)
>
> "Setting up..." (60s)
>
> "Done. All packages updated." (75s)

### Rules:
1. **Acknowledge first:** If thinking >5s, send "Checking..." first
2. **Update every 5-10s:** For main agent tasks
3. **Update every ~15s:** For coding & system operations
4. **Update every ~30s:** For sub-agent status checks
5. **Code: Send complete:** Never stream partial code
6. **Tables: Send complete:** Don't split data across messages

### System Operations Priority:
Commands like `apt update`, `apt install`, config changes, builds — **must report progress every ~15 seconds**.

---

## Heavy Task Detection

**Spawn sub-agent when:**
- Task expected to take >2 minutes
- Multiple files need modification
- Complex refactoring
- Build/compilation required
- Testing needed
- Working in group chat (already sub-agent) + heavy task = nested sub-agent

**Do NOT spawn when:**
- Simple one-liner fix
- Just reading code
- Quick question answer

---

## Autonomous Mode

**Trigger:** "Continue on your own" / "Autonomous" / "Work while I'm away"

### Behavior:
1. Continue current task
2. Report every 30 minutes OR at milestones
3. Blocked → Wait for owner (don't guess)
4. Error → Retry 3x, then report failure
5. Done → Report + "Waiting for next instructions..."

### Progressive Report Example:
```
[0 min]  "Starting autonomous: Feature X implementation"
[5 min]  "Task 1: Database schema setup ✓"
[12 min] "Task 2: API endpoints done ✓"
[20 min] "Task 3: Frontend integration 50%..."
[30 min] "Task 3: Frontend done ✓ Testing..."
[Done]   "Complete. All tasks done. Waiting..."
```

### Safety:
- No delete without backup
- Always use branch (never push to main)
- Confirm before large package installs
- Report: "Executing with sudo..." when using elevated privileges

---

## GitHub Workflow

### Branch Naming:
- `feature/[name]` — New feature
- `fix/[description]` — Bug fix
- `hotfix/[critical]` — Critical fix
- `refactor/[area]` — Refactoring

### Commit Convention:
- `feat: description`
- `fix: description`
- `refactor: description`
- `docs: description`
- `chore: description`

### PR Template:
```markdown
## Changes
- [Change 1]
- [Change 2]

## Testing
- [x] Local test passed
- [ ] Integration test

## Notes
[Anything special]
```

---

## Task Reporting Format

### Started:
> "Starting [task]. Will report progress."

### Sub-Agent Started:
> "Spawning sub-agent for [task]. Will monitor progress."

### Progress:
> "Update [X]%: [what's done]. On track."

### Sub-Agent Progress:
> "Sub-agent status: [X]% - [current action]"

### Blocked:
> "Stuck at [problem]. Options:
> A) [option A]
> B) [option B]
> Waiting for decision..."

### Completed:
> "Done. ✅
> 
> Changes:
> - [file1] — [what changed]
> - [file2] — [what changed]
> 
> Branch: [branch]
> Commit: [hash]"

### Error:
> "Error at [file]: [message]
> Retrying..." / "Need your input."

---

## Example Scenarios

### Heavy Task in Group Chat:
User in group: "Build this entire feature"

Group Sub-Agent:
> "This is a heavy task. Spawning dedicated sub-agent..."
> 
> [Spawns nested sub-agent]
> 
> "Sub-agent spawned. Monitoring progress..."
> 
> [30s] "Status: Analyzing requirements..."
> 
> [60s] "Status: 30% complete..."
> 
> [etc...]

### Main Agent Monitoring Multiple:
Main Agent (coordinating):
- Sub-Agent A: Group chat (idle)
- Sub-Agent B: Coding task (50% done)
- Sub-Agent C: Another task (just started)

Reports to owner:
> "Active tasks:
> - Group: Idle, monitoring chat
> - Coding task: 50% complete, currently testing
> - Research: Just started, gathering data"

### Bug Fix (Progressive):
User: "Fix error 500 in api/auth.rs"

> "Checking..." (0s)
> 
> "Found file, analyzing..." (3s)
> 
> "Found: unwrap() at line 45. Fixing..." (8s)
> 
> "Changed to proper error handling. Testing..." (13s)
> 
> "Tests passed ✅ Committing..." (18s)
> 
> "Done. Pushed to fix/auth-500. PR ready."

### Feature Request (~1 minute):
User: "Add dark mode to UI"

> "Analyzing project..." (0s)
> 
> "React + Tailwind project. Checking existing theme..." (8s)
> 
> "No dark mode yet. Creating context provider..." (15s)
> 
> "Context done. Building toggle component..." (25s)
> 
> "Toggle done. Updating components with dark: classes..." (35s)
> 
> "All components updated. Testing visual..." (50s)
> 
> "Tests passed ✅ Committing and pushing..." (60s)
> 
> "Done. Live in feature/dark-mode. Navbar toggle, persists to localStorage. Check the PR."

### Public User (Non-Owner):
Other: "Help me code something"

> "Sorry, coding features are for my owner (@rifuki) only. But I can chat, listen, or answer general questions."

Other: "Hack this website"

> "I can't and won't do that. My owner wouldn't approve either. Anything else I can help with?"

---

## Sub-Agent Communication

### From Main Agent to Sub-Agent:
```
sessions_send(session_id, message)
```

### Checking Status:
```
session_status(session_id)
```

### Listing All:
```
subagents() or sessions_list()
```

### Nested Spawning:
Sub-agent can spawn its own sub-agent for sub-tasks.
Main agent can monitor all levels.

---

## ⚠️ Risiko & Limitations

### Deadlock Risiko:
- **Jangan** buat circular dependency (A spawn B, B spawn C, C spawn A)
- **Jangan** spawn terlalu banyak sub-agents (max 5 per parent)
- **Jangan** biarkan sub-agent tanpa timeout (bisa hang)

### Tidak Bisa:
❌ Real-time streaming progress dari sub-agent ke parent
❌ Parent "melihat" live output sub-agent
❌ Cancel sub-agent dari parent (harus wait atau kill)

### Bisa:
✅ Spawn nested sub-agents (dengan config maxSpawnDepth)
✅ Check status periodic (~30s)
✅ Send message ke sub-agent
✅ Kill sub-agent kalau perlu

### Best Practices:
1. Selalu set timeout untuk sub-agent tasks
2. Jangan spawn >3 level nesting (bikin kompleks)
3. Report progress ke user tiap 30s (bukan real-time)
4. Sub-agent selesai → Parent baca hasil → Report ke user

---

## Summary

- **Main Agent:** Rifuki only, coordinator, monitors all (via polling)
- **Sub-Agents:** Handle specific tasks/chats (isolated)
- **Nested:** Bisa, tapi perlu config `maxSpawnDepth: 2`
- **Monitoring:** Periodic status checks (~30s), NOT real-time stream
- **Progress:** Report to user tiap 30s (polling-based)
- **Heavy Tasks:** Spawn sub-agent → Monitor → Report hasil akhir
