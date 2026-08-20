"""docs.zathura — zathura PDF viewer, pywal-themed, synctex-wired to nvim

templater.py rewrites zathurarc from the wal cache; called by applwal.sh.
"""

from __future__ import annotations

from .setup import FeatureSetup, SetupStep

SETUP = FeatureSetup(
    feature_id="docs.zathura",
    steps=(
    ),
)
