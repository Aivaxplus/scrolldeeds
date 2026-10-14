import Foundation
import SwiftUI
#if canImport(AlarmKit)
import AlarmKit
#endif
#if canImport(ActivityKit)
import ActivityKit
#endif
#if canImport(AppIntents)
import AppIntents
#endif

/// Bridges Fajr onto Apple's AlarmKit (iOS 26+): rings through silent mode and Focus,
/// like a Clock alarm. Older iOS keeps using a local notification.
enum FajrSystemAlarmStatus: Equatable {
    /// Scheduled as a real AlarmKit alarm.
    case systemAlarm
    /// iOS 26+, permission not asked yet.
    case needsPermission
    /// iOS 26+, the user turned Alarms off for Nafsi.
    case denied
    /// Before iOS 26: notifications + Nafsi keeping itself awake in the background.
    case legacy
}

enum FajrAlarmKitBridge {
    static func status() -> FajrSystemAlarmStatus {
        guard #available(iOS 26.0, *) else { return .legacy }
        #if canImport(AlarmKit)
        switch AlarmManager.shared.authorizationState {
        case .authorized: return .systemAlarm
        case .denied: return .denied
        default: return .needsPermission
        }
        #else
        return .legacy
        #endif
    }

    static func requestPermission() async -> FajrSystemAlarmStatus {
        guard #available(iOS 26.0, *) else { return .legacy }
        #if canImport(AlarmKit)
        _ = try? await AlarmManager.shared.requestAuthorization()
        #endif
        return status()
    }

    static func schedule(from date: Date) async -> Bool {
        guard #available(iOS 26.0, *) else { return false }
        #if canImport(AlarmKit)
        return await FajrAlarmKitScheduler.schedule(from: date)
        #else
        return false
        #endif
    }

    static func cancel() {
        guard #available(iOS 26.0, *) else { return }
        #if canImport(AlarmKit)
        FajrAlarmKitScheduler.cancel()
        #endif
    }

    static func scheduleFollowUp(at date: Date) async -> Bool {
        guard #available(iOS 26.0, *) else { return false }
        #if canImport(AlarmKit)
        return await FajrAlarmKitScheduler.scheduleFollowUp(at: date)
        #else
        return false
        #endif
    }

    static func cancelFollowUp() {
        guard #available(iOS 26.0, *) else { return }
        #if canImport(AlarmKit)
        FajrAlarmKitScheduler.cancelFollowUp()
        #endif
    }

    static func stopAlertingThenReschedule(from date: Date) {
        guard #available(iOS 26.0, *) else { return }
        #if canImport(AlarmKit)
        FajrAlarmKitScheduler.cancel()
        Task { _ = await FajrAlarmKitScheduler.schedule(from: date) }
        #endif
    }

    static func startObserving() {
        guard #available(iOS 26.0, *) else { return }
        #if canImport(AlarmKit)
        FajrAlarmKitScheduler.startObserving()
        #endif
    }
}

#if canImport(AlarmKit)
@available(iOS 26.0, *)
enum FajrAlarmKitScheduler {
    private static let idKey = "fajrAlarm.alarmKitId"
    private static let followUpIdKey = "fajrAlarm.alarmKitFollowUpId"

    static var alarmID: UUID { storedID(idKey) }
    static var followUpID: UUID { storedID(followUpIdKey) }

    private static func storedID(_ key: String) -> UUID {
        if let raw = UserDefaults.standard.string(forKey: key), let id = UUID(uuidString: raw) {
            return id
        }
        let id = UUID()
        UserDefaults.standard.set(id.uuidString, forKey: key)
        return id
    }

    static func schedule(from date: Date) async -> Bool {
        let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
        let time = Alarm.Schedule.Relative.Time(hour: comps.hour ?? 5, minute: comps.minute ?? 15)
        let daily = Alarm.Schedule.relative(
            .init(
                time: time,
                repeats: .weekly([.sunday, .monday, .tuesday, .wednesday, .thursday, .friday, .saturday])
            )
        )
        return await schedule(daily, id: alarmID)
    }

    static func scheduleFollowUp(at date: Date) async -> Bool {
        try? AlarmManager.shared.cancel(id: followUpID)
        return await schedule(.fixed(date), id: followUpID)
    }

    static func cancelFollowUp() {
        try? AlarmManager.shared.cancel(id: followUpID)
    }

    private static func schedule(_ schedule: Alarm.Schedule, id: UUID) async -> Bool {
        do {
            let manager = AlarmManager.shared
            let state = try await manager.requestAuthorization()
            guard state == .authorized else { return false }

            let title = LocalizedStringResource(
                stringLiteral: NSLocalizedString("fajr.ring.title", comment: "Fajr")
            )
            let stopTitle = LocalizedStringResource(
                stringLiteral: NSLocalizedString("fajr.alarmkit.stop", comment: "Stop")
            )
            let openTitle = LocalizedStringResource(
                stringLiteral: NSLocalizedString("fajr.alarmkit.open", comment: "Photograph")
            )

            let alert = AlarmPresentation.Alert(
                title: title,
                stopButton: AlarmButton(text: stopTitle, textColor: .white, systemImageName: "stop.fill"),
                secondaryButton: AlarmButton(text: openTitle, textColor: .white, systemImageName: "camera.fill"),
                secondaryButtonBehavior: .custom
            )
            let attributes = AlarmAttributes(
                presentation: AlarmPresentation(alert: alert),
                metadata: FajrAlarmMetadata(),
                tintColor: AppTheme.primary
            )
            let configuration = AlarmManager.AlarmConfiguration.alarm(
                schedule: schedule,
                attributes: attributes,
                stopIntent: StopFajrSystemAlarmIntent(),
                secondaryIntent: OpenNafsiFajrIntent(),
                sound: AlertConfiguration.AlertSound.default
            )
            _ = try await manager.schedule(id: id, configuration: configuration)
            return true
        } catch {
            return false
        }
    }

    static func cancel() {
        try? AlarmManager.shared.cancel(id: alarmID)
    }

    static func startObserving() {
        Task {
            for await alarms in AlarmManager.shared.alarmUpdates {
                let mainAlerting = alarms.contains { $0.id == alarmID && $0.state == .alerting }
                let followUpAlerting = alarms.contains { $0.id == followUpID && $0.state == .alerting }
                if mainAlerting || followUpAlerting {
                    await MainActor.run {
                        FajrAlarmManager.shared.beginRinging(force: true, armFollowUp: !followUpAlerting)
                    }
                }
            }
        }
    }
}

@available(iOS 26.0, *)
struct FajrAlarmMetadata: AlarmMetadata {}

@available(iOS 26.0, *)
struct OpenNafsiFajrIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Open Fajr"
    static var openAppWhenRun: Bool { true }

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            FajrAlarmManager.shared.beginRinging(force: true)
        }
        return .result()
    }
}

/// Stopping the system alarm counts as a dismiss: it rings again in one minute, up to five times.
@available(iOS 26.0, *)
struct StopFajrSystemAlarmIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Stop"
    static var openAppWhenRun: Bool { true }

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            FajrAlarmManager.shared.systemAlarmStopped()
        }
        return .result()
    }
}
#endif
