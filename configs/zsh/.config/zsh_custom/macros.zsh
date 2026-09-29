# free Ctrl-S / Ctrl-Q from terminal flow control
[[ -t 0 ]] && stty -ixon

# Shared fzf look for the widgets below
typeset -ga _fzf_ui=(
  --height=50%
  --layout=reverse
  --border=rounded
  --info=inline
)

# Run $1 as its own command line from a widget. push-input stashes any
# half-typed command; it pops back at the next prompt. A leading space in $1
# keeps the line out of history (hist_ignore_space).
_zle_run() {
  zle push-input
  BUFFER=$1
  zle accept-line
}

# ── Launchers ───────────────────────────────────────────────────────────

nvim-widget() { _zle_run nvim }
zle -N nvim-widget
bindkey '^n' nvim-widget

yazi-widget() { _zle_run yazi }
zle -N yazi-widget
bindkey '^[o' yazi-widget

# exec a fresh shell rather than re-sourcing .zshrc (see `reload` in aliases.zsh)
reload-widget() { _zle_run ' exec zsh' }
zle -N reload-widget
bindkey '^[r' reload-widget   # Alt+r — bare Esc would swallow arrow keys etc.

# ── tmux widgets ────────────────────────────────────────────────────────

tmux-csv-manager-widget() { _zle_run " $HOME/.config/zsh_custom/macros/tmux-manager.zsh" }
zle -N tmux-csv-manager-widget
bindkey '^s' tmux-csv-manager-widget

tmux-sessionizer-widget() { _zle_run " $HOME/.config/zsh_custom/macros/tmux-sessionizer.zsh" }
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
    fi
    zle reset-prompt # Show the new path, or redraw after a cancel
}
zle -N fzf-cd-shallow
bindkey '^[c' fzf-cd-shallow

# Search your processes and kill them (tab: multi-select). Sends SIGTERM so
# they can clean up; if one ignores it, up-arrow and add -9.
function fzf-kill() {
    local pids=$(ps -u "$UID" -o pid,etime,%cpu,%mem,args | fzf "${_fzf_ui[@]}" \
    --prompt="󰆴 Kill PID: " \
    --header-lines=1 \
    --multi \
    --accept-nth=1 \
    --preview 'echo {}' \
    --preview-window='down:3:wrap')

    if [[ -n "$pids" ]]; then
        _zle_run "kill ${(f)pids}"
    fi
    zle reset-prompt
}
zle -N fzf-kill
bindkey '^[k' fzf-kill

# Visually select and checkout a git branch (most recent commits first)
function fzf-checkout() {
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        zle -M "Not in a git repository."
        return
    fi

    # ' -> ' only appears on the remotes/*/HEAD alias: ref names can't hold spaces
    local branch=$(git branch -a --sort=-committerdate --color=always \
    | grep -v -e ' -> ' -e 'HEAD detached' | fzf "${_fzf_ui[@]}" \
    --prompt=" Checkout: " \
    --ansi \
    --preview 'git log --oneline --graph --color=always $(sed s/^..// <<< {} | cut -d" " -f1) | head -20' \
    --preview-window='right:50%:wrap' | \
    sed 's/^..//' | cut -d' ' -f1 | sed 's#^remotes/[^/]*/##')

    # (q) quotes the name: git allows $(...) in branch names, and so do filenames
    if [[ -n "$branch" ]]; then
        _zle_run "git checkout ${(q)branch}"
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
        _zle_run "nvim ${(q)file}"
    fi
    zle reset-prompt
}
zle -N fzf-edit
bindkey '^[e' fzf-edit
