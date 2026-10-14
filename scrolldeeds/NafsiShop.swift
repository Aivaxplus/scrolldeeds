//
//  NafsiShop.swift
//  scrolldeeds
//
//  Coin shop, the locker of things you own, and the frame Nafsi stands in.
//

import SwiftUI
import UIKit
import Combine

enum NafsiShopKind: String {
    case character
    case background
    case scrollScene
}

struct NafsiShopItem: Identifiable, Equatable {
    let id: String
    /// Empty for the plain frame with no picture behind Nafsi.
    let asset: String
    let nameKey: String
    let price: Int
    let kind: NafsiShopKind

    var isFree: Bool { price == 0 }
}

enum NafsiShopCatalog {
    static let defaultCharacter = "default"
    static let noBackground = "none"
    static let noScroll = "scroll_none"
    static let defaultScroll = "scroll_dome"

    static let all: [NafsiShopItem] = [
        NafsiShopItem(id: defaultCharacter, asset: "NafsiHeroCalm", nameKey: "shop.default", price: 0, kind: .character),
        NafsiShopItem(id: noBackground, asset: "", nameKey: "shop.none", price: 0, kind: .background),

        NafsiShopItem(id: "pose_read", asset: "NafsiShopPoseRead", nameKey: "shop.item.read", price: 360, kind: .character),
        NafsiShopItem(id: "pose_offer", asset: "NafsiShopPoseOffer", nameKey: "shop.item.offer", price: 400, kind: .character),
        NafsiShopItem(id: "pose_open", asset: "NafsiShopPoseOpen", nameKey: "shop.item.open", price: 320, kind: .character),
        NafsiShopItem(id: "pose_chest", asset: "NafsiShopPoseChest", nameKey: "shop.item.chest", price: 440, kind: .character),
        NafsiShopItem(id: "pose_walk", asset: "NafsiShopPoseWalk", nameKey: "shop.item.walk", price: 480, kind: .character),
        NafsiShopItem(id: "pose_reach", asset: "NafsiShopPoseReach", nameKey: "shop.item.reach", price: 520, kind: .character),
        NafsiShopItem(id: "pose_cross", asset: "NafsiShopPoseCross", nameKey: "shop.item.cross", price: 560, kind: .character),
        NafsiShopItem(id: "pose_sit", asset: "NafsiShopPoseSit", nameKey: "shop.item.sit", price: 280, kind: .character),
        NafsiShopItem(id: "pose_kneel", asset: "NafsiShopPoseKneel", nameKey: "shop.item.kneel", price: 640, kind: .character),
        NafsiShopItem(id: "pose_crouch", asset: "NafsiShopPoseCrouch", nameKey: "shop.item.crouch", price: 720, kind: .character),
        NafsiShopItem(id: "pose_heart", asset: "NafsiShopPoseHeart", nameKey: "shop.item.heart", price: 800, kind: .character),
        NafsiShopItem(id: "pose_lantern", asset: "NafsiShopPoseLantern", nameKey: "shop.item.lantern", price: 880, kind: .character),

        NafsiShopItem(id: "look_cream", asset: "NafsiShopLookCream", nameKey: "shop.item.cream", price: 960, kind: .character),
        NafsiShopItem(id: "look_gold", asset: "NafsiShopLookGold", nameKey: "shop.item.gold", price: 1200, kind: .character),
        NafsiShopItem(id: "look_silver", asset: "NafsiShopLookSilver", nameKey: "shop.item.silver", price: 1400, kind: .character),
        NafsiShopItem(id: "look_emerald", asset: "NafsiShopLookEmerald", nameKey: "shop.item.emerald", price: 1800, kind: .character),

        NafsiShopItem(id: "bg_dawn", asset: "NafsiShopBgDawn", nameKey: "shop.item.dawn", price: 240, kind: .background),
        NafsiShopItem(id: "bg_moon", asset: "NafsiShopBgMoon", nameKey: "shop.item.moon", price: 300, kind: .background),
        NafsiShopItem(id: "bg_olive", asset: "NafsiShopBgOlive", nameKey: "shop.item.olive", price: 360, kind: .background),
        NafsiShopItem(id: "bg_arch", asset: "NafsiShopBgArch", nameKey: "shop.item.arch", price: 420, kind: .background),
        NafsiShopItem(id: "bg_palms", asset: "NafsiShopBgPalms", nameKey: "shop.item.palms", price: 480, kind: .background),
        NafsiShopItem(id: "bg_mosque", asset: "NafsiShopBgMosque", nameKey: "shop.item.mosque", price: 540, kind: .background),
        NafsiShopItem(id: "bg_steps", asset: "NafsiShopBgSteps", nameKey: "shop.item.steps", price: 600, kind: .background),
        NafsiShopItem(id: "bg_night", asset: "NafsiShopBgNight", nameKey: "shop.item.night", price: 680, kind: .background),

        NafsiShopItem(id: noScroll, asset: "", nameKey: "shop.none", price: 0, kind: .scrollScene),
        NafsiShopItem(id: defaultScroll, asset: "ScrollBgDome", nameKey: "shop.item.dome", price: 0, kind: .scrollScene),
        NafsiShopItem(id: "scroll_minarets", asset: "ScrollBgMinarets", nameKey: "shop.item.minarets", price: 480, kind: .scrollScene),
        NafsiShopItem(id: "scroll_court", asset: "ScrollBgCourt", nameKey: "shop.item.court", price: 560, kind: .scrollScene),
        NafsiShopItem(id: "scroll_glass", asset: "ScrollBgGlass", nameKey: "shop.item.glass", price: 680, kind: .scrollScene),
        NafsiShopItem(id: "scroll_reflect", asset: "ScrollBgReflect", nameKey: "shop.item.reflect", price: 800, kind: .scrollScene),
        NafsiShopItem(id: "scroll_haram", asset: "ScrollBgHaram", nameKey: "shop.item.haram", price: 1100, kind: .scrollScene)
    ]

    static func item(_ id: String) -> NafsiShopItem? {
        all.first { $0.id == id }
    }

    static var paid: [NafsiShopItem] { all.filter { !$0.isFree } }

    static func paid(_ kind: NafsiShopKind) -> [NafsiShopItem] {
        paid.filter { $0.kind == kind }
    }
}

@MainActor
final class NafsiLocker: ObservableObject {
    static let shared = NafsiLocker()

    @Published private(set) var owned: Set<String>
    @Published private(set) var characterID: String
    @Published private(set) var backgroundID: String
    /// Full-screen picture behind the scroll feed. Separate from the Nafsi frame.
    @Published private(set) var scrollBackgroundID: String

    private let defaults = UserDefaults.standard
    private enum Keys {
        static let owned = "nafsiShop.owned"
        static let character = "nafsiShop.character"
        static let background = "nafsiShop.background"
        static let scroll = "nafsiShop.scrollBackground"
    }

    private init() {
        let stored = defaults.stringArray(forKey: Keys.owned) ?? []
        owned = Set(stored).union([
            NafsiShopCatalog.defaultCharacter,
            NafsiShopCatalog.noBackground,
            NafsiShopCatalog.noScroll,
            NafsiShopCatalog.defaultScroll
        ])
        characterID = defaults.string(forKey: Keys.character) ?? NafsiShopCatalog.defaultCharacter
        backgroundID = defaults.string(forKey: Keys.background) ?? NafsiShopCatalog.noBackground
        scrollBackgroundID = defaults.string(forKey: Keys.scroll) ?? NafsiShopCatalog.defaultScroll
        if !owned.contains(characterID) { characterID = NafsiShopCatalog.defaultCharacter }
        if !owned.contains(backgroundID) { backgroundID = NafsiShopCatalog.noBackground }
        // Old scroll picks were Nafsi-frame pictures. Those stay on the frame only.
        if NafsiShopCatalog.item(scrollBackgroundID)?.kind != .scrollScene {
            scrollBackgroundID = NafsiShopCatalog.defaultScroll
        }
        save()
    }

    var characterAsset: String {
        NafsiShopCatalog.item(characterID)?.asset ?? "NafsiHeroCalm"
    }

    var backgroundAsset: String? {
        guard let asset = NafsiShopCatalog.item(backgroundID)?.asset, !asset.isEmpty else { return nil }
        return asset
    }

    var scrollBackgroundAsset: String? {
        guard let asset = NafsiShopCatalog.item(scrollBackgroundID)?.asset, !asset.isEmpty else { return nil }
        return asset
    }

    /// True when the scroll picture is dark enough that ink should flip to white.
    var scrollUsesLightText: Bool {
        guard let name = scrollBackgroundAsset else { return false }
        return ScrollBackdropTone.prefersLightText(named: name)
    }

    func owns(_ id: String) -> Bool { owned.contains(id) }

    func isEquipped(_ item: NafsiShopItem) -> Bool {
        switch item.kind {
        case .character: return characterID == item.id
        case .background: return backgroundID == item.id
        case .scrollScene: return scrollBackgroundID == item.id
        }
    }

    func equip(_ item: NafsiShopItem) {
        guard owns(item.id) else { return }
        switch item.kind {
        case .character: characterID = item.id
        case .background: backgroundID = item.id
        case .scrollScene: scrollBackgroundID = item.id
        }
        save()
    }

    @discardableResult
    func buy(_ item: NafsiShopItem) -> Bool {
        if owns(item.id) {
            equip(item)
            return true
        }
        guard HeartJourneyManager.shared.spendCoins(item.price) else { return false }
        owned.insert(item.id)
        equip(item)
        save()
        return true
    }

    func ownedItems(_ kind: NafsiShopKind) -> [NafsiShopItem] {
        NafsiShopCatalog.all.filter { $0.kind == kind && owns($0.id) }
    }

    private func save() {
        defaults.set(Array(owned), forKey: Keys.owned)
        defaults.set(characterID, forKey: Keys.character)
        defaults.set(backgroundID, forKey: Keys.background)
        defaults.set(scrollBackgroundID, forKey: Keys.scroll)
    }
}

enum ScrollBackdropTone {
    private static var cache: [String: Bool] = [:]

    /// Center of the picture, where the card text sits. Below this, use white ink.
    static func prefersLightText(named name: String) -> Bool {
        if let cached = cache[name] { return cached }
        let dark = measuredLuminance(named: name).map { $0 < 0.58 } ?? false
        cache[name] = dark
        return dark
    }

    private static func measuredLuminance(named name: String) -> CGFloat? {
        guard let image = UIImage(named: name)?.cgImage else { return nil }
        let width = 16
        let height = 24
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        guard let context = CGContext(
            data: &pixels,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }
        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
        // Sample the middle band. The top and bottom of a scene can be much lighter.
        let start = height / 4
        let end = height - start
        var sum: CGFloat = 0
        var count: CGFloat = 0
        for y in start..<end {
            for x in 0..<width {
                let offset = (y * width + x) * 4
                let r = CGFloat(pixels[offset]) / 255
                let g = CGFloat(pixels[offset + 1]) / 255
                let b = CGFloat(pixels[offset + 2]) / 255
                sum += (0.2126 * r) + (0.7152 * g) + (0.0722 * b)
                count += 1
            }
        }
        guard count > 0 else { return nil }
        return sum / count
    }
}

// MARK: - Dashboard frame

/// Full-bleed picture behind the dashboard title and Nafsi. The lower edge
/// fades into the page so the scene is not a separate card.
struct NafsiSceneBackdrop: View {
    var backgroundName: String?

    var body: some View {
        frameFill
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .mask {
                LinearGradient(
                    stops: [
                        .init(color: .black, location: 0),
                        .init(color: .black, location: 0.78),
                        .init(color: .clear, location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
            .animation(.easeInOut(duration: 0.35), value: backgroundName)
            .allowsHitTesting(false)
    }

    @ViewBuilder
    private var frameFill: some View {
        if let backgroundName {
            Image(backgroundName)
                .resizable()
                .scaledToFill()
        } else {
            LinearGradient(
                colors: [
                    AppTheme.primary.opacity(0.10),
                    AppTheme.background.opacity(0.55),
                    AppTheme.background
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

// MARK: - Shop + locker

struct NafsiShopView: View {
    @ObservedObject private var locker = NafsiLocker.shared
    @ObservedObject private var journey = HeartJourneyManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var tab: ShopTab = .shop

    private enum ShopTab: String, CaseIterable {
        case shop
        case locker

        var titleKey: String {
            switch self {
            case .shop: return "shop.tab.shop"
            case .locker: return "shop.tab.locker"
            }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                SDPageBackground()

                VStack(spacing: 14) {
                    shopHeader

                    Picker("", selection: $tab) {
                        ForEach(ShopTab.allCases, id: \.self) { tab in
                            Text(NSLocalizedString(tab.titleKey, comment: "")).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 22) {
                            if tab == .shop {
                                section(NSLocalizedString("shop.section.poses", comment: ""), items: poseItems)
                                section(NSLocalizedString("shop.section.looks", comment: ""), items: lookItems)
                                section(NSLocalizedString("shop.section.frame", comment: ""), items: frameBackgroundItems)
                                section(NSLocalizedString("shop.section.scroll", comment: ""), items: scrollSceneItems)
                            } else {
                                section(NSLocalizedString("shop.section.nafsi", comment: ""), items: locker.ownedItems(.character))
                                section(NSLocalizedString("shop.section.frame", comment: ""), items: locker.ownedItems(.background))
                                section(NSLocalizedString("shop.section.scroll", comment: ""), items: locker.ownedItems(.scrollScene))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 28)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationBarHidden(true)
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    /// The system bar button squeezed the balance into “…”. A normal label keeps the full count.
    private var shopHeader: some View {
        ZStack {
            Text(NSLocalizedString("shop.title", comment: "Shop"))
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(AppTheme.primary)

            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    NafsiCoinGlyph(size: 16)
                    Text("\(journey.coins)")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)
                        .monospacedDigit()
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                }

                Spacer(minLength: 8)

                SDDismissButton { dismiss() }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
    }

    private var poseItems: [NafsiShopItem] {
        NafsiShopCatalog.paid(.character).filter { $0.id.hasPrefix("pose_") }
    }

    private var lookItems: [NafsiShopItem] {
        NafsiShopCatalog.paid(.character).filter { $0.id.hasPrefix("look_") }
    }

    private var frameBackgroundItems: [NafsiShopItem] {
        NafsiShopCatalog.all.filter { $0.kind == .background }
    }

    private var scrollSceneItems: [NafsiShopItem] {
        NafsiShopCatalog.all.filter { $0.kind == .scrollScene }
    }

    private func section(_ title: String, items: [NafsiShopItem]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)

            // A lazy grid measures each photo at its full size while scrolling,
            // then the list jumps to the bottom. Fixed rows keep the height stable.
            VStack(spacing: 12) {
                ForEach(shopRows(items)) { row in
                    HStack(alignment: .top, spacing: 12) {
                        shopTile(row.leading)
                        if let trailing = row.trailing {
                            shopTile(trailing)
                        } else {
                            Color.clear
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
        }
    }

    private struct ShopRow: Identifiable {
        let leading: NafsiShopItem
        let trailing: NafsiShopItem?
        var id: String { leading.id }
    }

    private func shopRows(_ items: [NafsiShopItem]) -> [ShopRow] {
        var rows: [ShopRow] = []
        var index = 0
        while index < items.count {
            let trailing = index + 1 < items.count ? items[index + 1] : nil
            rows.append(ShopRow(leading: items[index], trailing: trailing))
            index += 2
        }
        return rows
    }

    @ViewBuilder
    private func shopTile(_ item: NafsiShopItem) -> some View {
        if item.kind == .character {
            characterTile(item)
        } else {
            backgroundTile(item)
        }
    }

    private func characterTile(_ item: NafsiShopItem) -> some View {
        let owned = locker.owns(item.id)
        let equipped = locker.isEquipped(item)
        let canAfford = journey.coins >= item.price

        return Button {
            if owned {
                HapticManager.shared.soft()
                locker.equip(item)
            } else if locker.buy(item) {
                HapticManager.shared.success()
            } else {
                HapticManager.shared.error()
            }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                artworkWell(height: 132) {
                    if item.kind == .background, !item.asset.isEmpty {
                        Image(item.asset)
                            .resizable()
                            .scaledToFill()
                    } else if !item.asset.isEmpty {
                        Image(item.asset)
                            .resizable()
                            .scaledToFit()
                            .padding(8)
                    } else {
                        Image(systemName: "circle.dashed")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(AppTheme.textMuted)
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(equipped ? AppTheme.primary : Color.clear, lineWidth: 2)
                )

                Text(NSLocalizedString(item.nameKey, comment: ""))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(1)

                tileStatus(owned: owned, equipped: equipped, price: item.price, canAfford: canAfford)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(AppTheme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(AppTheme.border.opacity(0.6), lineWidth: 1)
            )
        }
        .buttonStyle(NafsiPressStyle())
    }

    private func artworkWell<Content: View>(height: CGFloat, @ViewBuilder content: () -> Content) -> some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color(red: 0.969, green: 0.953, blue: 0.918))
            .frame(height: height)
            .frame(maxWidth: .infinity)
            .overlay { content() }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    @ViewBuilder
    private func tileStatus(owned: Bool, equipped: Bool, price: Int, canAfford: Bool) -> some View {
        if equipped {
            Text(NSLocalizedString("shop.equipped", comment: "Wearing"))
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.primary)
        } else if owned {
            Text(NSLocalizedString("shop.wear", comment: "Wear"))
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.textSecondary)
        } else {
            HStack(spacing: 4) {
                NafsiCoinGlyph(size: 14)
                Text("\(price)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }
            .foregroundColor(canAfford ? AppTheme.textPrimary : AppTheme.textMuted)
        }
    }

    private func backgroundTile(_ item: NafsiShopItem) -> some View {
        let owned = locker.owns(item.id)
        let equipped = locker.isEquipped(item)
        let canAfford = journey.coins >= item.price

        return Button {
            if owned {
                HapticManager.shared.soft()
                locker.equip(item)
            } else if locker.buy(item) {
                HapticManager.shared.success()
            } else {
                HapticManager.shared.error()
            }
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                artworkWell(height: 168) {
                    if item.asset.isEmpty {
                        Image(systemName: "circle.dashed")
                            .font(.system(size: 28, weight: .medium))
                            .foregroundColor(AppTheme.textMuted)
                    } else {
                        Image(item.asset)
                            .resizable()
                            .scaledToFill()
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(equipped ? AppTheme.primary : Color.clear, lineWidth: 2)
                )

                Text(NSLocalizedString(item.nameKey, comment: ""))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(1)

                tileStatus(owned: owned, equipped: equipped, price: item.price, canAfford: canAfford)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(AppTheme.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(AppTheme.border.opacity(0.6), lineWidth: 1)
            )
        }
        .buttonStyle(NafsiPressStyle())
    }
}
