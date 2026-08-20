"""net.sharing — Syncthing, KDE Connect and the miniserve static server

hyprland starts all three at login; miniserve hosts
utils/firefox/home.html.
"""

from __future__ import annotations

from .setup import FeatureSetup, SetupStep

SETUP = FeatureSetup(
    feature_id="net.sharing",
    steps=(
    ),
)
