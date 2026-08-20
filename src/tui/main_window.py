from __future__ import annotations

from textual.app import App

from .screen_components import ScreenComponents


class MainWindow(App):
    """Top level: owns the look and opens on the components screen."""

    CSS = """
    Screen {
        align: center middle;
        background: ansi_default;
    }
    #box {
        border: round $accent;
        border-title-color: $accent;
        background: ansi_default;
        padding: 1 2;
        width: 60;
        height: auto;
    }
    #box Horizontal {
        height: auto;
    }
    Button {
        background: ansi_default;
        border: none;
        height: 1;
        min-width: 12;
        text-style: none;
    }
    Button:hover     { background: ansi_default; text-style: bold; }
    Button.-active   { background: ansi_default; }
    Button:focus     { background: ansi_default; text-style: reverse; }
    """

    BINDINGS = [("q", "quit", "quit")]

    def on_mount(self) -> None:
        # Only an "ansi" theme emits the terminal's default-background escape;
        # CSS `transparent` just blends alpha over the parent's RGB.
        self.theme = "ansi-dark"
        self.push_screen(ScreenComponents())

    def get_css_variables(self) -> dict[str, str]:
        # Currently unreferenced: theme_gen emits rules using these names.
        variables = super().get_css_variables()
        variables.update(
            {
                "PLACEHOLDER-1": variables["primary"],
                "PLACEHOLDER-2": variables["secondary"],
                "PLACEHOLDER-3": variables["warning"],
            }
        )
        return variables
