from __future__ import annotations

from textual.app import ComposeResult
from textual.widgets import Static

from ..deps import PrunePlan
from .plan_summary import ComponentPlanSummary


class ComponentPrunePlanSummary(ComponentPlanSummary):
    """Read-only view of what a prune will remove, and what it will not.

    Subclasses the install summary for its `_section` helper and its CSS --
    Textual matches type selectors up the MRO, so `ComponentPlanSummary` rules
    style this too. Only the wording and the field names differ.

    "kept back" and "nothing left to remove" are as important as the removal
    lists: a ticked feature that produces no commands has a reason, and the
    user should read it here rather than count rows and wonder.
    """

    DEFAULT_CSS = """
    ComponentPrunePlanSummary .ps-warn { margin-top: 1; text-style: bold; color: ansi_yellow; }
    """

    def __init__(self, plan: PrunePlan, **kwargs) -> None:
        super().__init__(plan, **kwargs)  # type: ignore[arg-type]
        self.plan: PrunePlan = plan

    def compose(self) -> ComposeResult:
        plan = self.plan
        self.border_title = "confirm removal"
        yield Static(
            f"{len(plan.features)} features · {plan.steps} steps · "
            f"{len(plan.pacman)} pacman · {len(plan.aur)} aur · "
            f"{len(plan.stow)} unstow · {len(plan.services)} services"
        )
        yield from self._section("removing", [f.id for f in plan.features])
        yield from self._section("pacman -Rn", plan.pacman)
        yield from self._section("pacman -Rn (from the AUR)", plan.aur)
        yield from self._section("stow -D", plan.stow)
        yield from self._section(
            "systemctl disable --now",
            [f"{'--user ' if s.user else ''}{s.unit}" for s in plan.services],
        )
        if plan.blocked:
            yield Static("kept back — something you are keeping needs them", classes="ps-warn")
            yield Static(
                "  "
                + "\n  ".join(
                    f"{fid} ← required by {', '.join(by) or 'a kept feature'}"
                    for fid, by in plan.blocked
                )
            )
        if plan.shadowed:
            yield Static(
                "nothing left to remove — every part is shared with a kept feature",
                classes="ps-warn",
            )
            yield Static("  " + "\n  ".join(plan.shadowed))
        yield from self._section(
            "left behind", [f"{fid}: {text}" for fid, text in plan.leftovers]
        )
