from __future__ import annotations

from dataclasses import dataclass

from textual.app import ComposeResult
from textual.containers import Horizontal, Vertical
from textual.message import Message
from textual.widgets import Static

from ..deps import Deps, build_plan, with_requires


class ComponentProfilePicker(Vertical):
    """Step 1: pick a starting profile. h/l move, enter chooses.

    Posts `Chosen`; the screen decides what the next step is.
    """

    DEFAULT_CSS = """
    ComponentProfilePicker { height: auto; }
    ComponentProfilePicker > .pp-row { height: auto; margin-bottom: 1; }
    ComponentProfilePicker .pp-card {
        width: 18;
        height: 3;
        margin-right: 1;
        /* border eats 2 rows of a 3-row card; any vertical padding hides the
           label entirely */
        padding: 0 2;
        content-align: center middle;
        border: round ansi_black;
        background: ansi_default;
    }
    ComponentProfilePicker .pp-card.-active {
        border: round ansi_green;
        color: ansi_green;
        text-style: bold;
    }
    ComponentProfilePicker > .pp-detail {
        height: auto;
        border: round $accent;
        border-title-color: $accent;
        background: ansi_default;
        padding: 1 2;
    }
    """

    @dataclass
    class Chosen(Message):
        profile: str
        feature_ids: tuple[str, ...]

    def __init__(self, deps: Deps, **kwargs) -> None:
        super().__init__(**kwargs)
        self.deps = deps
        self.names = tuple(deps.profiles)
        self.index = 0

    def compose(self) -> ComposeResult:
        with Horizontal(classes="pp-row"):
            for name in self.names:
                yield Static(name, classes="pp-card", id=f"card-{name}")
        detail = Static("", classes="pp-detail")
        detail.border_title = "profile"
        yield detail

    def on_mount(self) -> None:
        self._refresh()

    @property
    def current(self) -> str:
        return self.names[self.index] if self.names else ""

    def move(self, step: int) -> None:
        if self.names:
            self.index = (self.index + step) % len(self.names)
            self._refresh()

    def choose(self) -> None:
        self.post_message(self.Chosen(self.current, self._ids(self.current)))

    def _ids(self, profile: str) -> tuple[str, ...]:
        return with_requires(set(self.deps.profile_ids(profile)), self.deps)

    def _refresh(self) -> None:
        for name in self.names:
            self.query_one(f"#card-{name}", Static).set_class(
                name == self.current, "-active"
            )
        ids = self._ids(self.current)
        plan = build_plan(self.deps, ids)
        groups = sorted({self.deps[i].group for i in ids})
        self.query_one(".pp-detail", Static).update(
            f"{len(ids)} features · {len(plan.pacman)} pacman · {len(plan.aur)} aur · "
            f"{len(plan.stow)} stow · {len(plan.services)} services\n"
            f"covers: {', '.join(groups)}"
        )
