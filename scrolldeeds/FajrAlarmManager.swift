import Foundation
import Combine
import UIKit
import UserNotifications
import Vision
import AVFoundation

/// Local Fajr alarm: rings until the user photographs the enrolled object.
@MainActor
final class FajrAlarmManager: ObservableObject {
    static let shared = FajrAlarmManager()
    nonisolated static let notificationId = "nafsi.fajr.alarm"
    nonisolated static let snoozeNotificationId = "nafsi.fajr.snooze"
    /// One-minute retries after Fajr when the alarm is dismissed or ignored. Five rings total, then it stops.
    nonisolated static let maxRings = 5
    nonisolated static let burstOffsets = [1, 2, 3, 4]
    /// 30-second alarm tone; iOS caps notification sounds at 30 seconds.
    nonisolated static let alarmSoundFile = "fajr_alarm.caf"
    nonisolated static func burstId(_ index: Int) -> String { "nafsi.fajr.alarm.burst.\(index)" }
    nonisolated static var allNotificationIds: [String] {
        [notificationId, snoozeNotificationId] + burstOffsets.indices.map { burstId($0) }
    }
    nonisolated static func isFajrNotification(_ identifier: String) -> Bool {
        identifier.hasPrefix("nafsi.fajr.")
    }
    /// If the alarm is stopped or ignored without a verified photo, it rings again after this delay.
    private let retryMinutes = 1

    @Published var isEnabled: Bool
    @Published var fajrTime: Date
    @Published var isRinging = false
    @Published var hasReferencePhoto: Bool
    @Published var lastMatchFailed = false
    @Published var didSucceedThisRing = false
    @Published var isCheckingMatch = false
    @Published var selectedObject: FajrWakeObject?
    @Published private(set) var systemAlarmStatus: FajrSystemAlarmStatus = FajrAlarmKitBridge.status()

    var isArmed: Bool { isEnabled && selectedObject != nil }

    var objectName: String {
        selectedObject?.localizedName
            ?? NSLocalizedString("fajr.object.fallback", comment: "object")
    }

    private let defaults = UserDefaults.standard
    private enum Keys {
        static let enabled = "fajrAlarm.enabled"
        static let hour = "fajrAlarm.hour"
        static let minute = "fajrAlarm.minute"
        static let dismissedDay = "fajrAlarm.dismissedDay"
        static let snoozeUntil = "fajrAlarm.snoozeUntil"
        static let object = "fajrAlarm.object"
        static let ringDay = "fajrAlarm.ringDay"
        static let ringCount = "fajrAlarm.ringCount"
    }

    private var player: AVAudioPlayer?
    private var keepAlivePlayer: AVAudioPlayer?
    private var keepAliveTimer: Timer?
    /// Stops the same ring from being counted twice (alert observer + stop button).
    private var lastNotedRingAt: Date?
    private var giveUpTask: Task<Void, Never>?

    private var photoURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("fajr-reference.jpg")
    }

    private init() {
        isEnabled = defaults.bool(forKey: Keys.enabled)
        var comps = DateComponents()
        comps.hour = defaults.object(forKey: Keys.hour) as? Int ?? 5
        comps.minute = defaults.object(forKey: Keys.minute) as? Int ?? 15
        fajrTime = Calendar.current.date(from: comps) ?? Date()
        let photoPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("fajr-reference.jpg")
        hasReferencePhoto = FileManager.default.fileExists(atPath: photoPath.path)
        if let raw = defaults.string(forKey: Keys.object) {
            selectedObject = FajrWakeObject(rawValue: raw)
        }
        if isEnabled, selectedObject == nil {
            isEnabled = false
            defaults.set(false, forKey: Keys.enabled)
        }
        if isArmed {
            scheduleNotification()
        }
        FajrAlarmKitBridge.startObserving()
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main
        ) { _ in
            Task { @MainActor in
                let fajr = FajrAlarmManager.shared
                if fajr.isRinging, !fajr.didSucceedThisRing, fajr.systemAlarmStatus != .systemAlarm {
                    fajr.scheduleRetriesAfterIgnore()
                }
                fajr.startKeepAliveIfNeeded()
            }
        }
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main
        ) { _ in
            Task { @MainActor in
                let fajr = FajrAlarmManager.shared
                fajr.stopKeepAlive()
                fajr.refreshSystemAlarmStatus()
                if fajr.isRinging {
                    fajr.cancelPendingRetries()
                } else if fajr.isArmed {
                    fajr.refreshIgnoreRetriesIfNeeded()
                }
            }
        }
    }

    // MARK: - System alarm status

    func refreshSystemAlarmStatus() {
        systemAlarmStatus = FajrAlarmKitBridge.status()
    }

    func requestSystemAlarmPermission() {
        Task { @MainActor in
            systemAlarmStatus = await FajrAlarmKitBridge.requestPermission()
            if isArmed { scheduleNotification() }
        }
    }

    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - Pre-iOS 26 fallback

    /// Without AlarmKit, iOS won't wake a suspended app. While the alarm is armed, Nafsi keeps
    /// itself alive with a silent audio loop so it can ring at full volume (also on silent)
    /// at Fajr. Only works if the app was not swiped away; notifications cover that case.
    private func startKeepAliveIfNeeded() {
        guard isArmed, systemAlarmStatus != .systemAlarm, !isRinging,
              let fire = nextFireDate(), fire.timeIntervalSinceNow < 16 * 3600 else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch { return }
        keepAlivePlayer = try? AVAudioPlayer(data: Self.silentTone())
        keepAlivePlayer?.numberOfLoops = -1
        keepAlivePlayer?.volume = 0
        keepAlivePlayer?.play()

        keepAliveTimer?.invalidate()
        let timer = Timer(fire: fire, interval: 0, repeats: false) { _ in
            Task { @MainActor in
                FajrAlarmManager.shared.stopKeepAlive()
                FajrAlarmManager.shared.beginRinging(force: true)
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        keepAliveTimer = timer
    }

    private func stopKeepAlive() {
        keepAliveTimer?.invalidate()
        keepAliveTimer = nil
        keepAlivePlayer?.stop()
        keepAlivePlayer = nil
    }

    private func nextFireDate() -> Date? {
        let cal = Calendar.current
        let comps = cal.dateComponents([.hour, .minute], from: fajrTime)
        guard let today = cal.date(bySettingHour: comps.hour ?? 5, minute: comps.minute ?? 15, second: 0, of: Date()) else {
            return nil
        }
        if today > Date(), !wasDismissedToday { return today }
        return cal.date(byAdding: .day, value: 1, to: today)
    }

    func setSelectedObject(_ object: FajrWakeObject) {
        let changed = selectedObject != object
        selectedObject = object
        defaults.set(object.rawValue, forKey: Keys.object)
        guard changed else { return }
        if hasReferencePhoto {
            try? FileManager.default.removeItem(at: photoURL)
            hasReferencePhoto = false
        }
        if isArmed {
            scheduleNotification()
        }
    }

    func setEnabled(_ on: Bool) {
        guard !on || selectedObject != nil else { return }
        // Premium gate: never arm Fajr without an active trial/subscription.
        if on && !SubscriptionManager.shared.hasPremiumAccess {
            debugPrint("⛔️ Fajr enable blocked — no premium access")
            return
        }
        isEnabled = on
        defaults.set(on, forKey: Keys.enabled)
        if on {
            NotificationManager.shared.requestAuthorization()
            scheduleNotification()
        } else {
            cancelNotification()
            stopRinging()
        }
    }

    /// Turns Fajr off when trial/sub ends so it cannot keep ringing for free.
    func enforcePremiumAccess(_ hasAccess: Bool) {
        guard !hasAccess, isEnabled else { return }
        debugPrint("🔒 Fajr disarmed — premium access ended")
        setEnabled(false)
    }

    func setFajrTime(_ date: Date) {
        fajrTime = date
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        defaults.set(comps.hour ?? 5, forKey: Keys.hour)
        defaults.set(comps.minute ?? 15, forKey: Keys.minute)
        if isArmed {
            scheduleNotification()
        }
    }

    @discardableResult
    func saveReferencePhoto(_ image: UIImage) -> Bool {
        guard let data = image.jpegData(compressionQuality: 0.82) else { return false }
        do {
            try data.write(to: photoURL, options: .atomic)
            hasReferencePhoto = true
            if isEnabled {
                scheduleNotification()
            }
            return true
        } catch {
            return false
        }
    }

    func referenceImage() -> UIImage? {
        UIImage(contentsOfFile: photoURL.path)
    }

    /// `armFollowUp` is unused. Retries are armed only when the user dismisses or ignores the alarm.
    func beginRinging(force: Bool = false, armFollowUp _: Bool = true) {
        guard isArmed else { return }
        if wasDismissedToday { return }
        if !force, isSnoozed { return }
        if ringCount >= Self.maxRings {
            giveUpForToday()
            return
        }
        defaults.removeObject(forKey: Keys.snoozeUntil)
        noteRingIfNeeded()
        cancelPendingNotificationRetries()
        let wasRinging = isRinging
        isRinging = true
        lastMatchFailed = false
        didSucceedThisRing = false
        if !wasRinging || player?.isPlaying != true {
            startSound()
        }
        if ringCount >= Self.maxRings {
            scheduleGiveUpAfterLastRing()
        }
    }

    func handleNotification(identifier: String) {
        guard Self.isFajrNotification(identifier) else { return }
        defaults.removeObject(forKey: Keys.snoozeUntil)
        beginRinging(force: true)
    }

    /// Stop on the system alarm, the in-app X, or a dismissed notification.
    /// Rings again in one minute, at most five times, then stops for the day.
    func dismissWithoutPhoto() {
        guard isArmed else {
            stopRinging()
            return
        }
        if wasDismissedToday {
            stopRinging()
            cancelPendingRetries()
            return
        }
        noteRingIfNeeded()
        giveUpTask?.cancel()
        stopRinging()
        guard ringCount < Self.maxRings else {
            giveUpForToday()
            return
        }
        scheduleRetriesAfterIgnore()
    }

    func systemAlarmStopped() {
        dismissWithoutPhoto()
    }

    /// Called when the ringing screen is left in the background without a photo.
    func scheduleRetriesAfterIgnore() {
        guard isArmed, !wasDismissedToday, !didSucceedThisRing else { return }
        guard ringCount < Self.maxRings else {
            giveUpForToday()
            return
        }
        let remaining = min(Self.maxRings - ringCount, Self.burstOffsets.count)
        guard remaining > 0 else {
            giveUpForToday()
            return
        }
        cancelPendingRetries()
        if systemAlarmStatus == .systemAlarm {
            scheduleFollowUp(minutes: retryMinutes)
            return
        }
        let center = UNUserNotificationCenter.current()
        let content = fajrNotificationContent()
        for index in 0..<remaining {
            let seconds = TimeInterval((index + 1) * retryMinutes * 60)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
            let request = UNNotificationRequest(
                identifier: Self.burstId(index),
                content: content,
                trigger: trigger
            )
            center.add(request)
        }
    }

    func cancelPendingRetries() {
        giveUpTask?.cancel()
        cancelFollowUp()
        cancelPendingNotificationRetries()
    }

    private func cancelPendingNotificationRetries() {
        let burstIds = Self.burstOffsets.indices.map { Self.burstId($0) }
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: burstIds + [Self.snoozeNotificationId]
        )
    }

    func refreshIgnoreRetriesIfNeeded() {
        guard isArmed else { return }
        if wasDismissedToday || ringCount >= Self.maxRings {
            cancelPendingRetries()
            return
        }
        guard systemAlarmStatus != .systemAlarm, ringCount == 0 else { return }
        scheduleLegacyBurstsIfNeeded()
    }

    private func scheduleFollowUp(minutes: Int) {
        let fireDate = Date().addingTimeInterval(TimeInterval(minutes * 60))
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [Self.snoozeNotificationId])
        Task { @MainActor in
            if await FajrAlarmKitBridge.scheduleFollowUp(at: fireDate) { return }
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(minutes * 60), repeats: false)
            let request = UNNotificationRequest(
                identifier: Self.snoozeNotificationId,
                content: self.fajrNotificationContent(),
                trigger: trigger
            )
            try? await UNUserNotificationCenter.current().add(request)
        }
    }

    private func cancelFollowUp() {
        FajrAlarmKitBridge.cancelFollowUp()
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [Self.snoozeNotificationId])
    }

    func stopRinging() {
        isRinging = false
        lastMatchFailed = false
        didSucceedThisRing = false
        player?.stop()
        player = nil
    }

    func snoozeFiveMinutes() {
        guard isArmed, !wasDismissedToday else { return }
        isRinging = false
        lastMatchFailed = false
        didSucceedThisRing = false
        player?.stop()
        player = nil
        let until = Date().addingTimeInterval(5 * 60)
        defaults.set(until.timeIntervalSince1970, forKey: Keys.snoozeUntil)
        cancelPendingNotificationRetries()
        scheduleFollowUp(minutes: 5)
    }

    func tryDismiss(with photo: UIImage) {
        isCheckingMatch = true
        lastMatchFailed = false
        let object = objectName
        let wakeObject = selectedObject
        let reference = referenceImage()
        Task {
            var verdict: Bool?
            if let reference {
                verdict = await FajrAIVerifier.matches(capture: photo, reference: reference, objectName: object)
            } else {
                verdict = await FajrAIVerifier.matchesObject(capture: photo, objectName: object)
            }
            if verdict == nil, let wakeObject {
                verdict = FajrObjectClassifier.photo(photo, shows: wakeObject)
            }
            let ok = verdict ?? false
            await MainActor.run {
                self.finishDismiss(ok)
            }
        }
    }

    private func finishDismiss(_ ok: Bool) {
        isCheckingMatch = false
        if ok {
            markDismissedToday()
            defaults.removeObject(forKey: Keys.snoozeUntil)
            cancelPendingRetries()
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: Self.allNotificationIds)
            didSucceedThisRing = true
            player?.stop()
            player = nil
            HapticManager.shared.success()
            FajrAlarmKitBridge.stopAlertingThenReschedule(from: fajrTime)
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 1_600_000_000)
                self.stopRinging()
            }
        } else {
            lastMatchFailed = true
            HapticManager.shared.medium()
        }
    }

    func checkIfShouldRingOnForeground() {
        guard isArmed, !wasDismissedToday else { return }
        if isSnoozed { return }
        let cal = Calendar.current
        let now = Date()
        var fajr = cal.dateComponents([.hour, .minute], from: fajrTime)
        fajr.year = cal.component(.year, from: now)
        fajr.month = cal.component(.month, from: now)
        fajr.day = cal.component(.day, from: now)
        guard let fire = cal.date(from: fajr) else { return }
        let elapsed = now.timeIntervalSince(fire)
        // Notifications can ring without bumping ringCount. Opening the app a
        // few minutes later must still start the in-app alarm, not mark the day done.
        let morningWindow: TimeInterval = 2 * 60 * 60
        guard elapsed >= 0 else { return }
        if elapsed >= morningWindow || ringCount >= Self.maxRings {
            giveUpForToday()
            return
        }
        if ringCount == 0 {
            beginRinging()
        }
    }

    func scheduleNotification() {
        cancelNotification()
        guard isArmed else { return }
        guard SubscriptionManager.shared.hasPremiumAccess else {
            debugPrint("⛔️ Fajr schedule blocked — no premium access")
            return
        }

        let content = fajrNotificationContent()
        var comps = Calendar.current.dateComponents([.hour, .minute], from: fajrTime)
        comps.second = 0
        let fallbackContent = content
        let fallbackComps = comps

        Task { @MainActor in
            let usedAlarmKit = await FajrAlarmKitBridge.schedule(from: self.fajrTime)
            self.systemAlarmStatus = FajrAlarmKitBridge.status()
            guard !usedAlarmKit else { return }
            let center = UNUserNotificationCenter.current()
            let trigger = UNCalendarNotificationTrigger(dateMatching: fallbackComps, repeats: true)
            try? await center.add(
                UNNotificationRequest(identifier: Self.notificationId, content: fallbackContent, trigger: trigger)
            )
            if !self.wasDismissedToday, self.ringCount == 0 {
                self.scheduleLegacyBursts(content: fallbackContent, hourMinute: fallbackComps)
            }
        }
    }

    private func scheduleLegacyBurstsIfNeeded() {
        guard systemAlarmStatus != .systemAlarm, isArmed, !wasDismissedToday, ringCount == 0 else { return }
        scheduleLegacyBursts(
            content: fajrNotificationContent(),
            hourMinute: Calendar.current.dateComponents([.hour, .minute], from: fajrTime)
        )
    }

    private func scheduleLegacyBursts(content: UNNotificationContent, hourMinute: DateComponents) {
        let center = UNUserNotificationCenter.current()
        for (index, offset) in Self.burstOffsets.enumerated() {
            guard let base = Calendar.current.date(from: hourMinute),
                  let later = Calendar.current.date(byAdding: .minute, value: offset, to: base) else { continue }
            var comps = Calendar.current.dateComponents([.hour, .minute], from: later)
            comps.second = 0
            let burstTrigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
            center.add(
                UNNotificationRequest(identifier: Self.burstId(index), content: content, trigger: burstTrigger)
            )
        }
    }

    func cancelNotification() {
        FajrAlarmKitBridge.cancel()
        FajrAlarmKitBridge.cancelFollowUp()
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: Self.allNotificationIds)
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: Self.allNotificationIds)
    }

    func fajrNotificationContent() -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = NSLocalizedString("fajr.notification.title", comment: "Fajr")
        content.body = String(
            format: NSLocalizedString("fajr.notification.body", comment: "Open Nafsi and photograph your %@ to stop the alarm."),
            objectName
        )
        content.sound = Bundle.main.url(forResource: Self.alarmSoundFile, withExtension: nil) != nil
            ? UNNotificationSound(named: UNNotificationSoundName(Self.alarmSoundFile))
            : .default
        content.categoryIdentifier = "FAJR_ALARM"
        content.userInfo = ["fajr_alarm": true]
        content.interruptionLevel = .timeSensitive
        return content
    }

    var timeLabel: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: fajrTime)
    }

    private var isSnoozed: Bool {
        let until = defaults.double(forKey: Keys.snoozeUntil)
        guard until > 0 else { return false }
        return Date().timeIntervalSince1970 < until
    }

    private var ringCount: Int {
        guard defaults.string(forKey: Keys.ringDay) == Self.dayStamp() else { return 0 }
        return defaults.integer(forKey: Keys.ringCount)
    }

    private func noteRingIfNeeded() {
        let day = Self.dayStamp()
        if defaults.string(forKey: Keys.ringDay) != day {
            defaults.set(day, forKey: Keys.ringDay)
            defaults.set(0, forKey: Keys.ringCount)
            lastNotedRingAt = nil
        }
        if let lastNotedRingAt, Date().timeIntervalSince(lastNotedRingAt) < 50 { return }
        lastNotedRingAt = Date()
        defaults.set(ringCount + 1, forKey: Keys.ringCount)
    }

    private func scheduleGiveUpAfterLastRing() {
        giveUpTask?.cancel()
        giveUpTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            guard !Task.isCancelled, !self.didSucceedThisRing, self.ringCount >= Self.maxRings else { return }
            self.giveUpForToday()
        }
    }

    private func giveUpForToday() {
        giveUpTask?.cancel()
        markDismissedToday()
        defaults.removeObject(forKey: Keys.snoozeUntil)
        cancelPendingRetries()
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: Self.allNotificationIds)
        stopRinging()
        if systemAlarmStatus == .systemAlarm {
            FajrAlarmKitBridge.stopAlertingThenReschedule(from: fajrTime)
        }
    }

    private var wasDismissedToday: Bool {
        let day = defaults.string(forKey: Keys.dismissedDay)
        return day == Self.dayStamp()
    }

    private func markDismissedToday() {
        defaults.set(Self.dayStamp(), forKey: Keys.dismissedDay)
    }

    private static func dayStamp() -> String {
        let f = DateFormatter()
        f.calendar = Calendar.current
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    private func startSound() {
        #if targetEnvironment(simulator)
        return
        #else
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {}
        if let url = Bundle.main.url(forResource: Self.alarmSoundFile, withExtension: nil) {
            player = try? AVAudioPlayer(contentsOf: url)
        }
        if player == nil {
            player = try? AVAudioPlayer(data: Self.synthesizedAlarmTone())
        }
        player?.numberOfLoops = -1
        player?.volume = 1
        player?.play()
        #endif
    }

    private static func silentTone() -> Data {
        wavData([Int16](repeating: 0, count: 44_100), sampleRate: 44_100)
    }

    /// One-second two-tone beep pattern as 16-bit mono WAV, looped by the player.
    private static func synthesizedAlarmTone() -> Data {
        let sampleRate = 44_100
        let totalSamples = sampleRate
        var samples = [Int16](repeating: 0, count: totalSamples)
        let beeps: [(start: Double, length: Double, frequency: Double)] = [
            (0.00, 0.16, 880), (0.22, 0.16, 1175), (0.44, 0.16, 880)
        ]
        for beep in beeps {
            let start = Int(beep.start * Double(sampleRate))
            let count = Int(beep.length * Double(sampleRate))
            for i in 0..<count where start + i < totalSamples {
                let t = Double(i) / Double(sampleRate)
                let envelope = min(1, Double(i) / 400, Double(count - i) / 400)
                samples[start + i] = Int16(sin(2 * .pi * beep.frequency * t) * 30_000 * envelope)
            }
        }
        return wavData(samples, sampleRate: sampleRate)
    }

    private static func wavData(_ samples: [Int16], sampleRate: Int) -> Data {
        let totalSamples = samples.count
        var data = Data()
        func append<T: FixedWidthInteger>(_ value: T) {
            withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) }
        }
        let byteCount = UInt32(totalSamples * 2)
        data.append(contentsOf: Array("RIFF".utf8)); append(UInt32(36) + byteCount)
        data.append(contentsOf: Array("WAVEfmt ".utf8)); append(UInt32(16)); append(UInt16(1)); append(UInt16(1))
        append(UInt32(sampleRate)); append(UInt32(sampleRate * 2)); append(UInt16(2)); append(UInt16(16))
        data.append(contentsOf: Array("data".utf8)); append(byteCount)
        samples.forEach { append($0) }
        return data
    }
}

/// On-device check used when the AI verifier is unavailable (no key or no network).
enum FajrObjectClassifier {
    private static let rejectLabels = ["people", "person", "adult", "child", "face", "screen", "monitor", "display", "television"]

    static func photo(_ image: UIImage, shows object: FajrWakeObject) -> Bool {
        guard let cg = image.cgImage else { return false }
        let request = VNClassifyImageRequest()
        let handler = VNImageRequestHandler(cgImage: cg, orientation: cgOrientation(image.imageOrientation))
        guard (try? handler.perform([request])) != nil,
              let results = request.results else { return false }
        let labels = results
            .filter { $0.confidence >= 0.08 }
            .map { $0.identifier.lowercased() }
        guard !labels.isEmpty else { return false }
        if let top = labels.first, rejectLabels.contains(where: { top.contains($0) }) {
            return false
        }
        let keywords = keywords(for: object)
        if keywords.isEmpty { return false }
        return labels.contains { label in keywords.contains { label.contains($0) } }
    }

    private static func keywords(for object: FajrWakeObject) -> [String] {
        switch object {
        case .tap: return ["faucet", "tap", "sink", "bathroom", "kitchen", "plumbing", "water"]
        case .sandal: return ["sandal", "shoe", "footwear", "slipper", "flip", "sneaker", "boot"]
        case .rug: return ["rug", "carpet", "mat", "textile", "fabric", "tapestry"]
        case .desk: return ["desk", "table", "computer", "laptop", "keyboard", "office", "furniture"]
        case .door: return ["door", "doorway", "entrance", "gate", "handle"]
        case .light: return ["switch", "outlet", "socket", "electric", "light", "lamp", "wall"]
        case .miswak: return ["stick", "twig", "wood", "branch", "toothbrush", "root"]
        case .other: return []
        }
    }

    private static func cgOrientation(_ orientation: UIImage.Orientation) -> CGImagePropertyOrientation {
        switch orientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }
}

enum FajrWakeObject: String, CaseIterable, Identifiable, Equatable {
    case tap
    case sandal
    case rug
    case desk
    case door
    case light
    case miswak
    case other

    var id: String { rawValue }

    var symbolName: String {
        switch self {
        case .tap: return "drop.fill"
        case .sandal: return "figure.walk"
        case .rug: return "square.grid.3x3.fill"
        case .desk: return "laptopcomputer"
        case .door: return "door.left.hand.closed"
        case .light: return "lightbulb.fill"
        case .miswak: return "leaf.fill"
        case .other: return "cube.fill"
        }
    }

    var localizedName: String {
        NSLocalizedString("fajr.object.\(rawValue)", comment: rawValue)
    }
}
