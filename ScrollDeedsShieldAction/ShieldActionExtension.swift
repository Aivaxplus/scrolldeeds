//
//  ShieldActionExtension.swift
//  ScrollDeedsShieldAction
//
//  Handles the button on the Nafsi lock screen. A shield can't open the app itself,
//  so tapping the button posts a notification that opens Nafsi.
//

import ManagedSettings
import UserNotifications

private let actionAppGroupID = "group.com.scrolldeeds.app"

class ShieldActionExtension: ShieldActionDelegate {

    override func handle(action: ShieldAction,
                         for application: ApplicationToken,
                         completionHandler: @escaping (ShieldActionResponse) -> Void) {
        respond(to: action, completionHandler: completionHandler)
    }

    override func handle(action: ShieldAction,
                         for webDomain: WebDomainToken,
                         completionHandler: @escaping (ShieldActionResponse) -> Void) {
        respond(to: action, completionHandler: completionHandler)
    }

    override func handle(action: ShieldAction,
                         for category: ActivityCategoryToken,
                         completionHandler: @escaping (ShieldActionResponse) -> Void) {
        respond(to: action, completionHandler: completionHandler)
    }

    private func respond(to action: ShieldAction,
                         completionHandler: @escaping (ShieldActionResponse) -> Void) {
        guard action == .primaryButtonPressed else {
            completionHandler(.close)
            return
        }
        // `.defer` keeps the shield on screen instead of sending the user to the home screen.
        postUnlockNotification {
            completionHandler(.defer)
        }
    }

    private func postUnlockNotification(completion: @escaping () -> Void) {
        let copy = UnlockPromptCopy.current()
        let content = UNMutableNotificationContent()
        content.title = copy.title
        content.body = copy.body
        content.sound = .default
        content.categoryIdentifier = "BLOCKED_APP_ATTEMPT"
        content.interruptionLevel = .timeSensitive
        content.userInfo = ["shield_unlock_prompt": true]

        let center = UNUserNotificationCenter.current()
        center.removeDeliveredNotifications(withIdentifiers: [UnlockPromptCopy.identifier])
        let request = UNNotificationRequest(
            identifier: UnlockPromptCopy.identifier,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        )
        center.add(request) { _ in
            // Stops the lock screen from posting a second copy when .defer redraws it.
            UserDefaults(suiteName: actionAppGroupID)?
                .set(Date().timeIntervalSince1970, forKey: "shieldUnlockPromptPostedAt")
            completion()
        }
    }
}

/// The extension can't read the app's Localizable.strings, so the 7 locales live here.
private struct UnlockPromptCopy {
    static let identifier = "shield_unlock_prompt"

    let title: String
    let body: String

    static func current() -> UnlockPromptCopy {
        let saved = UserDefaults(suiteName: actionAppGroupID)?.string(forKey: "AppLanguage")
        let code = (saved ?? Locale.preferredLanguages.first ?? "en").prefix(2).lowercased()
        return all[code] ?? all["en"]!
    }

    static let all: [String: UnlockPromptCopy] = [
        "en": UnlockPromptCopy(
            title: "🔓 Tap here to unlock your apps",
            body: "Do one good deed in Nafsi and your apps open again."
        ),
        "nl": UnlockPromptCopy(
            title: "🔓 Tik hier om je apps te ontgrendelen",
            body: "Doe één goede daad in Nafsi en je apps gaan weer open."
        ),
        "es": UnlockPromptCopy(
            title: "🔓 Toca aquí para desbloquear tus apps",
            body: "Haz una buena acción en Nafsi y tus apps se abren de nuevo."
        ),
        "de": UnlockPromptCopy(
            title: "🔓 Tippe hier, um deine Apps zu entsperren",
            body: "Tu eine gute Tat in Nafsi und deine Apps sind wieder offen."
        ),
        "fr": UnlockPromptCopy(
            title: "🔓 Touche ici pour déverrouiller tes apps",
            body: "Fais une bonne action dans Nafsi et tes apps se rouvrent."
        ),
        "ru": UnlockPromptCopy(
            title: "🔓 Нажми, чтобы разблокировать приложения",
            body: "Сделай одно доброе дело в Nafsi — и приложения снова откроются."
        ),
        "ar": UnlockPromptCopy(
            title: "🔓 اضغط هنا لفتح تطبيقاتك",
            body: "قم بعمل صالح واحد في Nafsi وستُفتح تطبيقاتك من جديد."
        ),
    ]
}
