"""cli.core — the command-line baseline the aliases and configs assume"""

from __future__ import annotations

from .setup import FeatureSetup, SetupStep

SETUP = FeatureSetup(
    feature_id="cli.core",
    steps=(
    ),
)
