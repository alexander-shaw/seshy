//
//  UserProfileViewModel.swift
//  EventsApp
//
//  Created by Шоу on 10/11/25.
//

import Foundation
import Combine
import CoreData
import SwiftUI
import UIKit

@MainActor
final class UserProfileViewModel: ObservableObject {
    @Published var displayName: String = ""
    @Published var bio: String = ""
    @Published var dateOfBirth: Date?
    @Published var showAge: Bool = true
    @Published var genderCategory: GenderCategory?
    @Published var genderIdentity: String = ""
    @Published var showGender: Bool = true
    @Published var city: String? = nil
    @Published var state: String? = nil
    @Published var showCityState: Bool = true
    @Published var isVerified: Bool = false
    @Published var vibes: Set<Vibe> = []

    // Temporary media items selected but not yet uploaded.
    @Published var selectedMediaItems: [MediaItem] = []
    
    // Media items for editing (existing + new)
    @Published var editingMediaItems: [MediaItem] = []
    @Published private(set) var isSavingMedia: Bool = false

    // Input properties for forms.
    @Published var displayNameInput: String = ""
    @Published var bioInput: String = ""
    @Published var dateOfBirthInput: Date?
    @Published var genderIdentityInput: String = ""
    @Published var showGenderToggle: Bool = true
    @Published var showAgeToggle: Bool = true
    @Published var genderCategorySelection: GenderCategory = .unknown
    @Published var cityInput: String? = nil
    @Published var stateInput: String? = nil
    @Published var showCityStateToggle: Bool = true

    @Published private(set) var isOnboardingComplete: Bool = false
    @Published private(set) var isSaving: Bool = false
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var media: [Media] = []

    private let context: NSManagedObjectContext
    private let repository: UserProfileRepository
    private let mediaRepository: MediaRepository
    private let mediaUploadService: MediaUploadService
    private var userProfile: UserProfile?

    init(context: NSManagedObjectContext = CoreDataStack.shared.viewContext, repository: UserProfileRepository = CoreUserProfileRepository(), mediaRepository: MediaRepository = CoreMediaRepository(), mediaUploadService: MediaUploadService = MediaUploadService()) {
        self.context = context
        self.repository = repository
        self.mediaRepository = mediaRepository
        self.mediaUploadService = mediaUploadService
    }

    func loadProfile(for user: DeviceUser?) async {
        guard let user else {
            errorMessage = "No user provided"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
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
                city = profile.city
                state = profile.state
                showCityState = profile.showCityState
                isVerified = profile.isVerified
                vibes = profile.vibes ?? []

                // Update input properties.
                displayNameInput = profile.displayName
                bioInput = profile.bio ?? ""
                dateOfBirthInput = profile.dateOfBirth
                genderIdentityInput = profile.genderIdentity ?? ""
                showGenderToggle = profile.showGender
                showAgeToggle = profile.showAge
                genderCategorySelection = profile.genderCategory ?? .unknown
                cityInput = profile.city
                stateInput = profile.state
                showCityStateToggle = profile.showCityState
                
                // Load media from profile
                loadMediaFromProfile(profile)
                
                evaluateCompletion()
            } else {
                userProfile = nil
                errorMessage = "Profile not found"
            }
        } catch {
            errorMessage = "Failed to load profile: \(error.localizedDescription)"
            print("Failed to load profile:  \(error)")
        }
        
        isLoading = false
    }
    
    func refreshProfile(for user: DeviceUser?) async {
        // Refresh Core Data context to get latest local data
        await MainActor.run {
            context.refreshAllObjects()
        }
        await loadProfile(for: user)
    }
    
    // MARK: - MEDIA EDITING:
    
    /// Loads existing media into editingMediaItems for editing
    func loadMediaForEditing() {
        guard let profile = userProfile else { return }
        editingMediaItems = convertMediaToMediaItems(Array(profile.media ?? []))
    }
    
    /// Converts Core Data Media objects to MediaItem for editing
    private func convertMediaToMediaItems(_ mediaArray: [Media]) -> [MediaItem] {
        return mediaArray.sorted(by: { $0.position < $1.position }).compactMap { media in
            // Only load image data from file if it's a local file
            // For cloud-first approach, we don't load image data here
            // MediaItem is only used for new uploads, not for existing cloud media
            // Existing media is displayed via RemoteMediaImage which handles cloud URLs
            var imageData: Data? = nil
            
            let source = MediaURLResolver.resolveURL(for: media)
            switch source {
            case .remote:
                // Remote media - don't load data here, will be loaded by RemoteMediaImage
                // Return MediaItem with nil imageData for existing cloud media
                break
            case .missing:
                return nil
            }
            
            return MediaItem(
                id: media.id,
                imageData: imageData,
                mimeType: media.mimeType,
                position: media.position
            )
        }
    }
    
    /// Saves media changes: adds new, deletes removed, reorders
    /// - Parameter clearEditingItems: If true, clears editingMediaItems after save (default: false for auto-save, true for final save)
    func saveMediaChanges(for user: DeviceUser?, clearEditingItems: Bool = false) async throws {
        guard let user = user else {
            throw NSError(domain: "UserProfileViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user provided"])
        }
        
        // Ensure we have a fresh profile reference before saving
        if userProfile == nil {
            await loadProfile(for: user)
        }
        
        guard let profile = userProfile else {
            throw NSError(domain: "UserProfileViewModel", code: -1, userInfo: [NSLocalizedDescriptionKey: "No profile found"])
        }
        
        isSavingMedia = true
        defer { isSavingMedia = false }
        
        // Get current media IDs
        let currentMediaIDs = Set(media.map { $0.id })
        
        // Get editing media IDs (existing + new)
        let editingMediaIDs = Set(editingMediaItems.map { $0.id })
        
        // Find media to delete (in current but not in editing)
        let mediaToDelete = currentMediaIDs.subtracting(editingMediaIDs)
        for mediaID in mediaToDelete {
            try await mediaRepository.deleteMedia(mediaID)
        }
        
        // Find new media items (not in current media)
        let newMediaItems = editingMediaItems.filter { !currentMediaIDs.contains($0.id) }
        
        // Upload new media items and track ID mappings
        var mediaItemIDToMediaID: [UUID: UUID] = [:] // Maps MediaItem ID -> Media ID
        var createdMediaIDs: [UUID] = []
        
        for item in newMediaItems {
            guard let imageData = item.imageData else { 
                print("UserProfileViewModel | Skipping media item with no data")
                continue 
            }
            
            let placeholderURL = "placeholder://\(UUID().uuidString)"
            let createdMedia = try await mediaRepository.createMedia(
                userProfileID: profile.id,
                url: placeholderURL,
                mimeType: item.mimeType,
                position: item.position,
                averageColorHex: item.averageColorHex,
                primaryColorHex: item.primaryColorHex,
                secondaryColorHex: item.secondaryColorHex
            )
            
            let mediaID = createdMedia.id
            let mediaItemID = item.id
            mediaItemIDToMediaID[mediaItemID] = mediaID
            createdMediaIDs.append(mediaID)
            print("UserProfileViewModel | Created media \(mediaID) for profile \(profile.id) (MediaItem ID: \(mediaItemID))")
            
            // Save media file locally (fast - local file system)
            let fileURL: URL
            do {
                fileURL = try MediaStorageHelper.saveMediaData(imageData, mediaID: mediaID, isVideo: false)
                
                // Update media URL (local save - fast)
                try await mediaRepository.updateMediaURL(mediaID, url: fileURL.absoluteString)
                print("UserProfileViewModel | Saved media file and updated URL for \(mediaID)")
            } catch {
                print("UserProfileViewModel | Error saving media file for \(mediaID): \(error)")
                // Clean up the media record if file save failed
                try? await mediaRepository.deleteMedia(mediaID)
                throw error
            }
        }
        
        // Wait for Core Data merge notifications to propagate
        if !createdMediaIDs.isEmpty {
            try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
            print("UserProfileViewModel | Created \(createdMediaIDs.count) new media items")
        }
        
        // Build the final media ID list for reordering
        // For existing items, use their MediaItem ID (which matches Media ID)
        // For new items, use the mapped Media ID
        var finalMediaIDs: [UUID] = []
        for item in editingMediaItems {
            if let mediaID = mediaItemIDToMediaID[item.id] {
                // This is a newly created item, use the actual Media ID
                finalMediaIDs.append(mediaID)
            } else {
                // This is an existing item, MediaItem ID should match Media ID
                finalMediaIDs.append(item.id)
            }
        }
        
        // Reorder all media items (local save - fast)
        print("UserProfileViewModel | Reordering \(finalMediaIDs.count) media items")
        try await mediaRepository.reorderMedia(finalMediaIDs, userProfileID: profile.id)
        
        // Wait a bit more for all Core Data saves to complete
        try await Task.sleep(nanoseconds: 500_000_000)  // 0.5 seconds.
        
        // Refresh profile to reload media relationships
        await loadProfile(for: user)
        
        // Ensure we're using the updated userProfile reference after loadProfile
        guard let updatedProfile = userProfile else {
            throw NSError(domain: "UserProfileViewModel", code: -2, userInfo: [NSLocalizedDescriptionKey: "Profile not found after refresh"])
        }
        
        // Refresh the context to ensure newly created media is available
        await MainActor.run {
            context.refresh(updatedProfile, mergeChanges: true)
            
            // Force refresh of the media relationship
            if let mediaSet = updatedProfile.media {
                for mediaItem in mediaSet {
                    context.refresh(mediaItem, mergeChanges: true)
                }
            }
        }
        
        // Reload editing items from the refreshed profile to ensure consistency
        // This updates IDs for newly saved items and preserves the order
        let mediaArray = Array(updatedProfile.media ?? [])
        print("UserProfileViewModel | Found \(mediaArray.count) media items in profile after save")
        let savedMediaItems = convertMediaToMediaItems(mediaArray)
        
        // Preserve any truly new items that were added after the save started
        // (items with imageData that aren't in the saved media yet)
        let savedMediaIDs = Set(savedMediaItems.map { $0.id })
        let newUnsavedItems = editingMediaItems.filter { item in
            // Keep items that have data but aren't in saved media yet
            item.imageData != nil && !savedMediaIDs.contains(item.id)
        }
        
        // Combine saved items with any new unsaved items and update positions
        var finalItems: [MediaItem] = []
        let allItems = savedMediaItems + newUnsavedItems
        for (index, item) in allItems.enumerated() {
            var updatedItem = item
            updatedItem.position = Int16(index)
            finalItems.append(updatedItem)
        }
        editingMediaItems = finalItems
        
        // Clear editing items only if requested (e.g., when dismissing)
        if clearEditingItems {
            editingMediaItems = []
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
                existingProfile.city = cityInput
                existingProfile.state = stateInput
                existingProfile.showCityState = showCityStateToggle
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
                savedProfile.city = cityInput
                savedProfile.state = stateInput
                savedProfile.showCityState = showCityStateToggle
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
            city = cityInput
            state = stateInput
            showCityState = showCityStateToggle
            
            evaluateCompletion()
            
            // Upload selected media after profile is created/updated.
            guard let profile = userProfile, !selectedMediaItems.isEmpty else { return }
            try? await uploadSelectedMedia(for: profile.id)
        } catch {
            print("Failed to save UserProfile:  \(error)")
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
    
    // Uploads selected media items to cloud and creates Media records for user profiles.
    func uploadSelectedMedia(for profileID: UUID) async throws {
        for (index, item) in selectedMediaItems.enumerated() {
            do {
                // Upload to cloud first - get cloud URL and metadata
                let mediaDTO = try await mediaUploadService.uploadMedia(
                    item,
                    userProfileID: profileID,
                    position: Int16(index)
                )
                
                // Create Core Data Media record with cloud URL
                let createdMedia = try await mediaRepository.createMedia(
                    userProfileID: profileID,
                    url: mediaDTO.url, // Cloud URL from API
                    mimeType: mediaDTO.mimeType,
                    position: mediaDTO.position,
                    averageColorHex: mediaDTO.averageColorHex,
                    primaryColorHex: mediaDTO.primaryColorHex,
                    secondaryColorHex: mediaDTO.secondaryColorHex
                )
                
                print("Media uploaded to cloud: \(createdMedia.id) at \(mediaDTO.url)")
            } catch {
                // Log error but don't fail entire upload - continue with other items
                print("Failed to upload media item \(index): \(error.localizedDescription)")
                errorMessage = "Failed to upload some media items. Please try again."
            }
        }
        
        // Wait a moment for Core Data merge notification to propagate
        try await Task.sleep(nanoseconds: 100_000_000)  // 0.1 seconds
        
        // Refresh the profile to reload media relationships
        if let user = userProfile?.user {
            await loadProfile(for: user)
        }
        
        // Clear selected items after upload attempt
        selectedMediaItems.removeAll()
        
        print("All media items uploaded and profile refreshed.")
    }

    func evaluateCompletion() {
        isOnboardingComplete = !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && dateOfBirth != nil
    }

    func reset() {
        displayName = ""
        bio = ""
        dateOfBirth = nil
        showAge = true
        genderCategory = nil
        genderIdentity = ""
        showGender = true
        city = nil
        state = nil
        showCityState = true
        isVerified = false
        vibes = Set<Vibe>()
        isOnboardingComplete = false
        
        // Reset input properties.
        displayNameInput = ""
        dateOfBirthInput = nil
        genderIdentityInput = ""
        showGenderToggle = true
        showAgeToggle = true
        genderCategorySelection = .unknown
        cityInput = nil
        stateInput = nil
        showCityStateToggle = true
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
    
    var isValidVibes: Bool {
        vibes.count >= 0
    }
    
    var hasAtLeastOneMedia: Bool {
        return selectedMediaItems.count > 0 || (userProfile?.media?.count ?? 0) > 0
    }
    
    var isProfileComplete: Bool {
        isValidDisplayName && isValidDateOfBirth && isValidVibes
    }
    
    // MARK: - PROFILE DISPLAY PROPERTIES:
    
    var sortedMedia: [Media] {
        media.sorted { $0.position < $1.position }
    }
    
    var displayAge: String? {
        guard let dateOfBirth = dateOfBirth, showAge else { return nil }
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: dateOfBirth, to: Date())
        if let years = ageComponents.year {
            return "\(years) years old"
        }
        return nil
    }
    
    var displayGender: String? {
        guard showGender else { return nil }
        if !genderIdentity.isEmpty {
            return genderIdentity
        }
        guard let category = genderCategory else { return nil }
        switch category {
        case .male: return "Man"
        case .female: return "Woman"
        case .nonbinary: return "Nonbinary"
        case .other: return "Other"
        case .unknown: return nil
        }
    }
    
    var hasBio: Bool {
        guard !bio.isEmpty else { return false }
        return !bio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // Expose userProfile for views that need direct access to Core Data relationships
    var currentUserProfile: UserProfile? {
        return userProfile
    }
    
    // MARK: - PRIVATE METHODS:
    
    private func loadMediaFromProfile(_ profile: UserProfile) {
        guard let mediaSet = profile.media, !mediaSet.isEmpty else {
            media = []
            return
        }
        
        let sorted = Array(mediaSet).sorted(by: { $0.position < $1.position })
        
        // Force materialization of properties
        for mediaItem in sorted {
            let _ = mediaItem.id
            let _ = mediaItem.url
            let _ = mediaItem.position
            let _ = mediaItem.mimeType
        }
        
        media = sorted
    }
}
