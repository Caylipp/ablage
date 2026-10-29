# Ablage: Clipboard History for iPhone

[Deutsche Version](README.de.md)

A free, local-only clipboard history for iOS. Everything stays on the device.

## v2 (current): native app with a custom keyboard

Copy something, tap into any text field, switch to the **Ablage keyboard**: it saves the current clipboard automatically and shows two tabs, **History** and **Pinned** (notes and boards). Tapping an entry inserts the text directly; images and files are put on the clipboard for pasting.

- Native Swift app in [`native/`](native/): main app, keyboard extension, widgets and shared storage via an App Group
- Project generated with XcodeGen (`project.yml`), unit tests in `native/Tests`
- Setup tab in the app checks whether the keyboard and full access are enabled

```sh
cd native && xcodegen generate && open Ablage.xcodeproj
```

## v1 (archive): Expo / React Native

Kept in the repository root. Cards for text, links, images, colors, code, emails and phone numbers; deduplication (an existing entry just moves to the top), search and type filters, color-coded boards that survive "clear history", and a URL scheme (`ablage://add?text=…`) for Shortcuts and Back Tap. Pure logic (type detection, history reducer, hashing) in `src/lib/` with tests.

```sh
npm install && npm start    # Expo Go
npm run check               # typecheck, lint, tests
```

## Why a keyboard?

iOS does not let any app read the clipboard in the background. v1 could only capture when opened; a keyboard extension is the one place where saving happens naturally while you type. Requirements, design decisions and a retrospective are documented in [docs/](docs/) (German).
