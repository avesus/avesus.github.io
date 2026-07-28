#!/usr/bin/env python3
"""Physically verify the free-running 216 MHz serial binary32 divider.

The FPGA consumes one raw IEEE-754 binary32 numerator bit followed by one
denominator bit on every two MPSSE clocks.  Both records are LSB first.  MISO
returns each result bit twice so the host can check pair-slot coherence as well
as arithmetic correctness.

No FTDI handle is opened unless ``--execute`` is explicit.  Expected results
come from integer ratio arithmetic with round-to-nearest, ties-to-even; Python
or host hardware floating-point arithmetic is not used as the oracle.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import random
import string
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

PROJECT_DIR = Path(__file__).resolve().parents[1]
HOST_DIR = Path(__file__).resolve().parent
sys.path.insert(0, str(HOST_DIR))

from benchmark_mpsse30_echo_d2xx import D2xx, Mpsse30, select_channel_b  # noqa: E402


RECORD_BITS = 32
RECORD_BYTES = 8
RAW_MASK = (1 << RECORD_BITS) - 1
FRACTION_BITS = 23
FRACTION_MASK = (1 << FRACTION_BITS) - 1
EXPONENT_MASK = 0xFF
EXPONENT_BIAS = 127
MIN_NORMAL_EXPONENT = -126
MAX_NORMAL_EXPONENT = 127

MPSSE_SCLK_HZ = 30_000_000
DIVIDER_CLOCK_HZ = 216_000_000
MPSSE_EDGES_PER_PAIR_RECORD = 2 * RECORD_BITS
CORE_RECORDS_PER_USB_RECORD_NUMERATOR = 72
CORE_RECORDS_PER_USB_RECORD_DENOMINATOR = 5

DEFAULT_REPEATS = 8
DEFAULT_WARMUP_RECORDS = 16
DEFAULT_TAIL_RECORDS = 2
SAFE_PAIR = (0x3F800000, 0x3F800000)  # +1.0 / +1.0

# Raw binary32 values only.  Every operand and expected quotient is finite,
# normal, and nonzero.  The list deliberately spans signs, significand
# rounding, and the normal exponent range without requesting exception logic.
CURATED = [
    SAFE_PAIR,
    (0xBF800000, 0x3F800000),
    (0x3F800000, 0xBF800000),
    (0xBF800000, 0xBF800000),
    (0x3FC00000, 0x3FA00000),  # 1.5 / 1.25
    (0x3F800000, 0x40400000),  # 1 / 3
    (0x40000000, 0x40400000),  # 2 / 3
    (0x3F800000, 0x41200000),  # 1 / 10
    (0x3F800001, 0x3F800000),
    (0x3F800000, 0x3F800001),
    (0x00800000, 0x3F000000),  # minimum normal / 0.5
    (0x01000000, 0x40000000),  # twice minimum normal / 2
    (0x7F7FFFFF, 0x40000000),  # maximum normal / 2
    (0xFF7FFFFF, 0xC0000000),
    (0x7F7FFFFF, 0x7F7FFFFF),
    (0x00800000, 0x00800000),
    (0x00800001, 0x00800000),
    (0x00FFFFFF, 0x3F800000),
    # Physical regression set: each quotient is just above the RNE midpoint.
    # Before low32 per-lane truncation, folded high-product bits made every
    # one of these results exactly one ULP low on the FPGA.
    (0xB9BF7F44, 0x3D021BA8),
    (0x4682C64E, 0xD8BEA209),
    (0xC15DF06C, 0x6D6AFBA6),
    (0x6452B46F, 0xF8667CDF),
    (0x88EDBDC2, 0xAA0D525F),
    (0xE2023338, 0x4E293A2E),
    (0xB2206665, 0x10B072DE),
    (0x27E97FD7, 0x9546AFAB),
    (0xA7AB7E58, 0x927D0B09),
    (0x85657F1F, 0x021B1535),
]


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def is_finite_normal(raw: int) -> bool:
    """Return true exactly for a raw finite, normal binary32 value."""
    if not 0 <= raw <= RAW_MASK:
        return False
    exponent = (raw >> FRACTION_BITS) & EXPONENT_MASK
    return 1 <= exponent <= 254


def _normal_parts(raw: int) -> tuple[int, int, int]:
    """Return sign, 24-bit significand, and unbiased exponent."""
    if not is_finite_normal(raw):
        raise ValueError(f"operand 0x{raw & RAW_MASK:08x} is not finite normal")
    sign = raw >> 31
    exponent_field = (raw >> FRACTION_BITS) & EXPONENT_MASK
    significand = (1 << FRACTION_BITS) | (raw & FRACTION_MASK)
    return sign, significand, exponent_field - EXPONENT_BIAS


def _round_ratio_nearest_even(numerator: int, denominator: int) -> int:
    """Round a positive integer ratio to an integer, ties to even."""
    if numerator < 0 or denominator <= 0:
        raise ValueError("rounding ratio must have numerator >= 0 and denominator > 0")
    quotient, remainder = divmod(numerator, denominator)
    comparison = (remainder << 1) - denominator
    if comparison > 0 or (comparison == 0 and (quotient & 1)):
        quotient += 1
    return quotient


def _round_scaled_ratio(numerator: int, denominator: int, shift: int) -> int:
    """Round (numerator / denominator) * 2**shift exactly."""
    if shift >= 0:
        return _round_ratio_nearest_even(numerator << shift, denominator)
    return _round_ratio_nearest_even(numerator, denominator << -shift)


def _floor_log2_ratio(numerator: int, denominator: int) -> int:
    """Return floor(log2(numerator / denominator)) using integers only."""
    if numerator <= 0 or denominator <= 0:
        raise ValueError("log2 ratio inputs must be positive")
    result = numerator.bit_length() - denominator.bit_length()
    if result >= 0:
        if numerator < (denominator << result):
            result -= 1
    elif (numerator << -result) < denominator:
        result -= 1
    return result


def binary32_divide_rne(numerator_raw: int, denominator_raw: int) -> int:
    """Divide two finite-normal binary32 encodings with exact RNE rounding.

    The implementation also returns correctly signed zero, subnormal, or
    infinity encodings when the exact quotient leaves the controlled normal
    test domain.  Input zeros, subnormals, infinities, and NaNs are rejected.
    """
    numerator_sign, numerator_sig, numerator_exponent = _normal_parts(numerator_raw)
    denominator_sign, denominator_sig, denominator_exponent = _normal_parts(
        denominator_raw
    )
    sign_field = (numerator_sign ^ denominator_sign) << 31
    exponent_scale = numerator_exponent - denominator_exponent
    result_exponent = exponent_scale + _floor_log2_ratio(
        numerator_sig, denominator_sig
    )

    if result_exponent > MAX_NORMAL_EXPONENT:
        return sign_field | 0x7F800000

    if result_exponent < MIN_NORMAL_EXPONENT:
        # A binary32 subnormal stores units of 2**-149.
        subnormal = _round_scaled_ratio(
            numerator_sig, denominator_sig, exponent_scale + 149
        )
        if subnormal >= (1 << FRACTION_BITS):
            return sign_field | 0x00800000
        return sign_field | subnormal

    significand = _round_scaled_ratio(
        numerator_sig,
        denominator_sig,
        exponent_scale - result_exponent + FRACTION_BITS,
    )
    if significand == (1 << (FRACTION_BITS + 1)):
        significand >>= 1
        result_exponent += 1
        if result_exponent > MAX_NORMAL_EXPONENT:
            return sign_field | 0x7F800000

    exponent_field = result_exponent + EXPONENT_BIAS
    return sign_field | (exponent_field << FRACTION_BITS) | (
        significand & FRACTION_MASK
    )


def encode_record(numerator_raw: int, denominator_raw: int) -> bytes:
    """Encode two 32-bit LSB-first records as eight MSB-shifted MPSSE bytes."""
    if not 0 <= numerator_raw <= RAW_MASK or not 0 <= denominator_raw <= RAW_MASK:
        raise ValueError("record operands must be unsigned 32-bit integers")
    result = bytearray(RECORD_BYTES)
    for byte_index in range(RECORD_BYTES):
        packed = 0
        for pair_in_byte in range(4):
            bit_index = 4 * byte_index + pair_in_byte
            packed |= ((numerator_raw >> bit_index) & 1) << (7 - 2 * pair_in_byte)
            packed |= ((denominator_raw >> bit_index) & 1) << (6 - 2 * pair_in_byte)
        result[byte_index] = packed
    return bytes(result)


def decode_record(record: bytes) -> tuple[int, list[int]]:
    """Decode duplicated result slots and return disagreement bit indices."""
    if len(record) != RECORD_BYTES:
        raise ValueError(f"a returned record must contain {RECORD_BYTES} bytes")
    result = 0
    disagreements: list[int] = []
    for byte_index, byte_value in enumerate(record):
        for pair_in_byte in range(4):
            bit_index = 4 * byte_index + pair_in_byte
            first = (byte_value >> (7 - 2 * pair_in_byte)) & 1
            second = (byte_value >> (6 - 2 * pair_in_byte)) & 1
            if first != second:
                disagreements.append(bit_index)
            result |= first << bit_index
    return result, disagreements


def make_vectors(count: int, seed: int) -> list[tuple[int, int]]:
    """Build deterministic finite-normal tests whose quotients remain normal."""
    if count < len(CURATED):
        raise ValueError(f"--vectors must be at least {len(CURATED)}")
    for numerator_raw, denominator_raw in CURATED:
        if not is_finite_normal(numerator_raw) or not is_finite_normal(
            denominator_raw
        ):
            raise AssertionError("curated operand escaped the finite-normal domain")
        if not is_finite_normal(binary32_divide_rne(numerator_raw, denominator_raw)):
            raise AssertionError("curated quotient escaped the finite-normal domain")

    rng = random.Random(seed)
    vectors = list(CURATED)
    seen = set(vectors)
    while len(vectors) < count:
        numerator_raw = (
            (rng.getrandbits(1) << 31)
            | (rng.randrange(1, 255) << FRACTION_BITS)
            | rng.getrandbits(FRACTION_BITS)
        )
        denominator_raw = (
            (rng.getrandbits(1) << 31)
            | (rng.randrange(1, 255) << FRACTION_BITS)
            | rng.getrandbits(FRACTION_BITS)
        )
        pair = (numerator_raw, denominator_raw)
        if pair in seen:
            continue
        if not is_finite_normal(binary32_divide_rne(*pair)):
            continue
        seen.add(pair)
        vectors.append(pair)
    return vectors


def run_self_tests() -> dict[str, object]:
    """Exercise the pure exact oracle and wire codec without hardware."""
    rounding_cases = [
        (1, 2, 0),
        (3, 2, 2),
        (5, 2, 2),
        (7, 2, 4),
        (8, 3, 3),
        ((1 << 25) - 1, 2, 1 << 24),  # tie rounds up into a carry bit
    ]
    for numerator, denominator, expected in rounding_cases:
        actual = _round_ratio_nearest_even(numerator, denominator)
        assert actual == expected, (numerator, denominator, expected, actual)

    oracle_cases = [
        (0x3F800000, 0x3F800000, 0x3F800000),  # 1 / 1
        (0xBF800000, 0x3F800000, 0xBF800000),  # -1 / 1
        (0x3F800000, 0x40000000, 0x3F000000),  # 1 / 2
        (0x3F800000, 0x40400000, 0x3EAAAAAB),  # 1 / 3
        (0x40000000, 0x40400000, 0x3F2AAAAB),  # 2 / 3
        (0x3F800000, 0x41200000, 0x3DCCCCCD),  # 1 / 10
        (0x00800000, 0x3F000000, 0x01000000),  # min normal / .5
        (0x00800000, 0x40000000, 0x00400000),  # subnormal result
        (0x7F7FFFFF, 0x3F000000, 0x7F800000),  # overflow
    ]
    for numerator_raw, denominator_raw, expected in oracle_cases:
        actual = binary32_divide_rne(numerator_raw, denominator_raw)
        assert actual == expected, (
            f"0x{numerator_raw:08x}",
            f"0x{denominator_raw:08x}",
            f"0x{expected:08x}",
            f"0x{actual:08x}",
        )

    rejected_operands = [0x00000000, 0x00000001, 0x7F800000, 0x7FC00000]
    for invalid_raw in rejected_operands:
        try:
            binary32_divide_rne(invalid_raw, 0x3F800000)
        except ValueError:
            pass
        else:
            raise AssertionError(
                f"non-normal numerator 0x{invalid_raw:08x} was not rejected"
            )
    assert not is_finite_normal(
        binary32_divide_rne(0x00800000, 0x40000000)
    ), "subnormal quotient was incorrectly classified as normal"

    codec_cases = [
        SAFE_PAIR,
        (0x01234567, 0x89ABCDEF),
        (0xFFFFFFFF, 0x00000000),
    ]
    for numerator_raw, denominator_raw in codec_cases:
        encoded = encode_record(numerator_raw, denominator_raw)
        reconstructed_numerator = 0
        reconstructed_denominator = 0
        for byte_index, byte_value in enumerate(encoded):
            for pair_in_byte in range(4):
                bit_index = 4 * byte_index + pair_in_byte
                reconstructed_numerator |= (
                    (byte_value >> (7 - 2 * pair_in_byte)) & 1
                ) << bit_index
                reconstructed_denominator |= (
                    (byte_value >> (6 - 2 * pair_in_byte)) & 1
                ) << bit_index
        assert reconstructed_numerator == numerator_raw
        assert reconstructed_denominator == denominator_raw

    raw_result = 0xA5C33CA5
    duplicated = encode_record(raw_result, raw_result)
    decoded, disagreements = decode_record(duplicated)
    assert decoded == raw_result and not disagreements
    corrupted = bytearray(duplicated)
    corrupted[0] ^= 1 << 6
    decoded, disagreements = decode_record(bytes(corrupted))
    assert decoded == raw_result and disagreements == [0]

    generated = make_vectors(len(CURATED) + 64, 0x21632D1)
    assert all(is_finite_normal(a) and is_finite_normal(b) for a, b in generated)
    assert all(is_finite_normal(binary32_divide_rne(a, b)) for a, b in generated)
    return {
        "schema": "greenforest-serial-binary32-host-self-test/v1",
        "oracle_cases": len(oracle_cases),
        "ties_to_even_integer_cases": len(rounding_cases),
        "rounding_carry_cases": 1,
        "rejected_non_normal_operand_encodings": len(rejected_operands),
        "codec_cases": len(codec_cases) + 2,
        "generated_controlled_vectors": len(generated),
        "status": "PASS",
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--bitstream", type=Path)
    parser.add_argument("--expected-sha256")
    parser.add_argument("--vectors", type=int, default=4096)
    parser.add_argument("--seed", type=lambda value: int(value, 0), default=0x21632D1)
    parser.add_argument("--repeats", type=int, default=DEFAULT_REPEATS)
    parser.add_argument(
        "--warmup-records", type=int, default=DEFAULT_WARMUP_RECORDS
    )
    parser.add_argument("--tail-records", type=int, default=DEFAULT_TAIL_RECORDS)
    parser.add_argument("--chunk", type=int, default=65_536)
    parser.add_argument("--timeout", type=float, default=5.0)
    parser.add_argument("--report", type=Path)
    parser.add_argument("--serial")
    parser.add_argument("--location-id", type=lambda value: int(value, 0))
    parser.add_argument(
        "--execute",
        action="store_true",
        help="open FT2232H-B and perform the physical exchange",
    )
    parser.add_argument(
        "--self-test",
        action="store_true",
        help="test only the integer oracle and record codec, then exit",
    )
    return parser.parse_args()


def _validate_runtime_args(args: argparse.Namespace) -> tuple[Path, Path, str]:
    missing = [
        name
        for name, value in (
            ("--bitstream", args.bitstream),
            ("--expected-sha256", args.expected_sha256),
            ("--report", args.report),
        )
        if value is None
    ]
    if missing:
        raise ValueError(f"required unless --self-test: {', '.join(missing)}")
    assert args.bitstream is not None
    assert args.report is not None
    assert args.expected_sha256 is not None
    expected_hash = args.expected_sha256.lower()
    if len(expected_hash) != 64 or any(
        character not in string.hexdigits for character in expected_hash
    ):
        raise ValueError("--expected-sha256 must contain exactly 64 hexadecimal digits")
    if args.vectors < len(CURATED):
        raise ValueError(f"--vectors must be at least {len(CURATED)}")
    if args.repeats < 1:
        raise ValueError("--repeats must be positive")
    if args.warmup_records < 0 or args.tail_records < 0:
        raise ValueError("warmup and tail record counts cannot be negative")
    if not 1 <= args.chunk <= 65_536:
        raise ValueError("--chunk must be in 1..65536")
    if args.timeout <= 0:
        raise ValueError("--timeout must be positive")
    if args.report.exists():
        raise FileExistsError(f"refusing to overwrite report: {args.report}")
    return args.bitstream, args.report, expected_hash


def main() -> int:
    args = parse_args()
    if args.self_test:
        print(json.dumps(run_self_tests(), indent=2))
        return 0

    bitstream_path, report_path, expected_hash = _validate_runtime_args(args)
    bitstream = bitstream_path.read_bytes()
    bitstream_hash = digest(bitstream)
    if bitstream_hash.lower() != expected_hash:
        raise ValueError(
            f"bitstream hash mismatch: expected {expected_hash}, got {bitstream_hash}"
        )

    vectors = make_vectors(args.vectors, args.seed)
    expected = [binary32_divide_rne(numerator, denominator) for numerator, denominator in vectors]
    records = [SAFE_PAIR] * args.warmup_records
    selected_record_indices: list[int] = []
    for pair in vectors:
        records.extend([pair] * args.repeats)
        selected_record_indices.append(len(records) - 1)
    records.extend([vectors[-1]] * args.tail_records)
    outgoing = b"".join(encode_record(*pair) for pair in records)

    held_core_records_numerator = (
        args.repeats * CORE_RECORDS_PER_USB_RECORD_NUMERATOR
    )
    plan = {
        "schema": "greenforest-serial-binary32-div216-mpsse/v1",
        "created_utc": utc_now(),
        "execute_requested": bool(args.execute),
        "interface": "FT2232H channel B D2XX MPSSE SPI mode 0",
        "mpsse_sclk_hz": MPSSE_SCLK_HZ,
        "divider_clock_hz": DIVIDER_CLOCK_HZ,
        "record_format": "raw IEEE-754 binary32, fraction/exponent/sign LSB first",
        "input_pair_order": "numerator bit then denominator bit for bit indices 0..31",
        "mpsse_edges_per_input_pair_record": MPSSE_EDGES_PER_PAIR_RECORD,
        "wire_bytes_per_input_pair_record": RECORD_BYTES,
        "divider_clock_edges_per_record": RECORD_BITS,
        "sustained_core_records_per_second": DIVIDER_CLOCK_HZ // RECORD_BITS,
        "usb_pair_records_per_second": MPSSE_SCLK_HZ // MPSSE_EDGES_PER_PAIR_RECORD,
        "core_clock_enable_or_step_signals": 0,
        "transaction_load_wait_ready_valid_stall_signals": 0,
        "input_domain": "finite normal nonzero binary32 only",
        "scored_result_domain": "finite normal nonzero binary32 only",
        "oracle": "exact integer ratio; IEEE-754 round-to-nearest ties-to-even",
        "vector_count": len(vectors),
        "vector_seed": args.seed,
        "usb_repetitions_per_vector": args.repeats,
        "held_core_record_opportunities": {
            "numerator": held_core_records_numerator,
            "denominator": CORE_RECORDS_PER_USB_RECORD_DENOMINATOR,
            "decimal": held_core_records_numerator
            / CORE_RECORDS_PER_USB_RECORD_DENOMINATOR,
        },
        "warmup_usb_records": args.warmup_records,
        "tail_usb_records": args.tail_records,
        "wire_bytes": len(outgoing),
        "bitstream_file_name": bitstream_path.name,
        "bitstream_sha256": bitstream_hash,
        "rf_out_n16_design_state": "unconditionally_high_impedance",
    }
    if not args.execute:
        plan["status"] = "DRY RUN - NO FTDI HANDLE OPENED"
        print(json.dumps(plan, indent=2))
        return 0

    if os.name != "nt":
        raise SystemExit("--execute requires Windows with ftd2xx.dll")

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
        returned_records = [
            received[offset : offset + RECORD_BYTES]
            for offset in range(0, len(received), RECORD_BYTES)
        ]
        all_decoded: list[int] = []
        for record_index, returned_record in enumerate(returned_records):
            result_raw, pair_errors = decode_record(returned_record)
            all_decoded.append(result_raw)
            if pair_errors:
                disagreements.append(
                    {"record_index": record_index, "bit_indices": pair_errors}
                )
        decoded = [all_decoded[index] for index in selected_record_indices]

    mismatches = [
        index
        for index, (actual, wanted) in enumerate(zip(decoded, expected))
        if actual != wanted
    ]
    mismatch_examples = []
    for index in mismatches[:32]:
        numerator_raw, denominator_raw = vectors[index]
        mismatch_examples.append(
            {
                "vector_index": index,
                "numerator_raw_hex": f"0x{numerator_raw:08x}",
                "denominator_raw_hex": f"0x{denominator_raw:08x}",
                "expected_raw_hex": f"0x{expected[index]:08x}",
                "received_raw_hex": f"0x{decoded[index]:08x}",
            }
        )

    curated_results = []
    for index, (numerator_raw, denominator_raw) in enumerate(CURATED):
        if index >= len(decoded):
            break
        curated_results.append(
            {
                "numerator_raw_hex": f"0x{numerator_raw:08x}",
                "denominator_raw_hex": f"0x{denominator_raw:08x}",
                "expected_raw_hex": f"0x{expected[index]:08x}",
                "received_raw_hex": f"0x{decoded[index]:08x}",
                "match": expected[index] == decoded[index],
            }
        )

    passed = (
        primary_error is None
        and not close_errors
        and len(received) == len(outgoing)
        and len(decoded) == len(expected)
        and not disagreements
        and not mismatches
    )
    report = {
        **plan,
        "completed_utc": utc_now(),
        "device": {
            "description": channel["description"],
            "type": channel["type"],
            "id_hex": f"0x{channel['id']:08x}",
            "serial_redacted": True,
            "location_id_redacted": True,
        },
        "received_wire_bytes": len(received),
        "elapsed_seconds": elapsed,
        "effective_wire_bits_per_second": len(outgoing) * 8 / elapsed if elapsed else None,
        "outgoing_sha256": digest(outgoing),
        "received_sha256": digest(received),
        "decoded_vector_count": len(decoded),
        "duplicate_slot_disagreement_record_count": len(disagreements),
        "duplicate_slot_disagreement_bit_count": sum(
            len(item["bit_indices"]) for item in disagreements
        ),
        "first_duplicate_slot_disagreements": disagreements[:32],
        "arithmetic_mismatch_count": len(mismatches),
        "first_arithmetic_mismatches": mismatch_examples,
        "curated_results": curated_results,
        "close_errors": close_errors,
        "error": f"{type(primary_error).__name__}: {primary_error}" if primary_error else None,
        "status": "PASS" if passed else "FAIL",
    }
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2), file=sys.stdout if passed else sys.stderr)
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
