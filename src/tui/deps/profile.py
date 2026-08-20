from __future__ import annotations

from datetime import datetime
from pathlib import Path
from typing import Iterable

import tomllib

PROFILE_FILENAME = "profile.toml"


def _escape(text: str) -> str:
    return text.replace("\\", "\\\\").replace('"', '\\"')


def render_profile(
    feature_ids: Iterable[str],
    *,
    based_on: str = "custom",
    generated: datetime | None = None,
) -> str:
    """Serialise a selection as TOML.

    Hand-rolled because the stdlib reads TOML (tomllib) but cannot write it,
    and this shape is small enough not to justify a dependency.
    """
    stamp = (generated or datetime.now()).isoformat(timespec="seconds")
    lines = [
        "# Written by the feature selector. Edit by hand if you prefer;",
        "# it is read back the next time the selector opens.",
        "",
        "[profile]",
        f'based_on = "{_escape(based_on)}"',
        f'generated = "{stamp}"',
        "features = [",
    ]
    lines += [f'  "{_escape(i)}",' for i in feature_ids]
    lines += ["]", ""]
    return "\n".join(lines)


def write_profile(
    path: str | Path,
    feature_ids: Iterable[str],
    *,
    based_on: str = "custom",
) -> Path:
    target = Path(path)
    target.write_text(render_profile(feature_ids, based_on=based_on))
    return target


def read_profile(path: str | Path) -> tuple[str, ...]:
    """Feature ids from a written profile, or () when there is no file yet."""
    target = Path(path)
    if not target.exists():
        return ()
    raw = tomllib.loads(target.read_text())
    return tuple(raw.get("profile", {}).get("features", ()))
