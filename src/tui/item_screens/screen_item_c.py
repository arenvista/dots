from __future__ import annotations

from textual.app import ComposeResult
from textual.containers import Container
from textual.screen import Screen
from textual.widgets import Footer, Static


class Screen_Item_C(Screen):
    ITEM = "ITEM_C"

    BINDINGS = [("escape", "app.pop_screen", "back")]

    def compose(self) -> ComposeResult:
        with Container(id="box") as box:
            box.border_title = "hello"
            yield Static(f"unique actions from : {self.ITEM}")
        yield Footer()
