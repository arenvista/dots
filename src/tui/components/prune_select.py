from __future__ import annotations

from dataclasses import dataclass

from textual.app import ComposeResult
from textual.containers import Vertical
from textual.message import Message
from textual.widgets import SelectionList, Static
from textual.widgets.selection_list import Selection

from ..deps import FeaturePresence

from .markers import marker
from .visual_select import VisualRange, jump


class ComponentPruneSelect(Vertical):
    """Pick which of the detected features to remove.

    A sibling of `ComponentFeatureSelect`, not a subclass, because the two
    differ in the one place that matters: that one posts `with_requires(chosen)`
    so ticking a feature also installs what it needs, while ticking something
    here must never quietly remove what it needs. This posts exactly the ticked
    ids and leaves the requires question to `build_prune_plan`, which protects
    rather than expands.

    Presets are gone for the same reason -- there is no such thing as a preset
    worth removing -- and nothing starts ticked. Removal is opt-in, row by row.
    """

    DEFAULT_CSS = """
    ComponentPruneSelect { height: 1fr; }
    ComponentPruneSelect > SelectionList {
        height: 1fr;
        border: round $accent;
        border-title-color: $accent;
        background: ansi_default;
        padding: 0 1;
    }
    ComponentPruneSelect > SelectionList:focus { border: round $accent; }
    ComponentPruneSelect > .prs-footnote { height: auto; margin-top: 1; }
    /* same reasoning as ComponentFeatureSelect: under an ansi theme the
       built-in button reads as "checked" when it is not, so force the states */
    ComponentPruneSelect SelectionList > .selection-list--button {
        color: ansi_black;
        background: ansi_default;
        text-style: dim;
    }
    ComponentPruneSelect SelectionList > .selection-list--button-highlighted {
        color: ansi_black;
        background: ansi_default;
        text-style: dim;
    }
    ComponentPruneSelect SelectionList > .selection-list--button-selected {
        color: ansi_red;
        background: ansi_default;
        text-style: bold;
    }
    ComponentPruneSelect SelectionList > .selection-list--button-selected-highlighted {
        color: ansi_red;
        background: ansi_default;
        text-style: bold;
    }
    """

    @dataclass
    class Confirmed(Message):
        """Exactly what was ticked -- no closure, forward or reverse."""

        selected: tuple[str, ...]

    def __init__(self, found: tuple[FeaturePresence, ...], **kwargs) -> None:
        super().__init__(**kwargs)
        self.found = found
        self.visual = VisualRange(self)
        self._warning: str | None = None

    # -- rows -----------------------------------------------------------------

    @property
    def row_ids(self) -> tuple[str, ...]:
        return tuple(p.feature.id for p in self.found)

    def _label(self, presence: FeaturePresence, selected: bool, in_range: bool = False) -> str:
        feature = presence.feature
        text = (
            f"{marker(selected)} {feature.group:9} {feature.name:20} "
            f"{presence.summary:22} {feature.description[:38]}"
        )
        # visual range is shown by inverting the row, the way vim does
        return f"[reverse]{text}[/reverse]" if in_range else text

    def compose(self) -> ComposeResult:
        listing = SelectionList(
            *(Selection(self._label(p, False), p.feature.id, False) for p in self.found)
        )
        listing.border_title = "found on this machine"
        yield listing
        yield Static("", classes="prs-footnote")

    def on_mount(self) -> None:
        self._refresh_footnote()
        self.query_one(SelectionList).focus()

    # -- selection bookkeeping ------------------------------------------------

    @property
    def listing(self) -> SelectionList:
        return self.query_one(SelectionList)

    @property
    def chosen(self) -> tuple[str, ...]:
        return tuple(self.listing.selected)

    @property
    def at_last_row(self) -> bool:
        listing = self.listing
        return listing.highlighted is not None and (
            listing.highlighted >= listing.option_count - 1
        )

    def move_cursor(self, step: int) -> None:
        if step > 0:
            self.listing.action_cursor_down()
        else:
            self.listing.action_cursor_up()
        self.visual.moved()

    def focus_last_row(self) -> None:
        jump(self, last=True)

    def jump_to_edge(self, *, last: bool) -> None:
        """g / G."""
        jump(self, last=last)

    def repaint_rows(self) -> None:
        listing = self.listing
        selected = set(listing.selected)
        highlighted = listing.highlighted
        span = set(self.visual.rows)
        with listing.prevent(SelectionList.SelectedChanged):
            listing.clear_options()
            listing.add_options(
                [
                    Selection(
                        self._label(p, p.feature.id in selected, index in span),
                        p.feature.id,
                        p.feature.id in selected,
                    )
                    for index, p in enumerate(self.found)
                ]
            )
        listing.highlighted = highlighted
        self._refresh_footnote()

    # -- vim-style visual mode ------------------------------------------------

    @property
    def visual_active(self) -> bool:
        return self.visual.active

    def start_visual(self) -> None:
        self.visual.start()

    def cancel_visual(self) -> None:
        self.visual.cancel()

    def apply_visual(self) -> None:
        self.visual.apply()

    def toggle_current(self) -> None:
        self.visual.toggle_current()

    def select_all(self) -> None:
        listing = self.listing
        with listing.prevent(SelectionList.SelectedChanged):
            listing.select_all()
        self.repaint_rows()

    def select_none(self) -> None:
        listing = self.listing
        with listing.prevent(SelectionList.SelectedChanged):
            listing.deselect_all()
        self.repaint_rows()

    def warn(self, text: str) -> None:
        """Say something in the footnote until the selection changes.

        The footnote rather than `App.notify`: every other list in this app
        answers in its own note line, and a toast has to find room over a
        full-height SelectionList to be seen at all.
        """
        self._warning = text
        self.query_one(".prs-footnote", Static).update(f"[bold]{text}[/bold]")

    def _refresh_footnote(self) -> None:
        if self._warning is not None:
            return
        chosen = self.chosen
        if not chosen:
            text = f"{len(self.found)} features found · none ticked for removal"
        else:
            text = f"{len(chosen)} of {len(self.found)} ticked for removal"
        self.query_one(".prs-footnote", Static).update(text)

    # -- events ---------------------------------------------------------------

    def on_selection_list_selected_changed(self) -> None:
        self._warning = None
        self.repaint_rows()

    def confirm(self) -> None:
        self.post_message(self.Confirmed(selected=self.chosen))
