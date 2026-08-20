from __future__ import annotations

from textual.app import ComposeResult
from textual.containers import Vertical, VerticalScroll
from textual.widgets import Static

from ..deps import Plan


class ComponentPlanSummary(VerticalScroll):
    """Read-only view of what a plan will do. No buttons, no logic."""

    DEFAULT_CSS = """
    ComponentPlanSummary {
        height: 1fr;
        border: round $accent;
        border-title-color: $accent;
        background: ansi_default;
        padding: 1 2;
    }
    ComponentPlanSummary .ps-heading { margin-top: 1; text-style: bold; }
    """

    def __init__(self, plan: Plan, *, profile_path: str = "", **kwargs) -> None:
        super().__init__(**kwargs)
        self.plan = plan
        self.profile_path = profile_path

    def compose(self) -> ComposeResult:
        plan = self.plan
        self.border_title = "confirm"
        if self.profile_path:
            yield Static(f"profile written to {self.profile_path}")
        yield Static(
            f"{len(plan.features)} features · {plan.steps} steps · "
            f"{len(plan.pacman)} pacman · {len(plan.aur)} aur · "
            f"{len(plan.stow)} stow · {len(plan.services)} services"
        )
        yield from self._section("features", [f.id for f in plan.features])
        yield from self._section("pacman", plan.pacman)
        yield from self._section("aur", plan.aur)
        yield from self._section("stow", plan.stow)
        yield from self._section(
            "services", [f"{'--user ' if s.user else ''}{s.unit}" for s in plan.services]
        )
        yield from self._section(
            "scripted steps", [f"{fid}: {s.label}" for fid, s in plan.pre + plan.post]
        )
        yield from self._section(
            "left to you",
            [f"{fid}: {s.label}" for fid, s in plan.interactive]
            + [f"{fid}: {note}" for fid, note in plan.manual],
        )

    def _section(self, title: str, items: list[str] | tuple[str, ...]) -> ComposeResult:
        if not items:
            return
        yield Static(title, classes="ps-heading")
        yield Static("  " + "\n  ".join(items))
