//
//  PracticeSessionView.swift
//  scrolldeeds
//

import SwiftUI

// MARK: - Dhikr Types
enum DhikrType: String, CaseIterable {
    case alhamdulillah = "Alhamdulillah"
    case astaghfirullah = "Astaghfirullah"
    case allahuAkbar = "Allahu Akbar"
    case subhanallah = "Subhanallah"
    
    var instruction: String {
        switch self {
        case .alhamdulillah:
            return "Recite 'Alhamdulillah' 3 times"
        case .astaghfirullah:
            return "Recite 'Astaghfirullah' 3 times"
        case .allahuAkbar:
            return "Recite 'Allahu Akbar' 3 times"
        case .subhanallah:
            return "Recite 'Subhanallah' 3 times"
        }
    }
    
    var icon: String {
        switch self {
        case .alhamdulillah:
            return "hands.sparkles.fill"
        case .astaghfirullah:
            return "heart.fill"
        case .allahuAkbar:
            return "star.fill"
        case .subhanallah:
            return "moon.stars.fill"
        }
    }
    
    var description: String {
        switch self {
        case .alhamdulillah:
            return "All praise is due to Allah"
        case .astaghfirullah:
            return "I seek forgiveness from Allah"
        case .allahuAkbar:
            return "Allah is the Greatest"
        case .subhanallah:
            return "Glory be to Allah"
        }
    }
    
    static func random() -> DhikrType {
        return DhikrType.allCases.randomElement() ?? .alhamdulillah
    }
}

struct PracticeSessionView: View {
    @ObservedObject var detector: RecitationDetector
    let onCompleted: () -> Void
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var audioRecorder = AudioRecorderManager()
    @StateObject private var webhookService = WebhookService()
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @ObservedObject var userDataManager: UserDataManager
    @State private var showVerificationSheet = false
    @State private var verificationMessage = ""
    @State private var selectedDhikr: DhikrType
    @State private var hasGrantedGraceUnlock = false
    @State private var shouldUnlockAfterAlert = false
    @State private var showPaywall = false
    @State private var hasCompletedFirstDhikr = false
    
    // Initialize with random dhikr
    init(detector: RecitationDetector, userDataManager: UserDataManager, onCompleted: @escaping () -> Void) {
        self.detector = detector
        self.userDataManager = userDataManager
        self.onCompleted = onCompleted
        _selectedDhikr = State(initialValue: DhikrType.random())
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Unlock with Dhikr")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                        HStack(spacing: 6) {
                            Image(systemName: selectedDhikr.icon)
                                .font(.system(size: 14))
                            Text(selectedDhikr.rawValue)
                                .font(.system(size: 16))
                        }
                        .foregroundColor(AppTheme.textSecondary)
                    }
                    Spacer()
                    Button(action: {
                        HapticManager.shared.soft()
                        detector.stop()
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(AppTheme.textMuted)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                
                // Accountability Warning Badge - Akhira Reminder
                VStack(spacing: 8) {
                    HStack(spacing: 10) {
                        Image(systemName: "hourglass")
                            .font(.system(size: 16))
                            .foregroundColor(.orange)
                        
                        Text("Don't Waste Your Time")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(AppTheme.textPrimary)
                        
                        Spacer()
                    }
                    
                    Text("You will be questioned about every wasted moment in the Akhira. Use your time wisely.")
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.orange.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Dhikr Instruction Card - NOW FIRST!
                        VStack(spacing: 16) {
                            Image(systemName: selectedDhikr.icon)
                                .font(.system(size: 42))
                                .foregroundColor(AppTheme.primary)
                            
                            Text(selectedDhikr.rawValue)
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)
                            
                            Text(selectedDhikr.description)
                                .font(.system(size: 15))
                                .foregroundColor(AppTheme.textSecondary)
                                .multilineTextAlignment(.center)
                            
                            Divider()
                                .padding(.vertical, 4)
                            
                            Text(selectedDhikr.instruction)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppTheme.primary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 28)
                        .padding(.horizontal, 24)
                        .background(AppTheme.card)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.04), radius: 10, y: 5)
                        .padding(.horizontal, 24)
                        
                        // Recording Button - NOW CENTERED BELOW DHIKR!
                        Button(action: {
                            if !webhookService.isVerifying {
                                // Haptic feedback based on state
                                if audioRecorder.isRecording {
                                    HapticManager.shared.recordingStopped()
                                } else {
                                    HapticManager.shared.recordingStarted()
                                }
                                toggleRecording()
                            }
                        }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 28)
                                    .fill(
                                        audioRecorder.isRecording ?
                                        LinearGradient(colors: [AppTheme.error, AppTheme.error.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                        webhookService.isVerifying ?
                                        LinearGradient(colors: [AppTheme.primary, AppTheme.primary.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                                        AppTheme.gradientPrimary
                                    )
                                    .shadow(
                                        color: (audioRecorder.isRecording ? AppTheme.error : AppTheme.primary).opacity(0.4),
                                        radius: 24,
                                        y: 12
                                    )
                                
                                VStack(spacing: 16) {
                                    if audioRecorder.isRecording {
                                        // Recording state
                                        HStack(spacing: 8) {
                                            Circle()
                                                .fill(Color.white)
                                                .frame(width: 12, height: 12)
                                                .opacity(audioRecorder.isRecording ? 1 : 0)
                                                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: audioRecorder.isRecording)
                                            Text("Recording...")
                                                .font(.system(size: 16, weight: .semibold))
                                        }
                                        .foregroundColor(AppTheme.textOnDark)
                                        
                                        Text(formatTime(audioRecorder.recordingTime))
                                            .font(.system(size: 64, weight: .bold, design: .rounded))
                                            .foregroundColor(AppTheme.textOnDark)
                                            .monospacedDigit()
                                        
                                        HStack(spacing: 8) {
                                            Image(systemName: "stop.circle.fill")
                                                .font(.system(size: 20))
                                            Text("Tap to Stop & Verify")
                                                .font(.system(size: 16, weight: .semibold))
                                        }
                                        .foregroundColor(AppTheme.textOnDark.opacity(0.9))
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 12)
                                        .background(Color.white.opacity(0.2))
                                        .cornerRadius(20)
                                        
                                    } else if webhookService.isVerifying {
                                        // Verifying state
                                        SwiftUI.ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(2.0)
                                            .padding(.bottom, 8)
                                        
                                        Text("Verifying...")
                                            .font(.system(size: 24, weight: .bold))
                                            .foregroundColor(AppTheme.textOnDark)
                                        
                                        Text("AI is checking your recitation")
                                            .font(.system(size: 15))
                                            .foregroundColor(AppTheme.textOnDark.opacity(0.85))
                                        
                                    } else {
                                        // Ready state
                                        Image(systemName: "mic.circle.fill")
                                            .font(.system(size: 80))
                                            .foregroundColor(AppTheme.textOnDark)
                                            .padding(.bottom, 8)
                                        
                                        Text("Tap to Start Recording")
                                            .font(.system(size: 22, weight: .bold))
                                            .foregroundColor(AppTheme.textOnDark)
                                        
                                        Text("Recite your dhikr clearly")
                                            .font(.system(size: 15, weight: .medium))
                                            .foregroundColor(AppTheme.textOnDark.opacity(0.85))
                                    }
                                }
                                .padding(.vertical, 40)
                                .padding(.horizontal, 20)
                            }
                            .frame(height: 260)
                        }
                        .disabled(webhookService.isVerifying)
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal, 24)
                        
                        // Tips Card
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 8) {
                                Image(systemName: "lightbulb.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(AppTheme.accent)
                                Text("Tips for Best Results")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(AppTheme.textPrimary)
                            }
                            
                            VStack(alignment: .leading, spacing: 10) {
                                tipRow("Speak clearly and at a steady pace")
                                tipRow("Find a quiet environment")
                                tipRow("Focus on the meaning as you recite")
                                tipRow("Take your time - quality over speed")
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                        .background(AppTheme.card)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.04), radius: 10, y: 5)
                        .padding(.horizontal, 24)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .overlay {
            if showVerificationSheet {
                CustomAlertView(
                    title: "Verification Result",
                    message: verificationMessage,
                    icon: verificationMessage.contains("✅") ? "checkmark.circle.fill" : verificationMessage.contains("⚠️") ? "exclamationmark.triangle.fill" : "xmark.circle.fill",
                    iconColor: verificationMessage.contains("✅") ? .green : verificationMessage.contains("⚠️") ? .orange : .red,
                    isPresented: $showVerificationSheet,
                    primaryAction: {
                        if shouldUnlockAfterAlert {
                            shouldUnlockAfterAlert = false
                            onCompleted()
                            dismiss()
                        }
                    },
                    primaryActionTitle: "OK"
                )
            }
        }
        .fullScreenCover(isPresented: $showPaywall) {
            HardPaywallView(onSubscribed: {
                showPaywall = false
                // User purchased - they need to manually press mic button again
                // Show success message instead of auto-proceeding
                HapticManager.shared.success()
                verificationMessage = "🎉 JazakAllahu Khayran!\n\nYou're now a Premium member. Press the microphone button to start your dhikr and unlock your apps."
                showVerificationSheet = true
            })
        }
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private func tipRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(AppTheme.primary.opacity(0.2))
                .frame(width: 6, height: 6)
                .padding(.top, 6)
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(AppTheme.textSecondary)
                .lineSpacing(3)
            Spacer()
        }
    }

    private func toggleRecording() {
        if audioRecorder.isRecording {
            // Show verifying state IMMEDIATELY when button is pressed
            webhookService.isVerifying = true
            
            // Stop recording (with completion handler)
            audioRecorder.stopRecording {
                // Get audio data after recording has fully stopped
                guard let audioData = self.audioRecorder.getAudioData() else {
                    DispatchQueue.main.async {
                        self.webhookService.isVerifying = false
                        self.verificationMessage = "Failed to get audio data. Please try recording again."
                        self.showVerificationSheet = true
                    }
                    return
                }
                
                debugPrint("PracticeSessionView: Sending \(audioData.count) bytes to webhook")
                debugPrint("PracticeSessionView: Dhikr type: \(self.selectedDhikr.rawValue)")
                
                // Send to webhook for verification with dhikr type
                // Use background queue for network request to avoid blocking UI
                DispatchQueue.global(qos: .userInitiated).async {
                    self.webhookService.verifyDhikrRecording(audioData: audioData, dhikrType: self.selectedDhikr.rawValue) { result in
                        DispatchQueue.main.async {
                            self.handleVerificationResult(result)
                        }
                    }
                }
                
                // For testing only, use mock verification:
                // self.webhookService.mockVerification(success: true) { result in
                //     DispatchQueue.main.async {
                //         self.handleVerificationResult(result)
                //     }
                // }
            }
            
        } else {
            // Check if user is premium before starting recording
            if !subscriptionManager.isPremium {
                // Show paywall for non-premium users
                showPaywall = true
                return
            }
            
            // Start recording (only if premium)
            audioRecorder.startRecording()
        }
    }
    
    // Check premium status when paywall is dismissed
    private func checkPremiumAndUnlock() {
        if subscriptionManager.isPremium {
            // User purchased premium - proceed with unlock
            let level = UserDefaults.standard.string(forKey: "difficultyLevel").flatMap { DifficultyLevel(rawValue: $0) } ?? .medium
            verificationMessage = "✅ Verified! Alhamdulillah\n\nYou've unlocked \(level.displayDuration). Remember: In the Akhira, you will be questioned about every second you waste."
            shouldUnlockAfterAlert = true
            showVerificationSheet = true
        }
    }
    
    private func handleVerificationResult(_ result: VerificationResult) {
        switch result {
        case .approved:
            HapticManager.shared.dhikrVerified()
            
            // Mark that user has completed first dhikr
            hasCompletedFirstDhikr = true
            
            // Check if user is premium - if not, show paywall
            // ScrollDeeds has no free version, only a 1 month free trial for yearly subscription
            if !subscriptionManager.isPremium {
                showPaywall = true
                return
            }
            
            // Premium user - proceed with unlock
            // Get duration from UserDefaults (fallback to medium if not set)
            let level = UserDefaults.standard.string(forKey: "difficultyLevel").flatMap { DifficultyLevel(rawValue: $0) } ?? .medium
            verificationMessage = "✅ Verified! Alhamdulillah\n\nYou've unlocked \(level.displayDuration). Remember: In the Akhira, you will be questioned about every second you waste."
            shouldUnlockAfterAlert = true
            showVerificationSheet = true
            
        case .rejected(let reason):
            // Reason is already cleaned by WebhookService
            if !hasGrantedGraceUnlock {
                hasGrantedGraceUnlock = true
                HapticManager.shared.dhikrVerified()
                verificationMessage = "⚠️ \(reason)\n\nWe unlocked your apps this time so you can continue. Stay mindful and aim for a perfect recitation next session."
                shouldUnlockAfterAlert = true
            } else {
                HapticManager.shared.error()
                verificationMessage = "❌ \(reason)\n\nRecite your dhikr clearly and sincerely. Try again."
            }
            showVerificationSheet = true
            audioRecorder.deleteRecording()
            
        case .error(let error):
            // Error messages are already user-friendly from WebhookService
            if !hasGrantedGraceUnlock {
                hasGrantedGraceUnlock = true
                HapticManager.shared.dhikrVerified()
                verificationMessage = "⚠️ \(error)\n\nWe unlocked your apps this time so you can continue. Please try again next time."
                shouldUnlockAfterAlert = true
            } else {
                HapticManager.shared.error()
                verificationMessage = "⚠️ \(error)\n\nPlease check your connection and try again."
            }
            showVerificationSheet = true
            audioRecorder.deleteRecording()
        }
    }
}

#Preview {
    PracticeSessionView(detector: RecitationDetector(), userDataManager: UserDataManager(), onCompleted: {})
}


