//
//  SplashScreenView.swift
//  scrolldeeds
//
//  Splash: the sharp Nafsi portrait, then the name.
//

import SwiftUI

struct SplashScreenView: View {
    @State private var sparklesScale: CGFloat = 0.92
    @State private var sparklesOpacity: Double = 0
    
    @State private var titleOffset: CGFloat = 20
    @State private var titleOpacity: Double = 0
    
    @State private var subtitleOpacity: Double = 0
    
    @State private var isAnimationComplete = false
    
    var onComplete: () -> Void

    private var splashTextGradient: LinearGradient {
        LinearGradient(
            colors: [
                AppTheme.primaryLight,
                AppTheme.primary,
                Color(red: 0.20, green: 0.66, blue: 0.44)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                Image("NafsiMark")
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .frame(width: 168, height: 168)
                    .scaleEffect(sparklesScale)
                    .opacity(sparklesOpacity)

                Text(NSLocalizedString("splash.app_name", comment: "Nafsi"))
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(splashTextGradient)
                    .offset(y: titleOffset)
                    .opacity(titleOpacity)

                // Subtitle
                Text(NSLocalizedString("splash.subtitle", comment: "Built for Muslims who want more from life"))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppTheme.primary.opacity(0.72))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 24)
                    .opacity(subtitleOpacity)
                
                Spacer()
                
                // Loading indicator (subtle)
                LoadingSpinner(gradient: splashTextGradient)
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
        let gradient: LinearGradient
        @State private var isAnimating = false
        
        var body: some View {
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(gradient, style: StrokeStyle(lineWidth: 3, lineCap: .round))
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
        
        withAnimation(.spring(response: 0.8, dampingFraction: 0.82)) {
            sparklesScale = 1.0
            sparklesOpacity = 1.0
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                sparklesScale = 1.03
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

