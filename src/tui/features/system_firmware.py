"""system.firmware — fwupd — backs `manager` firmware updates (src/setup.py)"""

from __future__ import annotations

from .setup import FeatureSetup, SetupStep

SETUP = FeatureSetup(
    feature_id="system.firmware",
    steps=(
    ),
)
