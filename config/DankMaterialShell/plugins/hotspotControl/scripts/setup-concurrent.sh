#!/usr/bin/env bash
# One-time setup for "Share Wi-Fi connection" mode.
# Creating/deleting the virtual AP interface needs root, so this installs a sudoers
# rule allowing exactly those two `iw` commands without a password.
#
#   sudo ./setup-concurrent.sh [device]     # install (default device: wlan0)
#   sudo ./setup-concurrent.sh --remove     # uninstall
set -euo pipefail

SUDOERS_FILE="/etc/sudoers.d/hotspot-ap0"
AP_IFACE="ap0"

[ "$(id -u)" -eq 0 ] || { echo "Run with sudo: sudo $0 ${*:-wlan0}" >&2; exit 1; }

if [ "${1:-}" = "--remove" ]; then
    rm -f "$SUDOERS_FILE"
    echo "Removed $SUDOERS_FILE"
    exit 0
fi

user="${SUDO_USER:?Run this via sudo from your normal user}"
dev="${1:-wlan0}"

[ -e "/sys/class/net/${dev}/phy80211" ] || { echo "${dev} is not a wireless interface" >&2; exit 1; }
phy=$(basename "$(readlink -f "/sys/class/net/${dev}/phy80211")")
mac=$(sed -n 2p "/sys/class/ieee80211/${phy}/addresses")
[ -n "$mac" ] || { echo "${phy} exposes only one MAC address; concurrent AP not supported" >&2; exit 1; }

if ! iw phy "$phy" info | grep -A4 "valid interface combinations" | grep -q "managed.*AP\|AP.*managed\|#{ AP"; then
    echo "Warning: ${phy} does not advertise managed+AP concurrency; it may not work." >&2
fi

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
cat >"$tmp" <<EOF
# Installed by DankMaterialShell hotspotControl plugin (scripts/setup-concurrent.sh)
${user} ALL=(root) NOPASSWD: /usr/bin/iw dev ${dev} interface add ${AP_IFACE} type __ap addr ${mac}, /usr/bin/iw dev ${AP_IFACE} del
EOF

visudo -cf "$tmp" >/dev/null
install -m 0440 -o root -g root "$tmp" "$SUDOERS_FILE"
echo "Installed $SUDOERS_FILE (${dev} -> ${AP_IFACE}, MAC ${mac})"
echo "Now enable 'Share Wi-Fi connection' in DMS Settings -> Plugins -> Hotspot Control."
