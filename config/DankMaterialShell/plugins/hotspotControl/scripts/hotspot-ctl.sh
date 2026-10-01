#!/usr/bin/env bash
set -e

# NetworkManager profile that holds SSID, password and band
CON_NAME="Hotspot"
# Virtual AP interface used in "share Wi-Fi" (concurrent) mode
AP_IFACE="ap0"
PLUGIN_SETTINGS="${XDG_CONFIG_HOME:-$HOME/.config}/DankMaterialShell/plugin_settings.json"

# Plugin settings (DMS Settings -> Plugins -> Hotspot Control); env vars override
load_settings() {
    local dev="" concurrent="" unblock=""
    if command -v jq >/dev/null 2>&1 && [ -r "$PLUGIN_SETTINGS" ]; then
        { read -r dev; read -r concurrent; read -r unblock; } < <(jq -r '
            .hotspotControl // {} |
            (.device // ""),
            (if .concurrent == null then false else .concurrent end),
            (if .autoUnblock == null then true else .autoUnblock end)
        ' "$PLUGIN_SETTINGS" 2>/dev/null) || true
    fi
    DEVICE="${HOTSPOT_DEVICE:-${dev:-wlan0}}"
    CONCURRENT="${HOTSPOT_CONCURRENT:-${concurrent:-false}}"
    AUTO_UNBLOCK="${HOTSPOT_AUTO_UNBLOCK:-${unblock:-true}}"
}

# Run a command quietly; on failure print its output (stdout, so DMS can show it) and fail
run() {
    local out
    if ! out=$("$@" 2>&1); then
        echo "${out:-Command failed: $*}"
        return 1
    fi
}

die() {
    echo "Error: $*"
    exit 1
}

get_active() {
    if nmcli -t -f NAME,TYPE connection show --active 2>/dev/null | grep -q "^${CON_NAME}:802-11-wireless"; then
        echo "true"
    else
        echo "false"
    fi
}

get_field() {
    nmcli -s -g "$1" connection show "${CON_NAME}" 2>/dev/null || true
}

get_active_device() {
    nmcli -g GENERAL.DEVICES connection show "${CON_NAME}" 2>/dev/null | head -n1 || true
}

get_ip() {
    ip -4 addr show "$1" 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | head -n1 || true
}

get_clients() {
    local count
    count=$(iw dev "$1" station dump 2>/dev/null | grep -c '^Station') || count=0
    echo "${count:-0}"
}

get_upstream() {
    local up
    up=$(ip route show default 2>/dev/null | awk '{print $5}' | head -n1 || true)
    if [ -z "$up" ]; then
        up=$(nmcli -t -f DEVICE,TYPE,STATE dev 2>/dev/null | grep ':ethernet:connected' | cut -d: -f1 | head -n1 || true)
    fi
    echo "${up:-none}"
}

is_wifi_blocked() {
    if rfkill list wifi 2>/dev/null | grep -q "Soft blocked: yes"; then
        echo "true"
    else
        echo "false"
    fi
}

# Second hardware-provided MAC of the card, so the AP interface doesn't clash with $DEVICE
ap_mac() {
    local phy
    phy=$(basename "$(readlink -f "/sys/class/net/${DEVICE}/phy80211")" 2>/dev/null)
    sed -n 2p "/sys/class/ieee80211/${phy}/addresses" 2>/dev/null
}

# Frequency (MHz) of $DEVICE's current client connection, empty if not connected
upstream_freq() {
    iw dev "$DEVICE" link 2>/dev/null | awk '/freq:/ {print int($2)}'
}

json_esc() {
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

cmd_status() {
    local active ssid band pass dev ip="" clients=0 upstream blocked mode=""
    active=$(get_active)
    ssid=$(get_field 802-11-wireless.ssid)
    band=$(get_field 802-11-wireless.band)
    pass=$(get_field 802-11-wireless-security.psk)
    blocked=$(is_wifi_blocked)
    upstream=$(get_upstream)
    dev="$DEVICE"

    if [ "$active" = "true" ]; then
        dev=$(get_active_device)
        dev=${dev:-$DEVICE}
        ip=$(get_ip "$dev")
        clients=$(get_clients "$dev")
        if [ "$dev" = "$AP_IFACE" ]; then mode="concurrent"; else mode="exclusive"; fi
    fi
    clients=$(printf '%s' "$clients" | tr -cd '0-9')

    printf '{"active":%s,"ssid":"%s","password":"%s","band":"%s","device":"%s","ip":"%s","clients":%d,"upstream":"%s","wifiBlocked":%s,"mode":"%s","concurrentEnabled":%s}\n' \
        "$active" "$(json_esc "$ssid")" "$(json_esc "$pass")" "$(json_esc "${band:-bg}")" "$(json_esc "$dev")" \
        "$(json_esc "$ip")" "${clients:-0}" "$(json_esc "$upstream")" "$blocked" "$mode" \
        "$([ "$CONCURRENT" = "true" ] && echo true || echo false)"
}

remove_ap_iface() {
    if [ -e "/sys/class/net/${AP_IFACE}" ]; then
        sudo -n /usr/bin/iw dev "${AP_IFACE}" del >/dev/null 2>&1 || true
    fi
}

# Create the virtual AP interface next to $DEVICE and pin the hotspot to its channel
prepare_concurrent() {
    local freq="$1" band channel mac i
    if [ "$freq" -ge 2412 ] && [ "$freq" -le 2472 ]; then
        band="bg"; channel=$(( (freq - 2407) / 5 ))
    elif [ "$freq" -eq 2484 ]; then
        band="bg"; channel=14
    elif [ "$freq" -ge 5150 ] && [ "$freq" -le 5895 ]; then
        band="a"; channel=$(( (freq - 5000) / 5 ))
    else
        die "${DEVICE} is on ${freq} MHz (6 GHz); a hotspot can't share that channel. Connect to a 2.4/5 GHz network or turn off 'Share Wi-Fi connection'."
    fi

    if [ ! -e "/sys/class/net/${AP_IFACE}" ]; then
        mac=$(ap_mac)
        [ -n "$mac" ] || die "Could not determine a MAC address for ${AP_IFACE}"
        sudo -n /usr/bin/iw dev "$DEVICE" interface add "$AP_IFACE" type __ap addr "$mac" >/dev/null 2>&1 ||
            die "Can't create ${AP_IFACE}. Run once: sudo $(dirname "$(readlink -f "$0")")/setup-concurrent.sh ${DEVICE}"
    fi

    # Wait for NetworkManager to pick up the new interface, then keep it from autoconnecting client profiles
    for i in $(seq 1 25); do
        nmcli -g GENERAL.STATE device show "$AP_IFACE" >/dev/null 2>&1 && break
        sleep 0.2
    done
    run nmcli device set "$AP_IFACE" autoconnect no

    run nmcli connection modify "${CON_NAME}" connection.interface-name "$AP_IFACE" \
        802-11-wireless.band "$band" 802-11-wireless.channel "$channel"
}

device_state() {
    nmcli -g GENERAL.STATE device show "$DEVICE" 2>/dev/null | head -n1
}

# Make sure the card is present, unblocked and ready. Catches the usual post-boot problems,
# e.g. coming back from Windows with Fast Startup leaving the card uninitialised.
preflight() {
    local state i
    if [ ! -e "/sys/class/net/${DEVICE}" ]; then
        die "Wi-Fi interface ${DEVICE} not found. If you just came from Windows, Fast Startup can leave the card uninitialised: shut down Windows fully (or disable Fast Startup there), or reboot Linux."
    fi
    # Unblock first: on some laptops (e.g. Dell) a soft block on the platform switch
    # shows up as a hard block on the phy until it is cleared
    if [ "$AUTO_UNBLOCK" = "true" ] && rfkill list wifi 2>/dev/null | grep -q "blocked: yes"; then
        rfkill unblock wifi 2>/dev/null || true
        for i in $(seq 1 10); do
            rfkill list wifi 2>/dev/null | grep -q "blocked: yes" || break
            sleep 0.3
        done
    fi
    if rfkill list wifi 2>/dev/null | grep -q "Hard blocked: yes"; then
        die "Wi-Fi is hard-blocked (airplane-mode key or BIOS switch). Turn the radio on and try again."
    fi
    if [ "$(is_wifi_blocked)" = "true" ]; then
        die "Wi-Fi is turned off (rfkill soft block). Turn it on or enable Auto-Unblock in the plugin settings."
    fi
    nmcli radio wifi on >/dev/null 2>&1 || true

    # Right after boot or unblocking, the device sits in "unavailable" for a few seconds
    for i in $(seq 1 30); do
        state=$(device_state)
        case "$state" in
            10*) die "NetworkManager is not managing ${DEVICE}." ;;
            20*|"") sleep 0.5 ;;
            *) return 0 ;;
        esac
    done
    die "${DEVICE} is still unavailable (${state:-unknown state}). Wait a moment after boot, or reboot if it persists."
}

# Bring the profile up, retrying once (firmware/regulatory can lag right after boot)
activate() {
    local apdev="$1" band out
    if out=$(nmcli --wait 45 connection up "${CON_NAME}" ifname "$apdev" 2>&1); then
        return 0
    fi
    band=$(get_field 802-11-wireless.band)
    # Intel cards refuse 5 GHz AP until they have scanned and learned the regulatory region
    nmcli device wifi rescan ifname "$DEVICE" >/dev/null 2>&1 || true
    sleep 3
    if out=$(nmcli --wait 45 connection up "${CON_NAME}" ifname "$apdev" 2>&1); then
        return 0
    fi
    echo "$out"
    [ "$band" = "a" ] && echo "Hint: this card may not allow a 5 GHz hotspot here; switch to 2.4 GHz."
    return 1
}

cmd_start() {
    local freq apdev="$DEVICE"
    preflight

    freq=$(upstream_freq)
    if [ "$CONCURRENT" = "true" ] && [ -n "$freq" ]; then
        prepare_concurrent "$freq"
        apdev="$AP_IFACE"
    else
        remove_ap_iface
        run nmcli connection modify "${CON_NAME}" connection.interface-name "$DEVICE"
    fi

    if ! activate "$apdev"; then
        [ "$apdev" = "$AP_IFACE" ] && remove_ap_iface
        exit 1
    fi
    cmd_status
}

cmd_stop() {
    nmcli --wait 20 connection down "${CON_NAME}" >/dev/null 2>&1 || true
    remove_ap_iface
    cmd_status
}

cmd_toggle() {
    if [ "$(get_active)" = "true" ]; then
        cmd_stop
    else
        cmd_start
    fi
}

cmd_configure() {
    local new_ssid="$1" new_pass="$2" new_band="$3" was_active

    [ -n "$new_ssid" ] || die "SSID cannot be empty"
    if [ -n "$new_pass" ] && { [ "${#new_pass}" -lt 8 ] || [ "${#new_pass}" -gt 63 ]; }; then
        die "Password must be 8-63 characters"
    fi
    case "$new_band" in
        ""|5|5g|5GHz|a|2.4|2.4g|2.4GHz|bg) ;;
        *) die "Unknown band '$new_band' (use bg or a)" ;;
    esac

    was_active=$(get_active)

    run nmcli connection modify "${CON_NAME}" 802-11-wireless.ssid "$new_ssid"

    if [ -n "$new_pass" ]; then
        run nmcli connection modify "${CON_NAME}" \
            802-11-wireless-security.key-mgmt wpa-psk \
            802-11-wireless-security.proto rsn \
            802-11-wireless-security.pairwise ccmp \
            802-11-wireless-security.group ccmp \
            802-11-wireless-security.psk "$new_pass"
    fi

    # In concurrent mode the band/channel is dictated by the upstream connection on start
    case "$new_band" in
        "") ;;
        5|5g|5GHz|a) run nmcli connection modify "${CON_NAME}" 802-11-wireless.band a 802-11-wireless.channel 36 ;;
        2.4|2.4g|2.4GHz|bg) run nmcli connection modify "${CON_NAME}" 802-11-wireless.band bg 802-11-wireless.channel 6 ;;
    esac

    # Restart to apply new credentials
    if [ "$was_active" = "true" ]; then
        nmcli --wait 20 connection down "${CON_NAME}" >/dev/null 2>&1 || true
        cmd_start
    else
        cmd_status
    fi
}

load_settings

case "$1" in
    status) cmd_status ;;
    start) cmd_start ;;
    stop) cmd_stop ;;
    toggle) cmd_toggle ;;
    configure)
        shift
        cmd_configure "$@"
        ;;
    *)
        echo "Usage: $0 {status|start|stop|toggle|configure <ssid> <password> <band>}" >&2
        exit 1
        ;;
esac
