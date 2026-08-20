from __future__ import annotations

from pathlib import Path

from textual.app import ComposeResult
from textual.screen import Screen
from textual.widgets import Footer

from ..executers import ComponentExecShellScript


class ScreenRunInstall(Screen):
    """Step 3: run the generated script, reusing the shell-script component."""

    BINDINGS = [("escape", "app.pop_screen", "back")]

    def __init__(self, script: Path, cwd: Path, steps: int) -> None:
        super().__init__()
        self.script = script
        self.cwd = cwd
        self.steps = steps

    def compose(self) -> ComposeResult:
        yield ComponentExecShellScript(
            self.script.name,
            cwd=self.cwd,
            total=self.steps,
            panel_title="installing",
            output_title="pacman / stow / systemctl",
        )
        yield Footer()
