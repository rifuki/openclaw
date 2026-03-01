# TOOLS.md - Local Environment

## Shell & Terminal
- **Shell:** Zsh + Oh My Zsh
- **Terminal:** Ghostty (macOS), Hyper (fallback)
- **Prompt:** Starship (cyan-magenta theme)
- **Multiplexer:** Tmux (Catppuccin Frappe theme)

## Editor
- **Primary:** Neovim (NvChad-based config)
- **Alias:** `n` → nvim

## File Management
- **File Manager:** Yazi (terminal-based)
- **Function:** `y` → Open yazi + cd to selected dir
- **Safe Delete:** `rm` → trash (via function, not real rm)

## macOS Window Management
- **Tiling:** Yabai
- **Hotkey Daemon:** SkHD
- **Requirement:** Accessibility permissions

## Development Stack

### Languages & Runtimes
- **Node.js:** NVM-managed (Node 24)
- **Bun:** JavaScript runtime & package manager
- **Rust:** rustup (stable toolchain)
- **Python:** system + mise

### Blockchain (Optional)
- **Solana:** CLI + dev tools
- **Anchor:** via AVM
- **Sui:** suiup version manager
- **PATH:** `~/.local/share/solana/install/active_release/bin`

### AI Tools
- **Claude Code:** `claude` (Anthropic format)
- **Kimi CLI:** `kimi` (OpenAI format)
- **OpenCode:** `opencode` (OpenAI format)
- **Gemini CLI:** `gemini`
- **Proxy:** Antigravity (localhost:8045)
- **Switch mode:** `ai-claude`, `ai-kimi`, `ai-opencode`

### Docker
- **Runtime:** OrbStack (macOS)
- **Completions:** `~/.docker/completions`

## System Tools
- **Package Manager:** Homebrew (`/opt/homebrew/bin/brew`)
- **Search:** ripgrep (`rg`)
- **Process Viewer:** htop
- **System Info:** neofetch (Miku ASCII art)
- **GitHub CLI:** `gh`
- **VPN:** Cloudflare WARP

## Aliases & Functions
```bash
n='nvim'                    # Quick nvim
fucking='sudo'              # Fun sudo alias
rm → trash                  # Safe delete (function)
y → yazi + cd               # File manager with cwd change
```

## PATH Priority
```
~/.local/bin
~/.bun/bin
~/.cargo/bin
~/.antigravity/antigravity/bin
~/.local/share/solana/install/active_release/bin
/opt/homebrew/bin (Homebrew)
```

## Cross-Platform Notes
- Dotfiles support both macOS and Linux (VPS)
- Shared configs in `~/.dotfiles/shared/`
- Platform-specific in `~/.dotfiles/macos/` and `~/.dotfiles/vps/`

## Color Palette (Theme)
| Color | Hex | Usage |
|-------|-----|-------|
| Cyan | `#00D9FF` | Commands, time |
| Green | `#50FA7B` | Paths, success |
| Magenta | `#FF79C6` | Git branches |
| Purple | `#BD93F9` | Builtins |
| Teal | `#01CBC6` | Aliases |
| Orange | `#FFB86C` | Path alternates |

## Preferences
- Clean, minimal output
- Cyan-magenta color scheme
- Safety first (trash > rm)
- Terminal-centric workflow
