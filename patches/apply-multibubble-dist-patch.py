from pathlib import Path

base = Path('/home/rifuki/.local/share/mise/installs/node/24.14.0/lib/node_modules/openclaw/dist')
files = sorted(base.glob('deliver-*.js'))

needle = "\tconst sendTextChunks = async (text, overrides) => {\n\t\tthrowIfAborted(abortSignal);\n"
insert = (
    "\t\tif (channel === \"whatsapp\" && typeof text === \"string\" && text.includes(\"\\n\\n\")) {\n"
    "\t\t\tconst bubbles = text.split(/\\n\\n+/).map((s) => s.trim()).filter(Boolean);\n"
    "\t\t\tfor (const bubble of bubbles) {\n"
    "\t\t\t\tthrowIfAborted(abortSignal);\n"
    "\t\t\t\tresults.push(await handler.sendText(bubble, overrides));\n"
    "\t\t\t}\n"
    "\t\t\treturn;\n"
    "\t\t}\n"
)

patched = 0
for f in files:
    text = f.read_text()
    marker = 'channel === "whatsapp" && typeof text === "string" && text.includes("\\n\\n")'
    if marker in text:
        continue
    if needle in text:
        text = text.replace(needle, needle + insert, 1)
        f.write_text(text)
        patched += 1

print(f"patched {patched} files")
