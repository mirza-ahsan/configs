# 08 — Apps, web apps and defaults

## Applications

Packages are listed in `packages/`. Roles on the original machine:

| Role | App |
|---|---|
| Browser | Brave Origin (default for http/https/mailto), `SUPER+B` |
| Editors | Zed (`SUPER+Z`), VS Code (`SUPER+C`), Neovim |
| Terminal | Ghostty + tmux |
| PDF | **PdfCraft** (AUR `pdfcraft-bin`) as the default for PDF; Papers for comic-book and DjVu files |
| EPUB | Foliate |
| Chat | Discord through Vesktop (the `discord://` handler), WhatsApp as a web app |
| Music | Spotify |
| Zoom | **web app only**, never the native client |
| Obsidian | removed |

## Web apps

`packages/webapps.tsv` lists the web apps. Create each one with Omarchy's tool so Omarchy manages the launcher
and icon: `omarchy-webapp-install "<name>" "<url>" "<icon-url>"`. WhatsApp, GitHub and YouTube also have
`SUPER` bindings through `snippets/hypr/bindings.lua`.

## Default applications

Check with `xdg-mime query default <mime>`; set with `xdg-mime default <app>.desktop <mime>`.

```bash
xdg-mime default brave-origin.desktop x-scheme-handler/http x-scheme-handler/https text/html
xdg-mime default vesktop.desktop x-scheme-handler/discord
xdg-mime default ai.storyteller.pdfcraft.desktop application/pdf   # only after PdfCraft is installed
```

Omarchy's `~/.config/mimeapps.list` and Hyprland's `hyprland-mimeapps.list` hold the results; edit through
`xdg-mime`, not by hand. If PdfCraft does not open files passed to it, check that the `Exec=` line of its
`.desktop` file ends with a file placeholder (`%f` or `%u`).

## Claude Code

See `docs/01-bootstrap.md` ("Claude Code"). Settings in `~/.claude/` and `~/.claude.json` are deliberately not
mirrored here because they hold tokens and per-machine state.
