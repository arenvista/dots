"""shell.zsh — zsh + oh-my-zsh + starship prompt, aliases, tmux macros"""

from __future__ import annotations

from .setup import FeatureSetup, SetupStep

SETUP = FeatureSetup(
    feature_id="shell.zsh",
    steps=(
        SetupStep(
            'clone oh-my-zsh',
            'test -d "$HOME/.oh-my-zsh" || git clone https://github.com/ohmyzsh/ohmyzsh.git "$HOME/.oh-my-zsh"',
            when='post',
        ),
        # nvm (optional): the lazy-load block in .zshrc activates only if
        # ~/.nvm/nvm.sh exists
        # SetupStep('label', 'bash command here'),
        # ~/.secret_keys/openai.env is sourced if present; create it or ignore
        # SetupStep('label', 'bash command here'),
    ),
)
