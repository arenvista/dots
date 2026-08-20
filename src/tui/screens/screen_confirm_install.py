from __future__ import annotations

from pathlib import Path

from textual.app import ComposeResult
from textual.binding import Binding
from textual.screen import Screen
from textual.widgets import Button, Footer

from ..components import ComponentConfirmBar, ComponentPlanSummary
from ..deps import Deps, build_plan, to_bash
from .screen_run_install import ScreenRunInstall


class ScreenConfirmInstall(Screen):
    """Step 2: show exactly what will happen, then ask."""

    BINDINGS = [
        ("escape", "app.pop_screen", "back"),
        # the summary scrolls with j/k; enter installs from anywhere, so the
        # decision never depends on which widget happens to hold focus
        Binding("j", "scroll(+1)", "down"),
        Binding("k", "scroll(-1)", "up"),
        Binding("h", "app.focus_previous", "left", show=False),
        Binding("l", "app.focus_next", "right", show=False),
        Binding("enter", "confirm", "install", priority=True),
        Binding("i", "confirm", "install", show=False),
    ]

    DEFAULT_CSS = """
    ScreenConfirmInstall { padding: 1 2; }
    """

    def __init__(
        self, root: Path, deps: Deps, feature_ids: tuple[str, ...], profile_path: Path
    ) -> None:
        super().__init__()
        self.root = root
        self.deps = deps
        self.feature_ids = feature_ids
        self.profile_path = profile_path
        self.plan = build_plan(deps, feature_ids)

    def compose(self) -> ComposeResult:
        yield ComponentPlanSummary(
            self.plan, profile_path=str(self.profile_path.name)
        )
        yield ComponentConfirmBar(confirm_label="install", cancel_label="back")
        yield Footer()

    def on_mount(self) -> None:
        # land on "install" so enter means something the moment you arrive
        self.query_one("#confirm-yes", Button).focus()

    def action_scroll(self, step: int) -> None:
        summary = self.query_one(ComponentPlanSummary)
        summary.scroll_down() if step > 0 else summary.scroll_up()

    def action_confirm(self) -> None:
        script = self.root / ".manager-install.sh"
        script.write_text(to_bash(self.plan))
        script.chmod(0o755)
        self.app.push_screen(ScreenRunInstall(script, self.root, self.plan.steps))

    def on_component_confirm_bar_answered(
        self, event: ComponentConfirmBar.Answered
    ) -> None:
        if event.confirmed:
            self.action_confirm()
        else:
            self.app.pop_screen()
