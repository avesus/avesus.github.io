#!/usr/bin/env python3
"""Benchmark the board-wired FT2232H-B MPSSE link without RF activity.

The matching FPGA image returns 0xA5 first and then returns every MOSI byte
exactly one byte later.  The default proof verifies 64 KiB of deterministic,
privacy-neutral payload at a 30 MHz SPI clock.  Hardware is never opened unless
``--execute`` is explicit.
"""

from __future__ import annotations

import argparse
import ctypes
import hashlib
import json
import os
import sys
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from program_ice40_sram_d2xx import (
    D2xx,
    D2xxError,
    FT_BITMODE_MPSSE,
    FT_BITMODE_RESET,
    FT_DEVICE_2232H,
    FT_OK,
    FT_PURGE_RX,
    FT_PURGE_TX,
)


EXPECTED_ID = 0x04036010
EXPECTED_DESCRIPTION = "Dual RS232-HS B"
STATUS_BYTE = 0xA5

MC_SETB_LOW = 0x80
MC_FLUSH = 0x87
MC_DISABLE_DIV5 = 0x8A
MC_DISABLE_3PHASE = 0x8D
MC_SET_CLK_DIV = 0x86
MC_DISABLE_ADAPTIVE = 0x97
MC_DATA_INOUT_BYTES_MSB_NVE_PVE = 0x31

GPIO_DIRECTION = 0x0B  # BDBUS0 clock, BDBUS1 MOSI, BDBUS3 CS are outputs.
GPIO_IDLE = 0x08       # clock low, MOSI low, CS high; BDBUS2 MISO is input.
GPIO_SELECTED = 0x00   # clock low, MOSI low, CS low.


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


def make_payload(count: int) -> bytes:
    """Generate deterministic neutral bytes without any identity-bearing text."""
    state = 0x6D2B79F5
    result = bytearray(count)
    for index in range(count):
        state ^= (state << 13) & 0xFFFFFFFF
        state ^= state >> 17
        state ^= (state << 5) & 0xFFFFFFFF
        result[index] = (state ^ index ^ (index >> 8)) & 0xFF
    return bytes(result)


def select_channel_b(
    devices: list[dict[str, Any]], serial: str | None, location_id: int | None
) -> dict[str, Any]:
    candidates = [
        device
        for device in devices
        if device["type"] == FT_DEVICE_2232H
        and device["id"] == EXPECTED_ID
        and device["description"] == EXPECTED_DESCRIPTION
        and (serial is None or device["serial"] == serial)
        and (location_id is None or device["location_id"] == location_id)
    ]
    if len(candidates) != 1:
        raise D2xxError(
            f"expected exactly one {EXPECTED_DESCRIPTION!r} device; found {len(candidates)}"
        )
    if candidates[0]["is_open"]:
        raise D2xxError("FT2232H channel B is already open")
    return candidates[0]


class Mpsse30:
    def __init__(self, d2xx: D2xx, index: int, timeout_ms: int) -> None:
        self.d2xx = d2xx
        self.index = index
        self.timeout_ms = timeout_ms
        self.handle = ctypes.c_void_p()
        self.opened = False
        self.old_latency: int | None = None

    def open(self) -> None:
        self.d2xx.check(
            self.d2xx.dll.FT_Open(self.index, ctypes.byref(self.handle)),
            f"FT_Open({self.index})",
        )
        self.opened = True
        self.d2xx.check(self.d2xx.dll.FT_ResetDevice(self.handle), "FT_ResetDevice")
        self.d2xx.check(
            self.d2xx.dll.FT_Purge(self.handle, FT_PURGE_RX | FT_PURGE_TX),
            "FT_Purge",
        )
        self.d2xx.check(
            self.d2xx.dll.FT_SetUSBParameters(self.handle, 65536, 65536),
            "FT_SetUSBParameters",
        )
        self.d2xx.check(
            self.d2xx.dll.FT_SetTimeouts(
                self.handle, self.timeout_ms, self.timeout_ms
            ),
            "FT_SetTimeouts",
        )
        latency = ctypes.c_ubyte()
        self.d2xx.check(
            self.d2xx.dll.FT_GetLatencyTimer(self.handle, ctypes.byref(latency)),
            "FT_GetLatencyTimer",
        )
        self.old_latency = latency.value
        self.d2xx.check(
            self.d2xx.dll.FT_SetLatencyTimer(self.handle, 1),
            "FT_SetLatencyTimer(1)",
        )
        self.d2xx.check(
            self.d2xx.dll.FT_SetBitMode(self.handle, 0x00, FT_BITMODE_RESET),
            "FT_SetBitMode(reset)",
        )
        time.sleep(0.020)
        self.d2xx.check(
            self.d2xx.dll.FT_SetBitMode(self.handle, 0x00, FT_BITMODE_MPSSE),
            "FT_SetBitMode(MPSSE)",
        )
        time.sleep(0.050)
        self.d2xx.check(
            self.d2xx.dll.FT_Purge(self.handle, FT_PURGE_RX | FT_PURGE_TX),
            "FT_Purge(after MPSSE)",
        )

        # FT2232H 60 MHz master clock, divisor zero -> 30 MHz SCLK.
        self.write_all(
            bytes(
                (
                    MC_DISABLE_DIV5,
                    MC_DISABLE_ADAPTIVE,
                    MC_DISABLE_3PHASE,
                    MC_SET_CLK_DIV,
                    0x00,
                    0x00,
                    MC_SETB_LOW,
                    GPIO_IDLE,
                    GPIO_DIRECTION,
                )
            )
        )

    def close(self) -> list[str]:
        errors: list[str] = []
        if not self.opened:
            return errors
        # End selected-low transactions before releasing all pins to inputs.
        status = self._set_gpio_no_raise(GPIO_IDLE, GPIO_DIRECTION)
        if status != FT_OK:
            errors.append(f"restore CS high failed with FT_STATUS {status}")
        if self.old_latency is not None:
            status = self.d2xx.dll.FT_SetLatencyTimer(self.handle, self.old_latency)
            if status != FT_OK:
                errors.append(f"restore latency failed with FT_STATUS {status}")
        status = self.d2xx.dll.FT_SetBitMode(self.handle, 0x00, FT_BITMODE_RESET)
        if status != FT_OK:
            errors.append(f"reset bitmode failed with FT_STATUS {status}")
        status = self.d2xx.dll.FT_Close(self.handle)
        if status != FT_OK:
            errors.append(f"FT_Close failed with FT_STATUS {status}")
        self.opened = False
        return errors

    def write_all(self, data: bytes) -> None:
        offset = 0
        while offset < len(data):
            block = data[offset:]
            buffer = ctypes.create_string_buffer(block, len(block))
            written = ctypes.c_ulong()
            self.d2xx.check(
                self.d2xx.dll.FT_Write(
                    self.handle,
                    ctypes.cast(buffer, ctypes.c_void_p),
                    len(block),
                    ctypes.byref(written),
                ),
                "FT_Write",
            )
            if written.value == 0:
                raise D2xxError("FT_Write made no progress")
            offset += written.value

    def read_exact(self, size: int, deadline_seconds: float) -> bytes:
        deadline = time.monotonic() + deadline_seconds
        result = bytearray()
        while len(result) < size:
            queued = ctypes.c_ulong()
            self.d2xx.check(
                self.d2xx.dll.FT_GetQueueStatus(self.handle, ctypes.byref(queued)),
                "FT_GetQueueStatus",
            )
            if queued.value:
                wanted = min(size - len(result), queued.value)
                buffer = ctypes.create_string_buffer(wanted)
                received = ctypes.c_ulong()
                self.d2xx.check(
                    self.d2xx.dll.FT_Read(
                        self.handle,
                        ctypes.cast(buffer, ctypes.c_void_p),
                        wanted,
                        ctypes.byref(received),
                    ),
                    "FT_Read",
                )
                result.extend(buffer.raw[: received.value])
                continue
            if time.monotonic() >= deadline:
                raise D2xxError(
                    f"timed out after receiving {len(result)} of {size} byte(s)"
                )
            time.sleep(0.0005)
        return bytes(result)

    def _set_gpio_no_raise(self, value: int, direction: int) -> int:
        command = bytes((MC_SETB_LOW, value & 0xFF, direction & 0xFF))
        buffer = ctypes.create_string_buffer(command, len(command))
        written = ctypes.c_ulong()
        status = self.d2xx.dll.FT_Write(
            self.handle,
            ctypes.cast(buffer, ctypes.c_void_p),
            len(command),
            ctypes.byref(written),
        )
        if status == FT_OK and written.value != len(command):
            return 1
        return status

    def set_gpio(self, value: int, direction: int = GPIO_DIRECTION) -> None:
        self.write_all(bytes((MC_SETB_LOW, value & 0xFF, direction & 0xFF)))

    def exchange(self, outgoing: bytes, chunk_size: int, timeout: float) -> bytes:
        result = bytearray()
        self.set_gpio(GPIO_SELECTED)
        try:
            for start in range(0, len(outgoing), chunk_size):
                chunk = outgoing[start : start + chunk_size]
                count = len(chunk) - 1
                command = bytes(
                    (
                        MC_DATA_INOUT_BYTES_MSB_NVE_PVE,
                        count & 0xFF,
                        (count >> 8) & 0xFF,
                    )
                ) + chunk + bytes((MC_FLUSH,))
                self.write_all(command)
                result.extend(self.read_exact(len(chunk), timeout))
        finally:
            self.set_gpio(GPIO_IDLE)
        return bytes(result)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="RF-inert 30 MHz FT2232H-B MPSSE one-byte echo benchmark"
    )
    parser.add_argument("--count", type=int, default=65_536)
    parser.add_argument("--chunk", type=int, default=16_384)
    parser.add_argument("--timeout", type=float, default=5.0)
    parser.add_argument("--report", type=Path, required=True)
    parser.add_argument("--serial", help="optional exact FTDI channel-B serial gate")
    parser.add_argument(
        "--location-id",
        type=lambda value: int(value, 0),
        help="optional exact FTDI channel-B location gate, e.g. 0x2642",
    )
    parser.add_argument(
        "--execute",
        action="store_true",
        help="open channel B and run the benchmark; absent means no hardware access",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.count < 65_536:
        raise ValueError("--count must be at least 65536 bytes for this proof")
    if not 1 <= args.chunk <= 65_536:
        raise ValueError("--chunk must be in 1..65536")
    if args.timeout <= 0:
        raise ValueError("--timeout must be positive")
    if args.report.exists():
        raise FileExistsError(f"refusing to overwrite report: {args.report}")

    plan = {
        "schema": "greenforest-mpsse30-echo/v1",
        "created_utc": utc_now(),
        "execute_requested": bool(args.execute),
        "ftdi_interface": "FT2232H channel B MPSSE",
        "sclk_hz": 30_000_000,
        "spi_mode": 0,
        "payload_bytes": args.count,
        "wire_bytes": args.count + 1,
        "chunk_bytes": args.chunk,
        "expected_first_status_byte_hex": f"{STATUS_BYTE:02x}",
        "protocol": "first byte status; subsequent byte echoes immediately preceding MOSI byte",
        "payload_contains_public_identity": False,
        "rf_out_n16_design_state": "unconditionally_high_impedance",
    }
    if not args.execute:
        plan["status"] = "DRY RUN - NO FTDI HANDLE OPENED"
        print(json.dumps(plan, indent=2))
        return 0

    if os.name != "nt":
        raise SystemExit("--execute requires Windows with ftd2xx.dll")

    payload = make_payload(args.count)
    outgoing = payload + b"\x00"  # clocks the final delayed payload byte out
    expected = bytes((STATUS_BYTE,)) + payload
    d2xx = D2xx()
    devices = d2xx.devices()
    channel = select_channel_b(devices, args.serial, args.location_id)
    link = Mpsse30(d2xx, channel["index"], int(args.timeout * 1000))
    received = b""
    close_errors: list[str] = []
    primary_error: BaseException | None = None
    started = 0.0
    elapsed = 0.0
    try:
        link.open()
        started = time.perf_counter()
        received = link.exchange(outgoing, args.chunk, args.timeout)
        elapsed = time.perf_counter() - started
    except BaseException as exc:
        primary_error = exc
    finally:
        close_errors = link.close()

    mismatch = next(
        (index for index, pair in enumerate(zip(expected, received)) if pair[0] != pair[1]),
        None,
    )
    if mismatch is None and len(received) != len(expected):
        mismatch = min(len(received), len(expected))
    passed = primary_error is None and not close_errors and mismatch is None
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
        "effective_payload_bytes_per_second": (args.count / elapsed) if elapsed else None,
        "effective_payload_bits_per_second": (args.count * 8 / elapsed) if elapsed else None,
        "wire_utilization_fraction": (
            (len(outgoing) * 8 / elapsed) / 30_000_000 if elapsed else None
        ),
        "payload_sha256": hashlib.sha256(payload).hexdigest(),
        "expected_wire_sha256": hashlib.sha256(expected).hexdigest(),
        "received_wire_sha256": hashlib.sha256(received).hexdigest(),
        "first_mismatch_index": mismatch,
        "close_errors": close_errors,
        "error": (
            f"{type(primary_error).__name__}: {primary_error}"
            if primary_error is not None
            else None
        ),
        "status": "PASS" if passed else "FAIL",
    }
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    stream = sys.stdout if passed else sys.stderr
    print(json.dumps(report, indent=2), file=stream)
    return 0 if passed else 1


if __name__ == "__main__":
    raise SystemExit(main())
