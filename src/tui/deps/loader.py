from __future__ import annotations

import tomllib
from pathlib import Path

from .model import Deps, Feature, Meta

DEPS_FILENAME = "deps.toml"


def _tuple(value: object) -> tuple[str, ...]:
    if not value:
        return ()
    if isinstance(value, str):
        return (value,)
    return tuple(str(item) for item in value)  # type: ignore[union-attr]


def load_deps(path: str | Path) -> Deps:
    """Parse deps.toml into the model. Unknown keys are ignored, not fatal."""
    raw = tomllib.loads(Path(path).read_text())

    meta_raw = raw.get("meta", {})
    meta = Meta(
        name=meta_raw.get("name", "dotfiles"),
        target=meta_raw.get("target", "~"),
        stow_dir=meta_raw.get("stow_dir", "configs"),
        aur_helper=meta_raw.get("aur_helper", "yay"),
    )

    features: dict[str, Feature] = {}
    for group, entries in raw.get("feature", {}).items():
        for name, body in entries.items():
            feature_id = f"{group}.{name}"
            features[feature_id] = Feature(
                id=feature_id,
                group=group,
                name=name,
                description=body.get("description", ""),
                enabled=bool(body.get("enabled", False)),
                pacman=_tuple(body.get("pacman")),
                aur=_tuple(body.get("aur")),
                stow=_tuple(body.get("stow")),
                services=_tuple(body.get("services")),
                requires=_tuple(body.get("requires")),
                manual=_tuple(body.get("manual")),
                notes=body.get("notes", ""),
            )

    profiles = {
        name: _tuple(ids) for name, ids in raw.get("profiles", {}).items()
    }
    return Deps(meta=meta, profiles=profiles, features=features)
