//
//  ReminderSettingsView.swift
//  scrolldeeds
//
//  Daily dhikr reminder settings
//

import SwiftUI

struct ReminderSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var notificationManager = NotificationManager.shared
    
    @State private var reminderTimes: [Date] = []
    @State private var showingAddTime = false
    @State private var newReminderTime = Date()
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 12) {
                                Image(systemName: "bell.badge.fill")
                                    .font(.system(size: 32))
                                    .foregroundColor(AppTheme.primary)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Daily Dhikr Reminders")
                                        .font(.system(size: 24, weight: .bold))
                                        .foregroundColor(AppTheme.textPrimary)
                                    
                                    Text("Stay consistent with mindful unlocking")
                                        .font(.system(size: 14))
                                        .foregroundColor(AppTheme.textSecondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text("Set up to 3 daily reminders to practice dhikr and unlock your apps mindfully. You'll get a gentle notification to help build your habit.")
                                .font(.system(size: 15))
                                .foregroundColor(AppTheme.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Reminder Times List
                        VStack(spacing: 16) {
                            if reminderTimes.isEmpty {
                                VStack(spacing: 16) {
                                    Image(systemName: "clock.badge.questionmark")
                                        .font(.system(size: 48))
                                        .foregroundColor(AppTheme.textMuted)
                                    
                                    Text("No Reminders Set")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(AppTheme.textSecondary)
                                    
                                    Text("Add your first reminder to build a consistent dhikr habit")
                                        .font(.system(size: 14))
                                        .foregroundColor(AppTheme.textMuted)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal, 40)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                                .background(AppTheme.card)
                                .cornerRadius(16)
                                .padding(.horizontal, 20)
                            } else {
                                VStack(spacing: 12) {
                                    ForEach(reminderTimes.indices, id: \.self) { index in
                                        HStack(spacing: 16) {
                                            Image(systemName: "clock.fill")
                                                .font(.system(size: 20))
                                                .foregroundColor(AppTheme.primary)
                                                .frame(width: 32)
                                            
                                            Text(reminderTimes[index], style: .time)
                                                .font(.system(size: 18, weight: .medium))
                                                .foregroundColor(AppTheme.textPrimary)
                                            
                                            Spacer()
                                            
                                            Button(action: {
                                                HapticManager.shared.reminderDeleted()
                                                removeReminder(at: index)
                                            }) {
                                                Image(systemName: "trash.fill")
                                                    .font(.system(size: 18))
                                                    .foregroundColor(.red.opacity(0.8))
                                                    .frame(width: 32, height: 32)
                                            }
                                        }
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 14)
                                        .background(AppTheme.card)
                                        .cornerRadius(12)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                            
                            // Add Button
                            if reminderTimes.count < 3 {
                                Button(action: {
                                    showingAddTime = true
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(AppTheme.primary)
                                        
                                        Text(reminderTimes.isEmpty ? "Add Your First Reminder" : "Add Another Reminder")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(AppTheme.textPrimary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(AppTheme.card)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(AppTheme.primary.opacity(0.3), lineWidth: 2)
                                    )
                                }
                                .padding(.horizontal, 20)
                            } else {
                                Text("Maximum 3 reminders reached")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppTheme.textMuted)
                                    .padding(.vertical, 8)
                            }
                        }
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        saveReminders()
                        dismiss()
                    }
                    .foregroundColor(AppTheme.primary)
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingAddTime) {
                NavigationView {
                    ZStack {
                        AppTheme.background.ignoresSafeArea()
                        
                        VStack(spacing: 24) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Choose Time")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(AppTheme.textPrimary)
                                
                                Text("Pick a time that works best for you")
                                    .font(.system(size: 14))
                                    .foregroundColor(AppTheme.textSecondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            
                            DatePicker(
                                "Reminder Time",
                                selection: $newReminderTime,
                                displayedComponents: .hourAndMinute
                            )
                            .datePickerStyle(.wheel)
                            .labelsHidden()
                            .padding(.horizontal)
                            
                            Spacer()
                        }
                    }
                    .navigationTitle("Add Reminder")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel") {
                                showingAddTime = false
                            }
                            .foregroundColor(AppTheme.textSecondary)
                        }
                        
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Add") {
                                HapticManager.shared.reminderAdded()
                                reminderTimes.append(newReminderTime)
                                showingAddTime = false
                            }
                            .foregroundColor(AppTheme.primary)
                            .fontWeight(.semibold)
                        }
                    }
                }
            }
            .onAppear {
                loadReminders()
            }
        }
    }
    
    private func loadReminders() {
        if let data = UserDefaults.standard.data(forKey: "reminderTimes"),
           let times = try? JSONDecoder().decode([Date].self, from: data) {
            reminderTimes = times
        }
    }
    
    private func saveReminders() {
        if let encoded = try? JSONEncoder().encode(reminderTimes) {
            UserDefaults.standard.set(encoded, forKey: "reminderTimes")
        }
        
        // Convert to DateComponents and schedule
        let components = reminderTimes.map { date in
            Calendar.current.dateComponents([.hour, .minute], from: date)
        }
        
        notificationManager.scheduleDailyReminders(times: components)
    }
    
    private func removeReminder(at index: Int) {
        withAnimation {
            reminderTimes.remove(at: index)
        }
    }
}

#Preview {
    ReminderSettingsView()
}

