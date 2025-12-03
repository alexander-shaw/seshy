//
//  UserProfileToPublicProfileMapper.swift
//  EventsApp
//
//  Created by Шоу on 10/31/25.
//

import Foundation
import CoreData

// Calculate age in years from date of birth.
private func calculateAgeYears(from dateOfBirth: Date?) -> Int? {
    guard let dob = dateOfBirth else { return nil }
    let calendar = Calendar.current
    let now = Date()
    let ageComponents = calendar.dateComponents([.year], from: dob, to: now)
    return ageComponents.year
}

// Format gender string from category and identity.
// Shows "Man", "Woman", or "Nonbinary" when selected.  Otherwise, shows the user-provided identity (if any).
private func formatGender(category: GenderCategory?, identity: String?, showGender: Bool) -> String? {
    guard showGender else { return nil }

    // Normalize custom identity.
    let trimmedIdentity = identity?.trimmingCharacters(in: .whitespacesAndNewlines)
    let hasIdentity = (trimmedIdentity?.isEmpty == false)

    // Prefer canonical labels when selected.
    if let category = category {
        switch category {
        case .male:
            return "Man"
        case .female:
            return "Woman"
        case .nonbinary:
            return "Nonbinary"
        case .other, .unknown:
            // Falls through to custom identity (if present).
            break
        }
    }

    // If not one of the three, shows custom identity (if available).
    return hasIdentity ? trimmedIdentity : nil
}

// Creates/updates PublicProfile from UserProfile in the same context.
public func createOrUpdatePublicProfileFromUserProfile(
    _ userProfile: UserProfile,
    in ctx: NSManagedObjectContext
) throws -> PublicProfile {
    // Finds existing PublicProfile by ID or relationship.
    let existing: PublicProfile?
    
    if let existingPublicProfile = userProfile.publicProfile {
        existing = existingPublicProfile
    } else {
        // Tries to find by ID.
        let request: NSFetchRequest<PublicProfile> = PublicProfile.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", userProfile.id as CVarArg)
        request.fetchLimit = 1
        existing = try ctx.fetch(request).first
    }
    
    let publicProfile: PublicProfile
    
    if let existing = existing {
        publicProfile = existing
    } else {
        // Creates new PublicProfile.
        publicProfile = PublicProfile(context: ctx)
        publicProfile.id = userProfile.id
        publicProfile.createdAt = userProfile.createdAt
        publicProfile.schemaVersion = 1  // Default schema version for new PublicProfile.
        publicProfile.userProfile = userProfile
        userProfile.publicProfile = publicProfile
    }
    
    // Updates fields from UserProfile.
    publicProfile.displayName = userProfile.displayName
    publicProfile.bio = userProfile.bio
    publicProfile.isVerified = userProfile.isVerified
    
    // Calculates ageYears if showAge is true.
    if userProfile.showAge {
        publicProfile.ageYears = calculateAgeYears(from: userProfile.dateOfBirth).map { NSNumber(value: $0) }
    } else {
        publicProfile.ageYears = nil
    }
    
    // Formats gender string if showGender is true.
    if userProfile.showGender {
        publicProfile.gender = formatGender(
            category: userProfile.genderCategory,
            identity: userProfile.genderIdentity,
            showGender: userProfile.showGender
        )
    } else {
        publicProfile.gender = nil
    }
    
    // Preserves username and avatarURL (these are PublicProfile-only fields).
    // Only updates them if they're nil (initial creation).
    if publicProfile.username == nil {
        publicProfile.username = nil  // Keep nil, user sets this separately.
    }
    if publicProfile.avatarURL == nil {
        publicProfile.avatarURL = nil  // Keep nil, user sets this separately.
    }
    
    // Updates timestamps.
    publicProfile.updatedAt = userProfile.updatedAt
    
    // Marks for cloud sync.
    publicProfile.syncStatus = .pending
    
    return publicProfile
}
