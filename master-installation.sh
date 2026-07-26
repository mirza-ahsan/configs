#!/bin/bash
set -e

# ── Resolve configs root reliably (works no matter where you run this from) ───
CONFIGS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Source shared library ─────────────────────────────────────────────────────
source "$CONFIGS_DIR/scripts/lib.sh"

# ── Parse flags ───────────────────────────────────────────────────────────────
LINK_ONLY=false

for arg in "$@"; do
    case "$arg" in
        --link-only)
            LINK_ONLY=true
            ;;
        --help|-h)
            echo "Usage: ./master-installation.sh [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --link-only   Skip all package installations, only deploy symlinks"
            echo "  --help, -h    Show this help message"
            exit 0
            ;;
        *)
            log_error "Unknown option: $arg"
            echo "Run with --help for usage information."
            exit 1
            ;;
    esac
done

# ── Banner ────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${CYAN}"
echo "  ┌──────────────────────────────────────┐"
echo "  │        Configs Master Installer       │"
echo "  └──────────────────────────────────────┘"
echo -e "${RESET}"
log_info "Configs directory: ${BOLD}$CONFIGS_DIR${RESET}"
if $LINK_ONLY; then
    log_warn "Running in ${BOLD}--link-only${RESET} mode. Skipping all installations."
fi
echo ""

# ── Make all scripts executable ───────────────────────────────────────────────
chmod +x "$CONFIGS_DIR/scripts/"*.sh

# ══════════════════════════════════════════════════════════════════════════════
#  PHASE 1: Package Installation (skipped with --link-only)
# ══════════════════════════════════════════════════════════════════════════════

if ! $LINK_ONLY; then

    # ── 1a. AUR Helpers ───────────────────────────────────────────────────────
    bash "$CONFIGS_DIR/scripts/aur.sh"

    # ── 1b. Crucial Applications ──────────────────────────────────────────────
    bash "$CONFIGS_DIR/scripts/crucial-apps.sh"

    # ── 1c. Neovim & Dependencies ─────────────────────────────────────────────
    bash "$CONFIGS_DIR/scripts/nvim.sh"

    # ── 1d. Zsh & Oh My Zsh ──────────────────────────────────────────────────
    bash "$CONFIGS_DIR/scripts/zsh.sh"

    # ── 1e. Tmux & TPM ───────────────────────────────────────────────────────
    bash "$CONFIGS_DIR/scripts/tmux.sh"

    # ── 1f. GitHub SSH Key ────────────────────────────────────────────────────
    bash "$CONFIGS_DIR/scripts/github.sh"

fi

# ══════════════════════════════════════════════════════════════════════════════
#  PHASE 2: Symlink Deployment
# ══════════════════════════════════════════════════════════════════════════════

# ── 2a. Config files: config/* → ~/.config/* (file-by-file mirroring) ─────────
log_section "Symlinking config/ → ~/.config/"

CONFIG_COUNT=0
while IFS= read -r file; do
    # Get the relative path (e.g., nvim/init.lua)
    rel_path="${file#$CONFIGS_DIR/config/}"
    target_path="$HOME/.config/$rel_path"

    create_symlink "$file" "$target_path"
    ((++CONFIG_COUNT))
done < <(find "$CONFIGS_DIR/config" -type f)

log_success "Linked ${BOLD}$CONFIG_COUNT${RESET} config files."

# ── 2b. Home configs: home/* → ~/* ────────────────────────────────────────────
log_section "Symlinking home/ → ~/"

HOME_COUNT=0
for item in "$CONFIGS_DIR/home/"* "$CONFIGS_DIR/home/".*; do
    # Skip if glob didn't match anything
    [ -e "$item" ] || continue

    target_name=$(basename "$item")

    # Skip . and ..
    [[ "$target_name" == "." || "$target_name" == ".." ]] && continue

    target_path="$HOME/$target_name"

    create_symlink "$item" "$target_path"
    ((++HOME_COUNT))
done

log_success "Linked ${BOLD}$HOME_COUNT${RESET} home configs."

# ── 2c. Local share files: local_share/* → ~/.local/share/* ───────────────────
log_section "Symlinking local_share/ → ~/.local/share/"

LOCAL_SHARE_COUNT=0
if [ -d "$CONFIGS_DIR/local_share" ]; then
    while IFS= read -r file; do
        rel_path="${file#$CONFIGS_DIR/local_share/}"
        target_path="$HOME/.local/share/$rel_path"

        create_symlink "$file" "$target_path"
        ((++LOCAL_SHARE_COUNT))
    done < <(find "$CONFIGS_DIR/local_share" -type f)
fi

log_success "Linked ${BOLD}$LOCAL_SHARE_COUNT${RESET} local share files."

# ══════════════════════════════════════════════════════════════════════════════
#  PHASE 3: Desktop Database & Integration Updates
# ══════════════════════════════════════════════════════════════════════════════

bash "$CONFIGS_DIR/scripts/webapps.sh"

# ══════════════════════════════════════════════════════════════════════════════
#  Done!
# ══════════════════════════════════════════════════════════════════════════════

echo ""
echo -e "${BOLD}${GREEN}"
echo "  ┌──────────────────────────────────────┐"
echo "  │          Setup Complete! ✓            │"
echo "  └──────────────────────────────────────┘"
echo -e "${RESET}"

log_info "Total symlinks: ${BOLD}$((CONFIG_COUNT + HOME_COUNT + LOCAL_SHARE_COUNT))${RESET} ($CONFIG_COUNT config + $HOME_COUNT home + $LOCAL_SHARE_COUNT local share)"

if [ -d "${BACKUP_DIR:-}" ] && [ "$(ls -A "$BACKUP_DIR" 2>/dev/null)" ]; then
    log_warn "Backed-up files are in: ${BOLD}$BACKUP_DIR${RESET}"
fi

echo ""
log_info "Next steps:"
echo "  1. Restart your terminal (or run: exec zsh)"
echo "  2. Open tmux and press Ctrl+S, then I to install tmux plugins"
echo "  3. If you generated an SSH key, add it to GitHub: https://github.com/settings/ssh/new"
echo ""
