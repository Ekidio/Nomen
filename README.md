<p align="center">
  <img src="Resources/AppIcon.png" width="128" alt="Nomen icon">
</p>

<h1 align="center">Nomen</h1>

<p align="center">
  Batch file renamer for macOS · Tömeges fájlátnevező macOS-re<br>
  <a href="#english">English</a> · <a href="#magyar">Magyar</a>
</p>

---

## English

Nomen renames many files and folders at once. You see every new name before anything changes on disk. It was inspired by NameChanger, and it keeps the file extension when you number files.

![Nomen in English](docs/screenshot-en.png)

### Download

**[⬇ Download Nomen.dmg](https://github.com/Ekidio/Nomen/releases/latest/download/Nomen.dmg)** (macOS 14+, Apple Silicon and Intel)

1. Open the DMG and drag **Nomen** into **Applications**.
2. Nomen is not notarized by Apple, so the first launch is blocked with a warning. Open **System Settings → Privacy & Security**, scroll down and click **Open Anyway** next to Nomen.
   You can also run this in Terminal instead:
   ```bash
   xattr -dr com.apple.quarantine /Applications/Nomen.app
   ```

All versions are on the [Releases](https://github.com/Ekidio/Nomen/releases) page.

### Features

- **12 rename modes:** replace first / last / all occurrences, wildcard (`*`, `?`), append, prepend, remove characters, insert characters, change case, sequence, date, regular expression (with `$1`, `$2` groups)
- **Sequence mode:** set the start number, step, digit count (`001`, `002` …), separator and position, and optionally keep the original name. It follows the list order, which you can sort or rearrange.
- **Keeps the extension:** rules change only the name by default, so `IMG_9921.JPG` becomes `Holiday_001.JPG`. This can be switched off.
- **Live preview:** every new name is shown next to the original before you rename.
- **Conflict detection:** duplicate names, existing files and invalid characters are marked in red, and renaming is blocked until they are fixed.
- **Safe renaming:** swaps (a→b, b→a) and case-only renames work. If an error occurs, every file gets its original name back, and the last rename can be undone (⌥⌘Z).
- **Adding files:** drag them into the window, drop them on the Dock icon, use *Open With → Nomen*, or press ⌘O.
- **English and Hungarian interface,** switchable at any time with the 🌐 button.
- Uses the same keyboard shortcuts as NameChanger (⌃⌘F, ⌃⌘S, ⌃⌘R …).

### Requirements

macOS 14 Sonoma or later.

### Build from source

You need Xcode or the Swift 5.10+ toolchain.

```bash
git clone https://github.com/Ekidio/Nomen.git
cd Nomen
./build-app.sh                    # builds build/Nomen.app
./make-dmg.sh                     # builds build/Nomen-<version>.dmg
cp -R build/Nomen.app /Applications/
```

The app is ad-hoc signed and not notarized; see the steps under **Download** for the first launch.

```bash
swift test                        # runs the tests
swift Scripts/make-icon.swift .   # regenerates the app icon
```

---

## Magyar

A Nomen egyszerre sok fájlt és mappát nevez át. Minden új nevet előre látsz, és a lemezen semmi sem változik, amíg rá nem kattintasz az Átnevezésre. A NameChanger ihlette, de sorszámozáskor nem veszíti el a fájlok kiterjesztését.

![A Nomen magyarul](docs/screenshot-hu.png)

### Letöltés

**[⬇ Nomen.dmg letöltése](https://github.com/Ekidio/Nomen/releases/latest/download/Nomen.dmg)** (macOS 14+, Apple Silicon és Intel)

1. Nyisd meg a DMG-t, és húzd a **Nomen**-t az **Applications** (Programok) mappába.
2. A Nomen nincs az Apple által notarizálva, ezért az első indítást a macOS figyelmeztetéssel letiltja. Nyisd meg a **Rendszerbeállítások → Adatvédelem és biztonság** panelt, görgess le, és kattints a Nomen melletti **Megnyitás mégis** gombra.
   Ehelyett a Terminálban ezt is lefuttathatod:
   ```bash
   xattr -dr com.apple.quarantine /Applications/Nomen.app
   ```

Az összes verzió a [Releases](https://github.com/Ekidio/Nomen/releases) oldalon érhető el.

### Funkciók

- **12 átnevezési mód:** első, utolsó vagy összes előfordulás cseréje, helyettesítő karakterek (`*`, `?`), hozzáfűzés a végére vagy az elejére, karakterek törlése és beszúrása, kis- és nagybetűk, sorszámozás, dátum, reguláris kifejezés (`$1`, `$2` csoportokkal)
- **Sorszámozás:** beállítható a kezdőszám, a lépésköz, a számjegyek száma (`001`, `002` …), az elválasztó és a szám helye, és az eredeti név is megtartható. A számozás a lista sorrendjét követi, ami rendezhető és kézzel is átrendezhető.
- **Megmarad a kiterjesztés:** a szabályok alapból csak a nevet módosítják, így az `IMG_9921.JPG` fájlból `Nyaralas_001.JPG` lesz. Ez kikapcsolható.
- **Élő előnézet:** minden új név az eredeti mellett látszik, még az átnevezés előtt.
- **Ütközések jelzése:** az azonos nevek, a már létező fájlok és a tiltott karakterek pirossal jelennek meg, és amíg ezeket nem javítod, az átnevezés nem indítható el.
- **Biztonságos átnevezés:** működik a névcsere (a→b, b→a) és a csak kis- és nagybetűben eltérő átnevezés is. Hiba esetén minden fájl visszakapja az eredeti nevét, az utolsó átnevezés pedig visszavonható (⌥⌘Z).
- **Fájlok hozzáadása:** húzd be őket az ablakba, dobd rá a Dock-ikonra, használd a *Megnyitás ezzel → Nomen* parancsot, vagy nyomd meg a ⌘O-t.
- **Magyar és angol felület,** a 🌐 gombbal bármikor váltható.
- Ugyanazok a billentyűparancsok, mint a NameChangerben (⌃⌘F, ⌃⌘S, ⌃⌘R …).

### Követelmények

macOS 14 Sonoma vagy újabb.

### Fordítás forráskódból

Xcode vagy a Swift 5.10+ eszközkészlet kell hozzá.

```bash
git clone https://github.com/Ekidio/Nomen.git
cd Nomen
./build-app.sh                    # elkészíti a build/Nomen.app-ot
./make-dmg.sh                     # elkészíti a build/Nomen-<verzió>.dmg-t
cp -R build/Nomen.app /Applications/
```

Az app ad-hoc aláírású, és nincs notarizálva; az első indításhoz lásd a **Letöltés** részben leírt lépéseket.

```bash
swift test                        # lefuttatja a teszteket
swift Scripts/make-icon.swift .   # újra legenerálja az ikont
```

---

## License · Licenc

[MIT](LICENSE) © 2026 Ekidio
