//
//  CustomAlertView.swift
//  scrolldeeds
//
//  Premium custom alert view with beautiful animations
//

import SwiftUI

struct CustomAlertView: View {
    let title: String
    let message: String
    let icon: String?
    let iconColor: Color?
    @Binding var isPresented: Bool
    let primaryAction: (() -> Void)?
    let primaryActionTitle: String
    let secondaryAction: (() -> Void)?
    let secondaryActionTitle: String?
    /// When true (default), the card floats over a dimmed backdrop, like a system alert.
    /// When false, the card sits on a solid page background — used when this view
    /// is presented as its own full screen, so it reads as the primary content
    /// rather than a translucent overlay on top of something else.
    var dimBackground: Bool = true
    
    @State private var animateIn = false
    @State private var pulseAnimation = false
    @State private var confettiVisible = false
    
    // Check if this is a success message
    private var isSuccess: Bool {
        iconColor == .green || icon == "checkmark.circle.fill"
    }
    
    init(
        title: String,
        message: String,
        icon: String? = nil,
        iconColor: Color? = nil,
        isPresented: Binding<Bool>,
        primaryAction: (() -> Void)? = nil,
        primaryActionTitle: String = NSLocalizedString("common.ok", comment: "OK"),
        secondaryAction: (() -> Void)? = nil,
        secondaryActionTitle: String? = nil,
        dimBackground: Bool = true
    ) {
        self.title = title
        self.message = message
        self.icon = icon
        self.iconColor = iconColor
        self._isPresented = isPresented
        self.primaryAction = primaryAction
        self.primaryActionTitle = primaryActionTitle
        self.secondaryAction = secondaryAction
        self.secondaryActionTitle = secondaryActionTitle
        self.dimBackground = dimBackground
    }
    
    var body: some View {
        if isPresented {
            ZStack {
                // Backdrop — dimmed for a floating alert, solid page color when this
                // view IS the screen. Never dismisses on tap: only the button below does.
                Group {
                    if dimBackground {
                        Color.black.opacity(0.28)
                    } else {
                        AppTheme.background
                    }
                }
                .ignoresSafeArea()
                
                // Confetti for success
                if isSuccess && confettiVisible {
                    ForEach(0..<12, id: \.self) { i in
                        ConfettiPiece(index: i)
                    }
                }
                
                // Premium Alert card
                VStack(spacing: 0) {
                    // Premium Icon
                    if let icon = icon {
                        premiumIconView(icon: icon)
                            .padding(.top, 28)
                            .padding(.bottom, 20)
                    }
                    
                    // Title with gradient for success
                    if isSuccess {
                        Text(title)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [AppTheme.textPrimary, AppTheme.textPrimary.opacity(0.92)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                            .minimumScaleFactor(0.8)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 12)
                    } else {
                        Text(title)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                            .multilineTextAlignment(.center)
                            .lineLimit(nil)
                            .minimumScaleFactor(0.8)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 12)
                    }
                    
                    // Message with better formatting
                    Text(message)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)
                        .lineLimit(nil)
                        .minimumScaleFactor(0.9)
                        .padding(.horizontal, 28)
                        .padding(.bottom, 28)
                    
                    // Premium Buttons
                    HStack(spacing: 12) {
                        if let secondaryAction = secondaryAction, let secondaryTitle = secondaryActionTitle {
                            Button(action: {
                                HapticManager.shared.soft()
                                dismissAlert()
                                secondaryAction()
                            }) {
                                Text(secondaryTitle)
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(AppTheme.textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(AppTheme.muted.opacity(0.8))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 14)
                                                    .strokeBorder(AppTheme.border.opacity(0.45), lineWidth: 1)
                                            )
                                    )
                            }
                        }
                        
                        Button(action: {
                            HapticManager.shared.medium()
                            dismissAlert()
                            primaryAction?()
                        }) {
                            Text(primaryActionTitle)
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(
                                            isSuccess ?
                                            LinearGradient(
                                                colors: [AppTheme.success, AppTheme.success.opacity(0.85)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ) :
                                            LinearGradient(
                                                colors: [AppTheme.primary, AppTheme.primary.opacity(0.85)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                )
                                .shadow(color: (isSuccess ? AppTheme.success : AppTheme.primary).opacity(0.4), radius: 12, y: 6)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
                .frame(maxWidth: 340)
                .background(
                    RoundedRectangle(cornerRadius: 28)
                        .fill(
                            LinearGradient(
                                colors: [
                                    AppTheme.card,
                                    AppTheme.card
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 28)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [
                                            (isSuccess ? AppTheme.success : AppTheme.primary).opacity(0.3),
                                            AppTheme.border.opacity(0.35)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                )
                .shadow(color: Color.black.opacity(0.12), radius: 28, y: 16)
                .scaleEffect(animateIn ? 1.0 : 0.85)
                .opacity(animateIn ? 1.0 : 0.0)
            }
            .transition(.opacity)
            .zIndex(1000)
            .onAppear {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    animateIn = true
                }
                withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                    pulseAnimation = true
                }
                if isSuccess {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        withAnimation {
                            confettiVisible = true
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Premium Icon View
    
    private func premiumIconView(icon: String) -> some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            (iconColor ?? AppTheme.primary).opacity(0.4),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 60
                    )
                )
                .frame(width: 120, height: 120)
                .blur(radius: 15)
                .scaleEffect(pulseAnimation ? 1.1 : 1.0)
            
            // Outer ring
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            (iconColor ?? AppTheme.primary).opacity(0.5),
                            (iconColor ?? AppTheme.primary).opacity(0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 3
                )
                .frame(width: 88, height: 88)
            
            // Inner filled circle
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            (iconColor ?? AppTheme.primary).opacity(0.25),
                            (iconColor ?? AppTheme.primary).opacity(0.1)
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 40
                    )
                )
                .frame(width: 75, height: 75)
            
            // Icon
            Image(systemName: icon)
                .font(.system(size: 38, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            iconColor ?? AppTheme.primary,
                            (iconColor ?? AppTheme.primary).opacity(0.8)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: (iconColor ?? AppTheme.primary).opacity(0.5), radius: 10, y: 4)
        }
    }
    
    // MARK: - Helper Functions
    
    private func dismissAlert() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            animateIn = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            isPresented = false
        }
    }
}

// MARK: - Confetti Piece

struct ConfettiPiece: View {
    let index: Int
    @State private var animate = false
    
    private let colors: [Color] = [
        Color(red: 0.98, green: 0.85, blue: 0.48),
        AppTheme.success,
        AppTheme.primary,
        Color.white,
        Color(red: 0.95, green: 0.78, blue: 0.4)
    ]
    
    var body: some View {
        Circle()
            .fill(colors[index % colors.count])
            .frame(width: CGFloat.random(in: 6...12), height: CGFloat.random(in: 6...12))
            .offset(
                x: animate ? CGFloat.random(in: -150...150) : 0,
                y: animate ? CGFloat.random(in: 100...300) : -50
            )
            .opacity(animate ? 0 : 1)
            .scaleEffect(animate ? 0.3 : 1)
            .onAppear {
                withAnimation(.easeOut(duration: Double.random(in: 0.8...1.5)).delay(Double(index) * 0.05)) {
                    animate = true
                }
            }
    }
}

#Preview {
    ZStack {
        AppTheme.background.ignoresSafeArea()
        
        CustomAlertView(
            title: "Verification Result",
            message: "✅ Verified! Alhamdulillah\n\nYou've unlocked 1 hour. Remember: In the Akhira, you will be questioned about every second you waste.",
            icon: "checkmark.circle.fill",
            iconColor: .green,
            isPresented: .constant(true),
            primaryAction: {},
            primaryActionTitle: "OK"
        )
    }
}
