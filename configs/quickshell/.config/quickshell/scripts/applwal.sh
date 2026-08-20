#!/usr/bin/env bash
# Apply a wallpaper everywhere: set it, regenerate the pywal palette, and
# re-theme every consumer (waybar, swaync, zathura, ghostty, the firefox asset
# and the blurred lockscreen copy). Quickshell re-reads colors itself via a
# watched FileView, so it is not restarted here.

WALLPAPER_PATH="$1"

if [ -z "$WALLPAPER_PATH" ] || [ ! -f "$WALLPAPER_PATH" ]; then
    exit 1
fi

# Point ~/wallpapers/current at the chosen file.
ln -sf "$WALLPAPER_PATH" "$HOME/wallpapers/current"

# Scale/crop a copy to the focused monitor's resolution for swww + firefox.
read -r MON_WIDTH MON_HEIGHT < <(
    hyprctl monitors -j | jq -r '.[] | select(.focused == true) | "\(.width) \(.height)"'
)
MON_RES="${MON_WIDTH}x${MON_HEIGHT}"

OUTPUT_PATH_SWWW="$HOME/wallpapers/current.jpg"
OUTPUT_PATH_FIREFOX="$HOME/dotfiles/utils/firefox/current.jpg"

magick "$WALLPAPER_PATH" -resize "${MON_RES}^" -gravity center -extent "$MON_RES" "$OUTPUT_PATH_SWWW"
magick "$WALLPAPER_PATH" -resize "${MON_RES}^" -gravity center -extent "$MON_RES" "$OUTPUT_PATH_FIREFOX"

# Set the wallpaper and regenerate the pywal palette (detached background jobs).
setsid awww img "$OUTPUT_PATH_SWWW" --transition-type any --transition-duration 2 >/dev/null 2>&1 &
setsid wal -i "$WALLPAPER_PATH" -n -q >/dev/null 2>&1 &

# Give wal a moment to write ~/.cache/wal/* before the consumers read it.
sleep 1

# Per-app colorizers.
python "$HOME/.config/zathura/templater.py"
python "$HOME/.config/quickshell/scripts/ghosty-colorizer.py"

# Signal ghostty to reload its colors.
pkill -SIGUSR2 ghostty

# Restart waybar with the fresh palette.
killall waybar 2>/dev/null
setsid waybar >/dev/null 2>&1 &

# Push the new palette into swaync.
cp "$HOME/.cache/wal/colors-swaync.css" "$HOME/.config/swaync/style.css" 2>/dev/null
pkill -SIGUSR1 swaync 2>/dev/null

# Regenerate the blurred wallpaper used by the lockscreen/overview.
if [[ "$WALLPAPER_PATH" == *.gif ]]; then
    magick "${WALLPAPER_PATH}[0]" -resize 1920x -blur 0x8 -quality 85 "$HOME/wallpapers/.current-blurred.jpg"
else
    magick "$WALLPAPER_PATH" -resize 1920x -blur 0x8 -quality 85 "$HOME/wallpapers/.current-blurred.jpg"
fi

exit 0
