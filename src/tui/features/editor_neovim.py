"""editor.neovim — neovim ≥0.11 (lazy.nvim + mason), the config's required baseline

See configs/nvim/.config/nvim/DEPS.md for the per-plugin breakdown.
"""

from __future__ import annotations

from .setup import FeatureSetup, SetupStep

SETUP = FeatureSetup(
    feature_id="editor.neovim",
    steps=(
        SetupStep(
            'sync plugins',
            'nvim --headless "+Lazy! sync" +qa',
            when='post',
        ),
        SetupStep(
            'treesitter update',
            'nvim --headless "+TSUpdate" +qa',
            when='post',
        ),
        SetupStep(
            'checkhealth',
            ':checkhealth in a real nvim session',
            when='post', interactive=True,
        ),
    ),
)
