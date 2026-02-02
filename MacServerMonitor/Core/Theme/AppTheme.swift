//
//  AppTheme.swift
//  MacServerMonitor
//
//  Application theme management
//

import SwiftUI
import Combine

/// App theme options
enum AppTheme: String, CaseIterable, Identifiable {
    case light
    case dark

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }

    var icon: String {
        switch self {
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}

/// Theme color scheme for light and dark modes
struct ThemeColors {
    let background: Color
    let cardBackground: Color
    let primaryText: Color
    let secondaryText: Color
    let accent: Color
    let border: Color
    let divider: Color

    static let light = ThemeColors(
        background: Color(.windowBackgroundColor),
        cardBackground: Color(.controlBackgroundColor),
        primaryText: Color(.textColor),
        secondaryText: Color(.secondaryLabelColor),
        accent: Color.blue,
        border: Color(.separatorColor),
        divider: Color(.separatorColor)
    )

    static let dark = ThemeColors(
        background: Color(
            red: 30/255,
            green: 30/255,
            blue: 30/255
        ),
        cardBackground: Color(
            red: 50/255,
            green: 50/255,
            blue: 50/255
        ),
        primaryText: Color.white,
        secondaryText: Color(
            red: 180/255,
            green: 180/255,
            blue: 180/255
        ),
        accent: Color(
            red: 100/255,
            green: 150/255,
            blue: 255/255
        ),
        border: Color(
            red: 70/255,
            green: 70/255,
            blue: 70/255
        ),
        divider: Color(
            red: 70/255,
            green: 70/255,
            blue: 70/255
        )
    )
}

/// Theme manager to handle app-wide theme
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @Published var currentTheme: AppTheme {
        didSet {
            applyTheme(currentTheme)
            saveTheme(currentTheme)
        }
    }

    private init() {
        // Load saved theme or default to light
        if let savedThemeRaw = UserDefaults.standard.string(forKey: "app_theme"),
           let savedTheme = AppTheme(rawValue: savedThemeRaw) {
            self.currentTheme = savedTheme
        } else {
            self.currentTheme = .light
        }
        applyTheme(currentTheme)
    }

    var colorScheme: ColorScheme? {
        switch currentTheme {
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    var themeColors: ThemeColors {
        switch currentTheme {
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    func applyTheme(_ theme: AppTheme) {
        // Apply appearance
        switch theme {
        case .light:
            NSApp.appearance = NSAppearance(named: .aqua)
        case .dark:
            NSApp.appearance = NSAppearance(named: .darkAqua)
        }
    }

    private func saveTheme(_ theme: AppTheme) {
        UserDefaults.standard.set(theme.rawValue, forKey: "app_theme")
    }
}
