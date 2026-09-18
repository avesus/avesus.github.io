"""Verify the exact published received frame. Copyright 2026 Brian Greenforest, MIT."""
from pathlib import Path
import hashlib
import json
import struct
import zlib
from receive import crc16, crc32_independent

ROOT = Path(__file__).resolve().parent.parent
frame = (ROOT / 'data/received-beacon.bin').read_bytes()
header = (ROOT / 'data/received-plcp.bin').read_bytes()
assert len(header) == 6 and header[0] == 10
assert crc16(header[:4]) == int.from_bytes(header[4:], 'little')
assert int.from_bytes(header[2:4], 'little') == len(frame)*8
expected = bytes((37*i+11) & 255 for i in range(64))
assert len(frame) == 129
assert hashlib.sha256(frame).hexdigest() == 'a95cc5cb3ecdb9b97f1168708d2981d12f04185c02ca8077f583582e80f25a63'
assert frame[:2] == b'\x80\x00'  # beacon
stored = int.from_bytes(frame[-4:], 'little')
assert stored == (zlib.crc32(frame[:-4]) & 0xffffffff) == crc32_independent(frame[:-4])
assert frame[61:125] == expected
ies = {}
p = 36
while p < len(frame)-4:
    tag, size = frame[p:p+2]
    assert p+2+size <= len(frame)-4
    ies[tag] = frame[p+2:p+2+size]
    p += 2+size
assert ies[0] == b'HITL-RX-TEST' and ies[3] == b'\x06'
pcap = (ROOT / 'data/received-beacon.pcap').read_bytes()
assert struct.unpack_from('<I', pcap, 20)[0] == 127  # radiotap
assert pcap[40:49] == struct.pack('<BBHIB', 0, 0, 9, 2, 0x10)
assert pcap[49:] == frame
print(json.dumps(dict(frame_bytes=len(frame), plcp_crc16_valid=True, crc32_valid=True, independent_crc32_valid=True,
    test_payload_bits=512, bit_errors=0, ssid=ies[0].decode(), channel=ies[3][0],
    pcap_frame_identical=True), indent=2))
