//
//  RememberVaultDetailView.swift
//

import SwiftUI

struct RememberVaultDetailView: View {
    @ObservedObject var store: RememberVaultStore
    let itemId: UUID
    @Environment(\.dismiss) private var dismiss

    private var item: SavedRememberItem? {
        store.items.first { $0.id == itemId }
    }

    var body: some View {
        Group {
            if let item {
                content(item)
            } else {
                Text(NSLocalizedString("remember.not_found", comment: ""))
                    .foregroundColor(AppTheme.textSecondary)
            }
        }
        .navigationTitle(NSLocalizedString("remember.detail.title", comment: ""))
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func content(_ item: SavedRememberItem) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                HStack {
                    Text(item.category.rawValue)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppTheme.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(AppTheme.primary.opacity(0.12))
                        .clipShape(Capsule())

                    if item.isFridayKhutbahTag {
                        Text(NSLocalizedString("remember.tag.friday", comment: ""))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppTheme.accent)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(AppTheme.accent.opacity(0.15))
                            .clipShape(Capsule())
                    }

                    Spacer()

                    Button {
                        store.updateFavorite(id: item.id, isFavorite: !item.isFavorite)
                        HapticManager.shared.selection()
                    } label: {
                        Image(systemName: item.isFavorite ? "star.fill" : "star")
                            .font(.system(size: 22))
                            .foregroundColor(item.isFavorite ? AppTheme.accent : AppTheme.textMuted)
                    }
                }

                switch item.processingState {
                case .processing, .pending:
                    HStack(spacing: 10) {
                        SwiftUI.ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.primary))
                        Text(NSLocalizedString("remember.processing", comment: ""))
                            .font(.subheadline)
                            .foregroundColor(AppTheme.textSecondary)
                    }
                case .failed:
                    VStack(alignment: .leading, spacing: 8) {
                        Text(NSLocalizedString("remember.processing_failed", comment: ""))
                            .font(.subheadline)
                            .foregroundColor(AppTheme.error)
                        if let err = item.processingError {
                            Text(err)
                                .font(.caption)
                                .foregroundColor(AppTheme.textMuted)
                        }
                        Button(NSLocalizedString("remember.retry", comment: "")) {
                            store.retryProcessing(id: item.id)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppTheme.primary)
                    }
                case .ready:
                    EmptyView()
                }

                VStack(spacing: 12) {
                    Text(NSLocalizedString("remember.takeaway.label", comment: ""))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.textMuted)
                        .frame(maxWidth: .infinity)

                    Text(item.takeaway.isEmpty ? "—" : item.takeaway)
                        .font(.system(size: 20, weight: .semibold))
                        .multilineTextAlignment(.center)
                        .foregroundColor(AppTheme.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(NSLocalizedString("remember.summary", comment: ""))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(AppTheme.textPrimary)
                    Text(item.summary.isEmpty ? "—" : item.summary)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let t = item.transcript, !t.isEmpty {
                    DisclosureGroup(NSLocalizedString("remember.transcript", comment: "")) {
                        Text(t)
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .tint(AppTheme.primary)
                }

                Toggle(isOn: Binding(
                    get: { item.isFridayKhutbahTag },
                    set: { store.updateFridayTag(id: item.id, tagged: $0) }
                )) {
                    Text(NSLocalizedString("remember.tag.friday_toggle", comment: ""))
                        .font(.subheadline)
                }
                .tint(AppTheme.primary)

                if item.inputKind == .link, let url = URL(string: item.originalContent), url.scheme != nil {
                    Link(destination: url) {
                        Label(NSLocalizedString("remember.open_link", comment: ""), systemImage: "link")
                    }
                    .font(.subheadline)
                }

                Text(formattedDate(item.createdAt))
                    .font(.caption)
                    .foregroundColor(AppTheme.textMuted)
            }
            .padding(20)
        }
        .background(AppTheme.background)
    }

    private func formattedDate(_ d: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f.string(from: d)
    }
}
