#!/bin/sh
# Turn the artwork in art/ into the Mac layout icon and the iPhone app icon.
set -eu
cd "$(dirname "$0")/.."
tmp=$(mktemp -d)
set_dir="$tmp/ArmenianKeyboard.iconset"
mkdir -p "$set_dir" mac/icon
for s in 16 32 128 256 512; do
  sips -z $s $s art/menubar-glyph-512.png --out "$set_dir/icon_${s}x${s}.png" >/dev/null
  d=$((s * 2)); [ $d -gt 512 ] && d=512
  sips -z $d $d art/menubar-glyph-512.png --out "$set_dir/icon_${s}x${s}@2x.png" >/dev/null
done
iconutil -c icns "$set_dir" -o mac/icon/ArmenianKeyboard.icns
appicon=ios/App/Assets.xcassets/AppIcon.appiconset
mkdir -p "$appicon"
sips -s format png -z 1024 1024 art/app-icon-1024.png --out "$appicon/AppIcon.png" >/dev/null
cat > "$appicon/Contents.json" <<'JSON'
{
  "images" : [
    { "filename" : "AppIcon.png", "idiom" : "universal", "platform" : "ios", "size" : "1024x1024" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
JSON
cp art/app-icon-1024.png docs/icon.png
rm -rf "$tmp"
