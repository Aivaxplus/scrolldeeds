//
//  LocalStorageManager.swift
//  scrolldeeds
//
//  Manages all local storage using UserDefaults
//

import Foundation
import Combine

class LocalStorageManager: ObservableObject {
    static let shared = LocalStorageManager()
    private let defaults = UserDefaults.standard
    
    // MARK: - Published Properties
    @Published var hasCompletedOnboarding: Bool
    @Published var hasSeenQuickGuide: Bool
    @Published var hasSeenDashboardTutorial: Bool
    /// Bump when the in-app tour gains new steps so existing users see it once more.
    private static let dashboardTutorialRevision = 3
    @Published var onboardingScrollHours: Int
    @Published var referralCode: String
    
    private init() {
        // Load via the Published wrapper so init does not emit objectWillChange.
        _hasCompletedOnboarding = Published(initialValue: defaults.bool(forKey: Keys.hasCompletedOnboarding))
        _hasSeenQuickGuide = Published(initialValue: defaults.bool(forKey: Keys.hasSeenQuickGuide))
        _hasSeenDashboardTutorial = Published(initialValue: defaults.bool(forKey: Keys.hasSeenDashboardTutorial))
        _onboardingScrollHours = Published(initialValue: defaults.integer(forKey: Keys.onboardingScrollHours))
        _referralCode = Published(initialValue: defaults.string(forKey: Keys.referralCode) ?? "")
        setupObservers()
    }
    
    private func setupObservers() {
        // Save to UserDefaults when values change
        $hasCompletedOnboarding.dropFirst().sink { [weak self] value in
            self?.defaults.set(value, forKey: Keys.hasCompletedOnboarding)
        }.store(in: &cancellables)
        
        $hasSeenQuickGuide.dropFirst().sink { [weak self] value in
            self?.defaults.set(value, forKey: Keys.hasSeenQuickGuide)
        }.store(in: &cancellables)

        $hasSeenDashboardTutorial.dropFirst().sink { [weak self] value in
            self?.defaults.set(value, forKey: Keys.hasSeenDashboardTutorial)
        }.store(in: &cancellables)
        
        $onboardingScrollHours.dropFirst().sink { [weak self] value in
            self?.defaults.set(value, forKey: Keys.onboardingScrollHours)
        }.store(in: &cancellables)

        $referralCode.dropFirst().sink { [weak self] value in
            self?.defaults.set(value, forKey: Keys.referralCode)
        }.store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Keys
    private enum Keys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let hasSeenQuickGuide = "hasSeenQuickGuide"
        static let hasSeenDashboardTutorial = "hasSeenDashboardTutorial"
        static let dashboardTutorialRevision = "dashboardTutorialRevision"
        static let onboardingScrollHours = "onboardingScrollHours"
        static let onboardingAnswers = "onboardingAnswers"
        static let referralCode = "referralCode"
    }
    
    // MARK: - Onboarding Methods
    func saveOnboardingAnswers(_ answers: [Int: Int]) {
        if let encoded = try? JSONEncoder().encode(answers) {
            defaults.set(encoded, forKey: Keys.onboardingAnswers)
        }
    }
    
    func loadOnboardingAnswers() -> [Int: Int] {
        guard let data = defaults.data(forKey: Keys.onboardingAnswers),
              let answers = try? JSONDecoder().decode([Int: Int].self, from: data) else {
            return [:]
        }
        return answers
    }
    
    var needsDashboardTutorial: Bool {
        if !hasSeenDashboardTutorial { return true }
        return defaults.integer(forKey: Keys.dashboardTutorialRevision) < Self.dashboardTutorialRevision
    }

    func markDashboardTutorialSeen() {
        hasSeenDashboardTutorial = true
        defaults.set(Self.dashboardTutorialRevision, forKey: Keys.dashboardTutorialRevision)
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
    }
    
    func resetOnboarding() {
        hasCompletedOnboarding = false
        hasSeenQuickGuide = false
        hasSeenDashboardTutorial = false
        defaults.removeObject(forKey: Keys.dashboardTutorialRevision)
        onboardingScrollHours = 0
        referralCode = ""
        defaults.removeObject(forKey: Keys.onboardingAnswers)
    }
}

