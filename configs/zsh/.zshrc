# =============================================================================
# 1. ENVIRONMENT VARIABLES & PATHS
# =============================================================================
# EDITOR and $path are set in ~/.zshenv, so the login shell SDDM starts
# Hyprland from (and every GUI app under it) gets them too.
export ZSH="$HOME/.oh-my-zsh"
export ZSH_CUSTOM="$HOME/.config/zsh_custom"

# Load secret keys (skip silently if the file isn't there)
[[ -r "$HOME/.secret_keys/openai.env" ]] && source "$HOME/.secret_keys/openai.env"

# =============================================================================
# 2. OH MY ZSH CONFIGURATION
# =============================================================================
# starship draws the prompt (section 5); the theme is only a fallback for
# machines without it
if (( $+commands[starship] )); then ZSH_THEME=""; else ZSH_THEME="robbyrussell"; fi

plugins=( git z sudo web-search copypath extract )

# Initialize Oh My Zsh — this also auto-sources every *.zsh file in
# $ZSH_CUSTOM (aliases.zsh, macros.zsh), so they must not be sourced again.
source "$ZSH/oh-my-zsh.sh"

# =============================================================================
# 3. SYSTEM-INSTALLED PLUGINS (Order matters here!)
# =============================================================================
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# fzf's Ctrl-R fuzzy history. Empty commands switch off its Ctrl-T and Alt-C
# bindings (Alt-C is macros.zsh's cd widget); completion.zsh stays unloaded,
# so Tab is untouched. Needs a terminal: without one ($TTY empty, e.g.
# `zsh -i -c` from a tool) the file errors with "can't change option: zle".
FZF_CTRL_T_COMMAND= FZF_ALT_C_COMMAND=
[[ -n $TTY && -r /usr/share/fzf/key-bindings.zsh ]] && source /usr/share/fzf/key-bindings.zsh

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
# Both are optional features in deps.toml (cli.catnap, shell.prompt), so skip
# them where they aren't installed instead of erroring at every prompt
(( $+commands[catnap] )) && catnap
(( $+commands[starship] )) && eval "$(starship init zsh)"
