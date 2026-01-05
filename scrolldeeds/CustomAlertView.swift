//
//  CustomAlertView.swift
//  scrolldeeds
//
//  Beautiful custom alert view to replace standard alerts
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
    
    init(
        title: String,
        message: String,
        icon: String? = nil,
        iconColor: Color? = nil,
        isPresented: Binding<Bool>,
        primaryAction: (() -> Void)? = nil,
        primaryActionTitle: String = "OK",
        secondaryAction: (() -> Void)? = nil,
        secondaryActionTitle: String? = nil
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
    }
    
    var body: some View {
        if isPresented {
            ZStack {
                // Background overlay
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isPresented = false
                        }
                    }
                
                // Alert card
                VStack(spacing: 0) {
                    // Icon (if provided)
                    if let icon = icon {
                        ZStack {
                            Circle()
                                .fill((iconColor ?? AppTheme.primary).opacity(0.15))
                                .frame(width: 70, height: 70)
                            
                            Image(systemName: icon)
                                .font(.system(size: 32, weight: .semibold))
                                .foregroundColor(iconColor ?? AppTheme.primary)
                        }
                        .padding(.top, 24)
                        .padding(.bottom, 16)
                    }
                    
                    // Title
                    Text(title)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 8)
                    
                    // Message
                    Text(message)
                        .font(.system(size: 16))
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                    
                    // Buttons
                    HStack(spacing: 12) {
                        if let secondaryAction = secondaryAction, let secondaryTitle = secondaryActionTitle {
                            Button(action: {
                                HapticManager.shared.soft()
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    isPresented = false
                                }
                                secondaryAction()
                            }) {
                                Text(secondaryTitle)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(AppTheme.textPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(AppTheme.card)
                                    .cornerRadius(12)
                            }
                        }
                        
                        Button(action: {
                            HapticManager.shared.medium()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                isPresented = false
                            }
                            primaryAction?()
                        }) {
                            Text(primaryActionTitle)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(AppTheme.gradientPrimary)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                }
                .frame(maxWidth: 320)
                .background(AppTheme.card)
                .cornerRadius(24)
                .shadow(color: Color.black.opacity(0.3), radius: 30, y: 15)
                .scaleEffect(isPresented ? 1.0 : 0.8)
                .opacity(isPresented ? 1.0 : 0.0)
            }
            .transition(.opacity.combined(with: .scale(scale: 0.9)))
            .zIndex(1000)
        }
    }
}

#Preview {
    ZStack {
        AppTheme.background.ignoresSafeArea()
        
        CustomAlertView(
            title: "Error",
            message: "Something went wrong. Please try again.",
            icon: "exclamationmark.triangle.fill",
            iconColor: .orange,
            isPresented: .constant(true),
            primaryAction: {},
            primaryActionTitle: "OK"
        )
    }
}

