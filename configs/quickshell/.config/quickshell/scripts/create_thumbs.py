#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = ["pillow"]
# ///
"""Generate 180x120 center-crop JPEG thumbnails for wallpaper favorites.

Thumbnails are named md5(<full source path>).jpg in ~/.cache/wallpaper-thumbs,
matching the QML lookup `Qt.md5(modelData.path)` where modelData.path is the
`$HOME/wallpapers/favorites/<name>` path produced by the launcher's file scan.
Run via `uv run` so Pillow is provisioned automatically.
"""

import hashlib
import os
from concurrent.futures import ThreadPoolExecutor

from PIL import Image, ImageOps

HOME = os.environ["HOME"]
SRC = os.path.join(HOME, "wallpapers", "favorites")
CACHE = os.path.join(HOME, ".cache", "wallpaper-thumbs")
EXTS = (".jpg", ".jpeg", ".gif", ".png", ".webp")
SIZE = (180, 120)


def thumb_for(name: str) -> None:
    # Hash the same path string QML uses — do not resolve the symlink.
    src = os.path.join(SRC, name)
    digest = hashlib.md5(src.encode()).hexdigest()
    dst = os.path.join(CACHE, digest + ".jpg")

    # Skip if an up-to-date thumbnail already exists.
    try:
        if os.path.getmtime(dst) >= os.path.getmtime(src):
            return
    except OSError:
        pass

    try:
        with Image.open(src) as img:
            img.seek(0)  # first frame for animated gifs; no-op otherwise
            img = img.convert("RGB")
            img = ImageOps.fit(img, SIZE, Image.LANCZOS, centering=(0.5, 0.5))
            img.save(dst, "JPEG", quality=85)
    except (OSError, ValueError) as e:
        print(f"skip {name}: {e}")


def main() -> None:
    os.makedirs(CACHE, exist_ok=True)
    try:
        names = [
            n for n in os.listdir(SRC)
            if not n.startswith(".") and n.lower().endswith(EXTS)
        ]
    except OSError as e:
        print(f"no wallpapers: {e}")
        return
    with ThreadPoolExecutor() as pool:
        pool.map(thumb_for, names)


if __name__ == "__main__":
    main()
