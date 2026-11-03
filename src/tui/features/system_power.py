"""system.power — TLP + throttled battery tuning; copies system/etc/ into /etc

stow only links into $HOME, so the root-owned files are installed here
instead. throttled.conf has Autoreload: True, but the restart makes a fresh
install take effect even before the service's first poll.
"""

from __future__ import annotations

from .setup import FeatureSetup, SetupStep

SETUP = FeatureSetup(
    feature_id="system.power",
    steps=(
        SetupStep(
            'mask systemd-rfkill (TLP owns radio state)',
            'sudo systemctl mask systemd-rfkill.service systemd-rfkill.socket',
            when='post',
        ),
        SetupStep(
            'TLP battery drop-in',
            'sudo install -Dm644 system/etc/tlp.d/10-battery.conf /etc/tlp.d/10-battery.conf && sudo tlp start',
            when='post',
        ),
        SetupStep(
            'throttled power limits',
            'sudo install -Dm644 system/etc/throttled.conf /etc/throttled.conf && sudo systemctl restart throttled',
            when='post',
        ),
    ),
)
