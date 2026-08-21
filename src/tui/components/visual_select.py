"""Vim-style visual range over a SelectionList.

Held by a widget rather than inherited from: the owner supplies `listing`
(the SelectionList), `row_ids` (values in display order) and `repaint_rows()`,
and gets a visual mode in return.
"""

from __future__ import annotations

from typing import Protocol

from textual.widgets import SelectionList


class VisualOwner(Protocol):
    @property
    def listing(self) -> SelectionList: ...
    @property
    def row_ids(self) -> tuple[str, ...]: ...
    def repaint_rows(self) -> None: ...
    visual: VisualRange


class VisualRange:
    def __init__(self, owner: VisualOwner) -> None:
        self.owner = owner
        self.anchor: int | None = None

    @property
    def active(self) -> bool:
        return self.anchor is not None

    @property
    def rows(self) -> range:
        """Inclusive span between the anchor and the cursor."""
        if self.anchor is None:
            return range(0)
        cursor = self.owner.listing.highlighted or 0
        low, high = sorted((self.anchor, cursor))
        return range(low, high + 1)

    def start(self) -> None:
        self.anchor = self.owner.listing.highlighted or 0
        self.owner.repaint_rows()

    def cancel(self) -> None:
        self.anchor = None
        self.owner.repaint_rows()

    def toggle(self) -> None:
        self.cancel() if self.active else self.start()

    def apply(self) -> None:
        """Set the whole span to the opposite of the anchor row's state.

        Flipping every row individually would scramble a mixed selection;
        following the anchor makes one keypress predictable.
        """
        listing = self.owner.listing
        if self.anchor is None:
            return
        span = list(self.rows)
        ids = self.owner.row_ids
        turn_on = ids[self.anchor] not in set(listing.selected)
        with listing.prevent(SelectionList.SelectedChanged):
            for index in span:
                if turn_on:
                    listing.select(ids[index])
                else:
                    listing.deselect(ids[index])
        self.anchor = None
        self.owner.repaint_rows()

    def toggle_current(self) -> None:
        listing = self.owner.listing
        if listing.highlighted is not None:
            listing.toggle(self.owner.row_ids[listing.highlighted])

    def moved(self) -> None:
        """Call after the cursor moves so the span redraws."""
        if self.active:
            self.owner.repaint_rows()


def jump(owner: VisualOwner, *, last: bool) -> None:
    """vim's g and G: the cursor to the first or last row.

    A free function rather than a method on each list, because every list in
    this app already satisfies `VisualOwner` and the jump is the same three
    lines each time. It goes through `visual.moved()` for the same reason j/k
    do: with a visual span open, landing on the last row must stretch the span
    to it, not leave the highlight behind.
    """
    listing = owner.listing
    if not listing.option_count:
        return
    listing.focus()
    listing.highlighted = listing.option_count - 1 if last else 0
    owner.visual.moved()
