"""cli.files — yazi file manager, wired to nsxiv / zathura / nvim openers

Bound to Ctrl-Y in zsh and SUPER+E in hyprland (ghostty -e yazi).
"""

from __future__ import annotations

from .setup import FeatureSetup, SetupStep

SETUP = FeatureSetup(
    feature_id="cli.files",
    steps=(
    ),
)
