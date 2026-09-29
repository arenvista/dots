#!/usr/bin/env bash
# Apply a wallpaper everywhere: set it, regenerate the pywal palette, and
# re-theme every consumer (swaync, zathura, kitty, ghostty, the firefox asset
# and the blurred lockscreen copy). Quickshell (bar and panels) re-reads colors
# itself via a watched FileView, so it is not restarted here.

WALLPAPER_PATH="$1"
SCRIPTS_DIR="$(dirname "$(readlink -f "$0")")"

if [ -z "$WALLPAPER_PATH" ] || [ ! -f "$WALLPAPER_PATH" ]; then
    echo "usage: $0 <image>" >&2
    exit 1
fi

# Point ~/wallpapers/current at the chosen file.
ln -sf "$WALLPAPER_PATH" "$HOME/wallpapers/current"

# Scale/crop a copy to the focused monitor's resolution for awww + firefox.
# "[0]" takes the first frame, so an animated GIF yields one image instead of
# magick writing current-0.jpg, current-1.jpg, ... next to a stale current.jpg.
read -r MON_WIDTH MON_HEIGHT < <(
    hyprctl monitors -j | jq -r '.[] | select(.focused == true) | "\(.width) \(.height)"'
)
MON_RES="${MON_WIDTH}x${MON_HEIGHT}"

OUTPUT_PATH_AWWW="$HOME/wallpapers/current.jpg"
OUTPUT_PATH_FIREFOX="$HOME/.config/firefox/current.jpg"

magick "${WALLPAPER_PATH}[0]" -resize "${MON_RES}^" -gravity center -extent "$MON_RES" "$OUTPUT_PATH_AWWW"
cp "$OUTPUT_PATH_AWWW" "$OUTPUT_PATH_FIREFOX"

# Set the wallpaper in the background (its 2s transition needn't hold anything
# up), but regenerate the palette in the foreground: everything below reads
# ~/.cache/wal/*, and a fixed sleep raced slower wal runs.
setsid awww img "$OUTPUT_PATH_AWWW" --transition-type any --transition-duration 2 >/dev/null 2>&1 &
wal -i "$WALLPAPER_PATH" -n -q >/dev/null 2>&1

# Per-app colorizers.
python "$HOME/.config/zathura/templater.py"
python "$SCRIPTS_DIR/wal-template.py" \
    "$HOME/.config/ghostty/themes/theme-custom.template" "$HOME/.config/ghostty/themes/theme-custom"
python "$SCRIPTS_DIR/wal-template.py" \
    "$HOME/.config/kitty/theme-custom.template" "$HOME/.config/kitty/current-theme.conf"

# Signal ghostty and kitty to reload their colors.
pkill -SIGUSR2 ghostty
pkill -SIGUSR1 kitty 2>/dev/null

# Push the new palette into swaync.
cp "$HOME/.cache/wal/colors-swaync.css" "$HOME/.config/swaync/style.css" 2>/dev/null
pkill -SIGUSR1 swaync 2>/dev/null

# Regenerate the blurred wallpaper used by the lockscreen/overview.
magick "${WALLPAPER_PATH}[0]" -resize 1920x -blur 0x8 -quality 85 "$HOME/wallpapers/.current-blurred.jpg"

exit 0
