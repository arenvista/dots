alias install="sudo pacman -S"
# bare yay = -Syu over repo and AUR packages (never -Sy: partial upgrades)
alias update="yay"

alias ah="nvim"
alias ..="cd .."
alias ls="lsd"
alias l="ls"

# exec a fresh shell: re-sourcing .zshrc duplicates $fpath, which makes
# oh-my-zsh rebuild its completion cache (and loads every plugin twice)
alias reload="exec zsh"

# bindkey -s '^s' "tmux-attacher\n"
# bindkey -s '^f' "tmux-sessionizer\n"

# Alt+r / Ctrl-N / Alt+o launchers are widgets in macros.zsh: `bindkey -s`
# typed its text after whatever was already on the line
