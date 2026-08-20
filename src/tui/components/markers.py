"""The selected/unselected glyph shared by every list in the app.

SelectionList's own toggle button cannot show two different characters: it
draws ToggleButton.BUTTON_INNER either way and signals state through colour
alone. A filled/unfilled pair therefore has to be written into the row label,
so the built-in button is blanked out here and the marker prepended instead.
"""

from __future__ import annotations

from textual.widgets._toggle_button import ToggleButton

MARKER_ON = "●"  # filled circle
MARKER_OFF = "○"  # empty circle

ToggleButton.BUTTON_LEFT = ""
ToggleButton.BUTTON_INNER = ""
ToggleButton.BUTTON_RIGHT = ""


def marker(selected: bool) -> str:
    return MARKER_ON if selected else MARKER_OFF
