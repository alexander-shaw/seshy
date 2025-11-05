//
//  UserProfile.swift
//  EventsApp
//
//  Created by Шоу on 10/4/25.
//

// Local-only editable profile for the local user.
// One-to-one with DeviceUser (root).
// Changes automatically sync to PublicProfile locally, which then syncs to cloud.
// UserProfile itself never syncs to cloud directly.

import Foundation
import CoreData
import CoreDomain

@objc(UserProfile)
public class UserProfile: NSManagedObject {}

extension UserProfile {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserProfile> {
        NSFetchRequest<UserProfile>(entityName: "UserProfile")
    }

    @NSManaged public var id: UUID
    @NSManaged public var displayName: String
    @NSManaged public var bio: String?

    @NSManaged public var dateOfBirth: Date?
    @NSManaged public var showAge: Bool

    // Useful for social/dating dynamics, safety and moderation, analytics/insights.
    @NSManaged public var genderCategoryRaw: NSNumber?  // Optional Int16.
    @NSManaged public var genderIdentity: String?
    @NSManaged public var showGender: Bool

    @NSManaged public var isVerified: Bool
    @NSManaged public var wasVerifiedAt: Date?

    // Relationships:
    @NSManaged public var user: DeviceUser
    @NSManaged public var publicProfile: PublicProfile?
    @NSManaged public var media: Set<Media>?
    @NSManaged public var vibes: Set<Vibe>?
}

public extension UserProfile {
    var genderCategory: GenderCategory? {
        get { genderCategoryRaw.flatMap { GenderCategory(rawValue: $0.int16Value) } }
        set { genderCategoryRaw = newValue.map { NSNumber(value: $0.rawValue) } }
    }
}

extension UserProfile {
    // NOTE: Could depend on subscription tier!
    // Free: up to 4 images.
    // Paid: up to 9 images & videos.
    public var maxMediaUploads: Int {
        return 4
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

// Local & Cloud Storage:
extension UserProfile: SyncTrackable {
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var deletedAt: Date?
    @NSManaged public var syncStatusRaw: Int16
    @NSManaged public var lastCloudSyncedAt: Date?
    // Note: UserProfile doesn't have schemaVersion in Core Data model since it's local-only
    // Computed property to satisfy SyncTrackable protocol (always returns 1)
    public var schemaVersion: Int16 {
        get { 1 }
        set { /* No-op: UserProfile is local-only and doesn't sync */ }
    }

    // Computed:
    public var syncStatus: SyncStatus {
        get { SyncStatus(rawValue: syncStatusRaw) ?? .pending }
        set { syncStatusRaw = newValue.rawValue }
    }
}
