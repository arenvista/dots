# free Ctrl-S / Ctrl-Q from terminal flow control
[[ -t 0 ]] && stty -ixon

# Shared fzf look for the widgets below
typeset -ga _fzf_ui=(
  --height=50%
  --layout=reverse
  --border=rounded
  --info=inline
)

# ── tmux widgets ────────────────────────────────────────────────────────

tmux-csv-manager-widget() {
  zle push-input
  BUFFER=" $HOME/.config/zsh_custom/macros/tmux-manager.zsh"
  zle accept-line
}
zle -N tmux-csv-manager-widget
bindkey '^s' tmux-csv-manager-widget

tmux-sessionizer-widget() {
  zle push-input   # stash any half-typed command; it pops back at the next prompt
  BUFFER=" $HOME/.config/zsh_custom/macros/tmux-sessionizer.zsh"
  zle accept-line
}
zle -N tmux-sessionizer-widget
bindkey '^f' tmux-sessionizer-widget

# ── General Functions ───────────────────────────────────────────────────

function mkcd() {
  mkdir -p "$1" && cd "$1"
}

# oh-my-zsh's git plugin defines a `glog` alias; drop it so our function wins
unalias glog 2>/dev/null
function glog() {
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    # Launch Neovim and instantly run the Fugitive command
    nvim -c "G log --oneline --graph --decorate --all | only"
  else
    echo "Whoops! You aren't inside a Git repository."
  fi
}

# ── fzf widgets ─────────────────────────────────────────────────────────

# Find a directory (up to 5 levels deep) and cd into it
function fzf-cd-shallow() {
    local dir=$(fd --max-depth 5 --type d | fzf "${_fzf_ui[@]}" \
    --prompt=" Change Dir. " \
    --preview 'ls --color=always -F {} | head -20' \
    --preview-window='right:50%:wrap')

    if [[ -n "$dir" ]]; then
        cd "$dir"
        zle reset-prompt # Refreshes the prompt to show the new path
    fi
}
zle -N fzf-cd-shallow
bindkey '^w' fzf-cd-shallow

# Search running processes and kill one
function fzf-kill() {
    local pid=$(ps -ef | sed 1d | fzf "${_fzf_ui[@]}" \
    --prompt="󰆴 Kill PID: " \
    --preview 'echo {}' \
    --preview-window='down:3:wrap' | awk '{print $2}')

    if [[ -n "$pid" ]]; then
        BUFFER="kill -9 $pid"
        zle accept-line
    fi
    zle reset-prompt
}
zle -N fzf-kill
bindkey '^x' fzf-kill

# Visually select and checkout a git branch
function fzf-checkout() {
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "Not in a git repository."
        zle reset-prompt
        return
    fi

    local branch=$(git branch -a --color=always | grep -v '/HEAD\s' | sort | fzf "${_fzf_ui[@]}" \
    --prompt=" Checkout: " \
    --ansi \
    --preview 'git log --oneline --graph --color=always $(sed s/^..// <<< {} | cut -d" " -f1) | head -20' \
    --preview-window='right:50%:wrap' | \
    sed 's/^..//' | cut -d' ' -f1 | sed 's#^remotes/[^/]*/##')

    if [[ -n "$branch" ]]; then
        BUFFER="git checkout \"$branch\""
        zle accept-line
    fi
    zle reset-prompt
}
zle -N fzf-checkout
bindkey '^b' fzf-checkout

# Find a file and open it in Neovim
function fzf-edit() {
    local file=$(fd --type f --hidden --exclude .git | fzf "${_fzf_ui[@]}" \
    --prompt=" Edit File: " \
    --preview 'bat --style=numbers --color=always {} 2>/dev/null || head -30 {}' \
    --preview-window='right:50%:wrap')

    if [[ -n "$file" ]]; then
        BUFFER="nvim \"$file\""
        zle accept-line
    fi
    zle reset-prompt
}
zle -N fzf-edit
bindkey '^[e' fzf-edit
