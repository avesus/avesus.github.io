#!/usr/bin/env python3
"""Verify release hashes and the machine-readable multiplier result invariants."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "SHA256SUMS.txt"
CORE_RTL_SHA256 = "9d53834bb565e1c29d87eafa79b3a8cc606c4a4ef51c9a6acdf6f90e800d3d9a"
LOGISIM_SHA256 = "3317a9e721381e927b2fd307e1fd4b2139ab05036ef2cbea2129e36f2a74c597"
BITSTREAM_SHA256 = "38f51f3ba5067390b1208ad881212acd287996a869a837048f6280db1d335988"


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def read_json(relative_path: str) -> dict[str, object]:
    return json.loads((ROOT / relative_path).read_text(encoding="utf-8"))


def only_clock(report: dict[str, object]) -> dict[str, object]:
    clocks = report["fmax"]
    assert isinstance(clocks, dict) and len(clocks) == 1
    clock = next(iter(clocks.values()))
    assert isinstance(clock, dict)
    return clock


def verify_manifest() -> int:
    checked = 0
    for line_number, line in enumerate(MANIFEST.read_text(encoding="utf-8").splitlines(), 1):
        if not line:
            continue
        digest, separator, relative_name = line.partition("  ")
        if not separator or len(digest) != 64:
            raise ValueError(f"invalid manifest line {line_number}")
        relative_path = Path(relative_name)
        if relative_path.is_absolute() or ".." in relative_path.parts:
            raise ValueError(f"unsafe manifest path on line {line_number}")
        path = ROOT / relative_path
        actual = sha256_file(path)
        if actual != digest:
            raise ValueError(f"hash mismatch for {relative_name}: {actual} != {digest}")
        checked += 1
    return checked


def verify_results() -> None:
    if sha256_file(ROOT / "rtl/gf_logisim_mul64_low_full_retime.sv") != CORE_RTL_SHA256:
        raise ValueError("core RTL hash mismatch")
    if sha256_file(ROOT / "logisim/serial_july_2025.circ") != LOGISIM_SHA256:
        raise ValueError("Logisim circuit hash mismatch")
    if sha256_file(ROOT / "bitstream/design.bin") != BITSTREAM_SHA256:
        raise ValueError("bitstream hash mismatch")

    core = read_json("reports/core-nextpnr-report.json")
    core_lc = core["utilization"]["ICESTORM_LC"]  # type: ignore[index]
    assert core_lc == {"used": 637, "available": 7680}
    core_clock = only_clock(core)
    assert core_clock["achieved"] == 438.21209716796875
    assert core_clock["constraint"] == 432

    bank12 = read_json("reports/bank12-nextpnr-report.json")
    bank12_lc = bank12["utilization"]["ICESTORM_LC"]  # type: ignore[index]
    assert bank12_lc == {"used": 7622, "available": 7680}
    bank12_clock = only_clock(bank12)
    assert bank12_clock["achieved"] == 376.9317626953125
    assert bank12_clock["constraint"] == 216

    bank13_log = (ROOT / "reports/bank13-nextpnr.log").read_text(encoding="utf-8")
    assert "ICESTORM_LC:  8257/ 7680" in bank13_log
    assert "no BELs remaining" in bank13_log
    assert "1 warning, 1 error" in bank13_log

    total_vectors = 0
    for name in (
        "mul64_low_full_retime_mux_216_physical_20260728.json",
        "mul64_low_full_retime_mux_216_physical_repeat_20260728.json",
    ):
        evidence = read_json(f"evidence/{name}")
        assert evidence["status"] == "PASS"
        assert evidence["bitstream_sha256"] == BITSTREAM_SHA256
        assert evidence["decoded_vector_count"] == 4096
        assert evidence["arithmetic_mismatch_count"] == 0
        assert evidence["selected_pair_slot_disagreement_count"] == 0
        total_vectors += int(evidence["decoded_vector_count"])
    assert total_vectors == 8192


def main() -> int:
    checked = verify_manifest()
    verify_results()
    print(f"PASS: {checked} payload hashes and all published multiplier invariants")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
