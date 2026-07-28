#!/usr/bin/env python3
"""Physically verify the continuously running 216 MHz low-64 multiplier."""

from __future__ import annotations

import argparse
import hashlib
import json
import random
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

PROJECT_DIR = Path(__file__).resolve().parents[1]
HOST_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(HOST_DIR))

from benchmark_mpsse30_echo_d2xx import D2xx, Mpsse30, select_channel_b  # noqa: E402


WORD_BITS = 64
WORD_MASK = (1 << WORD_BITS) - 1
REPEATS = 4
WARMUP_FRAMES = 8
CURATED = [
    (48, 3),
    (56, 3),
    (7, 31),
    (0, WORD_MASK),
    (1, WORD_MASK),
    (WORD_MASK, 1),
    (0xFFFFFFFF, 0xFFFFFFFF),
    (0x8000000000000000, 1),
    (0x7FFFFFFFFFFFFFFF, 2),
    (0x100000000, 0xFFFFFFFF),
    (0x12345678, 0xFEDCBA98),
]


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def make_vectors(count: int, seed: int) -> list[tuple[int, int]]:
    if count < len(CURATED):
        raise ValueError(f"--vectors must be at least {len(CURATED)}")
    rng = random.Random(seed)
    vectors = list(CURATED)
    while len(vectors) < count:
        selector = len(vectors) & 3
        if selector == 0:
            a_value, b_value = rng.getrandbits(32), rng.getrandbits(32)
        elif selector == 1:
            a_value, b_value = rng.getrandbits(64), 1
        elif selector == 2:
            a_value, b_value = 1, rng.getrandbits(64)
        else:
            a_bits = rng.randrange(1, 64)
            a_value = rng.getrandbits(a_bits)
            b_value = rng.getrandbits(64 - a_bits)
        if a_value * b_value <= WORD_MASK:
            vectors.append((a_value, b_value))
    return vectors


def encode_frame(a_value: int, b_value: int) -> bytes:
    result = bytearray(16)
    for byte_index in range(16):
        packed = 0
        for pair_in_byte in range(4):
            bit_index = 4 * byte_index + pair_in_byte
            packed |= ((a_value >> bit_index) & 1) << (7 - 2 * pair_in_byte)
            packed |= ((b_value >> bit_index) & 1) << (6 - 2 * pair_in_byte)
        result[byte_index] = packed
    return bytes(result)


def decode_frame(frame: bytes) -> tuple[int, list[int]]:
    if len(frame) != 16:
        raise ValueError("a returned frame must contain 16 bytes")
    product = 0
    disagreements: list[int] = []
    for byte_index, byte_value in enumerate(frame):
        for pair_in_byte in range(4):
            bit_index = 4 * byte_index + pair_in_byte
            first = (byte_value >> (7 - 2 * pair_in_byte)) & 1
            second = (byte_value >> (6 - 2 * pair_in_byte)) & 1
            if first != second:
                disagreements.append(bit_index)
            product |= first << bit_index
    return product, disagreements


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--bitstream", type=Path, required=True)
    parser.add_argument("--expected-sha256", required=True)
    parser.add_argument("--vectors", type=int, default=4096)
    parser.add_argument("--seed", type=lambda v: int(v, 0), default=0x21664375)
    parser.add_argument("--chunk", type=int, default=65_536)
    parser.add_argument("--timeout", type=float, default=5.0)
    parser.add_argument("--report", type=Path, required=True)
    parser.add_argument("--serial")
    parser.add_argument("--location-id", type=lambda v: int(v, 0))
    parser.add_argument("--execute", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.report.exists():
        raise FileExistsError(f"refusing to overwrite report: {args.report}")

    bitstream = args.bitstream.read_bytes()
    bitstream_hash = digest(bitstream)
    if bitstream_hash.lower() != args.expected_sha256.lower():
        raise ValueError("bitstream hash mismatch")

    vectors = make_vectors(args.vectors, args.seed)
    expected = [a * b for a, b in vectors]
    frames = [(0, 0)] * WARMUP_FRAMES
    selected_frame_indices: list[int] = []
    for vector in vectors:
        frames.extend([vector] * REPEATS)
        selected_frame_indices.append(len(frames) - 1)
    frames.extend([vectors[-1]] * 2)
    outgoing = b"".join(encode_frame(a, b) for a, b in frames)

    plan = {
        "schema": "greenforest-serial-mul64-low216-mpsse/v1",
        "created_utc": utc_now(),
        "execute_requested": args.execute,
        "interface": "FT2232H channel B D2XX MPSSE SPI mode 0",
        "mpsse_sclk_hz": 30_000_000,
        "multiplier_clock_hz": 216_000_000,
        "multiplier_clock_edges_per_product": 64,
        "sustained_core_products_per_second": 3_375_000,
        "core_clock_enable_or_step_signals": 0,
        "word_bits": WORD_BITS,
        "result_bits": WORD_BITS,
        "result_semantics": "low 64 bits; generated vectors do not overflow",
        "vector_count": len(vectors),
        "vector_seed": args.seed,
        "usb_repetitions_per_vector": REPEATS,
        "warmup_frames": WARMUP_FRAMES,
        "wire_bytes": len(outgoing),
        "bitstream_sha256": bitstream_hash,
        "rf_out_n16_design_state": "unconditionally_high_impedance",
    }
    if not args.execute:
        plan["status"] = "DRY RUN - NO FTDI HANDLE OPENED"
        print(json.dumps(plan, indent=2))
        return 0

    d2xx = D2xx()
    channel = select_channel_b(d2xx.devices(), args.serial, args.location_id)
    link = Mpsse30(d2xx, channel["index"], int(args.timeout * 1000))
    received = b""
    elapsed = 0.0
    close_errors: list[str] = []
    primary_error: BaseException | None = None
    try:
        link.open()
        started = time.perf_counter()
        received = link.exchange(outgoing, args.chunk, args.timeout)
        elapsed = time.perf_counter() - started
    except BaseException as exc:
        primary_error = exc
    finally:
        close_errors = link.close()

    decoded: list[int] = []
    disagreements: list[dict[str, object]] = []
    if primary_error is None and len(received) == len(outgoing):
        returned_frames = [
            received[offset : offset + 16]
            for offset in range(0, len(received), 16)
        ]
        for vector_index, frame_index in enumerate(selected_frame_indices):
            product, pair_errors = decode_frame(returned_frames[frame_index])
            decoded.append(product)
            if pair_errors:
                disagreements.append(
                    {"vector_index": vector_index, "bit_indices": pair_errors}
                )

    mismatches = [
        index
        for index, (actual, wanted) in enumerate(zip(decoded, expected))
        if actual != wanted
    ]
    passed = (
        primary_error is None
        and not close_errors
        and len(decoded) == len(expected)
        and not disagreements
        and not mismatches
    )
    examples = []
    for index, (a_value, b_value) in enumerate(CURATED):
        if index >= len(decoded):
            break
        examples.append(
            {
                "a_hex": f"0x{a_value:016x}",
                "b_hex": f"0x{b_value:016x}",
                "expected_hex": f"0x{expected[index]:016x}",
                "received_hex": f"0x{decoded[index]:016x}",
                "match": expected[index] == decoded[index],
            }
        )

    report = {
        **plan,
        "completed_utc": utc_now(),
        "received_wire_bytes": len(received),
        "elapsed_seconds": elapsed,
        "effective_wire_bits_per_second": len(outgoing) * 8 / elapsed if elapsed else None,
        "outgoing_sha256": digest(outgoing),
        "received_sha256": digest(received),
        "decoded_vector_count": len(decoded),
        "selected_pair_slot_disagreement_count": len(disagreements),
        "arithmetic_mismatch_count": len(mismatches),
        "first_arithmetic_mismatch_indices": mismatches[:32],
        "curated_results": examples,
        "close_errors": close_errors,
        "error": f"{type(primary_error).__name__}: {primary_error}" if primary_error else None,
        "status": "PASS" if passed else "FAIL",
    }
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2), file=sys.stdout if passed else sys.stderr)
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
