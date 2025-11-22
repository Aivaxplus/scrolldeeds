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
            AuthorizationCenter.shared.requestAuthorization { [weak self] result in
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        self?.hasFamilyControlsAuthorization = (AuthorizationCenter.shared.authorizationStatus == .approved)
                    case .failure:
                        self?.hasFamilyControlsAuthorization = false
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


