from __future__ import annotations

import asyncio
import re
from pathlib import Path
from typing import Any

from textual.app import ComposeResult
from textual.containers import Vertical
from textual.widgets import Log, Static

from .progress import TqdmProgress


class ComponentExecShellScript(Vertical):
    """Runs a shell script: status + tqdm bar on the left, live output right.

    A plain widget, so the caller decides where it goes -- yield it from any
    `compose()`, inside any container, with whatever `id`/`classes` the
    surrounding layout needs:

        yield ComponentExecShellScript("data/sample_a/a_script.sh",
                                       cwd=REPO_ROOT)

    Progress advances one step per line of output, unless the script emits
    `::tick` directives -- then only ticks advance it, so a chatty command
    (pacman, make) counts as the one step it is. An optional label after the
    directive is written to the log as a heading.

    `total` sets the progress bar's denominator. Leave it None and the script
    can declare its own, at any point before or during the run, by emitting

        ::total 10

    on a line of its own -- computed counts work too, e.g.
    `echo "::total $(ls dotfiles | wc -l)"`. The directive is consumed, not
    logged. With neither, the bar counts lines instead of showing a percentage.
    """

    TOTAL_DIRECTIVE = re.compile(r"^::total\s+(\d+)\s*$")
    TICK_DIRECTIVE = re.compile(r"^::tick(?:\s+(.*))?$")

    DEFAULT_CSS = """
    ComponentExecShellScript {
        layout: horizontal;
        width: 100%;
        height: 1fr;
        padding: 1 2;
    }
    ComponentExecShellScript > .exec-side {
        width: 36;
        height: 100%;
        overflow-y: auto;
        margin-right: 1;
        border: round $accent;
        border-title-color: $accent;
        background: ansi_default;
        padding: 1 2;
    }
    ComponentExecShellScript .exec-status {
        height: auto;
        margin-bottom: 1;
    }
    ComponentExecShellScript .exec-result {
        height: auto;
        margin-top: 1;
    }
    ComponentExecShellScript > .exec-output {
        width: 1fr;
        height: 100%;
        border: round $accent;
        border-title-color: $accent;
        background: ansi_default;
        padding: 0 1;
    }
    """

    def __init__(
        self,
        script: str | Path,
        *,
        cwd: str | Path | None = None,
        total: int | None = None,
        panel_title: str = "running",
        output_title: str = "output",
        **kwargs: Any,
    ) -> None:
        super().__init__(**kwargs)
        self.script = Path(script)
        self.cwd = Path(cwd) if cwd is not None else Path.cwd()
        self.total = total
        self.panel_title = panel_title
        self.output_title = output_title
        self._tick_mode = False

    @property
    def script_path(self) -> Path:
        return self.script if self.script.is_absolute() else self.cwd / self.script

    def compose(self) -> ComposeResult:
        with Vertical(classes="exec-side") as side:
            side.border_title = self.panel_title
            yield Static(f"Running {self.script}", classes="exec-status")
            # bar before the result line: in a short panel the result is what
            # should be clipped, not the progress.
            yield TqdmProgress(total=self.total, desc="lines", classes="exec-progress")
            yield Static("", classes="exec-result")
        output = Log(classes="exec-output")
        output.border_title = self.output_title
        yield output

    def on_mount(self) -> None:
        self.run_worker(self._run(), exclusive=True)

    async def _run(self) -> None:
        result = self.query_one(".exec-result", Static)
        output = self.query_one(".exec-output", Log)
        progress = self.query_one(".exec-progress", TqdmProgress)

        progress.start()
        # `bash <path>` rather than exec'ing directly, so the script runs
        # whether or not its +x bit survived.
        process = await asyncio.create_subprocess_exec(
            "bash",
            str(self.script_path),
            cwd=str(self.cwd),
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.STDOUT,
        )
        if process.stdout is not None:
            async for raw in process.stdout:
                line = raw.decode(errors="replace").rstrip("\n")
                declared = self.TOTAL_DIRECTIVE.match(line)
                if declared is not None:
                    progress.set_total(int(declared.group(1)))
                    continue
                tick = self.TICK_DIRECTIVE.match(line)
                if tick is not None:
                    self._tick_mode = True
                    label = tick.group(1)
                    if label:
                        output.write_line(f"==> {label}")
                    progress.advance()
                    continue
                output.write_line(line)
                if not self._tick_mode:
                    progress.advance()
        returncode = await process.wait()
        progress.close()
        result.update(f"finished (exit {returncode})")
