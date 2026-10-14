//
//  SavedDiscoveryView.swift
//  scrolldeeds
//
//  Saved and liked discovery cards, opened from Settings.
//

import SwiftUI

struct SavedDiscoveryView: View {
    @ObservedObject private var store = DiscoveryProgressStore.shared
    @ObservedObject private var languageManager = LanguageManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var tab: CollectionTab = .saved
    @State private var sharePayload: String?

    private enum CollectionTab: String, CaseIterable {
        case saved
        case liked

        var title: String {
            switch self {
            case .saved:
                return NSLocalizedString("settings.saved.tab.saved", comment: "Saved")
            case .liked:
                return NSLocalizedString("settings.saved.tab.liked", comment: "Liked")
            }
        }
    }

    private var cards: [DiscoveryCard] {
        tab == .saved ? store.savedCards : store.likedCards
    }

    var body: some View {
        NavigationView {
            ZStack {
                SDPageBackground()
                VStack(spacing: 16) {
                    Picker("", selection: $tab) {
                        ForEach(CollectionTab.allCases, id: \.self) { item in
                            Text(item.title).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    if cards.isEmpty {
                        emptyState
                    } else {
                        cardList
                    }
                }
            }
            .navigationTitle(NSLocalizedString("settings.saved.title", comment: "Saved cards"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(NSLocalizedString("practice.done", comment: "Done")) {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.primary)
                }
            }
        }
        .id(languageManager.languageEpoch)
        .sheet(isPresented: Binding(
            get: { sharePayload != nil },
            set: { if !$0 { sharePayload = nil } }
        )) {
            ShareSheet(activityItems: [sharePayload ?? ""])
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: tab == .saved ? "bookmark" : "heart")
                .font(.system(size: 36, weight: .medium))
                .foregroundColor(AppTheme.primary)
            Text(tab == .saved
                 ? NSLocalizedString("settings.saved.empty.title", comment: "No saved cards yet")
                 : NSLocalizedString("settings.liked.empty.title", comment: "No liked cards yet"))
                .font(AppTypography.sectionTitle)
                .foregroundColor(AppTheme.textPrimary)
                .multilineTextAlignment(.center)
            Text(tab == .saved
                 ? NSLocalizedString("settings.saved.empty.body", comment: "Tap the bookmark while scrolling.")
                 : NSLocalizedString("settings.liked.empty.body", comment: "Tap the heart while scrolling."))
                .font(AppTypography.body)
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }

    private var cardList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 12) {
                ForEach(cards) { card in
                    savedRow(card)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 28)
        }
    }

    private func savedRow(_ card: DiscoveryCard) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(card.kind.label.uppercased())
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(1.1)
                .foregroundColor(AppTheme.primary)
            Text(card.title)
                .font(.system(size: 18, weight: .bold, design: .serif))
                .foregroundColor(AppTheme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Text(card.meaning)
                .font(AppTypography.body)
                .foregroundColor(AppTheme.textSecondary)
                .lineSpacing(3)
            Text(card.source)
                .font(AppTypography.caption)
                .foregroundColor(AppTheme.textMuted)
            HStack(spacing: 16) {
                Button {
                    sharePayload = shareText(for: card)
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel(NSLocalizedString("discovery.action.share", comment: "Share"))

                Spacer()

                if tab == .liked {
                    Button {
                        HapticManager.shared.soft()
                        store.toggleLike(card.id)
                    } label: {
                        Image(systemName: "heart.fill")
                            .foregroundColor(AppTheme.statusNegative)
                    }
                    .accessibilityLabel(NSLocalizedString("discovery.action.like", comment: "Like"))
                }

                Button {
                    HapticManager.shared.soft()
                    store.toggleSave(card.id)
                } label: {
                    Image(systemName: store.isSaved(card.id) ? "bookmark.fill" : "bookmark")
                        .foregroundColor(store.isSaved(card.id) ? AppTheme.primary : AppTheme.textPrimary)
                }
                .accessibilityLabel(NSLocalizedString("discovery.action.save", comment: "Save"))
            }
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(AppTheme.textPrimary)
            .padding(.top, 2)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .fill(AppTheme.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .stroke(AppTheme.border, lineWidth: 1)
        )
    }

    private func shareText(for card: DiscoveryCard) -> String {
        [
            card.title,
            "",
            card.meaning,
            "",
            card.source,
            "— ScrollDeeds"
        ].joined(separator: "\n")
    }
}
