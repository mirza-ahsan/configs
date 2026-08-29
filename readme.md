# System Configs & Dotfiles

Personal Arch Linux workstation configuration repository featuring **Niri Wayland Compositor**, **Dank Material Shell**, **Zed**, **VS Code**, **Ghostty**, **Neovim**, **Tmux**, **Zsh**, **Clang-format**, and custom web applications.

---

## Quick Start

To install all system dependencies, packages, toolchains, SSH keys, web application launchers, and deploy configuration symlinks:

```bash
# 1. Clone the repository
git clone https://github.com/mirza-ahsan/configs.git ~/configs

# 2. Navigate into directory
cd ~/configs

# 3. Make scripts executable
chmod +x master-installation.sh scripts/*.sh

# 4. Run master installation
./master-installation.sh
```

### Symlink-Only Deployment Mode

If software packages are already installed and you only wish to deploy or re-link configuration files:

```bash
./master-installation.sh --link-only
```

### Standalone GitHub & SSH Setup

To configure Git global identity (`mirza-ahsan <ahsan.17april@gmail.com>`) and SSH keys independently:

```bash
./scripts/github.sh
```

> **Automatic Backups:** Existing non-symlinked files at target locations are safely moved to `~/.configs-backup/<timestamp>/` prior to creating new symlinks.

---

## Managed Configurations

| Module | Location in Repo | Deployment Target | Key Features & Optimizations |
| :--- | :--- | :--- | :--- |
| **Niri Compositor** | `config/niri/` | `~/.config/niri/` | `config.kdl` + full `dms/` modular suite (`binds.kdl`, `layout.kdl`, `colors.kdl`, `alttab.kdl`, `outputs.kdl`, `cursor.kdl`, `windowrules.kdl`, `wpblur.kdl`). |
| **Zed Editor** | `config/zed/` | `~/.config/zed/` | `settings.json` (Vim mode, Pyrefly/Ruff/Clangd LSP, custom UI) & `keymap.json` (Vim normal/visual bindings, Leader shortcuts). |
| **VS Code** | `config/Code/User/` | `~/.config/Code/User/` | `settings.json` (AI/Copilot purge, Ayu Dark Bordered theme, clean titlebar, Python black formatter). |
| **Ghostty Terminal** | `config/ghostty/` | `~/.config/ghostty/` | `config` file & `themes/dankcolors` custom palette. |
| **Neovim** | `config/nvim/` | `~/.config/nvim/` | Lua init, Lazy.nvim plugin ecosystem (Treesitter, Blink, LSP, Conform, Telescope, Lualine, Noice). |
| **Tmux** | `home/.tmux.conf` | `~/.tmux.conf` | ESC delay set to 0ms, non-login interactive shell spawning (`default-command`), TPM resurrect, Spider-Man theme statusbar. |
| **Zsh & Shell** | `home/.zshrc`, `home/.p10k.zsh` | `~/.zshrc`, `~/.p10k.zsh` | Powerlevel10k theme, 0-latency completion caching, async autosuggestions, fastfetch integration. |
| **C++ Clang-Format** | `home/.clang-format` | `~/.clang-format` | Google-based C++17 formatting rules, 4-space indent, Allman braces, 130 column limit. |
| **Web Applications** | `local_share/applications/`, `local_share/icons/` | `~/.local/share/applications/`, `~/.local/share/icons/` | Chromium/Browser standalone launchers & custom icons for Gemini, WhatsApp, YouTube, YT Music, GitHub, Excalidraw, Google Docs/Sheets/Slides, Classroom. |
| **Dank Material Shell**| `config/DankMaterialShell/` | `~/.config/DankMaterialShell/` | UI settings & custom `zen.css` theme overrides. |
| **Ruff & Portal** | `config/ruff/`, `config/xdg-desktop-portal/` | `~/.config/ruff/`, `~/.config/xdg-desktop-portal/` | Linter rules and Wayland XDG desktop portal configurations. |
| **Git Global** | `home/.gitconfig` | `~/.gitconfig` | User identity (`mirza-ahsan`) & LFS filters. |

---

## System Dependencies & Installation Pipeline

All system dependencies required to run these configurations are included in the setup scripts:

- **Wayland / UI Desktop:** `niri`, `dms-shell`, `quickshell`, `matugen`, `xwayland-satellite`, `xdg-desktop-portal-gnome`, `xdg-desktop-portal-wlr`, `wl-clipboard`, `grim`, `slurp`, `brightnessctl`, `playerctl`.
- **Audio Stack:** `pipewire-pulse`, `pipewire-alsa`, `wireplumber`, `pavucontrol`.
- **Terminals & Shell:** `ghostty`, `zsh`, `oh-my-zsh`, `powerlevel10k`, `zsh-autosuggestions`, `zsh-syntax-highlighting`, `fastfetch`, `tmux`.
- **Editors & Tools:** `neovim`, `visual-studio-code-bin`, `zed`, `micro`, `yazi`, `cava`, `btop`, `duf`, `vesktop`, `zen-browser-bin`, `chromium`.
- **Formatters & LSP Toolchains:** `clang` (`clangd` + `clang-format`), `gcc`, `make`, `cmake`, `tree-sitter-cli`, `ripgrep`, `fd`, `uv`, `ruff`, `go`, `rust`, `npm`.

### Script Architecture

1. **`scripts/aur.sh`**: Installs base-devel, git, `yay`, and `paru`.
2. **`scripts/crucial-apps.sh`**: Automated installation of all 42 system packages and config dependencies.
3. **`scripts/nvim.sh`**: Neovim 0.12+ and language parser toolchain.
4. **`scripts/zsh.sh`**: Zsh shell framework, P10k prompt, and plugins.
5. **`scripts/tmux.sh`**: Tmux multiplexer and Plugin Manager (TPM).
6. **`scripts/github.sh`** *(Independent)*: Non-interactive Git credentials & ED25519 SSH key setup (`mirza-ahsan <ahsan.17april@gmail.com>`).
7. **`scripts/webapps.sh`**: Refreshes GTK icon cache and desktop launcher database.
