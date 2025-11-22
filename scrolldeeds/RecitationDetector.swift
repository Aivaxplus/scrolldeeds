//
//  RecitationDetector.swift
//  scrolldeeds
//
//  Simple on-device speech recognizer to count target phrases.
//

import Foundation
import Combine
import AVFoundation
import Speech

final class RecitationDetector: ObservableObject {
    enum Target: String, CaseIterable {
        case alhamdulillah = "alhamdulillah"
        case astaghfirullah = "astaghfirullah"
        case customDua = "dua"
    }

    @Published var recognizedCount: Int = 0
    @Published var isListening: Bool = false
    @Published var lastTranscript: String = ""

    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var target: Target = .alhamdulillah
    private var goalCount: Int = 3

    func start(target: Target, goal: Int = 3) throws {
        stop()
        recognizedCount = 0
        lastTranscript = ""
        self.target = target
        self.goalCount = goal

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        request = SFSpeechAudioBufferRecognitionRequest()
        guard let request = request else { throw NSError(domain: "Recitation", code: 1) }
        request.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.request?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()
        isListening = true

        recognitionTask = recognizer?.recognitionTask(with: request) { [weak self] result, error in
            guard let self = self else { return }
            if let result = result {
                let text = result.bestTranscription.formattedString.lowercased()
                self.lastTranscript = text
                self.updateCount(from: text)
            }
            if error != nil {
                self.stop()
            }
        }
    }

    func stop() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        request?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        request = nil
        isListening = false
    }

    private func updateCount(from transcript: String) {
        let normalized = transcript
            .replacingOccurrences(of: ",", with: " ")
            .replacingOccurrences(of: ".", with: " ")
            .replacingOccurrences(of: "  ", with: " ")
        let tokens = normalized.split(separator: " ").map { String($0) }

        let matchTokens: [String]
        switch target {
        case .alhamdulillah:
            matchTokens = ["alhamdulillah", "alhamdo", "alhamd", "alhamdolillah"]
        case .astaghfirullah:
            matchTokens = ["astaghfirullah", "astagfirullah", "astaghfirallah"]
        case .customDua:
            matchTokens = ["dua"]
        }

        let newMatches = tokens.filter { token in
            matchTokens.contains(where: { token.contains($0) })
        }.count

        // Heuristic: prevent runaway counting by limiting to growth per update
        let increment = min(max(newMatches - recognizedCount, 0), 3)
        if increment > 0 {
            recognizedCount += increment
        }
    }

    var reachedGoal: Bool { recognizedCount >= goalCount }
}


