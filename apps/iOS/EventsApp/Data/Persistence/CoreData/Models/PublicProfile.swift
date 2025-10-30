//
//  PublicUser.swift
//  EventsApp
//
//  Created by Шоу on 10/8/25.
//

// Read-only cache to render full public profiles.
// Evictable and refreshable.

import Foundation
import CoreData
import CoreDomain

@objc(PublicProfile)
public class PublicProfile: NSManagedObject {}

extension PublicProfile {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<PublicProfile> {
        NSFetchRequest<PublicProfile>(entityName: "PublicProfile")
    }

    @NSManaged public var id: UUID
    @NSManaged public var avatarURL: String?
    @NSManaged public var username: String?
    @NSManaged public var displayName: String
    @NSManaged public var bio: String?
    @NSManaged public var ageYears: NSNumber?
    @NSManaged public var gender: String?
    @NSManaged public var isVerified: Bool

    // Read-only, evictable profile gallery (ordered by position).
    @NSManaged public var media: Set<Media>?
}

// Local & Cloud Storage:
extension PublicProfile: SyncTrackable {
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var deletedAt: Date?
    @NSManaged public var syncStatusRaw: Int16
    @NSManaged public var lastCloudSyncedAt: Date?
    @NSManaged public var schemaVersion: Int16

    // Computed:
    public var syncStatus: SyncStatus {
        get { SyncStatus(rawValue: syncStatusRaw) ?? .pending }
        set { syncStatusRaw = newValue.rawValue }
    }
}
