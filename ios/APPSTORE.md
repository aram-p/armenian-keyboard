# App Store release

Everything that can be prepared in the repo is ready. The steps at the end need the
owner's Apple Developer account.

## Identifiers

| What | Value |
|---|---|
| App bundle id | `io.github.aramp.armeniankeyboard` |
| Keyboard extension bundle id | `io.github.aramp.armeniankeyboard.keyboard` |
| Version / build | 0.1.0 / 1 (`ios/project.yml`) |
| Home-screen name | Հայերեն |
| Category | Utilities |
| Minimum iOS | 17.0, iPhone only |
| Encryption | None (`ITSAppUsesNonExemptEncryption = NO`) |

## Listing text

**Name:** Armenian Keyboard — Հայերեն
**Subtitle:** Phonetic layout with ։ « » և

**Description:**

> A free Armenian phonetic keyboard. Letters sit where they sound on an English keyboard,
> in the same places as the Windows "Armenian Phonetic" layout, so there is nothing to relearn.
>
> • ։ next to the space bar, and two quick spaces end the sentence with ։
> • The numbers page puts Armenian punctuation first: ։ ՝ ՛ ՞ ՜ « » և ֊ ֏
> • Shift, caps lock, delete that repeats, light and dark mode
> • No Full Access, no network, nothing collected
>
> Open source: https://github.com/aram-p/armenian-keyboard

**Keywords:** armenian,keyboard,hayeren,phonetic,հայերեն,ստեղնաշար,armenia,yerevan
**Support URL:** https://github.com/aram-p/armenian-keyboard/issues
**Marketing URL:** https://aram-p.github.io/armenian-keyboard/
**Privacy policy URL:** https://aram-p.github.io/armenian-keyboard/privacy.html

## Privacy

- App Privacy questionnaire: **Data Not Collected**.
- The keyboard does not request Full Access (`RequestsOpenAccess = false`), so iOS gives it
  no network access and no shared storage. What you type never leaves the keyboard.
- Privacy policy text is in [`docs/privacy.html`](../docs/privacy.html).

## Review notes (paste into "Notes for the reviewer")

> This is a custom keyboard. To try it: Settings → General → Keyboard → Keyboards →
> Add New Keyboard… → Հայերեն. Then open the app and tap the globe key in the
> "Try it" field. The keyboard does not request Full Access.

## Screenshots

`docs/screenshots/` has 1206 × 2622 (6.3-inch) simulator screenshots of the letters page,
the punctuation page and dark mode. App Store Connect also wants one 6.9-inch set
(1320 × 2868); take it on an iPhone 16 Pro Max simulator before submitting.

## What the owner must do

1. Join the Apple Developer Program (99 USD a year) if not already a member.
2. In Xcode, open `ios/ArmenianKeyboard.xcodeproj`, pick the team for both targets
   (or set `DEVELOPMENT_TEAM` in `ios/project.yml` and run `xcodegen`).
3. In App Store Connect, create the app with bundle id `io.github.aramp.armeniankeyboard`
   (Xcode registers both ids on the first archive).
4. Product → Archive → Distribute App → App Store Connect.
5. Fill the listing from this file, upload the screenshots, answer the privacy
   questionnaire with "Data Not Collected", and submit for review.
