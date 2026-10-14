import SwiftUI

struct LanguageSettingsView: View {
    @ObservedObject private var languageManager = LanguageManager.shared
    @Environment(\.dismiss) var dismiss
    @State private var selectedLanguage: String
    
    init() {
        _selectedLanguage = State(initialValue: LanguageManager.shared.currentLanguage)
    }
    
    var body: some View {
        ZStack {
            SDPageBackground()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    SDDismissButton(action: { dismiss() })
                    
                    Spacer()
                    
                    Text(NSLocalizedString("settings.language", comment: "Language"))
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    Spacer()
                    
                    // Invisible spacer for centering
                    Color.clear.frame(width: 32, height: 32)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 20)
                
                // Language List
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 12) {
                        ForEach(LanguageManager.supportedLanguages) { language in
                            LanguageRow(
                                language: language,
                                isSelected: selectedLanguage == language.code
                            )
                            .onTapGesture {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedLanguage = language.code
                                    languageManager.setLanguage(language.code)
                                    HapticManager.shared.medium()
                                }
                                
                                // Auto dismiss after 0.5 seconds
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    dismiss()
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

struct LanguageRow: View {
    let language: LanguageInfo
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Flag
            Text(language.flag)
                .font(.system(size: 32))
            
            // Language Name
            VStack(alignment: .leading, spacing: 4) {
                Text(language.nativeName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                
                Text(language.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            Spacer()
            
            // Selection indicator
            ZStack {
                Circle()
                    .fill(isSelected ? 
                          LinearGradient(
                            colors: [
                                AppTheme.primary,
                                AppTheme.primaryLight
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                          ) : 
                          LinearGradient(
                            colors: [AppTheme.muted.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                          ))
                    .frame(width: 24, height: 24)
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppTheme.textOnLight)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isSelected ? AppTheme.cardSecondary : AppTheme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            isSelected ?
                            LinearGradient(
                                colors: [
                                    AppTheme.primary.opacity(0.35),
                                    AppTheme.primary.opacity(0.12)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [AppTheme.border.opacity(0.35)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(
            color: isSelected ? AppTheme.primary.opacity(0.14) : Color.black.opacity(0.035),
            radius: 12,
            y: 4
        )
        .scaleEffect(isSelected ? 1.02 : 1.0)
    }
}

#Preview {
    LanguageSettingsView()
}
