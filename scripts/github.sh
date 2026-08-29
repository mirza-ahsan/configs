#!/bin/bash
set -e

# ── Source shared library ─────────────────────────────────────────────────────
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPTS_DIR/lib.sh"

log_section "GitHub & Git User Credentials Setup"

USERNAME="mirza-ahsan"
EMAIL="ahsan.17april@gmail.com"
KEY_PATH="$HOME/.ssh/id_ed25519"

# 1. Configure Global Git Identity
log_info "Setting global Git user identity..."
git config --global user.name "$USERNAME"
git config --global user.email "$EMAIL"
log_success "Git user identity set to ${BOLD}$USERNAME <$EMAIL>${RESET}."

# 2. Setup SSH Key for GitHub
log_info "Checking SSH key for GitHub..."

if [ -f "$KEY_PATH" ]; then
    log_success "SSH key already exists at ${BOLD}$KEY_PATH${RESET}."
else
    log_info "Generating ED25519 SSH key for ${BOLD}$EMAIL${RESET}..."
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    ssh-keygen -t ed25519 -C "$EMAIL" -f "$KEY_PATH" -N ""
    log_success "SSH key generated."
fi

# 3. Start SSH Agent and Add Key
log_info "Starting SSH agent and adding key..."
eval "$(ssh-agent -s)" >/dev/null 2>&1 || true
ssh-add "$KEY_PATH" 2>/dev/null || true
log_success "SSH key registered with ssh-agent."

# 4. Display Public Key for GitHub
echo ""
log_success "GitHub SSH & Git identity setup complete!"
echo "───────────────────────────────────────────────────────"
cat "${KEY_PATH}.pub"
echo "───────────────────────────────────────────────────────"
log_info "Add this SSH public key to your GitHub account:"
log_info "${BOLD}https://github.com/settings/ssh/new${RESET}"
echo ""
