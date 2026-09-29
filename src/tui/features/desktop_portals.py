"""desktop.portals — xdg-desktop-portal-hyprland — screen sharing and file pickers

The portals are D-Bus/systemd user services; nothing in the hypr config starts them.
"""

from __future__ import annotations

from .setup import FeatureSetup, SetupStep

SETUP = FeatureSetup(
    feature_id="desktop.portals",
    steps=(
    ),
)
