#!/bin/bash
set -e

# ── Source shared library ─────────────────────────────────────────────────────
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPTS_DIR/lib.sh"

log_section "Crucial Applications & System Dependencies"

# Define all core packages & system dependencies required to run all configs.
PACKAGES=(
    # Web Browsers & WebApp Runner
    zen-browser-bin
    chromium

    # Editors & IDEs
    ghostty
    visual-studio-code-bin
    zed
    neovim
    micro

    # Wayland Compositor, Desktop Portals & DMS UI Infrastructure
    niri
    dms-shell
    quickshell
    matugen
    xwayland-satellite
    xdg-desktop-portal-gnome
    xdg-desktop-portal-wlr
    wl-clipboard
    grim
    slurp
    brightnessctl
    playerctl

    # Audio & Sound System
    pipewire-pulse
    pipewire-alsa
    wireplumber
    pavucontrol

    # File Managers & Terminal Tools
    yazi
    cava
    btop
    fastfetch
    duf
    ripgrep
    fd
    tree-sitter-cli
    unzip
    tar
    curl
    git

    # Development Toolchains, Formatters & LSPs
    cmake
    gcc
    clang
    go
    rust
    uv
    npm
    ruff

    # Desktop GUI Applications & Viewers
    vesktop
    evince
    nautilus
)

log_info "Installing ${#PACKAGES[@]} system packages & dependencies..."
paru -S --noconfirm --needed "${PACKAGES[@]}"

log_success "All crucial applications and system dependencies installed successfully."
