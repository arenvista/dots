"""net.core — NetworkManager — backs the waybar network module and the wifi panel"""

from __future__ import annotations

from .setup import FeatureSetup, SetupStep

SETUP = FeatureSetup(
    feature_id="net.core",
    steps=(
    ),
)
