"""Reading and changing stow's view of the world.

Status is computed by walking the package tree rather than shelling out, so
the table can be refreshed cheaply; only the link/unlink/restow actions run
`stow` itself.
"""

from __future__ import annotations

import asyncio
import re
from dataclasses import dataclass
from pathlib import Path

LINKED = "linked"
PARTIAL = "partial"
UNLINKED = "unlinked"
CONFLICT = "conflict"

MARKERS = {
    LINKED: "[x]",
    PARTIAL: "[~]",
    UNLINKED: "[ ]",
    CONFLICT: "[!]",
}


@dataclass(frozen=True)
class PackageStatus:
    name: str
    state: str
    linked: int
    total: int
    conflicts: tuple[str, ...] = ()

    @property
    def marker(self) -> str:
        return MARKERS.get(self.state, "[?]")

    @property
    def summary(self) -> str:
        return f"{self.linked}/{self.total} links"


def packages(stow_dir: Path) -> tuple[str, ...]:
    """Every stow package: the immediate subdirectories of the stow dir."""
    if not stow_dir.is_dir():
        return ()
    return tuple(
        sorted(p.name for p in stow_dir.iterdir() if p.is_dir() and not p.name.startswith("."))
    )


IGNORE_FILE = ".stow-local-ignore"


def _ignore_patterns(package_dir: Path) -> list[re.Pattern[str]]:
    """Regexes from the package's .stow-local-ignore, as stow reads them."""
    source = package_dir / IGNORE_FILE
    if not source.is_file():
        return []
    patterns = []
    for line in source.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        try:
            patterns.append(re.compile(line))
        except re.error:
            continue  # a bad line should not break the whole scan
    return patterns


def _is_ignored(relative: Path, patterns: list[re.Pattern[str]]) -> bool:
    if not patterns:
        return False
    # test the path and every ancestor: ignoring a directory ignores its tree
    candidates = ["/" + str(relative)]
    candidates += ["/" + str(parent) for parent in relative.parents if str(parent) != "."]
    return any(p.search(c) for p in patterns for c in candidates)


def _expected_links(package_dir: Path) -> list[Path]:
    """Paths inside the package that stow would create links for."""
    patterns = _ignore_patterns(package_dir)
    found = []
    for path in package_dir.rglob("*"):
        if not (path.is_file() or path.is_symlink()):
            continue
        relative = path.relative_to(package_dir)
        if relative.name == IGNORE_FILE or _is_ignored(relative, patterns):
            continue
        found.append(path)
    return found


def status(stow_dir: Path, target: Path, package: str) -> PackageStatus:
    """Compare what the package holds against what lives in the target."""
    package_dir = stow_dir / package
    sources = _expected_links(package_dir)
    linked = 0
    conflicts: list[str] = []
    for source in sources:
        relative = source.relative_to(package_dir)
        destination = target / relative
        if not destination.exists() and not destination.is_symlink():
            continue  # simply absent: stow has nothing to complain about
        # Resolve rather than test the leaf itself: stow folds trees, linking
        # the highest directory it can, so a linked file is often reached
        # THROUGH a symlinked parent and is not a symlink in its own right.
        try:
            same = destination.resolve() == source.resolve()
        except OSError:
            same = False
        if same:
            linked += 1
        else:
            # a real file (or a link elsewhere) sitting where ours belongs
            conflicts.append(str(relative))

    total = len(sources)
    if conflicts:
        state = CONFLICT
    elif total and linked == total:
        state = LINKED
    elif linked:
        state = PARTIAL
    else:
        state = UNLINKED
    return PackageStatus(package, state, linked, total, tuple(conflicts[:5]))


def scan(stow_dir: Path, target: Path) -> tuple[PackageStatus, ...]:
    return tuple(status(stow_dir, target, name) for name in packages(stow_dir))


async def run_stow(
    action: str, stow_dir: Path, target: Path, package: str
) -> tuple[int, list[str]]:
    """Run one stow action. Returns (exit code, output lines).

    `link` -> stow -S, `unlink` -> stow -D, `refresh` -> stow -R, and
    `adopt` -> stow --adopt -S, which MOVES a conflicting file out of the
    target and into the package before linking it. That rewrites the repo's
    contents, so it is deliberately a separate action.
    """
    flags = {
        "link": ["-S"],
        "unlink": ["-D"],
        "refresh": ["-R"],
        "adopt": ["--adopt", "-S"],
    }[action]
    process = await asyncio.create_subprocess_exec(
        "stow",
        *flags,
        "-v",
        "-d",
        str(stow_dir),
        "-t",
        str(target),
        package,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.STDOUT,
    )
    output, _ = await process.communicate()
    lines = [line for line in output.decode(errors="replace").splitlines() if line.strip()]
    return process.returncode or 0, lines
