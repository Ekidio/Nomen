import AppKit
import Observation
import NomenCore

struct FileItem: Identifiable {
    let id: UUID
    var url: URL
    var name: String
    var isDirectory: Bool
    var created: Date?
    var modified: Date
    /// The file's Finder icon.
    var icon: NSImage

    init(url: URL, id: UUID = UUID()) {
        let values = try? url.resourceValues(forKeys: [
            .isDirectoryKey, .isPackageKey, .creationDateKey, .contentModificationDateKey,
        ])
        self.id = id
        self.url = url
        self.name = url.lastPathComponent
        self.isDirectory = (values?.isDirectory ?? false) && !(values?.isPackage ?? false)
        self.created = values?.creationDate
        self.modified = values?.contentModificationDate ?? .distantPast
        self.icon = NSWorkspace.shared.icon(forFile: url.path)
    }

    var info: FileInfo {
        FileInfo(name: name, isDirectory: isDirectory, created: created, modified: modified)
    }
}

struct Toast: Equatable {
    let id = UUID()
    var text: String
    var symbol: String
}

struct Preview {
    var newName: String
    var issue: RenameIssue?
    var isChange: Bool
}

@MainActor
@Observable
final class NomenModel {
    var items: [FileItem] = []
    var selection: Set<FileItem.ID> = []
    var settings = RenameSettings()
    var sortOrder: [KeyPathComparator<FileItem>] = [] {
        didSet { items.sort(using: sortOrder) }
    }
    var lastRename: [RenamePlanItem] = []
    var language: AppLanguage = NomenModel.storedLanguage {
        didSet {
            AppLanguage.current = language
            UserDefaults.standard.set(language.rawValue, forKey: "language")
            // Standard system menu items (Edit, Window, Quit…) follow this on next launch.
            UserDefaults.standard.set([language.rawValue], forKey: "AppleLanguages")
        }
    }
    var alertMessage: String?
    /// Short confirmation shown after a rename or undo.
    var toast: Toast?

    init() {
        AppLanguage.current = language
    }

    private static var storedLanguage: AppLanguage {
        UserDefaults.standard.string(forKey: "language").flatMap(AppLanguage.init(rawValue:)) ?? .systemDefault
    }

    /// New names for the current list, plus a pattern error if the rule can't run.
    var previews: (byID: [FileItem.ID: Preview], error: String?) {
        var names: [String]
        var patternError: String?
        do {
            names = try items.enumerated().map { index, item in
                try RenameRule.newName(for: item.info, index: index, settings: settings)
            }
        } catch {
            names = items.map(\.name)
            patternError = error.localizedDescription
        }
        let plan = zip(items, names).map { RenamePlanItem(source: $0.url, newName: $1) }
        let issues = RenameEngine.validate(plan)
        var byID: [FileItem.ID: Preview] = [:]
        for (index, item) in items.enumerated() {
            byID[item.id] = Preview(newName: names[index], issue: issues[index], isChange: plan[index].isChange)
        }
        return (byID, patternError)
    }

    // MARK: - List

    func add(_ urls: [URL]) {
        let existing = Set(items.map { $0.url.standardizedFileURL.path })
        let new = urls
            .filter { $0.isFileURL && !existing.contains($0.standardizedFileURL.path) }
            .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
            .map { FileItem(url: $0) }
        items.append(contentsOf: new)
        if !sortOrder.isEmpty { items.sort(using: sortOrder) }
    }

    func showOpenPanel() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.prompt = L("Hozzáadás", "Add")
        if panel.runModal() == .OK { add(panel.urls) }
    }

    func removeSelected() {
        items.removeAll { selection.contains($0.id) }
        selection.removeAll()
    }

    func clear() {
        items.removeAll()
        selection.removeAll()
        lastRename.removeAll()
    }

    func moveSelected(by offset: Int) {
        let indices = items.indices.filter { selection.contains(items[$0].id) }
        guard !indices.isEmpty else { return }
        sortOrder = []
        let ordered = offset < 0 ? indices : indices.reversed()
        for index in ordered {
            let target = index + offset
            guard items.indices.contains(target), !selection.contains(items[target].id) else { continue }
            items.swapAt(index, target)
        }
    }

    // MARK: - Rename

    var canRename: Bool {
        let p = previews
        return p.error == nil
            && p.byID.values.contains(where: \.isChange)
            && !p.byID.values.contains(where: { $0.issue != nil })
    }

    func rename() {
        guard canRename else { return }
        let p = previews.byID
        let plan = items.map { RenamePlanItem(source: $0.url, newName: p[$0.id]?.newName ?? $0.name) }
        run(plan) { done in
            self.lastRename = done
            self.toast = Toast(text: L("\(done.count) fájl átnevezve", "\(done.count) \(done.count == 1 ? "file" : "files") renamed"), symbol: "checkmark.circle.fill")
        }
    }

    func undo() {
        guard !lastRename.isEmpty else { return }
        run(RenameEngine.undoPlan(for: lastRename)) { done in
            self.lastRename = []
            self.toast = Toast(text: L("\(done.count) fájl visszaállítva", "\(done.count) \(done.count == 1 ? "file" : "files") restored"), symbol: "arrow.uturn.backward.circle.fill")
        }
    }

    private func run(_ plan: [RenamePlanItem], onSuccess: ([RenamePlanItem]) -> Void) {
        do {
            let done = try RenameEngine.perform(plan)
            let moved = Dictionary(uniqueKeysWithValues: done.map { ($0.source.standardizedFileURL.path, $0.destination) })
            items = items.map { item in
                guard let destination = moved[item.url.standardizedFileURL.path] else { return item }
                return FileItem(url: destination, id: item.id)
            }
            onSuccess(done)
        } catch {
            alertMessage = L("Az átnevezés nem sikerült, minden fájl visszakapta az eredeti nevét.\n\n\(error.localizedDescription)", "Renaming failed; every file got its original name back.\n\n\(error.localizedDescription)")
        }
    }
}
