import AVFoundation
import AudioToolbox
import UIKit

/// Plays the lock chime even if the phone is on mute.
final class LockSoundPlayer: NSObject, AVAudioPlayerDelegate {
    static let shared = LockSoundPlayer()

    private var player: AVAudioPlayer?
    private var systemSoundID: SystemSoundID = 0

    func play() {
        if Thread.isMainThread {
            playOnMain()
        } else {
            DispatchQueue.main.async { self.playOnMain() }
        }
    }

    private func playOnMain() {
        activateSpeaker()

        if playFromAsset() || playFromBundle() {
            return
        }

        playSystemSoundFallback()
    }

    @discardableResult
    private func playFromAsset() -> Bool {
        guard let data = NSDataAsset(name: "sd_lock")?.data else { return false }
        return startPlayer(try? AVAudioPlayer(data: data))
    }

    @discardableResult
    private func playFromBundle() -> Bool {
        let url = Bundle.main.url(forResource: "sd_lock", withExtension: "wav")
            ?? Bundle.main.url(forResource: "sd_lock", withExtension: "caf")
        guard let url else { return false }
        return startPlayer(try? AVAudioPlayer(contentsOf: url))
    }

    private func startPlayer(_ player: AVAudioPlayer?) -> Bool {
        guard let player else { return false }
        player.delegate = self
        player.volume = 1
        player.prepareToPlay()
        guard player.play() else { return false }
        self.player = player
        return true
    }

    private func activateSpeaker() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.overrideOutputAudioPort(.speaker)
        try? session.setActive(true)
    }

    private func playSystemSoundFallback() {
        let url = Bundle.main.url(forResource: "sd_lock", withExtension: "wav")
            ?? Bundle.main.url(forResource: "sd_lock", withExtension: "caf")
        guard let url else { return }

        if systemSoundID != 0 {
            AudioServicesDisposeSystemSoundID(systemSoundID)
            systemSoundID = 0
        }
        AudioServicesCreateSystemSoundID(url as CFURL, &systemSoundID)
        var flag: UInt32 = 0
        AudioServicesSetProperty(
            kAudioServicesPropertyIsUISound,
            UInt32(MemoryLayout.size(ofValue: systemSoundID)),
            &systemSoundID,
            UInt32(MemoryLayout.size(ofValue: flag)),
            &flag
        )
        AudioServicesPlaySystemSound(systemSoundID)
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        if self.player === player {
            self.player = nil
        }
    }
}
