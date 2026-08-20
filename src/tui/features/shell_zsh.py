"""shell.zsh — zsh + oh-my-zsh + starship prompt, aliases, tmux/obsidian macros"""

from __future__ import annotations

from .setup import FeatureSetup, SetupStep

SETUP = FeatureSetup(
    feature_id="shell.zsh",
    steps=(
        # nvm (optional): the lazy-load block in .zshrc activates only if
        # ~/.nvm/nvm.sh exists
        # SetupStep('label', 'bash command here'),
        # ~/.secret_keys/openai.env is sourced if present; create it or ignore
        # SetupStep('label', 'bash command here'),
    ),
)
