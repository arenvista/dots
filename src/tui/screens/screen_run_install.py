from __future__ import annotations

from pathlib import Path

from textual.app import ComposeResult
from textual.binding import Binding
from textual.screen import Screen
from textual.widgets import Footer

from ..executers import ComponentExecShellScript


class ScreenRunInstall(Screen):
    """Step 3: run the generated script, reusing the shell-script component.

    Prune generates a script in the same shape, so the titles are arguments --
    the runner itself does not care which direction the script goes in.
    """

    BINDINGS = [
        ("escape", "app.pop_screen", "back"),
        # the output pane scrolls itself while the script runs; g/G is how you
        # get back to the top of a long run, and back to following it
        Binding("g", "edge(False)", "top"),
        Binding("G", "edge(True)", "bottom"),
    ]

    def __init__(
        self,
        script: Path,
        cwd: Path,
        steps: int,
        *,
        panel_title: str = "installing",
        output_title: str = "pacman / stow / systemctl",
        log_path: Path | None = None,
    ) -> None:
        super().__init__()
        self.script = script
        self.cwd = cwd
        self.steps = steps
        self.panel_title = panel_title
        self.output_title = output_title
        self.log_path = log_path

    def action_edge(self, last: bool) -> None:
        self.query_one(ComponentExecShellScript).jump_output(last=last)

    def compose(self) -> ComposeResult:
        yield ComponentExecShellScript(
            self.script.name,
            cwd=self.cwd,
            total=self.steps,
            panel_title=self.panel_title,
            output_title=self.output_title,
            log_path=self.log_path,
        )
        yield Footer()
