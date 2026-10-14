//
//  ShieldConfigurationExtension.swift
//  ScrollDeedsShield
//
//  Provides the custom visual design for the shield shown when a blocked app
//  is opened. iOS calls this extension instead of showing the default Apple message.
//

import ManagedSettings
import ManagedSettingsUI
import UIKit
import UserNotifications

private let shieldAppGroupID = "group.com.scrolldeeds.app"

class ShieldConfigurationExtension: ShieldConfigurationDataSource {

    // MARK: - ShieldConfigurationDataSource

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        makeConfig(for: application.localizedDisplayName)
    }

    override func configuration(shielding application: Application,
                                in category: ActivityCategory) -> ShieldConfiguration {
        makeConfig(for: application.localizedDisplayName)
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        makeConfig(for: webDomain.domain)
    }

    override func configuration(shielding webDomain: WebDomain,
                                in category: ActivityCategory) -> ShieldConfiguration {
        makeConfig(for: webDomain.domain)
    }

    // MARK: - Private

    private func makeConfig(for appName: String?) -> ShieldConfiguration {
        let isNewAppearance = UnlockPrompt.postIfDue()
        let copy = ShieldCopy.current()
        let lang = ShieldCopy.languageCode()
        let verse = ShieldVerses.current(language: lang, advance: isNewAppearance)
        let title: String
        if let name = appName, !name.isEmpty {
            title = String(format: copy.titleNamed, name)
        } else {
            title = copy.title
        }
        let subtitle = "“\(verse.text)”\n— \(verse.reference)\n\n\(verse.reflection)\n\n\(copy.instruction)"

        // A light blur keeps the shield white even when the phone is in dark mode.
        return ShieldConfiguration(
            backgroundBlurStyle: .extraLight,
            backgroundColor: .white,
            icon: nafsiIcon(),
            title: ShieldConfiguration.Label(text: title, color: ShieldPalette.title),
            subtitle: ShieldConfiguration.Label(text: subtitle, color: ShieldPalette.subtitle),
            primaryButtonLabel: ShieldConfiguration.Label(text: copy.button, color: .white),
            primaryButtonBackgroundColor: ShieldPalette.green
        )
    }

    private func nafsiIcon() -> UIImage? {
        if let cached = Self.cachedCenteredIcon { return cached }
        if let character = UIImage(named: "NafsiPoseStand") {
            // Pose art is visually off-center (robe flares left). Recenter the
            // opaque pixels so the shield icon lines up with the title below.
            let icon = centeredIcon(character, maxSide: 168)
            Self.cachedCenteredIcon = icon
            return icon
        }
        let config = UIImage.SymbolConfiguration(pointSize: 64, weight: .bold, scale: .large)
            .applying(UIImage.SymbolConfiguration(paletteColors: [ShieldPalette.green]))
        return UIImage(systemName: "lock.fill", withConfiguration: config)
    }

    private static var cachedCenteredIcon: UIImage?

    /// Square icon with the character’s visual weight centered (not just alpha bounds —
    /// the flowing robe pulls the bbox left while the body sits to the right).
    private func centeredIcon(_ image: UIImage, maxSide: CGFloat) -> UIImage {
        guard let cg = image.cgImage else { return scaledIcon(image, maxSide: maxSide) }
        let scale = image.scale
        let pixelW = CGFloat(cg.width)
        let pixelH = CGFloat(cg.height)
        guard pixelW > 0, pixelH > 0 else { return scaledIcon(image, maxSide: maxSide) }

        let mass = visualCenter(of: cg)
        let pointSize = CGSize(width: pixelW / scale, height: pixelH / scale)
        let fit = min(maxSide / pointSize.width, maxSide / pointSize.height, 1)
        let drawSize = CGSize(
            width: (pointSize.width * fit).rounded(.up),
            height: (pointSize.height * fit).rounded(.up)
        )
        // Keep canvas large enough that the optical shift still fits.
        let pad = abs(mass.x - 0.5) * drawSize.width * 2 + 8
        let canvasW = drawSize.width + pad
        let canvasH = drawSize.height
        let canvasSize = CGSize(width: canvasW.rounded(.up), height: canvasH.rounded(.up))

        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = false
        format.scale = 0

        // Shift so visual center of mass lands on the canvas midpoint.
        let opticalX = (0.5 - mass.x) * drawSize.width
        let origin = CGPoint(
            x: ((canvasSize.width - drawSize.width) / 2 + opticalX).rounded(.down),
            y: ((canvasSize.height - drawSize.height) / 2).rounded(.down)
        )

        return UIGraphicsImageRenderer(size: canvasSize, format: format).image { _ in
            image.draw(in: CGRect(origin: origin, size: drawSize))
        }
    }

    /// Normalized (0…1) center of mass of opaque pixels.
    private func visualCenter(of cgImage: CGImage) -> CGPoint {
        let width = cgImage.width
        let height = cgImage.height
        guard width > 0, height > 0 else { return CGPoint(x: 0.5, y: 0.5) }

        var data = [UInt8](repeating: 0, count: width * height * 4)
        guard let ctx = CGContext(
            data: &data,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return CGPoint(x: 0.5, y: 0.5) }

        ctx.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        var sumX = 0.0
        var sumY = 0.0
        var sum = 0.0
        let alphaThreshold: UInt8 = 12

        for y in 0..<height {
            let row = y * width * 4
            for x in 0..<width {
                let a = data[row + x * 4 + 3]
                guard a > alphaThreshold else { continue }
                let w = Double(a)
                sumX += Double(x) * w
                sumY += Double(y) * w
                sum += w
            }
        }

        guard sum > 0 else { return CGPoint(x: 0.5, y: 0.5) }
        return CGPoint(x: sumX / sum / Double(width - 1), y: sumY / sum / Double(height - 1))
    }

    private func scaledIcon(_ image: UIImage, maxSide: CGFloat) -> UIImage {
        let size = image.size
        guard size.width > 0, size.height > 0 else { return image }
        let scale = min(maxSide / size.width, maxSide / size.height, 1)
        let target = CGSize(width: (size.width * scale).rounded(), height: (size.height * scale).rounded())
        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = false
        format.scale = 0
        return UIGraphicsImageRenderer(size: target, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: target))
        }
    }
}

// MARK: - Unlock notification

/// iOS asks for the shield each time it is shown, so this is where the notification goes out.
/// Throttled because iOS can ask several times for one appearance.
private enum UnlockPrompt {
    static let identifier = "shield_unlock_prompt"
    private static let lastPostedKey = "shieldUnlockPromptPostedAt"
    private static let minimumGap: TimeInterval = 20

    /// Returns true when this is a fresh appearance (a notification went out).
    @discardableResult
    static func postIfDue() -> Bool {
        let defaults = UserDefaults(suiteName: shieldAppGroupID)
        let last = defaults?.double(forKey: lastPostedKey) ?? 0
        let now = Date().timeIntervalSince1970
        guard now - last >= minimumGap else { return false }
        defaults?.set(now, forKey: lastPostedKey)

        let copy = UnlockPromptCopy.current()
        let content = UNMutableNotificationContent()
        content.title = copy.title
        content.body = copy.body
        content.sound = .default
        content.categoryIdentifier = "BLOCKED_APP_ATTEMPT"
        content.interruptionLevel = .timeSensitive
        content.userInfo = ["shield_unlock_prompt": true]

        let center = UNUserNotificationCenter.current()
        center.removeDeliveredNotifications(withIdentifiers: [identifier])
        center.add(UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        ))
        return true
    }
}

private struct UnlockPromptCopy {
    let title: String
    let body: String

    static func current() -> UnlockPromptCopy {
        let saved = UserDefaults(suiteName: shieldAppGroupID)?.string(forKey: "AppLanguage")
        let code = (saved ?? Locale.preferredLanguages.first ?? "en").prefix(2).lowercased()
        return all[code] ?? all["en"]!
    }

    static let all: [String: UnlockPromptCopy] = [
        "en": UnlockPromptCopy(title: "🔓 Tap here to unlock your apps",
                               body: "Earn coins with a good deed, then buy a heart to open your apps."),
        "nl": UnlockPromptCopy(title: "🔓 Tik hier om je apps te ontgrendelen",
                               body: "Verdien munten met een goede daad. Koop daarna een hart om je apps te openen."),
        "es": UnlockPromptCopy(title: "🔓 Toca aquí para desbloquear tus apps",
                               body: "Gana monedas con una buena acción y compra un corazón para abrir tus apps."),
        "de": UnlockPromptCopy(title: "🔓 Tippe hier, um deine Apps zu entsperren",
                               body: "Verdiene Münzen mit einer guten Tat und kaufe ein Herz, um deine Apps zu öffnen."),
        "fr": UnlockPromptCopy(title: "🔓 Touche ici pour déverrouiller tes apps",
                               body: "Gagne des pièces avec une bonne action, puis achète un cœur pour ouvrir tes apps."),
        "ru": UnlockPromptCopy(title: "🔓 Нажми, чтобы разблокировать приложения",
                               body: "Заработай монеты добрым делом, затем купи сердце, чтобы открыть приложения."),
        "ar": UnlockPromptCopy(title: "🔓 اضغط هنا لفتح تطبيقاتك",
                               body: "اجمع عملات بعمل صالح، ثم اشترِ قلبًا لفتح تطبيقاتك."),
    ]
}

// MARK: - Palette (AppTheme light tokens)

private enum ShieldPalette {
    static let title = UIColor(red: 0.102, green: 0.114, blue: 0.106, alpha: 1)    // #1A1D1B
    static let subtitle = UIColor(red: 0.353, green: 0.400, blue: 0.376, alpha: 1) // #5A6660
    static let green = UIColor(red: 0.157, green: 0.604, blue: 0.392, alpha: 1)    // #289A64
}

// MARK: - Copy

/// The extension can't read the app's Localizable.strings, so the 7 locales live here.
struct ShieldCopy {
    let title: String
    let titleNamed: String
    let instruction: String
    let button: String

    static func languageCode() -> String {
        let saved = UserDefaults(suiteName: shieldAppGroupID)?.string(forKey: "AppLanguage")
        let code = String((saved ?? Locale.preferredLanguages.first ?? "en").prefix(2)).lowercased()
        return all[code] == nil ? "en" : code
    }

    static func current() -> ShieldCopy {
        all[languageCode()] ?? all["en"]!
    }

    static let all: [String: ShieldCopy] = [
        "en": ShieldCopy(
            title: "A moment for Allah",
            titleNamed: "Before you open %@",
            instruction: "When you’re ready, tap the notification. Earn coins, then buy a heart to continue.",
            button: "🔔  Send the notification again"
        ),
        "nl": ShieldCopy(
            title: "Een moment voor Allah",
            titleNamed: "Voordat je %@ opent",
            instruction: "Als je klaar bent, tik op de melding. Verdien munten en koop een hart om verder te gaan.",
            button: "🔔  Stuur de melding opnieuw"
        ),
        "es": ShieldCopy(
            title: "Un momento para Allah",
            titleNamed: "Antes de abrir %@",
            instruction: "Cuando estés listo, toca la notificación. Gana monedas y compra un corazón para seguir.",
            button: "🔔  Enviar la notificación otra vez"
        ),
        "de": ShieldCopy(
            title: "Ein Moment für Allah",
            titleNamed: "Bevor du %@ öffnest",
            instruction: "Wenn du bereit bist, tippe auf die Mitteilung. Verdiene Münzen und kaufe ein Herz, um weiterzumachen.",
            button: "🔔  Mitteilung erneut senden"
        ),
        "fr": ShieldCopy(
            title: "Un moment pour Allah",
            titleNamed: "Avant d’ouvrir %@",
            instruction: "Quand tu es prêt, touche la notification. Gagne des pièces, puis achète un cœur pour continuer.",
            button: "🔔  Renvoyer la notification"
        ),
        "ru": ShieldCopy(
            title: "Минута для Аллаха",
            titleNamed: "Прежде чем открыть %@",
            instruction: "Когда будешь готов, нажми на уведомление. Заработай монеты и купи сердце, чтобы продолжить.",
            button: "🔔  Отправить уведомление снова"
        ),
        "ar": ShieldCopy(
            title: "لحظة لله",
            titleNamed: "قبل أن تفتح %@",
            instruction: "حين تكون مستعدًا، اضغط على الإشعار. اجمع العملات واشترِ قلبًا لتُكمل.",
            button: "🔔  أرسل الإشعار مجددًا"
        ),
    ]
}
