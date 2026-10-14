//
//  DiscoveryCardView.swift
//  scrolldeeds
//
//  Home feed: full-screen Islamic cards (sunnah, ayah, adab, hadith, fact).
//  Swipe vertically. Like, share, save — vocabulary-app chrome, ScrollDeeds type.
//

import SwiftUI
import UIKit

struct KnowledgeFeedView: View {
    @ObservedObject private var store = DiscoveryProgressStore.shared
    @ObservedObject private var languageManager = LanguageManager.shared
    @ObservedObject private var locker = NafsiLocker.shared
    @State private var currentID: String? = DiscoveryProgressStore.shared.lastCardID
    @State private var sharePayload: String?
    @State private var infoCard: DiscoveryCard?

    private var cards: [DiscoveryCard] { store.orderedCards }

    var body: some View {
        feedStack
            .id(languageManager.currentLanguage)
            .onAppear(perform: handleAppear)
            .onChange(of: currentID) { id in
                if let id {
                    store.markSeen(id)
                }
                store.extendPlayOrderIfNeeded(currentID: id)
            }
            .sheet(isPresented: isSharePresented) {
                ShareSheet(activityItems: [sharePayload ?? ""])
            }
            .alert(
                infoCard?.kind.label ?? "",
                isPresented: isInfoPresented
            ) {
                Button(NSLocalizedString("discovery.ok", comment: "OK"), role: .cancel) {}
            } message: {
                Text(infoCard?.source ?? "")
            }
    }

    private var isSharePresented: Binding<Bool> {
        Binding(
            get: { sharePayload != nil },
            set: { if !$0 { sharePayload = nil } }
        )
    }

    private var isInfoPresented: Binding<Bool> {
        Binding(
            get: { infoCard != nil },
            set: { if !$0 { infoCard = nil } }
        )
    }

    private var onDarkScroll: Bool { locker.scrollUsesLightText }

    private var feedStack: some View {
        pagingFeed
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var pagingFeed: some View {
        VerticalCardPager(
            cards: cards,
            currentID: $currentID,
            page: cardPage(for:),
            extraCards: { alreadyHave, lastID in
                DiscoveryProgressStore.shared.extraCards(alreadyHave: alreadyHave, avoiding: lastID)
            }
        )
    }

    private func cardPage(for card: DiscoveryCard) -> KnowledgeCardPage {
        KnowledgeCardPage(
            card: card,
            onDark: onDarkScroll,
            overPhoto: locker.scrollBackgroundAsset != nil,
            isLiked: store.isLiked(card.id),
            isSaved: store.isSaved(card.id),
            onInfo: { infoCard = card },
            onShare: { sharePayload = shareText(for: card) },
            onLike: { toggleLike(card.id) },
            onSave: { toggleSave(card.id) }
        )
    }

    private func handleAppear() {
        if currentID == nil || DiscoveryCatalog.card(id: currentID ?? "") == nil {
            currentID = store.restoreCardID()
        }
        if let id = currentID {
            store.markSeen(id)
        }
        store.extendPlayOrderIfNeeded(currentID: currentID)
    }

    private func toggleLike(_ id: String) {
        HapticManager.shared.soft()
        store.toggleLike(id)
    }

    private func toggleSave(_ id: String) {
        HapticManager.shared.soft()
        store.toggleSave(id)
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

struct KnowledgeCardPage: View {
    let card: DiscoveryCard
    var onDark: Bool = false
    /// A shop photo sits behind the card, so the copy needs a calm plate.
    var overPhoto: Bool = false
    let isLiked: Bool
    let isSaved: Bool
    let onInfo: () -> Void
    let onShare: () -> Void
    let onLike: () -> Void
    let onSave: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 12)
            NafsiBuddyView(pose: card.feedBuddyPose, height: overPhoto ? 128 : 108)
                .padding(.bottom, 4)
            cardCopy
            actionBar
                .padding(.top, overPhoto ? 22 : 18)
            Spacer(minLength: 12)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { quoteScrim }
    }

    /// Light ink on a photo. On a plain page the original dark ink stays.
    private var onPhoto: Bool { overPhoto }

    private var cardCopy: some View {
        VStack(spacing: 12) {
            Text(card.kind.label.uppercased())
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .tracking(1.8)
                .foregroundColor(onPhoto ? Color.white.opacity(0.78) : AppTheme.primary)

            Text(card.title)
                .font(.system(size: 23, weight: .semibold, design: .serif))
                .foregroundColor(onPhoto ? .white : (onDark ? .white : AppTheme.textPrimary))
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .lineLimit(4)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)

            Text(card.meaning)
                .font(.system(size: 15, weight: .regular, design: .serif))
                .foregroundColor(onPhoto ? Color.white.opacity(0.92) : (onDark ? Color.white.opacity(0.92) : AppTheme.textSecondary))
                .multilineTextAlignment(.center)
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)

            Text("— \(card.source)")
                .font(.system(size: 13, weight: .medium, design: .serif))
                .foregroundColor(onPhoto ? Color.white.opacity(0.74) : (onDark ? Color.white.opacity(0.75) : AppTheme.textMuted))
                .multilineTextAlignment(.center)
                .padding(.top, 2)
        }
        .frame(maxWidth: 300)
        .frame(maxWidth: .infinity)
        .shadow(color: .black.opacity(onPhoto ? 0.4 : 0), radius: 3, y: 1)
    }

    /// A soft dark band behind the words so they stay readable. It has no edge.
    @ViewBuilder
    private var quoteScrim: some View {
        if overPhoto {
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black.opacity(0.04), location: 0.16),
                    .init(color: .black.opacity(0.26), location: 0.34),
                    .init(color: .black.opacity(0.26), location: 0.56),
                    .init(color: .black.opacity(0.06), location: 0.72),
                    .init(color: .clear, location: 0.86)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .allowsHitTesting(false)
        }
    }

    private var actionBar: some View {
        HStack(spacing: 36) {
            feedAction(
                systemName: "info.circle",
                label: NSLocalizedString("discovery.action.info", comment: "Info"),
                tint: actionTint,
                action: onInfo
            )
            feedAction(
                systemName: "square.and.arrow.up",
                label: NSLocalizedString("discovery.action.share", comment: "Share"),
                tint: actionTint,
                action: onShare
            )
            feedAction(
                systemName: isLiked ? "heart.fill" : "heart",
                label: NSLocalizedString("discovery.action.like", comment: "Like"),
                tint: isLiked && !onPhoto ? AppTheme.statusNegative : actionTint,
                action: onLike
            )
            feedAction(
                systemName: isSaved ? "bookmark.fill" : "bookmark",
                label: NSLocalizedString("discovery.action.save", comment: "Save"),
                tint: isSaved && !onPhoto ? AppTheme.primary : actionTint,
                action: onSave
            )
        }
    }

    private var actionTint: Color {
        onPhoto || onDark ? .white : AppTheme.textPrimary
    }

    private func feedAction(
        systemName: String,
        label: String,
        tint: Color = AppTheme.textPrimary,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 22, weight: .light))
                .foregroundColor(tint)
                .frame(width: 44, height: 44)
                .shadow(color: .black.opacity(onPhoto ? 0.35 : 0), radius: 6, y: 1)
        }
        .accessibilityLabel(label)
    }
}

private struct VerticalCardPager: UIViewControllerRepresentable {
    let cards: [DiscoveryCard]
    @Binding var currentID: String?
    let page: (DiscoveryCard) -> KnowledgeCardPage
    var extraCards: (Int, String?) -> [DiscoveryCard] = { _, _ in [] }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIViewController(context: Context) -> UIPageViewController {
        let controller = UIPageViewController(
            transitionStyle: .scroll,
            navigationOrientation: .vertical
        )
        controller.dataSource = context.coordinator
        controller.delegate = context.coordinator
        controller.view.backgroundColor = .clear
        controller.view.clipsToBounds = true
        tunePager(controller)
        context.coordinator.currentID = $currentID
        context.coordinator.page = page
        context.coordinator.extraCards = extraCards
        _ = context.coordinator.reload(cards: cards, page: page)
        if let start = context.coordinator.host(for: currentID) ?? context.coordinator.hosts.first {
            controller.setViewControllers([start], direction: .forward, animated: false)
        }
        return controller
    }

    func updateUIViewController(_ controller: UIPageViewController, context: Context) {
        context.coordinator.currentID = $currentID
        context.coordinator.page = page
        context.coordinator.extraCards = extraCards
        controller.view.backgroundColor = .clear
        controller.view.clipsToBounds = true
        tunePager(controller)
        let rebuilt = context.coordinator.reload(cards: cards, page: page)
        if rebuilt || controller.viewControllers?.isEmpty != false,
           let host = context.coordinator.host(for: currentID) ?? context.coordinator.hosts.first {
            controller.setViewControllers([host], direction: .forward, animated: false)
        }
    }

    private func tunePager(_ controller: UIPageViewController) {
        let pageSize = controller.view.bounds.size
        controller.view.subviews.forEach { subview in
            subview.backgroundColor = .clear
            guard let scroll = subview as? UIScrollView else { return }
            scroll.backgroundColor = .clear
            scroll.clipsToBounds = true
            scroll.contentInsetAdjustmentBehavior = .never
            scroll.contentInset = .zero
            scroll.verticalScrollIndicatorInsets = .zero
        }
        guard pageSize.height > 1 else { return }
        let scrolling = controller.view.subviews.contains { subview in
            guard let scroll = subview as? UIScrollView else { return false }
            return scroll.isDragging || scroll.isDecelerating
        }
        guard !scrolling else { return }
        controller.viewControllers?.forEach { page in
            if page.view.bounds.size != pageSize {
                page.view.frame.size = pageSize
            }
        }
    }

    final class Coordinator: NSObject, UIPageViewControllerDataSource, UIPageViewControllerDelegate {
        var currentID: Binding<String?> = .constant(nil)
        var cards: [DiscoveryCard] = []
        var hosts: [UIHostingController<KnowledgeCardPage>] = []
        var page: (DiscoveryCard) -> KnowledgeCardPage = { card in
            KnowledgeCardPage(
                card: card,
                isLiked: false,
                isSaved: false,
                onInfo: {},
                onShare: {},
                onLike: {},
                onSave: {}
            )
        }
        var extraCards: (Int, String?) -> [DiscoveryCard] = { _, _ in [] }

        func reload(cards: [DiscoveryCard], page: @escaping (DiscoveryCard) -> KnowledgeCardPage) -> Bool {
            let oldIDs = self.cards.map(\.id)
            let newIDs = cards.map(\.id)
            self.page = page
            if oldIDs == newIDs && hosts.count == cards.count {
                self.cards = cards
                for (index, card) in cards.enumerated() {
                    hosts[index].rootView = page(card)
                }
                return false
            }
            if !oldIDs.isEmpty, newIDs.starts(with: oldIDs) {
                let added = Array(cards.dropFirst(oldIDs.count))
                self.cards = cards
                appendHosts(added)
                return false
            }
            self.cards = cards
            hosts = cards.map { makeHost(for: $0) }
            return true
        }

        private func makeHost(for card: DiscoveryCard) -> UIHostingController<KnowledgeCardPage> {
            let host = UIHostingController(rootView: page(card))
            host.view.backgroundColor = .clear
            host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            host.view.insetsLayoutMarginsFromSafeArea = false
            if #available(iOS 16.4, *) {
                host.safeAreaRegions = []
            }
            if #available(iOS 16.0, *) {
                host.sizingOptions = []
            }
            return host
        }

        private func appendHosts(_ newCards: [DiscoveryCard]) {
            guard !newCards.isEmpty else { return }
            hosts.append(contentsOf: newCards.map { makeHost(for: $0) })
        }

        func host(for id: String?) -> UIHostingController<KnowledgeCardPage>? {
            guard let id, let index = cards.firstIndex(where: { $0.id == id }) else { return nil }
            return hosts[index]
        }

        func visibleID(in controller: UIPageViewController) -> String? {
            guard let visible = controller.viewControllers?.first,
                  let index = hosts.firstIndex(where: { $0 === visible }) else { return nil }
            return cards[index].id
        }

        func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerBefore viewController: UIViewController
        ) -> UIViewController? {
            guard let index = hosts.firstIndex(where: { $0 === viewController }), index > 0 else {
                return nil
            }
            return hosts[index - 1]
        }

        func pageViewController(
            _ pageViewController: UIPageViewController,
            viewControllerAfter viewController: UIViewController
        ) -> UIViewController? {
            guard let index = hosts.firstIndex(where: { $0 === viewController }) else {
                return nil
            }
            if index + 1 < hosts.count {
                return hosts[index + 1]
            }
            let more = extraCards(cards.count, cards.last?.id)
            guard !more.isEmpty else { return nil }
            cards.append(contentsOf: more)
            appendHosts(more)
            guard index + 1 < hosts.count else { return nil }
            return hosts[index + 1]
        }

        func pageViewController(
            _ pageViewController: UIPageViewController,
            didFinishAnimating finished: Bool,
            previousViewControllers: [UIViewController],
            transitionCompleted completed: Bool
        ) {
            guard completed else { return }
            currentID.wrappedValue = visibleID(in: pageViewController)
        }
    }
}

/// The Scroll scene, from the top of the screen through to the tab bar.
struct ScrollSceneBackdrop: View {
    @ObservedObject private var locker = NafsiLocker.shared

    var body: some View {
        ZStack {
            if let asset = locker.scrollBackgroundAsset {
                Image(asset)
                    .resizable()
                    .scaledToFill()
                if locker.scrollUsesLightText {
                    Color.black.opacity(0.28)
                }
            } else {
                SDPageBackground()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

#Preview {
    ZStack {
        ScrollSceneBackdrop()
        KnowledgeFeedView()
    }
}
