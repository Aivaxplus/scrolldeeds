//
//  RememberVaultMediaExporter.swift
//

import AVFoundation
import Foundation

enum RememberVaultMediaExporter {
    /// Extracts audio to a temporary m4a for speech recognition (video inputs).
    static func extractAudioM4A(fromVideoURL videoURL: URL) async throws -> URL {
        let asset = AVURLAsset(url: videoURL)
        guard let exporter = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetAppleM4A) else {
            throw NSError(domain: "RememberVault", code: 1, userInfo: [NSLocalizedDescriptionKey: "Export failed"])
        }
        let out = FileManager.default.temporaryDirectory
            .appendingPathComponent("vault_extract_\(UUID().uuidString).m4a")
        try? FileManager.default.removeItem(at: out)
        exporter.outputURL = out
        exporter.outputFileType = .m4a
        await exporter.export()
        if exporter.status != .completed {
            throw exporter.error ?? NSError(domain: "RememberVault", code: 2, userInfo: [NSLocalizedDescriptionKey: "Export incomplete"])
        }
        return out
    }
}
