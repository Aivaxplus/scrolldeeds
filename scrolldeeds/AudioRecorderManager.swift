//
//  AudioRecorderManager.swift
//  scrolldeeds
//

import Foundation
import AVFoundation
import Combine

class AudioRecorderManager: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var recordingTime: TimeInterval = 0
    @Published var audioFileURL: URL?
    
    private var audioRecorder: AVAudioRecorder?
    private var recordingTimer: Timer?
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default)
            try audioSession.setActive(true)
        } catch {
            debugPrint("Failed to set up audio session: \(error)")
        }
    }
    
    func startRecording() {
        let audioFilename = getDocumentsDirectory().appendingPathComponent("dhikr_recording_\(Date().timeIntervalSince1970).m4a")
        
        // Optimized settings for faster upload: lower quality but still clear enough for verification
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 22050, // Reduced from 44100 (half the sample rate = smaller file)
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue // Medium quality (was high) = faster encoding & smaller file
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.record()
            
            isRecording = true
            recordingTime = 0
            audioFileURL = audioFilename
            
            // Start timer to track recording duration
            recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                guard let self = self, let recorder = self.audioRecorder else { return }
                self.recordingTime = recorder.currentTime
            }
            
        } catch {
            debugPrint("Could not start recording: \(error)")
        }
    }
    
    func stopRecording(completion: @escaping () -> Void) {
        audioRecorder?.stop()
        recordingTimer?.invalidate()
        recordingTimer = nil
        isRecording = false
        
        // Give a tiny moment for the file to be written to disk
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            completion()
        }
    }
    
    func getAudioData() -> Data? {
        guard let url = audioFileURL else { 
            debugPrint("AudioRecorderManager: No audio file URL available")
            return nil 
        }
        
        // Check if file exists
        guard FileManager.default.fileExists(atPath: url.path) else {
            debugPrint("AudioRecorderManager: Audio file does not exist at path: \(url.path)")
            return nil
        }
        
        // Try to read the data
        do {
            let data = try Data(contentsOf: url)
            debugPrint("AudioRecorderManager: Successfully read audio data, size: \(data.count) bytes")
            return data
        } catch {
            debugPrint("AudioRecorderManager: Failed to read audio data: \(error)")
            return nil
        }
    }
    
    func deleteRecording() {
        if let url = audioFileURL {
            try? FileManager.default.removeItem(at: url)
        }
        audioFileURL = nil
        recordingTime = 0
    }
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}

