#!/usr/bin/env sh
set -eu

PORT="${1:-${PORT:-8179}}"
HOST="${HOST:-127.0.0.1}"
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

cd "$SCRIPT_DIR"

if command -v python3 >/dev/null 2>&1 && python3 -c 'import sys; raise SystemExit(0 if sys.version_info[0] == 3 else 1)' >/dev/null 2>&1; then
  set -- python3 -m http.server "$PORT" --bind "$HOST"
elif command -v python >/dev/null 2>&1 && python -c 'import sys; raise SystemExit(0 if sys.version_info[0] == 3 else 1)' >/dev/null 2>&1; then
  set -- python -m http.server "$PORT" --bind "$HOST"
elif command -v py >/dev/null 2>&1 && py -3 -c 'import sys; raise SystemExit(0 if sys.version_info[0] == 3 else 1)' >/dev/null 2>&1; then
  set -- py -3 -m http.server "$PORT" --bind "$HOST"
else
  echo "Python 3 is required to host this site locally." >&2
  echo "Install Python 3, then run this script again." >&2
  exit 1
fi

echo "Serving $SCRIPT_DIR"
echo "Open http://$HOST:$PORT/"
echo "Press Ctrl+C to stop."

exec "$@"
