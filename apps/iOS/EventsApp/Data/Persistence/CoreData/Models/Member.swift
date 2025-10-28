//
//  Member.swift
//  EventsApp
//
//  Created by Шоу on 10/4/25.
//

// Represents someone in the UserEvent with a clear role for permissions.
// Belongs to a UserEvent.  Stores person as userID and snapshot.
// Invite approval creates a Member.

import Foundation
import CoreData
import CoreDomain

@objc(Member)
public class Member: NSManagedObject {}

extension Member {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Member> {
        NSFetchRequest<Member>(entityName: "Member")
    }

    @NSManaged public var id: UUID  // MARK: Unique.
    @NSManaged public var roleRaw: Int16  // MemberRole.

    @NSManaged public var userID: UUID
    @NSManaged public var displayName: String
    @NSManaged public var username: String?
    @NSManaged public var avatarURL: String?

    // Relationships:
    @NSManaged public var event: UserEvent
}

extension Member {
    public var role: MemberRole {
        get { MemberRole(rawValue: roleRaw) ?? .guest }
        set { roleRaw = newValue.rawValue }
    }
}

// Local & Cloud Storage:
extension Member: SyncTrackable {
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
