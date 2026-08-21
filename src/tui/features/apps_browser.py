"""apps.browser — Firefox plus the org-backed start page (userChrome, todo/calendar)

The firefox stow package lands the start page at ~/.config/firefox/, where
net.miniserve serves it and applwal.sh refreshes its background. org-sync.py
is stdlib-only.
"""

from __future__ import annotations

from .setup import FeatureSetup, SetupStep

SETUP = FeatureSetup(
    feature_id="apps.browser",
    steps=(
        SetupStep(
            'firefox org-sync unit',
            'test -x "$HOME/.config/firefox/install_systemd_service.sh" && "$HOME/.config/firefox/install_systemd_service.sh"',
            when='post',
        ),
        SetupStep(
            'userChrome',
            'copy ~/.config/firefox/chrome/ into the profile dir and set toolkit.legacyUserProfileCustomizations.stylesheets',
            when='post', interactive=True,
        ),
    ),
)
