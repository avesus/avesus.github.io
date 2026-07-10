#!/usr/bin/env python3
"""Build static social metadata and branded preview cards for every tracked HTML page.

Slack and LinkedIn fetch HTML without running the site's JavaScript, so the
Open Graph tags generated here intentionally live in each document head. The
analytics loader is shared, deferred, and separate from the presentation-heavy
common-script.js used by most articles.

Requires Pillow. Run from anywhere:

    python tools/build_share_previews.py
    python tools/build_share_previews.py --check
"""

from __future__ import annotations

import argparse
import hashlib
import html as html_module
import io
import random
import re
import subprocess
import sys
from dataclasses import dataclass, field
from html.parser import HTMLParser
from pathlib import Path, PurePosixPath
from urllib.parse import quote, unquote, urljoin, urlparse

from PIL import Image, ImageDraw, ImageFont, ImageOps


SITE_ORIGIN = "https://greenforest.io"
PREVIEW_WIDTH = 1200
PREVIEW_HEIGHT = 630
PREVIEW_ROOT = PurePosixPath("social-previews")
MANAGED_START = "<!-- greenforest:share-metadata:start -->"
MANAGED_END = "<!-- greenforest:share-metadata:end -->"
SUPPORTED_IMAGE_SUFFIXES = {".gif", ".jpeg", ".jpg", ".png", ".webp"}

MANAGED_BLOCK_RE = re.compile(
    r"[ \t]*<!--\s*greenforest:share-metadata:start\s*-->.*?"
    r"<!--\s*greenforest:share-metadata:end\s*-->[ \t]*(?:\r\n|\r|\n)?",
    re.IGNORECASE | re.DOTALL,
)
SOURCE_RE = re.compile(
    r"<!--\s*greenforest:preview-source:(.*?)\s*-->",
    re.IGNORECASE,
)
META_TAG_RE = re.compile(r"<meta\b[^>]*>", re.IGNORECASE | re.DOTALL)
META_LINE_RE = re.compile(
    r"(?im)^[ \t]*(?P<tag><meta\b[^>]*>)[ \t]*(?P<newline>\r?\n)?"
)
ANALYTICS_SCRIPT_RE = re.compile(
    r"<script\b(?=[^>]*\bsrc\s*=\s*['\"]/?site-analytics\.js['\"])[^>]*>"
    r"\s*</script>",
    re.IGNORECASE | re.DOTALL,
)
ANALYTICS_SCRIPT_LINE_RE = re.compile(
    r"(?im)^[ \t]*(?P<tag><script\b(?=[^>]*\bsrc\s*=\s*['\"]/?site-analytics\.js['\"])[^>]*>"
    r"\s*</script>)[ \t]*(?P<newline>\r?\n)?"
)
ATTR_RE = re.compile(
    r"([:\w-]+)\s*=\s*(?:\"([^\"]*)\"|'([^']*)'|([^\s>]+))",
    re.DOTALL,
)


def normalize_text(value: str) -> str:
    normalized = " ".join(html_module.unescape(value).split())
    return re.sub(r"\s+([,.;:!?])", r"\1", normalized)


def truncate_words(value: str, limit: int) -> str:
    value = normalize_text(value)
    if len(value) <= limit:
        return value
    shortened = value[: limit + 1].rsplit(" ", 1)[0].rstrip(" ,.;:-")
    return (shortened or value[:limit].rstrip()) + "…"


def tag_attributes(tag: str) -> dict[str, str]:
    attributes: dict[str, str] = {}
    for match in ATTR_RE.finditer(tag):
        value = next(group for group in match.groups()[1:] if group is not None)
        attributes[match.group(1).lower()] = html_module.unescape(value)
    return attributes


def is_managed_meta(tag: str) -> bool:
    attributes = tag_attributes(tag)
    property_name = attributes.get("property", "").lower()
    name = attributes.get("name", "").lower()
    return property_name.startswith("og:image") or name in {
        "twitter:card",
        "twitter:image",
        "twitter:image:alt",
    }


def strip_managed_markup(document: str) -> str:
    head_open = re.search(r"<head\b[^>]*>", document, re.IGNORECASE)
    head_close = re.search(r"</head\s*>", document, re.IGNORECASE)
    if not head_open or not head_close or head_open.end() > head_close.start():
        return document

    prefix = document[: head_open.end()]
    head = document[head_open.end() : head_close.start()]
    suffix = document[head_close.start() :]
    head = MANAGED_BLOCK_RE.sub("", head)

    def remove_meta_line(match: re.Match[str]) -> str:
        return "" if is_managed_meta(match.group("tag")) else match.group(0)

    head = META_LINE_RE.sub(remove_meta_line, head)
    head = META_TAG_RE.sub(
        lambda match: "" if is_managed_meta(match.group(0)) else match.group(0),
        head,
    )
    head = ANALYTICS_SCRIPT_LINE_RE.sub("", head)
    head = ANALYTICS_SCRIPT_RE.sub("", head)
    return prefix + head + suffix


@dataclass
class PageInfo:
    title_parts: list[str] = field(default_factory=list)
    title_depth: int = 0
    paragraph_parts: list[str] = field(default_factory=list)
    paragraph_depth: int = 0
    first_paragraph: str = ""
    canonical: str = ""
    meta_names: dict[str, str] = field(default_factory=dict)
    meta_properties: dict[str, str] = field(default_factory=dict)
    media_sources: list[str] = field(default_factory=list)
    has_article_element: bool = False

    @property
    def title(self) -> str:
        return normalize_text(" ".join(self.title_parts))


class PageParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.info = PageInfo()

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        name = tag.lower()
        attributes = {key.lower(): value or "" for key, value in attrs}
        if name == "title":
            self.info.title_depth += 1
        elif name == "p" and not self.info.first_paragraph:
            self.info.paragraph_depth += 1
        elif name == "meta":
            content = attributes.get("content", "")
            meta_name = attributes.get("name", "").lower()
            meta_property = attributes.get("property", "").lower()
            if meta_name and meta_name not in self.info.meta_names:
                self.info.meta_names[meta_name] = content
            if meta_property and meta_property not in self.info.meta_properties:
                self.info.meta_properties[meta_property] = content
        elif name == "link" and "canonical" in attributes.get("rel", "").lower().split():
            if not self.info.canonical:
                self.info.canonical = attributes.get("href", "")
        elif name == "img":
            source = attributes.get("src", "")
            if source:
                self.info.media_sources.append(source)
        elif name == "video":
            poster = attributes.get("poster", "")
            if poster:
                self.info.media_sources.append(poster)
        elif name == "article":
            self.info.has_article_element = True

    def handle_startendtag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        self.handle_starttag(tag, attrs)

    def handle_endtag(self, tag: str) -> None:
        name = tag.lower()
        if name == "title" and self.info.title_depth:
            self.info.title_depth -= 1
        elif name == "p" and self.info.paragraph_depth:
            self.info.paragraph_depth -= 1
            if not self.info.paragraph_depth and not self.info.first_paragraph:
                self.info.first_paragraph = normalize_text(" ".join(self.info.paragraph_parts))

    def handle_data(self, data: str) -> None:
        if self.info.title_depth:
            self.info.title_parts.append(data)
        elif self.info.paragraph_depth and not self.info.first_paragraph:
            self.info.paragraph_parts.append(data)


def parse_page(document: str) -> PageInfo:
    parser = PageParser()
    parser.feed(document)
    parser.close()
    return parser.info


def tracked_files(root: Path, pattern: str | None = None) -> list[str]:
    command = ["git", "-C", str(root), "ls-files"]
    if pattern:
        command.extend(["--", pattern])
    output = subprocess.check_output(command, text=True, encoding="utf-8")
    return [line.strip().replace("\\", "/") for line in output.splitlines() if line.strip()]


def page_url(relative_path: PurePosixPath) -> str:
    if relative_path.name.lower() == "index.html":
        parent = relative_path.parent.as_posix()
        url_path = "/" if parent == "." else f"/{parent}/"
    else:
        url_path = "/" + relative_path.as_posix()
    return SITE_ORIGIN + quote(url_path, safe="/-._~")


def absolute_site_url(value: str, fallback: str) -> str:
    if not value:
        return fallback
    return urljoin(SITE_ORIGIN + "/", value)


def preview_path(relative_path: PurePosixPath) -> PurePosixPath:
    return PREVIEW_ROOT / relative_path.with_suffix(".png")


def preview_url(relative_path: PurePosixPath) -> str:
    path = "/" + preview_path(relative_path).as_posix()
    return SITE_ORIGIN + quote(path, safe="/-._~")


def derive_og_type(info: PageInfo, relative_path: PurePosixPath) -> str:
    if info.has_article_element or "article:published_time" in info.meta_properties:
        return "article"
    if relative_path.parts and relative_path.parts[0] in {"blog", "linkedin-archive"}:
        return "article" if relative_path.name.lower() != "index.html" else "website"
    return "website"


def resolve_local_image(
    root: Path,
    page_path: PurePosixPath,
    value: str,
    tracked: set[str],
) -> str | None:
    if not value or value.startswith(("data:", "blob:")):
        return None
    parsed = urlparse(value)
    if parsed.scheme and parsed.scheme not in {"http", "https"}:
        return None
    if parsed.netloc and parsed.netloc.lower() not in {"greenforest.io", "www.greenforest.io"}:
        return None
    raw_path = unquote(parsed.path)
    if not raw_path:
        return None
    if raw_path.startswith("/"):
        candidate = PurePosixPath(raw_path.lstrip("/"))
    else:
        candidate = page_path.parent / PurePosixPath(raw_path)
    normalized = PurePosixPath(*[part for part in candidate.parts if part not in {"", "."}])
    if ".." in normalized.parts:
        return None
    normalized_text = normalized.as_posix()
    if normalized.suffix.lower() not in SUPPORTED_IMAGE_SUFFIXES:
        return None
    if normalized_text not in tracked:
        return None
    if normalized.name.lower() in {"favicon.png", "favicon.ico", "logo.png"}:
        return None
    if normalized.parts and normalized.parts[0] == PREVIEW_ROOT.name:
        return None
    image_path = root / Path(*normalized.parts)
    try:
        with Image.open(image_path) as image:
            if image.width < 200 or image.height < 180:
                return None
    except (OSError, ValueError):
        return None
    return normalized_text


def choose_preview_source(
    root: Path,
    relative_path: PurePosixPath,
    original_info: PageInfo,
    original_document: str,
    tracked: set[str],
    refresh_sources: bool,
) -> str | None:
    source_match = SOURCE_RE.search(original_document)
    if source_match and not refresh_sources:
        saved = source_match.group(1).strip()
        if saved.lower() == "none":
            return None
        resolved = resolve_local_image(root, relative_path, "/" + saved, tracked)
        if resolved:
            return resolved

    candidates: list[str] = []
    existing_og_image = original_info.meta_properties.get("og:image", "")
    if existing_og_image:
        candidates.append(existing_og_image)
    if relative_path.name.lower() != "index.html":
        candidates.extend(original_info.media_sources)

    for candidate in candidates:
        resolved = resolve_local_image(root, relative_path, candidate, tracked)
        if resolved:
            return resolved
    return None


def document_newline(document: str) -> str:
    lf_count = document.count("\n")
    crlf_count = document.count("\r\n")
    return "\r\n" if lf_count and crlf_count * 2 >= lf_count else "\n"


def insert_share_metadata(
    document: str,
    relative_path: PurePosixPath,
    source_path: str | None,
) -> tuple[str, str, str]:
    stripped = strip_managed_markup(document)
    info = parse_page(stripped)
    title = info.meta_properties.get("og:title") or info.title or relative_path.stem
    title = normalize_text(title)
    fallback_url = page_url(relative_path)
    canonical = absolute_site_url(info.canonical, fallback_url)
    og_url = absolute_site_url(info.meta_properties.get("og:url", ""), canonical)
    description = (
        info.meta_properties.get("og:description")
        or info.meta_names.get("description")
        or info.first_paragraph
        or f"{title} on Greenforest I/O."
    )
    description = truncate_words(description, 220)
    og_type = info.meta_properties.get("og:type") or derive_og_type(info, relative_path)
    image = preview_url(relative_path)
    image_alt = truncate_words(f"{title} - Greenforest I/O share preview", 240)

    attributes = lambda value: html_module.escape(value, quote=True)
    lines: list[str] = [MANAGED_START]
    lines.append(f"<!-- greenforest:preview-source:{attributes(source_path or 'none')} -->")
    if "robots" not in info.meta_names:
        lines.append('<meta name="robots" content="index, follow, max-image-preview:large">')
    if "description" not in info.meta_names:
        lines.append(f'<meta name="description" content="{attributes(description)}">')
    if not info.canonical:
        lines.append(f'<link rel="canonical" href="{attributes(canonical)}">')
    if "og:site_name" not in info.meta_properties:
        lines.append('<meta property="og:site_name" content="Greenforest I/O">')
    if "og:title" not in info.meta_properties:
        lines.append(f'<meta property="og:title" content="{attributes(title)}">')
    if "og:description" not in info.meta_properties:
        lines.append(f'<meta property="og:description" content="{attributes(description)}">')
    if "og:type" not in info.meta_properties:
        lines.append(f'<meta property="og:type" content="{attributes(og_type)}">')
    if "og:url" not in info.meta_properties:
        lines.append(f'<meta property="og:url" content="{attributes(og_url)}">')
    lines.extend(
        [
            f'<meta property="og:image" content="{attributes(image)}">',
            f'<meta property="og:image:secure_url" content="{attributes(image)}">',
            '<meta property="og:image:type" content="image/png">',
            f'<meta property="og:image:width" content="{PREVIEW_WIDTH}">',
            f'<meta property="og:image:height" content="{PREVIEW_HEIGHT}">',
            f'<meta property="og:image:alt" content="{attributes(image_alt)}">',
            '<meta name="twitter:card" content="summary_large_image">',
            f'<meta name="twitter:image" content="{attributes(image)}">',
            f'<meta name="twitter:image:alt" content="{attributes(image_alt)}">',
            '<script src="/site-analytics.js" defer></script>',
            MANAGED_END,
        ]
    )

    head_open = re.search(r"<head\b[^>]*>", stripped, re.IGNORECASE)
    head_close = re.search(r"</head\s*>", stripped, re.IGNORECASE)
    if not head_open or not head_close or head_open.end() > head_close.start():
        raise ValueError(f"Could not locate a valid head in {relative_path.as_posix()}")

    head_body = stripped[head_open.end() : head_close.start()]
    script_match = re.search(r"(?im)^[ \t]*<script\b", head_body)
    insertion = head_open.end() + (script_match.start() if script_match else len(head_body))
    indent_match = re.search(r"(?im)^([ \t]*)<title\b", head_body)
    indent = indent_match.group(1) if indent_match else "    "
    newline = document_newline(stripped)
    block = newline.join(indent + line for line in lines) + newline
    if insertion and not stripped[:insertion].endswith(("\n", "\r")):
        block = newline + block
    updated = stripped[:insertion] + block + stripped[insertion:]
    return updated, title, canonical


def load_font(root: Path, filename: str, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(str(root / "fonts" / filename), size=size)


def split_long_word(
    draw: ImageDraw.ImageDraw,
    word: str,
    font: ImageFont.FreeTypeFont,
    maximum_width: int,
) -> list[str]:
    pieces: list[str] = []
    remaining = word
    while remaining:
        low, high = 1, len(remaining)
        while low < high:
            middle = (low + high + 1) // 2
            if draw.textlength(remaining[:middle], font=font) <= maximum_width:
                low = middle
            else:
                high = middle - 1
        pieces.append(remaining[:low])
        remaining = remaining[low:]
    return pieces


def wrap_title(
    draw: ImageDraw.ImageDraw,
    title: str,
    font: ImageFont.FreeTypeFont,
    maximum_width: int,
) -> list[str]:
    words: list[str] = []
    for word in title.split():
        if draw.textlength(word, font=font) > maximum_width:
            words.extend(split_long_word(draw, word, font, maximum_width))
        else:
            words.append(word)
    lines: list[str] = []
    current = ""
    for word in words:
        candidate = word if not current else current + " " + word
        if current and draw.textlength(candidate, font=font) > maximum_width:
            lines.append(current)
            current = word
        else:
            current = candidate
    if current:
        lines.append(current)
    return lines


def fit_title(
    draw: ImageDraw.ImageDraw,
    root: Path,
    title: str,
    maximum_width: int,
    maximum_height: int,
) -> tuple[ImageFont.FreeTypeFont, list[str], int, bool]:
    for size in range(64, 29, -2):
        font = load_font(root, "eb-garamond-400-latin.woff2", size)
        lines = wrap_title(draw, title, font, maximum_width)
        spacing = max(6, round(size * 0.12))
        line_height = draw.textbbox((0, 0), "Ag", font=font)[3]
        height = len(lines) * line_height + max(0, len(lines) - 1) * spacing
        if len(lines) <= 6 and height <= maximum_height:
            return font, lines, spacing, False

    font = load_font(root, "eb-garamond-400-latin.woff2", 30)
    lines = wrap_title(draw, title, font, maximum_width)
    truncated = len(lines) > 6
    lines = lines[:6]
    if truncated and lines:
        last = lines[-1]
        while last and draw.textlength(last + "…", font=font) > maximum_width:
            last = last[:-1].rstrip()
        lines[-1] = last + "…"
    return font, lines, 6, truncated


def crop_source_image(path: Path, size: tuple[int, int]) -> Image.Image:
    with Image.open(path) as opened:
        if getattr(opened, "is_animated", False):
            opened.seek(0)
        source = ImageOps.exif_transpose(opened).convert("RGB")
    return ImageOps.fit(source, size, method=Image.Resampling.LANCZOS, centering=(0.5, 0.5))


def draw_network_pattern(draw: ImageDraw.ImageDraw, title: str) -> None:
    seed = int.from_bytes(hashlib.sha256(title.encode("utf-8")).digest()[:8], "big")
    generator = random.Random(seed)
    nodes: list[tuple[int, int]] = []
    for _ in range(20):
        nodes.append((generator.randint(690, 1160), generator.randint(95, 560)))
    for index, point in enumerate(nodes):
        candidates = sorted(
            (other for other in nodes if other != point),
            key=lambda other: (other[0] - point[0]) ** 2 + (other[1] - point[1]) ** 2,
        )
        for other in candidates[: 1 + (index % 2)]:
            draw.line((point, other), fill=(27, 77, 62), width=3)
    for x, y in nodes:
        radius = generator.choice((5, 7, 9))
        draw.ellipse((x - radius, y - radius, x + radius, y + radius), fill=(38, 111, 83))
        draw.ellipse((x - 2, y - 2, x + 2, y + 2), fill=(195, 220, 176))


def shortened_display_url(canonical: str, limit: int = 82) -> str:
    parsed = urlparse(canonical)
    value = "greenforest.io" + (parsed.path or "/")
    if len(value) <= limit:
        return value
    parts = [part for part in (parsed.path or "/").split("/") if part]
    if len(parts) > 1:
        prefix = f"greenforest.io/{parts[0]}/…/"
        remaining = max(12, limit - len(prefix))
        filename = parts[-1]
        if len(filename) > remaining:
            filename = filename[: remaining - 1].rstrip("-_.") + "…"
        return prefix + filename
    prefix = "greenforest.io/"
    remaining = max(12, limit - len(prefix))
    filename = parts[0] if parts else ""
    return prefix + filename[: remaining - 1].rstrip("-_.") + "…"


def render_preview(
    root: Path,
    title: str,
    canonical: str,
    source_path: str | None,
) -> tuple[bytes, bool, bool]:
    canvas = Image.new("RGB", (PREVIEW_WIDTH, PREVIEW_HEIGHT), (7, 27, 22))
    draw = ImageDraw.Draw(canvas)

    for y in range(PREVIEW_HEIGHT):
        ratio = y / max(1, PREVIEW_HEIGHT - 1)
        color = (
            round(7 + 4 * ratio),
            round(27 + 18 * ratio),
            round(22 + 10 * ratio),
        )
        draw.line((0, y, PREVIEW_WIDTH, y), fill=color)
    for x in range(0, PREVIEW_WIDTH, 48):
        draw.line((x, 0, x, PREVIEW_HEIGHT), fill=(11, 43, 34), width=1)
    for y in range(0, PREVIEW_HEIGHT, 48):
        draw.line((0, y, PREVIEW_WIDTH, y), fill=(11, 43, 34), width=1)

    use_source = bool(source_path and len(title) <= 96)
    source_start = 770
    if use_source and source_path:
        try:
            source = crop_source_image(root / Path(*PurePosixPath(source_path).parts), (430, PREVIEW_HEIGHT))
            canvas.paste(source, (source_start, 0))
            overlay = Image.new("RGBA", (430, PREVIEW_HEIGHT), (5, 24, 19, 68))
            canvas.paste(overlay, (source_start, 0), overlay)
            fade = Image.new("RGBA", (150, PREVIEW_HEIGHT), (0, 0, 0, 0))
            fade_draw = ImageDraw.Draw(fade)
            for x in range(150):
                alpha = round(238 * (1 - x / 149))
                fade_draw.line((x, 0, x, PREVIEW_HEIGHT), fill=(7, 27, 22, alpha))
            canvas.paste(fade, (source_start, 0), fade)
            draw = ImageDraw.Draw(canvas)
        except (OSError, ValueError):
            use_source = False
    if not use_source:
        draw_network_pattern(draw, title)

    draw.rectangle((0, 0, 18, PREVIEW_HEIGHT), fill=(40, 116, 75))
    draw.rectangle((18, 0, 24, PREVIEW_HEIGHT), fill=(181, 210, 160))

    logo_path = root / "logo.png"
    with Image.open(logo_path) as opened_logo:
        logo = opened_logo.convert("RGBA").resize((92, 92), Image.Resampling.LANCZOS)
    canvas.paste(logo, (66, 46), logo)

    brand_font = load_font(root, "inconsolata-400-latin.woff2", 31)
    byline_font = load_font(root, "inconsolata-400-latin.woff2", 19)
    draw.text((177, 61), "greenforest.io", font=brand_font, fill=(244, 242, 232))
    draw.text(
        (179, 104),
        "RESEARCH / INVENTION / ARTIFACTS",
        font=byline_font,
        fill=(181, 210, 160),
    )
    title_limit = 650 if use_source else 1035
    draw.line((70, 164, 70 + title_limit, 164), fill=(40, 116, 75), width=4)

    title_font, title_lines, spacing, truncated = fit_title(
        draw,
        root,
        title,
        title_limit,
        340,
    )
    y = 199
    line_height = draw.textbbox((0, 0), "Ag", font=title_font)[3]
    for line in title_lines:
        draw.text(
            (70, y),
            line,
            font=title_font,
            fill=(248, 246, 238),
            stroke_width=1,
            stroke_fill=(248, 246, 238),
        )
        y += line_height + spacing

    path_font = load_font(root, "inconsolata-400-latin.woff2", 21)
    display_url = shortened_display_url(canonical)
    draw.text((70, 577), display_url, font=path_font, fill=(181, 210, 160))
    draw.line((70, 562, 356, 562), fill=(40, 116, 75), width=2)

    quantized = canvas.quantize(
        colors=256,
        method=Image.Quantize.MEDIANCUT,
        dither=Image.Dither.FLOYDSTEINBERG,
    )
    output = io.BytesIO()
    quantized.save(output, format="PNG", optimize=True, compress_level=9)
    return output.getvalue(), use_source, truncated


def write_or_compare(path: Path, expected: bytes, check: bool) -> bool:
    actual = path.read_bytes() if path.exists() else None
    if actual == expected:
        return False
    if not check:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(expected)
    return True


def build(args: argparse.Namespace) -> int:
    root = args.root.resolve()
    html_files = tracked_files(root, "*.html")
    tracked = set(tracked_files(root))
    if not html_files:
        raise SystemExit(f"No tracked HTML files found under {root}")

    changed_html: list[str] = []
    changed_previews: list[str] = []
    source_cards = 0
    truncated_cards: list[str] = []
    maximum_size = 0

    for relative_text in html_files:
        relative_path = PurePosixPath(relative_text)
        html_path = root / Path(*relative_path.parts)
        original_bytes = html_path.read_bytes()
        original_document = original_bytes.decode("utf-8")
        original_info = parse_page(original_document)
        source_path = choose_preview_source(
            root,
            relative_path,
            original_info,
            original_document,
            tracked,
            args.refresh_sources,
        )
        updated_document, title, canonical = insert_share_metadata(
            original_document,
            relative_path,
            source_path,
        )
        updated_bytes = updated_document.encode("utf-8")
        if write_or_compare(html_path, updated_bytes, args.check):
            changed_html.append(relative_text)

        if args.html_only:
            continue
        preview_bytes, used_source, truncated = render_preview(
            root,
            title,
            canonical,
            source_path,
        )
        if used_source:
            source_cards += 1
        if truncated:
            truncated_cards.append(relative_text)
        maximum_size = max(maximum_size, len(preview_bytes))
        output_relative = preview_path(relative_path)
        output_path = root / Path(*output_relative.parts)
        if write_or_compare(output_path, preview_bytes, args.check):
            changed_previews.append(output_relative.as_posix())
        if len(preview_bytes) >= 5_000_000:
            raise ValueError(f"Preview exceeds LinkedIn's 5 MB limit: {output_relative}")

    print(f"pages={len(html_files)}")
    print(f"changed_html={len(changed_html)}")
    if not args.html_only:
        print(f"changed_previews={len(changed_previews)}")
        print(f"source_cards={source_cards}")
        print(f"largest_preview_bytes={maximum_size}")
        print(f"truncated_titles={len(truncated_cards)}")
    if changed_html:
        print("HTML differences:")
        print("\n".join(f"  {path}" for path in changed_html))
    if changed_previews:
        print("Preview differences:")
        print("\n".join(f"  {path}" for path in changed_previews))
    if truncated_cards:
        print("Truncated preview titles:", file=sys.stderr)
        print("\n".join(f"  {path}" for path in truncated_cards), file=sys.stderr)

    if args.check and (changed_html or changed_previews or truncated_cards):
        return 1
    return 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    default_root = Path(__file__).resolve().parent.parent
    parser.add_argument("--root", type=Path, default=default_root)
    parser.add_argument("--check", action="store_true", help="report drift without writing")
    parser.add_argument("--html-only", action="store_true", help="skip preview rendering")
    parser.add_argument(
        "--refresh-sources",
        action="store_true",
        help="reselect source artwork instead of using the saved source marker",
    )
    return parser.parse_args()


if __name__ == "__main__":
    try:
        raise SystemExit(build(parse_args()))
    except (OSError, subprocess.CalledProcessError, ValueError) as error:
        print(f"error: {error}", file=sys.stderr)
        raise SystemExit(2) from error
