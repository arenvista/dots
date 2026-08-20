"""shell.tmux — tmux with tpm plugins, vim-aware pane nav, fzf session picker"""

from __future__ import annotations

from .setup import FeatureSetup, SetupStep

SETUP = FeatureSetup(
    feature_id="shell.tmux",
    steps=(
        SetupStep(
            'clone tpm',
            'test -d "$HOME/.tmux/plugins/tpm" || git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"',
            when='post',
        ),
        SetupStep(
            'tpm plugin install',
            'prefix + I inside tmux, once tmux is running',
            when='post', interactive=True,
        ),
    ),
)
