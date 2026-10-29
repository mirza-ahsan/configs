# 06 — System tweaks (need sudo; confirm with the user first)

Everything here is machine-level. The repo cannot apply it automatically, and each item is optional.

## Limine boot menu

Omarchy generates `/boot/limine.conf` (root only); boot entries come from limine-entry-tool and
limine-snapper-sync. Only edit the **header** (the lines before the first `/+` entry), and make a backup first
(`sudo cp /boot/limine.conf /boot/limine.conf.bak`). `omarchy-refresh-limine` regenerates the header, so repeat
these edits after running it.

Header options the owner uses:

```
timeout: no                       # no countdown: the menu waits until a key is pressed (default entry is preselected)
term_font_scale: 3x3              # readable on a 3840x2400 panel; 4x4 is bigger but not sharper (scaled 8x16 bitmap font)
wallpaper: boot():/limine-wallpaper.jpg
wallpaper_style: stretched
term_margin: 0                    # otherwise Limine leaves an untinted 64 px frame around the wallpaper
term_margin_gradient: 0
term_background: 601a1b26         # TTRRGGBB: first byte is transparency, tints the wallpaper so text stays readable
backdrop: 1a1b26
```

Keep the `default_entry` line and all entries untouched. The wallpaper must be a **baseline JPEG** (or PNG) on
the ESP, matching the panel aspect ratio. Make it from any image, for example for a 16:10 panel:

```bash
magick input.jpg -gravity center -crop 1728x1080+0+0 +repage -strip -interlace None \
  -sampling-factor 4:2:0 -quality 92 /tmp/limine-wallpaper.jpg
sudo cp /tmp/limine-wallpaper.jpg /boot/limine-wallpaper.jpg
```

A mistake here only affects the boot menu look; the entries still boot. Changes show on the next reboot.

## Firewall for the hotspot (ufw)

ufw drops INPUT and FORWARD by default, which blocks DHCP/DNS for hotspot clients and their routing. Replace
`<wifi-iface>` with the Wi-Fi interface (`ip -br link`; the owner's was `wlp0s20f3`):

```bash
sudo ufw allow in on <wifi-iface> to any port 67 proto udp   # DHCP
sudo ufw allow in on <wifi-iface> to any port 53             # DNS
sudo ufw route allow in on <wifi-iface>                      # forward client traffic
```

Needs the `dnsmasq` package (NetworkManager shared mode) — see `07`.

## Bluetooth

- If the bar icon disappears or Bluetooth "vanishes", the radio is soft-blocked: `rfkill list`, then
  `rfkill unblock bluetooth` and `sudo systemctl restart bluetooth`.
- Low-energy mice change their address when put into pairing mode; remove the old pairing
  (`bluetoothctl remove <MAC>`) before pairing again. If BlueZ pairs a mouse but never creates an input device
  (log line `No matching connection for device`), use the mouse's USB dongle.

## Docker

Omarchy installs docker. The owner does not use it: `docker.service` is disabled (the socket stays enabled so it
starts on demand). Do not enable it unless asked.

## Removable media

To make a USB stick usable on Linux, Windows and macOS: wipe it, create one partition and format it exFAT with a
label, for example `sudo wipefs -a /dev/sdX && sudo parted -s /dev/sdX mklabel gpt mkpart USB 1MiB 100% &&
sudo mkfs.exfat -L USB /dev/sdX1`. **Double-check the device with `lsblk` first**; this destroys its contents.

## OBS (lecture recording)

The owner's profile "Lectures": 3840x2400 canvas scaled to 1920x1200, NVENC H.264 hardware encoder, hybrid MP4
into `~/Videos`, audio on a USB headset (HyperX Cloud III). The scene file contains device IDs, so it is not
stored here; recreate it in OBS and pick the local audio devices.
