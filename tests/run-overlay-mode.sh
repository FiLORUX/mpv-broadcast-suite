#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
test_file=$(mktemp)
trap 'rm -f "$test_file"' EXIT
cat tests/mpv-stub.lua scripts/timecode.lua tests/overlay-mode.lua > "$test_file"
"${LUA:-lua}" "$test_file"
