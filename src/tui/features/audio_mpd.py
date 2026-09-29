"""audio.mpd — mpd daemon, rmpc TUI client, MPRIS bridge for the bar

scripts/Music.sh is the rmpc launcher; mpd-mpris runs as a user unit.
"""

from __future__ import annotations

from .setup import FeatureSetup, SetupStep

SETUP = FeatureSetup(
    feature_id="audio.mpd",
    steps=(
    ),
)
