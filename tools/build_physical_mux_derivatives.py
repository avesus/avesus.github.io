#!/usr/bin/env python3
"""Build metadata-free WebP derivatives for the physical MUX tile article."""

from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "physical-mux-tiles" / "tangible-surface-publisher-package" / "assets"
OUTPUT = ROOT / "physical-mux-tiles" / "media"

IMAGES = {
    "6BC563B5-5B9B-4D0F-9C4B-3017085E3F20.jpeg": "assembly.webp",
    "42F6D7B9-1A86-41C3-BCEF-6EFF2511CC81.jpeg": "alphabet.webp",
    "47FB8CE9-2FBC-4AF3-8562-6CD8DBE2E662.jpeg": "connector-stack.webp",
    "2F663DA5-6E7D-4922-9100-BFDCF5061025.jpeg": "side-profile.webp",
}


def main() -> None:
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for source_name, output_name in IMAGES.items():
        with Image.open(SOURCE / source_name) as source:
            image = source.convert("RGB")
            image.thumbnail((1440, 1440), Image.Resampling.LANCZOS)
            image.save(OUTPUT / output_name, "WEBP", quality=86, method=6)


if __name__ == "__main__":
    main()
