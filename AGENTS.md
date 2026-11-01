# AGENTS.md — how an AI assistant should use this repository

This repository describes how one person's Omarchy laptop is set up. It holds the **theme-independent**
parts only: editors, terminal behavior, shell, Hyprland keybinds and input, toolchains, packages, and a custom
bar widget. Colors, wallpapers and fonts come from Omarchy's theme system and are deliberately not stored here.

If you are an AI agent asked to "set up this system from ~/configs", follow this file. If you are asked to
update the repository, see "Keeping the repo current" at the bottom.

## Ground rules

1. **Omarchy owns the base.** Omarchy (Arch + Hyprland + Quickshell, with LazyVim, tmux, ghostty and the rest
   preconfigured) is assumed to be installed. This repo is a thin personal layer on top. Never replace
   Omarchy-managed files wholesale; the manifest only touches files that are safe to own, and *appends*
   marked blocks to the Hyprland Lua files. Omarchy updates must keep working.
2. **Do not change themes.** If a file here lacks a theme key, that is on purpose. `omarchy theme set` and the
   `omazed` hook write them.
3. **Ask before big decisions.** Packages, firewall rules, bootloader edits, scale/font size and anything that
   needs `sudo` should be confirmed with the user first. This repo records what the owner chose, not what every
   machine needs.
4. **Machine-specific values** are marked `MACHINE-SPECIFIC` or `manual` in `manifest.tsv`: monitor scale and
   text size, the touchpad device name, GPU/CUDA, bootloader, git identity. Check the real hardware, do not copy
   the numbers blindly.
5. **Never write secrets here.** No passwords, tokens, SSH keys, git identity or device IDs belong in this repo.
6. **Back up before replacing.** `deploy.sh` does this automatically (`~/.configs-backup/<timestamp>/`).
   Do the same for anything you change by hand.
7. Verify each step (run the tool, reload the config, open a file) instead of assuming it worked.

## Order of operations

1. Read `docs/01-bootstrap.md` and confirm prerequisites with the user.
2. Install packages: `packages/pacman.txt`, `packages/aur.txt` (see the headers in those files).
3. Deploy files: `./deploy.sh --dry-run`, review, then `./deploy.sh`. It applies `manifest.tsv`.
4. Walk through every `manual` row printed by the deploy and do it using the matching doc.
5. Install editor extensions: `packages/vscode-extensions.txt`; Zed installs its own (`packages/zed-extensions.txt`).
6. Optional topics: `docs/05-dev-toolchains.md`, `docs/06-system-tweaks.md`, `docs/08-apps-and-defaults.md`.
7. Re-run `./deploy.sh --dry-run`; every non-manual row should say `same`.

**Do not run `deploy.sh` on the laptop this repo was captured from.** Its Hyprland files already contain the
personal blocks written by hand (the append rows would duplicate them), and the Zed/VS Code copies drop the theme
keys that the live files carry. Use it on a fresh or different install.

## Map

| Path | What it is |
|---|---|
| `manifest.tsv` | Source -> target list with a mode per row: copy, link, append, manual |
| `deploy.sh` | Applies the manifest. `--dry-run`, `--only <substring>`; test with `HOME=/some/dir` |
| `home/` | Files that mirror `$HOME` (copied as-is) |
| `snippets/hypr/` | Blocks appended to Omarchy's `~/.config/hypr/*.lua` files |
| `omarchy-plugins/aztrek.hotspot/` | The Wi-Fi hotspot bar widget, with its backend and tests |
| `packages/` | pacman, AUR, VS Code, Zed and web-app lists |
| `python/` | uv GPU project example and the TensorFlow CUDA preload hook |
| `docs/` | Why things are the way they are, per topic, with the commands to redo them |

## Things that bite on this system

- Shell is zsh. `ls` is aliased to `eza`; use `command ls` for plain output. A bare word like `=====` expands in
  zsh, so quote it. Do not use `pkill -f <pattern>` from inside a shell whose own command line contains it.
- Omarchy's Hyprland config is **Lua** (`~/.config/hypr/*.lua`, helpers `o.bind`, `o.window`, `hl.*`), not
  `hyprland.conf`. Check `hyprctl version` and the comments at the top of those files before editing.
- Omarchy's Neovim config loads LazyVim keymaps on the `VeryLazy` event; a headless test must fire
  `doautocmd User VeryLazy` before checking mappings.
- tmux prefix is **Ctrl+S**, so Ctrl+S never reaches Neovim inside tmux. Pick other keys for Neovim mappings.
- Quickshell plugins hot-reload; validate with `omarchy plugin validate <path>`.

## Keeping the repo current

When the owner changes a setting on the machine and wants it kept:

1. Copy the live file back into the same repo path listed in `manifest.tsv` (strip theme keys, absolute
   personal paths and anything machine specific, as the existing files do).
2. For Hyprland, edit the matching file in `snippets/hypr/`, not the live-file copy.
3. Update the matching doc under `docs/` with the *reason*, not just the value.
4. Run `./deploy.sh --dry-run` against a scratch `HOME` to check the manifest still resolves.
5. Workflow for this repo, every time: `git pull --rebase --autostash` first, then commit each logically different
   change as its own one-line commit starting with a lowercase letter (for example `add x`, `drop github web app`),
   with no co-author trailer, then `git push`. Never force-push without the owner's explicit go-ahead.
