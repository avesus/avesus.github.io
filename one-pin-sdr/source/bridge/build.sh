#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
if [ ! -d pico-ice-sdk ]; then
  git clone https://github.com/tinyvision-ai-inc/pico-ice-sdk.git pico-ice-sdk
fi
git -C pico-ice-sdk checkout f3ddedcdabdbb929939720df0856f2f6b39962fc
git -C pico-ice-sdk submodule update --init --recursive
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j2
