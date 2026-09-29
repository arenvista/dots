# Read by every zsh: the login shell SDDM starts Hyprland from (so GUI apps
# inherit these), interactive shells and scripts. Keep it to cheap exports;
# interactive setup and secrets belong in .zshrc.
export EDITOR="nvim"

# Keep $path free of duplicates, prepend Cargo and ~/.local/bin (uv tools)
typeset -U path
path=("$HOME/.cargo/bin" "$HOME/.local/bin" $path)
