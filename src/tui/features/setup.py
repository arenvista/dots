from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class SetupStep:
    """One bash command belonging to a feature.

    Composition, not inheritance: a feature owns a tuple of these rather than
    subclassing an installer. Anything bash can do -- make, curl, git clone,
    prompting for a choice -- is just a command string.
    """

    label: str
    command: str
    when: str = "post"  # "pre" (before packages) or "post" (after stow)
    interactive: bool = False  # needs a tty; the plan lists it instead of running


@dataclass(frozen=True)
class FeatureSetup:
    """Extra shell work for one feature id, beyond what deps.toml declares."""

    feature_id: str
    steps: tuple[SetupStep, ...] = ()

    def when(self, phase: str) -> tuple[SetupStep, ...]:
        return tuple(s for s in self.steps if s.when == phase and not s.interactive)

    @property
    def interactive(self) -> tuple[SetupStep, ...]:
        return tuple(s for s in self.steps if s.interactive)
