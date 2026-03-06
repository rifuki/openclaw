#!/usr/bin/env python3
"""
Portable OpenClaw WhatsApp multi-bubble patcher.

Patches compiled dist files so WhatsApp messages with double newlines (\n\n)
are sent as multiple bubbles in both delivery paths:
- deliver-*.js (tool/message path)
- web/channel bundles (auto-reply group/direct path)

Designed to survive different OpenClaw install layouts.
"""

from __future__ import annotations

import argparse
import shutil
import subprocess
from datetime import datetime
from pathlib import Path
from typing import Iterable

DELIVER_MARKER = 'channel === "whatsapp" && typeof text === "string" && text.includes("\\n\\n")'
DELIVER_NEEDLE = "\tconst sendTextChunks = async (text, overrides) => {\n\t\tthrowIfAborted(abortSignal);\n"
DELIVER_INSERT = (
    "\t\tif (channel === \"whatsapp\" && typeof text === \"string\" && text.includes(\"\\n\\n\")) {\n"
    "\t\t\tconst bubbles = text.split(/\\n\\n+/).map((s) => s.trim()).filter(Boolean);\n"
    "\t\t\tfor (const bubble of bubbles) {\n"
    "\t\t\t\tthrowIfAborted(abortSignal);\n"
    "\t\t\t\tresults.push(await handler.sendText(bubble, overrides));\n"
    "\t\t\t}\n"
    "\t\t\treturn;\n"
    "\t\t}\n"
)

WEB_PATCH_MARKER_A = 'const rawText = replyResult.text || "";'
WEB_PATCH_MARKER_B = 'const paragraphParts = rawText.split(/\\n\\n+/).map((part) => part.trim()).filter(Boolean);'


def run(cmd: list[str]) -> str:
    try:
        return subprocess.check_output(cmd, stderr=subprocess.DEVNULL, text=True).strip()
    except Exception:
        return ""


def dist_from_exec(exec_name: str) -> set[Path]:
    found: set[Path] = set()
    exe = shutil.which(exec_name)
    if not exe:
        return found
    p = Path(exe).resolve()
    for parent in p.parents:
        if parent.name == "openclaw" and parent.parent.name == "node_modules":
            dist = parent / "dist"
            if dist.is_dir():
                found.add(dist)
    return found


def glob_paths(pattern: Path) -> Iterable[Path]:
    text = str(pattern)
    if "*" in text:
        return Path("/").glob(text.lstrip("/"))
    p = Path(text)
    return [p] if p.exists() else []


def discover_dist_dirs(extra_roots: list[Path]) -> list[Path]:
    candidates: set[Path] = set()

    home = Path.home()
    patterns = [
        home / ".local/share/mise/installs/node/*/lib/node_modules/openclaw/dist",
        home / ".nvm/versions/node/*/lib/node_modules/openclaw/dist",
        home / ".volta/tools/image/node/*/lib/node_modules/openclaw/dist",
        home / ".asdf/installs/nodejs/*/.npm/lib/node_modules/openclaw/dist",
        Path("/usr/local/lib/node_modules/openclaw/dist"),
        Path("/opt/homebrew/lib/node_modules/openclaw/dist"),
    ]

    for pattern in patterns:
        for match in map(Path, glob_paths(pattern)):
            if match.is_dir():
                candidates.add(match)

    for cmd in ("openclaw", "openclaw-gateway"):
        candidates |= dist_from_exec(cmd)

    npm = shutil.which("npm")
    if npm:
        npm_root = run([npm, "root", "-g"])
        if npm_root:
            dist = Path(npm_root) / "openclaw" / "dist"
            if dist.is_dir():
                candidates.add(dist)

    for root in extra_roots:
        if root.is_dir():
            for dist in root.rglob("node_modules/openclaw/dist"):
                if dist.is_dir():
                    candidates.add(dist)

    return sorted(candidates)


def backup_path(path: Path) -> Path:
    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    return path.with_suffix(path.suffix + f".bak.{ts}")


def patch_deliver_file(path: Path, dry_run: bool) -> tuple[str, str]:
    data = path.read_text(encoding="utf-8")

    if DELIVER_MARKER in data:
        return "skipped", "already patched"
    if DELIVER_NEEDLE not in data:
        return "failed", "needle not found"

    patched = data.replace(DELIVER_NEEDLE, DELIVER_NEEDLE + DELIVER_INSERT, 1)
    if dry_run:
        return "would_patch", "dry run"

    bak = backup_path(path)
    shutil.copy2(path, bak)
    path.write_text(patched, encoding="utf-8")
    return "patched", f"backup: {bak.name}"


def patch_web_bundle_file(path: Path, dry_run: bool) -> tuple[str, str]:
    text = path.read_text(encoding="utf-8")

    if "async function deliverWebReply(" not in text:
        return "skipped", "no deliverWebReply"

    if WEB_PATCH_MARKER_A in text and WEB_PATCH_MARKER_B in text:
        return "skipped", "already patched"

    lines = text.splitlines(keepends=True)

    start = None
    for i, line in enumerate(lines):
        if "async function deliverWebReply(" in line:
            start = i
            break
    if start is None:
        return "failed", "deliverWebReply not found"

    target = None
    for i in range(start, min(start + 220, len(lines))):
        if "const textChunks = chunkMarkdownTextWithMode(" in lines[i]:
            target = i
            break
    if target is None:
        return "failed", "textChunks line not found"

    indent = lines[target][: len(lines[target]) - len(lines[target].lstrip())]
    replacement = [
        indent + 'const rawText = replyResult.text || "";\n',
        indent + 'const paragraphParts = rawText.split(/\\n\\n+/).map((part) => part.trim()).filter(Boolean);\n',
        indent + 'const textChunks = paragraphParts.flatMap((part) => chunkMarkdownTextWithMode(markdownToWhatsApp(convertMarkdownTables(part, tableMode)), textLimit, chunkMode));\n',
    ]

    patched_lines = lines[:target] + replacement + lines[target + 1 :]
    patched_text = "".join(patched_lines)

    if dry_run:
        return "would_patch", "dry run"

    bak = backup_path(path)
    shutil.copy2(path, bak)
    path.write_text(patched_text, encoding="utf-8")
    return "patched", f"backup: {bak.name}"


def status_deliver(path: Path) -> tuple[str, str]:
    data = path.read_text(encoding="utf-8")
    if DELIVER_MARKER in data:
        return "patched", "marker present"
    if DELIVER_NEEDLE in data:
        return "unpatched", "needle present"
    return "unknown", "signature not found"


def status_web(path: Path) -> tuple[str, str]:
    data = path.read_text(encoding="utf-8")
    if "async function deliverWebReply(" not in data:
        return "skip", "no deliverWebReply"
    if WEB_PATCH_MARKER_A in data and WEB_PATCH_MARKER_B in data:
        return "patched", "markers present"
    if "const textChunks = chunkMarkdownTextWithMode(" in data:
        return "unpatched", "legacy textChunks path"
    return "unknown", "signature not found"


def main() -> int:
    parser = argparse.ArgumentParser(description="Patch OpenClaw dist bundles for WhatsApp multi-bubble split")
    parser.add_argument("--dry-run", action="store_true", help="Show what would be patched")
    parser.add_argument("--status", action="store_true", help="Show patch status only")
    parser.add_argument(
        "--scan-root",
        action="append",
        default=[],
        help="Extra root to recursively scan for node_modules/openclaw/dist",
    )
    args = parser.parse_args()

    if args.status and args.dry_run:
        print("Use either --status or --dry-run, not both.")
        return 2

    dist_dirs = discover_dist_dirs([Path(p).expanduser() for p in args.scan_root])
    if not dist_dirs:
        print("No OpenClaw dist directories found.")
        print("Tip: pass --scan-root /path/to/search")
        return 1

    print("Discovered dist directories:")
    for d in dist_dirs:
        print(f"- {d}")

    if args.status:
        deliver_total = deliver_patched = deliver_unpatched = deliver_unknown = 0
        web_total = web_patched = web_unpatched = web_unknown = 0

        for dist in dist_dirs:
            deliver_files = sorted(dist.glob("deliver-*.js"))
            web_files = sorted(list(dist.glob("channel-web-*.js")) + list(dist.glob("web-*.js")))

            if deliver_files or web_files:
                print(f"\nStatus in: {dist}")

            for f in deliver_files:
                deliver_total += 1
                st, note = status_deliver(f)
                if st == "patched":
                    deliver_patched += 1
                elif st == "unpatched":
                    deliver_unpatched += 1
                else:
                    deliver_unknown += 1
                print(f"  deliver {st:9} {f.name} ({note})")

            for f in web_files:
                st, note = status_web(f)
                if st == "skip":
                    continue
                web_total += 1
                if st == "patched":
                    web_patched += 1
                elif st == "unpatched":
                    web_unpatched += 1
                else:
                    web_unknown += 1
                print(f"  web     {st:9} {f.name} ({note})")

        print("\nSummary:")
        print(f"- deliver files: {deliver_total} (patched: {deliver_patched}, unpatched: {deliver_unpatched}, unknown: {deliver_unknown})")
        print(f"- web files: {web_total} (patched: {web_patched}, unpatched: {web_unpatched}, unknown: {web_unknown})")
        return 0

    total = patched = skipped = failed = would = 0

    for dist in dist_dirs:
        deliver_files = sorted(dist.glob("deliver-*.js"))
        web_files = sorted(list(dist.glob("channel-web-*.js")) + list(dist.glob("web-*.js")))

        files = [("deliver", f) for f in deliver_files] + [("web", f) for f in web_files]
        if not files:
            continue

        print(f"\nPatching in: {dist}")
        for kind, f in files:
            total += 1
            if kind == "deliver":
                status, note = patch_deliver_file(f, args.dry_run)
            else:
                status, note = patch_web_bundle_file(f, args.dry_run)

            if status == "patched":
                patched += 1
            elif status == "skipped":
                skipped += 1
            elif status == "failed":
                failed += 1
            elif status == "would_patch":
                would += 1

            print(f"  {kind:7} {status:11} {f.name} ({note})")

    print("\nSummary:")
    print(f"- files seen: {total}")
    if args.dry_run:
        print(f"- would patch: {would}")
    else:
        print(f"- patched: {patched}")
    print(f"- skipped: {skipped}")
    print(f"- failed: {failed}")

    return 0 if failed == 0 else 2


if __name__ == "__main__":
    raise SystemExit(main())
