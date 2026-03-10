"""
download_fonts.py — Download a curated set of free Japanese fonts for training.

Fonts are saved to ml/data/fonts/.

Usage:
    python scripts/download_fonts.py

Sources: Google Fonts GitHub (OFL licence), IPA Fonts (IPA licence).
"""

from __future__ import annotations

import sys
import urllib.request
from pathlib import Path

FONTS_DIR = Path(__file__).resolve().parents[1] / "data" / "fonts"

# (filename, url)
FONTS = [
    # --- Original set (kept if already downloaded) ---
    ("MPLUS1p-Regular.ttf",
     "https://github.com/google/fonts/raw/main/ofl/mplus1p/MPLUS1p-Regular.ttf"),
    ("KosugiMaru-Regular.ttf",
     "https://github.com/google/fonts/raw/main/ofl/kosugimaru/KosugiMaru-Regular.ttf"),
    ("Kosugi-Regular.ttf",
     "https://github.com/google/fonts/raw/main/ofl/kosugi/Kosugi-Regular.ttf"),
    ("SawarabiGothic-Regular.ttf",
     "https://github.com/google/fonts/raw/main/ofl/sawarabigothic/SawarabiGothic-Regular.ttf"),
    ("SawarabiMincho-Regular.ttf",
     "https://github.com/google/fonts/raw/main/ofl/sawarabimincho/SawarabiMincho-Regular.ttf"),
    ("HachiMaruPop-Regular.ttf",
     "https://github.com/google/fonts/raw/main/ofl/hachimarupop/HachiMaruPop-Regular.ttf"),
    ("ZenKurenaido-Regular.ttf",
     "https://github.com/google/fonts/raw/main/ofl/zenkurenaido/ZenKurenaido-Regular.ttf"),
    ("DelaGothicOne-Regular.ttf",
     "https://github.com/google/fonts/raw/main/ofl/delagothicone/DelaGothicOne-Regular.ttf"),

    # --- Additional confirmed fonts ---
    # BIZ UD Gothic — standard gothic, regular + bold
    ("BIZUDGothic-Regular.ttf",
     "https://github.com/google/fonts/raw/main/ofl/bizudgothic/BIZUDGothic-Regular.ttf"),
    ("BIZUDGothic-Bold.ttf",
     "https://github.com/google/fonts/raw/main/ofl/bizudgothic/BIZUDGothic-Bold.ttf"),
    # BIZ UDP Gothic — proportional gothic
    ("BIZUDPGothic-Regular.ttf",
     "https://github.com/google/fonts/raw/main/ofl/bizudpgothic/BIZUDPGothic-Regular.ttf"),
    # BIZ UD Mincho — standard mincho (serif)
    ("BIZUDMincho-Regular.ttf",
     "https://github.com/google/fonts/raw/main/ofl/bizudmincho/BIZUDMincho-Regular.ttf"),
    # BIZ UDP Mincho — proportional mincho
    ("BIZUDPMincho-Regular.ttf",
     "https://github.com/google/fonts/raw/main/ofl/bizudpmincho/BIZUDPMincho-Regular.ttf"),
    # M PLUS Rounded 1c — rounder than M PLUS 1p
    ("MPLUSRounded1c-Regular.ttf",
     "https://github.com/google/fonts/raw/main/ofl/mplusrounded1c/MPLUSRounded1c-Regular.ttf"),
    ("MPLUSRounded1c-Bold.ttf",
     "https://github.com/google/fonts/raw/main/ofl/mplusrounded1c/MPLUSRounded1c-Bold.ttf"),
    # Zen Maru Gothic — rounded gothic
    ("ZenMaruGothic-Regular.ttf",
     "https://github.com/google/fonts/raw/main/ofl/zenmarugothic/ZenMaruGothic-Regular.ttf"),
    ("ZenMaruGothic-Bold.ttf",
     "https://github.com/google/fonts/raw/main/ofl/zenmarugothic/ZenMaruGothic-Bold.ttf"),
    # Zen Old Mincho — classical mincho
    ("ZenOldMincho-Regular.ttf",
     "https://github.com/google/fonts/raw/main/ofl/zenoldmincho/ZenOldMincho-Regular.ttf"),
    # Yusei Magic — casual, handwriting-inspired
    ("YuseiMagic-Regular.ttf",
     "https://github.com/google/fonts/raw/main/ofl/yuseimagic/YuseiMagic-Regular.ttf"),
    # DotGothic16 — pixel/dot gothic
    ("DotGothic16-Regular.ttf",
     "https://github.com/google/fonts/raw/main/ofl/dotgothic16/DotGothic16-Regular.ttf"),
    # RocknRoll One — bold, expressive
    ("RocknRollOne-Regular.ttf",
     "https://github.com/google/fonts/raw/main/ofl/rocknrollone/RocknRollOne-Regular.ttf"),
    # Kaisei Tokumin — classic mincho, regular + bold
    ("KaiseiTokumin-Regular.ttf",
     "https://github.com/google/fonts/raw/main/ofl/kaiseitokumin/KaiseiTokumin-Regular.ttf"),
    ("KaiseiTokumin-Bold.ttf",
     "https://github.com/google/fonts/raw/main/ofl/kaiseitokumin/KaiseiTokumin-Bold.ttf"),
    # Shippori Mincho — refined mincho
    ("ShipporiMincho-Regular.ttf",
     "https://github.com/google/fonts/raw/main/ofl/shipporimincho/ShipporiMincho-Regular.ttf"),
    # Reggae One — decorative, high contrast
    ("ReggaeOne-Regular.ttf",
     "https://github.com/google/fonts/raw/main/ofl/reggaeone/ReggaeOne-Regular.ttf"),
    # Zen Antique — antique serif style
    ("ZenAntique-Regular.ttf",
     "https://github.com/google/fonts/raw/main/ofl/zenantique/ZenAntique-Regular.ttf"),
    # Stick — ultra-thin strokes
    ("Stick-Regular.ttf",
     "https://github.com/google/fonts/raw/main/ofl/stick/Stick-Regular.ttf"),
    # Train One — sharp, geometric
    ("TrainOne-Regular.ttf",
     "https://github.com/google/fonts/raw/main/ofl/trainone/TrainOne-Regular.ttf"),
]


def download(filename: str, url: str) -> bool:
    out = FONTS_DIR / filename
    if out.exists():
        print(f"  skip (exists): {filename}")
        return True
    print(f"  downloading: {filename} ...", end=" ", flush=True)
    try:
        urllib.request.urlretrieve(url, out)
        print("done")
        return True
    except Exception as e:
        print(f"FAILED: {e}")
        return False


def main():
    FONTS_DIR.mkdir(parents=True, exist_ok=True)
    ok = sum(download(name, url) for name, url in FONTS)
    print(f"\n{ok}/{len(FONTS)} fonts ready in {FONTS_DIR}")
    if ok < len(FONTS):
        print("Some downloads failed. Check URLs or download manually.")
        sys.exit(1)


if __name__ == "__main__":
    main()
