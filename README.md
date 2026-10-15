# Nomen

Batch file renamer for macOS, inspired by NameChanger. / Tömeges fájlátnevező macOS-re.

![icon](Resources/AppIcon.png)

## Features

- 12 modes: replace first / last / all, wildcard, append, prepend, remove, insert, change case, sequence, date, regex
- Keeps the file extension (toggle), live preview, conflict detection
- Safe renaming (swaps work, automatic rollback on error) and undo
- Drag & drop, Dock icon drop, "Open With → Nomen"
- English and Hungarian UI

## Build

Requires macOS 14+ and Xcode / Swift 5.10+.

```bash
./build-app.sh            # builds build/Nomen.app
swift test                # runs the tests
swift Scripts/make-icon.swift .   # regenerates the app icon
```
