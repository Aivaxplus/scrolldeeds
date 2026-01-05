import SwiftUI

struct OnboardingView: View {
    let onNext: () -> Void

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    Spacer(minLength: 40)
                    
                    // Hero Section
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.gradientPrimary)
                                .frame(width: 110, height: 110)
                                .shadow(color: AppTheme.primary.opacity(0.3), radius: 20, y: 10)
                            
                            Image(systemName: "sparkles")
                                .font(.system(size: 42, weight: .semibold))
                                .foregroundColor(AppTheme.textOnDark)
                            
                            // Badge
                            Text("3")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(AppTheme.textOnDark)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(AppTheme.gradientGold)
                                        .shadow(color: AppTheme.accent.opacity(0.4), radius: 6, y: 3)
                                )
                                .offset(x: 45, y: -45)
                        }
                        
                        VStack(spacing: 12) {
                            Text("ScrollDeeds")
                                .font(.system(size: 30, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)
                                .multilineTextAlignment(.center)
                            
                            Text("Break free from doomscrolling through the power of dhikr")
                                .font(.system(size: 17))
                                .foregroundColor(AppTheme.textSecondary)
                                .multilineTextAlignment(.center)
                                .lineSpacing(4)
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 8)
                    
                    // Feature Cards
                    VStack(spacing: 16) {
                        featureCard(
                            icon: "brain.head.profile",
                            title: "Reclaim Your Focus",
                            description: "Stop endless scrolling that damages your attention span and mental clarity"
                        )
                        
                        featureCard(
                            icon: "sparkles",
                            title: "Dhikr Unlock",
                            description: "Recite Alhamdulillah, Astaghfirullah, Allahu Akbar, or Subhanallah 3 times to unlock your apps"
                        )
                        
                        featureCard(
                            icon: "clock.fill",
                            title: "Mindful Time Limits",
                            description: "Get focused screen time based on your chosen difficulty level. When it ends, alarms keep reminding you until you relock."
                        )
                    }
                    .padding(.horizontal, 20)
                    
                    // CTA Button
                    VStack(spacing: 16) {
                        Button("Get Started") {
                            onNext()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal, 20)
                        
                        VStack(spacing: 8) {
                            Text("By continuing, you agree to our")
                                .font(.system(size: 13))
                                .foregroundColor(AppTheme.textMuted)
                            
                            HStack(spacing: 4) {
                                Button(action: {
                                    // Open Privacy Policy
                                    if let url = URL(string: "https://scrolldeeds.lovable.app/privacy") {
                                        UIApplication.shared.open(url)
                                    }
                                }) {
                                    Text("Privacy Policy")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(AppTheme.primary)
                                        .underline()
                                }
                                
                                Text("and")
                                    .font(.system(size: 13))
                                    .foregroundColor(AppTheme.textMuted)
                                
                                Button(action: {
                                    // Open Terms of Service
                                    if let url = URL(string: "https://scrolldeeds.lovable.app/terms") {
                                        UIApplication.shared.open(url)
                                    }
                                }) {
                                    Text("Terms of Service")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(AppTheme.primary)
                                        .underline()
                                }
                            }
                        }
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    }
                    .padding(.top, 8)
                    
                    Spacer(minLength: 40)
                }
            }
        }
    }

    private func featureCard(icon: String, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppTheme.primary.opacity(0.12))
                    .frame(width: 56, height: 56)
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(AppTheme.primary)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                Text(description)
                    .font(.system(size: 15))
                    .foregroundColor(AppTheme.textSecondary)
                    .lineSpacing(3)
            }
            
            Spacer(minLength: 0)
        }
        .padding(20)
        .background(AppTheme.card)
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.06), radius: 15, y: 8)
    }
}

#Preview { OnboardingView(onNext: {}) }


