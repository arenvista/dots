from __future__ import annotations

from pathlib import Path

from textual.app import ComposeResult
from textual.containers import Vertical
from textual.widgets import Log, SelectionList, Static
from textual.widgets.selection_list import Selection

from ..stow import LINKED, PackageStatus, run_stow, scan
from .markers import marker
from .visual_select import VisualRange


class ComponentSymlinkTable(Vertical):
    """What stow has linked, and the controls to change it.

    Composed of a list of packages and a log of stow's own output; the screen
    drives it by calling `move`, `act` and `reload`.
    """

    DEFAULT_CSS = """
    ComponentSymlinkTable { height: 1fr; }
    ComponentSymlinkTable > SelectionList {
        height: 2fr;
        border: round $accent;
        border-title-color: $accent;
        background: ansi_default;
        padding: 0 1;
    }
    ComponentSymlinkTable > SelectionList:focus { border: round $accent; }
    ComponentSymlinkTable SelectionList > .selection-list--button {
        color: ansi_black;
        background: ansi_default;
        text-style: dim;
    }
    ComponentSymlinkTable SelectionList > .selection-list--button-highlighted {
        color: ansi_black;
        background: ansi_default;
        text-style: dim;
    }
    ComponentSymlinkTable SelectionList > .selection-list--button-selected {
        color: ansi_green;
        background: ansi_default;
        text-style: bold;
    }
    ComponentSymlinkTable SelectionList > .selection-list--button-selected-highlighted {
        color: ansi_green;
        background: ansi_default;
        text-style: bold;
    }
    ComponentSymlinkTable > Log {
        height: 1fr;
        margin-top: 1;
        border: round $accent;
        border-title-color: $accent;
        background: ansi_default;
        padding: 0 1;
    }
    ComponentSymlinkTable > .sl-note { height: auto; margin-top: 1; }
    """

    def __init__(self, stow_dir: Path, target: Path, **kwargs) -> None:
        super().__init__(**kwargs)
        self.stow_dir = stow_dir
        self.target = target
        self.rows: tuple[PackageStatus, ...] = ()
        self.visual = VisualRange(self)

    def compose(self) -> ComposeResult:
        listing = SelectionList()
        listing.border_title = f"packages in {self.stow_dir.name}/"
        yield listing
        log = Log()
        log.border_title = "stow output"
        yield log
        yield Static("", classes="sl-note")

    def on_mount(self) -> None:
        self.reload()
        self.query_one(SelectionList).focus()

    # -- data -----------------------------------------------------------------

    def _label(self, row: PackageStatus, selected: bool, in_range: bool = False) -> str:
        """The circle is *selection*; link state lives in the text."""
        detail = f"{row.state:9} {row.summary}"
        if row.conflicts:
            detail += f"  ({', '.join(row.conflicts[:2])})"
        text = f"{marker(selected)} {row.name:14} {detail}"
        return f"[reverse]{text}[/reverse]" if in_range else text

    def reload(self) -> None:
        """Rescan link state, keeping whatever the user has selected."""
        self.rows = scan(self.stow_dir, self.target)
        self.repaint_rows()

    def repaint_rows(self) -> None:
        listing = self.query_one(SelectionList)
        highlighted = listing.highlighted
        selected = set(listing.selected)
        span = set(self.visual.rows)
        with listing.prevent(SelectionList.SelectedChanged):
            listing.clear_options()
            listing.add_options(
                [
                    Selection(
                        self._label(r, r.name in selected, index in span),
                        r.name,
                        r.name in selected,
                    )
                    for index, r in enumerate(self.rows)
                ]
            )
        if self.rows:
            listing.highlighted = min(highlighted or 0, len(self.rows) - 1)
        counts = {}
        for row in self.rows:
            counts[row.state] = counts.get(row.state, 0) + 1
        self.query_one(".sl-note", Static).update(
            "  ".join(f"{state}: {n}" for state, n in sorted(counts.items()))
            or "no packages found"
        )

    @property
    def current(self) -> PackageStatus | None:
        listing = self.query_one(SelectionList)
        if listing.highlighted is None or not self.rows:
            return None
        return self.rows[listing.highlighted]

    # -- actions --------------------------------------------------------------

    def on_selection_list_selected_changed(self) -> None:
        self.repaint_rows()

    @property
    def listing(self) -> SelectionList:
        return self.query_one(SelectionList)

    @property
    def row_ids(self) -> tuple[str, ...]:
        return tuple(r.name for r in self.rows)

    @property
    def targets(self) -> tuple[str, ...]:
        """Selected packages, or the row under the cursor when none are."""
        chosen = tuple(r.name for r in self.rows if r.name in set(self.listing.selected))
        if chosen:
            return chosen
        row = self.current
        return (row.name,) if row is not None else ()

    def move(self, step: int) -> None:
        listing = self.query_one(SelectionList)
        if step > 0:
            listing.action_cursor_down()
        else:
            listing.action_cursor_up()
        self.visual.moved()

    def act(self, action: str) -> None:
        """Run `action` over every selected package (or the cursor row)."""
        packages = self.targets
        if packages:
            self.run_worker(self._act_many(action, packages), exclusive=True)

    async def _act_many(self, action: str, packages: tuple[str, ...]) -> None:
        for package in packages:
            await self._act(action, package)

    async def _act(self, action: str, package: str) -> None:
        log = self.query_one(Log)
        log.write_line(f"==> stow {action} {package}")
        code, lines = await run_stow(action, self.stow_dir, self.target, package)
        for line in lines:
            log.write_line(line)
        log.write_line(f"    exit {code}")
        self.rows = scan(self.stow_dir, self.target)
        self.repaint_rows()
