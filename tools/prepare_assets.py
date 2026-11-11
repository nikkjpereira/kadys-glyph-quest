#!/usr/bin/env python3
"""Download open-license fonts and generate an Android app icon. No third-party libs."""
from pathlib import Path
from urllib.request import Request, urlopen
import struct
import zlib

ROOT = Path(__file__).resolve().parents[1]
FONTS = ROOT / "assets" / "fonts"
BASE = "https://raw.githubusercontent.com/google/fonts/main/ofl/"
SOURCES = {
    "NotoSansRunic-Regular.ttf": "notosansrunic/NotoSansRunic-Regular.ttf",
    "NotoSansEgyptianHieroglyphs-Regular.ttf": "notosansegyptianhieroglyphs/NotoSansEgyptianHieroglyphs-Regular.ttf",
    "NotoSansJP.ttf": "notosansjp/NotoSansJP%5Bwght%5D.ttf",
    "NotoSansKR.ttf": "notosanskr/NotoSansKR%5Bwght%5D.ttf",
}
LICENSE_FOLDERS = [
    "notosansrunic", "notosansegyptianhieroglyphs", "notosansjp", "notosanskr"
]


def fetch(url: str, path: Path) -> None:
    if path.exists() and path.stat().st_size > 100:
        return
    print("Fetching", path.name, flush=True)
    req = Request(url, headers={"User-Agent": "KadyGlyphQuest-Builder/0.1"})
    with urlopen(req, timeout=120) as resp:
        contents = resp.read()
    if len(contents) < 100:
        raise ValueError("Download was suspiciously small: " + url)
    path.write_bytes(contents)


def png_chunk(name: bytes, payload: bytes) -> bytes:
    data = name + payload
    return struct.pack(">I", len(payload)) + data + struct.pack(">I", zlib.crc32(data) & 0xffffffff)


def make_icon() -> None:
    width = height = 432
    scanlines = []
    for y in range(height):
        scan = bytearray([0])
        for x in range(width):
            r, g, b = 35 + y // 30, 23 + y // 52, 69 + y // 22
            ring = (x < 11 or x > 420 or y < 11 or y > 420)
            vertical = (100 <= x <= 135 and 78 <= y <= 353)
            diagonal_upper = (x >= 121 and x <= 342 and y <= 260 and abs((x - 122) + (y - 225) * 0.94) < 19)
            diagonal_lower = (x >= 121 and x <= 342 and y >= 206 and abs((x - 122) - (y - 225) * 0.94) < 19)
            if ring or vertical or diagonal_upper or diagonal_lower:
                r, g, b = 242, 203, 124
            scan.extend((min(r, 255), min(g, 255), min(b, 255), 255))
        scanlines.append(scan)
    chunks = b"".join(scanlines)
    data = b"\x89PNG\r\n\x1a\n"
    data += png_chunk(b"IHDR", struct.pack(">2I5B", width, height, 8, 6, 0, 0, 0))
    data += png_chunk(b"IDAT", zlib.compress(chunks, level=8))
    data += png_chunk(b"IEND", b"")
    out = ROOT / "assets" / "icon.png"
    out.write_bytes(data)
    print("Created", out)


def main() -> None:
    FONTS.mkdir(parents=True, exist_ok=True)
    for name, source in SOURCES.items():
        fetch(BASE + source, FONTS / name)
    for folder in LICENSE_FOLDERS:
        fetch(BASE + folder + "/OFL.txt", FONTS / (folder + "-OFL.txt"))
    make_icon()


if __name__ == "__main__":
    main()
