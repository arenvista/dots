from __future__ import annotations

import shlex
from dataclasses import dataclass, field

from ..features import get_setup
from ..features.setup import SetupStep
from .model import Deps, Feature


@dataclass(frozen=True)
class Service:
    unit: str
    user: bool

    @classmethod
    def parse(cls, raw: str) -> Service:
        # deps.toml spells a user unit "--user <name>"
        parts = raw.split()
        if parts and parts[0] == "--user":
            return cls(" ".join(parts[1:]), True)
        return cls(raw.strip(), False)


@dataclass(frozen=True)
class Plan:
    """Everything a selection implies, before any of it runs."""

    features: tuple[Feature, ...]
    pacman: tuple[str, ...] = ()
    aur: tuple[str, ...] = ()
    stow: tuple[str, ...] = ()
    services: tuple[Service, ...] = ()
    pre: tuple[tuple[str, SetupStep], ...] = ()
    post: tuple[tuple[str, SetupStep], ...] = ()
    interactive: tuple[tuple[str, SetupStep], ...] = ()
    manual: tuple[tuple[str, str], ...] = ()
    stow_dir: str = "configs"
    target: str = "~"
    aur_helper: str = "yay"

    @property
    def steps(self) -> int:
        """Number of ticked steps the script will report."""
        count = len(self.pre) + len(self.post) + len(self.stow) + len(self.services)
        if self.pacman:
            count += 1
        if self.aur:
            count += 1
        return count


def build_plan(deps: Deps, feature_ids: tuple[str, ...], *, stow_dir: str | None = None) -> Plan:
    """Collect a selection into one plan, de-duplicated and ordered."""
    features = tuple(deps[i] for i in feature_ids if i in deps.features)

    def merge(attr: str) -> tuple[str, ...]:
        seen: dict[str, None] = {}
        for feature in features:
            for item in getattr(feature, attr):
                seen.setdefault(item, None)
        return tuple(seen)

    pre: list[tuple[str, SetupStep]] = []
    post: list[tuple[str, SetupStep]] = []
    interactive: list[tuple[str, SetupStep]] = []
    manual: list[tuple[str, str]] = []
    for feature in features:
        setup = get_setup(feature.id)
        pre += [(feature.id, s) for s in setup.when("pre")]
        post += [(feature.id, s) for s in setup.when("post")]
        interactive += [(feature.id, s) for s in setup.interactive]
        manual += [(feature.id, note) for note in feature.manual]

    return Plan(
        features=features,
        pacman=merge("pacman"),
        aur=merge("aur"),
        stow=merge("stow"),
        services=tuple(dict.fromkeys(Service.parse(s) for s in merge("services"))),
        pre=tuple(pre),
        post=tuple(post),
        interactive=tuple(interactive),
        manual=tuple(manual),
        stow_dir=stow_dir or deps.meta.stow_dir,
        target=deps.meta.target,
        aur_helper=deps.meta.aur_helper,
    )


def to_bash(plan: Plan) -> str:
    """Render the plan as a script -- the thing the user confirms and runs."""
    q = shlex.quote
    # quoting $HOME would defeat it, so expand the tilde into a bash string
    target = (
        f'"$HOME{plan.target[1:]}"' if plan.target.startswith("~") else q(plan.target)
    )
    lines = [
        "#!/bin/bash",
        "# Generated from profile.toml. Safe to read before it runs -- that is the point.",
        "set -uo pipefail",
        "",
        f'echo "::total {plan.steps}"',
        "",
        "fail=0",
        'note() { printf "%s\\n" "$*"; }',
        "",
    ]

    if plan.pacman or plan.services:
        lines += [
            'if ! sudo -n true 2>/dev/null; then',
            '  note "!! sudo has no cached credentials -- run: sudo -v"',
            '  exit 1',
            'fi',
            "",
        ]

    for feature_id, step in plan.pre:
        lines += [
            f'echo "::tick {feature_id}: {step.label}"',
            step.command,
            '[ $? -ne 0 ] && { fail=1; note "!! failed: ' + feature_id + '"; }',
            "",
        ]

    if plan.pacman:
        pkgs = " ".join(q(p) for p in plan.pacman)
        lines += [
            f'echo "::tick pacman ({len(plan.pacman)} packages)"',
            f"sudo pacman -S --needed --noconfirm --noprogressbar --color never {pkgs}",
            '[ $? -ne 0 ] && { fail=1; note "!! pacman failed"; }',
            "",
        ]

    if plan.aur:
        pkgs = " ".join(q(p) for p in plan.aur)
        helper = q(plan.aur_helper)
        lines += [
            f'echo "::tick aur ({len(plan.aur)} packages)"',
            f'if command -v {helper} >/dev/null; then',
            f"  {helper} -S --needed --noconfirm {pkgs}",
            'elif command -v paru >/dev/null; then',
            f"  paru -S --needed --noconfirm {pkgs}",
            "else",
            f'  note "!! no AUR helper ({plan.aur_helper} or paru); skipped: {" ".join(plan.aur)}"',
            "fi",
            "",
        ]

    for package in plan.stow:
        lines += [
            f'echo "::tick stow {package}"',
            f"stow -d {q(plan.stow_dir)} -t {target} --restow {q(package)}",
            '[ $? -ne 0 ] && { fail=1; note "!! stow failed: ' + package + '"; }',
            "",
        ]

    for service in plan.services:
        scope = "--user " if service.user else ""
        sudo = "" if service.user else "sudo "
        lines += [
            f'echo "::tick enable {service.unit}"',
            f"{sudo}systemctl {scope}enable --now {q(service.unit)}",
            '[ $? -ne 0 ] && { fail=1; note "!! service failed: ' + service.unit + '"; }',
            "",
        ]

    for feature_id, step in plan.post:
        lines += [
            f'echo "::tick {feature_id}: {step.label}"',
            step.command,
            '[ $? -ne 0 ] && { fail=1; note "!! failed: ' + feature_id + '"; }',
            "",
        ]

    if plan.interactive or plan.manual:
        lines += ['note ""', 'note "-- left for you to do by hand --"']
        for feature_id, step in plan.interactive:
            lines.append(f'note "  {feature_id}: {step.label} -- {step.command}"')
        for feature_id, note in plan.manual:
            lines.append(f'note "  {feature_id}: {note}"')
        lines.append("")

    lines += ['exit "$fail"', ""]
    return "\n".join(lines)
