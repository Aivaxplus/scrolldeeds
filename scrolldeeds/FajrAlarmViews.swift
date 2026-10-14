import SwiftUI
import UIKit

struct FajrAlarmSettingsView: View {
    @ObservedObject private var fajr = FajrAlarmManager.shared
    @Environment(\.dismiss) private var dismiss

    private var hasObject: Bool { fajr.selectedObject != nil }

    var body: some View {
        NavigationView {
            ZStack {
                SDPageBackground()
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        heroCard
                        systemStatusCard
                        timeCard
                        objectCard
                        howItWorksCard

                        Text(NSLocalizedString("fajr.setup.footer", comment: "Turn off or change anytime."))
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundColor(AppTheme.textMuted)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, 4)
                            .padding(.bottom, 28)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
            }
            .navigationTitle(NSLocalizedString("fajr.setup.title", comment: "Fajr alarm"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(NSLocalizedString("fajr.setup.done", comment: "Done")) {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .navigationViewStyle(.stack)
        .onAppear { fajr.refreshSystemAlarmStatus() }
    }

    private var systemStatusCard: some View {
        let status = fajr.systemAlarmStatus
        let icon: String
        let tint: Color
        let title: String
        let body: String
        var action: (title: String, run: () -> Void)?
        switch status {
        case .systemAlarm:
            icon = "checkmark.seal.fill"
            tint = AppTheme.primary
            title = NSLocalizedString("fajr.status.system_title", comment: "Real iOS alarm")
            body = NSLocalizedString("fajr.status.system_body", comment: "")
        case .needsPermission:
            icon = "alarm.waves.left.and.right"
            tint = AppTheme.primary
            title = NSLocalizedString("fajr.status.permission_title", comment: "Allow alarms")
            body = NSLocalizedString("fajr.status.permission_body", comment: "")
            action = (NSLocalizedString("fajr.status.permission_cta", comment: "Allow"), { fajr.requestSystemAlarmPermission() })
        case .denied:
            icon = "exclamationmark.triangle.fill"
            tint = .orange
            title = NSLocalizedString("fajr.status.denied_title", comment: "Alarms are off")
            body = NSLocalizedString("fajr.status.denied_body", comment: "")
            action = (NSLocalizedString("fajr.status.open_settings", comment: "Open Settings"), { fajr.openAppSettings() })
        case .legacy:
            icon = "info.circle.fill"
            tint = AppTheme.textSecondary
            title = NSLocalizedString("fajr.status.legacy_title", comment: "Older iOS")
            body = NSLocalizedString("fajr.status.legacy_body", comment: "")
        }

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(tint)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)
                    Text(body)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            if let action {
                Button {
                    HapticManager.shared.buttonTap()
                    action.run()
                } label: {
                    Text(action.title)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(tint))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(AppTheme.card))
    }

    private var heroCard: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(fajr.isArmed ? 0.22 : 0.9))
                    .frame(width: 52, height: 52)
                Image(systemName: fajr.isArmed ? "alarm.fill" : "alarm")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(fajr.isArmed ? .white : AppTheme.primary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(fajr.timeLabel)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(fajr.isArmed ? .white : AppTheme.textPrimary)
                Text(statusLine)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(fajr.isArmed ? Color.white.opacity(0.85) : AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 8)

            Toggle(
                "",
                isOn: Binding(
                    get: { fajr.isEnabled },
                    set: { on in
                        HapticManager.shared.buttonTap()
                        fajr.setEnabled(on)
                    }
                )
            )
            .labelsHidden()
            .tint(fajr.isArmed ? Color.white.opacity(0.35) : AppTheme.primary)
            .disabled(!hasObject)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(fajr.isArmed ? AnyShapeStyle(AppTheme.primary) : AnyShapeStyle(AppTheme.card))
        )
        .animation(.easeInOut(duration: 0.25), value: fajr.isArmed)
    }

    private var statusLine: String {
        if fajr.isArmed {
            return String(format: NSLocalizedString("fajr.setup.status_on", comment: "On · %@"), fajr.objectName)
        }
        if !hasObject {
            return NSLocalizedString("fajr.setup.need_select", comment: "Choose an object first")
        }
        return NSLocalizedString("fajr.setup.status_off", comment: "Off")
    }

    private var timeCard: some View {
        HStack {
            Label {
                Text(NSLocalizedString("fajr.setup.time_label", comment: "Wake time"))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
            } icon: {
                Image(systemName: "sunrise.fill")
                    .foregroundColor(AppTheme.primary)
            }
            Spacer()
            DatePicker(
                "",
                selection: Binding(
                    get: { fajr.fajrTime },
                    set: { fajr.setFajrTime($0) }
                ),
                displayedComponents: .hourAndMinute
            )
            .labelsHidden()
            .tint(AppTheme.primary)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(AppTheme.card))
    }

    private var objectCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(NSLocalizedString("fajr.setup.object_title", comment: "Your object"))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                Text(NSLocalizedString("fajr.setup.object_body", comment: "You photograph this to stop the alarm."))
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(AppTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            objectPicker
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(AppTheme.card))
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
                            .frame(width: 18)
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

    private var howItWorksCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(NSLocalizedString("fajr.setup.how_title", comment: "How it works"))
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)
            howRow(
                icon: "bell.fill",
                text: String(format: NSLocalizedString("fajr.setup.how1", comment: ""), fajr.timeLabel)
            )
            howRow(
                icon: "camera.fill",
                text: String(format: NSLocalizedString("fajr.setup.how2", comment: ""), fajr.objectName)
            )
            howRow(
                icon: "sparkles",
                text: NSLocalizedString("fajr.setup.how3", comment: "")
            )
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(AppTheme.card))
    }

    private func howRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppTheme.primary)
                .frame(width: 28, height: 28)
                .background(Circle().fill(AppTheme.primary.opacity(0.12)))
            Text(text)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(AppTheme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)
            Spacer(minLength: 0)
        }
    }
}

struct FajrAlarmRingingView: View {
    @ObservedObject private var fajr = FajrAlarmManager.shared
    @State private var showCamera = false
    @State private var pulse = false

    var body: some View {
        ZStack {
            SDPageBackground()

            VStack(spacing: 0) {
                Spacer(minLength: 24)

                Text(NSLocalizedString("fajr.ring.title", comment: "Fajr"))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.primary)
                    .textCase(.uppercase)
                    .tracking(1.4)

                Text(fajr.timeLabel)
                    .font(.system(size: 64, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                    .padding(.top, 6)
                    .scaleEffect(pulse ? 1.04 : 1.0)
                    .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: pulse)

                Text(String(format: NSLocalizedString("fajr.ring.body", comment: "Photograph your %@ to stop the alarm."), fajr.objectName))
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 10)

                ZStack {
                    Circle()
                        .fill(AppTheme.primary.opacity(0.10))
                        .frame(width: 150, height: 150)
                    Image(systemName: fajr.selectedObject?.symbolName ?? "camera.fill")
                        .font(.system(size: 54, weight: .semibold))
                        .foregroundColor(AppTheme.primary)
                }
                .padding(.top, 28)

                Group {
                    if fajr.didSucceedThisRing {
                        Text(NSLocalizedString("fajr.ring.success", comment: "You got up."))
                            .foregroundColor(AppTheme.primary)
                    } else if fajr.lastMatchFailed {
                        Text(String(format: NSLocalizedString("fajr.ring.mismatch_object", comment: "That doesn't look like your %@."), fajr.objectName))
                            .foregroundColor(AppTheme.statusNegative)
                    } else {
                        Text(" ")
                    }
                }
                .font(.system(size: 15, weight: .semibold))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
                .padding(.top, 16)
                .frame(minHeight: 44)

                Spacer()

                if !fajr.didSucceedThisRing {
                    Button {
                        HapticManager.shared.buttonTap()
                        showCamera = true
                    } label: {
                        HStack(spacing: 10) {
                            if fajr.isCheckingMatch {
                                SwiftUI.ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "camera.fill")
                            }
                            Text(
                                fajr.isCheckingMatch
                                    ? NSLocalizedString("fajr.ring.checking", comment: "Checking…")
                                    : String(format: NSLocalizedString("fajr.ring.cta", comment: "Photograph your %@"), fajr.objectName)
                            )
                        }
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(AppTheme.primary)
                        .cornerRadius(16)
                    }
                    .disabled(fajr.isCheckingMatch)
                    .padding(.horizontal, 24)

                    Button {
                        HapticManager.shared.soft()
                        fajr.snoozeFiveMinutes()
                    } label: {
                        Text(NSLocalizedString("fajr.ring.snooze", comment: "Snooze 5 minutes"))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .padding(.top, 14)
                    .padding(.bottom, 36)
                }
            }

            if fajr.isCheckingMatch {
                Color.black.opacity(0.18).ignoresSafeArea()
                VStack(spacing: 12) {
                    SwiftUI.ProgressView()
                        .scaleEffect(1.2)
                    Text(NSLocalizedString("fajr.ring.checking", comment: "Checking…"))
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(AppTheme.textPrimary)
                }
                .padding(24)
                .background(.ultraThinMaterial)
                .cornerRadius(18)
            }
        }
        .interactiveDismissDisabled()
        .overlay(alignment: .topTrailing) {
            if !fajr.didSucceedThisRing {
                Button {
                    HapticManager.shared.soft()
                    fajr.dismissWithoutPhoto()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(AppTheme.textSecondary)
                        .frame(width: 36, height: 36)
                        .background(Color.primary.opacity(0.06))
                        .clipShape(Circle())
                }
                .padding(.top, 12)
                .padding(.trailing, 16)
                .accessibilityLabel(NSLocalizedString("fajr.ring.dismiss", comment: "Dismiss alarm"))
            }
        }
        .onAppear { pulse = true }
        .fullScreenCover(isPresented: $showCamera) {
            CameraCaptureView(
                objectName: fajr.objectName,
                objectSymbol: fajr.selectedObject?.symbolName ?? "camera.fill"
            ) { image in
                showCamera = false
                if let image {
                    fajr.tryDismiss(with: image)
                }
            }
        }
    }
}
