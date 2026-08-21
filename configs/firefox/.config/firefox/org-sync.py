#!/usr/bin/env python3
"""Turn org files into todo.js for the start page.

Same trick as before: Firefox gives file:// documents an opaque origin, so the
page can't fetch its own .org file. This writes a <script src>-able payload
instead, and the page reads window.ORG.

What it understands
    * TODO/NEXT/STRT/WAIT/HOLD/PROJ/DONE/KILL headings
    * [#A] priorities, :tag:inheritance:, #+FILETAGS, #+CATEGORY
    * SCHEDULED: and DEADLINE: lines, plus bare active <timestamps>
    * time ranges <2026-08-03 Mon 09:30-10:45>
    * repeaters +1w / ++1w / .+2d rolled forward to the next occurrence
    * deadline warning periods (-2d), statistics cookies [2/5] and [40%]
    * :PROPERTIES:/:LOGBOOK: drawers and :ARCHIVE: subtrees are skipped

Usage
    ./org-sync.py                 # read FILES below, write todo.js alongside
    ./org-sync.py --days 21 --out ~/.config/firefox/todo.js
"""

from __future__ import annotations

import argparse
import glob
import json
import os
import re
import sys
from datetime import date, datetime, timedelta
from pathlib import Path

# ── configure me ──────────────────────────────────────────────────────────
# Each entry is a path (globs allowed). "category" overrides #+CATEGORY and
# the filename; the order of this list picks each file's rail colour.
FILES = [
    {"path": "/home/sybil/orgfiles/refile.org", "category": "main"},
    {"path": "/home/sybil/orgfiles/school.org", "category": "school"},
    {"path": "/home/sybil/orgfiles/work.org", "category": "work"},
    {"path": "/home/sybil/orgfiles/buffers.org", "category": "buffer"},
    {"path": "/home/sybil/orgfiles/commute.org", "category": "commute"},
]

HORIZON_DAYS = 14  # how far ahead dated items are shown
BACKLOG_MAX = 12  # undated TODOs to carry over
MAX_ITEMS = 120

TODO_KEYWORDS = [
    "TODO",
    "NEXT",
    "STRT",
    "STARTED",
    "WAIT",
    "WAITING",
    "HOLD",
    "PROJ",
    "IDEA",
]
DONE_KEYWORDS = ["DONE", "KILL", "CANCELLED", "CANCELED"]
# ──────────────────────────────────────────────────────────────────────────

ALL_KEYWORDS = set(TODO_KEYWORDS) | set(DONE_KEYWORDS)

HEADING_RE = re.compile(r"^(\*+)\s+(.*)$")
PRIORITY_RE = re.compile(r"^\[#([A-Za-z])\]\s*")
TAGS_RE = re.compile(r"\s+(:(?:[\w@%#-]+:)+)$")
COOKIE_RE = re.compile(r"\s*\[(?:(\d+)/(\d+)|(\d+)%)\]")
LINK_RE = re.compile(r"\[\[([^\]]+?)\](?:\[([^\]]+?)\])?\]")
DRAWER_OPEN_RE = re.compile(r"^\s*:(?!END:)[\w-]+:\s*$")
COLOR_PROP_RE = re.compile(r"^\s*:COLOR:\s*(.+?)\s*$", re.I)
# an explicit rail colour: #rgb / #rgba / #rrggbb / #rrggbbaa, or a CSS name.
COLOR_VALUE_RE = re.compile(
    r"^(?:#(?:[0-9a-fA-F]{3,4}|[0-9a-fA-F]{6}|[0-9a-fA-F]{8})|[a-zA-Z]+)$"
)
DRAWER_END_RE = re.compile(r"^\s*:END:\s*$", re.I)
PLANNING_RE = re.compile(r"\b(SCHEDULED|DEADLINE|CLOSED):\s*")

TS_RE = re.compile(
    r"""
    (?P<open>[<\[])
    (?P<y>\d{4})-(?P<mo>\d{2})-(?P<d>\d{2})
    (?:\s+(?P<dow>[^\s\]>\d+.-]+))?
    (?:\s+(?P<h1>\d{1,2}):(?P<mi1>\d{2})
       (?:-(?P<h2>\d{1,2}):(?P<mi2>\d{2}))?)?
    (?P<mods>(?:\s+[-.+]{1,2}\d+[hdwmy])*)
    \s*(?P<close>[>\]])
""",
    re.X,
)


# ── timestamps ────────────────────────────────────────────────────────────
def add_months(d: date, months: int) -> date:
    month = d.month - 1 + months
    year = d.year + month // 12
    month = month % 12 + 1
    day = min(
        d.day,
        [
            31,
            29 if year % 4 == 0 and (year % 100 or year % 400 == 0) else 28,
            31,
            30,
            31,
            30,
            31,
            31,
            30,
            31,
            30,
            31,
        ][month - 1],
    )
    return date(year, month, day)


def step_once(d: date, count: int, unit: str) -> date:
    if unit == "d":
        return d + timedelta(days=count)
    if unit == "w":
        return d + timedelta(weeks=count)
    if unit == "h":
        return d + timedelta(days=max(1, count // 24))
    if unit == "m":
        return add_months(d, count)
    if unit == "y":
        return date(d.year + count, d.month, min(d.day, 28))
    return d


def roll_forward(d: date, repeater: str, today: date) -> date:
    """Advance a repeating timestamp to its next live occurrence."""
    if not repeater or d >= today:
        return d
    m = re.match(r"([.+]{1,2})(\d+)([hdwmy])", repeater)
    if not m:
        return d
    mode, count, unit = m.group(1), int(m.group(2)), m.group(3)
    if count <= 0:
        return d
    if mode == ".+":  # restart from today
        return step_once(today, count, unit)
    nxt = d
    for _ in range(500):  # guard against a pathological repeater
        nxt = step_once(nxt, count, unit)
        if nxt >= today:
            break
    return nxt


def parse_timestamp(m: re.Match, today: date) -> dict:
    mods = m.group("mods") or ""
    repeater = warn = ""
    for chunk in mods.split():
        if chunk.startswith("-"):
            warn = chunk
        else:
            repeater = chunk

    day = date(int(m.group("y")), int(m.group("mo")), int(m.group("d")))
    original = day
    day = roll_forward(day, repeater, today)

    ts = {
        "date": day.isoformat(),
        "active": m.group("open") == "<",
        "repeat": bool(repeater),
    }
    if repeater and day != original:
        ts["rolled"] = True
    if m.group("h1"):
        ts["time"] = f"{int(m.group('h1')):02d}:{m.group('mi1')}"
        if m.group("h2"):
            ts["endTime"] = f"{int(m.group('h2')):02d}:{m.group('mi2')}"
    if warn:
        ts["warn"] = warn
    return ts


# ── headings ──────────────────────────────────────────────────────────────
def clean_title(text: str) -> tuple[str, dict | None]:
    progress = None

    def take_cookie(m):
        nonlocal progress
        if m.group(1) is not None:
            done, total = int(m.group(1)), int(m.group(2))
            progress = {"done": done, "total": total}
        else:
            progress = {"pct": int(m.group(3))}
        return ""

    text = COOKIE_RE.sub(take_cookie, text)
    text = LINK_RE.sub(lambda m: m.group(2) or m.group(1), text)
    text = TS_RE.sub("", text)
    return re.sub(r"\s{2,}", " ", text).strip(), progress


def parse_heading(raw: str, today: date):
    m = HEADING_RE.match(raw)
    if not m:
        return None
    level, rest = len(m.group(1)), m.group(2).strip()

    tags: list[str] = []
    tag_match = TAGS_RE.search(rest)
    if tag_match:
        tags = [t for t in tag_match.group(1).split(":") if t]
        rest = rest[: tag_match.start()].rstrip()

    keyword = None
    first, _, remainder = rest.partition(" ")
    if first in ALL_KEYWORDS:
        keyword, rest = first, remainder.strip()

    priority = None
    pri_match = PRIORITY_RE.match(rest)
    if pri_match:
        priority = pri_match.group(1).upper()
        rest = rest[pri_match.end() :]

    inline = [parse_timestamp(t, today) for t in TS_RE.finditer(rest)]
    title, progress = clean_title(rest)

    return {
        "level": level,
        "keyword": keyword,
        "priority": priority,
        "title": title or "(untitled)",
        "tags": tags,
        "progress": progress,
        "inline": [t for t in inline if t["active"]],
    }


def clean_color(value: str) -> str | None:
    """A #+COLOR / :COLOR: value, or None if it isn't a usable colour.

    Dropping a typo (``#GGG``, a stray ``}``) here means the task quietly
    falls back to its palette rail instead of emitting broken CSS.
    """
    value = value.strip()
    return value if COLOR_VALUE_RE.match(value) else None


def parse_file(text: str, category: str, color: int, today: date) -> list[dict]:
    file_tags: list[str] = []
    file_category = category
    file_color: str | None = None

    items: list[dict] = []
    stack: list[dict] = []  # ancestors, for tag inheritance + breadcrumbs
    current: dict | None = None
    in_drawer = False

    for raw in text.replace("\r\n", "\n").split("\n"):
        line = raw.rstrip()

        if in_drawer:
            if DRAWER_END_RE.match(line):
                in_drawer = False
            elif current is not None:
                prop = COLOR_PROP_RE.match(line)  # :COLOR: #ff0000 in :PROPERTIES:
                if prop:
                    override = clean_color(prop.group(1))
                    if override:
                        current["railColor"] = override
            continue

        low = line.lower()
        if low.startswith("#+filetags:"):
            file_tags = [t for t in line.split(":", 1)[1].split(":") if t.strip()]
            continue
        if low.startswith("#+category:") and not category:
            file_category = line.split(":", 1)[1].strip()
            continue
        if low.startswith("#+color:"):
            file_color = clean_color(line.split(":", 1)[1])
            continue

        head = parse_heading(line, today)
        if head:
            in_drawer = False
            while stack and stack[-1]["level"] >= head["level"]:
                stack.pop()

            inherited = list(file_tags)
            for parent in stack:
                inherited += parent["tags"]
            head["allTags"] = sorted(set(inherited + head["tags"]))
            head["crumb"] = stack[-1]["title"] if stack else ""
            head["category"] = file_category
            head["color"] = color
            head["railColor"] = file_color  # a per-heading :COLOR: may override
            head["archived"] = "ARCHIVE" in head["allTags"] or any(
                p.get("archived") for p in stack
            )

            stack.append(head)
            current = head
            items.append(head)
            continue

        if current is None:
            continue

        if DRAWER_OPEN_RE.match(line) and not PLANNING_RE.search(line):
            in_drawer = True
            continue

        if PLANNING_RE.search(line):
            pos = 0
            while True:
                kw = PLANNING_RE.search(line, pos)
                if not kw:
                    break
                ts = TS_RE.search(line, kw.end())
                if ts:
                    current[kw.group(1).lower()] = parse_timestamp(ts, today)
                    pos = ts.end()
                else:
                    pos = kw.end()
            continue

        for ts in TS_RE.finditer(line):
            parsed = parse_timestamp(ts, today)
            if parsed["active"]:
                current.setdefault("inline", []).append(parsed)

    return items


# ── assembly ──────────────────────────────────────────────────────────────
def anchor(item: dict) -> tuple[str, dict, str] | None:
    """The date an item lands on in the agenda, and why."""
    if item.get("scheduled"):
        return item["scheduled"]["date"], item["scheduled"], "scheduled"
    if item.get("deadline"):
        return item["deadline"]["date"], item["deadline"], "deadline"
    for ts in item.get("inline", []):
        return ts["date"], ts, "timestamp"
    return None


def build(days: int) -> dict:
    today = date.today()
    horizon = today + timedelta(days=days)

    raw_items: list[dict] = []
    for index, entry in enumerate(FILES):
        pattern = os.path.expanduser(entry["path"])
        paths = (
            sorted(glob.glob(pattern))
            if any(c in pattern for c in "*?[")
            else [pattern]
        )
        for path in paths:
            try:
                text = Path(path).read_text(encoding="utf-8", errors="replace")
            except OSError as err:
                print(f"  skip {path}: {err}", file=sys.stderr)
                continue
            category = entry.get("category") or Path(path).stem
            found = parse_file(text, category, index % 6, today)
            raw_items += found
            print(f"  {category}: {len(found)} heading(s) from {path}")

    dated, backlog = [], []
    for item in raw_items:
        if item["archived"]:
            continue
        done = item["keyword"] in DONE_KEYWORDS if item["keyword"] else False
        spot = anchor(item)

        # a bare structural heading with no keyword and no date is just an outline node
        if not item["keyword"] and not spot:
            continue
        if done:
            continue

        record = {
            "title": item["title"],
            "keyword": item["keyword"],
            "priority": item["priority"],
            "tags": [t for t in item["allTags"] if t != "ARCHIVE"],
            "category": item["category"],
            "color": item["color"],
            "crumb": item["crumb"],
        }
        if item.get("railColor"):
            record["railColor"] = item["railColor"]
        if item.get("progress"):
            record["progress"] = item["progress"]
        if item.get("deadline"):
            record["deadline"] = item["deadline"]["date"]
        if item.get("scheduled"):
            record["scheduled"] = item["scheduled"]["date"]

        if spot:
            day, ts, kind = spot
            record["date"] = day
            record["kind"] = kind
            record["repeat"] = ts.get("repeat", False)
            if ts.get("time"):
                record["time"] = ts["time"]
            if ts.get("endTime"):
                record["endTime"] = ts["endTime"]
            if day <= horizon.isoformat():
                dated.append(record)
        else:
            backlog.append(record)

    rank = {"A": 0, "B": 1, None: 1, "C": 2}  # org treats "unset" as B
    dated.sort(
        key=lambda r: (
            r["date"],
            r.get("time") or "99:99",
            rank.get(r["priority"], 1),
            r["title"],
        )
    )
    backlog.sort(
        key=lambda r: (
            rank.get(r["priority"], 1),
            TODO_KEYWORDS.index(r["keyword"]) if r["keyword"] in TODO_KEYWORDS else 9,
            r["title"],
        )
    )

    return {
        "generated": datetime.now().astimezone().isoformat(),
        "today": today.isoformat(),
        "horizonDays": days,
        "categories": sorted({r["category"] for r in dated + backlog}),
        "items": (dated + backlog[:BACKLOG_MAX])[:MAX_ITEMS],
        "counts": {"dated": len(dated), "backlog": len(backlog)},
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Build todo.js from org files.")
    ap.add_argument("--out", default=str(Path(__file__).with_name("todo.js")))
    ap.add_argument("--days", type=int, default=HORIZON_DAYS)
    args = ap.parse_args()

    if not FILES:
        print("No org files configured — edit FILES near the top.", file=sys.stderr)

    data = build(args.days)
    payload = json.dumps(data, ensure_ascii=False, indent=2)

    out = Path(os.path.expanduser(args.out))
    tmp = out.with_suffix(".js.tmp")
    tmp.write_text(
        "/* generated by org-sync.py — do not edit */\n" f"window.ORG = {payload};\n",
        encoding="utf-8",
    )
    tmp.replace(out)  # atomic, so a new tab never reads a half file

    print(f"wrote {len(data['items'])} item(s) → {out}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
