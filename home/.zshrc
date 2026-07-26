# Enable Powerlevel10k instant prompt.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# --- 1. Environment & Log Drivers ---
# Silence TensorFlow absolute log spam system-wide
export TF_CPP_MIN_LOG_LEVEL='2'

# --- 2. Zsh Performance & Latency Optimizations ---
# Eliminate ESC key / multi-key sequence delay (default: 40, 1 = 10ms response)
export KEYTIMEOUT=1

# Disable Oh My Zsh auto-update check at startup to eliminate prompt lag
DISABLE_AUTO_UPDATE="true"
DISABLE_UPDATE_PROMPT="true"

# Disable paste magic functions to eliminate paste latency
DISABLE_MAGIC_FUNCTIONS="true"

# Speed up git status prompt in large repositories
DISABLE_UNTRACKED_FILES_DIRTY="true"

# History Optimization
HISTSIZE=100000
SAVEHIST=100000
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS
setopt SHARE_HISTORY
setopt INC_APPEND_HISTORY

# Completion Engine Caching for Zero Latency
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"
zstyle ':completion:*' rehash true

# --- 3. Shell Shortcuts & Global Aliases ---
alias fastfetch="fastfetch --logo arch"
alias :q="exit"
bindkey -s '^L' 'clear\n'

# --- 4. Oh My Zsh Framework Core Configuration ---
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

# Active feature extensions tree
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

# Sourcing framework hooks
source $ZSH/oh-my-zsh.sh

# --- 5. Plugin Ecosystem Optimizations ---
# Async autosuggestions for 0-latency typing
ZSH_AUTOSUGGEST_USE_ASYNC=1
ZSH_AUTOSUGGEST_MANUAL_REBIND=1
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#8a8a8a,bold"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern cursor root line)

# --- 6. Powerlevel10k Theme File Sync ---
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
