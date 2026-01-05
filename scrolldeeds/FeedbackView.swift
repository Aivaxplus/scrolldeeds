//
//  FeedbackView.swift
//  scrolldeeds
//
//  Beautiful feedback request popup after 3 unlocks
//

import SwiftUI

struct FeedbackView: View {
    @Binding var isPresented: Bool
    let onRate: () -> Void
    let onDismiss: () -> Void
    @State private var animateStars = false
    
    var body: some View {
        ZStack {
            // Enhanced semi-transparent background with blur
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        onDismiss()
                        isPresented = false
                    }
                }
            
            // Main card with enhanced styling
            VStack(spacing: 28) {
                // Animated icon with stars
                ZStack {
                    // Outer glow
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    AppTheme.primary.opacity(0.2),
                                    AppTheme.primary.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .blur(radius: 20)
                        .scaleEffect(animateStars ? 1.1 : 1.0)
                    
                    // Middle circle
                    Circle()
                        .fill(AppTheme.primary.opacity(0.15))
                        .frame(width: 90, height: 90)
                    
                    // Inner circle
                    Circle()
                        .fill(AppTheme.primary.opacity(0.1))
                        .frame(width: 80, height: 80)
                    
                    // Star icon
                    Image(systemName: "star.fill")
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundColor(AppTheme.primary)
                        .rotationEffect(.degrees(animateStars ? 360 : 0))
                }
                .onAppear {
                    withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: false)) {
                        animateStars = true
                    }
                }
                
                VStack(spacing: 12) {
                    // Title
                    Text("Loving ScrollDeeds?")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)
                    
                    // Description
                    Text("Your feedback helps us improve and reach more people who need mindful screen time.")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(AppTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)
                        .padding(.horizontal, 12)
                }
                
                // Buttons with enhanced styling
                VStack(spacing: 14) {
                    // Rate button - Enhanced
                    Button(action: {
                        HapticManager.shared.medium()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            onRate()
                            isPresented = false
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Rate on App Store")
                                .font(.system(size: 17, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            AppTheme.gradientPrimary
                                .shadow(color: Color.black.opacity(0.2), radius: 12, y: 6)
                        )
                        .cornerRadius(16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .strokeBorder(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.3), Color.clear],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                        )
                    }
                    
                    // Dismiss button - Enhanced
                    Button(action: {
                        HapticManager.shared.soft()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            onDismiss()
                            isPresented = false
                        }
                    }) {
                        Text("Maybe Later")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppTheme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppTheme.card.opacity(0.5))
                            .cornerRadius(14)
                    }
                }
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(AppTheme.card)
                    .shadow(color: Color.black.opacity(0.3), radius: 40, y: 20)
            )
            .padding(.horizontal, 24)
            .scaleEffect(isPresented ? 1.0 : 0.9)
            .opacity(isPresented ? 1.0 : 0.0)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.95)))
        .zIndex(1000)
    }
}

#Preview {
    FeedbackView(isPresented: .constant(true), onRate: {
        // Preview only
    }, onDismiss: {
        // Preview only
    })
}

