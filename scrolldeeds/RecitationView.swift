//
//  RecitationView.swift
//  scrolldeeds
//
//  UI for reciting and unlocking time.
//

import SwiftUI

struct RecitationView: View {
    enum Mode: String, CaseIterable, Identifiable {
        case alhamdulillah = "Alhamdulillah"
        case astaghfirullah = "Astaghfirullah"
        case dua = "Make a Dua"
        var id: String { rawValue }
    }

    @ObservedObject var detector: RecitationDetector
    let onCompleted: () -> Void

    @State private var mode: Mode = .alhamdulillah
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 16) {
            Picker("Mode", selection: $mode) {
                ForEach(Mode.allCases) { m in
                    Text(m.rawValue).tag(m)
                }
            }
            .pickerStyle(.segmented)

            // Get duration from UserDefaults (fallback to medium if not set)
            let level = UserDefaults.standard.string(forKey: "difficultyLevel").flatMap { DifficultyLevel(rawValue: $0) } ?? .medium
            Text("Say it 3 times to unlock \(level.displayDuration)")
                .font(.headline)

            Text("Count: \(detector.recognizedCount)/3")
                .font(.largeTitle)
                .bold()

            if !detector.lastTranscript.isEmpty {
                Text(detector.lastTranscript)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Button(action: toggleListening) {
                Text(detector.isListening ? "Stop" : "Start")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(detector.isListening ? Color.red : Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }

            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.footnote)
            }
        }
        .padding()
        .onChange(of: detector.recognizedCount) { _ in
            if detector.reachedGoal {
                detector.stop()
                onCompleted()
            }
        }
    }

    private func toggleListening() {
        if detector.isListening {
            detector.stop()
            return
        }
        do {
            let target: RecitationDetector.Target
            switch mode {
            case .alhamdulillah: target = .alhamdulillah
            case .astaghfirullah: target = .astaghfirullah
            case .dua: target = .customDua
            }
            try detector.start(target: target, goal: 3)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    RecitationView(detector: RecitationDetector(), onCompleted: {})
}


