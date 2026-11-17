#!/bin/sh
# Build every layout, install a test copy into ~/Library/Keyboard Layouts,
# and check every key on every modifier layer against layouts/*.toml.
# The test copy is removed afterwards; nothing is enabled or selected.
# (macOS reads new .bundle folders only at login, but a loose .keylayout
# registers immediately, so the test uses one.)
set -eu
cd "$(dirname "$0")/.."
python3 tools/build.py >/dev/null
mkdir -p build "$HOME/Library/Keyboard Layouts"
swiftc -O tools/verify_mac.swift -o build/verify_mac 2>/dev/null
status=0
for layout in build/mac/ArmenianKeyboard.bundle/Contents/Resources/*.keylayout; do
  base=$(basename "$layout" .keylayout)
  id=$(python3 tools/build.py --id-for "$base")
  stamp=$(date +%s)
  test_name="Test$(echo "$base" | tr -d ' ')$stamp"
  test_file="$HOME/Library/Keyboard Layouts/$test_name.keylayout"
  sed -e "s/name=\"$base\"/name=\"$test_name\"/" -e "s/ id=\"-[0-9]*\"/ id=\"-$((stamp % 20000 + 9000))\"/" "$layout" > "$test_file"
  build/verify_mac "$test_file" "build/expected/$id.json" "org.unknown.keylayout.$test_name" 2>&1 | grep -v '^Keyboard Layouts:' > build/verify.log || true
  cat build/verify.log
  tail -1 build/verify.log | grep -q '^OK$' || status=1
  rm -f "$test_file"
done
exit $status
