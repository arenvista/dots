"""desktop.appearance — cursor theme, Qt/GTK styling to match the compositor env vars

hyprland.lua pins XCURSOR/HYPRCURSOR to Bibata-Modern-Ice at size 25.
"""

from __future__ import annotations

from .setup import FeatureSetup, SetupStep

SETUP = FeatureSetup(
    feature_id="desktop.appearance",
    steps=(
    ),
)
