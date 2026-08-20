"""shell.bash — bash fallback rc — same aliases, sourced by non-zsh logins

Sources ~/wallpapers/scripts/wallpaper_state.env; that comes with
desktop.theming.
"""

from __future__ import annotations

from .setup import FeatureSetup, SetupStep

SETUP = FeatureSetup(
    feature_id="shell.bash",
    steps=(
    ),
)
