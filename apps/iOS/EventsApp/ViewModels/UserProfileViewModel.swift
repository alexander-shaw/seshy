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
import Combine
import CoreData
import SwiftUI
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
    
    // Temporary media items selected but not yet uploaded
    @Published var selectedMediaItems: [MediaItem] = []

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
    private let mediaRepository: MediaRepository
    private var userProfile: UserProfile?

    init(context: NSManagedObjectContext = CoreDataStack.shared.viewContext, repository: UserProfileRepository = CoreDataUserProfileRepository(), mediaRepository: MediaRepository = CoreDataMediaRepository()) {
        self.context = context
        self.repository = repository
        self.mediaRepository = mediaRepository
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
            
            // Upload selected media after profile is created/updated
            guard let profile = userProfile, !selectedMediaItems.isEmpty else { return }
            try? await uploadSelectedMedia(for: profile.id)
        } catch {
            print("Failed to save UserProfile: \(error)")
        }
    }
    
    // MARK: - SELECTED MEDIA ITEMS MANAGEMENT:
    
    func addSelectedMedia(_ mediaItem: MediaItem) {
        if !selectedMediaItems.contains(where: { $0.id == mediaItem.id }) {
            var item = mediaItem
            item.position = Int16(selectedMediaItems.count)
            selectedMediaItems.append(item)
        }
    }
    
    func removeSelectedMedia(at index: Int) {
        guard index < selectedMediaItems.count else { return }
        selectedMediaItems.remove(at: index)
        updateSelectedMediaPositions()
    }
    
    func moveSelectedMedia(from source: Int, to destination: Int) {
        guard source < selectedMediaItems.count && destination < selectedMediaItems.count else { return }
        let movedItem = selectedMediaItems.remove(at: source)
        selectedMediaItems.insert(movedItem, at: destination)
        updateSelectedMediaPositions()
    }
    
    private func updateSelectedMediaPositions() {
        var updatedItems: [MediaItem] = []
        for (index, item) in selectedMediaItems.enumerated() {
            var updatedItem = item
            updatedItem.position = Int16(index)
            updatedItems.append(updatedItem)
        }
        selectedMediaItems = updatedItems
    }
    
    /// Uploads selected media items and creates Media records for user profiles
    private func uploadSelectedMedia(for profileID: UUID) async throws {
        for (index, item) in selectedMediaItems.enumerated() {
            // Create Media record first to get the UUID
            let placeholderURL = "placeholder://\(UUID().uuidString)"
            let createdMedia = try await mediaRepository.createMedia(
                userProfileID: profileID,
                url: placeholderURL,
                mimeType: item.mimeType,
                position: Int16(index)
            )
            
            // Extract the media ID immediately to avoid Core Data context issues
            let mediaID = createdMedia.id
            
            // Verify we have data to save
            guard item.imageData != nil || item.videoData != nil else {
                // If no data, delete the created media record
                try? await mediaRepository.deleteMedia(mediaID)
                continue
            }
            
            // Save media data to persistent storage using the created media ID
            let fileURL: URL
            do {
                if let imageData = item.imageData {
                    fileURL = try MediaStorageHelper.saveMediaData(imageData, mediaID: mediaID, isVideo: false)
                } else if let videoData = item.videoData {
                    fileURL = try MediaStorageHelper.saveMediaData(videoData, mediaID: mediaID, isVideo: true)
                } else {
                    // This shouldn't happen due to guard above, but handle it anyway
                    try? await mediaRepository.deleteMedia(mediaID)
                    continue
                }
            } catch {
                // If saving fails, clean up the media record
                print("Failed to save media file: \(error)")
                try? await mediaRepository.deleteMedia(mediaID)
                throw error
            }
            
            // Update the media record with the actual file URL
            try await mediaRepository.updateMediaURL(mediaID, url: fileURL.absoluteString)
        }
        
        // Clear selected items after upload
        selectedMediaItems.removeAll()
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
        return selectedMediaItems.count > 0 || (userProfile?.media?.count ?? 0) > 0
    }
    
    var isProfileComplete: Bool {
        isValidDisplayName && isValidDateOfBirth && isValidTags
    }
}
