//
//  ThankYouView.swift
//  scrolldeeds
//
//  Thank you page shown after successful subscription
//

import SwiftUI

struct ThankYouView: View {
    let onContinue: () -> Void
    
    @State private var showContent = false
    @State private var showButton = false
    @State private var confettiOpacity: Double = 0
    @State private var pulseAnimation = false
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [
                    Color(red: 0.04, green: 0.08, blue: 0.06),
                    Color(red: 0.08, green: 0.14, blue: 0.10),
                    Color(red: 0.06, green: 0.10, blue: 0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Radial glow
            RadialGradient(
                colors: [AppTheme.primary.opacity(0.15), Color.clear],
                center: .center,
                startRadius: 0,
                endRadius: 350
            )
            .ignoresSafeArea()
            
            // Confetti particles
            ForEach(0..<20, id: \.self) { i in
                ConfettiParticle(delay: Double(i) * 0.1)
                    .opacity(confettiOpacity)
            }
            
            VStack(spacing: 40) {
                Spacer()
                
                // Success Icon
                ZStack {
                    // Outer rings
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .stroke(AppTheme.success.opacity(0.15 - Double(i) * 0.04), lineWidth: 3)
                            .frame(width: CGFloat(180 - i * 30), height: CGFloat(180 - i * 30))
                            .scaleEffect(pulseAnimation ? 1.0 + Double(i) * 0.05 : 1.0)
                            .animation(
                                .easeInOut(duration: 1.5)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.2),
                                value: pulseAnimation
                            )
                    }
                    
                    // Main circle
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.success, AppTheme.success.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                        .shadow(color: AppTheme.success.opacity(0.5), radius: 30)
                    
                    Image(systemName: "checkmark")
                        .font(.system(size: 56, weight: .bold))
                        .foregroundColor(.white)
                }
                .opacity(showContent ? 1 : 0)
                .scaleEffect(showContent ? 1 : 0.5)
                
                // Text content
                VStack(spacing: 20) {
                    Text("JazakAllahu Khayran!")
                        .font(.system(size: 32, weight: .black))
                        .foregroundColor(.white)
                    
                    Text("Welcome to ScrollDeeds Premium")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(AppTheme.accent)
                    
                    Text("You've taken the first step towards\ntransforming your screen time into worship")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 30)
                
                // Benefits reminder
                VStack(spacing: 16) {
                    ThankYouBenefit(icon: "lock.open.fill", text: "Unlock apps with dhikr")
                    ThankYouBenefit(icon: "chart.line.uptrend.xyaxis", text: "Track your spiritual growth")
                    ThankYouBenefit(icon: "bell.badge.fill", text: "Smart reminders")
                    ThankYouBenefit(icon: "infinity", text: "Unlimited sessions")
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(AppTheme.success.opacity(0.2), lineWidth: 1)
                        )
                )
                .opacity(showContent ? 1 : 0)
                .offset(y: showContent ? 0 : 20)
                
                Spacer()
                
                // Continue button
                Button(action: {
                    HapticManager.shared.success()
                    onContinue()
                }) {
                    HStack(spacing: 12) {
                        Text("Start Your Journey")
                            .font(.system(size: 18, weight: .bold))
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .bold))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [AppTheme.success, AppTheme.success.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: AppTheme.success.opacity(0.4), radius: 20, y: 10)
                }
                .opacity(showButton ? 1 : 0)
                .offset(y: showButton ? 0 : 20)
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            // Staggered animations
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.2)) {
                showContent = true
            }
            
            withAnimation(.easeOut(duration: 0.5).delay(0.8)) {
                showButton = true
            }
            
            withAnimation(.easeOut(duration: 0.5).delay(0.3)) {
                confettiOpacity = 1
            }
            
            // Start pulse animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                pulseAnimation = true
            }
            
            // Haptic feedback
            HapticManager.shared.success()
        }
    }
}

// MARK: - Supporting Views

struct ThankYouBenefit: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppTheme.success.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppTheme.success)
            }
            
            Text(text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(AppTheme.success)
        }
    }
}

struct ConfettiParticle: View {
    let delay: Double
    
    @State private var animate = false
    
    private let colors: [Color] = [
        AppTheme.success,
        AppTheme.accent,
        AppTheme.primary,
        .white
    ]
    
    var body: some View {
        Circle()
            .fill(colors.randomElement() ?? AppTheme.success)
            .frame(width: CGFloat.random(in: 6...12), height: CGFloat.random(in: 6...12))
            .position(
                x: CGFloat.random(in: 50...UIScreen.main.bounds.width - 50),
                y: animate ? UIScreen.main.bounds.height + 50 : -50
            )
            .opacity(animate ? 0 : 1)
            .animation(
                .easeIn(duration: Double.random(in: 2...4))
                .delay(delay)
                .repeatForever(autoreverses: false),
                value: animate
            )
            .onAppear {
                animate = true
            }
    }
}

#Preview {
    ThankYouView(onContinue: {})
}

