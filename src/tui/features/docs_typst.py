"""docs.typst — typst compiler + tinymist LSP and live preview

typst-preview.nvim downloads its own tinymist on first run if absent.
"""

from __future__ import annotations

from .setup import FeatureSetup, SetupStep

SETUP = FeatureSetup(
    feature_id="docs.typst",
    steps=(
    ),
)
