//
//  OnboardingAppTimePickerView.swift
//  scrolldeeds
//
//  “Which apps consume most of your time?” — multi-select 3×3 icon grid.
//

import SwiftUI

struct OnboardingAppOption: Identifiable, Hashable {
    let id: String
    let assetName: String
    let titleKey: String
}

enum OnboardingAppTimeOptions {
    static let all: [OnboardingAppOption] = [
        .init(id: "tiktok", assetName: "AppIconTikTok", titleKey: "questionnaire.apps.icon.tiktok"),
        .init(id: "instagram", assetName: "AppIconInstagram", titleKey: "questionnaire.apps.icon.instagram"),
        .init(id: "youtube", assetName: "AppIconYouTube", titleKey: "questionnaire.apps.icon.youtube"),
        .init(id: "snapchat", assetName: "AppIconSnapchat", titleKey: "questionnaire.apps.icon.snapchat"),
        .init(id: "x", assetName: "AppIconX", titleKey: "questionnaire.apps.icon.x"),
        .init(id: "facebook", assetName: "AppIconFacebook", titleKey: "questionnaire.apps.icon.facebook"),
        .init(id: "reddit", assetName: "AppIconReddit", titleKey: "questionnaire.apps.icon.reddit"),
        .init(id: "whatsapp", assetName: "AppIconWhatsApp", titleKey: "questionnaire.apps.icon.whatsapp"),
        .init(id: "netflix", assetName: "AppIconNetflix", titleKey: "questionnaire.apps.icon.netflix")
    ]
}

struct OnboardingAppTimePickerView: View {
    @Binding var selectedIDs: Set<String>
    var revealed: Bool

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 14), count: 3)

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 8)

            VStack(spacing: 10) {
                Text(NSLocalizedString("questionnaire.apps.title", comment: ""))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)

                Text(NSLocalizedString("questionnaire.apps.subtitle", comment: ""))
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
            .padding(.horizontal, 8)
            .opacity(revealed ? 1 : 0)
            .offset(y: revealed ? 0 : 4)

            Spacer().frame(height: 28)

            LazyVGrid(columns: columns, spacing: 18) {
                ForEach(Array(OnboardingAppTimeOptions.all.enumerated()), id: \.element.id) { index, app in
                    appCell(app)
                        .opacity(revealed ? 1 : 0)
                        .offset(y: revealed ? 0 : 8)
                        .animation(
                            .easeInOut(duration: 0.85).delay(0.12 + Double(index) * 0.05),
                            value: revealed
                        )
                }
            }
            .padding(.horizontal, 4)

            Spacer(minLength: 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func appCell(_ app: OnboardingAppOption) -> some View {
        let selected = selectedIDs.contains(app.id)
        return Button {
            HapticManager.shared.selection()
            withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                if selected {
                    selectedIDs.remove(app.id)
                } else {
                    selectedIDs.insert(app.id)
                }
            }
        } label: {
            VStack(spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    Image(app.assetName)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 72, height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(
                                    selected ? AppTheme.primary : Color.clear,
                                    lineWidth: 2.5
                                )
                        )
                        .shadow(
                            color: selected ? AppTheme.primary.opacity(0.28) : Color.black.opacity(0.08),
                            radius: selected ? 10 : 6,
                            y: 3
                        )
                        .scaleEffect(selected ? 1.03 : 1)

                    if selected {
                        // Lock badge instead of a checkmark: a tiny preview of what ScrollDeeds will do with this app.
                        ZStack {
                            Circle()
                                .fill(AppTheme.primary)
                                .frame(width: 24, height: 24)
                                .overlay(Circle().strokeBorder(Color.white.opacity(0.9), lineWidth: 1.5))
                            Image(systemName: "lock.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .offset(x: 4, y: -4)
                        .transition(.scale.combined(with: .opacity))
                    }
                }

                Text(NSLocalizedString(app.titleKey, comment: ""))
                    .font(.system(size: 12, weight: selected ? .semibold : .medium, design: .rounded))
                    .foregroundColor(selected ? AppTheme.textPrimary : AppTheme.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(NSLocalizedString(app.titleKey, comment: ""))
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
