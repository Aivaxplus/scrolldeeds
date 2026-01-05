import SwiftUI

enum AppTheme {
    // MARK: - Muslim Pro Inspired Colors (Green & Gold)
    
    // Base Colors - Adaptive for Light/Dark Mode
    static var background: Color {
        Color(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.08, green: 0.12, blue: 0.10, alpha: 1.0) // Dark green-black
                : UIColor(red: 0.97, green: 0.98, blue: 0.97, alpha: 1.0) // Light off-white
        })
    }
    
    static var card: Color {
        Color(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.12, green: 0.18, blue: 0.14, alpha: 1.0) // Dark green card
                : UIColor.white
        })
    }
    
    // Primary - Islamic Green (Like Muslim Pro)
    static var primary: Color {
        Color(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.28, green: 0.70, blue: 0.48, alpha: 1.0) // Brighter green for dark mode
                : UIColor(red: 0.22, green: 0.58, blue: 0.38, alpha: 1.0) // Deep Islamic green
        })
    }
    
    static let primaryLight = Color(red: 0.35, green: 0.75, blue: 0.55) // Light green
    static let primaryDark = Color(red: 0.16, green: 0.45, blue: 0.28) // Dark green
    
    // Accent - Golden (Like Muslim Pro)
    static var accent: Color {
        Color(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.95, green: 0.78, blue: 0.42, alpha: 1.0) // Brighter gold for dark mode
                : UIColor(red: 0.88, green: 0.68, blue: 0.32, alpha: 1.0) // Rich gold
        })
    }
    
    static let accentLight = Color(red: 0.98, green: 0.88, blue: 0.65) // Light gold
    
    // Secondary
    static var secondary: Color {
        Color(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.45, green: 0.52, blue: 0.48, alpha: 1.0)
                : UIColor(red: 0.50, green: 0.55, blue: 0.52, alpha: 1.0)
        })
    }
    
    static var muted: Color {
        Color(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.18, green: 0.24, blue: 0.20, alpha: 1.0) // Dark green-gray
                : UIColor(red: 0.94, green: 0.96, blue: 0.94, alpha: 1.0) // Light green-gray
        })
    }
    
    // Text - Adaptive
    static var textPrimary: Color {
        Color(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.95, green: 0.97, blue: 0.95, alpha: 1.0) // Off-white
                : UIColor(red: 0.10, green: 0.12, blue: 0.10, alpha: 1.0) // Near black
        })
    }
    
    static var textSecondary: Color {
        Color(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.68, green: 0.75, blue: 0.70, alpha: 1.0) // Light green-gray
                : UIColor(red: 0.40, green: 0.45, blue: 0.42, alpha: 1.0) // Medium green-gray
        })
    }
    
    static var textMuted: Color {
        Color(uiColor: UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(red: 0.50, green: 0.58, blue: 0.52, alpha: 1.0)
                : UIColor(red: 0.58, green: 0.62, blue: 0.60, alpha: 1.0)
        })
    }
    
    static let textOnDark = Color.white // Always white on dark backgrounds
    static let textOnLight = Color(red: 0.10, green: 0.12, blue: 0.10) // Always dark on light backgrounds
    
    // Status
    static let success = Color(red: 0.22, green: 0.68, blue: 0.45) // Green success
    static let error = Color(red: 0.88, green: 0.35, blue: 0.35)
    
    // Gradients - Green & Gold Theme
    static var gradientPrimary: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.20, green: 0.55, blue: 0.36),
                Color(red: 0.28, green: 0.65, blue: 0.44)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    static var gradientGold: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.92, green: 0.72, blue: 0.38),
                Color(red: 0.85, green: 0.65, blue: 0.30)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    static var gradientPeaceful: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.96, green: 0.98, blue: 0.97),
                Color(red: 0.92, green: 0.95, blue: 0.93)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// Custom Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    var isLarge: Bool = true
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: isLarge ? 16 : 15, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, isLarge ? 15 : 12)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.94, green: 0.74, blue: 0.38),
                        Color(red: 0.88, green: 0.66, blue: 0.30)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(isLarge ? 14 : 12)
            .shadow(color: AppTheme.accent.opacity(configuration.isPressed ? 0.15 : 0.35), radius: configuration.isPressed ? 4 : 12, y: configuration.isPressed ? 2 : 6)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    var isLarge: Bool = true
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: isLarge ? 16 : 15, weight: .semibold))
            .foregroundColor(AppTheme.primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, isLarge ? 15 : 12)
            .background(AppTheme.primary.opacity(0.08))
            .cornerRadius(isLarge ? 14 : 12)
            .overlay(
                RoundedRectangle(cornerRadius: isLarge ? 14 : 12)
                    .stroke(AppTheme.primary.opacity(0.15), lineWidth: 1.5)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct TertiaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(AppTheme.textSecondary)
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(AppTheme.muted)
            .cornerRadius(10)
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}


