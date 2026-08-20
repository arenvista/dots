"""desktop.notifications — swaync notification daemon and control center

style.css is overwritten from ~/.cache/wal/colors-swaync.css on every
wallpaper change.
"""

from __future__ import annotations

from .setup import FeatureSetup, SetupStep

SETUP = FeatureSetup(
    feature_id="desktop.notifications",
    steps=(
    ),
)
