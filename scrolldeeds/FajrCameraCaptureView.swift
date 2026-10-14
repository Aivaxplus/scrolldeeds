import AVFoundation
import Combine
import SwiftUI
import UIKit

struct CameraCaptureView: View {
    var objectName: String
    var objectSymbol: String
    var onFinish: (UIImage?) -> Void

    @StateObject private var camera = FajrCameraSession()
    @State private var captured: UIImage?

    var body: some View {
        ZStack {
            SDPageBackground()

            VStack(spacing: 0) {
                header

                Text(String(format: NSLocalizedString("fajr.capture.hint", comment: "Fill the frame with your %@."), objectName))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    .padding(.bottom, 14)

                viewfinder
                    .padding(.horizontal, 20)

                Spacer(minLength: 16)

                bottomBar
            }
        }
        .onAppear { camera.start() }
        .onDisappear { camera.stop() }
        .statusBarHidden(false)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            SDBrandMark(iconSize: 20, textSize: 20)
            Spacer(minLength: 8)
            SDDismissButton {
                HapticManager.shared.soft()
                onFinish(nil)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private var viewfinder: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.black.opacity(0.18))

            if let captured {
                Image(uiImage: captured)
                    .resizable()
                    .scaledToFill()
            } else if camera.isRunning {
                FajrCameraPreview(session: camera.session)
            } else if camera.permissionDenied {
                cameraMessage(NSLocalizedString("fajr.capture.permission", comment: "Allow camera in Settings."))
            } else if camera.unavailable {
                cameraMessage(NSLocalizedString("fajr.capture.unavailable", comment: "Camera isn’t available."))
            } else {
                SwiftUI.ProgressView()
                    .tint(AppTheme.primary)
            }

            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(AppTheme.primary.opacity(0.85), lineWidth: 2.5)

            VStack {
                HStack {
                    Label(objectName, systemImage: objectSymbol)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(AppTheme.primary.opacity(0.92)))
                    Spacer()
                }
                .padding(14)
                Spacer()
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 420)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: AppTheme.primary.opacity(0.16), radius: 18, y: 8)
    }

    private func cameraMessage(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 15, weight: .medium, design: .rounded))
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .padding(24)
    }

    private var bottomBar: some View {
        VStack(spacing: 14) {
            if captured != nil {
                Button {
                    HapticManager.shared.success()
                    onFinish(captured)
                } label: {
                    Text(NSLocalizedString("fajr.capture.use", comment: "Use this photo"))
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.primary)
                        .cornerRadius(16)
                }

                Button {
                    HapticManager.shared.soft()
                    captured = nil
                } label: {
                    Text(NSLocalizedString("fajr.setup.retake", comment: "Retake photo"))
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(AppTheme.textSecondary)
                }
            } else {
                Button {
                    HapticManager.shared.medium()
                    camera.capture { image in
                        if let image {
                            captured = image
                        }
                    }
                } label: {
                    ZStack {
                        Circle()
                            .stroke(AppTheme.primary, lineWidth: 4)
                            .frame(width: 78, height: 78)
                        Circle()
                            .fill(AppTheme.primary)
                            .frame(width: 62, height: 62)
                        Image(systemName: "camera.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .disabled(!camera.isRunning)
                .opacity(camera.isRunning ? 1 : 0.45)
                .accessibilityLabel(NSLocalizedString("fajr.capture.shutter", comment: "Take photo"))
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 28)
    }
}

private final class FajrCameraSession: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private let queue = DispatchQueue(label: "nafsi.fajr.camera")
    private var onCapture: ((UIImage?) -> Void)?

    @Published var isRunning = false
    @Published var permissionDenied = false
    @Published var unavailable = false

    func start() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            configureAndStart()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    if granted {
                        self?.configureAndStart()
                    } else {
                        self?.permissionDenied = true
                    }
                }
            }
        default:
            permissionDenied = true
        }
    }

    func stop() {
        queue.async { [weak self] in
            self?.session.stopRunning()
            DispatchQueue.main.async { self?.isRunning = false }
        }
    }

    func capture(completion: @escaping (UIImage?) -> Void) {
        onCapture = completion
        output.capturePhoto(with: AVCapturePhotoSettings(), delegate: self)
    }

    private func configureAndStart() {
        queue.async { [weak self] in
            guard let self else { return }
            self.session.beginConfiguration()
            self.session.sessionPreset = .photo

            self.session.inputs.forEach { self.session.removeInput($0) }
            self.session.outputs.forEach { self.session.removeOutput($0) }

            guard
                let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back)
                    ?? AVCaptureDevice.default(for: .video),
                let input = try? AVCaptureDeviceInput(device: device),
                self.session.canAddInput(input),
                self.session.canAddOutput(self.output)
            else {
                DispatchQueue.main.async {
                    self.unavailable = true
                }
                self.session.commitConfiguration()
                return
            }

            self.session.addInput(input)
            self.session.addOutput(self.output)
            if let connection = self.output.connection(with: .video), connection.isVideoOrientationSupported {
                connection.videoOrientation = .portrait
            }
            self.session.commitConfiguration()
            self.session.startRunning()
            DispatchQueue.main.async { self.isRunning = true }
        }
    }

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        var image: UIImage?
        if error == nil, let data = photo.fileDataRepresentation() {
            image = UIImage(data: data)
        }
        DispatchQueue.main.async { [weak self] in
            self?.onCapture?(image)
            self?.onCapture = nil
        }
    }
}

private struct FajrCameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.previewLayer.session = session
        if let connection = uiView.previewLayer.connection, connection.isVideoOrientationSupported {
            connection.videoOrientation = .portrait
        }
    }

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }
}
