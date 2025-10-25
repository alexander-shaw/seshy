//
//  UserProfileViewModel.swift
//  EventsApp
//
//  Created by Шоу on 10/11/25.
//

// Manages user profile data and onboarding flow.
// Provides a reactive interface for SwiftUI views to work with user profiles including:
// - Profile creation and editing;
// - Onboarding completion tracking;
// - Tag management for user interests; and
// - Integration with Core Data persistence layer.

import Foundation
import CoreData
import SwiftUI
import Combine
import CoreDomain

@MainActor
final class UserProfileViewModel: ObservableObject {
    @Published var displayName: String = ""
    @Published var bio: String = ""
    @Published var dateOfBirth: Date?
    @Published var showAge: Bool = false
    @Published var genderCategory: GenderCategory?
    @Published var genderIdentity: String = ""
    @Published var showGender: Bool = false
    @Published var isVerified: Bool = false
    @Published var tags: Set<Tag> = []

    // Input properties for forms.
    @Published var displayNameInput: String = ""
    @Published var bioInput: String = ""
    @Published var dateOfBirthInput: Date?
    @Published var genderIdentityInput: String = ""
    @Published var showGenderToggle: Bool = false
    @Published var showAgeToggle: Bool = false
    @Published var genderCategorySelection: GenderCategory = .unknown

    @Published private(set) var isOnboardingComplete: Bool = false
    @Published private(set) var isSaving: Bool = false

    private let context: NSManagedObjectContext
    private let repository: UserProfileRepository
    private var userProfile: UserProfile?

    init(context: NSManagedObjectContext = CoreDataStack.shared.viewContext, repository: UserProfileRepository = CoreDataUserProfileRepository()) {
        self.context = context
        self.repository = repository
    }

    func loadProfile(for user: DeviceUser?) async {
        guard let user else { return }
        
        do {
            if let profile = try await repository.getProfile(for: user) {
                userProfile = profile
                displayName = profile.displayName
                bio = profile.bio ?? ""
                dateOfBirth = profile.dateOfBirth
                showAge = profile.showAge
                genderCategory = profile.genderCategory
                genderIdentity = profile.genderIdentity ?? ""
                showGender = profile.showGender
                isVerified = profile.isVerified
                tags = profile.tags ?? []
                
                // Update input properties.
                displayNameInput = profile.displayName
                bioInput = profile.bio ?? ""
                dateOfBirthInput = profile.dateOfBirth
                genderIdentityInput = profile.genderIdentity ?? ""
                showGenderToggle = profile.showGender
                showAgeToggle = profile.showAge
                genderCategorySelection = profile.genderCategory ?? .unknown
                
                evaluateCompletion()
            } else {
                userProfile = nil
            }
        } catch {
            print("Failed to load profile: \(error)")
        }
    }

    func saveProfile(for user: DeviceUser?) async {
        guard let user else { return }
        isSaving = true
        defer { isSaving = false }

        do {
            if let existingProfile = userProfile {
                // Update existing profile.
                existingProfile.displayName = displayNameInput
                existingProfile.bio = bioInput.isEmpty ? nil : bioInput
                existingProfile.dateOfBirth = dateOfBirthInput
                existingProfile.showAge = showAgeToggle
                existingProfile.genderCategory = genderCategorySelection
                existingProfile.genderIdentity = genderIdentityInput.isEmpty ? nil : genderIdentityInput
                existingProfile.showGender = showGenderToggle
                existingProfile.updatedAt = Date()
                existingProfile.syncStatus = .pending
                
                let savedProfile = try await repository.updateProfile(existingProfile)
                userProfile = savedProfile
            } else {
                // Create new profile.
                let savedProfile = try await repository.createProfile(for: user)
                // Update the profile with form data.
                savedProfile.displayName = displayNameInput
                savedProfile.bio = bioInput.isEmpty ? nil : bioInput
                savedProfile.dateOfBirth = dateOfBirthInput
                savedProfile.showAge = showAgeToggle
                savedProfile.genderCategory = genderCategorySelection
                savedProfile.genderIdentity = genderIdentityInput.isEmpty ? nil : genderIdentityInput
                savedProfile.showGender = showGenderToggle
                savedProfile.updatedAt = Date()
                savedProfile.syncStatus = .pending
                
                let updatedProfile = try await repository.updateProfile(savedProfile)
                userProfile = updatedProfile
            }
            
            // Update the published properties.
            displayName = displayNameInput
            bio = bioInput
            dateOfBirth = dateOfBirthInput
            showAge = showAgeToggle
            genderCategory = genderCategorySelection
            genderIdentity = genderIdentityInput
            showGender = showGenderToggle
            
            evaluateCompletion()
        } catch {
            print("Failed to save UserProfile: \(error)")
        }
    }

    func evaluateCompletion() {
        isOnboardingComplete = !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && dateOfBirth != nil
    }

    func reset() {
        displayName = ""
        bio = ""
        dateOfBirth = nil
        showAge = false
        genderCategory = nil
        genderIdentity = ""
        showGender = false
        isVerified = false
        tags = Set<Tag>()
        isOnboardingComplete = false
        
        // Reset input properties.
        displayNameInput = ""
        dateOfBirthInput = nil
        genderIdentityInput = ""
        showGenderToggle = false
        showAgeToggle = false
        genderCategorySelection = .unknown
    }
    
    // MARK: - COMPUTED PROPERTIES EXPECTED BY VIEWS:

    var isValidDisplayName: Bool {
        !displayNameInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var isValidDateOfBirth: Bool {
        dateOfBirthInput != nil
    }
    
    var isValidGender: Bool {
        genderCategorySelection != .unknown
    }
    
    var isValidTags: Bool {
        tags.count >= 0
    }
    
    var hasAtLeastOneMedia: Bool {
        // This would check if user has uploaded media.
        // For now, return false as a placeholder.
        false
    }
    
    var isProfileComplete: Bool {
        isValidDisplayName && isValidDateOfBirth && isValidTags
    }
}
