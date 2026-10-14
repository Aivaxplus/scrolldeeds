import SwiftUI

/// Hero title shown above the paywall phone mockup.
/// Yearly variant highlights the "FREE" trial word; monthly variant shows the accountability hero line.
struct PaywallTrialTitleView: View {
    var titleColor: Color = AppTheme.textPrimary
    var isYearlyTrialHeadline: Bool = true

    var body: some View {
        Group {
            if isYearlyTrialHeadline {
                (
                    Text(NSLocalizedString("paywall.trial.title.before_free", comment: "Start your 3-day "))
                        .foregroundColor(titleColor)
                    + Text(NSLocalizedString("paywall.trial.title.free", comment: "FREE"))
                        .foregroundColor(AppTheme.primary)
                    + Text(NSLocalizedString("paywall.trial.title.after_free", comment: " trial to continue."))
                        .foregroundColor(titleColor)
                )
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
            } else {
                Text(NSLocalizedString("paywall.hero.title.monthly", comment: "Hold yourself accountable. Start with a small commitment."))
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(titleColor)
                    .multilineTextAlignment(.center)
            }
        }
        .lineSpacing(4)
        .lineLimit(4)
        .minimumScaleFactor(0.75)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, 24)
    }
}
