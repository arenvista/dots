"""desktop.portals — xdg-desktop-portal-hyprland — screen sharing and file pickers

hypr/xdph_start.sh restarts the portal stack after the compositor is up.
"""

from __future__ import annotations

from .setup import FeatureSetup, SetupStep

SETUP = FeatureSetup(
    feature_id="desktop.portals",
    steps=(
    ),
)
