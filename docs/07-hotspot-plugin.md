# 07 — Hotspot bar widget (`aztrek.hotspot`)

An Omarchy shell plugin (Quickshell QML) that shares the wired connection as a Wi-Fi hotspot from the top bar:
on/off toggle, SSID, password and band (5 GHz preferred, 2.4 GHz fallback). It follows the Omarchy theme
because it is built from Omarchy's own `qs.Ui` components.

Files (`omarchy-plugins/aztrek.hotspot/`):

| File | Role |
|---|---|
| `manifest.json` | Plugin id, a `bar-widget` kind, default section `right` |
| `Panel.qml` | Bar icon button and the keyboard-friendly popup |
| `bin/omarchy-hotspot` | Bash backend using `nmcli` only (no root). `status`, `on`, `off`, `toggle`, `get-password`, `set-password`, `set-ssid`, `set-band`; prints one JSON status object |
| `tests/run-tests.sh` | 39 checks of the backend with no side effects (`--radio` adds checks against the real Wi-Fi radio; that drops your Wi-Fi link) |

## Install

1. `./deploy.sh` copies the folder to `~/.config/omarchy/plugins/aztrek.hotspot` and links
   `~/.local/bin/omarchy-hotspot` to the backend.
2. Packages: `dnsmasq` (NetworkManager's shared mode), NetworkManager (Omarchy default), `iw` (channel flags).
3. Firewall: the three ufw rules in `docs/06-system-tweaks.md`.
4. Enable the widget: `omarchy plugin validate ~/.config/omarchy/plugins/aztrek.hotspot`, then
   `omarchy plugin enable aztrek.hotspot right`. If the bar does not show it, add
   `{ "id": "aztrek.hotspot" }` to `bar.layout.right` in `~/.config/omarchy/shell.json` (the owner has it between
   the tray and the agents widgets). Plugins hot-reload.
5. Set the password once: click the bar icon, open the popup, type a password (8-63 characters). It is stored in
   the NetworkManager profile (`omarchy-hotspot`), never in this repo.

## Behavior to know

- Needs a working uplink (Ethernet, USB tether). The Wi-Fi radio is **single**: while the hotspot runs the
  laptop's own Wi-Fi client link is down; on stop the saved client connection is restored by name.
- Band: 5 GHz is tried first using channels that the regulatory domain allows to **initiate** radiation
  (`iw phy info` flags, no "no IR"), 80 MHz wide. If none works it falls back to 2.4 GHz and the widget shows
  the band actually in use.
- State is in `~/.local/state/omarchy-hotspot/` (preferred band, last start note, lock, the Wi-Fi connection to
  restore). Calls are serialized with `flock`.
- Run the checks after any change: `omarchy-plugins/aztrek.hotspot/tests/run-tests.sh`.
