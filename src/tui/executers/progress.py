from __future__ import annotations

from typing import Any

from textual.widgets import Static
from tqdm import tqdm


class _WidgetSink:
    """File-like object that hands tqdm's rendered bar to a widget."""

    encoding = "utf-8"  # tqdm falls back to ASCII bars without this

    def __init__(self, widget: TqdmProgress) -> None:
        self._widget = widget

    def write(self, text: str) -> None:
        # tqdm redraws by rewinding with \r; keep only the drawn bar itself.
        line = text.strip("\r\n")
        if line:
            self._widget.update(line)

    def flush(self) -> None:
        pass


class TqdmProgress(Static):
    """A real tqdm bar, rendered into the TUI instead of the terminal.

    Standalone: give it a total and call `start()` / `advance()` / `close()`.
    With no total it still counts, it just cannot show a percentage.
    """

    DEFAULT_CSS = """
    TqdmProgress {
        height: auto;
        color: $accent;
        background: ansi_default;
    }
    """

    BAR_FORMAT = "{desc} {percentage:3.0f}%|{bar}| {n_fmt}/{total_fmt}"
    # tqdm cannot draw a bar without a total; count instead until we learn one.
    COUNT_FORMAT = "{desc} {n_fmt} [{elapsed}]"

    def __init__(
        self,
        *,
        total: int | None = None,
        desc: str = "",
        ncols: int | None = None,
        **kwargs: Any,
    ) -> None:
        super().__init__("", **kwargs)
        self._total = total
        self._desc = desc
        self._ncols = ncols
        self._bar: tqdm | None = None

    @property
    def _bar_width(self) -> int:
        """Measured, so a scrollbar or a narrow panel cannot wrap the bar."""
        if self._ncols is not None:
            return self._ncols
        return max(12, self.content_size.width or 30)

    def start(self) -> None:
        self._bar = tqdm(
            total=self._total,
            desc=self._desc,
            file=_WidgetSink(self),
            bar_format=(
                self.BAR_FORMAT if self._total is not None else self.COUNT_FORMAT
            ),
            ncols=self._bar_width,
            dynamic_ncols=False,
            ascii=False,
            mininterval=0.0,  # a TUI redraw is cheap; never skip a frame
            leave=True,
        )

    def set_total(self, total: int) -> None:
        """Learn the total mid-run, switching from counter to percentage."""
        self._total = total
        if self._bar is not None:
            self._bar.total = total
            self._bar.bar_format = self.BAR_FORMAT
            self._bar.refresh()

    def advance(self, n: int = 1) -> None:
        if self._bar is not None:
            self._bar.update(n)

    def close(self) -> None:
        if self._bar is not None:
            self._bar.close()
            self._bar = None
