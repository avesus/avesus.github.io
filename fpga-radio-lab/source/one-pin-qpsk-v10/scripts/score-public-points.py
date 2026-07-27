#!/usr/bin/env python3
"""Recompute held-out QPSK decisions, EVM, and correlation from public points."""

from __future__ import annotations

import argparse
import csv
import math
from pathlib import Path


IDEAL = (1.0 + 0.0j, 0.0 + 1.0j, -1.0 + 0.0j, 0.0 - 1.0j)
EXPECTED_FIELDS = ("epoch_index", "expected_state", "recovered_i", "recovered_q")


def parse_args() -> argparse.Namespace:
    bundled = Path(__file__).resolve().parents[1] / "data" / "qpsk-held-out-points.csv"
    parser = argparse.ArgumentParser(
        description="Score the privacy-clean held-out QPSK point set"
    )
    parser.add_argument("csv", nargs="?", type=Path, default=bundled)
    parser.add_argument(
        "--verify-bundled-result",
        action="store_true",
        help="require the retained 4,296-symbol result",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    observed: list[complex] = []
    expected: list[complex] = []
    epochs: set[int] = set()
    symbol_errors = 0
    bit_errors = 0

    with args.csv.open("r", encoding="utf-8", newline="") as stream:
        reader = csv.DictReader(stream)
        if tuple(reader.fieldnames or ()) != EXPECTED_FIELDS:
            raise SystemExit(f"unexpected CSV columns: {reader.fieldnames!r}")
        for row_number, row in enumerate(reader, start=2):
            epoch = int(row["epoch_index"])
            state = int(row["expected_state"])
            point = complex(float(row["recovered_i"]), float(row["recovered_q"]))
            if epoch in epochs:
                raise SystemExit(f"duplicate epoch {epoch} on row {row_number}")
            if state not in range(4):
                raise SystemExit(f"invalid QPSK state {state} on row {row_number}")
            if not (math.isfinite(point.real) and math.isfinite(point.imag)):
                raise SystemExit(f"non-finite point on row {row_number}")
            epochs.add(epoch)
            decision = min(range(4), key=lambda candidate: abs(point - IDEAL[candidate]) ** 2)
            symbol_errors += int(decision != state)
            bit_errors += (decision ^ state).bit_count()
            observed.append(point)
            expected.append(IDEAL[state])

    if not observed:
        raise SystemExit("no QPSK points found")

    error_energy = sum(abs(point - truth) ** 2 for point, truth in zip(observed, expected))
    reference_energy = sum(abs(truth) ** 2 for truth in expected)
    evm_percent = 100.0 * math.sqrt(error_energy / reference_energy)
    inner_product = sum(point.conjugate() * truth for point, truth in zip(observed, expected))
    observed_energy = sum(abs(point) ** 2 for point in observed)
    correlation = abs(inner_product) ** 2 / (observed_energy * reference_energy)

    print(f"held-out symbols: {len(observed)}")
    print(f"bits scored: {2 * len(observed)}")
    print(f"symbol errors: {symbol_errors}")
    print(f"bit errors: {bit_errors}")
    print(f"RMS EVM: {evm_percent:.12f} %")
    print(f"normalized correlation: {correlation:.12f}")

    verify = args.verify_bundled_result or args.csv.resolve() == (
        Path(__file__).resolve().parents[1] / "data" / "qpsk-held-out-points.csv"
    ).resolve()
    if verify:
        if len(observed) != 4296 or symbol_errors != 0 or bit_errors != 0:
            raise SystemExit("bundled held-out decision result changed")
        if not math.isclose(evm_percent, 2.0696355626125142, rel_tol=0.0, abs_tol=1e-12):
            raise SystemExit("bundled EVM changed")
        if not math.isclose(correlation, 0.9995840846484787, rel_tol=0.0, abs_tol=1e-14):
            raise SystemExit("bundled correlation changed")


if __name__ == "__main__":
    main()
