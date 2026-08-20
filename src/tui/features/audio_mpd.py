"""audio.mpd — mpd daemon, rmpc TUI client, MPRIS bridge for the bar

scripts/Music.sh is the rmpc launcher; hyprland starts mpd-mpris at login.
"""

from __future__ import annotations

from .setup import FeatureSetup, SetupStep

SETUP = FeatureSetup(
    feature_id="audio.mpd",
    steps=(
    ),
)
