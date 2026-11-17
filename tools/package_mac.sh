#!/bin/sh
# Build the Mac downloads into dist/:
#   ArmenianKeyboard-mac.zip  the .bundle, for dragging into ~/Library/Keyboard Layouts
#   ArmenianKeyboard-mac.pkg  an installer that puts it in /Library/Keyboard Layouts
set -eu
cd "$(dirname "$0")/.."
version=${1:-0.1.0}
python3 tools/build.py --version "$version" >/dev/null
rm -rf dist && mkdir -p dist
bundle=build/mac/ArmenianKeyboard.bundle

# Zip (ditto keeps the bundle structure the way Finder expects).
stage=build/zip && rm -rf "$stage" && mkdir -p "$stage/Armenian Keyboard"
cp -RX "$bundle" "$stage/Armenian Keyboard/"
cp mac/INSTALL.txt "$stage/Armenian Keyboard/How to install.txt"
(cd "$stage" && ditto -c -k --norsrc --noextattr --noqtn --keepParent "Armenian Keyboard" "../../dist/ArmenianKeyboard-mac.zip")

# Installer package.
root=build/pkgroot && rm -rf "$root" && mkdir -p "$root"
cp -RX "$bundle" "$root/"
COPYFILE_DISABLE=1 pkgbuild --root "$root" --install-location "/Library/Keyboard Layouts" \
  --identifier com.github.aram-p.armenian-keyboard.pkg --version "$version" \
  build/component.pkg >/dev/null
productbuild --distribution mac/distribution.xml --resources mac/pkg-resources \
  --package-path build "dist/ArmenianKeyboard-mac.pkg" >/dev/null
rm build/component.pkg
/bin/ls -l dist
