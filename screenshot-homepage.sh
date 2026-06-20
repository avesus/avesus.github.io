#!/usr/bin/env sh
set -eu

PORT="${PORT:-8193}"
HOST="${HOST:-127.0.0.1}"
VIEWPORT="${VIEWPORT:-390,844}"
WAIT_FOR_TIMEOUT="${WAIT_FOR_TIMEOUT:-1000}"
OUTPUT="${1:-screenshots/homepage-mobile.png}"
URL="${URL:-http://$HOST:$PORT/}"
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
OUTPUT_DIR=$(dirname -- "$OUTPUT")
CHANNEL="${PLAYWRIGHT_CHANNEL:-}"

cd "$SCRIPT_DIR"
mkdir -p "$OUTPUT_DIR"

if ! command -v npx >/dev/null 2>&1; then
  echo "npx is required to capture screenshots." >&2
  echo "Install Node.js, then run this script again." >&2
  exit 1
fi

if [ -z "$CHANNEL" ]; then
  case "$(uname -s 2>/dev/null || echo unknown)" in
    MINGW*|MSYS*|CYGWIN*)
      if [ -x "/c/Program Files (x86)/Microsoft/Edge/Application/msedge.exe" ] ||
        [ -x "/c/Program Files/Microsoft/Edge/Application/msedge.exe" ]; then
        CHANNEL="msedge"
      elif [ -x "/c/Program Files/Google/Chrome/Application/chrome.exe" ] ||
        [ -x "/c/Program Files (x86)/Google/Chrome/Application/chrome.exe" ]; then
        CHANNEL="chrome"
      fi
      ;;
    Darwin)
      if [ -d "/Applications/Google Chrome.app" ]; then
        CHANNEL="chrome"
      elif [ -d "/Applications/Microsoft Edge.app" ]; then
        CHANNEL="msedge"
      fi
      ;;
    Linux)
      if command -v google-chrome >/dev/null 2>&1 ||
        command -v google-chrome-stable >/dev/null 2>&1; then
        CHANNEL="chrome"
      elif command -v microsoft-edge >/dev/null 2>&1 ||
        command -v microsoft-edge-stable >/dev/null 2>&1; then
        CHANNEL="msedge"
      fi
      ;;
  esac
fi

./host-locally.sh "$PORT" > "$OUTPUT_DIR/host-locally.log" 2>&1 &
SERVER_PID=$!

cleanup() {
  kill "$SERVER_PID" 2>/dev/null || true
  wait "$SERVER_PID" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

sleep 2

set -- npx --yes playwright screenshot \
  --browser=chromium \
  --viewport-size="$VIEWPORT" \
  --full-page \
  --wait-for-selector="html.gf-ready" \
  --wait-for-timeout="$WAIT_FOR_TIMEOUT"

if [ -n "$CHANNEL" ]; then
  set -- "$@" --channel="$CHANNEL"
fi

set -- "$@" "$URL" "$OUTPUT"

echo "Capturing $URL at $VIEWPORT into $OUTPUT"
"$@"
