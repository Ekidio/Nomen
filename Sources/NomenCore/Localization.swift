import Foundation

/// The app's UI language, switchable at runtime.
public enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case hu, en

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .hu: "Magyar"
        case .en: "English"
        }
    }

    public var locale: Locale { Locale(identifier: rawValue) }

    /// Hungarian when the system prefers it, English otherwise.
    public static var systemDefault: AppLanguage {
        Locale.preferredLanguages.first?.hasPrefix("hu") == true ? .hu : .en
    }

    nonisolated(unsafe) public static var current: AppLanguage = .systemDefault
}

/// Picks the string for the current UI language.
public func L(_ hu: String, _ en: String) -> String {
    AppLanguage.current == .hu ? hu : en
}
