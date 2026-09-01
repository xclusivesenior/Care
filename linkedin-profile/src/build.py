#!/usr/bin/env python3
"""Render the LinkedIn image assets from the HTML templates in this folder.

Usage:  python3 build.py
Output: ../images/*.png at the exact pixel sizes LinkedIn expects.

Each template is rendered at 2x through headless Chromium and downsampled with
Pillow, which keeps the type crisp instead of letting Chromium hint it at 1x.
"""

import pathlib
import shutil
import subprocess
import sys
import tempfile

from PIL import Image

SRC = pathlib.Path(__file__).resolve().parent
OUT = SRC.parent / "images"

CHROME_CANDIDATES = [
    "/opt/pw-browsers/chromium-1194/chrome-linux/chrome",
    "/opt/pw-browsers/chromium/chrome-linux/chrome",
    shutil.which("chromium") or "",
    shutil.which("google-chrome") or "",
]

# (template, output name, width, height)
ASSETS = [
    ("logo.html",           "profile-picture-400x400.png",  400, 400),
    ("banner-profile.html", "banner-profile-1584x396.png", 1584, 396),
    ("banner-company.html", "banner-company-1128x191.png", 1128, 191),
]

SCALE = 2

# Chromium's --window-size includes window chrome, so the live viewport is
# shorter than the requested height and anything below it renders as bare page
# background. Render tall, then crop the top-left W x H, which is exact because
# every template anchors its field at 0,0.
VIEWPORT_PAD = 200


def find_chrome() -> str:
    for path in CHROME_CANDIDATES:
        if path and pathlib.Path(path).exists():
            return path
    sys.exit("No Chromium/Chrome binary found; set one in CHROME_CANDIDATES.")


def render(chrome: str, template: str, out_name: str, width: int, height: int) -> None:
    target = OUT / out_name
    with tempfile.TemporaryDirectory() as tmp:
        shot = pathlib.Path(tmp) / "shot.png"
        subprocess.run(
            [
                chrome,
                "--headless",
                "--disable-gpu",
                "--no-sandbox",
                "--hide-scrollbars",
                "--allow-file-access-from-files",
                "--default-background-color=00000000",
                f"--force-device-scale-factor={SCALE}",
                f"--window-size={width},{height + VIEWPORT_PAD}",
                f"--screenshot={shot}",
                f"--virtual-time-budget=4000",
                (SRC / template).as_uri(),
            ],
            check=True,
            capture_output=True,
        )
        img = Image.open(shot).convert("RGB")
        img = img.crop((0, 0, width * SCALE, height * SCALE))
        img = img.resize((width, height), Image.LANCZOS)
        img.save(target, "PNG", optimize=True)

    kb = target.stat().st_size / 1024
    print(f"  {out_name:<32} {width}x{height}  {kb:6.1f} KB")


def main() -> None:
    chrome = find_chrome()
    OUT.mkdir(parents=True, exist_ok=True)
    print(f"Rendering with {chrome}\n")
    for template, out_name, width, height in ASSETS:
        render(chrome, template, out_name, width, height)
    print(f"\nDone -> {OUT}")


if __name__ == "__main__":
    main()
