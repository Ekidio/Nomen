import SwiftUI
import NomenCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    /// Files dropped on the Dock icon or opened with "Open With"; buffered until the window is up.
    private var pending: [URL] = []
    var onOpen: (([URL]) -> Void)? {
        didSet {
            guard let onOpen, !pending.isEmpty else { return }
            onOpen(pending)
            pending = []
        }
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        if let onOpen { onOpen(urls) } else { pending += urls }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        removeHelpMenu()
        // SwiftUI rebuilds the menu bar (e.g. on language change) and puts Help back.
        NotificationCenter.default.addObserver(forName: NSMenu.didAddItemNotification, object: nil, queue: .main) { [weak self] _ in
            DispatchQueue.main.async { self?.removeHelpMenu() }
        }
    }

    private func removeHelpMenu() {
        guard let mainMenu = NSApp.mainMenu else { return }
        for item in mainMenu.items where item.submenu === NSApp.helpMenu || ["Help", "Súgó"].contains(item.title) {
            mainMenu.removeItem(item)
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}

@main
struct NomenApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var model = NomenModel()

    var body: some Scene {
        Window("Nomen", id: "main") {
            ContentView(model: model)
                .id(model.language)
                .environment(\.locale, model.language.locale)
                .onAppear { appDelegate.onOpen = { [model] in model.add($0) } }
                .frame(minWidth: 900, minHeight: 500)
        }
        .defaultSize(width: 1040, height: 660)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .help) {}
            CommandGroup(after: .appSettings) {
                Picker(L("Nyelv", "Language"), selection: Binding(get: { model.language }, set: { model.language = $0 })) {
                    ForEach(AppLanguage.allCases) { Text($0.displayName).tag($0) }
                }
            }
            CommandGroup(replacing: .newItem) {
                Button(L("Fájlok hozzáadása…", "Add Files…")) { model.showOpenPanel() }
                    .keyboardShortcut("o")
            }
            CommandMenu(L("Fájlok", "Files")) {
                Button(L("Átnevezés", "Rename")) { model.rename() }
                    .keyboardShortcut("r")
                    .disabled(!model.canRename)
                Button(L("Átnevezés visszavonása", "Undo Rename")) { model.undo() }
                    .keyboardShortcut("z", modifiers: [.command, .option])
                    .disabled(model.lastRename.isEmpty)
                Divider()
                Button(L("Kijelöltek feljebb", "Move Selected Up")) { model.moveSelected(by: -1) }
                    .keyboardShortcut(.upArrow, modifiers: [.command, .option])
                Button(L("Kijelöltek lejjebb", "Move Selected Down")) { model.moveSelected(by: 1) }
                    .keyboardShortcut(.downArrow, modifiers: [.command, .option])
                Divider()
                Button(L("Kijelöltek eltávolítása a listából", "Remove Selected from List")) { model.removeSelected() }
                Button(L("Lista ürítése", "Clear List")) { model.clear() }
                    .keyboardShortcut(.delete, modifiers: [.command, .shift])
            }
            CommandMenu(L("Mód", "Mode")) {
                ForEach(RenameMode.allCases) { mode in
                    Button(mode.title) { model.settings.mode = mode }
                        .keyboardShortcut(KeyEquivalent(mode.shortcut), modifiers: [.control, .command])
                }
            }
        }
    }
}
