"""editor.neovim-exec — sniprun / overseer — run code straight from the buffer"""

from __future__ import annotations

from .setup import FeatureSetup, SetupStep

SETUP = FeatureSetup(
    feature_id="editor.neovim-exec",
    steps=(
        # sniprun fetches a prebuilt binary on install; a local build needs
        # Rust ≥1.65
        # SetupStep('label', 'bash command here'),
    ),
)
