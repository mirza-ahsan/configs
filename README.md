# configs

Everything needed to rebuild one person's **Omarchy** laptop (Arch + Hyprland + Quickshell), written so that an
AI assistant — or a human — can read this folder and reproduce the setup on another machine.

It stores only what is **theme independent**: editor settings, tmux and shell behavior, Hyprland keybinds and
input, toolchain notes, package lists and a custom hotspot bar widget. Colors, wallpapers and fonts belong to
Omarchy's theme system and are left alone, so `omarchy theme set` keeps working everywhere (terminal, Neovim,
Zed, VS Code, bar).

> The previous version of this repo (Niri, Dank Material Shell, install scripts) is still in git history.
> Omarchy replaced all of it, so none of those scripts are needed any more.

## Use it

Ask your AI assistant: *"Read ~/configs/AGENTS.md and set this system up from it."* It will confirm the big
decisions with you, then apply everything. To do it by hand:

```bash
git clone git@github.com:mirza-ahsan/configs.git ~/configs && cd ~/configs
./deploy.sh --dry-run        # see what would change; nothing is written
./deploy.sh                  # apply (existing files are backed up to ~/.configs-backup/<timestamp>/)
```

Run it on a new install, not on the machine it was captured from (the Hyprland blocks are already there by hand).
Then follow the printed `manual` steps and the docs. `./deploy.sh --only nvim` limits the run to one area.

## What is in here

| Path | Contents |
|---|---|
| `AGENTS.md` | Playbook for AI agents (rules, order of operations, gotchas) |
| `manifest.tsv` | What goes where, and how (copy / link / append / manual) |
| `deploy.sh` | Applies the manifest safely and idempotently |
| `home/` | Dotfiles mirroring `$HOME`: Neovim, tmux, Zed, VS Code, ghostty, zsh, starship, ruff, clang-format |
| `snippets/hypr/` | Hyprland (Lua) keybinds, input, layout and window rules, appended to Omarchy's files |
| `omarchy-plugins/aztrek.hotspot/` | Wi-Fi hotspot bar widget with tests |
| `packages/` | pacman, AUR, VS Code, Zed extensions and web-app lists |
| `python/` | GPU PyTorch/TensorFlow project example and the TensorFlow CUDA preload hook |
| `docs/` | The reasoning and recipes: bootstrap, Hyprland, editors, terminal, toolchains, system tweaks, hotspot, apps |

## Highlights of the setup

- Hyprland **scrolling layout** by default; `SUPER` shortcuts for Brave, Zed, VS Code, WhatsApp, GitHub, YouTube.
- One language server and one formatter per language, no duplicate diagnostics (pyrefly + ruff without overlap,
  clangd + clang-format, gopls, prettier).
- clang is the default C/C++ compiler everywhere; one shared `.clang-format`.
- tmux with prefix `Ctrl+S`, zero escape delay, resurrect; zsh with starship; Neovim tuned to feel like Zed.
- Themed hotspot toggle in the top bar.

## Safety

No secrets live here: no passwords, keys, tokens, git identity or device IDs. Machine-specific values
(monitor scale, touchpad name, GPU, bootloader) are flagged and must be checked on the target machine.
