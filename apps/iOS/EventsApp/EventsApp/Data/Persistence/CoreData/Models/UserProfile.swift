//
//  UserProfile.swift
//  EventsApp
//
//  Created by Шоу on 10/4/25.
//

// MARK: Editable profile for the local user.
// One-to-one with DeviceUser (root).
// Other users are represented by PublicUser.

import Foundation
import CoreData

@objc(UserProfile)
public class UserProfile: NSManagedObject {}

extension UserProfile {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserProfile> {
        NSFetchRequest<UserProfile>(entityName: "UserProfile")
    }

    @NSManaged public var id: UUID
    @NSManaged public var createdAt: Date

    @NSManaged public var displayName: String
    @NSManaged public var bio: String?
    @NSManaged public var avatarURL: String?  // Faster than loading all media.
    @NSManaged public var isVerified: Bool

    @NSManaged public var dateOfBirth: Date?
    @NSManaged public var showAge: Bool

    // Useful for social/dating dynamics, safety and moderation, analytics/insights.
    @NSManaged public var genderCategoryRaw: NSNumber?  // Optional Int16.
    @NSManaged public var genderIdentity: String?
    @NSManaged public var showGender: Bool

    // Relationships:
    @NSManaged public var user: DeviceUser
    @NSManaged public var media: Set<OwnedMedia>?
    @NSManaged public var tags: Set<Tag>?

    // Local & Cloud Storage:
    @NSManaged public var lastLocallySavedAt: Date?
    @NSManaged public var lastCloudSyncedAt: Date?
    @NSManaged public var syncStatusRaw: Int16
}

public extension UserProfile {
    var genderCategory: GenderCategory? {
        get { genderCategoryRaw.flatMap { GenderCategory(rawValue: $0.int16Value) } }
        set { genderCategoryRaw = newValue.map { NSNumber(value: $0.rawValue) } }
    }

    var syncStatus: SyncStatus {
        get { SyncStatus(rawValue: syncStatusRaw) ?? .pending }
        set { syncStatusRaw = newValue.rawValue }
    }
}

extension UserProfile {
    // TODO: Should depend on subscription tier!
    public var maxMediaUploads: Int {
        return 6
    }

    public var currentMediaCount: Int {
        return media?.count ?? 0
    }

    public var canUploadMoreMedia: Bool {
        return currentMediaCount < maxMediaUploads
    }

    public var remainingMediaSlots: Int {
        return max(0, maxMediaUploads - currentMediaCount)
    }
}
