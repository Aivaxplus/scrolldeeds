import SwiftUI

struct WelcomeView: View {
    enum Tab: String, CaseIterable {
        case signIn = "Sign In"
        case signUp = "Sign Up"
    }
    
    @State private var selectedTab: Tab = .signIn
    @State private var email: String = ""
    @State private var password: String = ""
    let onContinue: () -> Void

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Logo & Title Section
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(AppTheme.gradientPrimary)
                            .frame(width: 90, height: 90)
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 38))
                            .foregroundColor(AppTheme.textOnDark)
                    }
                    .shadow(color: AppTheme.primary.opacity(0.3), radius: 20, y: 10)
                    
                    VStack(spacing: 8) {
                        Text("ScrollDeeds")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                        Text("Break free from doomscrolling through dhikr")
                            .font(.system(size: 16))
                            .foregroundColor(AppTheme.textSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                }
                .padding(.bottom, 48)
                
                // Card Section
                VStack(spacing: 24) {
                    // Tab Switcher
                    HStack(spacing: 0) {
                        ForEach(Tab.allCases, id: \.self) { tab in
                            Button(action: { 
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedTab = tab
                                }
                            }) {
                                Text(tab.rawValue)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(selectedTab == tab ? AppTheme.primary : AppTheme.textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(
                                        selectedTab == tab ? 
                                        AppTheme.card : Color.clear
                                    )
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding(4)
                    .background(AppTheme.muted)
                    .cornerRadius(14)
                    
                    // Form Fields
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppTheme.textSecondary)
                            TextField("you@example.com", text: $email)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                                .font(.system(size: 16))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(AppTheme.muted)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppTheme.primary.opacity(0.2), lineWidth: 1)
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppTheme.textSecondary)
                            SecureField("••••••••", text: $password)
                                .font(.system(size: 16))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(AppTheme.muted)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(AppTheme.primary.opacity(0.2), lineWidth: 1)
                                )
                        }
                    }
                    
                    // Action Button
                    Button(selectedTab == .signIn ? "Continue" : "Create Account") {
                        onContinue()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    
                    // Terms
                    Text("By continuing, you agree to our Terms of Service")
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.textMuted)
                        .multilineTextAlignment(.center)
                }
                .padding(28)
                .background(AppTheme.card)
                .cornerRadius(24)
                .shadow(color: Color.black.opacity(0.08), radius: 30, y: 15)
                .padding(.horizontal, 24)
                
                Spacer()
            }
        }
    }
}

#Preview { WelcomeView(onContinue: {}) }


