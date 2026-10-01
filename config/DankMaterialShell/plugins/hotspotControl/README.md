# Hotspot Control Plugin for DankMaterialShell (DMS)

Enable, disable, and configure a Wi-Fi hotspot from DankBar and the Control Center.
Built on the NetworkManager connection profile named `Hotspot` (AP mode, `ipv4.method shared`).

---

## Features

1. **DankBar Widget (Pill)**: hotspot icon, SSID when active, and a badge with the number of connected clients. Click to open the popout.

2. **Popout**:
   - Start / Stop button.
   - Edit SSID, WPA2 password (with show/hide), and band (2.4 / 5 GHz). Saving restarts the hotspot if it is running.
   - Gateway IP, upstream interface, and Copy Password button.

3. **Control Center tile** (`plugin_hotspotControl`): toggle plus a detail view. Add or remove it in Control Center edit mode.

4. **Settings** (DMS Settings -> Plugins -> Hotspot Control):
   - **Wireless Interface**: Wi-Fi card used for the hotspot (default `wlan0`).
   - **Share Wi-Fi Connection**: run the hotspot on a virtual interface (`ap0`) alongside your Wi-Fi connection (see below).
   - **Auto-Unblock Wi-Fi Radio**: run `rfkill unblock wifi` before starting.

   SSID, password and band live in the NetworkManager profile, so they're edited from the popout or CLI, not here.

5. **CLI** (`scripts/hotspot-ctl.sh`, reads the same plugin settings):
   ```bash
   ~/.config/DankMaterialShell/plugins/hotspotControl/scripts/hotspot-ctl.sh status
   ~/.config/DankMaterialShell/plugins/hotspotControl/scripts/hotspot-ctl.sh toggle
   ~/.config/DankMaterialShell/plugins/hotspotControl/scripts/hotspot-ctl.sh configure "SSID" "PASSWORD" "bg"
   ```
   Environment overrides: `HOTSPOT_DEVICE`, `HOTSPOT_CONCURRENT=true|false`, `HOTSPOT_AUTO_UNBLOCK=true|false`.

---

## Upstream connection

**Default mode**: starting the hotspot switches `wlan0` into AP mode, which drops your Wi-Fi connection. Use Ethernet (or another interface) for internet.

**Share Wi-Fi Connection mode**: keeps `wlan0` connected and creates `ap0` on the same card, on the same channel as your current Wi-Fi network (the band follows that network; 6 GHz networks can't be shared). If `wlan0` isn't connected when you start, it falls back to default mode.

Creating `ap0` needs root, so run this once (it installs a sudoers rule that allows only the two `iw` commands used):

```bash
sudo ~/.config/DankMaterialShell/plugins/hotspotControl/scripts/setup-concurrent.sh wlan0
# undo: sudo .../setup-concurrent.sh --remove
```

If your Wi-Fi roams to a different channel while sharing, the hotspot will drop; restart it.
