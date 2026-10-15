import Foundation

public enum RenameMode: String, CaseIterable, Identifiable, Sendable {
    case replaceFirst, replaceLast, replaceAll, wildcard, append, prepend
    case removeCharacters, insertCharacters, changeCase, sequence, date, regex

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .replaceFirst: L("Első előfordulás cseréje", "Replace First Occurrence")
        case .replaceLast: L("Utolsó előfordulás cseréje", "Replace Last Occurrence")
        case .replaceAll: L("Összes előfordulás cseréje", "Replace All Occurrences")
        case .wildcard: L("Helyettesítő karakterek (*, ?)", "Wildcard (*, ?)")
        case .append: L("Hozzáfűzés a végére", "Append")
        case .prepend: L("Hozzáfűzés az elejére", "Prepend")
        case .removeCharacters: L("Karakterek törlése", "Remove Characters")
        case .insertCharacters: L("Karakterek beszúrása", "Insert Characters")
        case .changeCase: L("Kis-/nagybetű", "Change Case")
        case .sequence: L("Sorszámozás", "Sequence")
        case .date: L("Dátum", "Date")
        case .regex: L("Reguláris kifejezés", "Regular Expression")
        }
    }

    /// Same ^⌘ shortcuts as NameChanger.
    public var shortcut: Character {
        switch self {
        case .replaceFirst: "f"
        case .replaceLast: "l"
        case .replaceAll: "a"
        case .wildcard: "w"
        case .append: "n"
        case .prepend: "p"
        case .removeCharacters: "m"
        case .insertCharacters: "i"
        case .changeCase: "c"
        case .sequence: "s"
        case .date: "d"
        case .regex: "r"
        }
    }

    /// The mode reads the "original text" (search) field.
    public var usesFind: Bool {
        [.replaceFirst, .replaceLast, .replaceAll, .wildcard, .regex].contains(self)
    }

    /// The mode reads the "new text" field.
    public var usesText: Bool {
        ![.removeCharacters, .changeCase, .date].contains(self)
    }
}

public enum TextAnchor: String, CaseIterable, Identifiable, Sendable {
    case start, end
    public var id: String { rawValue }
}

public enum CaseStyle: String, CaseIterable, Identifiable, Sendable {
    case lower, upper, title, sentence
    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .lower: L("kisbetű", "lowercase")
        case .upper: L("NAGYBETŰ", "UPPERCASE")
        case .title: L("Minden Szó Nagy", "Title Case")
        case .sentence: L("Mondat eleje nagy", "Sentence case")
        }
    }
}

public enum DateSource: String, CaseIterable, Identifiable, Sendable {
    case today, created, modified
    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .today: L("Mai nap", "Today")
        case .created: L("Létrehozás", "Created")
        case .modified: L("Módosítás", "Modified")
        }
    }
}

public enum DatePlacement: String, CaseIterable, Identifiable, Sendable {
    case prepend, append, replace
    public var id: String { rawValue }
    public var title: String {
        switch self {
        case .prepend: L("Elejére", "Start")
        case .append: L("Végére", "End")
        case .replace: L("Név helyett", "Replace name")
        }
    }
}

public struct RenameSettings: Equatable, Sendable {
    public var mode: RenameMode = .sequence
    /// "Original text" field: search string, wildcard or regex pattern.
    public var find = ""
    /// "New text" field: replacement, appended/inserted text, sequence base name.
    public var text = ""
    public var caseSensitive = true
    /// Transforms only touch the base name; the extension is put back untouched.
    public var keepExtension = true

    public var removeCount = 1
    public var removeOffset = 0
    public var removeFrom: TextAnchor = .start

    public var insertOffset = 0
    public var insertFrom: TextAnchor = .start

    public var caseStyle: CaseStyle = .lower

    public var sequenceStart = 1
    public var sequenceStep = 1
    public var sequenceDigits = 3
    public var sequenceSeparator = "_"
    public var sequenceNumberFirst = false
    public var sequenceKeepName = false

    public var dateSource: DateSource = .modified
    public var dateFormat = "yyyy-MM-dd"
    public var datePlacement: DatePlacement = .prepend
    public var dateSeparator = " "

    public init() {}
}

public struct FileInfo: Sendable {
    public var name: String
    /// True for plain folders; packages like .app count as files so their extension is kept.
    public var isDirectory: Bool
    public var created: Date?
    public var modified: Date?

    public init(name: String, isDirectory: Bool = false, created: Date? = nil, modified: Date? = nil) {
        self.name = name
        self.isDirectory = isDirectory
        self.created = created
        self.modified = modified
    }
}

public enum RenameRuleError: LocalizedError, Equatable {
    case invalidPattern(String)

    public var errorDescription: String? {
        switch self {
        case .invalidPattern(let message): L("Hibás minta: \(message)", "Invalid pattern: \(message)")
        }
    }
}

public enum RenameRule {
    /// Splits "photo.final.JPG" into ("photo.final", ".JPG").
    public static func split(_ name: String, isDirectory: Bool, keepExtension: Bool) -> (base: String, ext: String) {
        guard keepExtension, !isDirectory else { return (name, "") }
        let ext = (name as NSString).pathExtension
        guard !ext.isEmpty else { return (name, "") }
        let base = String(name.dropLast(ext.count + 1))
        // Dotfiles like ".gitignore" have no extension.
        guard !base.isEmpty else { return (name, "") }
        return (base, "." + ext)
    }

    /// The new name for `file`, which sits at `index` in the list (used by sequence mode).
    public static func newName(for file: FileInfo, index: Int, settings s: RenameSettings, now: Date = Date()) throws -> String {
        let (base, ext) = split(file.name, isDirectory: file.isDirectory, keepExtension: s.keepExtension)
        return try transform(base, file: file, index: index, settings: s, now: now) + ext
    }

    static func transform(_ base: String, file: FileInfo, index: Int, settings s: RenameSettings, now: Date) throws -> String {
        let options: String.CompareOptions = s.caseSensitive ? [] : [.caseInsensitive]

        switch s.mode {
        case .replaceFirst:
            guard !s.find.isEmpty, let range = base.range(of: s.find, options: options) else { return base }
            return base.replacingCharacters(in: range, with: s.text)

        case .replaceLast:
            guard !s.find.isEmpty, let range = base.range(of: s.find, options: options.union(.backwards)) else { return base }
            return base.replacingCharacters(in: range, with: s.text)

        case .replaceAll:
            guard !s.find.isEmpty else { return base }
            return base.replacingOccurrences(of: s.find, with: s.text, options: options)

        case .wildcard:
            guard !s.find.isEmpty else { return base }
            let pattern = s.find.map { char -> String in
                switch char {
                case "*": ".*"
                case "?": "."
                default: NSRegularExpression.escapedPattern(for: String(char))
                }
            }.joined()
            let template = NSRegularExpression.escapedTemplate(for: s.text)
            return try regexReplace(base, pattern: pattern, template: template, caseSensitive: s.caseSensitive, firstOnly: true)

        case .regex:
            guard !s.find.isEmpty else { return base }
            return try regexReplace(base, pattern: s.find, template: s.text, caseSensitive: s.caseSensitive, firstOnly: false)

        case .append:
            return base + s.text

        case .prepend:
            return s.text + base

        case .removeCharacters:
            var chars = Array(base)
            let count = max(0, s.removeCount)
            let offset = max(0, s.removeOffset)
            let lower: Int, upper: Int
            switch s.removeFrom {
            case .start:
                lower = min(offset, chars.count)
                upper = min(offset + count, chars.count)
            case .end:
                upper = max(chars.count - offset, 0)
                lower = max(upper - count, 0)
            }
            chars.removeSubrange(lower..<upper)
            return String(chars)

        case .insertCharacters:
            var chars = Array(base)
            let offset = min(max(0, s.insertOffset), chars.count)
            let position = s.insertFrom == .start ? offset : chars.count - offset
            chars.insert(contentsOf: s.text, at: position)
            return String(chars)

        case .changeCase:
            switch s.caseStyle {
            case .lower: return base.lowercased()
            case .upper: return base.uppercased()
            case .title: return base.capitalized
            case .sentence:
                let lower = base.lowercased()
                return lower.prefix(1).uppercased() + lower.dropFirst()
            }

        case .sequence:
            let number = s.sequenceStart + index * s.sequenceStep
            var digits = String(abs(number))
            if digits.count < s.sequenceDigits {
                digits = String(repeating: "0", count: s.sequenceDigits - digits.count) + digits
            }
            if number < 0 { digits = "-" + digits }
            let name = s.sequenceKeepName ? base + s.text : s.text
            guard !name.isEmpty else { return digits }
            return s.sequenceNumberFirst
                ? digits + s.sequenceSeparator + name
                : name + s.sequenceSeparator + digits

        case .date:
            let date: Date
            switch s.dateSource {
            case .today: date = now
            case .created: date = file.created ?? now
            case .modified: date = file.modified ?? now
            }
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.dateFormat = s.dateFormat
            let stamp = formatter.string(from: date)
            switch s.datePlacement {
            case .prepend: return stamp + s.dateSeparator + base
            case .append: return base + s.dateSeparator + stamp
            case .replace: return stamp
            }
        }
    }

    static func regexReplace(_ string: String, pattern: String, template: String, caseSensitive: Bool, firstOnly: Bool) throws -> String {
        let regex: NSRegularExpression
        do {
            regex = try NSRegularExpression(pattern: pattern, options: caseSensitive ? [] : [.caseInsensitive])
        } catch {
            throw RenameRuleError.invalidPattern(pattern)
        }
        let whole = NSRange(string.startIndex..., in: string)
        let range: NSRange
        if firstOnly {
            guard let match = regex.firstMatch(in: string, range: whole) else { return string }
            range = match.range
        } else {
            range = whole
        }
        return regex.stringByReplacingMatches(in: string, range: range, withTemplate: template)
    }
}
