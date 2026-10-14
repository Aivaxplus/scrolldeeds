//
//  PermissionsManager.swift
//  scrolldeeds
//
//  Handles permissions for Family Controls and Speech Recognition.
//

import Foundation
import Combine
import Speech

#if canImport(FamilyControls)
import FamilyControls
#endif

final class PermissionsManager: ObservableObject {
    @Published var hasFamilyControlsAuthorization: Bool = false
    @Published var hasSpeechAuthorization: Bool = false

    private var cancellables: Set<AnyCancellable> = []

    func requestAllPermissions() {
        requestSpeechPermission()
        requestFamilyControlsPermission()
    }

    func requestSpeechPermission() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.hasSpeechAuthorization = (status == .authorized)
            }
        }
    }

    func requestFamilyControlsPermission() {
        #if canImport(FamilyControls)
        if #available(iOS 16.0, *) {
            Task {
                do {
                    try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                    await MainActor.run {
                        self.hasFamilyControlsAuthorization = (AuthorizationCenter.shared.authorizationStatus == .approved)
                    }
                } catch {
                    await MainActor.run {
                        self.hasFamilyControlsAuthorization = false
                    }
                }
            }
        } else {
            hasFamilyControlsAuthorization = false
        }
        #else
        hasFamilyControlsAuthorization = false
        #endif
    }
}


