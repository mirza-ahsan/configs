#!/usr/bin/env bash
# Apply manifest.tsv to $HOME. Usage: ./deploy.sh [--dry-run] [--only <substring>]
# Existing files that differ are copied to ~/.configs-backup/<timestamp>/ before being replaced.
# $HOME can be overridden to test against a scratch directory: HOME=/tmp/x ./deploy.sh --dry-run
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY=0
ONLY=""
while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run | -n) DRY=1 ;;
    --only) ONLY="${2:?--only needs a substring}"; shift ;;
    -h | --help) sed -n '2,4p' "$0"; exit 0 ;;
    *) echo "unknown option: $1" >&2; exit 2 ;;
  esac
  shift
done

BACKUP="$HOME/.configs-backup/$(date +%Y%m%d-%H%M%S)"
say() { printf '%-7s %s\n' "$1" "$2"; }
run() { [ "$DRY" = 1 ] || "$@"; }

backup() { # back up $1 (a path under $HOME) if it exists and is not a symlink we own
  [ -e "$1" ] || [ -L "$1" ] || return 0
  local rel="${1#"$HOME"/}"
  run mkdir -p "$BACKUP/$(dirname "$rel")"
  run cp -a "$1" "$BACKUP/$rel"
}

same() { # same <src> <dst>: identical file or directory contents
  [ -e "$2" ] && diff -rq "$1" "$2" >/dev/null 2>&1
}

do_copy() {
  local src="$1" dst="$2"
  if same "$src" "$dst"; then say same "$dst"; return; fi
  backup "$dst"
  run mkdir -p "$(dirname "$dst")"
  if [ -d "$src" ]; then
    run rm -rf "$dst"
    run cp -a "$src" "$dst"
  else
    run cp -a "$src" "$dst"
  fi
  say copy "$dst"
}

do_link() {
  local src="$1" dst="$2"
  if [ "$(readlink "$dst" 2>/dev/null)" = "$src" ]; then say same "$dst"; return; fi
  backup "$dst"
  run mkdir -p "$(dirname "$dst")"
  run ln -sfn "$src" "$dst"
  say link "$dst -> $src"
}

do_append() {
  local src="$1" dst="$2" id begin end tmp
  id="${src#"$ROOT"/}"
  begin="-- >>> configs: $id"
  end="-- <<< configs: $id"
  if [ ! -f "$dst" ]; then
    say skip "$dst does not exist (is Omarchy's Hyprland config installed?)"
    return
  fi
  tmp="$(mktemp)"
  # Drop an earlier copy of this block, then add the current one.
  awk -v b="$begin" -v e="$end" '$0==b{skip=1} !skip{print} $0==e{skip=0}' "$dst" >"$tmp"
  # $(cat ...) trims trailing blank lines, so repeated runs do not grow the file.
  { printf '%s\n\n%s\n' "$(cat "$tmp")" "$begin"; cat "$src"; printf '%s\n' "$end"; } >"$tmp.new"
  if cmp -s "$tmp.new" "$dst"; then
    say same "$dst ($id)"
  else
    backup "$dst"
    run cp "$tmp.new" "$dst"
    say append "$dst ($id)"
  fi
  rm -f "$tmp" "$tmp.new"
}

while IFS=$'\t' read -r mode src dst note; do
  case "$mode" in '' | \#*) continue ;; esac
  dst="${dst/#\~/$HOME}"
  [ -n "$ONLY" ] && [[ "$src $dst" != *"$ONLY"* ]] && continue
  case "$mode" in
    copy) do_copy "$ROOT/$src" "$dst" ;;
    link) do_link "${src/#\~/$HOME}" "$dst" ;;
    append) do_append "$ROOT/$src" "$dst" ;;
    manual) say manual "$dst: $note" ;;
    *) echo "bad mode '$mode' in manifest.tsv" >&2; exit 1 ;;
  esac
done <"$ROOT/manifest.tsv"

[ "$DRY" = 1 ] && echo "(dry run: nothing was changed)"
exit 0
