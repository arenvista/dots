# =============================================================================
# 1. ENVIRONMENT VARIABLES & PATHS
# =============================================================================
export ZSH="$HOME/.oh-my-zsh"
export ZSH_CUSTOM="$HOME/.config/zsh_custom"
export EDITOR="nvim"

# Keep $path free of duplicates, prepend Cargo
typeset -U path
path=("$HOME/.cargo/bin" $path)

# Load secret keys (skip silently if the file isn't there)
[[ -r "$HOME/.secret_keys/openai.env" ]] && source "$HOME/.secret_keys/openai.env"

# =============================================================================
# 2. OH MY ZSH CONFIGURATION
# =============================================================================
ZSH_THEME="robbyrussell"

plugins=( git z sudo web-search copypath extract )

# Initialize Oh My Zsh — this also auto-sources every *.zsh file in
# $ZSH_CUSTOM (aliases.zsh, macros.zsh), so they must not be sourced again.
source "$ZSH/oh-my-zsh.sh"

# =============================================================================
# 3. SYSTEM-INSTALLED PLUGINS (Order matters here!)
# =============================================================================
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# =============================================================================
# 4. NODE VERSION MANAGER (NVM) — lazy-loaded
# =============================================================================
# Sourcing nvm.sh eagerly costs a few hundred ms per shell. Instead, stub the
# common commands; the first call loads the real nvm and replaces the stubs.
export NVM_DIR="$HOME/.nvm"
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
  _nvm_lazy_cmds=(nvm node npm npx corepack)
  _nvm_lazy_load() {
    unfunction $_nvm_lazy_cmds 2>/dev/null
    source "$NVM_DIR/nvm.sh"
    [[ -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"
  }
  for _cmd in $_nvm_lazy_cmds; do
    eval "${_cmd}() { _nvm_lazy_load; ${_cmd} \"\$@\" }"
  done
  unset _cmd
fi

# =============================================================================
# 5. STARTUP SCRIPTS
# =============================================================================
# Placed last so it doesn't block the shell from initializing quickly
catnap
eval "$(starship init zsh)"
