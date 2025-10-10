//
//  PublicUser.swift
//  EventsApp
//
//  Created by Шоу on 10/8/25.
//

// MARK: Read-only cache to render full public profiles.  Evictable and refreshable.

import Foundation
import CoreData

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

    // Cache freshness.
    @NSManaged public var lastFetchedAt: Date

    // Read-only, evictable profile gallery (ordered by position).
    @NSManaged var media: Set<ProfileMedia>?
}
