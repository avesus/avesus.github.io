#!/usr/bin/env python3
"""Volatile-only iCE40 SRAM loader for the official HX8K breakout board.

This is a narrow Windows/D2XX port of the ``iceprog -S`` path.  It opens
FT2232H channel A, drives the documented MPSSE configuration pins, shifts one
bitstream into CRAM, supplies the trailing clocks, and requires CDONE high.

There is deliberately no SPI-flash command or flash-write mode in this file.
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


FT_OK = 0
FT_DEVICE_2232H = 6
FT_PURGE_RX = 1
FT_PURGE_TX = 2
FT_BITMODE_RESET = 0x00
FT_BITMODE_MPSSE = 0x02

EXPECTED_ID = 0x04036010
EXPECTED_DESCRIPTION = "Dual RS232-HS A"

MC_SETB_LOW = 0x80
MC_READB_LOW = 0x81
MC_FLUSH = 0x87
MC_SET_CLK_DIV = 0x86
MC_TCK_D5 = 0x8B
MC_CLK_N = 0x8E
MC_CLK_N8 = 0x8F
MC_DATA_OUT_OCN = 0x11


def utc_now() -> str:
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def c_string(buf: ctypes.Array[ctypes.c_char]) -> str:
    return bytes(buf).split(b"\0", 1)[0].decode("ascii", errors="strict")


class D2xxError(RuntimeError):
    pass


class D2xx:
    def __init__(self) -> None:
        self.dll = ctypes.WinDLL("ftd2xx.dll")
        dword_p = ctypes.POINTER(ctypes.c_ulong)
        uchar_p = ctypes.POINTER(ctypes.c_ubyte)
        handle_p = ctypes.POINTER(ctypes.c_void_p)

        self.dll.FT_CreateDeviceInfoList.argtypes = [dword_p]
        self.dll.FT_CreateDeviceInfoList.restype = ctypes.c_ulong
        self.dll.FT_GetDeviceInfoDetail.argtypes = [
            ctypes.c_ulong,
            dword_p,
            dword_p,
            dword_p,
            dword_p,
            ctypes.c_void_p,
            ctypes.c_void_p,
            handle_p,
        ]
        self.dll.FT_GetDeviceInfoDetail.restype = ctypes.c_ulong
        self.dll.FT_Open.argtypes = [ctypes.c_int, handle_p]
        self.dll.FT_Open.restype = ctypes.c_ulong
        self.dll.FT_Close.argtypes = [ctypes.c_void_p]
        self.dll.FT_Close.restype = ctypes.c_ulong
        self.dll.FT_ResetDevice.argtypes = [ctypes.c_void_p]
        self.dll.FT_ResetDevice.restype = ctypes.c_ulong
        self.dll.FT_Purge.argtypes = [ctypes.c_void_p, ctypes.c_ulong]
        self.dll.FT_Purge.restype = ctypes.c_ulong
        self.dll.FT_SetUSBParameters.argtypes = [
            ctypes.c_void_p,
            ctypes.c_ulong,
            ctypes.c_ulong,
        ]
        self.dll.FT_SetUSBParameters.restype = ctypes.c_ulong
        self.dll.FT_SetTimeouts.argtypes = [
            ctypes.c_void_p,
            ctypes.c_ulong,
            ctypes.c_ulong,
        ]
        self.dll.FT_SetTimeouts.restype = ctypes.c_ulong
        self.dll.FT_GetLatencyTimer.argtypes = [ctypes.c_void_p, uchar_p]
        self.dll.FT_GetLatencyTimer.restype = ctypes.c_ulong
        self.dll.FT_SetLatencyTimer.argtypes = [ctypes.c_void_p, ctypes.c_ubyte]
        self.dll.FT_SetLatencyTimer.restype = ctypes.c_ulong
        self.dll.FT_SetBitMode.argtypes = [
            ctypes.c_void_p,
            ctypes.c_ubyte,
            ctypes.c_ubyte,
        ]
        self.dll.FT_SetBitMode.restype = ctypes.c_ulong
        self.dll.FT_GetQueueStatus.argtypes = [ctypes.c_void_p, dword_p]
        self.dll.FT_GetQueueStatus.restype = ctypes.c_ulong
        self.dll.FT_Read.argtypes = [
            ctypes.c_void_p,
            ctypes.c_void_p,
            ctypes.c_ulong,
            dword_p,
        ]
        self.dll.FT_Read.restype = ctypes.c_ulong
        self.dll.FT_Write.argtypes = [
            ctypes.c_void_p,
            ctypes.c_void_p,
            ctypes.c_ulong,
            dword_p,
        ]
        self.dll.FT_Write.restype = ctypes.c_ulong

    @staticmethod
    def check(status: int, operation: str) -> None:
        if status != FT_OK:
            raise D2xxError(f"{operation} failed with FT_STATUS {status}")

    def devices(self) -> list[dict[str, Any]]:
        count = ctypes.c_ulong()
        self.check(self.dll.FT_CreateDeviceInfoList(ctypes.byref(count)), "FT_CreateDeviceInfoList")
        found: list[dict[str, Any]] = []
        for index in range(count.value):
            flags = ctypes.c_ulong()
            kind = ctypes.c_ulong()
            device_id = ctypes.c_ulong()
            location = ctypes.c_ulong()
            serial = ctypes.create_string_buffer(64)
            description = ctypes.create_string_buffer(128)
            existing_handle = ctypes.c_void_p()
            self.check(
                self.dll.FT_GetDeviceInfoDetail(
                    index,
                    ctypes.byref(flags),
                    ctypes.byref(kind),
                    ctypes.byref(device_id),
                    ctypes.byref(location),
                    ctypes.cast(serial, ctypes.c_void_p),
                    ctypes.cast(description, ctypes.c_void_p),
                    ctypes.byref(existing_handle),
                ),
                f"FT_GetDeviceInfoDetail({index})",
            )
            found.append(
                {
                    "index": index,
                    "flags": flags.value,
                    "type": kind.value,
                    "id": device_id.value,
                    "location_id": location.value,
                    "serial": c_string(serial),
                    "description": c_string(description),
                    "is_open": bool(flags.value & 0x01),
                }
            )
        return found


class Mpsse:
    def __init__(self, d2xx: D2xx, index: int) -> None:
        self.d2xx = d2xx
        self.index = index
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
            self.d2xx.dll.FT_SetTimeouts(self.handle, 2000, 2000),
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
            self.d2xx.dll.FT_SetBitMode(self.handle, 0xFF, FT_BITMODE_MPSSE),
            "FT_SetBitMode(MPSSE)",
        )
        time.sleep(0.050)
        self.write(bytes((MC_TCK_D5, MC_SET_CLK_DIV, 0x00, 0x00)))

    def close(self) -> list[str]:
        errors: list[str] = []
        if not self.opened:
            return errors
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

    def write(self, data: bytes) -> None:
        offset = 0
        while offset < len(data):
            block = data[offset:]
            buf = ctypes.create_string_buffer(block, len(block))
            written = ctypes.c_ulong()
            self.d2xx.check(
                self.d2xx.dll.FT_Write(
                    self.handle,
                    ctypes.cast(buf, ctypes.c_void_p),
                    len(block),
                    ctypes.byref(written),
                ),
                "FT_Write",
            )
            if written.value == 0:
                raise D2xxError("FT_Write made no progress")
            offset += written.value

    def read_exact(self, size: int, deadline_seconds: float = 2.0) -> bytes:
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
                buf = ctypes.create_string_buffer(wanted)
                received = ctypes.c_ulong()
                self.d2xx.check(
                    self.d2xx.dll.FT_Read(
                        self.handle,
                        ctypes.cast(buf, ctypes.c_void_p),
                        wanted,
                        ctypes.byref(received),
                    ),
                    "FT_Read",
                )
                result.extend(buf.raw[: received.value])
                continue
            if time.monotonic() >= deadline:
                raise D2xxError(f"timed out waiting for {size} MPSSE byte(s)")
            time.sleep(0.001)
        return bytes(result)

    def set_gpio(self, value: int, direction: int) -> None:
        self.write(bytes((MC_SETB_LOW, value & 0xFF, direction & 0xFF)))

    def cdone(self) -> bool:
        self.write(bytes((MC_READB_LOW, MC_FLUSH)))
        return bool(self.read_exact(1)[0] & 0x40)

    def send_spi(self, data: bytes) -> None:
        if not data:
            return
        if len(data) > 65536:
            raise ValueError("one MPSSE SPI block cannot exceed 65536 bytes")
        count = len(data) - 1
        self.write(bytes((MC_DATA_OUT_OCN, count & 0xFF, (count >> 8) & 0xFF)) + data)


def select_channel_a(
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
            f"expected exactly one unopened {EXPECTED_DESCRIPTION!r} device; found {len(candidates)}"
        )
    if candidates[0]["is_open"]:
        raise D2xxError("FT2232H channel A is already open")
    return candidates[0]


def program_sram(bitstream: bytes, channel: dict[str, Any]) -> dict[str, Any]:
    d2xx = D2xx()
    mpsse = Mpsse(d2xx, channel["index"])
    result: dict[str, Any] = {
        "started_utc": utc_now(),
        "initial_cdone": None,
        "reset_cdone": None,
        "final_cdone": None,
        "bytes_shifted": 0,
        "close_errors": [],
    }
    primary_error: BaseException | None = None
    try:
        mpsse.open()
        result["initial_cdone"] = mpsse.cdone()

        # iceprog flash_release_reset(): both control pins released to pull-ups.
        mpsse.set_gpio(0x00, 0x03)
        time.sleep(0.100)

        # iceprog sram_reset(): CS and CRESET actively low.
        mpsse.set_gpio(0x00, 0x93)
        time.sleep(0.000100)

        # iceprog sram_chip_select(): CS low, CRESET released high.
        mpsse.set_gpio(0x00, 0x13)
        time.sleep(0.002)
        result["reset_cdone"] = mpsse.cdone()
        if result["reset_cdone"]:
            raise D2xxError("CDONE remained high after SRAM reset")

        for start in range(0, len(bitstream), 4096):
            chunk = bitstream[start : start + 4096]
            mpsse.send_spi(chunk)
            result["bytes_shifted"] += len(chunk)

        # Six dummy bytes plus one dummy bit, exactly as iceprog -S.
        mpsse.write(bytes((MC_CLK_N8, 5, 0, MC_CLK_N, 0)))
        result["final_cdone"] = mpsse.cdone()
        if not result["final_cdone"]:
            raise D2xxError("CDONE is low after volatile SRAM programming")
    except BaseException as exc:
        primary_error = exc
        raise
    finally:
        result["close_errors"] = mpsse.close()
        result["completed_utc"] = utc_now()
        if result["close_errors"] and primary_error is None:
            raise D2xxError("; ".join(result["close_errors"]))
    return result


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Volatile-only D2XX equivalent of iceprog -S for ICE40HX8K-B-EVN"
    )
    parser.add_argument("--bitstream", type=Path, required=True)
    parser.add_argument("--expected-sha256", required=True)
    parser.add_argument("--report", type=Path, required=True)
    parser.add_argument("--serial", help="optional exact FTDI channel-A serial gate")
    parser.add_argument(
        "--location-id",
        type=lambda value: int(value, 0),
        help="optional exact FTDI channel-A location gate",
    )
    parser.add_argument(
        "--execute",
        action="store_true",
        help="access hardware; without this flag the command is a dry run",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    bitstream = args.bitstream.resolve()
    report_path = args.report.resolve()
    if not bitstream.is_file():
        raise FileNotFoundError(bitstream)
    expected_sha = args.expected_sha256.lower()
    if len(expected_sha) != 64 or any(ch not in "0123456789abcdef" for ch in expected_sha):
        raise ValueError("--expected-sha256 must be exactly 64 hexadecimal characters")
    actual_sha = sha256_file(bitstream)
    if actual_sha != expected_sha:
        raise RuntimeError(f"bitstream SHA-256 mismatch: {actual_sha} != {expected_sha}")
    if report_path.exists():
        raise FileExistsError(f"refusing to overwrite report: {report_path}")

    d2xx = D2xx()
    devices = d2xx.devices()
    channel = select_channel_a(devices, args.serial, args.location_id)
    report: dict[str, Any] = {
        "schema": "greenforest-ice40-volatile-sram-d2xx/v1",
        "created_utc": utc_now(),
        "mode": "volatile_cram_only_equivalent_to_iceprog_-S",
        "persistent_flash_access": False,
        "bitstream": {
            "path": str(bitstream),
            "bytes": bitstream.stat().st_size,
            "sha256": actual_sha,
            "expected_sha256_verified": True,
        },
        "ftdi_channel": channel,
        "all_d2xx_devices": devices,
        "execute_requested": bool(args.execute),
    }

    if not args.execute:
        report["status"] = "DRY RUN - NO FTDI HANDLE OPENED AND NO FPGA ACCESSED"
        print(json.dumps(report, indent=2))
        return 0

    bitstream_bytes = bitstream.read_bytes()
    try:
        report["programming"] = program_sram(bitstream_bytes, channel)
        report["status"] = "PASS - VOLATILE SRAM LOADED AND CDONE HIGH"
    except BaseException as exc:
        report["status"] = "FAIL"
        report["error"] = f"{type(exc).__name__}: {exc}"
        report["failed_utc"] = utc_now()
        report_path.parent.mkdir(parents=True, exist_ok=True)
        report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
        print(json.dumps(report, indent=2), file=sys.stderr)
        return 1

    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2))
    return 0


if __name__ == "__main__":
    if os.name != "nt":
        raise SystemExit("program_ice40_sram_d2xx.py requires Windows")
    raise SystemExit(main())
