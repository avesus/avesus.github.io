#!/usr/bin/env python3
"""Validate Greenforest I/O crawl, canonical, metadata, and article structure."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import subprocess
import sys
import xml.etree.ElementTree as ET
from collections import Counter
from dataclasses import dataclass, field
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urljoin, urlparse


SITE = "https://greenforest.io/"
SITEMAP_NS = {"s": "http://www.sitemaps.org/schemas/sitemap/0.9"}
PILLARS = {
    "index.html",
    "serial_multiplier/index.html",
    "webgl-glsl-computing.html",
    "cartilage/index.html",
    "cartilage/logic-to-luts.html",
    "cartilage/cmos-gain-and-output-drivers.html",
    "cartilage/clock-event-reset-distribution.html",
    "cartilage/statecharts-and-one-hot-fsms.html",
    "cartilage/clock-regions-and-timing-closure.html",
    "cartilage/metal-wires.html",
    "cartilage/nested-components-and-composition.html",
    "cartilage-nested-instantiation-demo.html",
    "shader-before-gpu-renderman-ai-hardware.html",
    "cartilage-core.html",
    "cartilage-visual-language.html",
    "the-missing-maker-fab.html",
    "how-much-radio-do-you-actually-need.html",
    "wafer-diced-smart-dust-substrate.html",
    "writing-assistance-and-published-work.html",
    "technology-research-and-consulting.html",
    "linkedin-archive/2023-11-02-why-open-sourcing-asic-fma-is-hard.html",
    "linkedin-archive/2026-01-31-the-physical-mux-tile-alphabet.html",
}


@dataclass
class Page:
    path: Path
    title: str = ""
    metas: list[dict[str, str]] = field(default_factory=list)
    canonical: str = ""
    links: list[tuple[str, str]] = field(default_factory=list)
    json_ld: list[str] = field(default_factory=list)
    h1_count: int = 0
    h2_count: int = 0

    def named_meta(self, name: str) -> str:
        name = name.lower()
        for meta in self.metas:
            if meta.get("name", "").lower() == name:
                return meta.get("content", "")
        return ""

    def property_meta(self, name: str) -> str:
        name = name.lower()
        for meta in self.metas:
            if meta.get("property", "").lower() == name:
                return meta.get("content", "")
        return ""


class PageParser(HTMLParser):
    def __init__(self, path: Path) -> None:
        super().__init__(convert_charrefs=True)
        self.page = Page(path)
        self._in_title = False
        self._title_parts: list[str] = []
        self._in_json_ld = False
        self._json_parts: list[str] = []

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        values = {key: value or "" for key, value in attrs}
        if tag == "title":
            self._in_title = True
        elif tag == "meta":
            self.page.metas.append(values)
        elif tag == "link":
            rels = values.get("rel", "").lower().split()
            if "canonical" in rels and not self.page.canonical:
                self.page.canonical = values.get("href", "")
            if values.get("href"):
                self.page.links.append(("href", values["href"]))
        elif tag == "a" and values.get("href"):
            self.page.links.append(("href", values["href"]))
        elif tag in {"img", "script", "source", "video", "audio", "object"}:
            for attribute in ("src", "poster", "data"):
                if values.get(attribute):
                    self.page.links.append((attribute, values[attribute]))
            if tag == "source" and values.get("srcset"):
                for candidate in values["srcset"].split(","):
                    url = candidate.strip().split()[0]
                    if url:
                        self.page.links.append(("srcset", url))
            if tag == "img" and not values.get("alt", "").strip():
                self.page.links.append(("missing-alt", values.get("src", "<inline>")))
            if tag == "script" and values.get("type", "").lower() == "application/ld+json":
                self._in_json_ld = True
                self._json_parts = []
        elif tag == "h1":
            self.page.h1_count += 1
        elif tag == "h2":
            self.page.h2_count += 1

    def handle_endtag(self, tag: str) -> None:
        if tag == "title":
            self._in_title = False
            self.page.title = " ".join("".join(self._title_parts).split())
        elif tag == "script" and self._in_json_ld:
            self._in_json_ld = False
            self.page.json_ld.append("".join(self._json_parts))

    def handle_data(self, data: str) -> None:
        if self._in_title:
            self._title_parts.append(data)
        if self._in_json_ld:
            self._json_parts.append(data)


def tracked_html(root: Path) -> list[Path]:
    output = subprocess.check_output(
        ["git", "ls-files", "*.html"], cwd=root, text=True, encoding="utf-8"
    )
    return [root / Path(*line.split("/")) for line in output.splitlines() if line]


def expected_url(root: Path, path: Path) -> str:
    relative = path.relative_to(root).as_posix()
    if relative == "index.html":
        return SITE
    if relative.endswith("/index.html"):
        return SITE + relative[: -len("index.html")]
    return SITE + relative


def local_target(root: Path, page: Page, raw_url: str) -> Path | None:
    if raw_url.startswith(("#", "mailto:", "tel:", "javascript:", "data:")):
        return None
    # Relative links resolve against the document URL, even when the document
    # intentionally canonicalizes to a fuller article elsewhere.
    absolute = urljoin(expected_url(root, page.path), raw_url)
    parsed = urlparse(absolute)
    if parsed.netloc.lower() not in {"greenforest.io", "www.greenforest.io"}:
        return None
    relative = unquote(parsed.path.lstrip("/"))
    if not relative:
        return root / "index.html"
    target = root / relative
    if target.is_dir() or parsed.path.endswith("/"):
        target /= "index.html"
    return target


def run(root: Path) -> int:
    errors: list[str] = []
    warnings: list[str] = []
    pages: dict[str, Page] = {}

    for path in tracked_html(root):
        parser = PageParser(path)
        parser.feed(path.read_text(encoding="utf-8"))
        page = parser.page
        relative = path.relative_to(root).as_posix()
        pages[relative] = page

        if not page.title:
            errors.append(f"{relative}: missing title")
        if not page.named_meta("description"):
            errors.append(f"{relative}: missing meta description")
        if not page.canonical:
            errors.append(f"{relative}: missing canonical")
        elif not page.canonical.startswith(SITE):
            errors.append(f"{relative}: canonical is not on HTTPS apex: {page.canonical}")
        if not page.property_meta("og:title") or not page.property_meta("og:description"):
            errors.append(f"{relative}: missing Open Graph title or description")

        for index, payload in enumerate(page.json_ld, start=1):
            try:
                json.loads(payload)
            except json.JSONDecodeError as error:
                errors.append(f"{relative}: JSON-LD #{index} is invalid: {error}")

        for attribute, value in page.links:
            if attribute == "missing-alt":
                errors.append(f"{relative}: image lacks alt text: {value}")
                continue
            target = local_target(root, page, value)
            if target is not None and not target.exists():
                errors.append(f"{relative}: missing local {attribute} target {value}")

        if relative in PILLARS:
            if page.h1_count != 1:
                errors.append(f"{relative}: expected one primary h1, found {page.h1_count}")
            if page.h2_count == 0:
                errors.append(f"{relative}: expected h2 section headings")

    sitemap_path = root / "sitemap.xml"
    sitemap = ET.parse(sitemap_path)
    entries: list[tuple[str, str]] = []
    for node in sitemap.findall("s:url", SITEMAP_NS):
        location = node.findtext("s:loc", default="", namespaces=SITEMAP_NS)
        modified = node.findtext("s:lastmod", default="", namespaces=SITEMAP_NS)
        entries.append((location, modified))

    counts = Counter(location for location, _ in entries)
    for location, count in counts.items():
        if count != 1:
            errors.append(f"sitemap: duplicate URL ({count} entries): {location}")

    today = dt.date.today()
    canonical_to_pages: dict[str, list[Page]] = {}
    for page in pages.values():
        canonical_to_pages.setdefault(page.canonical, []).append(page)
    sitemap_urls = {location for location, _ in entries}
    for location, modified in entries:
        candidates = canonical_to_pages.get(location, [])
        page = next(
            (candidate for candidate in candidates if expected_url(root, candidate.path) == location),
            candidates[0] if candidates else None,
        )
        if page is None:
            errors.append(f"sitemap: URL has no matching local canonical: {location}")
            continue
        if "noindex" in page.named_meta("robots").lower():
            errors.append(f"sitemap: noindex page is included: {location}")
        try:
            date = dt.date.fromisoformat(modified)
            if date > today:
                errors.append(f"sitemap: future lastmod for {location}: {modified}")
        except ValueError:
            errors.append(f"sitemap: invalid lastmod for {location}: {modified!r}")

    for relative, page in pages.items():
        robots = page.named_meta("robots").lower()
        if "noindex" not in robots and page.canonical not in sitemap_urls:
            warnings.append(f"indexable canonical omitted from sitemap: {relative} -> {page.canonical}")

    homepage = pages["index.html"]
    homepage_source = homepage.path.read_text(encoding="utf-8")
    if 'loading="lazy"' not in homepage_source:
        errors.append("index.html: expected lazy-loaded article images")
    if not any(suffix in homepage_source.lower() for suffix in (".avif", ".webp", ".svg")):
        errors.append("index.html: expected at least one modern or vector image source")

    print(
        f"pages={len(pages)} sitemap_urls={len(entries)} "
        f"jsonld_blocks={sum(len(page.json_ld) for page in pages.values())}"
    )
    print(f"errors={len(errors)} warnings={len(warnings)}")
    for error in errors:
        print(f"ERROR: {error}")
    for warning in warnings:
        print(f"WARN: {warning}")
    return 1 if errors else 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--root", type=Path, default=Path(__file__).resolve().parent.parent
    )
    return parser.parse_args()


if __name__ == "__main__":
    try:
        raise SystemExit(run(parse_args().root.resolve()))
    except (OSError, subprocess.CalledProcessError, ET.ParseError) as error:
        print(f"audit failed: {error}", file=sys.stderr)
        raise SystemExit(2) from error
