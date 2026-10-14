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
    
    private var appAccent: Color {
        index.isMultiple(of: 2) ? AppTheme.primary : AppTheme.accent
    }
    
    var body: some View {
        HStack(spacing: 16) {
            SDIconBadge(
                systemName: appIcons[index % appIcons.count],
                size: 52,
                iconSize: 22,
                color: appAccent
            )
            
            // App info
            VStack(alignment: .leading, spacing: 4) {
                Text(String(format: NSLocalizedString("locked_app.app_number", comment: "App %d"), index + 1))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                
                Text(isLocked ? NSLocalizedString("dashboard.locked", comment: "Locked") : NSLocalizedString("dashboard.unlocked", comment: "Unlocked"))
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
        .padding(AppSpacing.md)
        .background(AppTheme.cardSecondary.opacity(0.58))
        .cornerRadius(AppRadius.md)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .stroke(
                    isLocked ? 
                        AppTheme.error.opacity(0.2) : 
                        AppTheme.success.opacity(0.2),
                    lineWidth: 1
                )
        )
        .shadow(
            color: Color.black.opacity(0.035),
            radius: 8,
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

