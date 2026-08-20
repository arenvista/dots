"""editor.neovim-ai — CodeCompanion over ACP + Copilot"""

from __future__ import annotations

from .setup import FeatureSetup, SetupStep

SETUP = FeatureSetup(
    feature_id="editor.neovim-ai",
    steps=(
        # claude setup-token (no ANTHROPIC_API_KEY is read)
        # SetupStep('label', 'bash command here'),
        # :Copilot auth — needs a GitHub Copilot subscription
        # SetupStep('label', 'bash command here'),
    ),
)
