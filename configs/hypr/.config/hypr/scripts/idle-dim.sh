#!/bin/sh
# hypridle's dim step: drop the panel to 10%, but never raise it if it's
# already below that. Always saves first (-s), so the listener's
# `brightnessctl -r` on resume restores this level and not a stale one.
cur=$(brightnessctl g)
target=$(($(brightnessctl m) / 10))
[ "$cur" -lt "$target" ] && target=$cur
brightnessctl -s set "$target"
