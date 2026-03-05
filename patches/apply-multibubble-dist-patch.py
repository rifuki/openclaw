#!/usr/bin/env python3
"""
Portable OpenClaw WhatsApp multi-bubble patcher.

Patches compiled dist files (deliver-*.js) so WhatsApp text containing
double newlines (\n\n) is split into multiple sends.

Designed to survive different OpenClaw install methods/paths.
"""

from __future__ import annotations

import argparse
import shutil
import subprocess
from datetime import datetime
from pathlib import Path


MARKER = 'channel === "whatsapp" && typeof text === "string" && text.includes("\\n\\n")'
NEEDLE = "\tconst sendTextChunks = async (text, overrides) => {\n\t\tthrowIfAborted(abortSignal);\n"
INSERT = (
    "\t\tif (channel === \"whatsapp\" && typeof text === \"string\" && text.includes(\"\\n\\n\")) {\n"
    "\t\t\tconst bubbles = text.split(/\\n\\n+/).map((s) => s.trim()).filter(Boolean);\n"
    "\t\t\tfor (const bubble of bubbles) {\n"
    "\t\t\t\tthrowIfAborted(abortSignal);\n"
    "\t\t\t\tresults.push(await handler.sendText(bubble, overrides));\n"
    "\t\t\t}\n"
    "\t\t\treturn;\n"
    "\t\t}\n"
)


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


def glob_paths(pattern: Path):
    text = str(pattern)
    if "*" in text:
        return Path("/").glob(text.lstrip("/"))
    p = Path(text)
    return [p] if p.exists() else []


def patch_file(path: Path, dry_run: bool) -> tuple[str, str]:
    data = path.read_text(encoding="utf-8")

    if MARKER in data:
        return "skipped", "already patched"
    if NEEDLE not in data:
        return "failed", "needle not found"

    patched = data.replace(NEEDLE, NEEDLE + INSERT, 1)
    if dry_run:
        return "would_patch", "dry run"

    ts = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup = path.with_suffix(path.suffix + f".bak.{ts}")
    shutil.copy2(path, backup)
    path.write_text(patched, encoding="utf-8")
    return "patched", f"backup: {backup.name}"


def main() -> int:
    parser = argparse.ArgumentParser(description="Patch OpenClaw dist deliver files for WhatsApp multi-bubble split")
    parser.add_argument("--dry-run", action="store_true", help="Show what would be patched")
    parser.add_argument(
        "--scan-root",
        action="append",
        default=[],
        help="Extra root to recursively scan for node_modules/openclaw/dist",
    )
    args = parser.parse_args()

    extra_roots = [Path(p).expanduser() for p in args.scan_root]
    dist_dirs = discover_dist_dirs(extra_roots)

    if not dist_dirs:
        print("No OpenClaw dist directories found.")
        print("Tip: pass --scan-root /path/to/search")
        return 1

    total = patched = skipped = failed = would = 0
    print("Discovered dist directories:")
    for d in dist_dirs:
        print(f"- {d}")

    for dist in dist_dirs:
        deliver_files = sorted(dist.glob("deliver-*.js"))
        if not deliver_files:
            continue
        print(f"\nPatching in: {dist}")
        for f in deliver_files:
            total += 1
            status, note = patch_file(f, args.dry_run)
            if status == "patched":
                patched += 1
            elif status == "skipped":
                skipped += 1
            elif status == "failed":
                failed += 1
            elif status == "would_patch":
                would += 1
            print(f"  {status:11} {f.name} ({note})")

    print("\nSummary:")
    print(f"- files seen: {total}")
    if args.dry_run:
        print(f"- would patch: {would}")
    else:
        print(f"- patched: {patched}")
    print(f"- already patched: {skipped}")
    print(f"- failed: {failed}")

    return 0 if failed == 0 else 2


if __name__ == "__main__":
    raise SystemExit(main())
