from __future__ import annotations

from .model import Deps


def with_requires(selected: set[str], deps: Deps) -> tuple[str, ...]:
    """Selection plus everything it `requires`, in deps.toml order.

    Selecting a feature whose requirement is unselected is the common case
    (pick `desktop.waybar`, get `desktop.hyprland` too), so pull the closure in
    rather than refusing the selection.
    """
    wanted = set(selected)
    pending = list(selected)
    while pending:
        current = pending.pop()
        feature = deps.features.get(current)
        if feature is None:
            continue
        for required in feature.requires:
            if required not in wanted and required in deps.features:
                wanted.add(required)
                pending.append(required)
    return tuple(i for i in deps.ids if i in wanted)


def pulled_in(selected: set[str], deps: Deps) -> tuple[str, ...]:
    """What `with_requires` adds -- for telling the user before they confirm."""
    return tuple(i for i in with_requires(selected, deps) if i not in selected)


def unknown_requires(deps: Deps) -> dict[str, tuple[str, ...]]:
    """Requirements naming features that do not exist. A deps.toml typo check."""
    broken: dict[str, tuple[str, ...]] = {}
    for feature in deps.features.values():
        missing = tuple(r for r in feature.requires if r not in deps.features)
        if missing:
            broken[feature.id] = missing
    return broken
