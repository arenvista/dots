from __future__ import annotations

from typing import ClassVar

from textual.screen import Screen
from textual.widgets import Button

from .item_screens import (
    Screen_Item_A,
    Screen_Item_B,
    Screen_Item_C,
    Screen_Item_D,
)


class ButtonItem(Button):
    """A component button that owns the screen it opens."""

    ITEM: ClassVar[str] = ""
    HELLO_SCREEN: ClassVar[type[Screen]]

    def __init__(self) -> None:
        super().__init__(self.ITEM, id=self.ITEM.lower())

    def on_button_pressed(self, event: Button.Pressed) -> None:
        self.app.push_screen(self.HELLO_SCREEN())


class ButtonItemA(ButtonItem):
    ITEM = "ITEM_A"
    HELLO_SCREEN = Screen_Item_A


class ButtonItemB(ButtonItem):
    ITEM = "ITEM_B"
    HELLO_SCREEN = Screen_Item_B


class ButtonItemC(ButtonItem):
    ITEM = "ITEM_C"
    HELLO_SCREEN = Screen_Item_C


class ButtonItemD(ButtonItem):
    ITEM = "ITEM_D"
    HELLO_SCREEN = Screen_Item_D
