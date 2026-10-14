//
//  HapticManager.swift
//  scrolldeeds
//
//  Semantic, contextual haptic feedback.
//  Every method has a clear meaning that matches the UI moment.
//

import UIKit
import SwiftUI

class HapticManager {
    static let shared = HapticManager()
    private init() {}

    // MARK: - Pre-warmed generators (lower latency)

    private let lightGen  = UIImpactFeedbackGenerator(style: .light)
    private let mediumGen = UIImpactFeedbackGenerator(style: .medium)
    private let heavyGen  = UIImpactFeedbackGenerator(style: .heavy)
    private let rigidGen  = UIImpactFeedbackGenerator(style: .rigid)
    private let softGen   = UIImpactFeedbackGenerator(style: .soft)
    private let notifGen  = UINotificationFeedbackGenerator()
    private let selectGen = UISelectionFeedbackGenerator()

    // MARK: - Base primitives (correct mapping)

    func light()     { lightGen.impactOccurred() }
    func medium()    { mediumGen.impactOccurred() }
    func heavy()     { heavyGen.impactOccurred() }
    func rigid()     { rigidGen.impactOccurred() }
    func soft()      { softGen.impactOccurred() }
    func selection() { selectGen.selectionChanged() }
    func success()   { notifGen.notificationOccurred(.success) }
    func warning()   { notifGen.notificationOccurred(.warning) }
    func error()     { notifGen.notificationOccurred(.error) }

    // MARK: - Dhikr / task tapping

    /// Called on every individual dhikr tap.
    /// Builds up from soft → medium → rigid as you approach the required count.
    /// Creates a satisfying crescendo that peaks on the final tap.
    func dhikrTap(count: Int, required: Int) {
        let fraction = Double(count) / Double(required)
        switch fraction {
        case ..<0.34: lightGen.impactOccurred()
        case ..<0.67: mediumGen.impactOccurred()
        default:      rigidGen.impactOccurred()
        }
    }

    /// Called when the user completes the final required tap.
    /// Two-beat: hard snap → success notification.
    func dhikrVerified() {
        heavyGen.impactOccurred()
        after(0.10) { self.notifGen.notificationOccurred(.success) }
    }

    // MARK: - Intention hold

    /// Subtle periodic pulse while the user holds the intention button.
    /// Light tick every ~0.6 s to signal progress without distraction.
    func intentionTick() {
        softGen.impactOccurred(intensity: 0.55)
    }

    /// Fired when the 3-second hold completes.
    /// Rising two-beat to signal readiness.
    func intentionCompleted() {
        mediumGen.impactOccurred()
        after(0.12) { self.heavyGen.impactOccurred() }
        after(0.28) { self.notifGen.notificationOccurred(.success) }
    }

    // MARK: - Task reveal

    /// Soft tick on each title change during the cycling animation.
    func taskCycling() {
        softGen.impactOccurred(intensity: 0.40)
    }

    /// Satisfying snap when the final task name lands.
    /// Rigid click + success feel.
    func taskLanded() {
        rigidGen.impactOccurred()
        after(0.12) { self.notifGen.notificationOccurred(.success) }
    }

    // MARK: - Task completion

    /// Called when the user taps "done" on a deed task (before the popup shows).
    /// Warm double-beat: medium then success.
    func taskCompleted() {
        mediumGen.impactOccurred()
        after(0.12) { self.notifGen.notificationOccurred(.success) }
    }

    /// Called when the completion overlay appears on screen.
    /// Soft arrival tap so the popup feels physical.
    func completionShown() {
        softGen.impactOccurred(intensity: 0.70)
    }

    // MARK: - Apps unlocking

    /// One clear beat: medium → heavy → success. Readable on device.
    func heartWelcomeCrescendo() {
        prepareHeartEngines()
        mediumGen.impactOccurred()
        after(0.18) { self.heavyGen.impactOccurred() }
        after(0.38) { self.notifGen.notificationOccurred(.success) }
    }

    /// Timed to the heart fill after a deed (~0.7s). Warm, short, not a fanfare stack.
    func heartUnlockFill(rankUp: Bool, pieceChanged: Bool) {
        prepareHeartEngines()
        softGen.impactOccurred(intensity: 0.58)
        after(0.11) { self.mediumGen.impactOccurred(intensity: 0.78) }

        if rankUp {
            after(0.30) { self.heavyGen.impactOccurred() }
            after(0.48) { self.notifGen.notificationOccurred(.success) }
        } else if pieceChanged {
            after(0.28) { self.mediumGen.impactOccurred(intensity: 1.0) }
            after(0.44) { self.softGen.impactOccurred(intensity: 0.82) }
        } else {
            after(0.26) { self.mediumGen.impactOccurred(intensity: 0.88) }
            after(0.42) { self.softGen.impactOccurred(intensity: 0.55) }
        }
    }

    func heartUpgraded() {
        heartUnlockFill(rankUp: true, pieceChanged: true)
    }

    /// Coins landing in the header pill: a few ticks, then a success beat as it fills.
    func coinsLanded() {
        prepareHeartEngines()
        lightGen.impactOccurred()
        after(0.09) { self.lightGen.impactOccurred() }
        after(0.18) { self.mediumGen.impactOccurred() }
        after(0.32) { self.notifGen.notificationOccurred(.success) }
    }

    /// Unlock click — lock opening. Bar-fill ticks follow separately.
    func appsUnlocked() {
        prepareHeartEngines()
        lightGen.impactOccurred()
        after(0.09) { self.mediumGen.impactOccurred() }
        after(0.20) { self.heavyGen.impactOccurred() }
    }

    /// Rigid single click — feels like a bolt sliding shut.
    func appsLocked() {
        rigidGen.impactOccurred()
        after(0.12) { self.mediumGen.impactOccurred(intensity: 0.5) }
    }

    // MARK: - Navigation / UI

    /// Tick timed to an on-screen animation beat (cards, titles, banners).
    func animationReveal(beat: Int = 0) {
        switch beat % 4 {
        case 0:
            softGen.impactOccurred(intensity: 0.80)
        case 1:
            lightGen.impactOccurred()
        case 2:
            selectGen.selectionChanged()
            softGen.impactOccurred(intensity: 0.42)
        default:
            mediumGen.impactOccurred(intensity: 0.52)
        }
    }

    func scheduleAnimationReveal(after delay: Double, beat: Int = 0) {
        after(delay) { self.animationReveal(beat: beat) }
    }

    /// One tick per typed character on onboarding explanation pages.
    func prepareTypewriter() {
        selectGen.prepare()
        softGen.prepare()
    }

    func typewriterTick(character: Character) {
        guard !character.isWhitespace else { return }
        selectGen.selectionChanged()
        softGen.impactOccurred(intensity: 0.22)
        selectGen.prepare()
    }

    /// Standard tap for buttons and row selections.
    func buttonTap() { lightGen.impactOccurred() }

    /// Forward navigation between steps / pages.
    func navigateForward() {
        lightGen.impactOccurred()
        after(0.06) { self.softGen.impactOccurred(intensity: 0.45) }
    }

    /// Backward navigation.
    func navigateBack() { softGen.impactOccurred() }

    /// Toggle switched on — positive click.
    func toggleOn() {
        mediumGen.impactOccurred()
        after(0.08) { self.softGen.impactOccurred(intensity: 0.5) }
    }

    /// Toggle switched off — softer click.
    func toggleOff() { lightGen.impactOccurred() }

    /// Destructive action (delete / remove).
    func destructive() {
        rigidGen.impactOccurred()
        after(0.10) { self.notifGen.notificationOccurred(.warning) }
    }

    // MARK: - Onboarding

    /// Completing the full onboarding flow.
    func onboardingComplete() {
        appsUnlocked()
    }

    /// Advancing one onboarding step.
    func onboardingNext() { navigateForward() }

    /// Going back one step.
    func onboardingBack() { navigateBack() }

    // MARK: - Settings

    func reminderAdded()   { toggleOn() }
    func reminderDeleted() { destructive() }
    func appearanceChanged() { selection() }

    // MARK: - Legacy aliases (kept for remaining call sites)

    func recordingStarted() { heavyGen.impactOccurred() }
    func recordingStopped() { mediumGen.impactOccurred() }

    // MARK: - Private

    /// Soft ticks while the XP bar fills. `completed` lands with success when the rank bar is full.
    func heartBarFilling(completed: Bool = false) {
        prepareHeartEngines()
        softGen.impactOccurred(intensity: 0.50)
        after(0.14) { self.lightGen.impactOccurred() }
        after(0.28) { self.mediumGen.impactOccurred(intensity: 0.70) }
        after(0.44) { self.mediumGen.impactOccurred(intensity: 0.90) }
        after(0.62) { self.rigidGen.impactOccurred() }
        if completed {
            after(0.84) { self.notifGen.notificationOccurred(.success) }
        } else {
            after(0.80) { self.softGen.impactOccurred(intensity: 0.78) }
        }
    }

    private func prepareHeartEngines() {
        lightGen.prepare()
        mediumGen.prepare()
        heavyGen.prepare()
        rigidGen.prepare()
        softGen.prepare()
        notifGen.prepare()
    }

    private func after(_ delay: Double, _ block: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: block)
    }
}

// MARK: - SwiftUI View Extension

extension View {
    func haptic(_ style: HapticStyle) -> some View {
        self.simultaneousGesture(
            TapGesture().onEnded { _ in HapticManager.shared.trigger(style) }
        )
    }
}

enum HapticStyle {
    case light, medium, heavy, soft, rigid
    case success, warning, error, selection
}

extension HapticManager {
    func trigger(_ style: HapticStyle) {
        switch style {
        case .light:     light()
        case .medium:    medium()
        case .heavy:     heavy()
        case .soft:      soft()
        case .rigid:     rigid()
        case .success:   success()
        case .warning:   warning()
        case .error:     error()
        case .selection: selection()
        }
    }
}
