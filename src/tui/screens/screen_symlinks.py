from __future__ import annotations

from pathlib import Path

from textual.app import ComposeResult
from textual.binding import Binding
from textual.screen import Screen
from textual.widgets import Footer, Static

from ..components.symlink_table import ComponentSymlinkTable
from ..deps import load_deps


class ScreenSymlinks(Screen):
    """See what stow has linked, and link/unlink/refresh it.

    The table component owns the scanning and the stow calls; this screen only
    supplies the paths and maps keys onto it.
    """

    DEFAULT_CSS = """
    ScreenSymlinks { padding: 1 2; }
    """

    BINDINGS = [
        Binding("escape", "back", "back"),
        Binding("v", "visual", "visual"),
        # space selects; SelectionList would otherwise claim it first
        Binding("space", "toggle", "toggle", priority=True),
        Binding("j", "move(+1)", "down"),
        Binding("k", "move(-1)", "up"),
        # g/G as in vim; hidden because the header line already spells them out
        Binding("g", "edge(False)", "top", show=False),
        Binding("G", "edge(True)", "bottom", show=False),
        Binding("l", "act('link')", "link"),
        Binding("u", "act('unlink')", "unlink"),
        Binding("r", "act('refresh')", "refresh"),
        # adopt MOVES the conflicting file in the target into the package
        # before linking, so it rewrites repo contents -- own key, no alias
        Binding("a", "act('adopt')", "adopt"),
        Binding("s", "reload", "rescan"),
    ]

    def __init__(self, root: Path) -> None:
        super().__init__()
        deps = load_deps(root / "deps.toml")
        self.stow_dir = root / deps.meta.stow_dir
        self.target = Path(deps.meta.target).expanduser()

    def compose(self) -> ComposeResult:
        yield Static(
            f"{self.stow_dir.name}/ → {self.target}   "
            "(j/k move · g/G ends · l link · u unlink · space select · v visual · "
            "r refresh · a adopt · s rescan)"
        )
        yield ComponentSymlinkTable(self.stow_dir, self.target)
        yield Footer()

    @property
    def table(self) -> ComponentSymlinkTable:
        return self.query_one(ComponentSymlinkTable)

    def action_back(self) -> None:
        if self.table.visual.active:
            self.table.visual.cancel()
        else:
            self.app.pop_screen()

    def action_visual(self) -> None:
        self.table.visual.toggle()

    def action_toggle(self) -> None:
        if self.table.visual.active:
            self.table.visual.apply()
        else:
            self.table.visual.toggle_current()

    def action_move(self, step: int) -> None:
        self.table.move(step)

    def action_edge(self, last: bool) -> None:
        self.table.jump_to_edge(last=last)

    def action_act(self, action: str) -> None:
        self.table.act(action)

    def action_reload(self) -> None:
        self.table.reload()
