//
//  UserProfileRepository.swift
//  EventsApp
//
//  Created by Шоу on 10/14/25.
//

import Foundation
import CoreData
import CoreDomain

protocol UserProfileRepository {
    func getProfile(for user: DeviceUser) async throws -> UserProfile?
    func createProfile(for user: DeviceUser) async throws -> UserProfile
    func updateProfile(_ profile: UserProfile) async throws -> UserProfile
    func deleteProfile(_ profile: UserProfile) async throws
    func addTagsToProfile(_ profileId: UUID, tags: Set<Tag>) async throws -> UserProfile
    func removeTagsFromProfile(_ profileId: UUID, tags: Set<Tag>) async throws -> UserProfile
    func getProfileTags(_ profileId: UUID) async throws -> Set<Tag>
    func updateProfileWithFormData(_ profile: UserProfile, displayName: String, bio: String, dateOfBirth: Date?, showAge: Bool, genderCategory: GenderCategory, genderIdentity: String, showGender: Bool, tags: Set<Tag>) async throws -> UserProfile
    func createProfileWithFormData(for user: DeviceUser, displayName: String, bio: String, dateOfBirth: Date?, showAge: Bool, genderCategory: GenderCategory, genderIdentity: String, showGender: Bool, tags: Set<Tag>) async throws -> UserProfile
}

final class CoreDataUserProfileRepository: UserProfileRepository {
    private let coreDataStack: CoreDataStack

    init(coreDataStack: CoreDataStack = CoreDataStack.shared) {
        self.coreDataStack = coreDataStack
    }

    func getProfile(for user: DeviceUser) async throws -> UserProfile? {
        // Use main context for profile queries to avoid context sync issues.
        let context = coreDataStack.viewContext
        
        // Query using the relationship.
        let request: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
        request.predicate = NSPredicate(format: "user == %@", user)
        request.fetchLimit = 1
        
        let profiles = try context.fetch(request)
        print("getProfile: Found \(profiles.count) profiles for user \(user.id)")
        if let profile = profiles.first {
            print("getProfile: Profile ID: \(profile.id), displayName: '\(profile.displayName)', dateOfBirth: \(profile.dateOfBirth?.description ?? "nil")")
        }
        return profiles.first
    }

    func createProfile(for user: DeviceUser) async throws -> UserProfile {
        return try await coreDataStack.performBackgroundTask { context in
            // Core Data entities can be updated directly.
            guard let contextUser = try context.existingObject(with: user.objectID) as? DeviceUser else {
                throw RepositoryError.userNotFound
            }

            let profile = UserProfile(context: context)
            profile.id = UUID()
            profile.displayName = "New User"  // Default name - will be updated with form data.
            profile.createdAt = Date()
            profile.updatedAt = Date()
            profile.syncStatus = .pending
            profile.user = contextUser

            try context.save()
            return profile
        }
    }

    func updateProfile(_ profile: UserProfile) async throws -> UserProfile {
        return try await coreDataStack.performBackgroundTask { context in
            // Core Data entities can be updated directly.
            profile.updatedAt = Date()
            profile.syncStatus = .pending
            try context.save()
            return profile
        }
    }

    func deleteProfile(_ profile: UserProfile) async throws {
        try await coreDataStack.performBackgroundTask { context in
            // Core Data entities can be updated directly.
            context.delete(profile)
            try context.save()
        }
    }

    func addTagsToProfile(_ profileId: UUID, tags: Set<Tag>) async throws -> UserProfile {
        return try await coreDataStack.performBackgroundTask { context in
            let profileRequest: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
            profileRequest.predicate = NSPredicate(format: "id == %@", profileId as CVarArg)

            guard let profile = try context.fetch(profileRequest).first else {
                throw RepositoryError.profileNotFound
            }

            // Add tags to profile.
            if profile.tags == nil {
                profile.tags = Set<Tag>()
            }
            profile.tags?.formUnion(tags)
            profile.updatedAt = Date()
            profile.syncStatus = .pending

            try context.save()
            return profile
        }
    }

    func removeTagsFromProfile(_ profileId: UUID, tags: Set<Tag>) async throws -> UserProfile {
        return try await coreDataStack.performBackgroundTask { context in
            let profileRequest: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
            profileRequest.predicate = NSPredicate(format: "id == %@", profileId as CVarArg)

            guard let profile = try context.fetch(profileRequest).first else {
                throw RepositoryError.profileNotFound
            }

            // Remove tags from profile.
            profile.tags?.subtract(tags)
            profile.updatedAt = Date()
            profile.syncStatus = .pending

            try context.save()
            return profile
        }
    }

    func getProfileTags(_ profileId: UUID) async throws -> Set<Tag> {
        return try await coreDataStack.performBackgroundTask { context in
            let profileRequest: NSFetchRequest<UserProfile> = UserProfile.fetchRequest()
            profileRequest.predicate = NSPredicate(format: "id == %@", profileId as CVarArg)

            guard let profile = try context.fetch(profileRequest).first else {
                throw RepositoryError.profileNotFound
            }

            return profile.tags ?? Set<Tag>()
        }
    }

    func updateProfileWithFormData(
        _ profile: UserProfile,
        displayName: String,
        bio: String,
        dateOfBirth: Date?,
        showAge: Bool,
        genderCategory: GenderCategory,
        genderIdentity: String,
        showGender: Bool,
        tags: Set<Tag>
    ) async throws -> UserProfile {
        return try await coreDataStack.performBackgroundTask { context in
            // Get the profile in this context using objectID.
            guard let contextProfile = try context.existingObject(with: profile.objectID) as? UserProfile else {
                throw RepositoryError.userNotFound
            }

            // Update the profile with form data.
            contextProfile.displayName = displayName
            contextProfile.bio = bio.isEmpty ? nil : bio
            contextProfile.dateOfBirth = dateOfBirth
            contextProfile.showAge = showAge
            contextProfile.genderCategory = genderCategory
            contextProfile.genderIdentity = genderIdentity.isEmpty ? nil : genderIdentity
            contextProfile.showGender = showGender
            contextProfile.tags = tags
            contextProfile.updatedAt = Date()
            contextProfile.syncStatus = .pending

            try context.save()
            print("updateProfileWithFormData: Updated profile \(contextProfile.id)")
            print("updateProfileWithFormData: displayName: '\(displayName)', dateOfBirth: \(dateOfBirth?.description ?? "nil")")
            return contextProfile
        }
    }

    func createProfileWithFormData(
        for user: DeviceUser,
        displayName: String,
        bio: String,
        dateOfBirth: Date?,
        showAge: Bool,
        genderCategory: GenderCategory,
        genderIdentity: String,
        showGender: Bool,
        tags: Set<Tag>
    ) async throws -> UserProfile {
        return try await coreDataStack.performBackgroundTask { context in
            // Use objectID to fetch the user in this context.
            guard let contextUser = try context.existingObject(with: user.objectID) as? DeviceUser else {
                throw RepositoryError.userNotFound
            }

            let profile = UserProfile(context: context)
            profile.id = UUID()
            profile.displayName = displayName
            profile.bio = bio.isEmpty ? nil : bio
            profile.dateOfBirth = dateOfBirth
            profile.showAge = showAge
            profile.genderCategory = genderCategory
            profile.genderIdentity = genderIdentity.isEmpty ? nil : genderIdentity
            profile.showGender = showGender
            profile.tags = tags
            profile.createdAt = Date()
            profile.updatedAt = Date()
            profile.syncStatus = .pending
            profile.user = contextUser

            try context.save()
            print("createProfileWithFormData: Created profile \(profile.id) for user \(contextUser.id)")
            print("createProfileWithFormData: displayName: '\(displayName)', dateOfBirth: \(dateOfBirth?.description ?? "nil")")
            return profile
        }
    }
}
