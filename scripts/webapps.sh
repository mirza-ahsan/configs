#!/bin/bash
set -e

# ── Source shared library ─────────────────────────────────────────────────────
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPTS_DIR/lib.sh"

log_section "Web Apps & Desktop Integration Setup"

# 1. Update desktop entry database
if command_exists update-desktop-database; then
    log_info "Updating desktop database..."
    update-desktop-database "$HOME/.local/share/applications"
    log_success "Desktop database updated."
fi

# 2. Update GTK icon cache
if command_exists gtk-update-icon-cache; then
    log_info "Updating GTK icon cache..."
    gtk-update-icon-cache -f -t "$HOME/.local/share/icons/hicolor" 2>/dev/null || true
    log_success "GTK icon cache updated."
fi

# 3. Rescan DankMaterialShell launcher apps if active
if command_exists dms; then
    log_info "Triggering DankMaterialShell launcher rescan..."
    dms ipc call plugin-scan scan >/dev/null 2>&1 || true
    log_success "DMS launcher scan triggered."
fi

log_success "Web apps integration setup complete."
