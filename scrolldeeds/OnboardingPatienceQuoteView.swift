//
//  OnboardingPatienceQuoteView.swift
//  scrolldeeds
//
//  Just Pray–inspired “almost done” + Qur’an quote, ScrollDeeds chrome.
//

import SwiftUI

struct OnboardingPatienceQuoteView: View {

    var onTypingComplete: () -> Void = {}

    @State private var runner = OnboardingTypewriterRunner()
    @State private var typedCount: [Int: Int] = [:]
    @State private var quoteSourceVisible = false

    private let greeting = NSLocalizedString(
        "onboarding.patience_quote.greeting",
        comment: "We're almost done. May Allah reward you for being patient with me."
    )
    private let quoteLabel = NSLocalizedString("onboarding.patience_quote.quote_label", comment: "Allah SWT said:")
    private let quoteBody = NSLocalizedString("onboarding.patience_quote.quote", comment: "")
    private let quoteSource = NSLocalizedString("onboarding.patience_quote.quote_source", comment: "Surah Al-Baqarah (2:153)")

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                AppTheme.primary.opacity(0.10),
                                AppTheme.primary.opacity(0.04),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 40,
                            endRadius: 160
                        )
                    )
                    .frame(width: 320, height: 320)
                    .blur(radius: 36)
                    .offset(y: -geometry.size.height * 0.12)

                VStack(spacing: 0) {
                    Spacer().frame(height: max(24, geometry.size.height * 0.04))

                    greetingBlock(fontSize: max(22, min(26, geometry.size.width * 0.058)))
                        .padding(.horizontal, max(20, geometry.size.width * 0.06))

                    Spacer(minLength: 28)

                    quoteBlock(fontSize: max(20, min(24, geometry.size.width * 0.055)))
                        .padding(.horizontal, max(24, geometry.size.width * 0.08))

                    Spacer(minLength: 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { startTyping() }
        .onDisappear { runner.cancel() }
    }

    // MARK: - Greeting

    private func greetingBlock(fontSize: CGFloat) -> some View {
        ZStack {
            Text(greeting)
                .font(.system(size: fontSize, weight: .regular, design: .rounded))
                .hidden()
            Text(OnboardingTypewriter.prefix(greeting, count: typedCount[0] ?? 0))
                .font(.system(size: fontSize, weight: .regular, design: .rounded))
        }
        .foregroundColor(AppTheme.textPrimary)
        .multilineTextAlignment(.center)
        .lineSpacing(5)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .center)
    }

    // MARK: - Quote

    private func quoteBlock(fontSize: CGFloat) -> some View {
        VStack(spacing: 14) {
            ZStack {
                Text(quoteLabel)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .hidden()
                Text(OnboardingTypewriter.prefix(quoteLabel, count: typedCount[1] ?? 0))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
            }
            .foregroundColor(AppTheme.primary)

            highlightedQuote(fontSize: fontSize, visibleCount: typedCount[2] ?? 0)
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)

            Text(quoteSource)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(AppTheme.textMuted)
                .opacity(quoteSourceVisible ? 1 : 0)
        }
        .frame(maxWidth: .infinity)
    }

    /// Highlights: patience, prayer, Allah, patient (order matters for overlapping matches).
    private func highlightedQuote(fontSize: CGFloat, visibleCount: Int) -> some View {
        let highlights = [
            NSLocalizedString("onboarding.patience_quote.highlight.patience", comment: "patience"),
            NSLocalizedString("onboarding.patience_quote.highlight.prayer", comment: "prayer"),
            NSLocalizedString("onboarding.patience_quote.highlight.allah", comment: "Allah"),
            NSLocalizedString("onboarding.patience_quote.highlight.patient", comment: "patient")
        ]
        return ZStack {
            OnboardingTypewriter.highlightedText(
                full: quoteBody,
                visibleCount: quoteBody.count,
                highlights: highlights,
                fontSize: fontSize
            )
            .hidden()
            OnboardingTypewriter.highlightedText(
                full: quoteBody,
                visibleCount: visibleCount,
                highlights: highlights,
                fontSize: fontSize
            )
        }
    }

    private func startTyping() {
        runner.start(lines: [greeting, quoteLabel, quoteBody], onCount: { index, count in
            typedCount[index] = count
        }, onComplete: {
            withAnimation(.easeOut(duration: 0.35)) {
                quoteSourceVisible = true
            }
            HapticManager.shared.animationReveal(beat: 3)
            onTypingComplete()
        })
    }
}
