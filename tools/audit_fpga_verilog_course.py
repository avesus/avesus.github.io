#!/usr/bin/env python3
"""Audit the source-preserving FPGA/Verilog course publication."""

from __future__ import annotations

import json
import re
import sys
import xml.etree.ElementTree as ET
from collections import defaultdict
from html import unescape
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urlparse


ROOT = Path(__file__).resolve().parents[1]
ORIGIN = "https://greenforest.io"

COURSE_PAGES = {
    "fpga-verilog/index.html": "/fpga-verilog/",
    "fpga-verilog/what-is-an-fpga.html": "/fpga-verilog/what-is-an-fpga.html",
    "fpga-verilog/fpga-architecture-luts-flip-flops-routing.html": (
        "/fpga-verilog/fpga-architecture-luts-flip-flops-routing.html"
    ),
    "fpga-verilog/fpga-learning-roadmap.html": (
        "/fpga-verilog/fpga-learning-roadmap.html"
    ),
    "fpga-verilog/verilog-workbench-iverilog-gtkwave.html": (
        "/fpga-verilog/verilog-workbench-iverilog-gtkwave.html"
    ),
    "fpga-verilog/verilog-modules-testbenches-constraints.html": (
        "/fpga-verilog/verilog-modules-testbenches-constraints.html"
    ),
    "fpga-verilog/cd4029b-counter-verilog.html": (
        "/fpga-verilog/cd4029b-counter-verilog.html"
    ),
    "fpga-verilog/yosys-nextpnr-icestorm-alchitry-cu.html": (
        "/fpga-verilog/yosys-nextpnr-icestorm-alchitry-cu.html"
    ),
}

BACKLINK_TARGETS = {
    "fpga-systems.html",
    "proof-and-artifacts.html",
    "faq.html",
    "serial_multiplier/index.html",
    "ethernet-udp-ice40-reprogrammer.html",
    "how-much-radio-do-you-actually-need.html",
    "one-pin-quadrature-sdm-transmitter.html",
    "cartilage/index.html",
    "cartilage/logic-to-luts.html",
    "physical-mux-tiles/index.html",
    "linkedin-archive/2022-04-18-verilog-as-a-programming-language.html",
    "linkedin-archive/2022-05-05-fpgas-as-reactive-parallel-beauty.html",
    "linkedin-archive/2022-05-12-verilog-allocation-and-dynamic-languages.html",
    "linkedin-archive/2021-06-18-mini-fpgas-inside-fpgas.html",
    "linkedin-archive/2023-11-09-learn-how-chips-multiply-and-add.html",
}

BLANK_SOURCE_PARAGRAPHS = {
    3,
    6,
    9,
    11,
    13,
    15,
    17,
    19,
    33,
    42,
    47,
    53,
    54,
    58,
    61,
    66,
    72,
    75,
    78,
    81,
    85,
    86,
    87,
    89,
    95,
    96,
    97,
    98,
    100,
    120,
    126,
    132,
    139,
    144,
    147,
}

SOURCE_OWNERS = {
    "fpga-verilog/index.html": {1},
    "fpga-verilog/what-is-an-fpga.html": set(range(4, 19)),
    "fpga-verilog/fpga-architecture-luts-flip-flops-routing.html": set(
        range(20, 30)
    ),
    "fpga-verilog/fpga-learning-roadmap.html": set(range(30, 53)),
    "fpga-verilog/verilog-workbench-iverilog-gtkwave.html": set(range(55, 66)),
    "fpga-verilog/verilog-modules-testbenches-constraints.html": {
        2,
        *range(67, 81),
    },
    "fpga-verilog/cd4029b-counter-verilog.html": set(range(82, 107)),
    "fpga-verilog/yosys-nextpnr-icestorm-alchitry-cu.html": set(range(107, 147)),
}

EXPECTED_DIAGRAMS = {
    "arrays-loops-checks.svg",
    "cd4029b-functional-model.svg",
    "counter-waveform.svg",
    "course-map.svg",
    "fpga-fabric-anatomy.svg",
    "hardwired-and-field-programmable.svg",
    "mental-models-for-hdl.svg",
    "module-testbench-constraints.svg",
    "verilog-to-bitstream.svg",
}

MINIMUM_WORDS = {
    "fpga-verilog/index.html": 550,
    "fpga-verilog/what-is-an-fpga.html": 900,
    "fpga-verilog/fpga-architecture-luts-flip-flops-routing.html": 750,
    "fpga-verilog/fpga-learning-roadmap.html": 1100,
    "fpga-verilog/verilog-workbench-iverilog-gtkwave.html": 850,
    "fpga-verilog/verilog-modules-testbenches-constraints.html": 850,
    "fpga-verilog/cd4029b-counter-verilog.html": 1500,
    "fpga-verilog/yosys-nextpnr-icestorm-alchitry-cu.html": 1600,
}


def normalize(value: str) -> str:
    return " ".join(unescape(value).split())


class PageParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.stack: list[str] = []
        self.title_parts: list[str] = []
        self.h1_count = 0
        self.h2_count = 0
        self.description = ""
        self.canonical = ""
        self.links: list[str] = []
        self.sources: list[str] = []
        self.images: list[dict[str, str]] = []
        self.json_ld: list[str] = []
        self._capture: str | None = None
        self._capture_parts: list[str] = []
        self._json_parts: list[str] | None = None
        self.paragraphs: list[str] = []
        self._paragraph_parts: list[str] | None = None
        self.text_parts: list[str] = []

    def handle_starttag(
        self, tag: str, attrs: list[tuple[str, str | None]]
    ) -> None:
        tag = tag.lower()
        values = {key.lower(): value or "" for key, value in attrs}
        self.stack.append(tag)
        if tag == "title":
            self._capture = "title"
            self._capture_parts = []
        elif tag == "h1":
            self.h1_count += 1
        elif tag == "h2":
            self.h2_count += 1
        elif tag == "meta" and values.get("name", "").lower() == "description":
            self.description = values.get("content", "")
        elif tag == "link" and values.get("rel", "").lower() == "canonical":
            self.canonical = values.get("href", "")
        elif tag == "a":
            self.links.append(values.get("href", ""))
        elif tag in {"img", "script", "source"} and values.get("src"):
            self.sources.append(values["src"])
            if tag == "img":
                self.images.append(values)
        elif (
            tag == "script"
            and values.get("type", "").lower() == "application/ld+json"
        ):
            self._json_parts = []
        elif tag == "p":
            self._paragraph_parts = []

    def handle_startendtag(
        self, tag: str, attrs: list[tuple[str, str | None]]
    ) -> None:
        self.handle_starttag(tag, attrs)
        self.handle_endtag(tag)

    def handle_data(self, data: str) -> None:
        if self._capture == "title":
            self._capture_parts.append(data)
        if self._json_parts is not None:
            self._json_parts.append(data)
        if self._paragraph_parts is not None:
            self._paragraph_parts.append(data)
        if not any(parent in {"script", "style"} for parent in self.stack):
            self.text_parts.append(data)

    def handle_endtag(self, tag: str) -> None:
        tag = tag.lower()
        if tag == "title" and self._capture == "title":
            self.title_parts = list(self._capture_parts)
            self._capture = None
        elif tag == "script" and self._json_parts is not None:
            self.json_ld.append("".join(self._json_parts))
            self._json_parts = None
        elif tag == "p" and self._paragraph_parts is not None:
            paragraph = normalize("".join(self._paragraph_parts))
            if paragraph:
                self.paragraphs.append(paragraph)
            self._paragraph_parts = None
        if self.stack:
            for index in range(len(self.stack) - 1, -1, -1):
                if self.stack[index] == tag:
                    del self.stack[index:]
                    break

    @property
    def title(self) -> str:
        return normalize("".join(self.title_parts))

    @property
    def text(self) -> str:
        return normalize(" ".join(self.text_parts))


def parse_page(relative: str) -> tuple[PageParser, str]:
    document = (ROOT / relative).read_text(encoding="utf-8")
    parser = PageParser()
    parser.feed(document)
    parser.close()
    return parser, document


def resolve_local(owner: Path, raw: str) -> Path | None:
    raw = raw.strip()
    if not raw or raw.startswith(("#", "mailto:", "tel:", "data:", "javascript:")):
        return None
    parsed = urlparse(raw)
    if parsed.scheme in {"http", "https"} or parsed.netloc:
        return None
    path_text = unquote(parsed.path)
    if not path_text:
        return None
    if path_text.startswith("/"):
        candidate = ROOT / path_text.lstrip("/")
    else:
        candidate = owner.parent / path_text
    if path_text.endswith("/"):
        candidate /= "index.html"
    return candidate.resolve()


def check_source_ledger(errors: list[str]) -> None:
    expected = set(range(1, 148)) - BLANK_SOURCE_PARAGRAPHS
    seen: dict[int, str] = {}
    for owner, paragraphs in SOURCE_OWNERS.items():
        for paragraph in paragraphs - BLANK_SOURCE_PARAGRAPHS:
            if paragraph in seen:
                errors.append(
                    f"source P{paragraph} assigned to both {seen[paragraph]} and {owner}"
                )
            seen[paragraph] = owner
    missing = sorted(expected - set(seen))
    extra = sorted(set(seen) - expected)
    if missing:
        errors.append(f"source ledger missing paragraphs: {missing}")
    if extra:
        errors.append(f"source ledger has non-substantive paragraphs: {extra}")
    if len(seen) != 112:
        errors.append(f"source ledger expected 112 substantive blocks, found {len(seen)}")


def main() -> int:
    errors: list[str] = []
    parsed: dict[str, PageParser] = {}
    all_paragraphs: dict[str, list[str]] = defaultdict(list)

    check_source_ledger(errors)

    for relative, route in COURSE_PAGES.items():
        path = ROOT / relative
        if not path.is_file():
            errors.append(f"missing course page: {relative}")
            continue
        page, document = parse_page(relative)
        parsed[relative] = page
        if page.h1_count != 1:
            errors.append(f"{relative}: expected one h1, found {page.h1_count}")
        if page.h2_count < 3:
            errors.append(f"{relative}: expected at least three h2 headings")
        if not page.title:
            errors.append(f"{relative}: missing title")
        if not 70 <= len(page.description) <= 190:
            errors.append(
                f"{relative}: description length {len(page.description)} outside 70-190"
            )
        expected_canonical = ORIGIN + route
        if page.canonical != expected_canonical:
            errors.append(
                f"{relative}: canonical {page.canonical!r}, expected {expected_canonical!r}"
            )
        if not page.json_ld:
            errors.append(f"{relative}: missing JSON-LD")
        for block in page.json_ld:
            try:
                json.loads(block)
            except json.JSONDecodeError as exc:
                errors.append(f"{relative}: invalid JSON-LD: {exc}")
        if "Source ownership:" not in document:
            errors.append(f"{relative}: missing source-ownership marker")
        words = re.findall(r"\b[\w’-]+\b", page.text)
        if len(words) < MINIMUM_WORDS[relative]:
            errors.append(
                f"{relative}: {len(words)} words, expected at least {MINIMUM_WORDS[relative]}"
            )
        for image in page.images:
            for attribute in ("src", "alt", "width", "height"):
                if not image.get(attribute):
                    errors.append(f"{relative}: image missing {attribute}: {image}")
        for raw in [*page.links, *page.sources]:
            resolved = resolve_local(path, raw)
            if resolved is not None and not resolved.exists():
                errors.append(f"{relative}: broken local reference {raw!r}")
        for paragraph in page.paragraphs:
            if len(paragraph) >= 100 and not paragraph.startswith(
                (
                    "Return to the complete",
                    "See the complete",
                    "Original Greenforest I/O",
                )
            ):
                all_paragraphs[paragraph].append(relative)

    for paragraph, owners in all_paragraphs.items():
        unique_owners = sorted(set(owners))
        if len(unique_owners) > 1:
            errors.append(
                "duplicate course paragraph in "
                + ", ".join(unique_owners)
                + f": {paragraph[:100]!r}"
            )

    for relative in sorted(BACKLINK_TARGETS):
        page, _ = parse_page(relative)
        links = [link for link in page.links if link.startswith("/fpga-verilog")]
        if not links:
            errors.append(f"{relative}: missing contextual course backlink")

    diagram_root = ROOT / "fpga-verilog" / "diagrams"
    actual_diagrams = {path.name for path in diagram_root.glob("*.svg")}
    if actual_diagrams != EXPECTED_DIAGRAMS:
        errors.append(
            f"diagram manifest mismatch: expected {sorted(EXPECTED_DIAGRAMS)}, "
            f"found {sorted(actual_diagrams)}"
        )
    for name in sorted(EXPECTED_DIAGRAMS):
        try:
            ET.parse(diagram_root / name)
        except (ET.ParseError, OSError) as exc:
            errors.append(f"invalid SVG {name}: {exc}")

    for retained_image in (
        ROOT / "fpga-verilog/media/manuscript-logic-array.png",
        ROOT / "fpga-verilog/media/manuscript-array-to-lab.png",
    ):
        if not retained_image.is_file() or retained_image.stat().st_size == 0:
            errors.append(f"missing retained manuscript image: {retained_image.name}")
    if any(path.name == "image2.png" for path in (ROOT / "fpga-verilog").rglob("*")):
        errors.append("unattributed cropped vendor image2.png was published")

    sitemap = ET.parse(ROOT / "sitemap.xml")
    namespace = {"sm": "http://www.sitemaps.org/schemas/sitemap/0.9"}
    sitemap_urls = {
        element.text or "" for element in sitemap.findall("sm:url/sm:loc", namespace)
    }
    for route in COURSE_PAGES.values():
        if ORIGIN + route not in sitemap_urls:
            errors.append(f"sitemap.xml missing {route}")

    site_map, site_map_document = parse_page("site-map.html")
    site_map_links = set(site_map.links)
    for relative, route in COURSE_PAGES.items():
        expected = route.lstrip("/")
        if route.endswith("/"):
            expected = expected
        if expected not in site_map_links:
            errors.append(f"site-map.html missing {route}")
    list_links = re.findall(r"<li><a\s+href=", site_map_document, flags=re.IGNORECASE)
    if len(list_links) != 218:
        errors.append(
            f"site-map.html expected 218 listed routes, found {len(list_links)}"
        )
    if "219 articles, collections" not in site_map_document:
        errors.append("site-map.html visible count is not 219")

    chapter_seven = (
        ROOT / "fpga-verilog/yosys-nextpnr-icestorm-alchitry-cu.html"
    ).read_text(encoding="utf-8")
    copied_phrases = (
        "I found that getting started with the Alchitry CU",
        "If you are reading this Alchitry, get your tutorials organized",
        "Assuming you have no errors, plug in your device and upload",
    )
    for phrase in copied_phrases:
        if phrase in chapter_seven:
            errors.append(f"chapter 7 retains copied prose: {phrase!r}")
    if "Cody Snider" not in chapter_seven:
        errors.append("chapter 7 is missing Cody Snider attribution")

    total_words = sum(
        len(re.findall(r"\b[\w’-]+\b", page.text)) for page in parsed.values()
    )
    backlink_count = 0
    for relative in BACKLINK_TARGETS:
        page, _ = parse_page(relative)
        backlink_count += sum(
            1 for link in page.links if link.startswith("/fpga-verilog")
        )

    print(f"course_pages={len(parsed)}")
    print(f"course_words={total_words}")
    print("source_blocks=112")
    print(f"diagrams={len(actual_diagrams)}")
    print("retained_manuscript_images=2")
    print(f"contextual_backlinks={backlink_count}")
    print(f"site_map_listed_routes={len(list_links)}")
    print(f"errors={len(errors)}")
    for error in errors:
        print(f"ERROR: {error}")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main())
