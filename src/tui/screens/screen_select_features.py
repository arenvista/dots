from __future__ import annotations

from pathlib import Path

from textual.app import ComposeResult
from textual.binding import Binding
from textual.screen import Screen
from textual.widgets import Button, Footer, Static

from ..components import ComponentFeatureSelect
from ..deps import PROFILE_FILENAME, load_deps, read_profile, write_profile
from .screen_confirm_install import ScreenConfirmInstall


class ScreenSelectFeatures(Screen):
    """The one menu: descriptions visible, hjkl to get around, install at the end."""

    DEFAULT_CSS = """
    ScreenSelectFeatures { padding: 1 2; }
    ScreenSelectFeatures > #install {
        width: 100%;
        height: 3;
        margin-top: 1;
        border: round ansi_black;
        background: ansi_default;
        content-align: center middle;
    }
    ScreenSelectFeatures > #install:focus {
        border: round ansi_green;
        color: ansi_green;
        text-style: bold;
    }
    """

    BINDINGS = [
        Binding("escape", "back", "back"),
        Binding("v", "visual", "visual"),
        # in visual mode space applies the span; otherwise it toggles one row.
        # Claimed at screen level so SelectionList's own binding cannot win.
        Binding("space", "toggle", "toggle", priority=True),
        # j/k walk the rows and fall through to the install button at the end;
        # h/l swap the preset underneath the selection.
        Binding("j", "down", "down"),
        Binding("k", "up", "up"),
        Binding("h", "preset(-1)", "prev preset"),
        Binding("l", "preset(+1)", "next preset"),
        # g/G as in vim; hidden because the header line already spells them out
        Binding("g", "edge(False)", "top", show=False),
        Binding("G", "edge(True)", "bottom", show=False),
        # SelectionList binds enter to "toggle", which makes it a second
        # spacebar. Claim it here so space toggles and enter installs, from
        # anywhere on the screen -- not just when the button holds focus.
        Binding("enter", "install", "install", priority=True),
    ]

    def __init__(self, root: Path) -> None:
        super().__init__()
        self.root = root
        self.deps = load_deps(root / "deps.toml")
        self.profile_path = root / PROFILE_FILENAME

    def compose(self) -> ComposeResult:
        yield Static("", id="header")
        yield ComponentFeatureSelect(
            self.deps,
            # reopening picks up where the last run left off
            preselected=read_profile(self.profile_path) or self.deps.default_ids(),
        )
        yield Button("install", id="install")
        yield Footer()

    def on_mount(self) -> None:
        self._refresh_header()

    @property
    def picker(self) -> ComponentFeatureSelect:
        return self.query_one(ComponentFeatureSelect)

    def _refresh_header(self) -> None:
        self.query_one("#header", Static).update(
            f"{self.deps.meta.name} — preset: {self.picker.based_on}"
            + ("   -- VISUAL --" if self.picker.visual_active else "")
            + "   (h/l preset · j/k move · g/G ends · v visual · space toggles · enter installs)"
        )

    # -- navigation -----------------------------------------------------------

    def action_down(self) -> None:
        if self.focused is self.query_one("#install", Button):
            return
        if self.picker.at_last_row:
            self.query_one("#install", Button).focus()
        else:
            self.picker.move_cursor(+1)

    def action_up(self) -> None:
        if self.focused is self.query_one("#install", Button):
            self.picker.focus_last_row()
        else:
            self.picker.move_cursor(-1)

    def action_edge(self, last: bool) -> None:
        self.picker.jump_to_edge(last=last)
        self._refresh_header()

    def action_back(self) -> None:
        if self.picker.visual_active:
            self.picker.cancel_visual()
        else:
            self.app.pop_screen()

    def action_visual(self) -> None:
        if self.picker.visual_active:
            self.picker.cancel_visual()
        else:
            self.picker.start_visual()
        self._refresh_header()

    def action_toggle(self) -> None:
        if self.picker.visual_active:
            self.picker.apply_visual()
        else:
            self.picker.toggle_current()
        self._refresh_header()

    def action_install(self) -> None:
        self.picker.confirm()

    def action_preset(self, step: int) -> None:
        self.picker.cycle_preset(step)
        self._refresh_header()

    # -- events ---------------------------------------------------------------

    def on_selection_list_selected_changed(self) -> None:
        self._refresh_header()

    def on_button_pressed(self, event: Button.Pressed) -> None:
        if event.button.id == "install":
            self.picker.confirm()

    def on_component_feature_select_confirmed(
        self, event: ComponentFeatureSelect.Confirmed
    ) -> None:
        write_profile(self.profile_path, event.selected, based_on=event.based_on)
        self.app.push_screen(
            ScreenConfirmInstall(self.root, self.deps, event.selected, self.profile_path)
        )
