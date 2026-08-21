from __future__ import annotations

from pathlib import Path

from textual.app import ComposeResult
from textual.binding import Binding
from textual.screen import Screen
from textual.widgets import Button, Footer, Static

from ..components import ComponentPruneSelect
from ..deps import detect, load_deps
from ..machine import read_machine
from .screen_confirm_prune import ScreenConfirmPrune


class ScreenPrune(Screen):
    """Step 1 of removal: what is on this machine, and which of it to drop.

    The mirror of the install selector, seeded from the machine instead of from
    a profile: every feature with a package, link or unit still present shows
    up, and nothing starts ticked. Reading profile.toml would be the wrong
    source here -- a feature can be installed and unlisted, or listed and never
    installed, and only the first kind is prunable.
    """

    DEFAULT_CSS = """
    ScreenPrune { padding: 1 2; }
    ScreenPrune > #prune-go {
        width: 100%;
        height: 3;
        margin-top: 1;
        border: round ansi_black;
        background: ansi_default;
        content-align: center middle;
    }
    ScreenPrune > #prune-go:focus {
        border: round ansi_red;
        color: ansi_red;
        text-style: bold;
    }
    ScreenPrune > .prune-note { margin-top: 1; }
    """

    BINDINGS = [
        Binding("escape", "back", "back"),
        Binding("v", "visual", "visual"),
        # in visual mode space applies the span; otherwise it toggles one row.
        # Claimed at screen level so SelectionList's own binding cannot win.
        Binding("space", "toggle", "toggle", priority=True),
        Binding("j", "down", "down"),
        Binding("k", "up", "up"),
        Binding("a", "all", "all"),
        Binding("n", "none", "none"),
        # g/G as in vim; hidden because the header line already spells them out
        Binding("g", "edge(False)", "top", show=False),
        Binding("G", "edge(True)", "bottom", show=False),
        Binding("enter", "review", "review", priority=True),
    ]

    def __init__(self, root: Path) -> None:
        super().__init__()
        self.root = root
        self.deps = load_deps(root / "deps.toml")
        # one scan, handed on to the confirm screen: a second one costs another
        # walk and could disagree with what the user just ticked
        self.state = read_machine(
            self.deps,
            root / self.deps.meta.stow_dir,
            Path(self.deps.meta.target).expanduser(),
        )
        self.found = detect(self.deps, self.state)

    def compose(self) -> ComposeResult:
        if not self.found:
            yield Static(
                "Nothing found to prune: none of the features in deps.toml has a "
                "package, link or unit still on this machine.",
                classes="prune-note",
            )
            yield Footer()
            return
        yield Static(
            f"{self.deps.meta.name} — {len(self.found)} features found on this machine"
            "   (j/k move · g/G ends · space ticks · v visual · a all · n none · enter reviews)",
            id="header",
        )
        yield ComponentPruneSelect(self.found)
        yield Button("review removal", id="prune-go")
        yield Footer()

    @property
    def picker(self) -> ComponentPruneSelect:
        return self.query_one(ComponentPruneSelect)

    # -- navigation -----------------------------------------------------------

    def action_down(self) -> None:
        if not self.found or self.focused is self.query_one("#prune-go", Button):
            return
        if self.picker.at_last_row:
            self.query_one("#prune-go", Button).focus()
        else:
            self.picker.move_cursor(+1)

    def action_up(self) -> None:
        if not self.found:
            return
        if self.focused is self.query_one("#prune-go", Button):
            self.picker.focus_last_row()
        else:
            self.picker.move_cursor(-1)

    def action_edge(self, last: bool) -> None:
        if self.found:
            self.picker.jump_to_edge(last=last)

    def action_back(self) -> None:
        if self.found and self.picker.visual_active:
            self.picker.cancel_visual()
        else:
            self.app.pop_screen()

    def action_visual(self) -> None:
        if not self.found:
            return
        if self.picker.visual_active:
            self.picker.cancel_visual()
        else:
            self.picker.start_visual()

    def action_toggle(self) -> None:
        if not self.found:
            return
        if self.picker.visual_active:
            self.picker.apply_visual()
        else:
            self.picker.toggle_current()

    def action_all(self) -> None:
        if self.found:
            self.picker.select_all()

    def action_none(self) -> None:
        if self.found:
            self.picker.select_none()

    def action_review(self) -> None:
        if self.found:
            self.picker.confirm()

    # -- events ---------------------------------------------------------------

    def on_button_pressed(self, event: Button.Pressed) -> None:
        if event.button.id == "prune-go":
            self.picker.confirm()

    def on_component_prune_select_confirmed(
        self, event: ComponentPruneSelect.Confirmed
    ) -> None:
        # nothing ticked is not a plan; say so rather than open an empty screen
        if not event.selected:
            self.picker.warn("Nothing ticked — space ticks a row, a ticks them all.")
            return
        self.app.push_screen(
            ScreenConfirmPrune(self.root, self.deps, event.selected, self.state)
        )
