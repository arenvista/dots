"""docs.latex — the TeX Live set this config compiles and formats against

latexindent and latexmk ship inside texlive-binextra.
"""

from __future__ import annotations

from .setup import FeatureSetup, SetupStep

SETUP = FeatureSetup(
    feature_id="docs.latex",
    steps=(
    ),
)
