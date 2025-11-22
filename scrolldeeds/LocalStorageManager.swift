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
    @Published var onboardingScrollHours: Int
    
    private init() {
        // Load initial values from UserDefaults
        self.hasCompletedOnboarding = defaults.bool(forKey: Keys.hasCompletedOnboarding)
        self.hasSeenQuickGuide = defaults.bool(forKey: Keys.hasSeenQuickGuide)
        self.onboardingScrollHours = defaults.integer(forKey: Keys.onboardingScrollHours)
        
        // Setup observers for changes
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
        
        $onboardingScrollHours.dropFirst().sink { [weak self] value in
            self?.defaults.set(value, forKey: Keys.onboardingScrollHours)
        }.store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Keys
    private enum Keys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let hasSeenQuickGuide = "hasSeenQuickGuide"
        static let onboardingScrollHours = "onboardingScrollHours"
        static let onboardingAnswers = "onboardingAnswers"
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
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
    }
    
    func resetOnboarding() {
        hasCompletedOnboarding = false
        hasSeenQuickGuide = false
        onboardingScrollHours = 0
        defaults.removeObject(forKey: Keys.onboardingAnswers)
    }
}

