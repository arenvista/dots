"""system.dotfiles — GNU stow — the linker every other feature's `stow` list depends on

Always required. manager/main.py link drives it.
"""

from __future__ import annotations

from .setup import FeatureSetup, SetupStep

SETUP = FeatureSetup(
    feature_id="system.dotfiles",
    steps=(
    ),
)
