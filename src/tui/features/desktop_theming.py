"""desktop.theming — pywal palette pipeline — wallpapers, templates, applwal.sh, colorizers

applwal.sh is the hub: sets the wallpaper (awww), regenerates the palette
(wal), then re-themes waybar, swaync, zathura, ghostty and kitty.
wal/templates/ holds the source templates; templates/ is the stowed copy
consumers read.
"""

from __future__ import annotations

from .setup import FeatureSetup, SetupStep

SETUP = FeatureSetup(
    feature_id="desktop.theming",
    steps=(
    ),
)
