//
//  PublicProfileViewModel.swift
//  EventsApp
//
//  Created by Шоу on 10/11/25.
//

import Foundation
import CoreData
import SwiftUI
import Combine

@MainActor
final class PublicProfileViewModel: ObservableObject {
    @Published var id: UUID = UUID()
    @Published var displayName: String = ""
    @Published var username: String = ""
    @Published var avatarURL: String = ""
    @Published var bio: String = ""
    @Published var ageYears: Int?
    @Published var gender: String = ""
    @Published var isVerified: Bool = false
    
    @Published private(set) var isSaving: Bool = false
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var profiles: [PublicProfile] = []
    @Published private(set) var media: [Media] = []
    
    private let context: NSManagedObjectContext
    private let repository: PublicProfileRepository
    private let mediaRepository: MediaRepository
    private var profile: PublicProfile?
    
    init(context: NSManagedObjectContext = CoreDataStack.shared.viewContext, repository: PublicProfileRepository = CorePublicProfileRepository(), mediaRepository: MediaRepository = CoreMediaRepository()) {
        self.context = context
        self.repository = repository
        self.mediaRepository = mediaRepository
    }
    
    func loadProfile(id: UUID) async {
        isLoading = true
        errorMessage = nil
        
        do {
            if let loadedProfile = try await repository.getPublicProfile(by: id) {
                profile = loadedProfile
                populateFromProfile(loadedProfile)
                await loadMedia(for: profile)
            }
        } catch {
            errorMessage = "Failed to load profile:  \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func loadProfile(username: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            if let loadedProfile = try await repository.getPublicProfile(by: username) {
                profile = loadedProfile
                populateFromProfile(loadedProfile)
                await loadMedia(for: profile)
            }
        } catch {
            errorMessage = "Failed to load profile:  \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func createProfile() async {
        guard !displayName.isEmpty else {
            errorMessage = "Display name is required."
            return
        }
        
        isSaving = true
        errorMessage = nil
        
        do {
            let newProfile = try await repository.createPublicProfile(
                id: id,
                displayName: displayName,
                username: username.isEmpty ? nil : username,
                avatarURL: avatarURL.isEmpty ? nil : avatarURL,
                bio: bio.isEmpty ? nil : bio,
                ageYears: ageYears,
                gender: gender.isEmpty ? nil : gender,
                isVerified: isVerified
            )
            
            profile = newProfile
            populateFromProfile(newProfile)
            profiles.append(newProfile)
        } catch {
            errorMessage = "Failed to create profile:  \(error.localizedDescription)"
        }
        
        isSaving = false
    }
    
    func updateProfile() async {
        guard let currentProfile = profile else { return }
        
        isSaving = true
        errorMessage = nil
        
        do {
            // Update the existing profile directly.
            currentProfile.avatarURL = avatarURL.isEmpty ? nil : avatarURL
            currentProfile.username = username.isEmpty ? nil : username
            currentProfile.displayName = displayName
            currentProfile.bio = bio.isEmpty ? nil : bio
            currentProfile.ageYears = ageYears.map { NSNumber(value: $0) }
            currentProfile.gender = gender.isEmpty ? nil : gender
            currentProfile.isVerified = isVerified
            currentProfile.updatedAt = Date()
            currentProfile.syncStatusRaw = SyncStatus.pending.rawValue
            
            if let result = try await repository.updatePublicProfile(currentProfile) {
                profile = result
                
                // Update in profiles array.
                if let index = profiles.firstIndex(where: { $0.id == currentProfile.id }) {
                    profiles[index] = result
                }
            }
        } catch {
            errorMessage = "Failed to update profile:  \(error.localizedDescription)"
        }
        
        isSaving = false
    }
    
    func deleteProfile() async {
        guard let currentProfile = profile else { return }
        
        isSaving = true
        errorMessage = nil
        
        do {
            try await repository.deletePublicProfile(currentProfile.id)
            
            // Remove from profiles array.
            profiles.removeAll { $0.id == currentProfile.id }
            
            profile = nil
            resetForm()
        } catch {
            errorMessage = "Failed to delete profile:  \(error.localizedDescription)"
        }
        
        isSaving = false
    }
    
    func searchProfiles(query: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            profiles = try await repository.searchPublicProfiles(query: query)
        } catch {
            errorMessage = "Failed to search profiles:  \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func loadVerifiedProfiles() async {
        isLoading = true
        errorMessage = nil
        
        do {
            profiles = try await repository.getVerifiedProfiles()
        } catch {
            errorMessage = "Failed to load verified profiles:  \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func loadProfilesByAgeRange(minAge: Int, maxAge: Int) async {
        isLoading = true
        errorMessage = nil
        
        do {
            profiles = try await repository.getProfilesByAgeRange(minAge: minAge, maxAge: maxAge)
        } catch {
            errorMessage = "Failed to load profiles by age range:  \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func refreshProfile() async {
        guard let currentProfile = profile else { return }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await repository.refreshPublicProfile(currentProfile.id)
            await loadProfile(id: currentProfile.id)
        } catch {
            errorMessage = "Failed to refresh profile:  \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func addMedia(url: String, mimeType: String?, position: Int16) async {
        guard let currentProfile = profile else { return }
        
        do {
            let newMedia = try await mediaRepository.createMedia(
                publicProfileID: currentProfile.id,
                url: url,
                mimeType: mimeType,
                position: position,
                averageColorHex: nil,
                primaryColorHex: nil,
                secondaryColorHex: nil
            )
            media.append(newMedia)
        } catch {
            errorMessage = "Failed to add media:  \(error.localizedDescription)"
        }
    }
    
    func removeMedia(_ mediaItem: Media) async {
        do {
            try await mediaRepository.deleteMedia(mediaItem.id)
            media.removeAll { $0.url == mediaItem.url }
        } catch {
            errorMessage = "Failed to remove media:  \(error.localizedDescription)"
        }
    }
    
    // MARK: - PRIVATE METHODS:
    private func loadMedia(for profile: PublicProfile?) async {
        guard let profile = profile else { return }
        do {
            media = try await mediaRepository.getMedia(publicProfileID: profile.id, limit: nil)
        } catch {
            errorMessage = "Failed to load media:  \(error.localizedDescription)"
        }
    }
    
    private func populateFromProfileDTO(_ profileDTO: PublicProfileDTO) {
        id = profileDTO.id
        displayName = profileDTO.displayName ?? ""
        username = profileDTO.username ?? ""
        avatarURL = profileDTO.avatarURL ?? ""
        bio = profileDTO.bio ?? ""
        ageYears = profileDTO.ageYears
        gender = profileDTO.gender ?? ""
        isVerified = profileDTO.isVerified
    }
    
    private func populateFromProfile(_ profile: PublicProfile) {
        id = profile.id
        displayName = profile.displayName ?? ""
        username = profile.username ?? ""
        avatarURL = profile.avatarURL ?? ""
        bio = profile.bio ?? ""
        ageYears = profile.ageYears?.intValue
        gender = profile.gender ?? ""
        isVerified = profile.isVerified
    }
    
    private func resetForm() {
        id = UUID()
        displayName = ""
        username = ""
        avatarURL = ""
        bio = ""
        ageYears = nil
        gender = ""
        isVerified = false
        media = []
    }
    
    // MARK: - COMPUTED PROPERTIES:
    var verifiedProfiles: [PublicProfile] {
        return profiles.filter { $0.isVerified }
    }
    
    var profileCount: Int {
        return profiles.count
    }
    
    var mediaCount: Int {
        return media.count
    }
    
    var hasAvatar: Bool {
        return !avatarURL.isEmpty
    }
    
    var hasBio: Bool {
        return !bio.isEmpty
    }
    
    var hasAge: Bool {
        return ageYears != nil
    }
    
    var hasGender: Bool {
        return !gender.isEmpty
    }
    
    var isValid: Bool {
        return !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var displayAge: String {
        guard let age = ageYears else { return "" }
        return "\(age) years old"
    }
}
