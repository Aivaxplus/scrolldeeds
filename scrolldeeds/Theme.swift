import SwiftUI

// MARK: - ScrollDeeds Color System
//
// Light Mode: Soft off-white backgrounds, clean white surfaces, soft Apple-style green.
// Dark Mode:  Calm deep forest, bright emerald, kept consistent with the light system.
// Gold is used only as a rare highlight. All text values target WCAG AA contrast.

enum AppTheme {

    // MARK: - Backgrounds

    /// Main screen background — warm, airy off-white (Journal-like calm, not clinical white)
    static var background: Color {
        adaptive(
            light: UIColor(r: 0.976, g: 0.969, b: 0.953), // warm off-white #F9F7F3
            dark:  UIColor(r: 0.075, g: 0.102, b: 0.090)  // calm forest #131A17
        )
    }

    /// Card / surface — clean, elevated over background
    static var card: Color {
        adaptive(
            light: UIColor.white,
            dark:  UIColor(r: 0.110, g: 0.141, b: 0.125)  // dark card #1C2420
        )
    }

    /// Secondary card — very light gray surface, for nested or grouped content
    static var cardSecondary: Color {
        adaptive(
            light: UIColor(r: 0.949, g: 0.957, b: 0.945), // light gray surface #F2F4F1
            dark:  UIColor(r: 0.137, g: 0.176, b: 0.157)  // dark tinted card
        )
    }

    // MARK: - Brand Colors

    /// Primary green — soft, modern Apple-style green (readable, not neon)
    static var primary: Color {
        adaptive(
            light: UIColor(r: 0.157, g: 0.604, b: 0.392), // soft emerald #289A64
            dark:  UIColor(r: 0.349, g: 0.776, b: 0.541)  // bright emerald #59C68A
        )
    }

    static let primaryLight = Color(red: 0.376, green: 0.776, blue: 0.557) // bright highlight
    static let primaryDark  = Color(red: 0.106, green: 0.420, blue: 0.270) // deep shadow

    /// Face of the primary action key — the brand emerald, kept readable under white text.
    static var actionFace: Color {
        adaptive(
            light: UIColor(r: 0.157, g: 0.604, b: 0.392), // brand emerald #289A64
            dark:  UIColor(r: 0.180, g: 0.549, b: 0.365)  // #2E8C5D
        )
    }

    /// Base the action key rests on — a deeper forest green that reads as the
    /// button's own shadow, so pressing it looks like the key drops onto it.
    static var actionInk: Color {
        adaptive(
            light: UIColor(r: 0.086, g: 0.353, b: 0.235), // deep forest #165A3C
            dark:  UIColor(r: 0.078, g: 0.310, b: 0.208)  // #145035
        )
    }

    /// Accent gold — used sparingly as a rare highlight only
    static var accent: Color {
        adaptive(
            light: UIColor(r: 0.706, g: 0.443, b: 0.031), // rich amber #B4710A
            dark:  UIColor(r: 0.949, g: 0.780, b: 0.420)  // warm gold #F2C76B
        )
    }

    static let accentLight = Color(red: 0.980, green: 0.882, blue: 0.651) // pale gold
    /// Rating / review stars everywhere in the app.
    static let starYellow = Color(red: 1.0, green: 0.769, blue: 0.0) // #FFC400
    /// Darker gold for badges
    static let accentDark = Color(red: 0.72, green: 0.52, blue: 0.12)
    /// ScrollDeeds green for yearly-plan paywall badge (e.g. "3 DAYS FREE"; white text stays readable)
    static var badgeMostPopular: Color { primary }

    /// “3 days free” trial chip on pricing cards (blue pill, white text)
    static let paywallTrialBadgeBackground = Color(red: 0.20, green: 0.52, blue: 0.96)

    // MARK: - Text

    /// Main body text — near-black / soft off-white
    static var textPrimary: Color {
        adaptive(
            light: UIColor(r: 0.102, g: 0.114, b: 0.106), // near-black #1A1D1B
            dark:  UIColor(r: 0.933, g: 0.961, b: 0.941)  // soft off-white #EEF5F0
        )
    }

    /// Secondary text — medium contrast for labels, subtitles
    static var textSecondary: Color {
        adaptive(
            light: UIColor(r: 0.353, g: 0.400, b: 0.376), // medium gray-green #5A6660
            dark:  UIColor(r: 0.651, g: 0.710, b: 0.675)  // muted green-grey
        )
    }

    /// Muted text — hints, placeholders, footnotes
    static var textMuted: Color {
        adaptive(
            light: UIColor(r: 0.541, g: 0.576, b: 0.553), // readable muted #8A938D
            dark:  UIColor(r: 0.471, g: 0.514, b: 0.486)  // dark muted
        )
    }

    static let textOnDark  = Color.white
    static let textOnLight = Color(red: 0.102, green: 0.114, blue: 0.106)

    // MARK: - Surfaces

    /// Muted surface — for pills, chips, toggle backgrounds
    static var muted: Color {
        adaptive(
            light: UIColor(r: 0.933, g: 0.941, b: 0.929), // light neutral #EEF0ED
            dark:  UIColor(r: 0.137, g: 0.184, b: 0.157)  // dark muted surface
        )
    }

    /// Secondary surface — for page-section backgrounds
    static var secondary: Color {
        adaptive(
            light: UIColor(r: 0.945, g: 0.953, b: 0.941), // pale neutral wash #F1F3EF
            dark:  UIColor(r: 0.169, g: 0.220, b: 0.188)
        )
    }

    /// Subtle border — for card outlines, dividers
    static var border: Color {
        adaptive(
            light: UIColor(r: 0.906, g: 0.914, b: 0.898), // soft border #E7E9E5
            dark:  UIColor(r: 0.208, g: 0.267, b: 0.231)
        )
    }

    // MARK: - Status

    static let success = Color(red: 0.157, green: 0.639, blue: 0.400) // clear green
    static let error   = Color(red: 0.859, green: 0.298, blue: 0.298)
    static let warning = Color(red: 0.918, green: 0.596, blue: 0.106)

    /// Soft, Apple Health–style status accents — used only for small status
    /// indicators (dots, pills) where color communicates state at a glance.
    /// Additive tokens; existing `success`/`error` are unchanged elsewhere.
    static let statusPositive = Color(red: 0.133, green: 0.773, blue: 0.369) // #22C55E
    static let statusNegative = Color(red: 0.973, green: 0.443, blue: 0.443) // #F87171

    // MARK: - Gradients

    /// Primary action gradient — soft green (works in both modes)
    static var gradientPrimary: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.176, green: 0.639, blue: 0.420), // #2DA36B
                Color(red: 0.231, green: 0.706, blue: 0.471)  // #3BB478
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Gold / amber gradient — rare highlight only
    static var gradientGold: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.918, green: 0.714, blue: 0.361),
                Color(red: 0.843, green: 0.635, blue: 0.271)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    /// Subtle atmospheric background gradient — light and airy
    static var gradientPeaceful: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.973, green: 0.976, blue: 0.969),
                Color(red: 0.945, green: 0.957, blue: 0.949)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    // MARK: - Helpers

    private static func adaptive(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? dark : light })
    }
}

// MARK: - ScrollDeeds Design Tokens

enum AppSpacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 22
    static let xl: CGFloat = 28
    static let xxl: CGFloat = 36
    static let page: CGFloat = 24
    static let section: CGFloat = 32
}

enum AppRadius {
    static let sm: CGFloat = 14
    static let md: CGFloat = 18
    static let lg: CGFloat = 22
    static let xl: CGFloat = 28
    static let sheet: CGFloat = 32
    static let pill: CGFloat = 999
}

enum AppTypography {
    /// Large hero title (Apple large-title feel)
    static let hero = Font.system(size: 40, weight: .bold, design: .rounded)
    static let display = Font.system(size: 34, weight: .bold, design: .rounded)
    static let largeTitle = Font.system(size: 30, weight: .bold, design: .rounded)
    static let screenTitle = Font.system(size: 26, weight: .bold, design: .rounded)
    static let sectionTitle = Font.system(size: 20, weight: .bold, design: .rounded)
    static let cardTitle = Font.system(size: 17, weight: .semibold, design: .rounded)
    static let body = Font.system(size: 16, weight: .regular)
    static let bodyMedium = Font.system(size: 16, weight: .medium)
    static let callout = Font.system(size: 15, weight: .medium)
    static let caption = Font.system(size: 13, weight: .medium)
    static let badge = Font.system(size: 12, weight: .bold, design: .rounded)
}

enum AppMotion {
    static let soft = Animation.easeInOut(duration: 0.22)
    static let spring = Animation.spring(response: 0.34, dampingFraction: 0.82)
    /// Last onboarding page → plan loading. Slow enough to read as one scene.
    static let funnelHandoff = Animation.spring(response: 0.82, dampingFraction: 0.86)
    static let funnelDissolve = Animation.easeInOut(duration: 0.52)
}

struct OnboardingHandoffModifier: ViewModifier {
    let isActive: Bool

    func body(content: Content) -> some View {
        content
            .opacity(isActive ? 0 : 1)
            .allowsHitTesting(!isActive)
    }
}

extension AnyTransition {
    /// Outgoing onboarding page: fade off the shared cream canvas.
    /// The last page already dissolves its own content before this fires.
    static var funnelHandoffOut: AnyTransition {
        .opacity
    }

    /// Incoming loading / paywall: fade onto the same cream canvas.
    /// Content blooms inside `PaywallPlanLoadingView` so the full screen never scales.
    static var funnelHandoffIn: AnyTransition {
        .opacity
    }
}

// MARK: - Shared Surfaces

struct SDPageBackground: View {
    var body: some View {
        ZStack {
            AppTheme.background
            // Very subtle green wash for depth without darkening the airy feel.
            LinearGradient(
                colors: [
                    AppTheme.primary.opacity(0.04),
                    Color.clear,
                    AppTheme.primary.opacity(0.02)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .ignoresSafeArea()
    }
}

/// Light green liquid-glass card surface — soft fill, gradient border, inner highlight.
struct SDLiquidGlassSurface: View {
    var cornerRadius: CGFloat = AppRadius.md

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.92),
                        AppTheme.primary.opacity(0.05),
                        AppTheme.cardSecondary.opacity(0.88)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                AppTheme.primaryLight.opacity(0.75),
                                AppTheme.primary.opacity(0.50),
                                AppTheme.primary.opacity(0.28)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .inset(by: 0.75)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.85), Color.white.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .center
                        ),
                        lineWidth: 1
                    )
            )
    }
}

extension View {
    func sdLiquidGlassCard(cornerRadius: CGFloat = AppRadius.md) -> some View {
        background(SDLiquidGlassSurface(cornerRadius: cornerRadius))
            .shadow(color: AppTheme.primary.opacity(0.14), radius: 14, x: 0, y: 6)
            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
    }
}

struct SDCard<Content: View>: View {
    var padding: CGFloat = AppSpacing.lg
    var cornerRadius: CGFloat = AppRadius.xl
    var accent: Color? = nil
    var content: () -> Content

    var body: some View {
        content()
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(AppTheme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(AppTheme.border.opacity(0.6), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 20, x: 0, y: 8)
    }
}

struct SDIconBadge: View {
    let systemName: String
    var size: CGFloat = 48
    var iconSize: CGFloat = 20
    var color: Color = AppTheme.primary
    var filled: Bool = true

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    filled
                    ? LinearGradient(
                        colors: [color.opacity(0.18), AppTheme.accent.opacity(0.10)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    : LinearGradient(colors: [AppTheme.card, AppTheme.card], startPoint: .top, endPoint: .bottom)
                )
                .overlay(Circle().stroke(color.opacity(0.22), lineWidth: 1))

            Image(systemName: systemName)
                .font(.system(size: iconSize, weight: .semibold))
                .foregroundColor(color)
        }
        .frame(width: size, height: size)
    }
}

struct SDBrandMark: View {
    var iconSize: CGFloat = 26
    var textSize: CGFloat = 24
    var titleColor: Color = AppTheme.primary

    private var markSize: CGFloat { iconSize + 8 }

    var body: some View {
        HStack(spacing: 10) {
            Image("NafsiMark")
                .resizable()
                .scaledToFit()
                .frame(width: markSize, height: markSize)
            Text("Nafsi")
                .font(.system(size: textSize, weight: .bold, design: .rounded))
                .foregroundColor(titleColor)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
        .accessibilityLabel("Nafsi")
    }
}

struct CoinsPillFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        let next = nextValue()
        if next != .zero { value = next }
    }
}

struct SDCoinsPill: View {
    let coins: Int

    @ObservedObject private var journey = HeartJourneyManager.shared
    @State private var fill: CGFloat = 0
    @State private var pop = false

    var body: some View {
        HStack(spacing: 6) {
            NafsiCoinGlyph(size: 18)
                .scaleEffect(pop ? 1.18 : 1)
            Text("\(coins)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(pop ? Color(red: 0.45, green: 0.30, blue: 0.04) : AppTheme.textPrimary)
                .monospacedDigit()
                .fixedSize()
                .lineLimit(1)
        }
        .padding(.leading, 8)
        .padding(.trailing, 12)
        .padding(.vertical, 6)
        .background(
            ZStack {
                Capsule()
                    .fill(AppTheme.card)
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.99, green: 0.86, blue: 0.42),
                                Color(red: 0.93, green: 0.72, blue: 0.22)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .scaleEffect(x: fill, y: 1, anchor: .leading)
            }
        )
        .clipShape(Capsule())
        .scaleEffect(pop ? 1.08 : 1)
        .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
        .overlay(
            Capsule()
                .stroke(AppTheme.textMuted.opacity(0.12), lineWidth: 1)
        )
        .background(
            GeometryReader { geo in
                Color.clear.preference(
                    key: CoinsPillFrameKey.self,
                    value: geo.frame(in: .global)
                )
            }
        )
        .overlay(alignment: .top) {
            if let flash = journey.pillSpendFlash {
                PillSpendLabel(amount: flash.amount)
                    .id(flash.id)
                    .fixedSize()
                    .offset(y: -18)
            }
        }
        .onChange(of: journey.lastCoinChange) { change in
            guard let change, change.amount > 0 else { return }
            fillIn()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(coins) \(NSLocalizedString("heart.xp_label", comment: "Coins"))")
    }

    private func fillIn() {
        fill = 0
        pop = false
        withAnimation(.easeOut(duration: 0.38)) { fill = 1 }
        withAnimation(.spring(response: 0.28, dampingFraction: 0.52)) { pop = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            withAnimation(.easeOut(duration: 0.45)) {
                fill = 0
                pop = false
            }
        }
    }
}

/// Red “−40” that rises off a coin balance each time coins are spent.
struct CoinSpendFloater: View {
    @ObservedObject private var journey = HeartJourneyManager.shared
    @State private var change: CoinChange?
    @State private var rise = false

    var body: some View {
        Group {
            if let change, change.amount < 0 {
                Text("\(change.amount)")
                    .font(.system(size: 16, weight: .black, design: .rounded))
                    .foregroundColor(Color(red: 0.86, green: 0.16, blue: 0.18))
                    .monospacedDigit()
                    .fixedSize()
                    .lineLimit(1)
                    .shadow(color: AppTheme.card.opacity(0.95), radius: 2)
                    .offset(y: rise ? -30 : 6)
                    .opacity(rise ? 0 : 1)
                    .allowsHitTesting(false)
            }
        }
        .onChange(of: journey.lastCoinChange) { next in
            guard let next, next.amount < 0 else { return }
            change = next
            rise = false
            DispatchQueue.main.async {
                withAnimation(.easeOut(duration: 0.85)) { rise = true }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                if change?.id == next.id { change = nil }
            }
        }
    }
}

/// One red spend amount rising off the header coin pill.
private struct PillSpendLabel: View {
    let amount: Int
    @State private var rise = false

    var body: some View {
        Text("\(amount)")
            .font(.system(size: 16, weight: .black, design: .rounded))
            .foregroundColor(Color(red: 0.86, green: 0.16, blue: 0.18))
            .monospacedDigit()
            .fixedSize()
            .lineLimit(1)
            .shadow(color: AppTheme.card.opacity(0.95), radius: 2)
            .offset(y: rise ? -26 : 2)
            .opacity(rise ? 0 : 1)
            .allowsHitTesting(false)
            .onAppear {
                withAnimation(.easeOut(duration: 0.65)) { rise = true }
            }
    }
}

struct SDStreakPill: View {
    let streak: Int
    var ink: Color = AppTheme.textPrimary
    var fill: Color = AppTheme.card

    var body: some View {
        HStack(spacing: 5) {
            Text("🔥")
                .font(.system(size: 16))
            Text("\(streak)")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(ink)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(fill)
                .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
        )
        .overlay(
            Capsule()
                .stroke(AppTheme.textMuted.opacity(0.12), lineWidth: 1)
        )
    }
}

struct SDBrandHeader<Trailing: View>: View {
    private let trailing: Trailing
    private let tagline: String?
    private let buddyPose: String?
    /// Extra space above the header content (on top of the safe area). Keep tight on tall phones.
    private let topPadding: CGFloat
    private let bottomPadding: CGFloat
    private let titleColor: Color

    init(
        tagline: String? = nil,
        buddy: String? = nil,
        topPadding: CGFloat = 4,
        bottomPadding: CGFloat = 8,
        titleColor: Color = AppTheme.primary,
        @ViewBuilder trailing: () -> Trailing
    ) {
        self.tagline = tagline
        self.buddyPose = buddy
        self.topPadding = topPadding
        self.bottomPadding = bottomPadding
        self.titleColor = titleColor
        self.trailing = trailing()
    }

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 1) {
                SDBrandMark(titleColor: titleColor)
                if let tagline {
                    Text(tagline)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.leading, 44)
                }
            }
            Spacer(minLength: 8)
            if let buddyPose {
                NafsiBuddyView(pose: buddyPose, height: 78)
            }
            trailing
        }
        .padding(.horizontal, 20)
        .padding(.top, topPadding)
        .padding(.bottom, bottomPadding)
    }
}

extension SDBrandHeader where Trailing == EmptyView {
    init() {
        self.init { EmptyView() }
    }
}

struct SDDismissButton: View {
    var style: Style = .muted
    let action: () -> Void

    enum Style {
        case muted
        case glass
        case plain
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(foregroundColor)
                .frame(width: 44, height: 44)
                .background(background)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .contentShape(Circle())
    }

    private var foregroundColor: Color {
        switch style {
        case .muted, .plain:
            return AppTheme.textMuted
        case .glass:
            return AppTheme.textPrimary
        }
    }

    @ViewBuilder
    private var background: some View {
        switch style {
        case .muted:
            Circle().fill(AppTheme.muted.opacity(0.72))
        case .glass:
            Circle().fill(AppTheme.card.opacity(0.84))
        case .plain:
            Color.clear
        }
    }
}

struct SDOverlayCard<Content: View>: View {
    var maxWidth: CGFloat = 340
    var content: () -> Content

    var body: some View {
        SDCard(padding: AppSpacing.xl, cornerRadius: AppRadius.sheet, content: content)
            .frame(maxWidth: maxWidth)
            .padding(.horizontal, AppSpacing.xl)
    }
}

// MARK: - Elevation & Card Chrome

/// Semantic elevation tokens — one soft, Apple-like shadow per level.
/// Use these instead of ad-hoc `.shadow(...)` stacks.
enum AppElevation {
    /// Resting card on a page background.
    static func card<V: View>(_ view: V) -> some View {
        view.shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 6)
    }
    /// Floating element (CTA, nav, modal).
    static func floating<V: View>(_ view: V) -> some View {
        view.shadow(color: Color.black.opacity(0.10), radius: 24, x: 0, y: 10)
    }
}

extension View {
    /// The standard dashboard surface: clean card fill, continuous corners,
    /// hairline border, one soft shadow. Replaces the copied "premium card" chrome.
    func sdSurfaceCard(cornerRadius: CGFloat = AppRadius.lg, padding: CGFloat = AppSpacing.lg) -> some View {
        self
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(AppTheme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(AppTheme.border.opacity(0.4), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 14, x: 0, y: 4)
    }
}

// MARK: - UIColor convenience init
private extension UIColor {
    convenience init(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat = 1) {
        self.init(red: r, green: g, blue: b, alpha: a)
    }
}

// MARK: - Button Styles

/// Canonical primary CTA — solid emerald key on a deeper forest base.
/// Matches the dashboard “Unlock apps” button; use for every primary action.
///
/// IMPORTANT: Face + ink are always backgrounds of the sized label. Never place an
/// unconstrained Capsule in a ZStack — it expands to the parent proposal and
/// becomes a giant circle under flexible layouts.
struct PrimaryButtonStyle: ButtonStyle {
    /// How far the face sits above its base.
    var depth: CGFloat = 5
    /// When false, label keeps its own font/padding (for custom content).
    var stylesLabel: Bool = true
    /// Vertical padding when `stylesLabel` is true. Use a larger value for hero CTAs.
    var verticalPadding: CGFloat = 17

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed && isEnabled
        let shape = Capsule(style: .continuous)
        let face = isEnabled ? AppTheme.actionFace : AppTheme.muted
        let ink = isEnabled ? AppTheme.actionInk : AppTheme.muted.opacity(0.75)

        return Group {
            if stylesLabel {
                configuration.label
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, verticalPadding)
            } else {
                configuration.label
            }
        }
        .background(shape.fill(face))
        .overlay(
            shape.strokeBorder(Color.white.opacity(isEnabled ? 0.18 : 0), lineWidth: 1)
        )
        // Depth “base” — sized to the label, not the parent proposal
        .background(
            shape
                .fill(ink)
                .offset(y: depth)
        )
        .offset(y: pressed ? depth : 0)
        .padding(.bottom, depth)
        .contentShape(Rectangle())
        .animation(.spring(response: 0.2, dampingFraction: 0.72), value: pressed)
    }
}

/// Same physical key as `PrimaryButtonStyle`, without forcing label typography.
struct ActionCardButtonStyle: ButtonStyle {
    var depth: CGFloat = 5

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let pressed = configuration.isPressed && isEnabled
        let shape = Capsule(style: .continuous)
        let face = isEnabled ? AppTheme.actionFace : AppTheme.muted
        let ink = isEnabled ? AppTheme.actionInk : AppTheme.muted.opacity(0.75)

        return configuration.label
            .background(shape.fill(face))
            .overlay(
                shape.strokeBorder(Color.white.opacity(isEnabled ? 0.18 : 0), lineWidth: 1)
            )
            .background(
                shape
                    .fill(ink)
                    .offset(y: depth)
            )
            .offset(y: pressed ? depth : 0)
            .padding(.bottom, depth)
            .contentShape(Rectangle())
            .animation(.spring(response: 0.2, dampingFraction: 0.72), value: pressed)
    }
}

/// Convenience primary CTA with standard chrome.
struct SDPrimaryButton: View {
    let title: String
    var systemImage: String? = nil
    var isLoading: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if isLoading {
                    SwiftUI.ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text(title)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    if let systemImage {
                        Image(systemName: systemImage)
                            .font(.system(size: 16, weight: .bold))
                    }
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(isLoading)
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
                    .stroke(AppTheme.primary.opacity(0.18), lineWidth: 1.5)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}
