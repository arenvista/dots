from __future__ import annotations

from dataclasses import dataclass

from textual.app import ComposeResult
from textual.containers import Horizontal
from textual.message import Message
from textual.widgets import Button


class ComponentConfirmBar(Horizontal):
    """A yes/no bar. Posts a message; decides nothing itself."""

    DEFAULT_CSS = """
    ComponentConfirmBar { height: auto; margin-top: 1; }
    ComponentConfirmBar Button {
        min-width: 14;
        height: 1;
        border: none;
        background: ansi_default;
    }
    ComponentConfirmBar Button:focus { text-style: reverse; }
    """

    @dataclass
    class Answered(Message):
        confirmed: bool

    def __init__(self, *, confirm_label: str = "install", cancel_label: str = "back", **kwargs) -> None:
        super().__init__(**kwargs)
        self.confirm_label = confirm_label
        self.cancel_label = cancel_label

    def compose(self) -> ComposeResult:
        yield Button(self.confirm_label, id="confirm-yes")
        yield Button(self.cancel_label, id="confirm-no")

    def on_button_pressed(self, event: Button.Pressed) -> None:
        event.stop()
        self.post_message(self.Answered(event.button.id == "confirm-yes"))
