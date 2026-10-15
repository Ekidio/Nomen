import Foundation

public struct RenamePlanItem: Equatable, Sendable {
    public var source: URL
    public var newName: String

    public init(source: URL, newName: String) {
        self.source = source
        self.newName = newName
    }

    public var destination: URL {
        source.deletingLastPathComponent().appendingPathComponent(newName)
    }

    public var isChange: Bool { source.lastPathComponent != newName }
}

public enum RenameIssue: Equatable, Sendable {
    case empty, invalidCharacters, duplicate, alreadyExists

    public var message: String {
        switch self {
        case .empty: L("Üres név", "Empty name")
        case .invalidCharacters: L("A név nem tartalmazhat „/” vagy „:” karaktert", "The name can't contain “/” or “:”")
        case .duplicate: L("Több fájl kapná ugyanezt a nevet", "Several files would get this name")
        case .alreadyExists: L("Már létezik ilyen nevű fájl", "A file with this name already exists")
        }
    }
}

public enum RenameEngine {
    /// Problems keyed by plan index. An empty result means the plan is safe to run.
    public static func validate(
        _ plan: [RenamePlanItem],
        fileExists: (URL) -> Bool = { FileManager.default.fileExists(atPath: $0.path) }
    ) -> [Int: RenameIssue] {
        // APFS/HFS+ are usually case-insensitive, so compare paths case-insensitively.
        func key(_ url: URL) -> String {
            url.standardizedFileURL.path.precomposedStringWithCanonicalMapping.lowercased()
        }
        let sources = Set(plan.map { key($0.source) })
        var destinationCounts: [String: Int] = [:]
        for item in plan { destinationCounts[key(item.destination), default: 0] += 1 }

        var issues: [Int: RenameIssue] = [:]
        for (index, item) in plan.enumerated() {
            let name = item.newName
            if name.isEmpty || name == "." || name == ".." {
                issues[index] = .empty
            } else if name.contains("/") || name.contains(":") {
                issues[index] = .invalidCharacters
            } else if destinationCounts[key(item.destination), default: 0] > 1 {
                issues[index] = .duplicate
            } else if item.isChange, !sources.contains(key(item.destination)), fileExists(item.destination) {
                issues[index] = .alreadyExists
            }
        }
        return issues
    }

    /// Renames in two passes (via temporary names) so swaps like a→b, b→a work.
    /// On failure everything already moved is put back. Returns the renames actually made.
    @discardableResult
    public static func perform(_ plan: [RenamePlanItem], fileManager: FileManager = .default) throws -> [RenamePlanItem] {
        let changes = plan.filter(\.isChange)
        var parked: [(item: RenamePlanItem, temp: URL)] = []

        do {
            for item in changes {
                let temp = item.source.deletingLastPathComponent()
                    .appendingPathComponent(".nomen-\(UUID().uuidString)")
                try fileManager.moveItem(at: item.source, to: temp)
                parked.append((item, temp))
            }
        } catch {
            for (item, temp) in parked.reversed() {
                try? fileManager.moveItem(at: temp, to: item.source)
            }
            throw error
        }

        var done: [RenamePlanItem] = []
        for (position, entry) in parked.enumerated() {
            do {
                try fileManager.moveItem(at: entry.temp, to: entry.item.destination)
                done.append(entry.item)
            } catch {
                for item in done.reversed() {
                    try? fileManager.moveItem(at: item.destination, to: item.source)
                }
                for (item, temp) in parked[position...] {
                    try? fileManager.moveItem(at: temp, to: item.source)
                }
                throw error
            }
        }
        return done
    }

    /// The plan that reverses `done`.
    public static func undoPlan(for done: [RenamePlanItem]) -> [RenamePlanItem] {
        done.map { RenamePlanItem(source: $0.destination, newName: $0.source.lastPathComponent) }
    }
}
