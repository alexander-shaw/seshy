//
//  DeviceUser.swift
//  EventsApp
//
//  Created by Шоу on 10/6/25.
//

import Foundation
import CoreData
import CoreDomain

@objc(DeviceUser)
public class DeviceUser: NSManagedObject {}

public extension DeviceUser {
    @nonobjc class func fetchRequest() -> NSFetchRequest<DeviceUser> {
        NSFetchRequest<DeviceUser>(entityName: "DeviceUser")
    }

    @NSManaged var id: UUID  // MARK: Unique.
    @NSManaged var username: String?

    // Relationships:
    @NSManaged var fingerprint: DeviceFingerprint?  // One-to-one.
    @NSManaged var login: UserLogin?  // One-to-one.
    @NSManaged var profile: UserProfile?  // One-to-one.
    @NSManaged var settings: UserSettings?  // One-to-one.

    // App Features:
    @NSManaged var memberships: Set<Member>?
}

// Local & Cloud Storage:
extension DeviceUser: SyncTrackable {
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var deletedAt: Date?
    @NSManaged public var syncStatusRaw: Int16
    @NSManaged public var lastCloudSyncedAt: Date?
    @NSManaged public var schemaVersion: Int

    // Computed:
    public var syncStatus: SyncStatus {
        get { SyncStatus(rawValue: syncStatusRaw) ?? .pending }
        set { syncStatusRaw = newValue.rawValue }
    }
}
