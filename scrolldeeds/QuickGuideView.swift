//
//  QuickGuideView.swift
//  scrolldeeds
//
//  Quick guide/tutorial for new users
//

import SwiftUI

struct QuickGuideView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentPage: Int = 0
    
    let onComplete: () -> Void
    
    private let pages: [GuidePage] = [
        GuidePage(
            icon: "lock.shield.fill",
            title: "How It Works",
            subtitle: "Your apps are locked by default",
            description: "The apps you selected are now locked. You'll need to complete a spiritual practice to unlock them.",
            color: .red
        ),
        GuidePage(
            icon: "sparkles",
            title: "Unlock with Dhikr",
            subtitle: "Recite dhikr 3 times",
            description: "Tap 'Unlock Apps with Dhikr', record yourself reciting Alhamdulillah, Astaghfirullah, Allahu Akbar, or Subhanallah 3 times. Our AI will verify it.",
            color: .green
        ),
        GuidePage(
            icon: "clock.fill",
            title: "Unlock Duration",
            subtitle: "Use your apps mindfully",
            description: "After verification, you get access based on your chosen difficulty level. When time runs out, ScrollDeeds keeps sending alarms until you relock. Use every minute intentionally.",
            color: .orange
        ),
        GuidePage(
            icon: "chart.line.uptrend.xyaxis",
            title: "Track Your Progress",
            subtitle: "Build better habits",
            description: "Check your progress anytime to see your improvement. Build streaks and reduce mindless scrolling!",
            color: .blue
        )
    ]
    
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button(action: handleComplete) {
                        Text("Skip")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppTheme.primary)
                    }
                    .padding(.trailing, 24)
                    .padding(.top, 20)
                }
                
                // Content
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { index in
                        pageView(for: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                
                // Bottom section
                VStack(spacing: 24) {
                    // Page indicator
                    HStack(spacing: 8) {
                        ForEach(pages.indices, id: \.self) { index in
                            Circle()
                                .fill(currentPage == index ? AppTheme.primary : AppTheme.textMuted.opacity(0.3))
                                .frame(width: currentPage == index ? 10 : 8, height: currentPage == index ? 10 : 8)
                                .animation(.spring(response: 0.3), value: currentPage)
                        }
                    }
                    
                    // Next/Get Started button
                    Button(action: handleNext) {
                        Text(currentPage == pages.count - 1 ? "Get Started" : "Next")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 40)
            }
        }
    }
    
    private func pageView(for page: GuidePage) -> some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                getColor(for: page.color).opacity(0.2),
                                getColor(for: page.color).opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                
                Image(systemName: page.icon)
                    .font(.system(size: 64, weight: .semibold))
                    .foregroundColor(getColor(for: page.color))
            }
            .shadow(color: getColor(for: page.color).opacity(0.3), radius: 30, y: 15)
            
            // Content
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(page.subtitle)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(getColor(for: page.color))
                    .multilineTextAlignment(.center)
                
                Text(page.description)
                    .font(.system(size: 16))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
            Spacer()
        }
    }
    
    private func getColor(for color: Color) -> Color {
        switch color {
        case .red: return AppTheme.error
        case .green: return AppTheme.primary
        case .orange: return AppTheme.accent
        case .blue: return AppTheme.primary
        default: return AppTheme.primary
        }
    }
    
    private func handleNext() {
        if currentPage < pages.count - 1 {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                currentPage += 1
            }
        } else {
            handleComplete()
        }
    }
    
    private func handleComplete() {
        // Mark guide as seen locally
        LocalStorageManager.shared.hasSeenQuickGuide = true
        onComplete()
        dismiss()
    }
}

struct GuidePage {
    let icon: String
    let title: String
    let subtitle: String
    let description: String
    let color: Color
}

#Preview {
    QuickGuideView(onComplete: {})
}

