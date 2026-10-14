//
//  PushupCameraPreviewView.swift
//  scrolldeeds
//
//  Alleen videovoorbeeld — geen skelet-overlay; pose wordt alleen op de camera-queue gebruikt voor reps.
//

import AVFoundation
import SwiftUI
import UIKit

final class PushupPreviewContainerView: UIView {
    let previewLayer = AVCaptureVideoPreviewLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        previewLayer.videoGravity = .resizeAspectFill
        layer.addSublayer(previewLayer)
    }

    required init?(coder: NSCoder) { nil }

    override func layoutSubviews() {
        super.layoutSubviews()
        previewLayer.frame = bounds
    }

    func configureSession(_ session: AVCaptureSession) {
        previewLayer.session = session
        if let c = previewLayer.connection, c.isVideoOrientationSupported {
            c.videoOrientation = .portrait
        }
        if let c = previewLayer.connection, c.isVideoMirroringSupported {
            c.automaticallyAdjustsVideoMirroring = false
            c.isVideoMirrored = true
        }
    }
}

struct PushupCameraPreviewRepresentable: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PushupPreviewContainerView {
        let v = PushupPreviewContainerView()
        v.configureSession(session)
        return v
    }

    func updateUIView(_ uiView: PushupPreviewContainerView, context: Context) {
        uiView.configureSession(session)
    }
}
