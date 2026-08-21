from __future__ import annotations

from pathlib import Path

from textual.app import ComposeResult
from textual.binding import Binding
from textual.screen import Screen
from textual.widgets import Button, Footer, Static

from ..components import ComponentConfirmBar, ComponentPrunePlanSummary
from ..deps import Deps, MachineState, build_prune_plan, to_prune_bash
from .screen_run_install import ScreenRunInstall


class ScreenConfirmPrune(Screen):
    """Step 2 of removal: every command it will run, before it runs any.

    The same bargain the install confirm screen makes -- nothing happens that
    is not on this screen first -- which is why the plan uses `pacman -Rn` and
    not `-Rns`: `-s` would take orphaned dependencies nobody was shown.
    """

    BINDINGS = [
        ("escape", "app.pop_screen", "back"),
        Binding("j", "scroll(+1)", "down"),
        Binding("k", "scroll(-1)", "up"),
        Binding("g", "edge(False)", "top"),
        Binding("G", "edge(True)", "bottom"),
        Binding("h", "app.focus_previous", "left", show=False),
        Binding("l", "app.focus_next", "right", show=False),
        Binding("enter", "confirm", "prune", priority=True),
    ]

    DEFAULT_CSS = """
    ScreenConfirmPrune { padding: 1 2; }
    ScreenConfirmPrune > .prune-note { margin-top: 1; }
    """

    def __init__(
        self,
        root: Path,
        deps: Deps,
        drop_ids: tuple[str, ...],
        state: MachineState,
    ) -> None:
        super().__init__()
        self.root = root
        self.deps = deps
        self.plan = build_prune_plan(deps, drop_ids, present=state)

    def compose(self) -> ComposeResult:
        yield ComponentPrunePlanSummary(self.plan)
        if self.plan.empty:
            yield Static(
                "Nothing to run: see the reasons above.", classes="prune-note"
            )
        else:
            yield ComponentConfirmBar(confirm_label="prune", cancel_label="back")
        yield Footer()

    def on_mount(self) -> None:
        # land on "prune" so enter means something the moment you arrive
        button = self.query("#confirm-yes")
        if button:
            button.first(Button).focus()

    def action_scroll(self, step: int) -> None:
        summary = self.query_one(ComponentPrunePlanSummary)
        summary.scroll_down() if step > 0 else summary.scroll_up()

    def action_edge(self, last: bool) -> None:
        summary = self.query_one(ComponentPrunePlanSummary)
        summary.scroll_end(animate=False) if last else summary.scroll_home(animate=False)

    def action_confirm(self) -> None:
        if self.plan.empty:
            return
        script = self.root / ".manager-prune.sh"
        script.write_text(to_prune_bash(self.plan))
        script.chmod(0o755)
        self.app.push_screen(
            ScreenRunInstall(
                script,
                self.root,
                self.plan.steps,
                panel_title="pruning",
                output_title="systemctl / stow / pacman",
                log_path=self.root / ".manager-prune.log",
            )
        )

    def on_component_confirm_bar_answered(
        self, event: ComponentConfirmBar.Answered
    ) -> None:
        if event.confirmed:
            self.action_confirm()
        else:
            self.app.pop_screen()
