#!/bin/bash
# Backend QA for omarchy-hotspot. Radio tests run sequentially; restores the
# original ssid/password/band afterwards and leaves the hotspot OFF.
# Usage: tests/run-tests.sh [--radio]   (--radio also starts/stops the hotspot)
H="$(dirname "$(readlink -f "$0")")/../bin/omarchy-hotspot"
RADIO=0; [[ ${1:-} == --radio ]] && RADIO=1
pass=0; fail=0
ok() { echo "PASS $1"; pass=$((pass+1)); }
ko() { echo "FAIL $1 :: $2"; fail=$((fail+1)); }
chk() { if eval "$2"; then ok "$1"; else ko "$1" "$2"; fi; }

OPW=$("$H" get-password); OSSID=$("$H" status | jq -r .ssid); OBAND=$("$H" status | jq -r .band)
restore() {
  "$H" set-password "$OPW" >/dev/null 2>&1; "$H" set-ssid "$OSSID" >/dev/null 2>&1; "$H" set-band "$OBAND" >/dev/null 2>&1
  "$H" off >/dev/null 2>&1
}
trap restore EXIT

# --- status schema
S=$("$H" status)
chk "status valid JSON" 'jq -e . <<<"$S" >/dev/null'
chk "status schema/types" 'jq -e "(.available|type==\"boolean\") and (.active|type==\"boolean\") and (.ssid|type==\"string\") and (.channel|type==\"number\") and (.clients|type==\"number\") and (.canStart|type==\"boolean\") and (.error|type==\"string\")" <<<"$S" >/dev/null'
chk "status has no password field" '! jq -e "tostring|test(\"psk|password\\\":\\\"\")" <<<"$S" >/dev/null'
chk "unknown cmd fails with JSON error" '! "$H" bogus >/tmp/o.$$ 2>&1 && jq -e .error /tmp/o.$$ >/dev/null; rm -f /tmp/o.$$'

# --- password validation: must be rejected and leave stored value untouched
reject_pw() { local before after; before=$("$H" get-password); "$H" set-password "$2" >/dev/null 2>&1; local rc=$?; after=$("$H" get-password)
  if (( rc != 0 )) && [[ $before == "$after" ]]; then ok "$1"; else ko "$1" "rc=$rc changed=$([[ $before == "$after" ]] && echo no || echo YES)"; fi; }
accept_pw() { local out; out=$("$H" set-password "$2" 2>&1); local rc=$?; local got; got=$("$H" get-password)
  if (( rc == 0 )) && [[ $got == "$2" ]]; then ok "$1"; else ko "$1" "rc=$rc got=[$got] out=$(jq -r .error <<<"$out" 2>/dev/null)"; fi; }
reject_pw "pw 7 chars rejected" "abcdefg"
reject_pw "pw 64 chars rejected" "$(printf 'a%.0s' {1..64})"
reject_pw "pw non-ascii rejected" "pässwörd123"
reject_pw "pw control char rejected" $'abcdefgh\x01'
reject_pw "pw embedded newline rejected" $'validpass1\nx'
reject_pw "pw multi-line (valid 2nd line) rejected" $'x\nvalid-password-here'
reject_pw "pw empty rejected" ""
accept_pw "pw 8 chars" "abcdefgh"
accept_pw "pw 63 chars" "$(printf 'b%.0s' {1..63})"
accept_pw "pw with spaces" "pass word with spaces"
accept_pw "pw leading space" " leadingspace1"
accept_pw "pw trailing space" "trailingspace1 "
accept_pw "pw specials \$'\"\\\`!" "a\$b'c\"d\\e\`f!g"
accept_pw "pw leading dash" "-leading-dash-1"
accept_pw "pw leading double dash" "--passphrase1"
accept_pw "pw colon" "a:b:c:d:e:f:g:h"
accept_pw "pw backslash only run" 'ab\\cd\ef\\\gh'
accept_pw "pw semicolon/pipe/glob" 'a;b|c*d?e[f]g&h'
accept_pw "pw hex-like 8" "deadbeef"

# --- ssid validation
reject_ssid() { local before after; before=$("$H" status | jq -r .ssid); "$H" set-ssid "$2" >/dev/null 2>&1; local rc=$?; after=$("$H" status | jq -r .ssid)
  if (( rc != 0 )) && [[ $before == "$after" ]]; then ok "$1"; else ko "$1" "rc=$rc before=[$before] after=[$after]"; fi; }
accept_ssid() { "$H" set-ssid "$2" >/dev/null 2>&1; local rc=$?; local got raw; got=$("$H" status | jq -r .ssid); raw=$(nmcli -g 802-11-wireless.ssid connection show omarchy-hotspot)
  if (( rc == 0 )) && [[ $got == "$2" ]]; then ok "$1"; else ko "$1" "rc=$rc status.ssid=[$got] nm=[$raw]"; fi; }
reject_ssid "ssid empty" ""
reject_ssid "ssid 33 ascii" "$(printf 's%.0s' {1..33})"
reject_ssid "ssid multibyte >32 bytes" "$(printf 'é%.0s' {1..17})"
reject_ssid "ssid control char" $'ab\x07cd'
reject_ssid "ssid newline" $'ab\ncd'
accept_ssid "ssid 1 char" "x"
accept_ssid "ssid 32 chars" "$(printf 'S%.0s' {1..32})"
accept_ssid "ssid multibyte <=32 bytes" "Café ☕ Wi-Fi"
accept_ssid "ssid leading dash" "-dash-ssid"
accept_ssid "ssid spaces" "my  home   net"
accept_ssid "ssid quotes/dollar" "a'b\"c\$d"
accept_ssid "ssid colon" "a:b:c"
accept_ssid "ssid backslash" 'a\b\\c'
accept_ssid "ssid contains word 'type'" "mytype-net"
accept_ssid "ssid contains word 'channel'" "channel-5"

# --- concurrency (no radio): two writers must serialise and both land
( "$H" set-ssid concA >/dev/null 2>&1 & "$H" set-ssid concB >/dev/null 2>&1 & wait )
chk "concurrent set-ssid leaves valid ssid" '[[ $("$H" status | jq -r .ssid) =~ ^conc[AB]$ ]]'

if (( RADIO )); then
  "$H" set-ssid "$OSSID" >/dev/null; "$H" set-password "$OPW" >/dev/null
  for band in 5 2.4; do
    "$H" set-band "$band" >/dev/null
    S=$("$H" on); chk "on @$band active" 'jq -e .active <<<"$S" >/dev/null'
    chk "on @$band iw type AP" '[[ $(iw dev "$(jq -r .iface <<<"$S")" info | awk "/^\s*type/{print \$2}") == AP ]]'
    f=$(iw dev "$(jq -r .iface <<<"$S")" info | awk '/channel/{print $3}' | tr -d '(')
    if [[ $band == 2.4 ]]; then chk "2.4 radio freq" '(( f < 3000 ))'; else chk "5 radio freq (or noted fallback)" '(( f > 5000 )) || [[ -n $(jq -r .note <<<"$S") ]]'; fi
    chk "bandActual matches radio" '[[ $(jq -r .bandActual <<<"$S") == $([[ $f -lt 3000 ]] && echo 2.4 || echo 5) ]]'
    S=$("$H" on); chk "on twice idempotent" 'jq -e .active <<<"$S" >/dev/null'
    S=$("$H" off); chk "off" '! jq -e .active <<<"$S" >/dev/null'
    S=$("$H" off); chk "off twice idempotent" '! jq -e .active <<<"$S" >/dev/null'
    sleep 15
    chk "stays off 15s" '! "$H" status | jq -e .active >/dev/null'
    chk "client restored" '[[ $(nmcli -t -g GENERAL.CONNECTION device show "$(jq -r .iface <<<"$S")") == StormFiber-07B6-5G ]]'
    chk "was-client consumed" '[[ ! -e ${XDG_STATE_HOME:-$HOME/.local/state}/omarchy-hotspot/was-client ]]'
  done
fi
echo "== $pass passed, $fail failed"
exit $((fail > 0))
