#!/bin/bash
# Source an ARM Linux C++20 SDK environment before invoking this script.
# Packet agent and capture helper do not link UHD, OpenSSL or a Wi-Fi library.
set -euo pipefail
root=$(cd -- "$(dirname -- "$0")" && pwd)
out="$root/wifi_e310_link/build/release-arm"
mkdir -p "$out"
: "${CXX:?Source the ARM Linux SDK environment first}"
# The SDK intentionally supplies CXX as compiler plus architecture flags.
$CXX -std=c++20 -O2 -Wall -Wextra -Werror \
  "$root/wifi_e310_link/host/e310_packet_agent.cpp" \
  "$root/wifi_e310_link/host/e310_sifs_uio.cpp" -o "$out/gf_e310_packet_agent"
$CXX -std=c++20 -O2 -Wall -Wextra -Werror \
  "$root/wifi_e310_link/host/e310_rx_capture.cpp" -o "$out/gf_e310_rx_capture"
printf 'Built ARM packet transport and RX capture helper in %s\n' "$out"
printf 'Use the matching SDK runtime locally; do not replace board system libraries.\n'
