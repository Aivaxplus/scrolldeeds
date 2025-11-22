//
//  SplashScreenView.swift
//  scrolldeeds
//
//  Beautiful animated splash screen with sparkles icon and ScrollDeeds branding
//

import SwiftUI

struct SplashScreenView: View {
    @State private var sparklesScale: CGFloat = 0.5
    @State private var sparklesOpacity: Double = 0
    @State private var sparklesRotation: Double = -10
    
    @State private var titleOffset: CGFloat = 20
    @State private var titleOpacity: Double = 0
    
    @State private var subtitleOpacity: Double = 0
    
    @State private var isAnimationComplete = false
    
    var onComplete: () -> Void
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(hex: "1a472a"),  // Dark green
                    Color(hex: "0f2818")   // Darker green
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                // Sparkles icon
                Image(systemName: "sparkles")
                    .font(.system(size: 80, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, Color(hex: "d4af37")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .scaleEffect(sparklesScale)
                    .opacity(sparklesOpacity)
                    .rotationEffect(.degrees(sparklesRotation))
                    .shadow(color: Color(hex: "d4af37").opacity(0.5), radius: 20, x: 0, y: 10)
                
                // App name
                Text("ScrollDeeds")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.white, Color(hex: "d4af37")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(y: titleOffset)
                    .opacity(titleOpacity)
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                
                // Subtitle
                Text("Break free from doomscrolling")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .opacity(subtitleOpacity)
                
                Spacer()
                
                // Loading indicator (subtle)
                LoadingSpinner()
                    .scaleEffect(0.8)
                    .opacity(subtitleOpacity)
                    .padding(.bottom, 50)
            }
            .padding()
        }
        .onAppear {
            startAnimations()
        }
    }
    
    // Custom loading spinner to avoid conflict with ProgressView
    private struct LoadingSpinner: View {
        @State private var isAnimating = false
        
        var body: some View {
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(Color.white, lineWidth: 3)
                .frame(width: 20, height: 20)
                .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
                .onAppear {
                    withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                        isAnimating = true
                    }
                }
        }
    }
    
    private func startAnimations() {
        debugPrint("✨ SPLASH SCREEN: Starting animations...")
        
        // Sparkles animation
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
            sparklesScale = 1.0
            sparklesOpacity = 1.0
            sparklesRotation = 0
        }
        
        // Title animation (delayed)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                titleOffset = 0
                titleOpacity = 1.0
            }
        }
        
        // Subtitle animation (delayed)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeIn(duration: 0.5)) {
                subtitleOpacity = 1.0
            }
        }
        
        // Add a subtle continuous sparkle animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                sparklesScale = 1.1
            }
        }
        
        // Complete animation and dismiss after 2.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 0.4)) {
                sparklesOpacity = 0
                titleOpacity = 0
                subtitleOpacity = 0
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                debugPrint("✨ SPLASH SCREEN: Animation complete, calling onComplete()")
                onComplete()
            }
        }
    }
}

// Helper extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    SplashScreenView {
        debugPrint("Splash screen complete!")
    }
}

