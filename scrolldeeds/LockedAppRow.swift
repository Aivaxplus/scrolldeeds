//
//  LockedAppRow.swift
//  scrolldeeds
//
//  Beautiful row component for locked apps with animations
//

import SwiftUI

#if canImport(FamilyControls)
import FamilyControls
#endif

struct LockedAppRow: View {
    let index: Int
    let isLocked: Bool
    
    // App icon options (since we can't get real icons)
    private let appIcons = [
        "iphone.gen3.circle.fill",
        "app.fill",
        "square.stack.3d.up.fill",
        "rectangle.stack.fill",
        "square.grid.2x2.fill",
        "circle.grid.3x3.fill",
        "square.grid.3x2.fill",
        "rectangle.grid.1x2.fill"
    ]
    
    private let appColors: [Color] = [
        Color(red: 0.2, green: 0.7, blue: 0.9),  // Blue
        Color(red: 0.9, green: 0.3, blue: 0.5),  // Pink
        Color(red: 0.3, green: 0.8, blue: 0.5),  // Green
        Color(red: 0.9, green: 0.6, blue: 0.2),  // Orange
        Color(red: 0.6, green: 0.4, blue: 0.9),  // Purple
        Color(red: 0.2, green: 0.6, blue: 0.8),  // Teal
        Color(red: 0.9, green: 0.5, blue: 0.3),  // Coral
        Color(red: 0.4, green: 0.7, blue: 0.3)   // Lime
    ]
    
    var body: some View {
        HStack(spacing: 16) {
            // App icon placeholder with color
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                appColors[index % appColors.count],
                                appColors[index % appColors.count].opacity(0.7)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 52, height: 52)
                    .shadow(color: appColors[index % appColors.count].opacity(0.3), radius: 8, y: 4)
                
                Image(systemName: appIcons[index % appIcons.count])
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
            }
            
            // App info
            VStack(alignment: .leading, spacing: 4) {
                Text("App \(index + 1)")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                
                Text(isLocked ? "Locked" : "Unlocked")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            Spacer()
            
            // Lock status indicator with animation
            ZStack {
                Circle()
                    .fill(isLocked ? AppTheme.error.opacity(0.12) : AppTheme.success.opacity(0.12))
                    .frame(width: 36, height: 36)
                
                Image(systemName: isLocked ? "lock.fill" : "lock.open.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isLocked ? AppTheme.error : AppTheme.success)
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isLocked)
        }
        .padding(16)
        .background(AppTheme.background.opacity(0.5))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    isLocked ? 
                        AppTheme.error.opacity(0.2) : 
                        AppTheme.success.opacity(0.2),
                    lineWidth: 1.5
                )
        )
        .shadow(
            color: isLocked ? 
                AppTheme.error.opacity(0.08) : 
                AppTheme.success.opacity(0.08),
            radius: 10,
            y: 4
        )
    }
}

#Preview {
    VStack(spacing: 12) {
        // Preview with locked state
        LockedAppRow(
            index: 0,
            isLocked: true
        )
        
        // Preview with unlocked state
        LockedAppRow(
            index: 1,
            isLocked: false
        )
        
        // More examples
        LockedAppRow(
            index: 2,
            isLocked: true
        )
    }
    .padding()
    .background(AppTheme.background)
}

