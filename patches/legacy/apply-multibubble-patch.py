#!/usr/bin/env python3
"""
OpenClaw Multi-Bubble WhatsApp Patch
Auto-split messages with \\n\\n into multiple WhatsApp bubbles
Created: 2026-03-06

Usage:
    python3 apply-multibubble-patch.py

This script patches the WhatsApp extension in OpenClaw to automatically
split messages containing \\n\\n into multiple WhatsApp bubbles.
"""

import os
import re
import shutil
from datetime import datetime
from pathlib import Path

def find_openclaw_installations():
    """Find all OpenClaw installations"""
    home = Path.home()
    base_path = home / ".local/share/mise/installs/node"
    
    installations = []
    if base_path.exists():
        for node_version in base_path.iterdir():
            if node_version.is_dir():
                channel_file = node_version / "lib/node_modules/openclaw/extensions/whatsapp/src/channel.ts"
                if channel_file.exists():
                    installations.append(channel_file)
    
    return installations

def create_backup(file_path):
    """Create timestamped backup"""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_path = f"{file_path}.backup.{timestamp}"
    shutil.copy2(file_path, backup_path)
    return backup_path

def is_already_patched(content):
    """Check if file is already patched"""
    return "_multiBubble" in content or "Auto-split multi-bubble" in content

def apply_patch(file_path):
    """Apply the multi-bubble patch"""
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Check if already patched
    if is_already_patched(content):
        print(f"   ✅ Already patched, skipping...")
        return True
    
    # Find the sendText function
    old_pattern = r'''(sendText: async \(\{ to, text, accountId, deps, gifPlayback \}\) => \{\s*const send =)'''
    
    replacement = r'''sendText: async ({ to, text, accountId, deps, gifPlayback }) => {
      // Auto-split multi-bubble messages (middleware)
      const bubbles = text.split(/\n\n+/).map(s => s.trim()).filter(s => s.length > 0);
      
      if (bubbles.length <= 1) {
        // Single bubble - send normally
        const send ='''
    
    if re.search(old_pattern, content):
        # Create backup
        backup_path = create_backup(file_path)
        print(f"   💾 Backup created: {backup_path}")
        
        # Apply patch
        new_content = re.sub(old_pattern, replacement, content, count=1)
        
        # Also need to add the multi-bubble handling code after the single bubble case
        # Find where to insert the rest
        single_bubble_end = '''return { channel: "whatsapp", ...result };
    },'''
        
        multi_bubble_code = '''return { channel: "whatsapp", ...result };
      }
      
      // Multiple bubbles - send each separately
      const results = [];
      for (let i = 0; i < bubbles.length; i++) {
        const result = await send(to, bubbles[i], {
          verbose: false,
          accountId: accountId ?? undefined,
          gifPlayback: i === 0 ? gifPlayback : false,
        });
        results.push(result);
        // Small delay to maintain order
        if (i < bubbles.length - 1) {
          await new Promise(r => setTimeout(r, 150));
        }
      }
      
      return { channel: "whatsapp", ...results[0], _multiBubble: true, _bubbleCount: bubbles.length };
    },'''
        
        new_content = new_content.replace(single_bubble_end, multi_bubble_code, 1)
        
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        
        print(f"   ✅ Patch applied successfully!")
        return True
    else:
        print(f"   ❌ Could not find target pattern. File may have changed.")
        return False

def main():
    print("🦞 OpenClaw Multi-Bubble WhatsApp Patch")
    print("=" * 50)
    
    installations = find_openclaw_installations()
    
    if not installations:
        print("❌ No OpenClaw installations found!")
        print("   Make sure OpenClaw is installed via mise/node")
        return 1
    
    print(f"📁 Found {len(installations)} installation(s):\n")
    
    patched_count = 0
    for installation in installations:
        print(f"🔧 Processing: {installation}")
        if apply_patch(installation):
            patched_count += 1
        print()
    
    print("=" * 50)
    if patched_count > 0:
        print(f"🎉 Successfully patched {patched_count} installation(s)!")
        print("\n📝 Next steps:")
        print("   1. Restart OpenClaw gateway:")
        print("      pkill -f openclaw-gateway && openclaw-gateway &")
        print("   2. Test multi-bubble functionality")
        print("\n📖 For manual patches or troubleshooting:")
        print("   ~/.openclaw/patches/")
    else:
        print("⚠️  No patches were applied")
        print("   (All installations may already be patched)")
    
    return 0

if __name__ == "__main__":
    exit(main())
