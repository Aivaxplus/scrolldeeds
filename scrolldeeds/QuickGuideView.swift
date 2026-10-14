//
//  QuickGuideView.swift
//  scrolldeeds
//

import SwiftUI
import UIKit
import Foundation

struct QuickGuideView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var languageManager = LanguageManager.shared
    @State private var currentPage: Int = 0

    let onComplete: () -> Void

    private var pages: [GuidePage] {
        [
            GuidePage(
                mockupImageAssetName: "QuickGuidePage1",
                title: NSLocalizedString("guide.page1.title", comment: ""),
                subtitle: NSLocalizedString("guide.page1.subtitle", comment: ""),
                description: NSLocalizedString("guide.page1.description", comment: "")
            ),
            GuidePage(
                mockupImageAssetName: "QuickGuidePage2",
                title: NSLocalizedString("guide.page2.title", comment: ""),
                subtitle: NSLocalizedString("guide.page2.subtitle", comment: ""),
                description: NSLocalizedString("guide.page2.description", comment: "")
            ),
            GuidePage(
                mockupImageAssetName: "QuickGuidePage3",
                title: NSLocalizedString("guide.page3.title", comment: ""),
                subtitle: NSLocalizedString("guide.page3.subtitle", comment: ""),
                description: NSLocalizedString("guide.page3.description", comment: "")
            ),
            GuidePage(
                mockupImageAssetName: "QuickGuidePage4",
                title: NSLocalizedString("guide.page4.title", comment: ""),
                subtitle: NSLocalizedString("guide.page4.subtitle", comment: ""),
                description: NSLocalizedString("guide.page4.description", comment: "")
            )
        ]
    }

    var body: some View {
        ZStack {
            SDPageBackground()

            RadialGradient(
                colors: [AppTheme.primary.opacity(0.08), Color.clear],
                center: .top, startRadius: 0, endRadius: 400
            )
            .ignoresSafeArea()

            // GeometryReader inside an .ignoresSafeArea() root ZStack: fills the
            // full screen and geo.safeAreaInsets correctly reports device insets.
            // (QuickGuideView lives in a fullScreenCover — no NavigationView wrapper,
            // so no double-counting of top inset like in OnboardingView.)
            GeometryReader { geo in
                let w           = geo.size.width
                let h           = geo.size.height
                let topInset    = geo.safeAreaInsets.top
                let bottomInset = geo.safeAreaInsets.bottom

                // Fixed chrome heights (no skip button)
                let dotsH: CGFloat    = 20
                let buttonH: CGFloat  = 54
                let bottomPad: CGFloat = max(24, bottomInset + 16)
                // Gaps: pages→dots(12), dots→button-gap(14)
                let spacingH: CGFloat  = 12 + 14
                let fixedH = topInset + dotsH + buttonH + bottomPad + spacingH

                // Scrollable page area
                let pageH = max(200, h - fixedH)

                // Mockup: 66 % of pageH → visually larger, pushes text block lower
                let mockupAvailH  = pageH * 0.66
                let scaleByH      = mockupAvailH / 568.0
                let scaleByW      = (w - 40) / 280.0
                let mockupScale   = max(0.44, min(scaleByH, scaleByW, 1.10))
                let mockupLayoutW = 280.0 * mockupScale
                let mockupLayoutH = 568.0 * mockupScale

                // Typography scales slightly with screen width
                let titleSize    = max(22, min(w * 0.065, 28))
                let subtitleSize = max(14, min(w * 0.042, 17))
                let bodySize     = max(13, min(w * 0.038, 15))

                VStack(spacing: 0) {
                    // Safe-area top pad
                    Spacer().frame(height: topInset)

                    // Pages
                    TabView(selection: $currentPage) {
                        ForEach(pages.indices, id: \.self) { i in
                            pageView(
                                pages[i],
                                mockupLayoutW: mockupLayoutW,
                                mockupLayoutH: mockupLayoutH,
                                mockupScale:   mockupScale,
                                titleSize:     titleSize,
                                subtitleSize:  subtitleSize,
                                bodySize:      bodySize
                            )
                            .tag(i)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: pageH)

                    // Dots
                    HStack(spacing: 8) {
                        ForEach(pages.indices, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    i == currentPage
                                    ? AnyShapeStyle(LinearGradient(
                                        colors: [AppTheme.primary, AppTheme.primaryLight],
                                        startPoint: .leading, endPoint: .trailing))
                                    : AnyShapeStyle(AppTheme.border.opacity(0.7))
                                )
                                .frame(width: i == currentPage ? 22 : 8, height: 8)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentPage)
                        }
                    }
                    .frame(height: dotsH)

                    Spacer().frame(height: 14)

                    // Next / Get Started
                    Button(action: handleNext) {
                        HStack(spacing: 8) {
                            Text(currentPage == pages.count - 1
                                 ? NSLocalizedString("guide.get_started", comment: "Get Started")
                                 : NSLocalizedString("guide.next", comment: "Next"))
                            .font(.system(size: 17, weight: .semibold))
                            if currentPage < pages.count - 1 {
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 14, weight: .semibold))
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: buttonH)
                        .background(
                            LinearGradient(
                                colors: [AppTheme.primary, AppTheme.primaryLight],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(27)
                        .shadow(color: AppTheme.primary.opacity(0.35), radius: 12, y: 5)
                    }
                    .padding(.horizontal, 28)

                    Spacer().frame(height: bottomPad)
                }
                .frame(width: w, height: h, alignment: .top)
            }
        }
        .ignoresSafeArea() // root ZStack fills full screen; GeometryReader inside gets real safeAreaInsets
        .trackScreen(AnalyticsScreen.quickGuide)
    }

    // MARK: - Page content

    private func pageView(
        _ page: GuidePage,
        mockupLayoutW: CGFloat,
        mockupLayoutH: CGFloat,
        mockupScale: CGFloat,
        titleSize: CGFloat,
        subtitleSize: CGFloat,
        bodySize: CGFloat
    ) -> some View {
        VStack(spacing: 0) {
            // Small top breathing room
            Spacer(minLength: 6)

            // Phone mockup — larger thanks to 66% allocation
            iPhoneMockupView { quickGuideMockupInner(for: page) }
                .scaleEffect(mockupScale)
                .frame(width: mockupLayoutW, height: mockupLayoutH)
                .shadow(color: Color.black.opacity(0.12), radius: 20, x: 0, y: 10)

            // Gap between mockup and text (flexible — absorbs remaining space,
            // pushing text block naturally lower on taller phones)
            Spacer(minLength: 12)

            // Text block
            VStack(alignment: .center, spacing: 10) {
                Text(page.title)
                    .font(.system(size: titleSize, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.82)
                    .lineLimit(2)

                Text(page.subtitle)
                    .font(.system(size: subtitleSize, weight: .semibold))
                    .foregroundColor(AppTheme.primary)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.85)
                    .lineLimit(2)

                Text(page.description)
                    .font(.system(size: bodySize))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .minimumScaleFactor(0.8)
                    .lineLimit(6)
            }
            .padding(.horizontal, 32)

            // Small bottom breathing room (less than top → text sits lower)
            Spacer(minLength: 4)
        }
    }

    // MARK: - Mockup image loader

    @ViewBuilder
    private func quickGuideMockupInner(for page: GuidePage) -> some View {
        if let name = page.mockupImageAssetName,
           let ui = QuickGuideMockupAssets.uiImage(named: name, languageCode: languageManager.currentLanguage) {
            Image(uiImage: ui)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            OnboardingDemoVideoView()
        }
    }

    // MARK: - Actions

    private func handleNext() {
        if currentPage < pages.count - 1 {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                currentPage += 1
            }
        } else {
            handleComplete()
        }
    }

    private func handleComplete() {
        LocalStorageManager.shared.hasSeenQuickGuide = true
        onComplete()
        dismiss()
    }
}

// MARK: - Model

struct GuidePage {
    let mockupImageAssetName: String?
    let title: String
    let subtitle: String
    let description: String
}

enum QuickGuideMockupAssets {
    static let pageAssetNames = [
        "QuickGuidePage1",
        "QuickGuidePage2",
        "QuickGuidePage3",
        "QuickGuidePage4"
    ]

    static let programReadyAssetNames = [
        "ProgramReadyMockup1",
        "ProgramReadyMockup2",
        "ProgramReadyMockup3",
        "ProgramReadyMockup4",
        "ProgramReadyMockup5"
    ]

    private static let folders = [
        "ProgramReadyMockupImages",
        "QuickGuideMockupImages"
    ]
    private static let imageExtensions = ["png", "jpg", "jpeg", "heic", "webp"]

    /// Custom paywall shots when present; otherwise the Quick Guide screenshots.
    static func programReadyFanNames(languageCode: String) -> [String] {
        let custom = programReadyAssetNames.filter { uiImage(named: $0, languageCode: languageCode) != nil }
        return custom.isEmpty ? pageAssetNames : custom
    }

    static func uiImage(named baseName: String, languageCode: String) -> UIImage? {
        let candidates = localizedNameCandidates(for: baseName, languageCode: languageCode)

        for name in candidates {
            if let assetImage = UIImage(named: name) { return assetImage }
        }

        for folder in folders {
            for name in candidates {
                for ext in imageExtensions {
                    if let url = Bundle.main.url(
                        forResource: name, withExtension: ext,
                        subdirectory: folder
                    ), let img = UIImage(contentsOfFile: url.path) {
                        return img
                    }
                }
            }
        }

        for folder in folders {
            if let folderURL = Bundle.main.resourceURL?.appendingPathComponent(folder) {
                let fm = FileManager.default
                if let urls = try? fm.contentsOfDirectory(
                    at: folderURL, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]
                ) {
                    let base = baseName.lowercased()
                    for fileURL in urls {
                        let name = fileURL.lastPathComponent.lowercased()
                        if name.hasPrefix(base) || name.replacingOccurrences(of: " ", with: "").hasPrefix(base) {
                            if let img = UIImage(contentsOfFile: fileURL.path) { return img }
                        }
                    }
                }
            }
        }
        return nil
    }

    private static func localizedNameCandidates(for baseName: String, languageCode: String) -> [String] {
        var candidates: [String] = []

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

#Preview {
    QuickGuideView(onComplete: {})
}
