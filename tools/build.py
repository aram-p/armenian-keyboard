#!/usr/bin/env python3
"""Generate every platform's keyboard from layouts/*.toml.

Outputs:
  build/mac/<Name>.bundle      macOS keyboard layout bundle (all layouts)
  build/expected/<id>.json     what each key must type, used by tools/verify_mac.swift
  ios/Keyboard/Generated/Layouts.swift   iPhone key grid
  docs/layouts.json            data for the website's layout picture

Usage: python3 tools/build.py [--version 0.1.0]
"""
from __future__ import annotations

import argparse
import json
import plistlib
import shutil
import tomllib
import zlib
from pathlib import Path
from xml.sax.saxutils import quoteattr

ROOT = Path(__file__).resolve().parent.parent
LAYOUTS = ROOT / "layouts"
BUILD = ROOT / "build"
BUNDLE_ID = "com.github.aram-p.armenian-keyboard"
BUNDLE_NAME = "Armenian Keyboard"

# US QWERTY: key name -> (mac keycode, plain, shift)
US = [
    ("`", 50, "`", "~"), ("1", 18, "1", "!"), ("2", 19, "2", "@"), ("3", 20, "3", "#"),
    ("4", 21, "4", "$"), ("5", 23, "5", "%"), ("6", 22, "6", "^"), ("7", 26, "7", "&"),
    ("8", 28, "8", "*"), ("9", 25, "9", "("), ("0", 29, "0", ")"), ("-", 27, "-", "_"),
    ("=", 24, "=", "+"),
    ("q", 12, "q", "Q"), ("w", 13, "w", "W"), ("e", 14, "e", "E"), ("r", 15, "r", "R"),
    ("t", 17, "t", "T"), ("y", 16, "y", "Y"), ("u", 32, "u", "U"), ("i", 34, "i", "I"),
    ("o", 31, "o", "O"), ("p", 35, "p", "P"), ("[", 33, "[", "{"), ("]", 30, "]", "}"),
    ("\\", 42, "\\", "|"),
    ("a", 0, "a", "A"), ("s", 1, "s", "S"), ("d", 2, "d", "D"), ("f", 3, "f", "F"),
    ("g", 5, "g", "G"), ("h", 4, "h", "H"), ("j", 38, "j", "J"), ("k", 40, "k", "K"),
    ("l", 37, "l", "L"), (";", 41, ";", ":"), ("'", 39, "'", '"'),
    ("z", 6, "z", "Z"), ("x", 7, "x", "X"), ("c", 8, "c", "C"), ("v", 9, "v", "V"),
    ("b", 11, "b", "B"), ("n", 45, "n", "N"), ("m", 46, "m", "M"), (",", 43, ",", "<"),
    (".", 47, ".", ">"), ("/", 44, "/", "?"),
]
US_BY_NAME = {name: (code, plain, shift) for name, code, plain, shift in US}
KEY_ROWS = [
    ["`", "1", "2", "3", "4", "5", "6", "7", "8", "9", "0", "-", "="],
    ["q", "w", "e", "r", "t", "y", "u", "i", "o", "p", "[", "]", "\\"],
    ["a", "s", "d", "f", "g", "h", "j", "k", "l", ";", "'"],
    ["z", "x", "c", "v", "b", "n", "m", ",", ".", "/"],
]
# The ISO key left of "1" (keycode 10) types the same as the ` key.
ISO_SECTION = 10

# Non-character keys: keycode -> output, the same on every modifier layer.
SPECIAL = {
    36: "\r", 48: "\t", 49: " ", 51: "\x08", 52: "\x03", 53: "\x1b", 76: "\x03",
    71: "\x1b", 65: ".", 67: "*", 69: "+", 75: "/", 78: "-", 81: "=",
    82: "0", 83: "1", 84: "2", 85: "3", 86: "4", 87: "5", 88: "6", 89: "7", 91: "8", 92: "9",
    114: "\x05", 115: "\x01", 116: "\x0b", 117: "\x7f", 119: "\x04", 121: "\x0c",
    123: "\x1c", 124: "\x1d", 125: "\x1f", 126: "\x1e",
}
for fkey in (96, 97, 98, 99, 100, 101, 103, 105, 106, 107, 109, 111, 113, 118, 120, 122, 64, 79, 80, 90):
    SPECIAL[fkey] = "\x10"

# Modifier layers. Order matters: macOS uses the first matching rule.
MODIFIERS = [
    ("plain", [""]),
    ("shift", ["anyShift caps?"]),
    ("caps", ["caps"]),
    ("option", ["anyOption caps?"]),
    ("option_shift", ["anyShift anyOption caps?"]),
    ("command", ["command anyShift? anyOption? caps?"]),
    ("control", ["anyControl anyShift? anyOption? caps? command?"]),
]


def load_layouts() -> list[dict]:
    layouts = []
    for path in sorted(LAYOUTS.glob("*.toml")):
        data = tomllib.loads(path.read_text(encoding="utf-8"))
        missing = [name for name, *_ in US if name not in data["keys"]]
        extra = [k for k in data["keys"] if k not in US_BY_NAME]
        if missing or extra:
            raise SystemExit(f"{path.name}: missing keys {missing}, unknown keys {extra}")
        layouts.append(data)
    if not layouts:
        raise SystemExit("no layouts in layouts/")
    return layouts


def is_letter(s: str) -> bool:
    return any(ch.isalpha() for ch in s)


def layer_outputs(layout: dict) -> dict[str, dict[str, str]]:
    """Key name -> layer -> output, for the character keys."""
    out: dict[str, dict[str, str]] = {}
    caps_overrides = layout.get("caps", {})
    for name, code, us_plain, us_shift in US:
        plain, shift = layout["keys"][name]
        caps = caps_overrides.get(name, shift if is_letter(plain) else plain)
        ctrl = chr(ord(us_plain) - 96) if us_plain.isalpha() else {"[": "\x1b", "\\": "\x1c", "]": "\x1d"}.get(us_plain, us_plain)
        if layout.get("option_layer") != "us":
            raise SystemExit("only option_layer = \"us\" is supported")
        out[name] = {
            "plain": plain, "shift": shift, "caps": caps,
            "option": us_plain, "option_shift": us_shift,
            "command": us_plain, "control": ctrl,
        }
    return out


def xml_chars(s: str) -> str:
    return "".join(ch if (ch.isalnum() and ord(ch) < 128) else f"&#x{ord(ch):04X};" for ch in s)


def keylayout_xml(layout: dict) -> str:
    outputs = layer_outputs(layout)
    by_code: dict[int, dict[str, str]] = {US_BY_NAME[n][0]: v for n, v in outputs.items()}
    by_code[ISO_SECTION] = outputs["`"]
    maxout = max(len(s) for v in outputs.values() for s in v.values())
    # Stable negative id derived from the layout id (Unicode layouts use negative ids).
    kb_id = -(zlib.crc32(layout["id"].encode()) % 30000 + 2000)
    lines = [
        '<?xml version="1.1" encoding="UTF-8"?>',
        '<!DOCTYPE keyboard SYSTEM "file://localhost/System/Library/DTDs/KeyboardLayout.dtd">',
        f'<!-- Generated by tools/build.py from layouts/{layout["id"]}.toml. Do not edit. -->',
        f'<keyboard group="126" id="{kb_id}" name={quoteattr(layout["name"])} maxout="{maxout}">',
        "  <layouts>",
        '    <layout first="0" last="255" mapSet="ANSI" modifiers="Modifiers"/>',
        "  </layouts>",
        '  <modifierMap id="Modifiers" defaultIndex="0">',
    ]
    for index, (_, rules) in enumerate(MODIFIERS):
        lines.append(f'    <keyMapSelect mapIndex="{index}">')
        lines += [f'      <modifier keys="{r}"/>' for r in rules]
        lines.append("    </keyMapSelect>")
    lines += ["  </modifierMap>", '  <keyMapSet id="ANSI">']
    for index, (layer, _) in enumerate(MODIFIERS):
        lines.append(f'    <keyMap index="{index}">')
        keys = {code: v[layer] for code, v in by_code.items()}
        keys.update(SPECIAL)
        for code in sorted(keys):
            lines.append(f'      <key code="{code}" output="{xml_chars(keys[code])}"/>')
        lines.append("    </keyMap>")
    lines += ["  </keyMapSet>", "</keyboard>", ""]
    return "\n".join(lines)


def file_stem(layout: dict) -> str:
    # macOS pairs KLInfo_<name> in Info.plist with Resources/<name>.keylayout.
    return layout["name"]


def source_id(layout: dict) -> str:
    # macOS derives the input source id as <bundle id>.<lowercased name, spaces removed>
    # only when it is not declared; we declare it explicitly in Info.plist.
    return f"{BUNDLE_ID}.{layout['id']}"


def build_mac(layouts: list[dict], version: str) -> Path:
    bundle = BUILD / "mac" / f"{BUNDLE_NAME.replace(' ', '')}.bundle"
    if bundle.exists():
        shutil.rmtree(bundle)
    resources = bundle / "Contents" / "Resources"
    resources.mkdir(parents=True)
    icon = ROOT / "mac" / "icon" / "ArmenianKeyboard.icns"
    info = {
        "CFBundleIdentifier": BUNDLE_ID,
        "CFBundleName": BUNDLE_NAME,
        "CFBundleVersion": version,
        "CFBundleShortVersionString": version,
        "CFBundlePackageType": "BNDL",
    }
    strings = []
    for layout in layouts:
        stem = file_stem(layout)
        (resources / f"{stem}.keylayout").write_text(keylayout_xml(layout), encoding="utf-8")
        if icon.exists():
            shutil.copy(icon, resources / f"{stem}.icns")
        info[f"KLInfo_{layout['name']}"] = {
            "TISInputSourceID": source_id(layout),
            "TISIntendedLanguage": layout["language"],
            "TICapsLockLanguageSwitchCapable": False,
            "TISIconIsTemplate": True,
        }
        strings.append(f'"{layout["name"]}" = "{layout["name"]}";')
    (bundle / "Contents" / "Info.plist").write_bytes(plistlib.dumps(info))
    for lang in ("en", "hy"):
        lproj = resources / f"{lang}.lproj"
        lproj.mkdir()
        (lproj / "InfoPlist.strings").write_text("\n".join(strings) + "\n", encoding="utf-16")
    return bundle


def expected(layout: dict) -> dict:
    """Every (keycode, layer) -> text, for tools/verify_mac.swift."""
    outputs = layer_outputs(layout)
    cases = []
    for name, (code, *_rest) in US_BY_NAME.items():
        for layer, text in outputs[name].items():
            cases.append({"key": name, "code": code, "layer": layer, "text": text})
    for layer, text in outputs["`"].items():
        cases.append({"key": "iso-section", "code": ISO_SECTION, "layer": layer, "text": text})
    for code, text in SPECIAL.items():
        for layer, _ in MODIFIERS:
            cases.append({"key": f"special-{code}", "code": code, "layer": layer, "text": text})
    return {"source_id": source_id(layout), "cases": cases}


def swift_string(s: str) -> str:
    return json.dumps(s, ensure_ascii=False)


def build_ios(layouts: list[dict]) -> Path:
    out = ROOT / "ios" / "Keyboard" / "Generated" / "Layouts.swift"
    out.parent.mkdir(parents=True, exist_ok=True)
    lines = [
        "// Generated by tools/build.py from layouts/*.toml. Do not edit.",
        "",
        "enum Layouts {",
        "    static let all: [KeyboardLayout] = [",
    ]
    for layout in layouts:
        t = layout["touch"]
        keys = layout["keys"]

        def letter(name: str) -> str:
            plain, shift = keys[name]
            return f"LetterKey({swift_string(plain)}, {swift_string(shift)})"

        def rows(rs: list[list[str]], fn) -> str:
            return "[\n" + "".join(
                "            [" + ", ".join(fn(k) for k in r) + "],\n" for r in rs
            ) + "        ]"

        lines += [
            "        KeyboardLayout(",
            f"            id: {swift_string(layout['id'])},",
            f"            name: {swift_string(layout['name'])},",
            f"            shortName: {swift_string(layout['short_name'])},",
            f"            letterRows: {rows(t['letter_rows'], letter)},",
            f"            symbolRows: {rows(t['symbol_rows'], swift_string)},",
            f"            moreSymbolRows: {rows(t['more_symbol_rows'], swift_string)},",
            f"            spaceLabel: {swift_string(t['space_label'])},",
            f"            spaceLeft: {swift_string(t['space_left'])},",
            f"            spaceRight: {swift_string(t['space_right'])},",
            f"            doubleSpace: {swift_string(t['double_space'])},",
            f"            sentenceEnders: [{', '.join(swift_string(c) for c in t['sentence_enders'])}]",
            "        ),",
        ]
    lines += ["    ]", "}", ""]
    out.write_text("\n".join(lines), encoding="utf-8")
    return out


def build_site(layouts: list[dict]) -> Path:
    out = ROOT / "docs" / "layouts.json"
    data = []
    for layout in layouts:
        outputs = layer_outputs(layout)
        data.append({
            "id": layout["id"],
            "name": layout["name"],
            "rows": [[{"key": k, **{l: outputs[k][l] for l in ("plain", "shift", "option", "option_shift")}} for k in row] for row in KEY_ROWS],
        })
    out.write_text(json.dumps(data, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    return out


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--version", default="0.1.0")
    parser.add_argument("--id-for", help="print the id of the layout with this name and exit")
    args = parser.parse_args()
    layouts = load_layouts()
    if args.id_for:
        print(next(l["id"] for l in layouts if l["name"] == args.id_for))
        return
    bundle = build_mac(layouts, args.version)
    exp_dir = BUILD / "expected"
    exp_dir.mkdir(parents=True, exist_ok=True)
    for layout in layouts:
        (exp_dir / f"{layout['id']}.json").write_text(json.dumps(expected(layout), ensure_ascii=False), encoding="utf-8")
    print(bundle.relative_to(ROOT))
    print(build_ios(layouts).relative_to(ROOT))
    print(build_site(layouts).relative_to(ROOT))


if __name__ == "__main__":
    main()
