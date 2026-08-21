"""The inverse of a Plan: what removing a set of features implies.

Install starts from a wish list. Prune starts from the machine: `detect` walks
every feature in deps.toml and reports which of them left something behind, the
user ticks the ones to remove, and `build_prune_plan` works out what can
actually go -- which is never simply "everything those features name", because
a package or a stow package can be claimed by more than one feature.

Two ways a ticked feature can come back empty, and both are reported rather
than silently dropped:

  blocked   a feature that is being kept `requires` it, so removing it would
            break the thing that stays. Protected, not pruned.
  shadowed  survived that, but every package, link and unit it owns is also
            claimed by a feature being kept. Nothing left to remove.

Kept pure: `MachineState` is a bag of frozensets, so a plan can be built and
read without a machine underneath it. The shelling out that fills one in lives
in `tui/machine.py`.
"""

from __future__ import annotations

import shlex
from dataclasses import dataclass

from ..features import get_setup
from .model import Deps, Feature
from .plan import Service
from .resolver import with_requires


@dataclass(frozen=True)
class MachineState:
    """What is installed, enabled and linked right now.

    Empty sets mean "nothing is here", which is why the functions below take
    `present=None` rather than a default instance to mean "do not filter".
    """

    packages: frozenset[str] = frozenset()
    services: frozenset[Service] = frozenset()
    stow_linked: frozenset[str] = frozenset()

    def has_package(self, name: str) -> bool:
        return name in self.packages

    def has_service(self, service: Service) -> bool:
        return service in self.services

    def has_stow(self, package: str) -> bool:
        return package in self.stow_linked


@dataclass(frozen=True)
class FeaturePresence:
    """One feature's footprint on this machine, as found."""

    feature: Feature
    packages: tuple[str, ...] = ()
    stow: tuple[str, ...] = ()
    services: tuple[Service, ...] = ()

    @property
    def found(self) -> bool:
        return bool(self.packages or self.stow or self.services)

    @property
    def summary(self) -> str:
        parts = []
        if self.packages:
            parts.append(f"{len(self.packages)} pkg")
        if self.stow:
            parts.append(f"{len(self.stow)} link")
        if self.services:
            parts.append(f"{len(self.services)} svc")
        return " · ".join(parts)


def detect(deps: Deps, state: MachineState) -> tuple[FeaturePresence, ...]:
    """Every feature that left something on this machine, in deps.toml order.

    A feature counts as present if *any* of its packages, stow packages or
    units are -- a half-installed feature is exactly what prune is for.
    """
    found = []
    for feature in deps.features.values():
        presence = FeaturePresence(
            feature=feature,
            packages=tuple(
                p for p in feature.pacman + feature.aur if state.has_package(p)
            ),
            stow=tuple(p for p in feature.stow if state.has_stow(p)),
            services=tuple(
                s
                for s in (Service.parse(raw) for raw in feature.services)
                if state.has_service(s)
            ),
        )
        if presence.found:
            found.append(presence)
    return tuple(found)


@dataclass(frozen=True)
class PrunePlan:
    """Everything the ticked features can actually give up."""

    features: tuple[Feature, ...] = ()
    pacman: tuple[str, ...] = ()
    aur: tuple[str, ...] = ()
    stow: tuple[str, ...] = ()
    services: tuple[Service, ...] = ()
    # ticked but not pruned, with the reason -- see the module docstring
    blocked: tuple[tuple[str, tuple[str, ...]], ...] = ()
    shadowed: tuple[str, ...] = ()
    # setup steps and manual notes have no inverse -- listed, never run
    leftovers: tuple[tuple[str, str], ...] = ()
    stow_dir: str = "configs"
    target: str = "~"

    @property
    def steps(self) -> int:
        """Number of ticked steps the script will report."""
        count = len(self.stow) + len(self.services)
        if self.pacman:
            count += 1
        if self.aur:
            count += 1
        return count

    @property
    def empty(self) -> bool:
        return not self.steps


def build_prune_plan(
    deps: Deps,
    drop_ids: tuple[str, ...],
    *,
    present: MachineState | None = None,
    stow_dir: str | None = None,
) -> PrunePlan:
    """What can be removed if `drop_ids` go and everything else stays.

    Everything not ticked is kept, and kept features are pulled through
    `with_requires` -- so a ticked feature that something kept depends on is
    protected rather than removed, and says why.

    `present=None` skips the "is it actually here?" filter, which is what tests
    want and what a caller with no machine to inspect gets.
    """
    drop = {i for i in drop_ids if i in deps.features}
    keep = {i for i in deps.ids if i not in drop}
    protected = set(with_requires(keep, deps))

    blocked = tuple(
        (
            feature_id,
            tuple(k for k in deps.ids if k in protected and feature_id in deps[k].requires),
        )
        for feature_id in deps.ids
        if feature_id in drop and feature_id in protected
    )
    dropping = tuple(deps[i] for i in deps.ids if i in drop and i not in protected)
    kept = tuple(deps[i] for i in deps.ids if i in protected)

    def owned(attr: str) -> set[str]:
        return {item for feature in kept for item in getattr(feature, attr)}

    keep_pacman = owned("pacman")
    keep_aur = owned("aur")
    keep_stow = owned("stow")
    keep_services = {Service.parse(s) for s in owned("services")}

    has_package = (lambda _: True) if present is None else present.has_package
    has_service = (lambda _: True) if present is None else present.has_service
    has_stow = (lambda _: True) if present is None else present.has_stow

    # dicts, not sets: two dropped features can name the same package, and the
    # order deps.toml lists them in is the order the summary should show
    pacman: dict[str, None] = {}
    aur: dict[str, None] = {}
    stow: dict[str, None] = {}
    services: dict[Service, None] = {}
    contributors: list[Feature] = []
    shadowed: list[str] = []

    for feature in dropping:
        mine_pacman = [p for p in feature.pacman if p not in keep_pacman and has_package(p)]
        mine_aur = [p for p in feature.aur if p not in keep_aur and has_package(p)]
        mine_stow = [p for p in feature.stow if p not in keep_stow and has_stow(p)]
        mine_services = [
            s
            for s in (Service.parse(raw) for raw in feature.services)
            if s not in keep_services and has_service(s)
        ]
        if not (mine_pacman or mine_aur or mine_stow or mine_services):
            shadowed.append(feature.id)
            continue
        contributors.append(feature)
        for item in mine_pacman:
            pacman.setdefault(item, None)
        for item in mine_aur:
            aur.setdefault(item, None)
        for item in mine_stow:
            stow.setdefault(item, None)
        for service in mine_services:
            services.setdefault(service, None)

    leftovers: list[tuple[str, str]] = []
    for feature in contributors:
        for step in get_setup(feature.id).steps:
            leftovers.append((feature.id, f"{step.label} — ran at install, not undone"))
        for note in feature.manual:
            leftovers.append((feature.id, note))

    return PrunePlan(
        features=tuple(contributors),
        pacman=tuple(pacman),
        aur=tuple(aur),
        stow=tuple(stow),
        services=tuple(services),
        blocked=blocked,
        shadowed=tuple(shadowed),
        leftovers=tuple(leftovers),
        stow_dir=stow_dir or deps.meta.stow_dir,
        target=deps.meta.target,
    )


def to_prune_bash(plan: PrunePlan) -> str:
    """Render the prune plan as a script -- the thing the user confirms and runs.

    The reverse of an install, in reverse order: services off, then links out,
    then packages. Removal is `pacman -Rn`, never `-Rns`: `-s` would take
    orphaned dependencies with it, and the confirm screen never showed those.
    AUR packages are ordinary local packages once installed, so pacman removes
    them too -- no helper is needed to undo what yay did.

    Every command goes through `run`, which prints it before running it, so the
    log shows what was attempted and not merely what it said.
    """
    q = shlex.quote
    # quoting $HOME would defeat it, so expand the tilde into a bash string
    target = (
        f'"$HOME{plan.target[1:]}"' if plan.target.startswith("~") else q(plan.target)
    )
    lines = [
        "#!/bin/bash",
        "# Generated by the manager. Removes what the pruned features own.",
        "set -uo pipefail",
        "",
        f'echo "::total {plan.steps}"',
        "",
        "fail=0",
        'note() { printf "%s\\n" "$*"; }',
        "# echo the command, then run it: $? afterwards is still the command's",
        'run() { printf "$ %s\\n" "$*"; "$@"; }',
        "",
    ]

    needs_root = plan.pacman or plan.aur or any(not s.user for s in plan.services)
    if needs_root:
        lines += [
            'if ! sudo -n true 2>/dev/null; then',
            '  note "!! sudo has no cached credentials -- run: sudo -v"',
            '  exit 1',
            'fi',
            "",
        ]

    for service in plan.services:
        scope = "--user " if service.user else ""
        sudo = "sudo " if not service.user else ""
        lines += [
            f'echo "::tick disable {service.unit}"',
            f"run {sudo}systemctl {scope}disable --now {q(service.unit)}",
            '[ $? -ne 0 ] && { fail=1; note "!! disable failed: ' + service.unit + '"; }',
            "",
        ]

    for package in plan.stow:
        lines += [
            f'echo "::tick unstow {package}"',
            f"run stow -d {q(plan.stow_dir)} -t {target} -D {q(package)}",
            '[ $? -ne 0 ] && { fail=1; note "!! unstow failed: ' + package + '"; }',
            "",
        ]

    # One batched call per section, like the install script: pacman -R is
    # atomic, so a package something else still depends on fails the batch
    # rather than half-removing it. The error in the log is the honest answer.
    for label, packages in (("aur", plan.aur), ("pacman", plan.pacman)):
        if not packages:
            continue
        names = " ".join(q(p) for p in packages)
        lines += [
            f'echo "::tick remove {label} ({len(packages)} packages)"',
            f"run sudo pacman -Rn --noconfirm --noprogressbar --color never {names}",
            f'[ $? -ne 0 ] && {{ fail=1; note "!! {label} removal failed"; }}',
            "",
        ]

    if plan.leftovers:
        lines += ['note ""', 'note "-- left behind, remove by hand if you want it gone --"']
        lines += [f'note "  {feature_id}: {text}"' for feature_id, text in plan.leftovers]
        lines.append("")

    lines += [
        'orphans=$(pacman -Qtdq 2>/dev/null)',
        'if [ -n "$orphans" ]; then',
        '  note ""',
        # single-quoted in bash: the $() here is advice to read, not to run
        """  note '-- now orphaned; clear with: sudo pacman -Rns $(pacman -Qtdq) --'""",
        '  note "$orphans" | tr "\\n" " " | fold -s -w 76 | sed "s/^/  /"',
        "fi",
        "",
        'exit "$fail"',
        "",
    ]
    return "\n".join(lines)
