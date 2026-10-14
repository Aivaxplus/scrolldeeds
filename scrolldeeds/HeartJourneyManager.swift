import Foundation
import Combine

/// Long-term heart path: XP from deeds fills a bar; a full bar upgrades the heart.
@MainActor
final class HeartJourneyManager: ObservableObject {
    static let shared = HeartJourneyManager()

    static let welcomeBonusXP = 50
    static let deedXP = 20

    @Published private(set) var totalXP: Int
    /// Spendable coins (good deeds earn them; buying hearts spends them).
    /// This balance — not lifetime XP — drives the rank so spending is visible.
    @Published private(set) var coins: Int
    @Published private(set) var rank: HeartRank
    @Published var isPlayingWelcome = false
    @Published private(set) var welcomePhase: HeartWelcomePhase = .idle
    /// Last coin change, for the floating +/- animation on the wallet card.
    @Published private(set) var lastCoinChange: CoinChange?

    private let defaults = UserDefaults.standard
    private enum Keys {
        static let totalXP = "heartJourney.totalXP"
        static let coins = "heartJourney.coins"
        static let welcomeGranted = "heartJourney.welcomeGranted"
        static let welcomePopupSeen = "heartJourney.welcomePopupSeen"
        static let pendingDeedCoins = "heartJourney.pendingDeedCoins"
    }

    /// Coins earned by the deed just finished, waiting to fly into the pill.
    var pendingDeedCoins: Int { max(0, defaults.integer(forKey: Keys.pendingDeedCoins)) }

    func stageDeedCoins(_ amount: Int) {
        let value = max(0, amount)
        guard value > 0 else { return }
        defaults.set(value, forKey: Keys.pendingDeedCoins)
    }

    func clearPendingDeedCoins() {
        defaults.removeObject(forKey: Keys.pendingDeedCoins)
    }

    /// Credits the staged deed reward once, when the flying coins reach the pill.
    @discardableResult
    func claimPendingDeedCoins() -> Int {
        let amount = pendingDeedCoins
        guard amount > 0 else { return 0 }
        defaults.removeObject(forKey: Keys.pendingDeedCoins)
        addXP(amount)
        return amount
    }

    var hasGrantedWelcome: Bool {
        defaults.bool(forKey: Keys.welcomeGranted)
    }

    var shouldPlayWelcome: Bool { !hasGrantedWelcome }

    /// Coin balance needed to leave the current rank.
    var nextRankAt: Int { rank.nextThreshold(totalXP: coins) }

    /// Coins still needed for the next rank — moves up again when you spend.
    var coinsToNextRank: Int { max(0, nextRankAt - coins) }

    var visualStage: HeartVisualStage { HeartVisualStage.from(xp: coins) }

    /// 0...1 inside the current rank. Hitting 1.0 promotes immediately.
    var fillProgress: Double {
        HeartRank.fillProgress(xp: coins)
    }

    var deedsIntoRank: Int {
        HeartRank.deedsIntoRank(xp: coins)
    }

    private init() {
        var stored = max(0, defaults.integer(forKey: Keys.totalXP))
        // Repair: bonus was granted but the bar reset to 0 after the rank-up.
        if defaults.bool(forKey: Keys.welcomeGranted), stored == 0 {
            stored = Self.welcomeBonusXP
            defaults.set(stored, forKey: Keys.totalXP)
        }
        totalXP = stored

        let storedCoins: Int
        if defaults.object(forKey: Keys.coins) == nil {
            storedCoins = stored
            defaults.set(stored, forKey: Keys.coins)
        } else {
            storedCoins = max(0, defaults.integer(forKey: Keys.coins))
        }
        coins = storedCoins
        rank = HeartRank.from(xp: storedCoins)
    }

    func beginWelcomeIfNeeded() -> Bool {
        guard shouldPlayWelcome, !isPlayingWelcome else { return false }
        // Show the gift first. Coins land in the pill only when the user collects.
        isPlayingWelcome = true
        welcomePhase = .popup
        return true
    }

    func collectWelcomeBonus() {
        guard isPlayingWelcome, !hasGrantedWelcome else { return }
        welcomePhase = .collecting
        totalXP = max(0, totalXP) + Self.welcomeBonusXP
        defaults.set(totalXP, forKey: Keys.totalXP)
        creditCoins(Self.welcomeBonusXP)
        defaults.set(true, forKey: Keys.welcomeGranted)
    }

    func endWelcome() {
        defaults.set(true, forKey: Keys.welcomePopupSeen)
        isPlayingWelcome = false
        welcomePhase = .idle
    }

    @discardableResult
    func addDeedXP() -> Bool {
        addXP(Self.deedXP)
    }

    @discardableResult
    func addXP(_ amount: Int) -> Bool {
        let previous = rank
        let gain = max(0, amount)
        totalXP = max(0, totalXP + gain)
        defaults.set(totalXP, forKey: Keys.totalXP)
        creditCoins(gain)
        return rank > previous
    }

    /// Spends waiting to float off the header pill once the shop or heart sheet closes.
    private var pillSpendQueue: [Int] = []
    @Published private(set) var pillSpendFlash: CoinChange?

    @discardableResult
    func spendCoins(_ amount: Int) -> Bool {
        let cost = max(0, amount)
        guard coins >= cost else { return false }
        setCoins(coins - cost, delta: -cost)
        if cost > 0 { pillSpendQueue.append(cost) }
        return true
    }

    /// Plays each queued spend on the header pill, one after another.
    func presentQueuedSpends() {
        let amounts = pillSpendQueue
        pillSpendQueue.removeAll()
        guard !amounts.isEmpty else { return }
        playPillSpends(amounts)
    }

    private func playPillSpends(_ amounts: [Int]) {
        guard let first = amounts.first else {
            pillSpendFlash = nil
            return
        }
        pillSpendFlash = CoinChange(amount: -first)
        let rest = Array(amounts.dropFirst())
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.72) { [weak self] in
            self?.playPillSpends(rest)
        }
    }

    private func creditCoins(_ amount: Int) {
        guard amount > 0 else { return }
        setCoins(coins + amount, delta: amount)
    }

    private func setCoins(_ value: Int, delta: Int) {
        coins = max(0, value)
        defaults.set(coins, forKey: Keys.coins)
        rank = HeartRank.from(xp: coins)
        if delta != 0 {
            lastCoinChange = CoinChange(amount: delta)
        }
    }
}

/// One coin credit or debit — `id` makes every change animate, even repeats.
struct CoinChange: Identifiable, Equatable {
    let id = UUID()
    let amount: Int
}

enum HeartWelcomePhase: Equatable {
    case idle
    case popup
    case collecting
}

enum HeartRank: Int, Comparable {
    case spark = 0
    case bronze = 1
    case silver = 2
    case gold = 3
    case diamond = 4
    case emerald = 5

    static func < (lhs: HeartRank, rhs: HeartRank) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// Unlocks needed to finish this rank's bar (bronze is after the welcome gift).
    var deedsRequired: Int {
        switch self {
        case .spark: return 0
        case .bronze: return 3
        case .silver: return 6
        case .gold: return 9
        case .diamond: return 12
        case .emerald: return 15
        }
    }

    /// XP width of this rank's bar (bronze includes the welcome gift).
    var xpSpan: Int {
        switch self {
        case .spark:
            return HeartJourneyManager.welcomeBonusXP
        case .bronze:
            return HeartJourneyManager.welcomeBonusXP
                + deedsRequired * HeartJourneyManager.deedXP
        default:
            return deedsRequired * HeartJourneyManager.deedXP
        }
    }

    /// Silver starts when bronze bar is complete.
    static var silverStart: Int { HeartRank.bronze.xpSpan }
    static var goldStart: Int { silverStart + HeartRank.silver.xpSpan }
    static var diamondStart: Int { goldStart + HeartRank.gold.xpSpan }
    static var emeraldStart: Int { diamondStart + HeartRank.diamond.xpSpan }

    /// A full bar promotes immediately (`>=` threshold).
    static func from(xp: Int) -> HeartRank {
        if xp >= emeraldStart { return .emerald }
        if xp >= diamondStart { return .diamond }
        if xp >= goldStart { return .gold }
        if xp >= silverStart { return .silver }
        if xp > 0 { return .bronze }
        return .spark
    }

    func startXP(totalXP: Int) -> Int {
        switch self {
        case .spark: return 0
        case .bronze: return 0
        case .silver: return Self.silverStart
        case .gold: return Self.goldStart
        case .diamond: return Self.diamondStart
        case .emerald:
            let floor = Self.emeraldStart
            let span = xpSpan
            guard span > 0 else { return floor }
            let extra = max(0, totalXP - floor)
            return floor + (extra / span) * span
        }
    }

    func nextThreshold(totalXP: Int) -> Int {
        startXP(totalXP: totalXP) + xpSpan
    }

    static func fillProgress(xp: Int) -> Double {
        let rank = from(xp: xp)
        let start = Double(rank.startXP(totalXP: xp))
        let next = Double(rank.nextThreshold(totalXP: xp))
        guard next > start else { return 1 }
        return min(1, max(0, (Double(xp) - start) / (next - start)))
    }

    /// Dots: unlocks after welcome (bronze), or deeds inside later ranks.
    static func deedsIntoRank(xp: Int) -> Int {
        let rank = from(xp: xp)
        if rank == .spark { return 0 }
        let start: Int
        switch rank {
        case .bronze:
            start = HeartJourneyManager.welcomeBonusXP
        default:
            start = rank.startXP(totalXP: xp)
        }
        return min(
            rank.deedsRequired,
            max(0, (xp - start) / HeartJourneyManager.deedXP)
        )
    }

    var localizationKey: String {
        switch self {
        case .spark: return "heart.rank.spark"
        case .bronze: return "heart.rank.bronze"
        case .silver: return "heart.rank.silver"
        case .gold: return "heart.rank.gold"
        case .diamond: return "heart.rank.diamond"
        case .emerald: return "heart.rank.emerald"
        }
    }
}

/// Visual fill of the heart inside a rank: one image per unlock step.
enum HeartVisualStage: Equatable {
    case spark
    case filling(HeartRank, piece: Int)

    var imageName: String {
        switch self {
        case .spark:
            return "HeartWeak"
        case .filling(let rank, let piece):
            let metal: String
            switch rank {
            case .spark: return "HeartWeak"
            case .bronze: metal = "Bronze"
            case .silver: metal = "Silver"
            case .gold: metal = "Gold"
            case .diamond: metal = "Diamond"
            case .emerald:
                // No emerald heart art; the Nafsi hero draws its own heart.
                return "HeartDiamond\(min(piece, HeartRank.diamond.deedsRequired))"
            }
            return "Heart\(metal)\(piece)"
        }
    }

    var piece: Int {
        switch self {
        case .spark: return 0
        case .filling(_, let piece): return piece
        }
    }

    static func from(xp: Int) -> HeartVisualStage {
        let rank = HeartRank.from(xp: xp)
        guard rank != .spark else { return .spark }
        let deeds = HeartRank.deedsIntoRank(xp: xp)
        // deeds 0 → step 1 … last unlock before promote → full step count
        let step = min(rank.deedsRequired, max(1, deeds + 1))
        return .filling(rank, piece: step)
    }

    static func step(forFill fill: Double, rank: HeartRank) -> Int {
        let n = max(1, rank.deedsRequired)
        let stepped = Int((min(1, max(0, fill)) * Double(n)).rounded(.up))
        return min(n, max(1, stepped))
    }
}
