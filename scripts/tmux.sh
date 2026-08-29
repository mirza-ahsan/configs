#!/bin/bash
set -e

# ── Source shared library ─────────────────────────────────────────────────────
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPTS_DIR/lib.sh"

log_section "Tmux & Automated Plugin Infrastructure"

# 1. Install tmux
if command_exists tmux; then
    log_success "tmux is already installed."
else
    log_info "Installing tmux..."
    sudo pacman -S --needed --noconfirm tmux
    log_success "tmux installed."
fi

# 2. Setup TPM (Tmux Plugin Manager)
PLUGINS_DIR="$HOME/.tmux/plugins"
mkdir -p "$PLUGINS_DIR"

if [ -d "$PLUGINS_DIR/tpm" ]; then
    log_success "TPM is already installed."
else
    log_info "Installing TPM (Tmux Plugin Manager)..."
    git clone https://github.com/tmux-plugins/tpm "$PLUGINS_DIR/tpm"
    log_success "TPM installed."
fi

# 3. Pre-install Core Plugins (tmux-resurrect)
if [ -d "$PLUGINS_DIR/tmux-resurrect" ]; then
    log_success "tmux-resurrect plugin already installed."
else
    log_info "Installing tmux-resurrect plugin..."
    git clone https://github.com/tmux-plugins/tmux-resurrect "$PLUGINS_DIR/tmux-resurrect"
    log_success "tmux-resurrect installed."
fi

# 4. Prepare Resurrect storage directory
mkdir -p "$HOME/.tmux/resurrect"

# 5. Reload active tmux sessions if running
if pgrep -x tmux >/dev/null 2>&1; then
    log_info "Reloading active tmux server..."
    tmux source-file "$HOME/.tmux.conf" 2>/dev/null || true
    log_success "Active tmux configuration reloaded."
fi

log_success "Tmux environment setup complete and ready to use."
