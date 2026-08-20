from __future__ import annotations

from typing import ClassVar

from textual.app import ComposeResult
from textual.containers import Container
from textual.screen import Screen
from textual.widgets import Footer, Static


class ScreenHello(Screen):
    """What a component button opens. Subclasses only supply the item name."""

    ITEM: ClassVar[str] = ""

    BINDINGS = [("escape", "app.pop_screen", "back")]

    def compose(self) -> ComposeResult:
        with Container(id="box") as box:
            box.border_title = "hello"
            yield Static(f"hello from {self.ITEM}")
        yield Footer()


class ScreenHelloA(ScreenHello):
    ITEM = "ITEM_A"


class ScreenHelloB(ScreenHello):
    ITEM = "ITEM_B"


class ScreenHelloC(ScreenHello):
    ITEM = "ITEM_C"
