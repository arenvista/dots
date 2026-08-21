"""What this machine currently has installed, enabled and linked.

Only the subtraction step of a prune plan needs any of this, and it is the only
part that has to ask the system rather than read a file -- so it lives here
rather than in `deps/`, which stays readable without a machine underneath it.

Nothing here is a survey: each query names the packages, units and packages
deps.toml already knows about, so the cost is fixed and small. A missing tool
is not an error either -- an empty answer means "nothing of this kind is here",
which makes the plan smaller, never larger. For a script that removes things,
failing closed is the only safe direction.
"""

from __future__ import annotations

import subprocess
from pathlib import Path
from typing import Iterable

from .deps.model import Deps
from .deps.plan import Service
from .deps.prune import MachineState
from .stow import LINKED, PARTIAL, scan


def _run(*command: str) -> subprocess.CompletedProcess[str] | None:
    try:
        return subprocess.run(command, capture_output=True, text=True, timeout=30)
    except (OSError, subprocess.SubprocessError):
        return None


def installed_packages() -> frozenset[str]:
    """Explicitly installed packages.

    `-Qeq`, not `-Qq`: `pacman -S --needed` marks everything the install script
    pulls in as explicit, so this is exactly the set that script is responsible
    for -- and it leaves out packages that are only present as a dependency of
    something being kept.
    """
    done = _run("pacman", "-Qeq")
    if done is None or done.returncode != 0:
        return frozenset()
    return frozenset(line.strip() for line in done.stdout.splitlines() if line.strip())


def enabled_services(services: Iterable[Service]) -> frozenset[Service]:
    """Which of `services` systemd reports as enabled.

    `systemctl is-enabled a b c` answers one line per unit, in order, and exits
    nonzero as soon as any of them is not enabled -- the normal case here. So
    the exit code is ignored and the lines are read positionally; a short reply
    simply drops the tail, which shrinks the plan.

    Asking about named units rather than `list-unit-files --state=enabled` is
    not just narrower, it is ~200x faster: listing walks every unit file on the
    system, and that walk is long enough to look like a hang.
    """
    wanted = list(dict.fromkeys(services))
    found: set[Service] = set()
    for user in (False, True):
        batch = [s for s in wanted if s.user is user]
        if not batch:
            continue
        scope = ["--user"] if user else []
        done = _run("systemctl", *scope, "is-enabled", *(s.unit for s in batch))
        if done is None:
            continue
        # "enabled-runtime" counts: `systemctl disable` is still the way off
        found.update(
            service
            for service, state in zip(batch, done.stdout.splitlines())
            if state.strip().startswith("enabled")
        )
    return frozenset(found)


def linked_packages(stow_dir: Path, target: Path) -> frozenset[str]:
    """Stow packages with at least one live link in the target.

    `conflict` is deliberately excluded along with `unlinked`: those paths are
    held by something that is not ours, so unstowing them is not our call.
    """
    return frozenset(
        row.name for row in scan(stow_dir, target) if row.state in (LINKED, PARTIAL)
    )


def read_machine(deps: Deps, stow_dir: Path, target: Path) -> MachineState:
    candidates = (
        Service.parse(raw) for feature in deps.features.values() for raw in feature.services
    )
    return MachineState(
        packages=installed_packages(),
        services=enabled_services(candidates),
        stow_linked=linked_packages(stow_dir, target),
    )
