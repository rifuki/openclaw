# TOOLS.md - Environment

Source of truth: `~/.dotfiles` (github.com/rifuki/dotfiles)
Supports: macOS, Ubuntu/Debian, Gentoo Linux.

---

## Conventions

### Safe Delete
Always use `trash` instead of `rm -rf`:
```
trash <file>
```
If `trash` unavailable on current platform: **warn before deleting anything permanently**.

### Paths
- Use `$HOME` or `~` — never hardcode `/Users/rifuki` or `/home/rifuki`
- Dotfiles: `~/.dotfiles/`
- Shared configs: `~/.dotfiles/shared/.config/` → symlinked to `~/.config/`
- Platform-specific: `~/.dotfiles/macos/`, `~/.dotfiles/ubuntu/`, `~/.dotfiles/gentoo/`

---

## Shell & Terminal

| Tool | Notes |
|------|-------|
| **Zsh** + Oh My Zsh | Primary shell, all platforms |
| **Starship** | Cross-shell prompt, cyan-magenta theme |
| **Ghostty** | Terminal emulator (macOS + Gentoo) |
| **tmux** | Multiplexer, Catppuccin Frappe theme |

Aliases:
```bash
n='nvim'
fucking='sudo'
rm → trash          # safe delete via function
y → yazi + cd       # file manager with cwd change
```

---

## Editor

- **Neovim** (`nvim`) — NvChad-based, LSP + Treesitter
- Config: `~/.config/nvim/`

---

## File Manager

- **Yazi** — terminal-based, cross-platform opener
- `y` → open yazi + cd to selected dir

---

## macOS Only

| Tool | Purpose |
|------|---------|
| **Yabai** | Tiling window manager |
| **Skhd** | Hotkey daemon |
| **OrbStack** | Docker & Linux VM runtime |
| **Cloudflare WARP** | VPN client |
| Homebrew | Package manager (`/opt/homebrew/bin/brew`) |

---

## Gentoo Only

| Tool | Purpose |
|------|---------|
| **Hyprland** | Wayland tiling compositor |
| **Waybar** | Status bar (TokyoNight theme) |
| **Wofi** | App launcher |
| **hyprlock** / **hyprpaper** | Screen locker / wallpaper |
| **dunst** | Notification daemon |

---

## Dev Stack

### Languages & Runtimes
- **Node.js** — NVM-managed (Node 24)
- **Bun** — JS runtime & package manager
- **Rust** — rustup, stable toolchain
- **Python** — system + mise

### Blockchain (optional, macOS)
- **Solana** CLI + dev tools
- **Anchor** via AVM
- **Sui** via suiup
- PATH: `~/.local/share/solana/install/active_release/bin`

### AI Tools
- **Kimi CLI** — `kimi`
- **OpenCode** — `opencode`
- **Antigravity proxy** — `localhost:8045`
- Switch mode: `ai-claude`, `ai-kimi`, `ai-opencode`

---

## Common Tools (all platforms)

| Tool | Purpose |
|------|---------|
| **ripgrep** (`rg`) | Fast search |
| **gh** | GitHub CLI |
| **htop** | Process viewer |
| **neofetch** | System info (Miku ASCII art) |
| **trash** | Safe delete (see Conventions) |

---

## PATH Priority
```
~/.local/bin
~/.bun/bin
~/.cargo/bin
~/.antigravity/antigravity/bin
~/.local/share/solana/install/active_release/bin
/opt/homebrew/bin   (macOS)
```

---

_Add SSH hosts, device names, and infra notes below as needed._
