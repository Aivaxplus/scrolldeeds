import SwiftUI
#if canImport(FamilyControls)
import FamilyControls
#endif
#if canImport(ManagedSettings)
import ManagedSettings
#endif

#if canImport(FamilyControls) && canImport(ManagedSettings)
@available(iOS 16.0, *)
struct LockedAppTile: View {
    let token: Token<Application>

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(AppTheme.muted)
                    .frame(width: 56, height: 56)
                Image(systemName: "app.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(AppTheme.primary)
                
                // Locked badge
                Circle()
                    .fill(AppTheme.error)
                    .frame(width: 18, height: 18)
                    .overlay(
                        Image(systemName: "lock.fill")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                    )
                    .offset(x: 20, y: -20)
            }
            
            Text("App")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(AppTheme.textPrimary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(AppTheme.muted)
        .cornerRadius(14)
    }
}
#else
struct LockedAppTile: View {
    let name: String
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 18)
                    .fill(AppTheme.muted)
                    .frame(width: 72, height: 72)
                Image(systemName: "lock.fill")
                    .font(.title2)
                    .foregroundStyle(AppTheme.primary)
            }
            Text(name)
                .font(.footnote)
                .foregroundStyle(.primary)
                .lineLimit(1)
            Text("Locked")
                .font(.caption2)
                .foregroundStyle(.red)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 16).fill(.background))
        .shadow(color: .black.opacity(0.05), radius: 6, y: 4)
    }
}
#endif


