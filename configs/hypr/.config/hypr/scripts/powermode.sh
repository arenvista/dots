#!/bin/sh
# Charger plugged or pulled: run by quickshell's Battery singleton whenever
# UPower's onBattery flips. hyprland.lua reads the AC state itself when it
# loads, so a reload is all the compositor needs; this script only adds the
# parts Hyprland can't do, like pausing syncthing's radio traffic on battery.

# Set to 0 to keep syncing on battery
PAUSE_SYNCTHING=1

hyprctl reload >/dev/null

online=$(cat /sys/class/power_supply/AC/online 2>/dev/null || echo 1)
if [ "$PAUSE_SYNCTHING" = 1 ]; then
    if [ "$online" = 0 ]; then
        systemctl --user stop syncthing.service
    else
        systemctl --user start syncthing.service
    fi
fi
