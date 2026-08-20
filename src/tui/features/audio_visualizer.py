"""audio.visualizer — cava audio visualizer

The cava config/shaders are no longer tracked in configs/ — package
only.
"""

from __future__ import annotations

from .setup import FeatureSetup, SetupStep

SETUP = FeatureSetup(
    feature_id="audio.visualizer",
    steps=(
    ),
)
