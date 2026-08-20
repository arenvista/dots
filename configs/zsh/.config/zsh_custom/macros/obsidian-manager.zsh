#!/usr/bin/env zsh
# tmux-csv-manager — manage the path list used by tmux-csv-sessionizer.
#
# Usage:
#   tmux-csv-manager.zsh                no args → fzf menu of actions
#   tmux-csv-manager.zsh add [path]     add $PWD (or the given path)
#   tmux-csv-manager.zsh edit           pick an entry with fzf, edit the path inline
#   tmux-csv-manager.zsh remove         pick entries with fzf (tab = multi-select), delete
#   tmux-csv-manager.zsh list           pretty-print all entries
#
# File: $TMUX_SESSIONS_CSV, else ~/.config/tmux/sessions.csv.
# One path per line. Comments (#) and blank lines in the file are preserved.
# Legacy `"title", path` lines are read by taking the path field only.

emulate -L zsh
setopt err_return pipe_fail

cmd="${1:-}"
CSV_FILE="${TMUX_SESSIONS_CSV:-$HOME/dotfiles/utils/obsidianvaults/vaults.md}"

if [[ -z "$cmd" || "$cmd" == (edit|remove|rm) ]]; then
  (( $+commands[fzf] )) || { print -u2 "error: fzf not found in PATH"; return 1 }
fi

# ── No subcommand → pretty action menu ──────────────────────────────────
if [[ -z "$cmd" ]]; then
  menu=(
    $'\033[1;32madd\033[0m\ttrack the current directory'
    $'\033[1;33medit\033[0m\tedit an entry\'s path'
    $'\033[1;31mremove\033[0m\tremove entries (tab: multi-select)'
    $'\033[1;36mlist\033[0m\tshow all tracked directories'
  )
  cmd="$(
    print -rl -- "${menu[@]}" | fzf \
      --delimiter=$'\t' \
      --ansi \
      --height=~12 --layout=reverse --border=rounded \
      --border-label=' ◤ sessions: choose action ◢ ' \
      --prompt='  ' --pointer='▶' \
      --header="$(print -P "%B%F{magenta}${PWD/#$HOME/~}%f%b")" \
      --color='border:magenta,label:bold:magenta,prompt:cyan,pointer:magenta,header:dim' \
      --no-multi \
      | head -n1 | cut -f1 | sed 's/\x1b\[[0-9;]*m//g'
  )" || true
  [[ -n "$cmd" ]] || return 0   # esc — exit quietly
fi

mkdir -p -- "${CSV_FILE:h}"
[[ -e "$CSV_FILE" ]] || : > "$CSV_FILE"

autoload -Uz colors && colors

# ── Inline prompt with an editable default value ────────────────────────
# Forces the emacs keymap for this vared call so backspace / ^W / ^U delete
# the whole line — including the pre-filled default. Under vi keybindings
# (bindkey -v) vared starts in insert mode, where vi-backward-delete-char
# refuses to erase text that existed before insert mode began, leaving the
# default path impossible to shorten. '-M emacs' sidesteps that without
# mutating the user's global keymap.
prompt_edit() {  # prompt_edit <prompt> <varname>
  vared -M emacs -p "$1" "$2"
}

# ── Parse the file, tagging each entry with its line number ─────────────
# Emits: lineno <TAB> path
parse_entries() {
  local line dir n=0
  while IFS= read -r line || [[ -n "$line" ]]; do
    (( ++n ))
    local trimmed="${line##[[:space:]]#}"
    [[ -z "$trimmed" || "$trimmed" == \#* ]] && continue
    # legacy: "title", /path  → keep only the path
    if [[ "$trimmed" =~ '^"[^"]*"[[:space:]]*,[[:space:]]*(.*)$' ]]; then
      dir="${match[1]}"
    else
      dir="$trimmed"
    fi
    dir="${dir%%[[:space:]]#}"; dir="${dir#\"}"; dir="${dir%\"}"
    [[ -n "$dir" ]] || continue
    printf '%d\t%s\n' "$n" "$dir"
  done < "$CSV_FILE"
}

# ── fzf picker over entries; extra args pass through (e.g. --multi) ─────
pick_entries() {
  parse_entries | fzf \
    --delimiter=$'\t' \
    --with-nth=2 \
    --height=50% --layout=reverse --border=rounded \
    --border-label=" ◤ $1 ◢ " \
    --prompt='  ' --pointer='▶' --marker='✗ ' \
    --preview=$'echo "\033[1;35m{2}\033[0m"' \
    --preview-window='down:3:border-top' \
    --color='border:magenta,label:bold:magenta,prompt:cyan,pointer:magenta' \
    "${@:2}"
}

# ── Rewrite the file with line $1 replaced by $2 (or deleted if $2 unset)
rewrite_line() {
  local target="$1" replacement="$2" tmp n=0 line
  tmp="$(mktemp "${CSV_FILE}.XXXXXX")"
  while IFS= read -r line || [[ -n "$line" ]]; do
    (( ++n ))
    if (( n == target )); then
      (( $# >= 2 )) && print -r -- "$replacement" >> "$tmp"
    else
      print -r -- "$line" >> "$tmp"
    fi
  done < "$CSV_FILE"
  mv -- "$tmp" "$CSV_FILE"
}

case "$cmd" in
# ────────────────────────────────────────────────────────────────────────
add)
  dir="${2:-$PWD}"
  dir="${dir%/}"                                  # no trailing slash
  [[ -n "$dir" ]] || { print -u2 "error: empty path, aborting"; return 1 }
  # refuse duplicates (compare resolved paths)
  while IFS=$'\t' read -r _ existing; do
    existing="${existing/#\~/$HOME}"
    if [[ "${existing:A}" == "${${dir/#\~/$HOME}:A}" ]]; then
      print -u2 "already tracked: $dir"
      return 1
    fi
  done < <(parse_entries)

  [[ -d "${dir/#\~/$HOME}" ]] || print -u2 "warning: '$dir' does not exist (saved anyway)"

  print -r -- "$dir" >> "$CSV_FILE"
  print "${fg_bold[green]}added${reset_color} $dir"
  ;;
# ────────────────────────────────────────────────────────────────────────
edit)
  selected="$(pick_entries 'edit entry')" || return 0
  lineno="${selected%%$'\t'*}"
  dir="${selected#*$'\t'}"

  prompt_edit "Path: " dir
  [[ -n "$dir" ]] || { print -u2 "error: empty path, aborting"; return 1 }
  dir="${dir%/}"
  [[ -d "${dir/#\~/$HOME}" ]] || print -u2 "warning: '$dir' does not exist (saved anyway)"

  rewrite_line "$lineno" "$dir"
  print "${fg_bold[yellow]}updated${reset_color} $dir"
  ;;
# ────────────────────────────────────────────────────────────────────────
remove|rm)
  selected="$(pick_entries 'remove entries (tab: multi)' --multi)" || return 0
  # collect selections, then delete bottom-up so line numbers stay valid
  linenos=()
  while IFS=$'\t' read -r n dir; do
    [[ -n "$n" ]] || continue
    linenos+=("$n")
    print "${fg_bold[red]}removed${reset_color} $dir"
  done <<< "$selected"
  for lineno in ${(On)linenos}; do
    rewrite_line "$lineno"
  done
  ;;
# ────────────────────────────────────────────────────────────────────────
list|ls)
  parse_entries | while IFS=$'\t' read -r n dir; do
    marker=' '
    if [[ "${${dir/#\~/$HOME}:A}" == "${PWD:A}" ]]; then
      marker="${fg_bold[cyan]}●${reset_color}"
    fi
    printf '%s %s%s%s\n' "$marker" "${fg_bold[magenta]}" "$dir" "$reset_color"
  done
  ;;
# ────────────────────────────────────────────────────────────────────────
*)
  print -u2 "usage: ${0:t} {add [path]|edit|remove|list}"
  return 1
  ;;
esac
