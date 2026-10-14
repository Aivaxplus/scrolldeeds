//
//  OnboardingBenefitsReflectionView.swift
//  scrolldeeds
//
//  HIDDEN (not deleted): benefits now runs as questionnaire step
//  `benefits_reflection` — same PrayerLock chrome as “ScrollDeeds helpt je…”.
//  Restore this standalone screen only if the funnel should exit the questionnaire again.
//

import SwiftUI

struct OnboardingBenefitsReflectionView: View {
    let onContinue: () -> Void

    var body: some View {
        // Kept for compile / easy restore. Funnel uses QuestionnaireView.prayerLock instead.
        Color.clear
            .onAppear { onContinue() }
    }
}
