import Foundation
import ObjectiveC.runtime
import SwiftUI

enum AppLanguageOption: String, CaseIterable, Identifiable {
    case english
    case system
    case simplifiedChinese

    var id: String { rawValue }

    var overrideLocalizationIdentifier: String? {
        switch self {
        case .english:
            return "en"
        case .system:
            return nil
        case .simplifiedChinese:
            return "zh-Hans"
        }
    }

    var title: String {
        switch self {
        case .english:
            return NSLocalizedString("English (Default)", comment: "")
        case .system:
            return NSLocalizedString("Follow System", comment: "")
        case .simplifiedChinese:
            return NSLocalizedString("Simplified Chinese", comment: "")
        }
    }

    var subtitle: String {
        switch self {
        case .english:
            return NSLocalizedString("Always use English inside the app.", comment: "")
        case .system:
            return NSLocalizedString("Match the language selected for PoolStats in iPhone Settings.", comment: "")
        case .simplifiedChinese:
            return NSLocalizedString("Use Simplified Chinese across the app.", comment: "")
        }
    }
}

enum AppLanguageRuntime {
    static let supportedLocalizations = ["en", "zh-Hans"]
    private(set) static var currentLocalizationIdentifier = "en"

    static var locale: Locale {
        Locale(identifier: currentLocalizationIdentifier)
    }

    static func apply(overrideLocalizationIdentifier: String?) {
        LocalizedMainBundleController.installIfNeeded()
        LocalizedMainBundleController.setOverrideLocalization(overrideLocalizationIdentifier)
        currentLocalizationIdentifier = resolvedLocalizationIdentifier(for: overrideLocalizationIdentifier)
    }

    static func resolvedLocalizationIdentifier(for overrideLocalizationIdentifier: String?) -> String {
        if let overrideLocalizationIdentifier, supportedLocalizations.contains(overrideLocalizationIdentifier) {
            return overrideLocalizationIdentifier
        }
        return Bundle.preferredLocalizations(from: supportedLocalizations).first ?? "en"
    }

    static func format(_ format: String, _ arguments: CVarArg...) -> String {
        String(format: format, locale: locale, arguments: arguments)
    }

    static func localizedFormat(_ key: String, comment: String = "", _ arguments: CVarArg...) -> String {
        String(
            format: NSLocalizedString(key, comment: comment),
            locale: locale,
            arguments: arguments
        )
    }
}

@MainActor
final class AppLanguageStore: ObservableObject {
    private static let storageKey = "appLanguageOption"

    @Published private(set) var selectedOption: AppLanguageOption
    @Published private(set) var locale: Locale

    init() {
        let raw = UserDefaults.standard.string(forKey: Self.storageKey)
        let initial = AppLanguageOption(rawValue: raw ?? AppLanguageOption.english.rawValue) ?? .english
        selectedOption = initial
        AppLanguageRuntime.apply(overrideLocalizationIdentifier: initial.overrideLocalizationIdentifier)
        locale = AppLanguageRuntime.locale
    }

    func setLanguage(_ option: AppLanguageOption) {
        UserDefaults.standard.set(option.rawValue, forKey: Self.storageKey)
        selectedOption = option
        apply(option)
    }

    func refreshSystemLanguageIfNeeded() {
        guard selectedOption == .system else { return }
        apply(.system)
    }

    private func apply(_ option: AppLanguageOption) {
        AppLanguageRuntime.apply(overrideLocalizationIdentifier: option.overrideLocalizationIdentifier)
        locale = AppLanguageRuntime.locale
    }
}

private var localizedBundleAssociationKey: UInt8 = 0

private final class LocalizedMainBundle: Bundle, @unchecked Sendable {
    override func localizedString(forKey key: String, value: String?, table tableName: String?) -> String {
        if let overrideBundle = objc_getAssociatedObject(self, &localizedBundleAssociationKey) as? Bundle {
            return overrideBundle.localizedString(forKey: key, value: value, table: tableName)
        }
        return super.localizedString(forKey: key, value: value, table: tableName)
    }
}

private enum LocalizedMainBundleController {
    private static var isInstalled = false

    static func installIfNeeded() {
        guard isInstalled == false else { return }
        object_setClass(Bundle.main, LocalizedMainBundle.self)
        isInstalled = true
    }

    static func setOverrideLocalization(_ identifier: String?) {
        let overrideBundle = identifier
            .flatMap { Bundle.main.path(forResource: $0, ofType: "lproj") }
            .flatMap(Bundle.init(path:))
        objc_setAssociatedObject(
            Bundle.main,
            &localizedBundleAssociationKey,
            overrideBundle,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
    }
}
