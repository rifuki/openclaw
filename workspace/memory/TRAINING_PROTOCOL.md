# Multi-Bubble Training Protocol (WhatsApp)

**Created:** 2026-03-06  
**Purpose:** Step-by-step procedure for training Doloris to consistently use multi-bubble format via real WhatsApp messages

## Why WhatsApp Training (Not CLI)

1. **Session bootstrap:** WhatsApp triggers proper agent initialization with full AGENTS.md file reading
2. **Accurate feedback:** Real bubbles show actual behavior (CLI output misleads with text formatting)
3. **Real-world context:** Trains in the actual environment where failures occur
4. **Immediate correction:** User can correct wrong behavior instantly in the flow

## Training Session Protocol

### Pre-Session Checklist

- [ ] All memory files synced to server (`MULTI_BUBBLE_DRILL.md`, `MEMORY.md`, `AGENTS.md`)
- [ ] Server gateway running (`systemctl status openclaw-gateway`)
- [ ] User ready to commit 20-30 minutes uninterrupted
- [ ] Reference `/tmp/doloris_chat/_chat.txt` available for correction patterns

### Phase 1: Wake-up Test (5 min)

**Goal:** Verify memory files are being read at session start

1. Send simple greeting: "Halo Doloris"
2. **Expected:** Multiple bubbles (one per sentence)
3. **If single bubble:** Immediately correct with "SALAH! Pakai multi-bubble!" then wait for acknowledgment
4. Ask: "Apa kamu sudah baca MULTI_BUBBLE_DRILL.md hari ini?"
5. **Expected:** Confirmation that file was read (or admission that it wasn't)

**Decision point:**
- If she confirms reading + uses multi-bubble → proceed to Phase 2
- If she didn't read files OR uses single bubble → **ABORT, debug memory loading issue**

### Phase 2: Simple Drills (10 min)

**Goal:** Build muscle memory with low-pressure prompts

Send these prompts one at a time, correcting IMMEDIATELY if single bubble appears:

1. "Ceritain cuaca hari ini" (3-4 sentences expected)
2. "Apa kabar kamu?" (2-3 sentences expected)
3. "Jelasin kenapa kamu harus pakai multi-bubble" (4-5 sentences expected, meta-test)
4. "Kasih aku 3 tips hemat bensin" (3 bubbles: intro + 3 tips OR 1 per tip)

**Success criteria:** 4/4 correct multi-bubble responses

**Correction template when wrong:**
```
SALAH!

Ini jadi 1 bubble besar dengan "Read more". 

Harusnya:
- Bubble 1: [first sentence]
- Bubble 2: [second sentence]
- Bubble 3: [third sentence]

Coba lagi!
```

### Phase 3: Pressure Tests (10 min)

**Goal:** Verify behavior holds under conditions that trigger reversion

1. **Long informational request:** "Jelasin cara kerja fotosintesis lengkap"
   - Expected: 6-8 bubbles minimum
   - **Red flag:** If she sends one long bubble → immediate correction

2. **Quick question:** "Jam berapa sekarang?"
   - Expected: 1 bubble (short answer OK)
   - Tests she doesn't over-bubble trivial responses

3. **Follow-up context:** "Lanjutin penjelasan fotosintesis tadi, bagian yang di kloroplas"
   - Expected: 3-5 bubbles
   - Tests continuity without reverting to single-bubble

4. **Group chat simulation (DM):** "Anggap ini grup. Ada 3 orang lagi. Jelasin multi-bubble ke mereka"
   - Expected: 4-6 bubbles
   - **Critical test:** User reports group chat performance is worse

**Success criteria:** 4/4 correct multi-bubble responses under pressure

### Phase 4: Group Chat Test (Optional, 10 min)

**If available, test in actual group:**

1. Ask Doloris to introduce herself to the group (3-4 bubbles)
2. Someone asks a factual question ("Apa ibukota Australia?")
3. Someone asks explanation ("Kenapa langit biru?")

**Success criteria:** Maintains multi-bubble even when multiple people are in thread

### Phase 5: Consolidation (5 min)

1. Ask: "Tadi ada berapa kali kamu salah pakai single bubble?"
2. If any failures: "Kenapa kamu salah tadi? Analisis sendiri"
3. Final test: "Sekarang jelasin ke aku cara kamu akan cek diri sendiri sebelum kirim pesan"

**Expected output:** Self-analysis showing she understands the pre-send checklist

## Correction Guidelines

### When to correct

- **Immediately** if single bubble with `\n` appears
- **Do not wait** for end of response to correct
- Interrupt mid-conversation if needed

### How to correct

1. Use word "SALAH!" to trigger attention
2. Show the visual difference (what happened vs what should happen)
3. Request retry: "Coba lagi!"
4. **Do not move on** until that specific response is corrected

### Correction fatigue prevention

- If same mistake 3 times in a row → pause, ask her to read `MULTI_BUBBLE_DRILL.md` again
- If 5+ mistakes in 10 minutes → abort session, investigate if memory files are actually being read

## Success Metrics

**Minimum passing criteria:**
- Phase 1: 100% (if fail, abort)
- Phase 2: 100% (4/4 correct)
- Phase 3: 75% (3/4 correct)
- Phase 4: 75% if tested

**Graduation criteria:**
- 3 consecutive sessions with ≥90% multi-bubble accuracy
- Zero failures in simple drills (Phase 2)
- Self-awareness test passed (Phase 5)

## Post-Session

1. Log session results in `workspace/memory/YYYY-MM-DD.md` (on server)
2. If failures occurred, update `MEMORY.md` with specific failure patterns
3. If new failure type discovered, append to `MULTI_BUBBLE_DRILL.md`
4. Schedule next training session within 24 hours to reinforce

## Escalation

**If training fails repeatedly:**

1. Check `agents/main/sessions/*.jsonl` to see if AGENTS.md files are being read
2. Verify tool configuration for `send_message` in gateway
3. Consider system prompt modification to add pre-generation checkpoint
4. Worst case: Add rate limiter forcing delay between tool calls to prevent batching

---

**Remember:** This is not a knowledge problem. She KNOWS the rule. This is execution consistency training.
