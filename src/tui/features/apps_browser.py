"""apps.browser — Firefox plus the org-backed start page (userChrome, todo/calendar)

The start page's background is refreshed by applwal.sh. org-sync.py is
stdlib-only.
"""

from __future__ import annotations

from .setup import FeatureSetup, SetupStep

SETUP = FeatureSetup(
    feature_id="apps.browser",
    steps=(
        SetupStep(
            'firefox org-sync unit',
            'test -x utils/firefox/install_systemd_service.sh && utils/firefox/install_systemd_service.sh',
            when='post',
        ),
        SetupStep(
            'userChrome',
            'copy utils/firefox/chrome/ into the profile dir and set toolkit.legacyUserProfileCustomizations.stylesheets',
            when='post', interactive=True,
        ),
    ),
)
