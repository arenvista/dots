"""apps.extras — the desktop apps this machine actually carries

Pick from this list rather than taking it whole.
"""

from __future__ import annotations

from .setup import FeatureSetup, SetupStep

SETUP = FeatureSetup(
    feature_id="apps.extras",
    steps=(
    ),
)
