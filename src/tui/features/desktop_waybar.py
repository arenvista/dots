"""desktop.waybar — waybar top bar — clock, workspaces, media, volume, net, dashboard

Bar buttons call `qs ipc call ...`, so the panels come from
desktop.quickshell.
"""

from __future__ import annotations

from .setup import FeatureSetup, SetupStep

SETUP = FeatureSetup(
    feature_id="desktop.waybar",
    steps=(
    ),
)
