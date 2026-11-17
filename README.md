# Armenian Keyboard

A free Armenian phonetic keyboard for **Mac** and **iPhone**.

- Letters sit on the English keys that sound the same, in the same places as the Windows
  “Armenian Phonetic” layout, so there is nothing to relearn.
- The Armenian punctuation is where you expect it: **։** on the period key, **« »** on
  Shift+, and Shift+., **՝ ՛ ՞ ՜** and **և** one key away.
- On the Mac, hold **Option** to type English (digits, Latin letters, every ASCII symbol).

**Download and install:** https://aram-p.github.io/armenian-keyboard/
**The layout and why:** [docs/layout.md](docs/layout.md)

## Repository

| Path | What |
|---|---|
| `layouts/*.toml` | The layouts. The only place keys are defined. |
| `tools/build.py` | Generates the Mac `.keylayout` bundle, the iPhone key grid and the website data from `layouts/`. |
| `tools/test_mac.sh` | Installs a test copy and checks every key on every modifier layer through macOS itself. |
| `tools/package_mac.sh` | Builds `dist/ArmenianKeyboard-mac.zip` and `.pkg`. |
| `mac/` | Mac icon, installer texts. |
| `ios/` | iPhone app (SwiftUI) and keyboard extension. `cd ios && xcodegen` regenerates the Xcode project. |
| `docs/` | The website (GitHub Pages). |
| `art/` | Source artwork; `tools/make_icons.sh` turns it into the app and layout icons. |

## Build

```sh
python3 tools/build.py          # regenerate everything from layouts/
tools/test_mac.sh               # check the Mac layout key by key
tools/package_mac.sh 0.1.0      # Mac downloads into dist/
cd ios && xcodebuild -scheme ArmenianKeyboard -sdk iphonesimulator build
```

## Adding a layout

Copy `layouts/armenian-phonetic.toml`, change the id, name and keys, run `python3 tools/build.py`.
The Mac bundle and the iPhone keyboard pick it up.

## License

MIT
