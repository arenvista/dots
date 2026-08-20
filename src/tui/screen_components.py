from __future__ import annotations

from pathlib import Path

from textual.app import ComposeResult
from textual.binding import Binding
from textual.containers import Container, Horizontal
from textual.screen import Screen
from textual.widgets import Button, Footer, Static

from .button_item import ButtonItemA, ButtonItemB, ButtonItemC, ButtonItemD
from .screens import ScreenSelectFeatures, ScreenSymlinks

REPO_ROOT = Path(__file__).resolve().parents[2]


class ScreenComponents(Screen):
    """The picker the main window opens with."""

    BINDINGS = [
        # hjkl, as the prompt below advertises; the row is horizontal, so
        # j/k are aliases for l/h rather than separate axes.
        Binding("l,j", "app.focus_next", "move", show=False),
        Binding("h,k", "app.focus_previous", "move", show=False),
    ]

    def compose(self) -> ComposeResult:
        with Container(id="box") as box:
            box.border_title = "components"
            yield Static("Pick what to install:  (hjkl to move, q to quit)\n")
            with Horizontal():
                yield Button("Install", id="features")
                yield Button("Symlink", id="symlink")
            yield Static("")
        yield Footer()

    def on_button_pressed(self, event: Button.Pressed) -> None:
        # ButtonItem subclasses handle their own press and let it bubble, so
        # only claim the one that belongs to this screen.
        if event.button.id == "features":
            self.app.push_screen(ScreenSelectFeatures(REPO_ROOT))
        if event.button.id == "symlink":
            self.app.push_screen(ScreenSymlinks(REPO_ROOT))
        if event.button.id == "prune":
            print("NOT IMPLEMENTED")
