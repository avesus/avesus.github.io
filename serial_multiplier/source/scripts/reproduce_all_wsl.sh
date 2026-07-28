#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

"${script_dir}/run_sim_wsl.sh" 4096
"${script_dir}/build_core_fit_wsl.sh"
"${script_dir}/build_bank_fit_wsl.sh" 12 1

if "${script_dir}/build_bank_fit_wsl.sh" 13 1; then
  echo "FAIL: 13 independent cores unexpectedly fit" >&2
  exit 1
fi

echo "PASS: simulation, isolated core fit, 12-core fit, and 13-core capacity edge reproduced"
