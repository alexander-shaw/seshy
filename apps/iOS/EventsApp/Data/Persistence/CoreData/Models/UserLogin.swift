//
//  UserLogin.swift
//  EventsApp
//
//  Created by Шоу on 10/4/25.
//

import Foundation
import CoreData
import CoreDomain

@objc(UserLogin)
public class UserLogin: NSManagedObject {}

extension UserLogin {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserLogin> {
        NSFetchRequest<UserLogin>(entityName: "UserLogin")
    }

    @NSManaged public var id: UUID
    @NSManaged public var lastLoginAt: Date?

    // Phone (Required):
    // Normalized E.164 hash for privacy.
    @NSManaged public var phoneE164Hashed: String  // MARK: Unique.
    @NSManaged public var phoneVerifiedAt: Date?

    // Email (Optional):
    // Hash for privacy.
    @NSManaged public var emailAddressHashed: String?  // MARK: Unique.
    @NSManaged public var emailDomain: String?
    @NSManaged public var emailVerifiedAt: Date?

    // Relationship:
    @NSManaged public var user: DeviceUser
}

// Local & Cloud Storage:
extension UserLogin: SyncTrackable {
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
