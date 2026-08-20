GTK_THEME=Adwaita:dark
GTK2_RC_FILES=/usr/share/themes/Adwaita-dark/gtk-2.0/gtkrc
QT_STYLE_OVERRIDE=Adwaita-Dark
# If not running interactively, don't do anything
[[ $- != *i* ]] && return
#SOURCE ---
source ~/wallpapers/scripts/wallpaper_state.env
source ~/.secret_keys/openai.env
#ALIASES ---
alias sl='systemctl sleep && swaylock -i $WALLPAPER' 
alias grep='grep --color=auto'
alias ah='nvim'
alias ta="tmux-attacher"
alias ..="cd .."
alias ls="lsd"
alias t="tmux"
alias tnw="tmux new-window"
alias tns="tmux new-session"
alias tks="tmux kill-server"
# alias dwm='startx dwm'

# EXEC ONCE ---- 
export EDITOR='nvim'
catnap
# neofetch --kitty ~/wallpapers/favorites/carbeach.png

# BINDS ----
# PS1='[\u@\h \W]\$ '
bind '"\016": "nvim\n"'
bind '"\006": "tmux-attacher\n"'
alias cdf="cd \$(find -mindepth 1 -maxdepth 1 -type d | fzf)" 
kill -SIGUSR1 $(pidof kitty) # Reload kitty colorscheme


# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/opt/miniconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/opt/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/opt/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/opt/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

# EXPORTS
export QT_QPA_PLATFORM=xcb
[ -f /opt/miniconda3/etc/profile.d/conda.sh ] && source /opt/miniconda3/etc/profile.d/conda.sh

