#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
test_file=$(mktemp)
trap 'rm -f "$test_file"' EXIT
awk '/^local function calc_dropframe\(/ {copy=1} /^-- Timecode Formatting/ {copy=0} copy {print}' scripts/timecode.lua > "$test_file"
cat tests/drop-frame.lua >> "$test_file"
"${LUA:-lua}" "$test_file"
