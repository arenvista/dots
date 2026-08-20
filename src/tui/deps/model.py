from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class Feature:
    """One selectable unit from deps.toml."""

    id: str
    group: str
    name: str
    description: str = ""
    enabled: bool = False
    pacman: tuple[str, ...] = ()
    aur: tuple[str, ...] = ()
    stow: tuple[str, ...] = ()
    services: tuple[str, ...] = ()
    requires: tuple[str, ...] = ()
    manual: tuple[str, ...] = ()
    notes: str = ""


@dataclass(frozen=True)
class Meta:
    name: str = "dotfiles"
    target: str = "~"
    stow_dir: str = "configs"
    aur_helper: str = "yay"


@dataclass(frozen=True)
class Deps:
    meta: Meta
    profiles: dict[str, tuple[str, ...]]
    features: dict[str, Feature]

    def __getitem__(self, feature_id: str) -> Feature:
        return self.features[feature_id]

    @property
    def ids(self) -> tuple[str, ...]:
        return tuple(self.features)

    def groups(self) -> dict[str, list[Feature]]:
        """Features bucketed by group, preserving deps.toml order."""
        out: dict[str, list[Feature]] = {}
        for feature in self.features.values():
            out.setdefault(feature.group, []).append(feature)
        return out

    def profile_ids(self, profile: str) -> tuple[str, ...]:
        """Feature ids for a named profile; `["*"]` means every feature."""
        wanted = self.profiles.get(profile, ())
        if "*" in wanted:
            return self.ids
        return tuple(i for i in self.ids if i in set(wanted))

    def default_ids(self) -> tuple[str, ...]:
        return tuple(i for i, f in self.features.items() if f.enabled)
