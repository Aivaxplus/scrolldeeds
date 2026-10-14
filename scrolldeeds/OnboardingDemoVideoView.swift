//
//  OnboardingDemoVideoView.swift
//  scrolldeeds
//
//  Looping, muted video for Get Started iPhone mockup.
//  Only the English demo asset is used for every app language (`Videos/OnboardingDemo_en.mp4` in source).
//  Add it to the app target to show the demo; otherwise a placeholder is shown.
//

import SwiftUI
import AVFoundation

struct OnboardingDemoVideoView: View {
    var body: some View {
        if let url = Self.englishDemoVideoURL() {
            LoopingVideoPlayerView(url: url)
        } else {
            OnboardingDemoPlaceholderView()
        }
    }

    /// Always resolves the English onboarding demo only (ignores device / in-app language for video choice).
    private static func englishDemoVideoURL() -> URL? {
        let bundle = Bundle.main
        // Source lives under `scrolldeeds/Videos/`; the built app may keep that folder or flatten — try both.
        for name in ["OnboardingDemo_en", "OnboardingDemo"] {
            if let url = bundle.url(forResource: name, withExtension: "mp4", subdirectory: "Videos") {
                return url
            }
            if let url = bundle.url(forResource: name, withExtension: "mp4") {
                return url
            }
        }
        return nil
    }
}

// MARK: - Looping video (muted)

private struct LoopingVideoPlayerView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> UIView {
        let view = LoopingVideoUIView()
        view.configure(url: url)
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard let view = uiView as? LoopingVideoUIView else { return }
        view.configure(url: url)
    }
}

private final class LoopingVideoUIView: UIView {
    private var queuePlayer: AVQueuePlayer?
    private var looper: AVPlayerLooper?
    private var currentURL: URL?

    override class var layerClass: AnyClass { AVPlayerLayer.self }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func configure(url: URL) {
        if currentURL == url { return }
        currentURL = url

        let item = AVPlayerItem(url: url)
        let player = AVQueuePlayer(playerItem: item)
        player.isMuted = true
        player.play()

        let looper = AVPlayerLooper(player: player, templateItem: item)
        self.queuePlayer = player
        self.looper = looper

        let layer = self.layer as! AVPlayerLayer
        layer.player = player
        layer.videoGravity = .resizeAspectFill
    }
}

// MARK: - Placeholder when no video file

private struct OnboardingDemoPlaceholderView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    AppTheme.primary.opacity(0.25),
                    AppTheme.accent.opacity(0.15),
                    Color(red: 0.06, green: 0.10, blue: 0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            VStack(spacing: 12) {
                Image(systemName: "play.rectangle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(AppTheme.accent.opacity(0.8))
                Text(NSLocalizedString("onboarding.demo_placeholder", comment: "How it works"))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
            }
        }
    }
}

#Preview("Demo video (placeholder)") {
    OnboardingDemoVideoView()
        .frame(width: 252, height: 540)
}
