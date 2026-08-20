#!/usr/bin/env python3
"""Fill a Ghostty theme template with colors from pywal's colors-kitty.conf.

Reads key/value pairs like `color4  #1B3D9F` from the wal cache, then
replaces bracketed placeholders ([bg], [fg], [cursor], [color0]..[color15])
in the template with the corresponding hex values.

Placeholders are matched as whole tokens via regex, so [color1] can never
clobber part of [color10]-[color15].
"""

import re
import sys
from pathlib import Path

WAL_CONF = Path("/home/sybil/.cache/wal/colors-kitty.conf")
TEMPLATE = Path("/home/sybil/.config/ghostty/themes/theme-custom.template")
OUTPUT = Path("/home/sybil/.config/ghostty/themes/theme-custom")

# Template placeholder -> key name in the wal conf
ALIASES = {
    "bg": "background",
    "fg": "foreground",
    "cursor": "cursor",
}


def parse_wal_conf(path: Path) -> dict[str, str]:
    """Parse `name  #hex` lines into a dict, skipping blanks/comments."""
    colors: dict[str, str] = {}
    for line in path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        parts = line.split()
        if len(parts) >= 2:
            colors[parts[0]] = parts[1]
    return colors


def fill_template(template_text: str, colors: dict[str, str]) -> str:
    """Replace [placeholder] tokens with color values, exact-match only."""
    missing: set[str] = set()

    def substitute(match: re.Match) -> str:
        token = match.group(1)  # e.g. "color10" or "bg"
        key = ALIASES.get(token, token)  # map bg -> background, etc.
        value = colors.get(key)
        if value is None:
            missing.add(token)
            return match.group(0)  # leave placeholder untouched
        return value

    result = re.sub(r"\[([A-Za-z0-9_]+)\]", substitute, template_text)

    # Ghostty forbids inline comments after values, so strip them.
    # Only a '#' preceded AND followed by whitespace counts as a comment,
    # which leaves hex values like '#0c0c0d' untouched. Full-line comments
    # (lines starting with '#') are kept as-is.
    cleaned = []
    for line in result.splitlines():
        if not line.lstrip().startswith("#"):
            line = re.sub(r"\s+#\s.*$", "", line)
        cleaned.append(line.rstrip())
    result = "\n".join(cleaned) + "\n"

    if missing:
        print(
            f"warning: no value found for: {', '.join(sorted(missing))}",
            file=sys.stderr,
        )
    return result


def main() -> int:
    # Allow overriding paths: color.py [wal_conf] [template] [output]
    wal = Path(sys.argv[1]) if len(sys.argv) > 1 else WAL_CONF
    template = Path(sys.argv[2]) if len(sys.argv) > 2 else TEMPLATE
    output = Path(sys.argv[3]) if len(sys.argv) > 3 else OUTPUT

    if not wal.is_file():
        print(f"error: wal conf not found: {wal}", file=sys.stderr)
        return 1
    if not template.is_file():
        print(f"error: template not found: {template}", file=sys.stderr)
        return 1

    colors = parse_wal_conf(wal)
    filled = fill_template(template.read_text(), colors)
    output.write_text(filled)
    print(f"wrote {output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
