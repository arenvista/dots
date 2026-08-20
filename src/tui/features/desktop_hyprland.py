"""desktop.hyprland — Hyprland (lua config, scrolling layout), lockscreen, keyboard pointer

hyprland.lua is the lua config format; .hyprland.conf.bk is the old
hyprlang one.
"""

from __future__ import annotations

from .setup import FeatureSetup, SetupStep

SETUP = FeatureSetup(
    feature_id="desktop.hyprland",
    steps=(
        SetupStep(
            'hyprpm plugin',
            'hyprpm list | grep -q hyprscrolling || { hyprpm add https://github.com/hyprwm/hyprland-plugins && hyprpm enable hyprscrolling; }',
            when='post',
        ),
    ),
)
