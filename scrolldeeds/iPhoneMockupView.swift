//
//  iPhoneMockupView.swift
//  scrolldeeds
//
//  iPhone mockup: black frame, Dynamic Island, rounded corners.
//  Same structure/size as reference; content (e.g. video) inside the screen area.
//

import SwiftUI
import UIKit

/// Target height for paywall mockup (larger; may extend below fold)
private let paywallMockupHeight: CGFloat = 480

/// iPhone-style frame (black bezel, Dynamic Island). Content is clipped to the inner screen.
struct iPhoneMockupView<Content: View>: View {
    @ViewBuilder var content: () -> Content

    /// Outer size of the phone (including bezel). Inner screen is inset.
    private let phoneWidth: CGFloat = 280
    private let phoneHeight: CGFloat = 568
    private let cornerRadius: CGFloat = 44
    private let bezelWidth: CGFloat = 14
    private let dynamicIslandWidth: CGFloat = 126
    private let dynamicIslandHeight: CGFloat = 37

    private var innerWidth: CGFloat { phoneWidth - bezelWidth * 2 }
    private var innerHeight: CGFloat { phoneHeight - bezelWidth * 2 }

    var body: some View {
        ZStack {
            // Black bezel / frame
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color(red: 0.06, green: 0.06, blue: 0.07))
                .frame(width: phoneWidth, height: phoneHeight)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )

            // Dynamic Island (pill)
            Capsule()
                .fill(Color.black)
                .frame(width: dynamicIslandWidth, height: dynamicIslandHeight)
                .frame(maxHeight: .infinity, alignment: .top)
                .offset(y: bezelWidth + 12)

            // Inner screen (content area) — clip to rounded rect
            content()
                .frame(width: innerWidth, height: innerHeight)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius - bezelWidth))
                .offset(y: 0)
        }
        .frame(width: phoneWidth, height: phoneHeight)
    }
}

// MARK: - Scaled mockup for paywall (same height as timeline, custom image inside)

struct PaywallPhoneMockupView: View {
    var titleColor: Color = AppTheme.textPrimary
    /// Matches yearly (trial headline) vs monthly (original hero) on the pricing step.
    var isYearlyTrialHeadline: Bool = true
    /// Shown directly under the hero title (e.g. “No Payment Due Now” / monthly trust line).
    var ctaDisclaimer: String? = nil
    @ObservedObject private var languageManager = LanguageManager.shared
    
    private var scale: CGFloat { paywallMockupHeight / 568 }
    private var scaledWidth: CGFloat { 280 * scale }
    /// Gap between hero block and phone mockup (was 20 pt when title stood alone).
    private var spacingBeforeMockup: CGFloat { ctaDisclaimer == nil ? 20 : 8 }

    private static let paywallMockupFolder = "PaywallMockupImages"
    private static let paywallMockupImageExtensions = ["png", "jpg", "jpeg", "heic", "webp"]
    
    var body: some View {
        VStack(spacing: 0) {
            PaywallTrialTitleView(titleColor: titleColor, isYearlyTrialHeadline: isYearlyTrialHeadline)
            if let disclaimer = ctaDisclaimer {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(AppTheme.accent.opacity(0.95))
                    Text(disclaimer)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.88)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                .padding(.top, 4)
                .padding(.bottom, 16)
            }
            Spacer().frame(height: spacingBeforeMockup)
            iPhoneMockupView {
                paywallMockupContent
            }
            .frame(width: 280, height: 568)
            .scaleEffect(scale)
            .frame(width: scaledWidth, height: paywallMockupHeight)
        }
        .frame(maxWidth: 420)
    }
    
    @ViewBuilder
    private var paywallMockupContent: some View {
        if let name = Self.localizedPaywallMockupName(
            baseName: "PaywallMockupImage",
            languageCode: languageManager.currentLanguage
        ) {
            Image(uiImage: UIImage(named: name) ?? UIImage(contentsOfFile: Self.urlForMockup(named: name)?.path ?? "") ?? UIImage())
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            LinearGradient(
                colors: [
                    AppTheme.primary.opacity(0.25),
                    AppTheme.accent.opacity(0.15),
                    Color(red: 0.06, green: 0.10, blue: 0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            VStack(spacing: 8) {
                Image(systemName: "photo.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(AppTheme.accent.opacity(0.8))
                Text("PaywallMockupImage")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(AppTheme.textMuted)
            }
        }
    }

    /// Returns the best matching mockup base name available in the bundle.
    /// Naming: `PaywallMockupImage_<lang>.png` or `PaywallMockupImage_<lang-region>.png`.
    /// Fallback: suffix candidates → `PaywallMockupImage`.
    private static func localizedPaywallMockupName(baseName: String, languageCode: String) -> String? {
        let candidates = localizedNameCandidates(for: baseName, languageCode: languageCode)

        // Prefer bundled loose files first, then asset catalog fallback.
        // This is important because a default asset named `PaywallMockupImage`
        // would otherwise mask localized files like `PaywallMockupImage_de`.
        for name in candidates {
            if urlForMockup(named: name) != nil { return name }
            if UIImage(named: name) != nil { return name }
        }
        return nil
    }

    private static func urlForMockup(named name: String) -> URL? {
        for ext in paywallMockupImageExtensions {
            if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: paywallMockupFolder) {
                return url
            }
        }
        return nil
    }

    private static func localizedNameCandidates(for baseName: String, languageCode: String) -> [String] {
        var candidates: [String] = []

        // 1) In-app selected language (instant switch source of truth).
        candidates.append("\(baseName)_\(languageCode)")
        if let dash = languageCode.firstIndex(of: "-") {
            let base = String(languageCode[..<dash])
            candidates.append("\(baseName)_\(base)")
        }

        for loc in Bundle.main.preferredLocalizations {
            candidates.append("\(baseName)_\(loc)")
            if let dash = loc.firstIndex(of: "-") {
                let base = String(loc[..<dash])
                candidates.append("\(baseName)_\(base)")
            }
        }

        if let lang = Locale.current.language.languageCode?.identifier {
            candidates.append("\(baseName)_\(lang)")
        }

        candidates.append(baseName)

        var seen = Set<String>()
        return candidates.filter { seen.insert($0).inserted }
    }
}

#Preview("iPhone Mockup") {
    ZStack {
        AppTheme.background.ignoresSafeArea()
        iPhoneMockupView {
            LinearGradient(
                colors: [AppTheme.primary.opacity(0.3), AppTheme.accent.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}
