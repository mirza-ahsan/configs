# Enable Powerlevel10k instant prompt.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# --- 1. Custom Core Functions & System Environment Drivers ---
export TF_FORCE_GPU_ALLOW_GROWTH=true

# Silence TensorFlow absolute log spam system-wide
export TF_CPP_MIN_LOG_LEVEL='2'
export TF_ENABLE_ONEDNN_OPTS='0'

# Auto-Detecting TensorFlow CUDA Engine (Dynamic Version)
add_tf_cuda_paths() {
    if [ -n "$VIRTUAL_ENV" ]; then
        local PY_VER=$(python -c "import sys; print(f'python{sys.version_info.major}.{sys.version_info.minor}')")
        local SITE_PACKAGES="$VIRTUAL_ENV/lib/$PY_VER/site-packages"
        if [ -d "$SITE_PACKAGES/nvidia" ]; then
            # Filter out old virtual env paths to prevent path bloat
            export LD_LIBRARY_PATH=$(echo "$LD_LIBRARY_PATH" | awk -v RS=: -v ORS=: '!/site-packages\/nvidia/')
            # Append the current active virtual environment paths
            export LD_LIBRARY_PATH="$SITE_PACKAGES/nvidia/cuda_runtime/lib:$SITE_PACKAGES/nvidia/cudnn/lib:$SITE_PACKAGES/nvidia/cublas/lib:$SITE_PACKAGES/nvidia/cufft/lib:$SITE_PACKAGES/nvidia/curand/lib:$SITE_PACKAGES/nvidia/cusolver/lib:$SITE_PACKAGES/nvidia/cusparse/lib:$LD_LIBRARY_PATH"
        fi
    fi
}

# Run automatically every time a new prompt draws or an environment activates
autoload -Uz add-zsh-hook
add-zsh-hook precmd add_tf_cuda_paths


# --- 2. Shell Shortcuts & Global Aliases ---
alias fastfetch="fastfetch --logo arch"
alias :q="exit"
bindkey -s '^L' 'clear\n'


# --- 3. Oh My Zsh Framework Core Configuration ---
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="powerlevel10k/powerlevel10k"

# Active feature extensions tree
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

# Sourcing framework hooks
source $ZSH/oh-my-zsh.sh

# --- 4. Plugin Ecosystem Theme Variables ---
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#8a8a8a,bold"
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern cursor root line)

# --- 5. Powerlevel10k Theme File Sync ---
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
