//
//  RememberVaultModels.swift
//  scrolldeeds — Save → Remember (Islamic Content Vault)
//

import Foundation

enum RememberInputKind: String, Codable, CaseIterable {
    case link
    case pastedText
    case audioFile
    case videoFile
    case recordedAudio
}

enum RememberCategory: String, Codable, CaseIterable {
    case dua = "Dua"
    case reminder = "Reminder"
    case story = "Story"
    case khutbah = "Khutbah"
    case knowledge = "Knowledge"
    case quranHadith = "Quran/Hadith"

    var localizedKey: String {
        switch self {
        case .dua: return "remember.category.dua"
        case .reminder: return "remember.category.reminder"
        case .story: return "remember.category.story"
        case .khutbah: return "remember.category.khutbah"
        case .knowledge: return "remember.category.knowledge"
        case .quranHadith: return "remember.category.quran_hadith"
        }
    }
}

enum RememberProcessingState: String, Codable {
    case pending
    case processing
    case ready
    case failed
}

struct SavedRememberItem: Codable, Identifiable, Equatable {
    var id: UUID
    var createdAt: Date
    var inputKind: RememberInputKind
    /// URL string, pasted text, or relative filename under media folder
    var originalContent: String
    var mediaRelativePath: String?
    var transcript: String?
    var summary: String
    var category: RememberCategory
    var takeaway: String
    var isFavorite: Bool
    var isFridayKhutbahTag: Bool
    var processingState: RememberProcessingState
    var processingError: String?

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        inputKind: RememberInputKind,
        originalContent: String,
        mediaRelativePath: String? = nil,
        transcript: String? = nil,
        summary: String = "",
        category: RememberCategory = .reminder,
        takeaway: String = "",
        isFavorite: Bool = false,
        isFridayKhutbahTag: Bool = false,
        processingState: RememberProcessingState = .pending,
        processingError: String? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.inputKind = inputKind
        self.originalContent = originalContent
        self.mediaRelativePath = mediaRelativePath
        self.transcript = transcript
        self.summary = summary
        self.category = category
        self.takeaway = takeaway
        self.isFavorite = isFavorite
        self.isFridayKhutbahTag = isFridayKhutbahTag
        self.processingState = processingState
        self.processingError = processingError
    }
}
