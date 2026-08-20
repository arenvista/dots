#!/usr/bin/env zsh
# tmux-csv-sessionizer — pick a project from a CSV with fzf, jump to its tmux session.
#
# CSV format (one entry per line, '#' lines and blanks ignored):
#   "Title describing directory", /path/to/dir
#
# Usage:
#   tmux-csv-sessionizer.zsh [path/to/sessions.csv]
#   (falls back to $TMUX_SESSIONS_CSV, then ~/.config/tmux/sessions.csv)

emulate -L zsh
setopt err_return pipe_fail

CSV_FILE="${1:-${TMUX_SESSIONS_CSV:-$HOME/.config/tmux/sessions.csv}}"

for cmd in fzf tmux; do
  (( $+commands[$cmd] )) || { print -u2 "error: '$cmd' not found in PATH"; return 1 }
done
[[ -r "$CSV_FILE" ]] || { print -u2 "error: cannot read CSV file: $CSV_FILE"; return 1 }

# ── Parse CSV into "title <TAB> path" lines ─────────────────────────────
parse_csv() {
  local line title dir
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line##[[:space:]]#}"                      # ltrim
    [[ -z "$line" || "$line" == \#* ]] && continue
    if [[ "$line" =~ '^"([^"]*)"[[:space:]]*,[[:space:]]*(.*)$' ]]; then
      title="${match[1]}" dir="${match[2]}"           # quoted title
    elif [[ "$line" =~ '^([^,]*[^,[:space:]])[[:space:]]*,[[:space:]]*(.*)$' ]]; then
      title="${match[1]}" dir="${match[2]}"           # bare title
    else
      continue
    fi
    dir="${dir%%[[:space:]]#}"                        # rtrim path
    dir="${dir#\"}" dir="${dir%\"}"                   # strip optional quotes
    dir="${dir/#\~/$HOME}"                            # expand leading ~
    printf '%s\t%s\n' "$title" "$dir"
  done < "$CSV_FILE"
}

entries="$(parse_csv)"
[[ -n "$entries" ]] || { print -u2 "error: no valid entries found in $CSV_FILE"; return 1 }

# ── Preview command: pretty listing if eza/exa exists, else ls ──────────
if (( $+commands[eza] )); then
  preview='eza --tree --level=1 --icons --color=always --group-directories-first {2} 2>/dev/null'
elif (( $+commands[exa] )); then
  preview='exa --tree --level=1 --color=always {2} 2>/dev/null'
else
  preview='ls -A --color=always {2} 2>/dev/null'
fi
preview="echo '\\033[1;35m{1}\\033[0m'; echo '\\033[2m{2}\\033[0m'; echo; $preview"

# ── fzf picker (shows only the title column) ────────────────────────────
selected="$(
  print -r -- "$entries" | fzf \
    --delimiter=$'\t' \
    --with-nth=1 \
    --ansi \
    --height=60% \
    --layout=reverse \
    --border=rounded \
    --border-label=' ◤ tmux sessions ◢ ' \
    --prompt='  ' \
    --pointer='▶' \
    --marker='✓' \
    --header=$'enter: open / switch  ·  esc: cancel' \
    --preview="$preview" \
    --preview-window='right:45%:border-left' \
    --color='border:magenta,label:bold:magenta,prompt:cyan,pointer:magenta,header:dim'
)" || return 0   # user pressed esc — exit quietly

title="${selected%%$'\t'*}"
dir="${selected#*$'\t'}"

[[ -d "$dir" ]] || { print -u2 "error: directory does not exist: $dir"; return 1 }

# tmux session names cannot contain '.' or ':'; tidy the rest for readability
session="${title// /_}"
session="${session//[.:]/-}"

# ── Create the session if needed, then attach or switch ─────────────────
if ! tmux has-session -t "=$session" 2>/dev/null; then
  tmux new-session -d -s "$session" -c "$dir"
fi

if [[ -n "$TMUX" ]]; then
  tmux switch-client -t "=$session"
else
  tmux attach-session -t "=$session"
fi
