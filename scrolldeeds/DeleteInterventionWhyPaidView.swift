import SwiftUI

struct DeleteInterventionWhyPaidView: View {
    let onContinue: () -> Void
    let onDismiss: () -> Void
    
    private static let pageBg = AppTheme.background
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                DeleteInterventionWhyPaidView.pageBg
                    .ignoresSafeArea()
                
                RadialGradient(
                    colors: [
                        AppTheme.primary.opacity(0.12),
                        AppTheme.primary.opacity(0.04),
                        Color.clear
                    ],
                    center: .top,
                    startRadius: 0,
                    endRadius: 420
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        Button(action: onDismiss) {
                            Image(systemName: "xmark")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)
                                .padding(10)
                                .background(
                                    Circle()
                                        .fill(AppTheme.card.opacity(0.85))
                                        .overlay(
                                            Circle()
                                                .stroke(AppTheme.border.opacity(0.45), lineWidth: 1)
                                        )
                                )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, geometry.safeAreaInsets.top + 8)
                    
                    Spacer().frame(height: 16)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Why We Ask for Payment")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text("Free apps are often downloaded quickly and ignored just as quickly. Real change needs commitment, not convenience.")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(AppTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text("When you pay, you take your intention seriously. You show yourself that your focus, faith, and future are worth protecting.")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(AppTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text("This is not just a fee. It is sadaqah for yourself and an investment in your discipline.")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppTheme.primary)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 22)
                    .background(
                        RoundedRectangle(cornerRadius: 22)
                            .fill(AppTheme.card.opacity(0.9))
                            .overlay(
                                RoundedRectangle(cornerRadius: 22)
                                    .stroke(AppTheme.border.opacity(0.5), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 20)
                    
                    Button(action: onContinue) {
                        HStack(spacing: 10) {
                            Text("I Want to Commit")
                                .font(.system(size: 17, weight: .semibold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 17)
                    }
                    .buttonStyle(ActionCardButtonStyle())
                    .padding(.horizontal, 24)
                    .padding(.bottom, max(24, geometry.safeAreaInsets.bottom + 8))
                }
            }
        }
    }
}

#Preview {
    DeleteInterventionWhyPaidView(onContinue: {}, onDismiss: {})
}
