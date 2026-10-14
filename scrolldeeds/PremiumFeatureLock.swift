//
//  PremiumFeatureLock.swift
//  scrolldeeds
//
//  Small corner lock for premium cards after trial / without an active sub.
//

import SwiftUI

struct PremiumFeatureLockBadge: View {
    var body: some View {
        Image(systemName: "lock.fill")
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.white)
            .padding(6)
            .background(
                Circle()
                    .fill(AppTheme.textPrimary.opacity(0.88))
            )
            .shadow(color: Color.black.opacity(0.14), radius: 3, y: 1)
            .accessibilityLabel(NSLocalizedString("premium.lock.a11y", comment: "Requires Premium"))
    }
}

extension View {
    /// Tiny lock in the top-trailing corner of a card when `locked` is true.
    func premiumLockedCorner(_ locked: Bool, padding: CGFloat = 8) -> some View {
        overlay(alignment: .topTrailing) {
            if locked {
                PremiumFeatureLockBadge()
                    .padding(padding)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }
}
