from __future__ import annotations

from dataclasses import dataclass

from textual.app import ComposeResult
from textual.containers import Vertical
from textual.message import Message
from textual.widgets import SelectionList, Static
from textual.widgets.selection_list import Selection

from ..deps import Deps, pulled_in, with_requires

from .markers import marker
from .visual_select import VisualRange, jump


class ComponentFeatureSelect(Vertical):
    """The manual checkbox menu: [x] on, [ ] off.

    Seeded from whatever ids it is handed, so a profile choice becomes the
    starting point rather than the final answer. Owns no install logic -- it
    posts `Confirmed` and lets whoever placed it decide what happens next.
    """

    DEFAULT_CSS = """
    ComponentFeatureSelect { height: 1fr; }
    ComponentFeatureSelect > SelectionList {
        height: 1fr;
        border: round $accent;
        border-title-color: $accent;
        background: ansi_default;
        padding: 0 1;
    }
    /* keep the frame identical when focused; the default swaps to a heavy border */
    ComponentFeatureSelect > SelectionList:focus {
        border: round $accent;
    }
    ComponentFeatureSelect > .fs-footnote { height: auto; margin-top: 1; }
    /* Under an ansi theme the unselected marker resolves to the terminal's
       default foreground -- a fully visible X that reads as "checked". Force
       the off state dark and dim, the on state bright and bold. */
    ComponentFeatureSelect SelectionList > .selection-list--button {
        color: ansi_black;
        background: ansi_default;
        text-style: dim;
    }
    ComponentFeatureSelect SelectionList > .selection-list--button-highlighted {
        color: ansi_black;
        background: ansi_default;
        text-style: dim;
    }
    ComponentFeatureSelect SelectionList > .selection-list--button-selected {
        color: ansi_green;
        background: ansi_default;
        text-style: bold;
    }
    ComponentFeatureSelect SelectionList > .selection-list--button-selected-highlighted {
        color: ansi_green;
        background: ansi_default;
        text-style: bold;
    }
    """

    @dataclass
    class Confirmed(Message):
        """Selection accepted, requirements already folded in."""

        selected: tuple[str, ...]
        implied: tuple[str, ...]
        based_on: str

    def __init__(self, deps: Deps, *, preselected: tuple[str, ...] = (), **kwargs) -> None:
        super().__init__(**kwargs)
        self.deps = deps
        self.preselected = set(preselected or deps.default_ids())
        self.based_on = "custom"
        self.visual = VisualRange(self)

    @property
    def _order(self) -> tuple[str, ...]:
        return self.deps.ids

    def _label(self, feature_id: str, selected: bool, in_range: bool = False) -> str:
        feature = self.deps[feature_id]
        text = (
            f"{marker(selected)} {feature.group:9} {feature.name:20} "
            f"{feature.description[:50]}"
        )
        # visual range is shown by inverting the row, the way vim does
        return f"[reverse]{text}[/reverse]" if in_range else text

    def _repaint_markers(self) -> None:
        """Rebuild the prompts so the marker matches the state."""
        listing = self.query_one(SelectionList)
        selected = set(listing.selected)
        highlighted = listing.highlighted
        rows = set(self.visual_rows())
        with listing.prevent(SelectionList.SelectedChanged):
            listing.clear_options()
            listing.add_options(
                [
                    Selection(
                        self._label(fid, fid in selected, index in rows), fid, fid in selected
                    )
                    for index, fid in enumerate(self._order)
                ]
            )
        listing.highlighted = highlighted

    def compose(self) -> ComposeResult:
        listing = SelectionList(
            *(
                Selection(self._label(fid, fid in self.preselected), fid, fid in self.preselected)
                for fid in self._order
            )
        )
        listing.border_title = "features"
        yield listing
        yield Static("", classes="fs-footnote")

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
    def preset_names(self) -> tuple[str, ...]:
        return tuple(self.deps.profiles)

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
        """Coming back up from the install button lands on the final row."""
        jump(self, last=True)

    def jump_to_edge(self, *, last: bool) -> None:
        """g / G."""
        jump(self, last=last)

    # -- vim-style visual mode (shared helper) --------------------------------

    @property
    def row_ids(self) -> tuple[str, ...]:
        return self._order

    def repaint_rows(self) -> None:
        self._repaint_markers()
        self._refresh_footnote()

    @property
    def visual_active(self) -> bool:
        return self.visual.active

    def visual_rows(self) -> range:
        return self.visual.rows

    def start_visual(self) -> None:
        self.visual.start()

    def cancel_visual(self) -> None:
        self.visual.cancel()

    def apply_visual(self) -> None:
        self.based_on = "custom"
        self.visual.apply()

    def toggle_current(self) -> None:
        self.visual.toggle_current()

    def apply_profile(self, profile: str) -> None:
        listing = self.listing
        wanted = set(self.deps.profile_ids(profile))
        # Without this the SelectedChanged messages queued by our own edits
        # arrive later and flip based_on back to "custom", so the next h/l
        # would restart from the beginning.
        with listing.prevent(SelectionList.SelectedChanged):
            listing.deselect_all()
            for feature_id in wanted:
                listing.select(feature_id)
        self._repaint_markers()
        self.based_on = profile
        self._refresh_footnote()

    def cycle_preset(self, step: int) -> None:
        """h/l walk the preset list, wrapping at both ends."""
        presets = self.preset_names
        if not presets:
            return
        try:
            index = presets.index(self.based_on)
        except ValueError:
            index = -1 if step > 0 else 0
        self.apply_profile(presets[(index + step) % len(presets)])

    def _refresh_footnote(self) -> None:
        chosen = set(self.chosen)
        implied = pulled_in(chosen, self.deps)
        text = f"{len(chosen)} selected"
        if implied:
            text += f"  ·  pulls in {len(implied)}: {', '.join(implied[:4])}"
            if len(implied) > 4:
                text += " …"
        self.query_one(".fs-footnote", Static).update(text)

    # -- events ---------------------------------------------------------------

    def on_selection_list_selected_changed(self) -> None:
        # a hand-toggle means the selection is no longer any named preset
        self.based_on = "custom"
        self._repaint_markers()
        self._refresh_footnote()

    def confirm(self) -> None:
        chosen = set(self.chosen)
        self.post_message(
            self.Confirmed(
                selected=with_requires(chosen, self.deps),
                implied=pulled_in(chosen, self.deps),
                based_on=self.based_on,
            )
        )
