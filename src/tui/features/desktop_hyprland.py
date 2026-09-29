"""desktop.hyprland — Hyprland (lua config, scrolling layout), lockscreen, keyboard pointer

hyprland.lua is the lua config format; .hyprland.conf.bk is the old
hyprlang one.
"""

from __future__ import annotations

from .setup import FeatureSetup, SetupStep

SETUP = FeatureSetup(
    feature_id="desktop.hyprland",
    steps=(
    ),
)
