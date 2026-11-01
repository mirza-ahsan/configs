# 02 — Omarchy and Hyprland

Omarchy 4 configures Hyprland in **Lua**. `~/.config/hypr/hyprland.lua` loads Omarchy's defaults, then your own
`monitors.lua`, `input.lua`, `bindings.lua`, `looknfeel.lua`, `autostart.lua`. Package updates improve the
defaults without touching these files, so keep personal changes in them and nowhere else.

This repo adds its changes as **marked blocks appended** to those files (`snippets/hypr/`, applied by
`deploy.sh`). Re-running replaces the block instead of duplicating it. Block markers look like
`-- >>> configs: snippets/hypr/bindings.lua`.

## Keybinds (snippets/hypr/bindings.lua)

Omarchy defaults stay, except for the keys below. List all bindings with `omarchy menu keybindings --print`.

| Key | Action | Replaces |
|---|---|---|
| `SUPER+Q` | Close window | `SUPER+W` (freed for WhatsApp) |
| `SUPER+B` | Brave Origin | |
| `SUPER+Z` | Zed | |
| `SUPER+E` | File manager (nautilus) | |
| `SUPER+W` | WhatsApp web app | Close window |
| `SUPER+G` | GitHub in a Brave Origin tab (not a web app) | Toggle window grouping |
| `SUPER+Y` | YouTube web app | |
| `SUPER+C` | VS Code | Universal copy |
| `SUPER+V` | Clipboard manager | Universal paste (clipboard manager was `SUPER+CTRL+V`) |
| `SUPER+X` | System menu | Universal cut |
| `SUPER+SHIFT+S` | Screenshot | Google Maps web app |
| `SUPER+SHIFT+X`, `SUPER+SHIFT+ALT+X` | unbound | Omarchy's X and X Post web apps |

Pattern: `hl.unbind("<chord>")` first, then `o.bind("<chord>", "<description>", <action>)`. Actions are a
shell command string, `{ launch = "cmd" }`, `{ omarchy = "name" }`, `{ webapp = "url", focus = true }`, or an
`hl.dsp.*` dispatcher.

## Layout

`looknfeel.lua`: `general.layout = "scrolling"` (niri-style horizontal scrolling columns) as the default.
`SUPER+L` toggles it per workspace. Window resizing keys are Omarchy's defaults:
`omarchy menu keybindings --print | grep -i resize`.

## Input (snippets/hypr/input.lua)

- Touchpad: natural scrolling, adaptive acceleration. MACHINE-SPECIFIC device name, get it from `hyprctl devices`.
- Mouse: `accel_profile = "flat"`, `sensitivity = 0` (1:1 movement).
- Keyboard: `kb_options = "compose:ralt"` — Caps Lock stays Caps Lock; Compose moves to Right Alt. The layout
  itself stays Omarchy's (from `/etc/vconsole.conf`).

## Window rules (snippets/hypr/hyprland.lua)

- Papers (PDF/EPUB viewer) floats like Evince does by default.
- Brave Origin is treated like the other Chromium browsers (Omarchy's rule only matches `brave-browser`),
  so it gets the same slight transparency instead of the default app opacity.

## Scaling and font size (MACHINE-SPECIFIC)

Reference machine: 14" 16:10 panel, 3840x2400, about 286 DPI.

| Scale | Effective size | Verdict |
|---|---|---|
| 3x | 1280x800 | too big |
| **2x** | **1920x1200** | **chosen**: crisp, same density as a 15.6" 1080p laptop |
| 1.6x | 2400x1500 | more room, small text, fractional scaling can blur some apps |

How to set it (do not hand-edit unless these tools are missing):

```bash
omarchy-hyprland-monitor-scaling 2     # writes the two locals at the top of ~/.config/hypr/monitors.lua
omarchy-display-text-size 16           # shell, GTK and terminal text; whole numbers 9-20, owner uses 16
```

`omarchy-display-text-size` writes `[font] base-size` in `~/.config/omarchy/shell.toml` and adjusts GTK and the
terminal. For other displays: aim for an effective resolution near 1920x1200 and pick the text size by eye.
Ghostty's `font-size` lives in `home/.config/ghostty/config`; if text looks wrong, make sure it agrees with the
text-size command.

## Omarchy shell

- Bar layout: `~/.config/omarchy/shell.json` (`bar.layout.left/center/right`, a list of `{ "id": ... }`).
  Only the hotspot widget is added by this repo (see `07`).
- Themes: never edit colors here. `omarchy theme set <name>` changes everything, including Zed (`omazed`
  hook in `~/.config/omarchy/hooks/theme-set.d/omazed`), VS Code and Neovim (hot reload).
- Extra menu entries: `~/.config/omarchy/extensions/omarchy-menu.jsonc` (unused by the owner).
- Night light: `~/.config/hypr/hyprsunset.conf` is Omarchy's default.
- Boot menu look: `docs/06-system-tweaks.md`.
