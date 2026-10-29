# 01 — Bootstrap

Goal: take a fresh Omarchy install to the owner's setup with the least risk.

## Prerequisites

- Omarchy installed and booted into Hyprland (Omarchy 4.x: Lua-based Hyprland config, Quickshell bar).
- Network, a user with `sudo`, and the account that will own the files.
- This repo cloned, for example `git clone git@github.com:mirza-ahsan/configs.git ~/configs`.
  (Cloning over SSH needs an SSH key that is registered on GitHub; see "Git and SSH" below.)

Omarchy already provides: Hyprland + Quickshell bar, ghostty, tmux (with TPM), Neovim with LazyVim, Brave,
nautilus, clang/gcc, fzf/ripgrep/fd/zoxide/starship, NVIDIA driver, bluez, ufw, OBS. Do not reinstall them.

## Steps

1. **Review what will change.** `./deploy.sh --dry-run` prints one line per manifest row. `same` means nothing
   to do, `copy`/`append`/`link` are changes, `manual` rows need a human decision.
2. **Packages.** Follow the headers in `packages/pacman.txt` and `packages/aur.txt`. Remove anything the user does
   not want. Things the owner explicitly removed from Omarchy's defaults: Obsidian (and Zoom is a web app, never
   the native client).
3. **Deploy.** `./deploy.sh`. Existing files that differ are saved in `~/.configs-backup/<timestamp>/`.
4. **Manual rows**, in this order:
   - Hyprland monitor scale and text size: `docs/02-omarchy-hyprland.md`.
   - Hotspot widget: `docs/07-hotspot-plugin.md`.
   - Git identity (below).
5. **Reload.** `hyprctl reload` (Hyprland), open a new terminal (ghostty/zsh), `tmux source-file ~/.config/tmux/tmux.conf`
   (tmux), restart Neovim (it will install plugins on first start), restart Zed/VS Code.
6. **Editor extensions.** `docs/03-editors.md`.
7. **Optional.** toolchains (`05`), system tweaks (`06`), apps and defaults (`08`).

## Git and SSH

Omarchy's `~/.config/git/config` already has good defaults (aliases, `pull.rebase`, `push.autoSetupRemote`,
histogram diffs, rerere). Only add what is missing:

```bash
git config --global user.name  "<name>"
git config --global user.email "<email>"
git lfs install                     # LFS filters (git-lfs is in packages/pacman.txt)
ssh-keygen -t ed25519 -C "<email>"  # only if there is no key yet; never copy a private key into this repo
gh auth login                       # or add ~/.ssh/id_ed25519.pub to GitHub by hand
```

The owner keeps projects under `~/projects/<repo>` (clone with `git@github.com:<user>/<repo>`), with a few
exceptions kept outside it (`~/configs`, `~/aiml`).

## Claude Code

- Native Claude Code lives at `~/.local/bin/claude` (installed by Omarchy's agent hook). Do not also install it
  through mise.
- `~/.claude/settings.json` enables the plugins `frontend-design@claude-plugins-official` and
  `clangd-lsp@claude-plugins-official`. Enable them with `/plugin` if missing.
- The owner marked `/` as trusted in `~/.claude.json` (`projects["/"].hasTrustDialogAccepted = true`) so Claude
  Code never asks about folder trust. That removes a safeguard for cloned repositories (their hooks, MCP servers
  and project settings run without a prompt). Only do this if the user asks for it again.

## Verifying

- `./deploy.sh --dry-run` shows only `same` and `manual` rows.
- `nvim --headless "+checkhealth" +qa` (optional), `tmux source-file ~/.config/tmux/tmux.conf`, `hyprctl reload`
  report no errors.
