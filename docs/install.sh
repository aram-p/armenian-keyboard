#!/bin/sh
# Installs the Armenian Phonetic Plus keyboard layout for the current user.
# Usage: curl -fsSL https://aram-p.github.io/armenian-keyboard/install.sh | sh
set -eu
url="https://github.com/aram-p/armenian-keyboard/releases/latest/download/ArmenianKeyboard-mac.zip"
dest="$HOME/Library/Keyboard Layouts"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
echo "Downloading…"
curl -fsSL "$url" -o "$tmp/kb.zip"
ditto -x -k "$tmp/kb.zip" "$tmp"
mkdir -p "$dest"
rm -rf "$dest/ArmenianKeyboard.bundle"
cp -R "$tmp/Armenian Keyboard/ArmenianKeyboard.bundle" "$dest/"
echo "Installed to $dest/ArmenianKeyboard.bundle"
echo
echo "Next:"
echo "  1. Log out and back in."
echo "  2. System Settings → Keyboard → Text Input → Edit… → + → Armenian → Armenian Phonetic Plus."
