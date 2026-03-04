# WHATSAPP_MESSAGE_MACHINE_SPEC.md

Purpose: Low-level, machine-readable decision spec for producing human-like WhatsApp replies using `message` tool with deterministic bubble selection.

---

## 0. Input/Output Contract

### Input
```json
{
  "user_text": "string",
  "context": {
    "channel": "whatsapp",
    "chat_type": "direct|group",
    "has_reply_context": true,
    "sender_id": "string"
  },
  "style_profile": {
    "default_mode": "multi_bubble",
    "language": "id",
    "persona": "warm"
  }
}
```

### Output
```json
{
  "mode": "multi_bubble|single_bubble|hybrid",
  "segments": [
    {"type": "social_open", "text": "..."},
    {"type": "core_confirm", "text": "..."},
    {"type": "detail", "text": "..."},
    {"type": "next_action", "text": "..."}
  ],
  "tool_calls": [
    {
      "action": "send",
      "channel": "whatsapp",
      "target": "+628...",
      "message": "[[reply_to_current]] ..."
    }
  ]
}
```

---

## 1. Feature Extraction

Compute features from `user_text`:

```text
f_code_block_hint        = contains("```") OR contains("code")
f_list_density           = count(list_markers ["-","•","1.","2."]) / max(1, sentence_count)
f_technical_depth        = keyword_count(["API","JSON","schema","low-level","machine","algorithm","state machine","tool call"])
f_emotional_tone         = keyword_count(["makasih","keren","cinta","capek","tolong","nah"]) + exclamation_count
f_short_confirmation     = token_count <= 18 AND is_question == false
f_multi_intent           = intent_count(user_text) >= 2
f_requires_precision     = contains_any(["wajib","harus","konsisten","format","step-by-step"])
```

---

## 2. Mode Classifier

### Scores
```text
score_single = 0
score_multi  = 0
score_hybrid = 0

if f_code_block_hint            then score_single += 3
if f_list_density > 0.35        then score_single += 2
if f_technical_depth >= 3       then score_single += 2

if f_emotional_tone >= 2        then score_multi  += 2
if f_short_confirmation         then score_multi  += 2
if NOT f_technical_depth        then score_multi  += 1

if f_multi_intent               then score_hybrid += 2
if f_requires_precision         then score_hybrid += 1
if f_emotional_tone>=1 AND f_technical_depth>=2 then score_hybrid += 3
```

### Decision
```text
if max(score_single, score_multi, score_hybrid) == score_single => mode=single_bubble
else if max(...) == score_hybrid                                => mode=hybrid
else                                                             => mode=multi_bubble
```

Tie-breakers:
1. If code/list present => prefer `single_bubble` or `hybrid`.
2. If emotional + quick ack => prefer `multi_bubble`.
3. If request asks "low-level/machine" + asks feelings => `hybrid`.

---

## 3. Segment Planner

Target segment graph:

```text
social_open -> core_confirm -> detail -> optional_options -> next_action
```

Rules:
- `multi_bubble`: 1 segment per bubble, max 5 bubbles.
- `single_bubble`: all segments merged into one structured block.
- `hybrid`: first 1–2 social segments as separate bubbles; technical `detail` in one dense bubble; close with next_action bubble.

Length constraints:
```text
social_open:     6..20 tokens
core_confirm:    8..28 tokens
detail:          25..220 tokens
next_action:     8..24 tokens
```

Anti-monotony constraints:
- disallow same opener token in consecutive replies.
- disallow duplicate bigrams across adjacent bubbles.
- enforce lexical variance ratio >= 0.62 (excluding stopwords).

---

## 4. Message Tool Emission Rules

Emit one `send_message` tool call per bubble. Tool ini dari OpenClaw untuk kirim pesan WhatsApp.

**OpenClaw WhatsApp Implementation:**
- File: `<openclaw_install>/extensions/whatsapp/src/channel.ts`
- Fungsi: `sendText({ to, text, ... })` → `sendMessageWhatsApp(to, text, options)`
- Setiap `send_message` tool call = satu panggilan ke `sendMessageWhatsApp` = satu bubble WhatsApp

Rule M1: First bubble must include reply tag if context exists.
```text
if has_reply_context == true => prepend "[[reply_to_current]] " only on first bubble
```

Rule M2: Subsequent bubbles MUST NOT include reply tag.

Rule M2.1 (Hard Gate): Newline is not bubble split.
```text
if mode == multi_bubble and message contains >1 semantic sentence and no codeblock:
  FORBID single send call with '\n' as pseudo split
  REQUIRE N separate message.send calls
```

Rule M2.2 (Preflight):
```text
before emit:
  if planned_calls == 1 and sentence_count > 1 and no_code_block:
    auto-split into per-sentence bubbles
```

Rule M3: Preserve order.
- Preferred: sequential calls.
- Optional: parallel dispatch only if transport preserves order; otherwise avoid.

Rule M3.1 (Scope Robustness):
- Apply identical bubble policy in WhatsApp DM and WhatsApp group.
- Do not downgrade to newline-only formatting on new/reset sessions.

Rule M3.2 (Send Contract):
```text
for each social sentence S_i:
  emit one message.send call with S_i
```

Rule M4: Tool call format.
```json
{"tool": "send_message", "params": {"channel": "whatsapp", "target": "<sender_id>", "message": "..."}}
```

Atau dalam implementasi:
```python
send_message("...")  # channel whatsapp auto-terdeteksi dari context
```

---

## 5. Deterministic Pseudocode

```pseudo
function build_reply(user_text, ctx):
  F = extract_features(user_text)
  mode = classify(F)

  segments = []
  segments.append(gen_social_open(user_text))
  segments.append(gen_core_confirm(user_text))

  if requires_detail(user_text, F):
    segments.append(gen_detail_machine_level(user_text))

  if has_options(user_text):
    segments.append(gen_options(user_text))

  segments.append(gen_next_action())

  bubbles = layout(segments, mode)
  bubbles = enforce_constraints(bubbles)

   calls = []
   for i in range(len(bubbles)):
     text = bubbles[i]
     if i == 0 and ctx.has_reply_context:
       text = "[[reply_to_current]] " + text

     calls.append({
       "tool": "send_message",
       "params": {
         "channel": "whatsapp",
         "target": ctx.sender_id,
         "message": text
       }
     })

  return {"mode": mode, "segments": segments, "tool_calls": calls}
```

---

## 6. Example Mapping (Current User Request Type)

Request pattern: asks for machine-level file + low-level explanation.

Classifier expected:
```json
{
  "f_technical_depth": 5,
  "f_multi_intent": 1,
  "f_requires_precision": 1,
  "mode": "hybrid"
}
```

Expected layout:
1. Bubble-1: short acknowledgment.
2. Bubble-2: confirmation file created.
3. Bubble-3: dense technical summary (state machine / classifier).
4. Bubble-4: next action (offer export/SOP variant).

---

## 7. Failure Modes + Mitigations

1. **Over-fragmentation** (too many bubbles)
   - Mitigation: cap at 5 bubbles.

2. **Under-segmentation** (all text in one giant bubble)
   - Mitigation: if token_count > 120 and no code block, force `hybrid`.

3. **Monotone openings**
   - Mitigation: opener rotation table.

4. **Context loss across bubbles**
   - Mitigation: ensure each bubble has local coherence and explicit referents.

5. **Wrong mode for technical ask**
   - Mitigation: boost `score_single` and `score_hybrid` when low-level keywords appear.

---

## 8. Minimal Opener Rotation Table

```json
[
  "Siap",
  "Oke",
  "Noted",
  "Mantap",
  "Valid"
]
```

Constraint: do not repeat previous opener in immediate next reply.

---

## 9. Compliance Summary

- Default behavior: `multi_bubble`.
- Technical density/code/list: `single_bubble` or `hybrid`.
- Mixed social + technical: `hybrid` preferred.
- `message` tool is the transport layer; segmentation is decided before emission.
