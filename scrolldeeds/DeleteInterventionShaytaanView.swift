import SwiftUI

struct DeleteInterventionShaytaanView: View {
    let onContinue: () -> Void
    let onDismiss: () -> Void
    
    private static let pageBg = AppTheme.background

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                DeleteInterventionShaytaanView.pageBg
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
                        Text("Shaytaan Is Tricking You")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text("Right now, you are close to a real breakthrough. Deleting the app in this exact moment often feels like relief, but it usually leads back to the same cycle of distraction, regret, and lost time.")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(AppTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text("This is not just about an app. It is about protecting your focus, your salah, and your future. Stay with ScrollDeeds and choose discipline over impulse.")
                            .font(.system(size: 17, weight: .regular))
                            .foregroundColor(AppTheme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text("Paying is a commitment to yourself - a sadaqah and an investment in your growth.")
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
                            Text("Continue With ScrollDeeds")
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
    DeleteInterventionShaytaanView(onContinue: {}, onDismiss: {})
}
