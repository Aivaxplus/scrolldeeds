//
//  PaywallEaseIntro.swift
//  scrolldeeds
//
//  Short plan-loading theater, then 3 conviction screens that teach the product.
//  Same cream / emerald chrome as the rest of onboarding.
//

import SwiftUI

struct PaywallEaseBenefit: Equatable {
    let icon: String
    let title: String
    let body: String
}

struct PaywallPlanLoadingView: View {
    var onFinished: () -> Void

    @State private var step = 0
    @State private var didFinish = false
    @State private var showMark = false
    @State private var showCopy = false
    @State private var showList = false

    var body: some View {
        ZStack {
            SDPageBackground()
            RadialGradient(
                colors: [
                    AppTheme.primary.opacity(0.10),
                    AppTheme.accent.opacity(0.04),
                    Color.clear
                ],
                center: .top,
                startRadius: 0,
                endRadius: 420
            )
            .ignoresSafeArea()
            .opacity(showMark ? 1 : 0)

            VStack(spacing: 28) {
                Spacer()

                NafsiBuddyView(pose: "NafsiPoseWatch", height: 118)
                .scaleEffect(showMark ? 1 : 0.56)
                .opacity(showMark ? 1 : 0)

                VStack(spacing: 10) {
                    Text(NSLocalizedString("paywall.ease.loading.title", comment: ""))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(NSLocalizedString("paywall.ease.loading.subtitle", comment: ""))
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)
                .opacity(showCopy ? 1 : 0)
                .offset(y: showCopy ? 0 : 16)

                VStack(alignment: .leading, spacing: 14) {
                    loadingRow(0, key: "paywall.ease.loading.step1")
                    loadingRow(1, key: "paywall.ease.loading.step2")
                    loadingRow(2, key: "paywall.ease.loading.step3")
                    loadingRow(3, key: "paywall.ease.loading.step4")
                }
                .padding(.top, 8)
                .opacity(showList ? 1 : 0)
                .offset(y: showList ? 0 : 12)

                Spacer()
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.74, dampingFraction: 0.78)) {
                showMark = true
            }
            withAnimation(.spring(response: 0.80, dampingFraction: 0.84).delay(0.14)) {
                showCopy = true
            }
            withAnimation(.spring(response: 0.84, dampingFraction: 0.86).delay(0.28)) {
                showList = true
            }
            HapticManager.shared.soft()
            let beats: [(delay: Double, value: Int)] = [
                (1.15, 1),
                (2.10, 2),
                (3.05, 3),
                (3.90, 4)
            ]
            for beat in beats {
                DispatchQueue.main.asyncAfter(deadline: .now() + beat.delay) {
                    withAnimation(.easeOut(duration: 0.4)) { step = beat.value }
                    HapticManager.shared.animationReveal(beat: beat.value)
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.40) {
                finish()
            }
        }
    }

    private func loadingRow(_ index: Int, key: String) -> some View {
        let done = step > index
        let active = step == index
        return HStack(spacing: 10) {
            Image(systemName: done ? "checkmark.circle.fill" : (active ? "circle.dotted" : "circle"))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(done ? AppTheme.primary : AppTheme.textMuted)
            Text(NSLocalizedString(key, comment: ""))
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(done || active ? AppTheme.textPrimary : AppTheme.textMuted)
        }
        .opacity(step >= index ? 1 : 0.45)
    }

    private func finish() {
        guard !didFinish else { return }
        didFinish = true
        HapticManager.shared.medium()
        onFinished()
    }
}

struct PaywallEasePageView: View {
    let kicker: String
    let title: String
    let imageName: String?
    var outcomes: [PaywallEaseBenefit] = []
    var priceMonthly: String? = nil
    var priceYearly: String? = nil
    var trialNote: String? = nil
    var ctaTitle: String
    var isPurchasing: Bool = false
    let onContinue: () -> Void

    @State private var appeared = false

    var body: some View {
        GeometryReader { geo in
            easeLayout(compact: geo.size.height < 720)
        }
        .onAppear {
            HapticManager.shared.soft()
            withAnimation(.easeOut(duration: 0.36)) {
                appeared = true
            }
        }
    }

    private func easeLayout(compact: Bool) -> some View {
        let imageSize: CGFloat = compact ? 232 : 260
        return ZStack {
                SDPageBackground()
                RadialGradient(
                    colors: [
                        AppTheme.primary.opacity(0.08),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 0,
                    endRadius: 380
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer(minLength: compact ? 8 : 16)

                    VStack(spacing: compact ? 12 : 14) {
                        Text(kicker)
                            .font(.system(size: compact ? 26 : 28, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.primary)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(title)
                            .font(.system(size: compact ? 16 : 17, weight: .semibold, design: .rounded))
                            .foregroundColor(AppTheme.textPrimary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 8)

                        if let imageName {
                            pageImage(imageName, size: imageSize)
                        }

                        if !outcomes.isEmpty {
                            outcomesCard
                        }
                    }
                    .padding(.horizontal, 24)
                    .opacity(appeared ? 1 : 0)

                    Spacer(minLength: 10)

                    VStack(spacing: 8) {
                        Button(action: {
                            guard !isPurchasing else { return }
                            HapticManager.shared.medium()
                            onContinue()
                        }) {
                            if isPurchasing {
                                SwiftUI.ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 4)
                            } else {
                                Text(ctaTitle)
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(isPurchasing)

                        if priceYearly != nil || trialNote != nil {
                            Text(
                                [trialNote, priceYearly, priceMonthly]
                                    .compactMap { $0 }
                                    .filter { !$0.isEmpty }
                                    .joined(separator: "  ·  ")
                            )
                            .font(.system(size: 12, weight: .regular, design: .rounded))
                            .foregroundColor(AppTheme.textMuted)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 28)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 22)
                    .opacity(appeared ? 1 : 0)
                }
        }
    }

    private func pageImage(_ name: String, size: CGFloat) -> some View {
        Image(name)
            .resizable()
            .scaledToFill()
            .frame(width: size, height: size)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(Color.white.opacity(0.6), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.10), radius: 16, x: 0, y: 8)
    }

    private var outcomesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(Array(outcomes.enumerated()), id: \.offset) { _, item in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(AppTheme.primary)
                        .padding(.top, 1)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(AppTheme.textPrimary)
                        Text(item.body)
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(AppTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(AppTheme.card)
                .shadow(color: Color.black.opacity(0.05), radius: 16, y: 6)
        )
    }
}
