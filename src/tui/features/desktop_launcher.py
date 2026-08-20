"""desktop.launcher — rofi app launcher (SUPER+SPACE), wallpaper-backed theme

config.rasi imports ~/.cache/wal/colors-rofi-light.rasi — pywal must have
run once.
"""

from __future__ import annotations

from .setup import FeatureSetup, SetupStep

SETUP = FeatureSetup(
    feature_id="desktop.launcher",
    steps=(
    ),
)
