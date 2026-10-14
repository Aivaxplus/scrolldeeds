//
//  ScrollDeedsQuickLinkHandler.swift
//  scrolldeeds
//
//  Centraliseert Home Screen quick action → Safari (directe URL).
//

import UIKit

enum ScrollDeedsQuickLinkHandler {
    static func url(for shortcutItem: UIApplicationShortcutItem) -> URL? {
        switch shortcutItem.type {
        case "com.scrolldeeds.delete.shaytaan":
            return URL(string: "https://scrolldeeds.lovable.app/shaytaan")
        case "com.scrolldeeds.delete.money":
            return URL(string: "https://scrolldeeds.lovable.app/pricing")
        case "com.scrolldeeds.delete.reason":
            return URL(string: "https://scrolldeeds.lovable.app/feedback")
        default:
            return nil
        }
    }

    /// Opent de URL rechtstreeks in Safari (browser), nooit via universal links terug naar de app.
    /// Moet altijd op de main queue worden aangeroepen.
    static func openInSafari(_ shortcutItem: UIApplicationShortcutItem) {
        guard let url = url(for: shortcutItem) else { return }
        // universalLinksOnly: false = open altijd in de browser, ook als de URL
        // ergens als universal link geregistreerd staat.
        let options: [UIApplication.OpenExternalURLOptionsKey: Any] = [
            .universalLinksOnly: false
        ]
        UIApplication.shared.open(url, options: options, completionHandler: nil)
    }

    /// Legacy helper — intern nog gebruikt voor URL-validatie.
    @discardableResult
    static func open(_ shortcutItem: UIApplicationShortcutItem, completion: ((Bool) -> Void)? = nil) -> Bool {
        guard let url = url(for: shortcutItem) else {
            completion?(false)
            return false
        }
        let options: [UIApplication.OpenExternalURLOptionsKey: Any] = [.universalLinksOnly: false]
        let work = { UIApplication.shared.open(url, options: options, completionHandler: completion) }
        if Thread.isMainThread { work() } else { DispatchQueue.main.async(execute: work) }
        return true
    }
}
