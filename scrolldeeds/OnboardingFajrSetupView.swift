//
//  OnboardingFajrSetupView.swift
//  scrolldeeds
//
//  Optional Fajr alarm setup: time + object. Morning photo is checked by AI.
//

import SwiftUI

struct OnboardingFajrSetupView: View {
    var onReady: () -> Void

    @ObservedObject private var fajr = FajrAlarmManager.shared
    @State private var appeared = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(NSLocalizedString("questionnaire.fajr_setup.title", comment: ""))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(NSLocalizedString("questionnaire.fajr_setup.subtitle", comment: ""))
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 4)

                stepCard(
                    number: 1,
                    title: NSLocalizedString("fajr.setup.step1_title", comment: "")
                ) {
                    DatePicker(
                        "",
                        selection: Binding(
                            get: { fajr.fajrTime },
                            set: { fajr.setFajrTime($0) }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                    .datePickerStyle(.wheel)
                    .labelsHidden()
                    .frame(maxWidth: .infinity)
                    .frame(height: 108)
                    .clipped()
                }

                stepCard(
                    number: 2,
                    title: NSLocalizedString("fajr.setup.step2_title", comment: "")
                ) {
                    objectPicker
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(NSLocalizedString("questionnaire.fajr_setup.how_title", comment: ""))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)
                    Text(
                        String(
                            format: NSLocalizedString("questionnaire.fajr_setup.how_body", comment: ""),
                            fajr.objectName
                        )
                    )
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(AppTheme.card)
                )

                Text(NSLocalizedString("questionnaire.fajr_setup.later", comment: ""))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(AppTheme.textMuted)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 8)
            }
            .padding(.horizontal, 24)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            onReady()
            withAnimation(.easeOut(duration: 0.35)) {
                appeared = true
            }
        }
    }

    private var objectPicker: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
            ForEach(FajrWakeObject.allCases) { object in
                let selected = fajr.selectedObject == object
                Button {
                    HapticManager.shared.soft()
                    fajr.setSelectedObject(object)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: object.symbolName)
                            .font(.system(size: 14, weight: .semibold))
                        Text(object.localizedName)
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        Spacer(minLength: 0)
                    }
                    .foregroundColor(selected ? AppTheme.primary : AppTheme.textPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 11)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(selected ? AppTheme.primary.opacity(0.12) : AppTheme.muted.opacity(0.55))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(selected ? AppTheme.primary : Color.clear, lineWidth: 1.5)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func stepCard<Content: View>(
        number: Int,
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Text("\(number)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(AppTheme.primary))
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
            }
            content()
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(AppTheme.card)
        )
    }
}
