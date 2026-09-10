#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
# Source the Cortex-A9 OpenEmbedded SDK environment first. Its CXX includes
# the cross-compiler, CPU/FPU flags, and matching --sysroot. Do not quote it as
# a single executable name. This is the same invocation used on the lab build.
: "${CXX:?Source your ARM hard-float SDK environment first}"
mkdir -p build
$CXX -std=c++20 -O3 -Wall -Wextra -Werror -Wno-psabi cpu_dsss_probe.cpp -o build/cpu_dsss_probe_arm
file build/cpu_dsss_probe_arm
