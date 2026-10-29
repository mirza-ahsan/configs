# 04 — Terminal, tmux, shell

## tmux (`home/.config/tmux/personal.conf`)

Omarchy's `~/.config/tmux/tmux.conf` ends with `source-file -q ~/.config/tmux/personal.conf`, so this file is
the only tmux file the repo owns. It changes behavior and keys only; colors stay with Omarchy's theme.

| Setting | Why |
|---|---|
| prefix **Ctrl+S** (no second prefix; Omarchy's Ctrl+Space / Ctrl+B unbound) | owner's habit |
| `prefix r` reloads the config | Omarchy had rename-window there (`prefix ,` still renames) |
| `prefix h/j/k/l` and arrows move between panes (arrows not repeatable) | vim-style navigation |
| `prefix Ctrl+L` clears the screen | |
| `escape-time 0`, `repeat-time 300` | no ESC delay in Neovim |
| `default-command 'exec $SHELL'` | non-login interactive shell for every pane |
| Ghostty terminal features `RGB:sync:extkeys` | truecolor, tear-free redraw, modified keys through tmux |
| status bar at the bottom, 12-hour clock | |
| plugins: TPM + tmux-resurrect (`prefix Ctrl+S` save, `prefix Ctrl+R` restore) | |

After first deploy press `prefix` then `Shift+I` inside tmux to install TPM plugins.

Consequence: because Ctrl+S is the prefix, **Ctrl+S never reaches Neovim inside tmux**. Do not bind Neovim
keys to it, and note that Ctrl+A (readline "start of line") is untouched.

## Ghostty (`home/.config/ghostty/config`)

- First line includes Omarchy's theme file (`config-file = ?"~/.local/state/omarchy/current/theme/ghostty.conf"`),
  which is how colors follow the theme.
- JetBrainsMono Nerd Font 16, block cursor without blinking, 14 px padding, no close-confirmation, flat toolbar.
- Keys: Shift+Insert paste, Ctrl+Insert copy, Shift+Enter sent as CSI-u (TUIs can tell it from Enter),
  Alt+Shift+Enter as CSI-u (tmux), `ctrl+shift+e` unbound so Neovim/Zed get it, split-resize chords.
- `async-backend = epoll` fixes general slowness on Hyprland; scrolling multiplier 0.95.
- `font-size` should agree with `omarchy-display-text-size` (see `02`).

## Zsh (`home/.zshrc`)

Built on Omarchy's shell defaults (`$OMARCHY_PATH/default/bash/{envs,aliases,fns,completions}`):

- oh-my-zsh with only the `git` plugin, **no theme**; prompt is starship (`home/.config/starship.toml`, no colors,
  so it follows the terminal theme). mise, zoxide and fzf are activated when present.
- History: 100k entries, deduplicated, shared between sessions. Completion cache on.
- `zsh-autosuggestions` configured for async use; `KEYTIMEOUT=1`; `Ctrl+L` clears the screen.
- Aliases: `fastfetch` with the Arch logo, `:q` exits.
- `TF_CPP_MIN_LOG_LEVEL=2` quiets TensorFlow.
- Packages: `zsh`, `zsh-autosuggestions`, `zsh-completions`, `zsh-syntax-highlighting` (pacman list), oh-my-zsh
  in `~/.oh-my-zsh` (clone from ohmyzsh/ohmyzsh if missing).
- Make zsh the login shell: `chsh -s /usr/bin/zsh`.
- `ls` is aliased to `eza`; use `command ls` in scripts run through this shell.
