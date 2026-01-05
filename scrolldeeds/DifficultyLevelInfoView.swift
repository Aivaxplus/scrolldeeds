//
//  DifficultyLevelInfoView.swift
//  scrolldeeds
//
//  Beautiful full popup view explaining a difficulty level
//

import SwiftUI

struct DifficultyLevelInfoView: View {
    let level: DifficultyLevel
    let onDismiss: () -> Void
    @State private var appearAnimation = false
    
    var body: some View {
        ZStack {
            // Background
            AppTheme.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Drag indicator
                Capsule()
                    .fill(AppTheme.muted)
                    .frame(width: 36, height: 5)
                    .padding(.top, 12)
                    .padding(.bottom, 20)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        // Hero Section
                        VStack(spacing: 24) {
                            // Animated Icon with rings
                            ZStack {
                                // Outer glow rings
                                ForEach(0..<3) { i in
                                    Circle()
                                        .stroke(
                                            level.color.opacity(0.12 - Double(i) * 0.03),
                                            lineWidth: 2
                                        )
                                        .frame(width: CGFloat(100 + i * 28), height: CGFloat(100 + i * 28))
                                        .scaleEffect(appearAnimation ? 1.0 : 0.8)
                                        .opacity(appearAnimation ? 1.0 : 0.0)
                                        .animation(
                                            .spring(response: 0.6, dampingFraction: 0.7)
                                            .delay(Double(i) * 0.1),
                                            value: appearAnimation
                                        )
                                }
                                
                                // Glow effect
                                Circle()
                                    .fill(level.color.opacity(0.15))
                                    .frame(width: 90, height: 90)
                                    .blur(radius: 15)
                                
                                // Main circle with gradient
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                level.color.opacity(0.25),
                                                level.color.opacity(0.12)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 88, height: 88)
                                
                                // Inner circle
                                Circle()
                                    .fill(AppTheme.card)
                                    .frame(width: 72, height: 72)
                                
                                // Icon
                                Image(systemName: level.icon)
                                    .font(.system(size: 34, weight: .semibold))
                                    .foregroundColor(level.color)
                            }
                            .frame(height: 160)
                            
                            // Title & Duration Badge
                            VStack(spacing: 14) {
                                Text(level.displayName)
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(AppTheme.textPrimary)
                                
                                // Duration badge
                                HStack(spacing: 8) {
                                    Image(systemName: "clock.fill")
                                        .font(.system(size: 15))
                                    Text(level.displayDuration)
                                        .font(.system(size: 17, weight: .bold))
                                    Text("unlock time")
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                                .foregroundColor(level.color)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(
                                    Capsule()
                                        .fill(level.color.opacity(0.12))
                                )
                            }
                        }
                        .opacity(appearAnimation ? 1.0 : 0.0)
                        .offset(y: appearAnimation ? 0 : 30)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: appearAnimation)
                        
                        // Info Cards Section
                        VStack(spacing: 16) {
                            // What this means
                            InfoCardLarge(
                                icon: "info.circle.fill",
                                title: "What this means",
                                content: level.description,
                                color: level.color,
                                delay: 0.1
                            )
                            
                            // How it works
                            InfoCardLarge(
                                icon: "sparkles",
                                title: "How it works",
                                content: "Complete 3 dhikr recitations to unlock your apps for \(level.displayDuration). When time expires, you'll receive gentle reminders to practice again.",
                                color: level.color,
                                delay: 0.15
                            )
                            
                            // Encouragement card with gradient
                            VStack(alignment: .leading, spacing: 14) {
                                HStack(spacing: 10) {
                                    ZStack {
                                        Circle()
                                            .fill(level.color.opacity(0.15))
                                            .frame(width: 36, height: 36)
                                        Image(systemName: "heart.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(level.color)
                                    }
                                    
                                    Text("Remember")
                                        .font(.system(size: 17, weight: .bold))
                                        .foregroundColor(AppTheme.textPrimary)
                                }
                                
                                Text(level.encouragement)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(AppTheme.textSecondary)
                                    .italic()
                                    .lineSpacing(5)
                            }
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                level.color.opacity(0.12),
                                                level.color.opacity(0.05)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(level.color.opacity(0.2), lineWidth: 1)
                            )
                            .opacity(appearAnimation ? 1.0 : 0.0)
                            .offset(y: appearAnimation ? 0 : 20)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.2), value: appearAnimation)
                        }
                        .padding(.horizontal, 20)
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.top, 10)
                }
                
                // Bottom Button - Fixed
                VStack(spacing: 0) {
                    Divider()
                        .background(AppTheme.muted.opacity(0.3))
                    
                    Button(action: {
                        HapticManager.shared.soft()
                        onDismiss()
                    }) {
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 20))
                            Text("Got it!")
                                .font(.system(size: 18, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                colors: [level.color, level.color.opacity(0.85)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: level.color.opacity(0.35), radius: 16, y: 8)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 24)
                }
                .background(AppTheme.background)
            }
        }
        .onAppear {
            withAnimation {
                appearAnimation = true
            }
        }
    }
}

// MARK: - Large Info Card Component

struct InfoCardLarge: View {
    let icon: String
    let title: String
    let content: String
    let color: Color
    let delay: Double
    
    @State private var appear = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(color)
                }
                
                Text(title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
            }
            
            Text(content)
                .font(.system(size: 16))
                .foregroundColor(AppTheme.textSecondary)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.card)
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppTheme.muted.opacity(0.3), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 10, y: 5)
        .opacity(appear ? 1.0 : 0.0)
        .offset(y: appear ? 0 : 20)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8).delay(delay)) {
                appear = true
            }
        }
    }
}

// Helper extension for custom corner radius
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    DifficultyLevelInfoView(level: .medium, onDismiss: {})
}
