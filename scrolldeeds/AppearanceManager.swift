//
//  AppearanceManager.swift
//  scrolldeeds
//
//  Stores the user's preferred colour scheme (light / dark / system).
//

import SwiftUI
import UIKit
import Combine

enum AppearanceMode: String, CaseIterable {
    case system = "system"
    case light  = "light"
    case dark   = "dark"

    var label: String {
        switch self {
        case .system: return NSLocalizedString("settings.system_default", comment: "System Default")
        case .light:  return NSLocalizedString("settings.light_mode",     comment: "Light Mode")
        case .dark:   return NSLocalizedString("settings.dark_mode",      comment: "Dark Mode")
        }
    }

    var icon: String {
        switch self {
        case .system: return "iphone"
        case .light:  return "sun.max.fill"
        case .dark:   return "moon.fill"
        }
    }

    /// The SwiftUI ColorScheme value, or nil for system default.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

final class AppearanceManager: ObservableObject {
    static let shared = AppearanceManager()

    private static let appearanceKey = "appearance_mode"
    private static let sharedDefaults = UserDefaults(suiteName: "group.com.scrolldeeds.app")

    @Published var mode: AppearanceMode {
        didSet { persistMode() }
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: Self.appearanceKey) ?? AppearanceMode.light.rawValue
        let resolved = AppearanceMode(rawValue: saved) ?? .light
        // Assign the wrapper so init does not emit objectWillChange during scene connect.
        _mode = Published(initialValue: resolved)
        persistMode()
    }

    var preferredColorScheme: ColorScheme? { mode.colorScheme }

    private func persistMode() {
        UserDefaults.standard.set(mode.rawValue, forKey: Self.appearanceKey)
        Self.sharedDefaults?.set(mode.rawValue, forKey: Self.appearanceKey)
    }
}

// Keeps UIKit dynamic colors (AppTheme.adaptive) in sync with the in-app appearance setting.
// SwiftUI's `.preferredColorScheme` alone does not always update UIColor trait resolution.
struct AppearanceWindowSync: ViewModifier {
    @ObservedObject private var appearanceManager = AppearanceManager.shared

    func body(content: Content) -> some View {
        content
            .onAppear {
                DispatchQueue.main.async { syncWindowAppearance() }
            }
            .onChange(of: appearanceManager.mode) { _ in
                DispatchQueue.main.async { syncWindowAppearance() }
            }
    }

    private func syncWindowAppearance() {
        let style: UIUserInterfaceStyle
        switch appearanceManager.mode {
        case .light:  style = .light
        case .dark:   style = .dark
        case .system: style = .unspecified
        }

        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for window in windowScene.windows {
                window.overrideUserInterfaceStyle = style
            }
        }
    }
}

extension View {
    func syncAppearanceWithWindows() -> some View {
        modifier(AppearanceWindowSync())
    }
}
