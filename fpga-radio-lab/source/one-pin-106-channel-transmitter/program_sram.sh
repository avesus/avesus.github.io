#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
bitstream="${1:-${script_dir}/bitstream/pattern106_iq24_lean_mpsse_v3_1s.bin}"

if [[ ! -f "${bitstream}" ]]; then
    echo "Bitstream not found: ${bitstream}" >&2
    exit 2
fi

echo "Loading volatile iCE40 SRAM from ${bitstream}"
exec iceprog -S "${bitstream}"
