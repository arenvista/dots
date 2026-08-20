"""Per-feature setup modules.

One module per feature id (dots and dashes become underscores). Each defines a
module-level `SETUP = FeatureSetup(...)`; this package finds them by import, so
adding a feature means adding a file -- nothing here needs editing.
"""

from __future__ import annotations

import importlib
import pkgutil

from .setup import FeatureSetup, SetupStep

_SKIP = {"setup"}


def _discover() -> dict[str, FeatureSetup]:
    found: dict[str, FeatureSetup] = {}
    for module_info in pkgutil.iter_modules(__path__):
        if module_info.name.startswith("_") or module_info.name in _SKIP:
            continue
        module = importlib.import_module(f"{__name__}.{module_info.name}")
        setup = getattr(module, "SETUP", None)
        if isinstance(setup, FeatureSetup):
            found[setup.feature_id] = setup
    return found


SETUPS: dict[str, FeatureSetup] = _discover()


def get_setup(feature_id: str) -> FeatureSetup:
    return SETUPS.get(feature_id, FeatureSetup(feature_id=feature_id))


__all__ = ["FeatureSetup", "SetupStep", "SETUPS", "get_setup"]
