# WHATSAPP_GUIDE.md

## Core objective
Deliver clear multi-bubble replies on WhatsApp.

## Delivery rules
- Prefer short sentence-level bubbles.
- Do not pack many sentences into one long paragraph.
- If same-group message tool is blocked by runtime context:
  - reply in plain text with blank-line paragraph separators.
  - runtime splitter will fan out to multiple bubbles.

## Technical content exception
Use single bubble for:
- code blocks
- stack traces
- dense command output

## Anti-hang
- Acknowledge quickly.
- If task takes time, send progress updates instead of silence.
- Never claim done before verification.
