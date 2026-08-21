from __future__ import annotations

from pathlib import Path

from textual.app import ComposeResult
from textual.binding import Binding
from textual.screen import Screen
from textual.widgets import Footer

from ..executers import ComponentExecShellScript

# src/tui/item_screens/ -> repo root; the script is addressed relative to it so
# whatever the script does with relative paths lands where you'd expect.
REPO_ROOT = Path(__file__).resolve().parents[3]
SCRIPT = Path("data/sample_a/a_script.sh")


class Screen_Item_D(Screen):
    ITEM = "ITEM_D"

    BINDINGS = [
        ("escape", "app.pop_screen", "back"),
        Binding("g", "edge(False)", "top"),
        Binding("G", "edge(True)", "bottom"),
    ]

    def action_edge(self, last: bool) -> None:
        self.query_one(ComponentExecShellScript).jump_output(last=last)

    def compose(self) -> ComposeResult:
        yield ComponentExecShellScript(
            SCRIPT,
            cwd=REPO_ROOT,
            panel_title=self.ITEM,
        )
        yield Footer()
