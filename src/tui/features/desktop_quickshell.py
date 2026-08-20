"""desktop.quickshell — quickshell panels — launcher, dashboard, wifi, bluetooth, music

Wifi/BT/MPRIS come from Quickshell's own services, not shelled-out CLIs.
Thumbnails: `uv run scripts/create_thumbs.py` (pulls Pillow itself).
"""

from __future__ import annotations

from .setup import FeatureSetup, SetupStep

SETUP = FeatureSetup(
    feature_id="desktop.quickshell",
    steps=(
    ),
)
