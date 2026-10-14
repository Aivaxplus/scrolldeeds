//
//  OnboardingHeroEmojiIcon.swift
//  scrolldeeds
//
//  Large 3D-style emoji hero with radial glow + gentle float (streak page style).
//

import SwiftUI

struct OnboardingHeroEmojiIcon: View {
    let emoji: String
    /// When set, shows an SF Symbol instead of the emoji (e.g. loop / cycle).
    var systemImage: String? = nil
    var glowColor: Color = AppTheme.accent
    var emojiSize: CGFloat = 56
    var revealed: Bool

    @State private var isFloating = false

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            glowColor.opacity(0.30),
                            glowColor.opacity(0.08),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 6,
                        endRadius: 70
                    )
                )
                .frame(width: 132, height: 132)

            Group {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: emojiSize * 0.82, weight: .semibold))
                        .foregroundStyle(glowColor)
                        .symbolRenderingMode(.hierarchical)
                } else {
                    Text(emoji)
                        .font(.system(size: emojiSize))
                }
            }
            .offset(y: isFloating ? -6 : 2)
        }
        .scaleEffect(revealed ? 1 : 0.55)
        .opacity(revealed ? 1 : 0)
        .animation(.spring(response: 0.52, dampingFraction: 0.64), value: revealed)
        .animation(
            revealed
                ? .easeInOut(duration: 1.05).repeatForever(autoreverses: true)
                : .default,
            value: isFloating
        )
        .onAppear { updateFloating() }
        .onChange(of: revealed) { _ in updateFloating() }
    }

    private func updateFloating() {
        guard revealed else {
            isFloating = false
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            guard revealed else { return }
            isFloating = true
        }
    }
}

enum OnboardingQuestionEmoji {
    static func glow(for emoji: String) -> Color {
        switch emoji {
        case "🔥", "⏳", "🪪", "💪", "🌄", "🎯", "⏰":
            return AppTheme.accent
        case "😔":
            return Color(red: 0.55, green: 0.45, blue: 0.75)
        case "✋", "📲", "🤲", "👂", "🎚️", "🌙", "🔄", "🧱":
            return AppTheme.primary
        default:
            return AppTheme.primary
        }
    }
}
