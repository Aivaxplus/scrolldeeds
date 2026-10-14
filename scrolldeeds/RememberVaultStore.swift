//
//  RememberVaultStore.swift
//  scrolldeeds — persisted “Remember” vault items (Save → Remember)
//

import Combine
import Foundation

private enum RememberVaultStorage {
    static let appGroupId = "group.com.scrolldeeds.app"
}

@MainActor
final class RememberVaultStore: ObservableObject {
    static let shared = RememberVaultStore()

    @Published private(set) var items: [SavedRememberItem] = []

    private let fileName = "saved_remember_items.json"

    private var fileURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: RememberVaultStorage.appGroupId)?
            .appendingPathComponent(fileName, isDirectory: false)
    }

    private init() {
        load()
    }

    func load() {
        guard let url = fileURL, FileManager.default.fileExists(atPath: url.path) else {
            items = []
            return
        }
        do {
            let data = try Data(contentsOf: url)
            items = try JSONDecoder().decode([SavedRememberItem].self, from: data)
                .sorted { $0.createdAt > $1.createdAt }
        } catch {
            items = []
        }
    }

    private func persist() {
        guard let url = fileURL else { return }
        do {
            let data = try JSONEncoder().encode(items)
            try data.write(to: url, options: [.atomic])
        } catch {}
    }

    func upsert(_ item: SavedRememberItem) {
        if let i = items.firstIndex(where: { $0.id == item.id }) {
            items[i] = item
        } else {
            items.insert(item, at: 0)
        }
        persist()
    }

    func updateFavorite(id: UUID, isFavorite: Bool) {
        guard let i = items.firstIndex(where: { $0.id == id }) else { return }
        items[i].isFavorite = isFavorite
        persist()
    }

    func updateFridayTag(id: UUID, tagged: Bool) {
        guard let i = items.firstIndex(where: { $0.id == id }) else { return }
        items[i].isFridayKhutbahTag = tagged
        persist()
    }

    /// Reset processing so a future pipeline can pick the item up again.
    func retryProcessing(id: UUID) {
        guard let i = items.firstIndex(where: { $0.id == id }) else { return }
        items[i].processingState = .pending
        items[i].processingError = nil
        persist()
    }

    func delete(id: UUID) {
        items.removeAll { $0.id == id }
        persist()
    }
}
