---
title: Armenian Phonetic Plus — the layout
---

# The layout

Source of truth: [`layouts/armenian-phonetic.toml`](https://github.com/aram-p/armenian-keyboard/blob/main/layouts/armenian-phonetic.toml).
The Mac `.keylayout`, the iPhone key grid and the picture on the website are all generated from it by `tools/build.py`.

## Letters: the Windows "Armenian Phonetic" layout

Most people in Armenia learned to type on Windows, so the letters follow the Windows
**Armenian Phonetic** layout (KBDARMPH) exactly. Anyone who types Armenian on Windows
can type on this layout without relearning anything.

| Row | Keys → letters |
|---|---|
| Number row | ` ՝ · 1 է · 2 թ · 3 փ · 4 ձ · 5 ջ · 6 ւ · 7 և · 8 ր · 9 չ · 0 ճ · - - · = ժ |
| Top row | q ք · w ո · e ե · r ռ · t տ · y ը · u ւ · i ի · o օ · p պ · [ խ · ] ծ · \ շ |
| Home row | a ա · s ս · d դ · f ֆ · g գ · h հ · j յ · k կ · l լ · ; ; · ' ՛ |
| Bottom row | z զ · x ղ · c ց · v վ · b բ · n ն · m մ · , , · . ։ · / / |

Shift gives the capital letter.

### Layouts we compared

| Layout | Where | How it differs |
|---|---|---|
| Windows Armenian Phonetic | Built into Windows | The convention we follow for letters. Digits need AltGr; ։ is on Shift+; and « » only exist on the extra ISO key, which US-style keyboards don't have. |
| Apple "Armenian – HM QWERTY" | Built into macOS | Different letter places (q ճ, w ւ, o ո, j ձ, x խ, c ծ), 13 letters only on Option; ։ ՝ ՞ « » և all behind Option. |
| Apple "Armenian – Western QWERTY" | Built into macOS | Western Armenian; letter places differ a lot. |
| Community "Armenian Phonetic" (Ukelele) | Mac downloads | Same as Windows but with r ր / 8 ռ swapped in one variant. |

We keep **r = ռ, 8 = ր** as on Windows. Swapping them is a one-line change in the source
file if that turns out to be what people want.

## What is better here: punctuation

| Mark | Name | Key | Windows | Apple HM |
|---|---|---|---|---|
| ։ | verjaket (full stop) | **.** | Shift+; | Option+. |
| , | comma | **,** | , | , |
| ՝ | but (comma-like pause) | **`** | ` | Option+, |
| ՛ | emphasis | **'** | ' | Option+' |
| ՞ | question | **Shift+/** | Shift+/ | Option+/ |
| ՜ | exclamation | **Shift+`** | Shift+` | Option+1 |
| « » | quotes | **Shift+,  Shift+.** | ISO key only | Option+9 / 0 |
| և | yev ligature | **7** | 7 | Option+V |
| — | dash | **Shift+-** | Shift+- | Option+Shift+- |

- The sentence end ։ is the most-typed mark in Armenian, so it gets the period key with no Shift.
- « » sit on Shift+, and Shift+. — the same keys as < > on an English keyboard, so they are easy to find.
- Shift+7 types **Եվ** (for the start of a sentence) and Caps Lock+7 types **ԵՎ**.
- Shift+; types a plain Latin period, for numbers, abbreviations and web addresses.
- Caps Lock only changes letters; punctuation keys keep typing punctuation.

## Mac: English is one key away

Hold **Option** and every key types exactly what it types on the US English keyboard:
Option+1 is 1, Option+Shift+1 is !, Option+A is a. Keyboard shortcuts (⌘C, ⌘V …) work
as usual.

## iPhone

- Letters are in the same places as on the Mac, in four rows: the number-row letters on top
  (է թ փ ձ ջ և ր չ ճ ժ), then the Q, A and Z rows. ւ, already on U, is not repeated.
- Next to the space bar: , on the left, ։ on the right.
- Two quick spaces type ։ and a space; the next letter is capitalised.
- **123** opens numbers with Armenian punctuation first: ։ ՝ ՛ ՞ ՜ « » և ֊ ֏.
- **#+=** has brackets, maths signs, currency (֏ $ € ₽) and the rare marks ՚ ՟.

## Adding another layout

Copy `layouts/armenian-phonetic.toml` to, for example, `layouts/russian-phonetic.toml`,
change the id, name and keys, and run `python3 tools/build.py`. The Mac bundle and the
iPhone keyboard pick it up automatically.
