# Zsh on Omarchy: oh-my-zsh behavior + Omarchy's aliases, functions and tools.
# The prompt is Omarchy's starship, so it follows the current Omarchy theme.

# --- 1. Environment ---
# Omarchy's EDITOR, BROWSER, BAT_THEME, MANPAGER and locale fallback
source "${OMARCHY_PATH:-/usr/share/omarchy}/default/bash/envs"

# Silence TensorFlow log spam
export TF_CPP_MIN_LOG_LEVEL='2'

# --- 2. Performance & Latency ---
# Eliminate ESC / multi-key sequence delay (10ms)
export KEYTIMEOUT=1

DISABLE_AUTO_UPDATE="true"
DISABLE_UPDATE_PROMPT="true"
DISABLE_MAGIC_FUNCTIONS="true"
DISABLE_UNTRACKED_FILES_DIRTY="true"

# History
HISTSIZE=100000
SAVEHIST=100000
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS
setopt SHARE_HISTORY
setopt INC_APPEND_HISTORY

# Completion caching
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"
zstyle ':completion:*' rehash true

# --- 3. Oh My Zsh ---
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""  # prompt comes from starship below
plugins=(git)
# Skip compaudit's fpath permission scan on every startup
ZSH_DISABLE_COMPFIX="true"
source "$ZSH/oh-my-zsh.sh"

# --- 4. Omarchy aliases, functions & tools ---
# Loaded after oh-my-zsh, so Omarchy's aliases win where both define one
source "$OMARCHY_PATH/default/bash/aliases"
# Omarchy's worktree functions ga/gd replace oh-my-zsh's git add/diff aliases
unalias ga gd 2>/dev/null
for f in "$OMARCHY_PATH"/default/bash/fns/*; do source "$f"; done
unset f

command -v mise &>/dev/null && eval "$(mise activate zsh)"
command -v zoxide &>/dev/null && eval "$(zoxide init zsh)"
[[ ${TERM:-} != "dumb" ]] && command -v starship &>/dev/null && eval "$(starship init zsh)"

if command -v try &>/dev/null; then
  try() {
    unset -f try
    eval "$(SHELL=/bin/zsh command try init ~/Work/tries)"
    try "$@"
  }
fi

if command -v fzf &>/dev/null; then
  [[ -f /usr/share/fzf/completion.zsh ]] && source /usr/share/fzf/completion.zsh
  [[ -f /usr/share/fzf/key-bindings.zsh ]] && source /usr/share/fzf/key-bindings.zsh
fi

# `omarchy <tab>` completion, reusing Omarchy's bash completion
autoload -U bashcompinit && bashcompinit
# (skipping its bash-only `complete -I` line)
source <(grep -v '^complete -I' "$OMARCHY_PATH/default/bash/completions")

# --- 5. Personal aliases & keybinds ---
alias fastfetch="fastfetch --logo arch"
alias :q="exit"
bindkey -s '^L' 'clear\n'

# --- 6. Plugins (system packages, updated with pacman) ---
ZSH_AUTOSUGGEST_USE_ASYNC=1
ZSH_AUTOSUGGEST_MANUAL_REBIND=1
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=8,bold"  # theme's dim color
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

# Syntax highlighting must be sourced last
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern cursor root line)
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# --- 7. Cursor: steady (non-blinking) block ---
_set_block_cursor() { echo -ne '\e[2 q' }
precmd_functions+=(_set_block_cursor)
zle-keymap-select() { echo -ne '\e[2 q' }
zle -N zle-keymap-select
