alias install="sudo pacman -S"
# -Syu, not -Sy: refreshing the db without upgrading invites partial upgrades
alias update="sudo pacman -Syu"

alias ah="nvim"
alias ..="cd .."
alias ls="lsd"
alias l="ls"

alias reload="source ~/.zshrc"

# bindkey -s '^s' "tmux-attacher\n"
# bindkey -s '^f' "tmux-sessionizer\n"

bindkey -s '^[r' "source ~/.zshrc\n"   # Alt+r — bare Esc would swallow arrow keys etc.
bindkey -s '^n' "nvim\n"
bindkey -s '^y' "yazi\n"
